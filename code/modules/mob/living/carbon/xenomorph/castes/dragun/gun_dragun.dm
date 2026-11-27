/obj/item/weapon/gun/dragun
	name = "Dragun arm rifle"
	desc = "An integrated acid rifle powered by the Dragun's plasma. It must be held with both hands to fire."
	icon = 'icons/Xeno/dragun_item.dmi'
	icon_state = "hand_dragun"
	worn_icon_state = "hand_dragun"
	worn_icon_list = list()
	item_flags = TWOHANDED|HAND_ITEM|DELONDROP
	resistance_flags = RESIST_ALL
	force = 75
	gun_features_flags = GUN_WIELDED_FIRING_ONLY|GUN_WIELDED_STABLE_FIRING_ONLY|GUN_NO_PITCH_SHIFT_NEAR_EMPTY
	reciever_flags = AMMO_RECIEVER_CYCLE_ONLY_BEFORE_FIRE
	default_ammo_type = null
	allowed_ammo_types = list()
	attachable_allowed = list()
	max_chamber_items = 0
	ammo_datum_type = /datum/ammo/xeno/acid
	gun_firemode_list = list(GUN_FIREMODE_SEMIAUTO)
	fire_delay = 0.5 SECONDS
	wield_delay = 0.5 SECONDS
	aim_slowdown = 0.35
	gun_skill_category = SKILL_RIFLES
	/// Provisional cost until the caste's weapon balance is finalized.
	var/plasma_cost = 25
	var/charge_level = 0
	/// Live ammunition is retained while ordinary acid mode is selected.
	var/live_rounds = 0
	var/live_mode = FALSE
	var/bolt_loaded = FALSE
	var/bone_shrapnel_loaded = FALSE
	var/bolt_charge = 0

/obj/item/weapon/gun/dragun/proc/get_shot_cost()
	return live_mode ? 0 : plasma_cost

/obj/item/weapon/gun/dragun/proc/reset_charge()
	charge_level = 0
	bolt_charge = 0
	var/mob/living/carbon/xenomorph/dragun/dragun = loc
	if(!istype(dragun))
		return
	var/datum/action/ability/xeno_action/dragun_charge/action = dragun.actions_by_path[/datum/action/ability/xeno_action/dragun_charge]
	action?.update_button_icon()

/// Use the complete unarmed interaction path, including intent, hive/host
/// protection, barriers, posture, blocked hands, and the caste attack delay.
/obj/item/weapon/gun/dragun/melee_attack_chain(mob/user, atom/target, params, rightclick)
	if(!can_operate(user))
		return
	var/mob/living/carbon/xenomorph/dragun/dragun = user
	if(dragun.hand_dragun != src || dragun.get_active_held_item() != src)
		return
	var/list/modifiers = params2list(params)
	modifiers["right"] = rightclick
	RegisterSignal(dragun, COMSIG_XENOMORPH_ATTACK_LIVING, PROC_REF(blade_damage))
	. = dragun.UnarmedAttack(target, TRUE, modifiers)
	UnregisterSignal(dragun, COMSIG_XENOMORPH_ATTACK_LIVING)

/// Adjust only this blade swing; normal empty-hand attacks and abilities keep
/// their own damage. The normal harm proc still handles armor and shields.
/obj/item/weapon/gun/dragun/proc/blade_damage(mob/living/carbon/xenomorph/dragun/source, mob/living/target, damage, list/damage_mod, list/armor_mod)
	SIGNAL_HANDLER
	damage_mod += (force - source.xeno_caste.melee_damage) * source.xeno_melee_damage_modifier

/obj/item/weapon/gun/dragun/Initialize(mapload)
	. = ..()
	QDEL_NULL(muzzle_flash)
	ADD_TRAIT(src, TRAIT_NODROP, TRAIT_GENERIC)

/obj/item/weapon/gun/dragun/can_operate(mob/user)
	return istype(user, /mob/living/carbon/xenomorph/dragun) && loc == user

/// Projectiles identify their source as the gun, rather than its owner.
/// Expose the owner's hive so the existing xeno bullet_act protection applies.
/obj/item/weapon/gun/dragun/get_xeno_hivenumber()
	if(istype(loc, /mob/living/carbon/xenomorph/dragun))
		return loc.get_xeno_hivenumber()
	return ..()

/obj/item/weapon/gun/dragun/gun_on_cooldown(mob/user)
	// An integrated weapon cannot be juggled. Xenos lack the human cooldown signal responder.
	// Keep the normal last_fired/fire_delay check without human skills or anti-juggling.
	if(can_operate(user))
		return ..(null)
	return ..()

/obj/item/weapon/gun/dragun/able_to_fire(mob/user)
	if(!..())
		return FALSE
	var/mob/living/carbon/xenomorph/dragun/owner = user
	if(owner.hand_dragun != src || owner.get_active_held_item() != src)
		return FALSE
	if(live_mode && !live_rounds)
		owner.balloon_alert(owner, "no Live rounds")
		return FALSE
	if(owner.plasma_stored < get_shot_cost())
		to_chat(owner, span_warning("We need more plasma to fire our rifle!"))
		return FALSE
	return TRUE

/obj/item/weapon/gun/dragun/wield(mob/user)
	if(!can_operate(user) || user.get_active_held_item() != src)
		return FALSE
	return ..()

/obj/item/weapon/gun/dragun/toggle_wielded(mob/user, wielded)
	. = ..()
	user.update_icons()

// The weapon is already part of the body sprite in both poses; retain only the HUD icon.
/obj/item/weapon/gun/dragun/make_worn_icon(species_type, slot_name, inhands, default_icon, default_layer)
	if(!inhands)
		return null
	return ..()

/obj/item/weapon/gun/dragun/update_icon_state()
	icon_state = "hand_dragun"

/obj/item/weapon/gun/dragun/cycle(mob/living/user, after_fire = TRUE)
	if(!after_fire && !in_chamber && can_operate(user))
		in_chamber = get_ammo_object()

/obj/item/weapon/gun/dragun/do_fire(obj/object_to_fire)
	if(!able_to_fire(gun_user))
		return FALSE
	var/mob/living/carbon/xenomorph/dragun/owner = gun_user
	var/shot_cost = get_shot_cost()
	var/atom/movable/projectile/projectile = object_to_fire
	// Rebuild even a previously chambered round from the current charge.
	// Never modify the shared ammo datum in GLOB.ammo_list.
	var/ammo_type = charge_level >= 3 ? /datum/ammo/xeno/acid/heavy/passthrough : /datum/ammo/xeno/acid
	var/firing_live = live_mode && !bolt_loaded
	var/firing_bolt = bolt_loaded
	if(firing_bolt && !bone_shrapnel_loaded && prob(owner.xeno_caste.upgrade == XENO_UPGRADE_PRIMO ? 25 : 35))
		bone_shrapnel_loaded = TRUE
		owner.balloon_alert(owner, "the bone bolt shattered")
	if(firing_live)
		ammo_type = /datum/ammo/xeno/acid/heavy/passthrough/dragun_live
	else if(firing_bolt)
		ammo_type = bone_shrapnel_loaded ? /datum/ammo/bullet/dragun_bone_shrapnel : /datum/ammo/bullet/dragun_bone_bolt
	projectile.generate_bullet(GLOB.ammo_list[ammo_type])
	projectile.icon = initial(projectile.icon)
	if(firing_live || firing_bolt)
		projectile.icon = 'icons/Xeno/dragun_item.dmi'
		projectile.color = null
	if(charge_level && !firing_live && !firing_bolt)
		projectile.damage *= charge_level >= 3 ? charge_level - 1 : 2
	if(firing_bolt)
		if(!bone_shrapnel_loaded)
			projectile.damage *= max(1, bolt_charge * 3)
		projectile.dragun_bolt_charge = bolt_charge
	. = ..()
	if(.)
		if(firing_bolt)
			bolt_loaded = FALSE
			bone_shrapnel_loaded = FALSE
			bolt_charge = 0
		if(firing_live)
			live_rounds--
			owner.balloon_alert(owner, "Live [live_rounds]/3")
		owner.use_plasma(shot_cost)
		reset_charge()

/obj/item/weapon/gun/dragun/reload(obj/item/new_mag, mob/living/user, force = FALSE)
	return FALSE

/obj/item/weapon/gun/dragun/unload(mob/living/user, drop = TRUE, after_fire = FALSE)
	return FALSE

/obj/item/weapon/gun/dragun/proc/fire_acid_at(turf/target_turf)
	if(!target_turf || !gun_user || !(item_flags & FULLY_WIELDED))
		return FALSE
	if(gun_on_cooldown(gun_user))
		return FALSE
	set_target(target_turf)
	return Fire()

/obj/item/stack/dragun_bone
	name = "harvested bones"
	desc = "Bones that a Dragun can shape into living ammunition."
	icon = 'icons/Xeno/dragun_item.dmi'
	icon_state = "bone"
	max_amount = 50
	singular_name = "bone"

/obj/item/stack/dragun_bone/attack_alien(mob/living/carbon/xenomorph/xeno_attacker, isrightclick = FALSE)
	if(xeno_attacker.xeno_caste.can_flags & CASTE_CAN_HOLD_DRAGUN_BONES)
		return attack_hand(xeno_attacker)
	return FALSE

/datum/ammo/xeno/acid/heavy/passthrough/dragun_live
	name = "Live"
	bullet_color = null
	damage = 27
	damage_falloff = 0
	icon_state = "live_spire_1"
	ammo_behavior_flags = AMMO_XENO|AMMO_SKIPS_ALIENS|AMMO_SPECIAL_PROCESS
	shell_speed = 1
	max_range = 15

/datum/ammo/xeno/acid/heavy/passthrough/dragun_live/ammo_process(atom/movable/projectile/proj, damage)
	proj.icon_state = "live_spire_[min(3, 1 + round(proj.distance_travelled / 2))]"
	var/mob/living/nearest
	var/nearest_distance = 8
	for(var/mob/living/candidate in view(7, proj))
		if(candidate.stat == DEAD || isxeno(candidate) || candidate == proj.firer || (candidate.status_flags & (GODMODE|INCORPOREAL)))
			continue
		var/distance = get_dist(proj, candidate)
		if(distance < nearest_distance)
			nearest = candidate
			nearest_distance = distance
	if(!nearest)
		return
	var/target_angle = Get_Angle(get_turf(proj), get_turf(nearest))
	var/angle_delta = (target_angle - proj.dir_angle + 540) % 360 - 180
	proj.dir_angle = (proj.dir_angle + clamp(angle_delta, -30, 30) + 360) % 360
	proj.x_offset = round(sin(proj.dir_angle), 0.01)
	proj.y_offset = round(cos(proj.dir_angle), 0.01)
	var/matrix/rotation = matrix()
	rotation.Turn(proj.dir_angle)
	animate(proj, transform = rotation, time = SSprojectiles.wait)

/datum/ammo/bullet/dragun_bone_bolt
	name = "bone bolt"
	damage = 50
	penetration = 15
	damage_falloff = 0
	icon = 'icons/Xeno/dragun_item.dmi'
	icon_state = "Bolt"
	ammo_behavior_flags = AMMO_BALLISTIC
	shell_speed = 2
	max_range = 20
	shrapnel_chance = 100
	shrapnel_type = /obj/item/shard/shrapnel/bone_chips/xeno

/datum/ammo/bullet/dragun_bone_shrapnel
	name = "bone shrapnel"
	damage = 35
	penetration = 25
	damage_falloff = 0
	icon = 'icons/Xeno/dragun_item.dmi'
	icon_state = "shrapneli"
	shrapnel_chance = 0
	shrapnel_type = /obj/item/shard/shrapnel/bone_chips/xeno
	bonus_projectiles_amount = 1

/datum/ammo/bullet/dragun_bone_shrapnel/fire_bonus_projectiles(atom/movable/projectile/main_proj, mob/living/shooter, atom/source, range, speed, angle, target, origin_override)
	for(var/i in 1 to max(1, main_proj.dragun_bolt_charge))
		var/atom/movable/projectile/pellet = new(main_proj.loc)
		pellet.generate_bullet(src)
		pellet.icon = icon
		var/pellet_angle = angle + 8 * ((i % 2) ? -(i + 1) / 2 : i / 2)
		pellet.fire_at(target, shooter, source, range, speed, pellet_angle, TRUE, loc_override = origin_override)

/datum/ammo/bullet/dragun_bone_shrapnel/on_hit_mob(mob/target_mob, atom/movable/projectile/proj)
	if(!ishuman(target_mob))
		return
	var/mob/living/carbon/human/victim = target_mob
	var/list/zones = list(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	var/original_zone = proj.def_zone
	for(var/i in 1 to 4)
		proj.def_zone = pick(zones)
		victim.embed_projectile_shrapnel(proj)
	proj.def_zone = original_zone
