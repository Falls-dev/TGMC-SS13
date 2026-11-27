#define GUNSLINGER_DEPLOY_COST 25
#define GUNSLINGER_SALVAGE_COST 5
#define GUNSLINGER_REPAIR_AMOUNT 20
#define GUNSLINGER_RELOAD_AMOUNT 20

/obj/item/gunslinger
	name = "\improper Gunslinger"
	desc = "Инженерная механическая рука со встроенным сборщиком мини-турелей."
	icon = 'icons/obj/items/gunslinger.dmi'
	icon_state = "gunslinger"
	worn_icon_state = "gunslinger"
	worn_icon_list = list(
		slot_l_hand_str = 'icons/mob/inhands/equipment/gunslinger_left.dmi',
		slot_r_hand_str = 'icons/mob/inhands/equipment/gunslinger_right.dmi',
	)
	w_class = WEIGHT_CLASS_NORMAL
	force = 12
	hitsound = 'sound/weapons/genhit2.ogg'
	///The only wearer authorized to command this unit.
	var/mob/living/carbon/human/wearer
	///The deployed unit, if any.
	var/obj/machinery/deployable/mounted/sentry/gunslinger/mini_sentry

/obj/item/gunslinger/examine(mob/user)
	. = ..()
	. += span_notice("Активируйте предмет в руке, чтобы закрепить его. ПКМ по соседней клетке устанавливает мини-турель за одну секунду и [GUNSLINGER_DEPLOY_COST] листов металла. ПКМ по самой турели разбирает её и возвращает металл с учётом оставшихся прочности и боезапаса и вычетом [GUNSLINGER_SALVAGE_COST] листов. ПКМ в другом месте отзывает турель без возврата металла. Удар по своей или дружественной мини-турели тратит один лист на ремонт и пополнение боезапаса. Удар по живой цели вызывает краткое замедление и стаггер на одну секунду.")

/obj/item/gunslinger/attack_self(mob/user)
	. = ..()
	if(. || wearer || !ishuman(user) || user.get_active_held_item() != src || user.incapacitated(TRUE) || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
		return
	var/obj/item/gunslinger/other = user.get_inactive_held_item()
	if(istype(other) && other.wearer)
		user.balloon_alert(user, "Механическая рука уже установлена")
		return
	wearer = user
	ADD_TRAIT(src, TRAIT_NODROP, TRAIT_GENERIC)
	item_flags |= DELONDROP
	RegisterSignal(wearer, COMSIG_MOB_CLICK_RIGHT, PROC_REF(on_right_click))
	user.balloon_alert(user, "Механическая рука закреплена")
	return TRUE

/obj/item/gunslinger/Destroy()
	if(wearer)
		UnregisterSignal(wearer, COMSIG_MOB_CLICK_RIGHT)
	wearer = null
	QDEL_NULL(mini_sentry)
	return ..()

/obj/item/gunslinger/proc/can_operate(mob/user)
	return wearer == user && loc == user && user.get_active_held_item() == src && !user.incapacitated(TRUE) && !user.lying_angle && !HAS_TRAIT(user, TRAIT_HANDS_BLOCKED)

/obj/item/gunslinger/proc/on_right_click(mob/user, atom/target)
	SIGNAL_HANDLER
	if(!can_operate(user) || !isturf(user.loc) || user.in_throw_mode)
		return
	if(mini_sentry)
		recall_sentry(user, target == mini_sentry)
	else
		INVOKE_ASYNC(src, PROC_REF(deploy_sentry), user, get_turf(target))
	return COMSIG_MOB_CLICK_HANDLED

/obj/item/gunslinger/proc/deploy_sentry(mob/user, turf/open/site)
	if(user.do_actions || !can_deploy_at(user, site))
		return
	if(!spend_metal(user, GUNSLINGER_DEPLOY_COST, check_only = TRUE))
		user.balloon_alert(user, "Нужно [GUNSLINGER_DEPLOY_COST] листов металла")
		return
	user.setDir(get_cardinal_dir(user, site))
	if(!do_after(user, 1 SECONDS, NONE, src, BUSY_ICON_BUILD) || QDELETED(src) || !can_deploy_at(user, site))
		return
	if(!spend_metal(user, GUNSLINGER_DEPLOY_COST))
		user.balloon_alert(user, "Нужно [GUNSLINGER_DEPLOY_COST] листов металла")
		return

	var/obj/item/weapon/gun/sentry/mini/gunslinger/gun = new(null, TRUE)
	gun.fill_gun()
	mini_sentry = new(site, gun, user, src)
	mini_sentry.setDir(get_cardinal_dir(user, site))
	mini_sentry.update_appearance()
	log_combat(user, mini_sentry, "deployed")

/obj/item/gunslinger/proc/can_deploy_at(mob/user, turf/open/site)
	if(mini_sentry || !can_operate(user) || !isturf(user.loc) || user.in_throw_mode)
		return FALSE
	if(!istype(site) || !site.allow_construction || site == user.loc || !user.Adjacent(site) || LinkBlocked(user.loc, site) || is_blocked_turf(site))
		user.balloon_alert(user, "Здесь нельзя установить турель")
		return FALSE
	for(var/obj/object in site)
		if(object.obj_flags & BLOCKS_CONSTRUCTION)
			user.balloon_alert(user, "Что-то мешает установить турель")
			return FALSE
	for(var/obj/machinery/deployable/mounted/sentry/sentry in urange(1, site))
		user.balloon_alert(user, "Слишком близко к другой турели")
		return FALSE
	return TRUE

/obj/item/gunslinger/proc/recall_sentry(mob/user, salvage)
	var/turf/recall_site = get_turf(mini_sentry)
	var/refund_amount = 0
	if(salvage)
		var/obj/item/weapon/gun/gun = mini_sentry.get_internal_item()
		var/integrity_fraction = clamp(mini_sentry.obj_integrity / mini_sentry.max_integrity, 0, 1)
		var/ammo_fraction = gun?.max_rounds ? clamp(gun.rounds / gun.max_rounds, 0, 1) : 0
		refund_amount = max(0, FLOOR(GUNSLINGER_DEPLOY_COST * (integrity_fraction + ammo_fraction) / 2, 1) - GUNSLINGER_SALVAGE_COST)
	log_combat(user, mini_sentry, "recalled", addition = "(refunded [refund_amount] metal sheets)")
	QDEL_NULL(mini_sentry)
	if(recall_site)
		new /obj/effect/temp_visual/explosion(recall_site, 1, LIGHT_COLOR_LAVA, 15)
		playsound(recall_site, 'sound/effects/explosion/micro1.ogg', 40, TRUE, SHORT_SOUND_RANGE)

	if(!refund_amount)
		user.balloon_alert(user, "Турель отозвана без возврата металла")
		return
	var/obj/item/stack/sheet/metal/refund = new(null, refund_amount)
	for(var/obj/item/stack/sheet/metal/stack as anything in user.get_all_contents_type(/obj/item/stack/sheet/metal))
		refund.merge(stack)
		if(QDELETED(refund))
			break
	if(!QDELETED(refund))
		user.put_in_hands(refund)
	user.balloon_alert(user, "Турель отозвана. Возвращено металла: [refund_amount]")

/obj/item/gunslinger/proc/spend_metal(mob/user, cost, check_only = FALSE)
	var/list/stacks = user.get_all_contents_type(/obj/item/stack/sheet/metal)
	var/available = 0
	for(var/obj/item/stack/sheet/metal/stack as anything in stacks)
		available += stack.get_amount()
		if(available >= cost)
			break
	if(available < cost)
		return FALSE
	if(check_only)
		return TRUE
	for(var/obj/item/stack/sheet/metal/stack as anything in stacks)
		var/used = min(cost, stack.get_amount())
		cost -= used
		stack.use(used)
		if(!cost)
			return TRUE

/obj/item/gunslinger/preattack(atom/target, mob/user, params)
	var/obj/machinery/deployable/mounted/sentry/gunslinger/sentry = target
	if(!istype(sentry) || !can_operate(user) || !user.Adjacent(sentry))
		return ..()
	if(sentry != mini_sentry && !sentry.match_iff(user))
		return ..()
	var/obj/item/weapon/gun/gun = sentry.get_internal_item()
	var/obj/item/ammo_magazine/magazine = gun.chamber_items[1]
	var/repair = min(GUNSLINGER_REPAIR_AMOUNT, sentry.max_integrity - sentry.obj_integrity)
	var/refill = min(GUNSLINGER_RELOAD_AMOUNT, gun.max_rounds - gun.rounds)
	if(repair <= 0 && refill <= 0)
		user.balloon_alert(user, "Турель исправна и заряжена")
		return TRUE
	if(!spend_metal(user, 1))
		user.balloon_alert(user, "Нужен лист металла")
		return TRUE
	if(repair > 0)
		sentry.repair_damage(repair, user)
	if(refill > 0)
		gun.adjust_current_rounds(magazine, refill)
		if(!gun.in_chamber)
			gun.cycle(after_fire = FALSE)
		gun.update_ammo_count()
	sentry.update_appearance()
	user.changeNext_move(CLICK_CD_MELEE)
	user.do_attack_animation(sentry, used_item = src)
	playsound(sentry, 'sound/weapons/tap.ogg', 35, TRUE)
	return TRUE

/obj/item/gunslinger/attack(mob/living/target, mob/living/user)
	// A fully blocked hit can still return TRUE, so require an increase in brute damage before applying effects.
	var/previous_brute_loss = target.get_brute_loss()
	. = ..()
	if(!. || QDELETED(target) || target.stat == DEAD || target.get_brute_loss() <= previous_brute_loss)
		return
	target.Stagger(1 SECONDS)
	target.add_slowdown(1)

/obj/item/weapon/gun/sentry/mini/gunslinger
	name = "боевая мини-турель"
	desc = "Компактная автоматическая турель для механической руки Gunslinger. Ремонтируется и пополняет боезапас за счёт листов металла."
	icon = 'icons/obj/items/gunslinger.dmi'
	icon_state = "combat_mini"
	turret_flags = TURRET_IMMOBILE|TURRET_RADIAL|TURRET_SAFETY
	deployable_item = null
	deploy_flags = DEPLOYED_NO_PICKUP
	reciever_flags = AMMO_RECIEVER_MAGAZINES|AMMO_RECIEVER_AUTO_EJECT_LOCKED
	default_ammo_type = /obj/item/ammo_magazine/minisentry/gunslinger
	allowed_ammo_types = list(/obj/item/ammo_magazine/minisentry/gunslinger)
	max_integrity = 100
	max_shells = 100
	fire_delay = 0.2 SECONDS
	///Radial operation reduces the inherited range by two tiles.
	turret_range = 7

/obj/item/ammo_magazine/minisentry/gunslinger
	name = "встроенный магазин мини-турели"
	max_rounds = 100

/obj/machinery/deployable/mounted/sentry/gunslinger
	density = FALSE
	obj_flags = CAN_BE_HIT|BLOCKS_CONSTRUCTION
	///The prosthesis that built this unit.
	var/obj/item/gunslinger/controller

/obj/machinery/deployable/mounted/sentry/gunslinger/Initialize(mapload, obj/item/weapon/gun/gun, mob/deployer, obj/item/gunslinger/builder)
	. = ..()
	controller = builder
	if(!iff_signal)
		iff_signal = GLOB.faction_to_iff[deployer.faction]
	gun.forceMove(src)
	gun.toggle_deployment_flag(TRUE)
	max_integrity = gun.max_integrity
	obj_integrity = max_integrity

/obj/machinery/deployable/mounted/sentry/gunslinger/Destroy()
	if(controller?.mini_sentry == src)
		controller.mini_sentry = null
	controller = null
	var/obj/item/weapon/gun/gun = get_internal_item()
	gun?.stop_fire()
	return ..()

/obj/machinery/deployable/mounted/sentry/gunslinger/update_icon_state()
	. = ..()
	var/obj/item/weapon/gun/gun = get_internal_item()
	if(gun && !gun.rounds)
		icon_state = "[default_icon_state]_e[machine_stat & KNOCKED_DOWN ? "_f" : ""]"

/obj/machinery/deployable/mounted/sentry/gunslinger/AltClick(mob/user)
	return

/obj/machinery/deployable/mounted/sentry/gunslinger/attack_hand_alternate(mob/living/user)
	return

/obj/machinery/deployable/mounted/sentry/gunslinger/attackby_alternate(obj/item/item, mob/user, params)
	return

/obj/machinery/deployable/mounted/sentry/gunslinger/reload(mob/user, ammo_magazine)
	return

/obj/machinery/deployable/mounted/sentry/gunslinger/welder_act(mob/living/user, obj/item/item)
	return FALSE

/obj/machinery/deployable/mounted/sentry/gunslinger/interact(mob/user, manual_mode = FALSE)
	return TRUE

#undef GUNSLINGER_DEPLOY_COST
#undef GUNSLINGER_SALVAGE_COST
#undef GUNSLINGER_REPAIR_AMOUNT
#undef GUNSLINGER_RELOAD_AMOUNT
