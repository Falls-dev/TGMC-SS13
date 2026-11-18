/obj/docking_port/stationary/marine_dropship/minidropship
	name = "Minidropship hangar pad"
	shuttle_id = SHUTTLE_TADPOLE
	roundstart_template = null

/obj/docking_port/mobile/marine_dropship/minidropship
	name = "Tadpole"
	shuttle_id = SHUTTLE_TADPOLE
	max_personnel = 6
	max_vehicles = 0
	dwidth = 0
	dheight = 0
	width = 7
	height = 9
	rechargeTime = 0

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship
	name = "Tadpole navigation computer"
	desc = "Flight controls for the Tadpole. Hold W/S for forward/reverse thrust and A/D to turn gradually. The aircraft coasts after releasing the controls. Land to touch down at the current position."
	icon_state = "shuttlecomputer"
	screen_overlay = "shuttlecomputer_screen"
	req_access = list(ACCESS_MARINE_TADPOLE)
	density = FALSE
	interaction_flags = INTERACT_OBJ_UI
	resistance_flags = RESIST_ALL
	shuttle_id = SHUTTLE_TADPOLE
	lock_override = CAMERA_LOCK_GROUND
	shuttlePortId = "minidropship_custom"
	view_range = "26x26"
	x_offset = 0
	y_offset = 0
	open_prompt = FALSE
	rotate_action = null
	nvg_vision_mode = FALSE
	/// Action of landing to a custom zone
	var/datum/action/innate/shuttledocker_land/land_action
	/// The current flying state of the shuttle
	var/fly_state = SHUTTLE_ON_SHIP
	/// The next flying state of the shuttle
	var/next_fly_state = SHUTTLE_ON_SHIP
	/// The flying state we will have when reaching our destination
	var/destination_fly_state = SHUTTLE_ON_SHIP
	/// If the next destination is a transit
	var/to_transit = TRUE
	/// The id of the stationary docking port on the ship
	var/origin_port_id = SHUTTLE_TADPOLE
	/// The user of the ui
	var/mob/living/ui_user
	/// How long before you can launch tadpole after a landing
	var/launching_delay = 10 SECONDS
	/// Native lower-level scene. No per-object appearance snapshots.
	var/datum/tadpole_scene/flight_scene
	var/datum/tadpole_transit_animation/transit_animation
	var/obj/effect/abstract/tadpole_searchlight/ground_searchlight
	var/list/ground_tiles = list()
	/// Continuous coordinates in tiles, velocity in tiles/second, heading in degrees.
	var/flight_x
	var/flight_y
	var/flight_heading = 0
	var/flight_velocity_x = 0
	var/flight_velocity_y = 0
	var/flight_turn_velocity = 0
	var/datum/tadpole_flight_controller/flight_controller
	///Minimap for use while piloting
	var/datum/action/minimap/marine/external/tadmap

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/Initialize(mapload)
	. = ..()
	start_processing()
	set_light(3,3, LIGHT_COLOR_RED)
	land_action = new
	flight_controller = new(src)
	tadmap = new
	off_action.name = "Release flight controls"
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/Destroy()
	if(current_user)
		remove_eye_control(current_user)
	QDEL_NULL(transit_animation)
	clear_ground_view()
	QDEL_NULL(flight_controller)
	QDEL_NULL(land_action)
	QDEL_NULL(tadmap)
	return ..()

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/CreateEye()
	. = ..()
	tadmap.override_locator(eyeobj)
	if(eyeobj)
		// Reuse the remote input/perspective plumbing, never move the actual shuttle in flight.
		eyeobj.name = "Tadpole flight controls"

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/LateInitialize()
	shuttle_port = SSshuttle.getShuttle(shuttle_id)
	if(lock_override & CAMERA_LOCK_GROUND)
		z_lock |= SSmapping.levels_by_trait(ZTRAIT_GROUND)

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/give_actions(mob/living/user)
	if(!user)
		return

	for(var/datum/action/action_from_shuttle_docker AS in actions)
		action_from_shuttle_docker.remove_action(user)
	actions.Cut()

	if(off_action)
		off_action.target = user
		off_action.give_action(user)
		actions += off_action

	if(tadmap)
		tadmap.target = user
		tadmap.give_action(user)
		actions += tadmap

	if(fly_state != SHUTTLE_IN_ATMOSPHERE)
		return

	if(land_action)
		land_action.target = user
		land_action.give_action(user)
		actions += land_action

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/shuttle_arrived()
	if(fly_state == next_fly_state)
		return
	var/previous_fly_state = fly_state
	clear_ground_view()
	fly_state = next_fly_state
	if(fly_state != SHUTTLE_IN_ATMOSPHERE && current_user)
		remove_eye_control(current_user)
	if(fly_state == SHUTTLE_IN_SPACE)
		shuttle_port.assigned_transit.reserved_area.set_turf_type(/turf/open/space/transit)
		if(previous_fly_state == SHUTTLE_IN_ATMOSPHERE && transit_animation?.returning)
			transit_animation.fade_to_space()
		else
			QDEL_NULL(transit_animation)
			if(previous_fly_state == SHUTTLE_ON_SHIP && destination_fly_state == SHUTTLE_IN_ATMOSPHERE)
				transit_animation = new(src, FALSE)
	else if(fly_state != SHUTTLE_IN_ATMOSPHERE)
		QDEL_NULL(transit_animation)
	if(to_transit)
		to_transit = FALSE
		next_fly_state = destination_fly_state
		return
	if(fly_state == SHUTTLE_ON_GROUND)
		TIMER_COOLDOWN_START(src, COOLDOWN_TADPOLE_LAUNCHING, launching_delay)
	if(fly_state != SHUTTLE_IN_ATMOSPHERE)
		return
	shuttle_port.assigned_transit.reserved_area.set_turf_type(/turf/open/space/transit/atmos)
	transit_animation?.reveal_ground()
	open_prompt = TRUE
	initialize_flight_position()
	build_ground_view()

///The action of taking off and sending the shuttle to the atmosphere
/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/take_off()
	shuttle_port = SSshuttle.getShuttle(shuttle_id)
	if((fly_state != SHUTTLE_ON_SHIP && fly_state != SHUTTLE_ON_GROUND) || shuttle_port?.mode != SHUTTLE_IDLE)
		return
	#ifndef TESTING
	if(!(shuttle_port.shuttle_flags & GAMEMODE_IMMUNE) && world.time < SSticker.round_start_time + SSticker.mode.deploy_time_lock)
		to_chat(ui_user, span_warning("The mothership is too far away from the theatre of operation, we cannot take off."))
		return
	#endif
	if(TIMER_COOLDOWN_RUNNING(src, COOLDOWN_TADPOLE_LAUNCHING))
		to_chat(ui_user, span_warning("The dropship's engines are not ready yet"))
		return
	var/current_personnel = 0
	var/current_vehicles = 0
	var/list/counted_humans = list()
	var/obj/docking_port/mobile/marine_dropship/minidropship/tadpole_port = shuttle_port
	if(istype(tadpole_port))
		for(var/turf/T in tadpole_port.return_turfs())
			if(!istype(T.loc, /area/shuttle/minidropship))
				continue
			for(var/obj/vehicle/sealed/V in T)
				current_vehicles++
				for(var/mob/living/carbon/human/H in V.occupants)
					if(!(H in counted_humans))
						counted_humans += H
			for(var/mob/living/carbon/human/H in T.GetAllContents())
				if(!(H in counted_humans))
					counted_humans += H
		current_personnel = counted_humans.len
		if(current_personnel > tadpole_port.max_personnel || current_vehicles > tadpole_port.max_vehicles)
			to_chat(ui_user, span_warning("ТАД перегружен! Взлёт невозможен! (Люди: [current_personnel]/[tadpole_port.max_personnel], Техника: [current_vehicles]/[tadpole_port.max_vehicles])"))
			return
	TIMER_COOLDOWN_START(src, COOLDOWN_TADPOLE_LAUNCHING, launching_delay) // To stop spamming
	shuttle_port.shuttle_computer = src
	//SEND_GLOBAL_SIGNAL(COMSIG_GLOB_TADPOLE_LAUNCHED)
	if(fly_state == SHUTTLE_ON_GROUND)
		next_fly_state = SHUTTLE_IN_ATMOSPHERE
		shuttle_port.callTime = SHUTTLE_TAKEOFF_GROUND_CALLTIME
	else
		to_transit = TRUE
		shuttle_port.callTime = SHUTTLE_TAKEOFF_SHIP_CALLTIME
		next_fly_state = SHUTTLE_IN_SPACE
		destination_fly_state = SHUTTLE_IN_ATMOSPHERE
	SSshuttle.moveShuttleToTransit(shuttle_id, TRUE)

///The action of sending the shuttle back to its shuttle port on main ship
/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/return_to_ship()
	shuttle_port = SSshuttle.getShuttle(shuttle_id)
	if(fly_state != SHUTTLE_IN_ATMOSPHERE || shuttle_port?.mode != SHUTTLE_IDLE)
		return
	var/obj/docking_port/stationary/hangar = SSshuttle.getDock(origin_port_id)
	if(!hangar || !shuttle_port.check_dock(hangar, TRUE))
		return
	shuttle_port.shuttle_computer = src
	SSshuttle.moveShuttleToDock(shuttle_id, hangar, TRUE)
	if(shuttle_port.mode != SHUTTLE_IGNITING || shuttle_port.destination != hangar)
		return
	to_transit = TRUE
	next_fly_state = SHUTTLE_IN_SPACE
	destination_fly_state = SHUTTLE_ON_SHIP
	open_prompt = FALSE
	clean_ui_user()
	var/initial_scale = transit_animation?.ground_scale() || 1
	QDEL_NULL(transit_animation)
	transit_animation = new(src, TRUE, initial_scale)

/obj/docking_port/mobile/marine_dropship/minidropship/check()
	. = ..()
	var/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/helm = shuttle_computer
	if(!istype(helm) || !helm.transit_animation)
		return
	if(!helm.transit_animation.revealing_ground && (mode == SHUTTLE_IDLE || mode == SHUTTLE_RECALL))
		QDEL_NULL(helm.transit_animation)
		return
	helm.transit_animation.refresh_viewers()

/// Manual only: moving the shuttle never changes the chosen shutter state.
/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/toggle_shutters()
	if(!shuttle_port)
		return
	var/list/shutters = list()
	var/should_open = FALSE
	for(var/turf/tile as anything in shuttle_port.return_turfs())
		for(var/obj/machinery/door/poddoor/shutters/transit/shutter in tile)
			shutters |= shutter
			if(shutter.density)
				should_open = TRUE
	for(var/obj/machinery/door/poddoor/shutters/transit/shutter as anything in shutters)
		if(should_open)
			INVOKE_ASYNC(shutter, TYPE_PROC_REF(/obj/machinery/door/poddoor, open))
		else
			INVOKE_ASYNC(shutter, TYPE_PROC_REF(/obj/machinery/door/poddoor, close))

/// Toggle the vision between small nightvision and turf vision
/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/toggle_nvg()
	if(!check_hovering_spot(eyeobj?.loc))
		to_chat(ui_user, span_warning("Can't toggle night vision mode in caves!"))
		return
	nvg_vision_mode = !nvg_vision_mode
	ui_user?.update_sight()

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/attack_alien(mob/living/carbon/xenomorph/xeno_attacker, damage_amount, damage_type, damage_flag, effects, armor_penetration, isrightclick)
	. = ..()
	if(machine_stat & BROKEN)
		return
	if(xeno_attacker.status_flags & INCORPOREAL)
		return
	xeno_attacker.visible_message("[xeno_attacker] begins to slash delicately at the computer",
	"We start slashing delicately at the computer. This will take a while.")
	if(!do_after(xeno_attacker, 10 SECONDS, NONE, src, BUSY_ICON_DANGER, BUSY_ICON_HOSTILE))
		return
	visible_message("The inner wiring is visible, it can be slashed!")
	xeno_attacker.visible_message("[xeno_attacker] continue to slash at the computer",
	"We continue slashing at the computer. If we stop now we will have to start all over again.")
	var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
	s.set_up(3, 1, src)
	s.start()
	if(!do_after(xeno_attacker, 10 SECONDS, NONE, src, BUSY_ICON_DANGER, BUSY_ICON_HOSTILE))
		return
	visible_message("The wiring is destroyed, nobody will be able to repair this computer!")
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_MINI_DROPSHIP_DESTROYED, src)
	var/datum/effect_system/spark_spread/s2 = new /datum/effect_system/spark_spread
	s2.set_up(3, 1, src)
	s2.start()
	set_broken()
	open_prompt = FALSE
	clean_ui_user()

	if(fly_state == SHUTTLE_IN_ATMOSPHERE && last_valid_ground_port)
		visible_message("Autopilot detects loss of helm control. INITIATING EMERGENCY LANDING!")
		shuttle_port.callTime = SHUTTLE_LANDING_CALLTIME
		next_fly_state = SHUTTLE_ON_GROUND
		shuttle_port.set_mode(SHUTTLE_CALL)
		SSshuttle.moveShuttleToDock(shuttle_id, last_valid_ground_port, TRUE)
		return

	if(next_fly_state == SHUTTLE_IN_ATMOSPHERE)
		shuttle_port.set_idle() // don't go up with a broken console, cencel spooling
		visible_message("Autopilot detects loss of helm control. Halting take off!")

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/can_interact(mob/user)
	if(machine_stat & BROKEN)
		to_chat(user, span_warning("The [src] blinks and lets out a crackling noise. Its broken!"))
		return
	return ..()

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/ui_state(mob/user)
	return GLOB.dropship_state

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(ui_user)
		return

	if(!ui)
		ui_user = user
		RegisterSignals(ui_user, list(COMSIG_QDELETING, COMSIG_MOVABLE_MOVED), PROC_REF(clean_ui_user))
		ui = new(user, src, "Minidropship", name)
		ui.open()

/// Set ui_user to null to prevent hard del
/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/clean_ui_user(datum/source)
	SIGNAL_HANDLER
	if(ui_user)
		SStgui.close_user_uis(ui_user, src) //Close the tadpole UI
		remove_eye_control(ui_user) //Boot the user out of the camera system
		UnregisterSignal(ui_user, list(COMSIG_QDELETING, COMSIG_MOVABLE_MOVED))
		ui_user = null

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/ui_data(mob/user)
	. = list()
	if(!shuttle_port)
		shuttle_port = SSshuttle.getShuttle(shuttle_id)
	.["fly_state"] = fly_state
	.["take_off_locked"] = ( !(fly_state == SHUTTLE_ON_GROUND || fly_state == SHUTTLE_ON_SHIP) || shuttle_port?.mode != SHUTTLE_IDLE)
	.["return_to_ship_locked"] = (fly_state != SHUTTLE_IN_ATMOSPHERE || shuttle_port?.mode != SHUTTLE_IDLE)
	var/obj/docking_port/mobile/marine_dropship/shuttle = shuttle_port
	.["equipment_data"] = list()
	var/element_nbr = 1
	for(var/X in shuttle?.equipments)
		var/obj/structure/dropship_equipment/E = X
		.["equipment_data"] += list(list("name"= sanitize(copytext(E.name,1,MAX_MESSAGE_LEN)), "eqp_tag" = element_nbr, "is_weapon" = (E.dropship_equipment_flags & IS_WEAPON), "is_interactable" = (E.dropship_equipment_flags & IS_INTERACTABLE)))
		element_nbr++

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	switch(action)
		if("take_off")
			take_off()
		if("return_to_ship")
			return_to_ship()
		if("toggle_nvg")
			toggle_nvg()
		if("toggle_shutters")
			toggle_shutters()
		if("equip_interact")
			var/base_tag = text2num(params["equip_interact"])
			var/obj/docking_port/mobile/marine_dropship/shuttle = shuttle_port
			var/obj/structure/dropship_equipment/E = shuttle.equipments[base_tag]
			E.linked_console = src
			E.equipment_interact(usr)

/datum/action/innate/shuttledocker_land
	name = "Land"
	action_icon = 'icons/mecha/actions_mecha.dmi'
	action_icon_state = "land"

/datum/action/innate/shuttledocker_land/Activate()
	var/mob/living/C = target
	if(!istype(C))
		return
	var/mob/camera/aiEye/remote/remote_eye = C.remote_control
	if(!istype(remote_eye))
		return
	var/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/origin = remote_eye.origin
	if(!istype(origin) || origin.current_user != C)
		return
	if(origin.shuttle_port.mode != SHUTTLE_IDLE)
		to_chat(owner, span_warning("The shuttle is not ready to land yet!"))
		return
	if(!origin.placeLandingSpot(target))
		to_chat(owner, span_warning("You cannot land here."))
		return
	if(is_ground_level(origin.z)) //Safety check to prevent instant transmission
		to_chat(owner, span_warning("The shuttle can't move while docked on the planet"))
		return
	var/area/landing_area = get_area(remote_eye)
	if(!(landing_area.area_flags & MARINE_BASE))
		SEND_GLOBAL_SIGNAL(COMSIG_GLOB_TADPOLE_LANDED_OUT_LZ)
	origin.shuttle_port.callTime = SHUTTLE_LANDING_CALLTIME
	origin.next_fly_state = SHUTTLE_ON_GROUND
	origin.open_prompt = FALSE
	SStgui.close_user_uis(C, origin)
	origin.shuttle_port.set_mode(SHUTTLE_CALL)
	origin.last_valid_ground_port = origin.my_port
	// Keep the terrain and light visible throughout the landing countdown.
	// shuttle_arrived() removes them once the real shuttle reaches the ground.
	origin.remove_eye_control(C)
	SSshuttle.moveShuttleToDock(origin.shuttle_id, origin.my_port, TRUE)

/obj/docking_port/mobile/marine_dropship/minidropship/canMove()
	. = ..()
	if(!.)
		return FALSE

	var/current_personnel = 0
	var/current_vehicles = 0
	var/list/counted_humans = list()
	for(var/turf/T in return_turfs())
		if(!istype(T.loc, /area/shuttle/minidropship))
			continue
		for(var/obj/vehicle/sealed/V in T)
			current_vehicles++
			for(var/mob/living/carbon/human/H in V.occupants)
				if(!(H in counted_humans))
					counted_humans += H
		for(var/mob/living/carbon/human/H in T.GetAllContents())
			if(!(H in counted_humans))
				counted_humans += H
	current_personnel = counted_humans.len

	var/limit_p = isnull(max_personnel) ? INFINITY : max_personnel
	var/limit_v = isnull(max_vehicles) ? INFINITY : max_vehicles

	if(current_personnel > limit_p || current_vehicles > limit_v)
		if(shuttle_computer)
			shuttle_computer.visible_message(span_warning("Внимание! Обнаружен перегруз (Людей: [current_personnel]/[limit_p], Техники: [current_vehicles]/[limit_v]). Взлёт отменён!"))
			playsound(shuttle_computer, 'sound/machines/buzz-sigh.ogg', 50, TRUE)

		mode = SHUTTLE_IDLE
		return FALSE

	return TRUE
