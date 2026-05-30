#define ARC_MODULE_ICON 'icons/obj/armored/2x3/arc_module.dmi'
#define ARC_ANTENNA_DEPLOY_TIME 1.2 SECONDS
#define ARC_ANTENNA_RETRACT_TIME 1 SECONDS
#define ARC_TESLA_RANGE 7
#define ARC_TESLA_XENO_COOLDOWN 5 SECONDS

/obj/vehicle/sealed/armored/multitile/arc
	name = "\improper ARC - Argus"
	desc = "An M540-B Armored Recon Carrier. A lightly armored reconnaissance and intelligence vehicle. Entrances on the sides. \
		Optional tesla antenna and Bushwhacker autocannon modules can be installed or purchased separately."
	icon = 'icons/obj/armored/2x3/arc.dmi'
	icon_state = "arc"
	damage_icon_path = 'icons/obj/armored/2x3/arc_damage_overlay.dmi'
	hitbox = /obj/hitbox/two_three
	interior = /datum/interior/armored/arc
	permitted_weapons = list(/obj/item/armored_weapon/arc_autocannon)
	permitted_mods = list(/obj/item/tank_module/ability/arc_tesla_antenna)
	armored_flags = ARMORED_HAS_HEADLIGHTS|ARMORED_HAS_UNDERLAY|ARMORED_WRECKABLE|ARMORED_PURCHASABLE_TRANSPORT|ARMORED_SELF_WALL_DAMAGE|ARMORED_HAS_SECONDARY_WEAPON
	required_entry_skill = SKILL_LARGE_VEHICLE_DEFAULT
	minimap_icon_state = "arc"
	turret_icon = null
	pixel_x = -24
	pixel_y = -32
	pixel_w = 0
	pixel_z = 0
	max_integrity = 450
	soft_armor = list(MELEE = 30, BULLET = 60, LASER = 50, ENERGY = 40, BOMB = 35, BIO = 60, FIRE = 35, ACID = 35)
	hard_armor = list(MELEE = 0, BULLET = 10, LASER = 10, ENERGY = 10, BOMB = 0, BIO = 10, FIRE = 0, ACID = 0)
	max_occupants = 5
	enter_delay = 0.4 SECONDS
	ram_damage = 25
	move_delay = 0.2 SECONDS
	glide_size = 8.5
	easy_load_list = list(
		/obj/item/ammo_magazine/tank,
		/obj/structure/largecrate,
		/obj/structure/closet/crate,
	)
	/// Whether the tesla antenna is fully deployed. Blocks movement and powers the autocannon.
	var/antenna_deployed = FALSE
	/// Antenna deploy/retract animation in progress.
	var/antenna_deploying = FALSE
	/// REF() -> world.time when that xeno last granted supply points from tesla.
	var/list/tesla_hit_cooldowns = list()
	/// Timer id for antenna deploy/retract animation.
	var/antenna_deploy_timer

/// ARC with tesla antenna and autocannon pre-installed (mapping / presets).
/obj/vehicle/sealed/armored/multitile/arc/equipped
	desc = "An M540-B Armored Recon Carrier. A lightly armored reconnaissance and intelligence vehicle. Entrances on the sides. \
		Comes pre-fitted with a tesla antenna and Bushwhacker autocannon."

/obj/vehicle/sealed/armored/multitile/arc/equipped/Initialize(mapload)
	. = ..()
	if(QDELETED(src))
		return
	install_arc_modules()

/obj/vehicle/sealed/armored/multitile/arc/proc/install_arc_modules()
	if(!has_tesla_antenna())
		var/obj/item/tank_module/ability/arc_tesla_antenna/antenna = new()
		antenna.on_equip(src)
	if(!has_autocannon())
		var/obj/item/armored_weapon/arc_autocannon/gun = new(src)
		gun.attach(src, FALSE)

/obj/vehicle/sealed/armored/multitile/arc/proc/has_tesla_antenna()
	return istype(driver_utility_module, /obj/item/tank_module/ability/arc_tesla_antenna)

/obj/vehicle/sealed/armored/multitile/arc/proc/has_autocannon()
	return istype(secondary_weapon, /obj/item/armored_weapon/arc_autocannon)

/obj/vehicle/sealed/armored/multitile/arc/Destroy()
	set_antenna(FALSE, instant = TRUE)
	tesla_hit_cooldowns = null
	return ..()

/obj/vehicle/sealed/armored/multitile/arc/setDir(newdir)
	. = ..()
	update_arc_module_overlays()
	if(armored_flags & ARMORED_IS_WRECK)
		update_smoke_dir(null, null, newdir)

// Это ПРОКЛЯТО
// Нет я серьёзно, это просто проклято нахуй
// Менять на свой страх и риск
/obj/vehicle/sealed/armored/multitile/arc/enter_locations(atom/movable/entering_thing)
	var/min_x
	var/max_x
	var/min_y
	var/max_y
	for(var/turf/vehicle_turf AS in hitbox?.locs)
		if(isnull(min_x) || vehicle_turf.x < min_x)
			min_x = vehicle_turf.x
		if(isnull(max_x) || vehicle_turf.x > max_x)
			max_x = vehicle_turf.x
		if(isnull(min_y) || vehicle_turf.y < min_y)
			min_y = vehicle_turf.y
		if(isnull(max_y) || vehicle_turf.y > max_y)
			max_y = vehicle_turf.y
	if(isnull(min_x))
		return ..()
	switch(dir)
		if(NORTH)
			return list(locate(max_x + 1, min_y + 1, z))
		if(SOUTH)
			return list(locate(max_x + 1, min_y + 2, z))
		if(EAST)
			return list(locate(min_x + 1, min_y - 1, z))
		if(WEST)
			return list(locate(min_x + 2, max_y + 1, z))
	return ..()

/obj/vehicle/sealed/armored/multitile/arc/wreck_vehicle()
	. = ..()
	cancel_antenna_toggle()
	antenna_deployed = FALSE
	antenna_deploying = FALSE
	STOP_PROCESSING(SSobj, src)
	update_arc_module_overlays()
	update_smoke_dir(newdir = dir)

/obj/vehicle/sealed/armored/multitile/arc/update_smoke_dir(datum/source, dir, newdir)
	switch(newdir)
		if(SOUTH)
			smoke_holder.particles.position = list(20, 16, 0)
		if(NORTH)
			smoke_holder.particles.position = list(-4, 73, 0)
		if(EAST)
			smoke_holder.particles.position = list(70, 35, 0)
		if(WEST)
			smoke_holder.particles.position = list(10, 35, 0)

/obj/vehicle/sealed/armored/multitile/arc/relaymove(mob/user, direction)
	if(antenna_deployed || antenna_deploying)
		balloon_alert(user, "antenna deployed")
		return FALSE
	return ..()

/obj/vehicle/sealed/armored/multitile/arc/on_mouseclick(mob/user, atom/target, turf/location, control, list/modifiers)
	SIGNAL_HANDLER
	modifiers = params2list(modifiers)
	if(isnull(location) && target.plane == CLICKCATCHER_PLANE)
		target = params2turf(modifiers["screen-loc"], get_turf(src), user.client)
		modifiers["icon-x"] = num2text(ABS_PIXEL_TO_REL(text2num(modifiers["icon-x"])))
		modifiers["icon-y"] = num2text(ABS_PIXEL_TO_REL(text2num(modifiers["icon-y"])))
	if(modifiers[SHIFT_CLICK])
		return
	if(!isturf(target) && !isturf(target.loc))
		return
	if(HAS_TRAIT(user, TRAIT_INCAPACITATED))
		return
	if(src == target)
		return
	if(!is_equipment_controller(user))
		balloon_alert(user, "wrong seat for equipment!")
		return COMSIG_MOB_CLICK_CANCELED
	if(LAZYACCESS(modifiers, MIDDLE_CLICK))
		set_safety(user)
		return COMSIG_MOB_CLICK_CANCELED
	if(!has_autocannon())
		return ..()
	if(modifiers[BUTTON] != RIGHT_CLICK && modifiers[BUTTON] != LEFT_CLICK)
		return ..()
	if(!antenna_deployed)
		balloon_alert(user, "deploy antenna first")
		return COMSIG_MOB_CLICK_CANCELED
	if(antenna_deploying)
		balloon_alert(user, "antenna moving")
		return COMSIG_MOB_CLICK_CANCELED
	if(weapons_safety || zoom_mode)
		return COMSIG_MOB_CLICK_CANCELED
	INVOKE_ASYNC(secondary_weapon, TYPE_PROC_REF(/obj/item/armored_weapon, begin_fire), user, target, modifiers)
	return COMSIG_MOB_CLICK_CANCELED

/obj/vehicle/sealed/armored/multitile/arc/process()
	if(!has_tesla_antenna() || !antenna_deployed || antenna_deploying || (armored_flags & ARMORED_IS_WRECK) || obj_integrity <= 0)
		return PROCESS_KILL
	var/turf/arc_turf = get_turf(src)
	if(!is_ground_level(arc_turf.z))
		return
	var/list/zapped = zap_beam(src, ARC_TESLA_RANGE, 4, max_targets = 4)
	if(!length(zapped))
		return
	playsound(loc, 'sound/weapons/guns/fire/tesla.ogg', 60, TRUE)
	for(var/mob/living/carbon/xenomorph/xeno AS in zapped)
		if(!can_award_tesla_points(xeno))
			continue
		award_tesla_points(xeno)
		tesla_hit_cooldowns[REF(xeno)] = world.time + ARC_TESLA_XENO_COOLDOWN

/obj/vehicle/sealed/armored/multitile/arc/proc/cancel_antenna_toggle()
	deltimer(antenna_deploy_timer)
	antenna_deploy_timer = null

/obj/vehicle/sealed/armored/multitile/arc/proc/toggle_antenna(mob/user)
	if(!has_tesla_antenna())
		balloon_alert(user, "no antenna module")
		return
	if(antenna_deploying)
		balloon_alert(user, "antenna moving")
		return
	if(armored_flags & ARMORED_IS_WRECK)
		balloon_alert(user, "vehicle wrecked")
		return
	set_antenna(!antenna_deployed)

/// Deploy or stow the tesla antenna. [instant] skips animation (destroy/wreck).
/obj/vehicle/sealed/armored/multitile/arc/proc/set_antenna(enabled, instant = FALSE)
	if(!has_tesla_antenna())
		antenna_deployed = FALSE
		antenna_deploying = FALSE
		STOP_PROCESSING(SSobj, src)
		update_arc_module_overlays()
		return
	if(!instant && (enabled == antenna_deployed || antenna_deploying))
		return
	cancel_antenna_toggle()
	if(instant)
		antenna_deployed = enabled
		antenna_deploying = FALSE
		if(antenna_deployed)
			START_PROCESSING(SSobj, src)
		else
			STOP_PROCESSING(SSobj, src)
		update_arc_module_overlays()
		return
	antenna_deploying = TRUE
	update_arc_module_overlays()
	if(enabled)
		play_antenna_animation("antenna_extending", CALLBACK(src, PROC_REF(on_antenna_deploy_complete)))
	else
		STOP_PROCESSING(SSobj, src)
		play_antenna_animation("antenna_retracting", CALLBACK(src, PROC_REF(on_antenna_retract_complete)))

/obj/vehicle/sealed/armored/multitile/arc/proc/on_antenna_deploy_complete()
	antenna_deployed = TRUE
	START_PROCESSING(SSobj, src)
	update_arc_module_overlays()

/obj/vehicle/sealed/armored/multitile/arc/proc/on_antenna_retract_complete()
	antenna_deployed = FALSE
	update_arc_module_overlays()

/obj/vehicle/sealed/armored/multitile/arc/proc/play_antenna_animation(sequence, datum/callback/finish_callback)
	var/atom/movable/vis_obj/fx = new()
	fx.icon = ARC_MODULE_ICON
	fx.icon_state = "antenna_cover"
	fx.dir = dir
	fx.vis_flags = VIS_INHERIT_ID|VIS_INHERIT_LAYER|VIS_INHERIT_PLANE
	vis_contents += fx
	flick(sequence, fx)
	var/delay = (sequence == "antenna_extending") ? ARC_ANTENNA_DEPLOY_TIME : ARC_ANTENNA_RETRACT_TIME
	antenna_deploy_timer = addtimer(CALLBACK(src, PROC_REF(on_antenna_animation_end), fx, finish_callback), delay, TIMER_STOPPABLE)

/obj/vehicle/sealed/armored/multitile/arc/proc/on_antenna_animation_end(atom/movable/fx, datum/callback/finish_callback)
	antenna_deploy_timer = null
	antenna_deploying = FALSE
	if(fx)
		vis_contents -= fx
		qdel(fx)
	finish_callback?.Invoke()
	update_arc_module_overlays()

/obj/vehicle/sealed/armored/multitile/arc/proc/flick_autocannon_fire()
	if(!has_autocannon())
		return
	var/atom/movable/vis_obj/fx = new()
	fx.icon = ARC_MODULE_ICON
	fx.icon_state = "autocannon"
	fx.dir = dir
	fx.vis_flags = VIS_INHERIT_ID|VIS_INHERIT_LAYER|VIS_INHERIT_PLANE
	vis_contents += fx
	flick("autocannon_fire", fx)
	addtimer(CALLBACK(src, PROC_REF(cleanup_autocannon_flick), fx), 0.4 SECONDS)

/obj/vehicle/sealed/armored/multitile/arc/proc/cleanup_autocannon_flick(atom/movable/fx)
	vis_contents -= fx
	qdel(fx)

/obj/vehicle/sealed/armored/multitile/arc/proc/can_award_tesla_points(mob/living/carbon/xenomorph/xeno)
	var/cooldown_end = tesla_hit_cooldowns[REF(xeno)]
	return !cooldown_end || world.time >= cooldown_end

/obj/vehicle/sealed/armored/multitile/arc/proc/award_tesla_points(mob/living/carbon/xenomorph/xeno)
	var/points = get_tesla_points_for_tier(xeno.xeno_caste?.tier)
	if(!points)
		return
	var/faction = get_supply_faction()
	SSpoints.supply_points[faction] += points
	for(var/mob/living/occupant AS in occupants)
		if(!occupant.client)
			continue
		var/tier_label = xeno.xeno_caste?.tier ? GLOB.tier_as_number[xeno.xeno_caste.tier] : "?"
		to_chat(occupant, span_notice("Tesla antenna awards [points] supply points for striking a tier [tier_label] xenomorph."))

/obj/vehicle/sealed/armored/multitile/arc/proc/get_tesla_points_for_tier(tier)
	switch(tier)
		if(XENO_TIER_ONE)
			return 5
		if(XENO_TIER_TWO)
			return 10
		if(XENO_TIER_THREE)
			return 25
		if(XENO_TIER_FOUR)
			return 50
	return 0

/obj/vehicle/sealed/armored/multitile/arc/proc/get_supply_faction()
	for(var/mob/living/occupant AS in occupants)
		if(occupant.faction)
			return occupant.faction
	return FACTION_TERRAGOV

/obj/vehicle/sealed/armored/multitile/arc/proc/update_arc_module_overlays()
	update_appearance(UPDATE_OVERLAYS)

/obj/vehicle/sealed/armored/multitile/arc/update_overlays()
	. = ..()
	if(armored_flags & ARMORED_IS_WRECK)
		if(has_autocannon())
			. += mutable_appearance(ARC_MODULE_ICON, "autocannon_wreck", dir = dir)
		if(has_tesla_antenna())
			. += mutable_appearance(ARC_MODULE_ICON, "antenna_wreck", dir = dir)
		return
	if(has_autocannon())
		. += mutable_appearance(ARC_MODULE_ICON, "autocannon", dir = dir)
	if(!has_tesla_antenna())
		return
	if(antenna_deploying)
		return
	. += mutable_appearance(ARC_MODULE_ICON, antenna_deployed ? "antenna_extended" : "antenna_cover", dir = dir)

/obj/item/armored_weapon/arc_autocannon
	name = "\improper ARC Bushwhacker Autocannon"
	desc = "A hull-mounted Bushwhacker 30mm autocannon. Only functions while the tesla antenna is deployed."
	icon = ARC_MODULE_ICON
	icon_state = "autocannon"
	armored_weapon_flags = MODULE_SECONDARY|MODULE_FIXED_FIRE_ARC
	interior_fire_sound = null

/obj/item/armored_weapon/arc_autocannon/attach(obj/vehicle/sealed/armored/tank, attach_primary)
	tank.secondary_weapon?.detach(tank.exit_location())
	tank.secondary_weapon = src
	chassis = tank
	forceMove(tank)
	var/icon_list
	if(ammo?.default_ammo)
		icon_list = list(ammo.default_ammo.hud_state, ammo.default_ammo.hud_state_empty)
	else
		icon_list = list(hud_state_empty, hud_state_empty)
	for(var/mob/occupant AS in chassis.occupants)
		occupant.hud_used.add_ammo_hud(src, icon_list, ammo ? ammo.current_rounds : 0)
	if(istype(tank, /obj/vehicle/sealed/armored/multitile/arc))
		var/obj/vehicle/sealed/armored/multitile/arc/arc = tank
		arc.update_arc_module_overlays()

/obj/item/armored_weapon/arc_autocannon/detach(atom/moveto)
	if(chassis?.secondary_weapon == src)
		chassis.secondary_weapon = null
		for(var/mob/occupant AS in chassis.occupants)
			occupant.hud_used.remove_ammo_hud(src)
		if(istype(chassis, /obj/vehicle/sealed/armored/multitile/arc))
			var/obj/vehicle/sealed/armored/multitile/arc/arc = chassis
			arc.update_arc_module_overlays()
	chassis = null
	forceMove(moveto)

/obj/item/armored_weapon/arc_autocannon/proc/get_fire_turf()
	return chassis?.hitbox?.get_projectile_loc(src) || get_turf(chassis)

/obj/item/armored_weapon/arc_autocannon/begin_fire(mob/source, atom/target, list/modifiers)
	if(istype(chassis, /obj/vehicle/sealed/armored/multitile/arc))
		var/obj/vehicle/sealed/armored/multitile/arc/arc = chassis
		if(!arc.has_autocannon())
			return
		if(!arc.antenna_deployed || arc.antenna_deploying)
			playsound(source, 'sound/weapons/guns/fire/empty.ogg', 15, 1)
			chassis.balloon_alert(source, "deploy antenna first")
			return
	return ..()

/obj/item/armored_weapon/arc_autocannon/do_after_checks(atom/target)
	if(!chassis || QDELETED(current_target))
		return FALSE
	var/turf/source_turf = get_fire_turf()
	var/dir_target_diff = get_between_angles(Get_Angle(source_turf, target), dir2angle(chassis.dir))
	return dir_target_diff <= (ARMORED_FIRE_CONE_ALLOWED * 0.5)

/obj/item/armored_weapon/arc_autocannon/fire()
	if(!current_target)
		return
	var/turf/source_turf = get_fire_turf()
	if(armored_weapon_flags & MODULE_FIXED_FIRE_ARC)
		var/dir_target_diff = get_between_angles(Get_Angle(source_turf, current_target), dir2angle(chassis.dir))
		if(dir_target_diff > (ARMORED_FIRE_CONE_ALLOWED * 0.5))
			return
	do_fire(source_turf)
	var/atom/sound_play_loc = interior_fire_sound && chassis.interior ? chassis : src
	playsound(sound_play_loc, islist(fire_sound) ? pick(fire_sound):fire_sound, GUN_FIRE_SOUND_VOLUME, fire_sound_vary)
	if(interior_fire_sound)
		chassis.play_interior_sound(chassis.interior.secondary_breech, islist(interior_fire_sound) ? pick(interior_fire_sound):interior_fire_sound, 40, fire_sound_vary)
	chassis.log_message("Fired from [name], targeting [current_target] at [AREACOORD(current_target)].", LOG_ATTACK)
	ammo.current_rounds--
	if(istype(chassis, /obj/vehicle/sealed/armored/multitile/arc))
		var/obj/vehicle/sealed/armored/multitile/arc/arc = chassis
		arc.flick_autocannon_fire()
	for(var/mob/occupant AS in chassis.occupants)
		occupant.hud_used.update_ammo_hud(src, list(ammo.default_ammo.hud_state, ammo.default_ammo.hud_state_empty), ammo.current_rounds)
	if(ammo.current_rounds > 0)
		return AUTOFIRE_CONTINUE|AUTOFIRE_SUCCESS
	playsound(src, 'sound/weapons/guns/misc/empty_alarm.ogg', 25, 1)
	eject_ammo()
	if(LAZYACCESS(current_firer.do_actions, src) || length(ammo_magazine) < 1)
		return AUTOFIRE_SUCCESS
	var/obj/item/ammo_magazine/tank/new_mag = ammo_magazine[1]
	if(istype(new_mag) && new_mag.loading_sound)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), src, new_mag.loading_sound, 40), 5)
	if(!do_after(current_firer, rearm_time, IGNORE_HELD_ITEM|IGNORE_LOC_CHANGE, chassis, BUSY_ICON_GENERIC))
		return AUTOFIRE_SUCCESS
	reload()
	return AUTOFIRE_CONTINUE|AUTOFIRE_SUCCESS

/datum/action/vehicle/sealed/armored/arc_tesla_antenna
	name = "Toggle Tesla Antenna"
	action_icon = 'icons/mob/actions/actions_mecha.dmi'
	action_icon_state = "pulsearmor"
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_MECHABILITY_TOGGLE_ZOOM,
	)

/datum/action/vehicle/sealed/armored/arc_tesla_antenna/action_activate(trigger_flags)
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	var/obj/vehicle/sealed/armored/multitile/arc/arc = chassis
	if(!istype(arc))
		return
	arc.toggle_antenna(owner)
	var/state_text = arc.antenna_deploying ? "moving" : (arc.antenna_deployed ? "deployed" : "stowed")
	chassis.balloon_alert(owner, "antenna [state_text]")
	update_button_icon()

/obj/item/tank_module/ability/arc_tesla_antenna
	name = "ARC tesla antenna"
	desc = "A deployable tesla coil mast. While deployed the ARC cannot move, shocks nearby xenomorphs for requisitions points, and powers the autocannon."
	icon_state = "tesla"
	is_driver_module = TRUE
	flag_controller = VEHICLE_CONTROL_DRIVE
	ability_to_grant = /datum/action/vehicle/sealed/armored/arc_tesla_antenna

/obj/item/tank_module/ability/arc_tesla_antenna/on_equip(obj/vehicle/sealed/armored/vehicle, mob/living/user)
	. = ..()
	if(!.)
		return
	if(overlay)
		vehicle.cut_overlay(overlay)
		overlay = null
	if(istype(vehicle, /obj/vehicle/sealed/armored/multitile/arc))
		var/obj/vehicle/sealed/armored/multitile/arc/arc = vehicle
		arc.update_arc_module_overlays()

/obj/item/tank_module/ability/arc_tesla_antenna/on_unequip(mob/user)
	var/obj/vehicle/sealed/armored/multitile/arc/arc = owner
	if(istype(arc))
		if(arc.antenna_deployed || arc.antenna_deploying)
			arc.set_antenna(FALSE, instant = TRUE)
	. = ..()
	if(istype(arc))
		arc.update_arc_module_overlays()

/obj/hitbox/two_three/get_projectile_loc(obj/item/armored_weapon/weapon)
	if(istype(weapon, /obj/item/armored_weapon/arc_autocannon))
		var/turf/origin = get_turf(root)
		if(!origin)
			return loc
		return get_step(origin, root.dir) || origin
	return ..()

#undef ARC_MODULE_ICON
#undef ARC_ANTENNA_DEPLOY_TIME
#undef ARC_ANTENNA_RETRACT_TIME
#undef ARC_TESLA_RANGE
#undef ARC_TESLA_XENO_COOLDOWN
