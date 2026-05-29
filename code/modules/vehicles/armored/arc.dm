/obj/vehicle/sealed/armored/multitile/arc
	name = "\improper ARC - Argus"
	desc = "An M540-B Armored Recon Carrier. A lightly armored reconnaissance and intelligence vehicle. Entrances on the sides."
	icon = 'icons/obj/armored/2x3/arc.dmi'
	icon_state = "arc_base"
	damage_icon_path = null
	hitbox = /obj/hitbox/two_three
	interior = /datum/interior/armored/arc
	permitted_weapons = NONE
	permitted_mods = list(/obj/item/tank_module/ability/arc_sensor)
	armored_flags = ARMORED_HAS_HEADLIGHTS|ARMORED_PURCHASABLE_TRANSPORT|ARMORED_SELF_WALL_DAMAGE
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
	///Whether the recon mast is deployed. When deployed, the ARC scans but cannot move.
	var/antenna_deployed = FALSE
	///Range at which deployed ARC sensors temporarily reveal xenos on minimaps.
	var/sensor_radius = 45

/obj/vehicle/sealed/armored/multitile/arc/Initialize(mapload)
	. = ..()
	var/obj/item/tank_module/module = new /obj/item/tank_module/ability/arc_sensor()
	module.on_equip(src)

/obj/vehicle/sealed/armored/multitile/arc/Destroy()
	set_antenna(FALSE)
	return ..()

/obj/vehicle/sealed/armored/multitile/arc/setDir(newdir)
	. = ..()
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
	set_antenna(FALSE)
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
	if(antenna_deployed)
		balloon_alert(user, "antenna deployed")
		return FALSE
	return ..()

/obj/vehicle/sealed/armored/multitile/arc/process()
	if(!antenna_deployed || (armored_flags & ARMORED_IS_WRECK) || obj_integrity <= 0)
		return PROCESS_KILL
	var/turf/arc_turf = get_turf(src)
	if(!is_ground_level(arc_turf.z))
		return
	var/contacts = 0
	for(var/mob/living/carbon/xenomorph/current_xeno AS in GLOB.alive_xeno_list)
		var/turf/xeno_turf = get_turf(current_xeno)
		if(!is_ground_level(xeno_turf.z))
			continue
		if(get_dist(src, current_xeno) <= sensor_radius)
			contacts++
	if(contacts)
		for(var/mob/living/occupant AS in occupants)
			to_chat(occupant, span_warning("ARC sensors detect [contacts] xenomorph contact[contacts == 1 ? "" : "s"] nearby."))

/obj/vehicle/sealed/armored/multitile/arc/proc/set_antenna(enabled)
	if(enabled == antenna_deployed)
		return
	antenna_deployed = enabled
	if(antenna_deployed)
		START_PROCESSING(SSslowprocess, src)
	else
		STOP_PROCESSING(SSslowprocess, src)
	update_appearance(UPDATE_OVERLAYS)

/obj/vehicle/sealed/armored/multitile/arc/update_overlays()
	. = ..()
	if(antenna_deployed)
		. += mutable_appearance(icon, "antenna_extended_1")

/datum/action/vehicle/sealed/armored/arc_sensor
	name = "Toggle ARC Sensors"
	action_icon = 'icons/mob/actions/actions_mecha.dmi'
	action_icon_state = "mech_zoom_off"
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_MECHABILITY_TOGGLE_ZOOM,
	)

/datum/action/vehicle/sealed/armored/arc_sensor/action_activate(trigger_flags)
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	var/obj/vehicle/sealed/armored/multitile/arc/arc = chassis
	if(!istype(arc))
		return
	arc.set_antenna(!arc.antenna_deployed)
	action_icon_state = "mech_zoom_[arc.antenna_deployed ? "on" : "off"]"
	chassis.balloon_alert(owner, "sensors [arc.antenna_deployed ? "deployed" : "stowed"]")
	update_button_icon()

/obj/item/tank_module/ability/arc_sensor
	name = "ARC sensor mast"
	desc = "A deployable reconnaissance mast that feeds nearby xenomorph contacts to tactical minimaps. The vehicle cannot move while the mast is deployed."
	icon_state = "zoom"
	tank_mod_flags = TANK_MOD_NOT_FABRICABLE
	is_driver_module = TRUE
	flag_controller = VEHICLE_CONTROL_DRIVE
	ability_to_grant = /datum/action/vehicle/sealed/armored/arc_sensor
