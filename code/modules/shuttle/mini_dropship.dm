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
	/// World-space holders rendering the ground below the actual transit shuttle.
	var/list/ground_holders = list()
	var/list/ground_movables = list()
	/// One native light-mask relay per source, shared by the entire lower scene.
	var/list/ground_lights = list()
	var/list/dirty_ground_tiles = list()
	var/obj/effect/abstract/tadpole_searchlight/ground_searchlight
	var/obj/effect/abstract/tadpole_ground_surface/ground_surface
	var/ground_origin_x
	var/ground_origin_y
	var/list/ground_tiles = list()
	var/list/ground_view_bounds
	var/next_ground_bounds = 0
	/// Round-robin terrain polling keeps periodic appearance checks bounded.
	var/ground_refresh_cursor = 0
	var/last_ground_x
	var/last_ground_y
	var/last_ground_heading
	var/last_ground_z
	var/list/last_ground_bounds
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
	clear_ground_view()
	fly_state = next_fly_state
	if(fly_state != SHUTTLE_IN_ATMOSPHERE && current_user)
		remove_eye_control(current_user)
	if(fly_state == SHUTTLE_IN_SPACE)
		shuttle_port.assigned_transit.reserved_area.set_turf_type(/turf/open/space/transit)
	if(to_transit)
		to_transit = FALSE
		next_fly_state = destination_fly_state
		return
	if(fly_state == SHUTTLE_ON_GROUND)
		TIMER_COOLDOWN_START(src, COOLDOWN_TADPOLE_LAUNCHING, launching_delay)
	if(fly_state != SHUTTLE_IN_ATMOSPHERE)
		return
	shuttle_port.assigned_transit.reserved_area.set_turf_type(/turf/open/space/transit/atmos)
	open_prompt = TRUE
	initialize_flight_position()
	build_ground_view()

///The action of taking off and sending the shuttle to the atmosphere
/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/take_off()
	shuttle_port = SSshuttle.getShuttle(shuttle_id)
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
	shuttle_port.shuttle_computer = src
	to_transit = TRUE
	next_fly_state = SHUTTLE_IN_SPACE
	destination_fly_state = SHUTTLE_ON_SHIP
	if(!origin_port_id)
		return
	open_prompt = FALSE
	clean_ui_user()
	SSshuttle.moveShuttle(shuttle_id, origin_port_id, TRUE)

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


/// A lower-level visual composited below the entire shuttle. Source appearances
/// must use FLOAT_PLANE: KEEP_TOGETHER alone does not capture explicit planes.
/// Never insert real ground atoms here; their planes can escape above the ship.
/obj/effect/abstract/tadpole_ground
	icon = null
	layer = FLOAT_LAYER
	blocks_emissive = EMISSIVE_BLOCK_NONE
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	// Tile containers must not form separate draw groups: a neighbouring
	// floor would then cover the overhang of a wide/tall object.
	appearance_flags = PIXEL_SCALE
	plane = TADPOLE_GROUND_PLANE
	var/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/flight_helm
	var/turf/displayed_turf
	var/next_refresh = 0
	var/view_turn = 0
	var/obj/effect/abstract/tadpole_ground_lighting/ground_lighting
	var/cached_static_light
	var/cached_ambient_light
	var/cached_static_lighting
	var/list/cached_ground_directions
	var/list/obj/effect/abstract/tadpole_ground_sprite/sprites = list()
	var/list/cached_ground_appearances
	var/list/cached_ground_visuals
	var/list/cached_ground_sources

/obj/effect/abstract/tadpole_ground/Destroy()
	for(var/atom/old_source as anything in cached_ground_sources)
		UnregisterSignal(old_source, list(COMSIG_ATOM_UPDATED_ICON, COMSIG_ATOM_DIR_CHANGE, COMSIG_QDELETING, COMSIG_MOVABLE_MOVED))
	if(flight_helm)
		flight_helm.dirty_ground_tiles -= displayed_turf
	if(displayed_turf)
		UnregisterSignal(displayed_turf, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_EXITED))
	flight_helm = null
	QDEL_NULL(ground_lighting)
	cached_static_light = null
	cached_ambient_light = null
	vis_contents.Cut()
	QDEL_LIST(sprites)
	displayed_turf = null
	cached_ground_directions = null
	cached_ground_appearances = null
	cached_ground_visuals = null
	cached_ground_sources = null
	return ..()

/obj/effect/abstract/tadpole_ground/proc/on_ground_entered(datum/source, atom/movable/arrived, atom/old_loc)
	SIGNAL_HANDLER
	if(tadpole_ground_tracks_movement(arrived))
		flight_helm?.track_ground_movable(arrived, old_loc)
	else
		mark_dirty()

/obj/effect/abstract/tadpole_ground/proc/on_ground_exited(datum/source, atom/movable/departed)
	SIGNAL_HANDLER
	forget_source(departed)

/obj/effect/abstract/tadpole_ground/proc/mark_dirty()
	next_refresh = 0
	if(flight_helm && displayed_turf)
		flight_helm.dirty_ground_tiles[displayed_turf] = TRUE

/obj/effect/abstract/tadpole_ground/proc/on_source_changed()
	SIGNAL_HANDLER
	mark_dirty()

/obj/effect/abstract/tadpole_ground/proc/on_static_moved(atom/movable/source)
	SIGNAL_HANDLER
	// Also listen on the atom: some turf Exited overrides omit the parent
	// signal, and portable scenery can be unanchored before its next poll.
	if(source.loc != displayed_turf)
		forget_source(source)
	else
		mark_dirty()

/obj/effect/abstract/tadpole_ground/proc/on_static_deleted(atom/source)
	SIGNAL_HANDLER
	if(ismovable(source))
		forget_source(source)
	mark_dirty()

/// Remove a departed static copy immediately, before a new motion anchor is
/// shown. Remaining geometry is rebuilt later within the same bounded budget.
/obj/effect/abstract/tadpole_ground/proc/forget_source(atom/movable/source)
	var/index = cached_ground_sources?.Find(source)
	if(!index)
		return
	var/obj/effect/abstract/tadpole_ground_sprite/departed_sprite = sprites[index]
	vis_contents -= departed_sprite
	sprites.Cut(index, index + 1)
	cached_ground_sources.Cut(index, index + 1)
	UnregisterSignal(source, list(COMSIG_ATOM_UPDATED_ICON, COMSIG_ATOM_DIR_CHANGE, COMSIG_QDELETING, COMSIG_MOVABLE_MOVED))
	qdel(departed_sprite)
	cached_ground_appearances = null
	mark_dirty()

/// A persistent motion anchor, independent of the cached terrain snapshots.
/// Only normalized visuals are relayed: real atoms keep their own world/planes.
/obj/effect/abstract/tadpole_mobile_anchor
	icon = null
	layer = FLOAT_LAYER
	blocks_emissive = EMISSIVE_BLOCK_NONE
	plane = FLOAT_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/helm
	var/atom/movable/source_atom
	var/obj/effect/abstract/tadpole_ground_sprite/sprite
	var/last_appearance
	var/list/last_visuals
	var/last_direction
	var/last_turn
	var/last_glide_duration = 0
	var/move_started = 0
	var/from_x = 0
	var/from_y = 0
	var/to_x = 0
	var/to_y = 0

/obj/effect/abstract/tadpole_mobile_anchor/Destroy()
	if(source_atom)
		UnregisterSignal(source_atom, list(COMSIG_MOVABLE_MOVED, COMSIG_QDELETING, COMSIG_ATOM_DIR_CHANGE, COMSIG_ATOM_UPDATED_ICON))
	if(helm)
		helm.ground_surface?.vis_contents.Remove(src)
		if(helm.ground_movables[source_atom] == src)
			helm.ground_movables -= source_atom
	helm = null
	source_atom = null
	last_visuals = null
	last_appearance = null
	vis_contents.Cut()
	QDEL_NULL(sprite)
	return ..()

/obj/effect/abstract/tadpole_mobile_anchor/proc/bind_movable(atom/movable/mobile, obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/owner, atom/old_loc)
	source_atom = mobile
	helm = owner
	sprite = new
	vis_contents += sprite
	var/turf/start = isturf(old_loc) && old_loc.z == mobile.z && get_dist(old_loc, mobile) <= 1 ? old_loc : get_turf(mobile)
	pixel_x = (start.x - helm.ground_origin_x) * world.icon_size
	pixel_y = (start.y - helm.ground_origin_y) * world.icon_size
	from_x = pixel_x
	from_y = pixel_y
	to_x = pixel_x
	to_y = pixel_y
	RegisterSignal(mobile, COMSIG_MOVABLE_MOVED, PROC_REF(on_source_moved))
	RegisterSignal(mobile, COMSIG_QDELETING, PROC_REF(on_source_deleted))
	RegisterSignal(mobile, COMSIG_ATOM_DIR_CHANGE, PROC_REF(on_source_dir))
	RegisterSignal(mobile, COMSIG_ATOM_UPDATED_ICON, PROC_REF(on_source_icon))
	sync_visual()

/obj/effect/abstract/tadpole_mobile_anchor/proc/sync_visual()
	if(!source_atom || !helm)
		return
	var/turn = 90 * round((SIMPLIFY_DEGREES(helm.flight_heading - dir2angle(helm.shuttle_port.dir)) + 45) / 90)
	var/list/visuals = tadpole_ground_visual_signature(source_atom)
	if(last_appearance != source_atom.appearance || last_direction != source_atom.dir || !tadpole_ground_same_list(visuals, last_visuals))
		var/offset = PLANE_RANGE * SSmapping.z_level_to_plane_offset[source_atom.z]
		var/mutable_appearance/picture = tadpole_ground_atom_appearance(source_atom, offset)
		picture.layer = tadpole_ground_layer(source_atom.appearance, offset)
		picture.appearance_flags = (picture.appearance_flags & ~TILE_BOUND) | KEEP_TOGETHER
		sprite.configure_source(source_atom, picture)
		sprite.set_view_turn(turn)
		last_appearance = source_atom.appearance
		last_visuals = visuals
		last_direction = source_atom.dir
		last_turn = turn
	else if(last_turn != turn)
		sprite.set_view_turn(turn)
		last_turn = turn
	// Let each client apply see_invisible instead of dropping all nonzero levels.
	sprite.invisibility = source_atom.invisibility
	var/angle = helm.flight_heading - dir2angle(helm.shuttle_port.dir)
	// Match the displayed glide, not the destination turf reached by Move().
	var/progress = last_glide_duration ? clamp((world.time - move_started) / last_glide_duration, 0, 1) : 1
	var/draw_x = from_x + (to_x - from_x) * progress
	var/draw_y = from_y + (to_y - from_y) * progress
	sprite.set_view_depth((draw_y * cos(angle) + draw_x * sin(angle)) / world.icon_size)

/obj/effect/abstract/tadpole_mobile_anchor/proc/on_source_moved(atom/movable/mobile, atom/old_loc, movement_dir, forced)
	SIGNAL_HANDLER
	if(!tadpole_ground_movable_visible(mobile) || mobile.z != helm.eyeobj.z)
		qdel(src)
		return
	sync_visual()
	var/turf/old_turf = get_turf(old_loc)
	// BYOND glides by glide_size pixels per tick on the dominant axis.
	// Forced/nonadjacent moves must remain teleports, just as on the ground.
	var/progress = last_glide_duration ? clamp((world.time - move_started) / last_glide_duration, 0, 1) : 1
	from_x += (to_x - from_x) * progress
	from_y += (to_y - from_y) * progress
	to_x = (mobile.x - helm.ground_origin_x) * world.icon_size
	to_y = (mobile.y - helm.ground_origin_y) * world.icon_size
	move_started = world.time
	last_glide_duration = (!forced || istype(mobile, /obj/vehicle)) && old_turf && old_turf.z == mobile.z && get_dist(old_turf, mobile) <= 1 ? world.icon_size / max(mobile.glide_size, 1) * world.tick_lag : 0
	animate(src, pixel_x = to_x, pixel_y = to_y, time = last_glide_duration, easing = LINEAR_EASING)
	sync_visual()

/// Changing the terrain origin must not interrupt an in-progress glide.
/obj/effect/abstract/tadpole_mobile_anchor/proc/rebase(shift_x, shift_y)
	var/progress = last_glide_duration ? clamp((world.time - move_started) / last_glide_duration, 0, 1) : 1
	var/remaining = max(0, last_glide_duration - (world.time - move_started))
	from_x += (to_x - from_x) * progress + shift_x
	from_y += (to_y - from_y) * progress + shift_y
	to_x += shift_x
	to_y += shift_y
	move_started = world.time
	last_glide_duration = remaining
	animate(src, pixel_x = from_x, pixel_y = from_y, time = 0)
	if(remaining)
		animate(pixel_x = to_x, pixel_y = to_y, time = remaining, easing = LINEAR_EASING)

/obj/effect/abstract/tadpole_mobile_anchor/proc/on_source_deleted()
	SIGNAL_HANDLER
	qdel(src)

/obj/effect/abstract/tadpole_mobile_anchor/proc/on_source_dir(atom/movable/mobile, old_dir, new_dir)
	SIGNAL_HANDLER
	// setDir sends its signal before assigning mobile.dir.
	sprite.source_direction = new_dir
	sprite.set_view_turn(last_turn)

/obj/effect/abstract/tadpole_mobile_anchor/proc/on_source_icon()
	SIGNAL_HANDLER
	sync_visual()

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/track_ground_movable(atom/movable/mobile, atom/old_loc)
	if(!ground_surface || !tadpole_ground_tracks_movement(mobile) || !tadpole_ground_movable_visible(mobile) || mobile.z != eyeobj.z || mobile.plane + PLANE_RANGE * SSmapping.z_level_to_plane_offset[mobile.z] >= LIGHTING_PLANE)
		return
	if(ground_movables[mobile])
		return
	var/obj/effect/abstract/tadpole_mobile_anchor/anchor = new
	ground_movables[mobile] = anchor
	ground_surface.vis_contents += anchor
	anchor.bind_movable(mobile, src, old_loc)

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/update_ground_movables()
	for(var/atom/movable/mobile as anything in ground_movables.Copy())
		var/obj/effect/abstract/tadpole_mobile_anchor/anchor = ground_movables[mobile]
		if(QDELETED(mobile) || !tadpole_ground_tracks_movement(mobile) || !tadpole_ground_movable_visible(mobile) || !ground_movable_in_view(mobile))
			qdel(anchor)
			continue
		anchor.sync_visual()

/// A multi-tile vehicle can still overlap the viewport after its root turf
/// leaves it. Native vis_contents sees the occupied turfs, so do the same.
/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/ground_movable_in_view(atom/movable/mobile)
	if(ground_holders[mobile.loc])
		return TRUE
	for(var/turf/occupied as anything in mobile.locs)
		if(ground_holders[occupied])
			return TRUE
	return FALSE

/// Native movable light placed on the lower map. This is a real light source,
/// so observers on the ground see the beam and normal wall occlusion applies.
/obj/effect/abstract/tadpole_searchlight
	icon = null
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	blocks_emissive = EMISSIVE_BLOCK_NONE
	atom_flags = SHUTTLE_IMMUNE|PREVENT_CONTENTS_EXPLOSION
	// Moving a static source invalidates hundreds of corner underlays, dirtying
	// both the real map and terrain snapshots. Hybrid light uses a moving mask.
	light_system = HYBRID_LIGHT
	light_range = 9
	light_power = 8
	light_color = COLOR_WHITE

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/update_ground_searchlight()
	if(fly_state != SHUTTLE_IN_ATMOSPHERE || !eyeobj?.z || !shuttle_port)
		return
	var/list/bounds = shuttle_port.return_coords(shuttle_port.x, shuttle_port.y, shuttle_port.dir)
	var/dx = (bounds[1] + bounds[3]) / 2 - shuttle_port.x
	var/dy = (bounds[2] + bounds[4]) / 2 - shuttle_port.y
	var/angle = flight_heading - dir2angle(shuttle_port.dir)
	var/turf/target = locate(round(flight_x + dx * cos(angle) + dy * sin(angle) + 0.5), round(flight_y + dy * cos(angle) - dx * sin(angle) + 0.5), eyeobj.z)
	if(!target)
		return
	if(!ground_searchlight)
		ground_searchlight = new(target)
	else if(get_turf(ground_searchlight) != target)
		ground_searchlight.forceMove(target)

/// Retain the native static-light appearance. SSlighting has already calculated
/// its corner colours; the flight controller must never calculate them again.
/obj/effect/abstract/tadpole_ground/proc/update_ground_lighting(turf/source)
	var/area/region = source.loc
	var/mutable_appearance/static_light = source.static_lighting_object?.current_underlay
	var/mutable_appearance/ambient = LAZYACCESS(region.lighting_effects, GET_TURF_PLANE_OFFSET(source) + 1)
	var/static_picture = static_light?.appearance
	var/ambient_picture = ambient?.appearance
	if(ground_lighting && cached_static_light == static_picture && cached_ambient_light == ambient_picture && cached_static_lighting == region.static_lighting)
		return FALSE
	cached_static_light = static_picture
	cached_ambient_light = ambient_picture
	cached_static_lighting = region.static_lighting
	if(!ground_lighting)
		ground_lighting = new
		if(flight_helm)
			SET_PLANE(ground_lighting, TADPOLE_GROUND_LIGHTING_PLANE, flight_helm)
		vis_contents += ground_lighting
	ground_lighting.overlays.Cut()
	// Native light planes have a white backdrop; the static underlay supplies
	// darkness. An uninitialised static tile must stay dark instead of flashing.
	ground_lighting.color = static_light || !region.static_lighting ? COLOR_WHITE : COLOR_BLACK
	if(static_light)
		var/mutable_appearance/light = new(static_light)
		light.plane = FLOAT_PLANE
		light.layer = FLOAT_LAYER
		light.appearance_flags &= ~RESET_TRANSFORM
		ground_lighting.overlays += light
	if(ambient)
		var/mutable_appearance/light = new(ambient)
		light.plane = FLOAT_PLANE
		light.layer = FLOAT_LAYER
		light.appearance_flags &= ~RESET_TRANSFORM
		ground_lighting.overlays += light
	return TRUE

/// The light pass is separate from geometry, like the native multiz plates.
/// KEEP_APART is required: these children must escape the geometry surface
/// KEEP_TOGETHER group before the lighting plane can collect them.
/// Native additive light masks are combined first, then the plane master
/// multiplies the resulting light image onto the lower scene exactly once.
/obj/effect/abstract/tadpole_ground_lighting
	icon = 'icons/effects/alphacolors.dmi'
	icon_state = "white"
	plane = TADPOLE_GROUND_LIGHTING_PLANE
	layer = TOPDOWN_LAYER + 9000
	appearance_flags = KEEP_APART | KEEP_TOGETHER | PIXEL_SCALE | RESET_COLOR
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	blocks_emissive = EMISSIVE_BLOCK_NONE
	anchored = TRUE

/obj/effect/abstract/tadpole_light_relay
	plane = TADPOLE_GROUND_LIGHTING_PLANE
	layer = TOPDOWN_LAYER + 9500
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	blocks_emissive = EMISSIVE_BLOCK_NONE
	var/last_light_appearance

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/update_ground_lights()
	var/list/needed = list()
	for(var/turf/lower as anything in ground_holders)
		var/obj/effect/abstract/tadpole_ground/holder = ground_holders[lower]
		holder.update_ground_lighting(lower)
		for(var/atom/movable/lighting_mask/light as anything in lower.hybrid_lights_affecting)
			needed[light] = TRUE
	for(var/atom/movable/lighting_mask/light as anything in ground_lights.Copy())
		if(!needed[light] || QDELETED(light))
			ground_surface.vis_contents -= ground_lights[light]
			qdel(ground_lights[light])
			ground_lights -= light
	for(var/atom/movable/lighting_mask/light as anything in needed)
		if(QDELETED(light) || !light.attached_atom)
			continue
		var/obj/effect/abstract/tadpole_light_relay/relay = ground_lights[light]
		if(!relay)
			relay = new
			ground_lights[light] = relay
			ground_surface.vis_contents += relay
		if(relay.last_light_appearance != light.appearance)
			relay.last_light_appearance = light.appearance
			var/mutable_appearance/picture = new(light.appearance)
			picture.plane = MUTATE_PLANE(TADPOLE_GROUND_LIGHTING_PLANE, src)
			picture.layer = TOPDOWN_LAYER + 9500
			picture.invisibility = 0
			picture.appearance_flags = (picture.appearance_flags & ~RESET_TRANSFORM) | KEEP_APART | KEEP_TOGETHER
			// Keep the native shadow triangles and alpha filter, but namespace
			// their target so this lower scene cannot shadow the real shuttle.
			var/shadow_target = "*tadpole_shadow_[REF(src)]"
			picture.overlays = list()
			for(var/overlay as anything in light.overlays)
				var/mutable_appearance/shadow = new(overlay)
				if(shadow.render_target == SHADOW_RENDER_TARGET)
					shadow.render_target = shadow_target
				shadow.plane = FLOAT_PLANE
				picture.overlays += shadow
			picture.filters = null
			relay.appearance = picture
			relay.add_filter("pixel_smoother", 3, gauss_blur_filter(2))
			relay.add_filter("shadow_alpha_masking", 4, alpha_mask_filter(render_source = shadow_target, flags = MASK_INVERSE))
			relay.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		var/turf/position = get_turf(light.attached_atom)
		relay.pixel_x = (position.x - ground_origin_x) * world.icon_size + light.pixel_x
		relay.pixel_y = (position.y - ground_origin_y) * world.icon_size + light.pixel_y

/// Each original atom has its own direction and local overlay hierarchy.
/// A mutable appearance used directly as another atom's overlay may inherit
/// that atom's direction; a separate movable retains its actual dir.
/obj/effect/abstract/tadpole_ground_sprite
	blocks_emissive = EMISSIVE_BLOCK_NONE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = FLOAT_PLANE
	appearance_flags = KEEP_TOGETHER | PIXEL_SCALE
	var/source_direction = SOUTH
	var/matrix/source_transform
	var/mutable_appearance/source_picture
	var/source_junction = 0
	var/source_smoothing_flags = 0
	var/source_base_state
	var/source_weeds_state = FALSE
	var/source_weeds_suffix = ""
	var/list/source_corners
	var/source_plane = GAME_PLANE
	var/source_layer = MOB_LAYER
	var/view_depth = 0
	var/source_width = 32
	var/source_height = 32
	var/alternate_door_icon

/// Select the DMI direction relative to the viewer and cancel the cardinal
/// portion of the surface rotation. Quarter-turns preserve square tile edges;
/// cancelling arbitrary angles on floors would open gaps in the terrain grid.
/// Smoothing bitmasks use separate bits for diagonal neighbours. BYOND turn()
/// only rotates direction constants, so rotate each junction explicitly.
/proc/tadpole_rotate_junction(junction, angle)
	var/static/list/dirs = list(NORTH, SOUTH, EAST, WEST, NORTHEAST, SOUTHEAST, SOUTHWEST, NORTHWEST)
	var/static/list/bits = list(NORTH_JUNCTION, SOUTH_JUNCTION, EAST_JUNCTION, WEST_JUNCTION, NORTHEAST_JUNCTION, SOUTHEAST_JUNCTION, SOUTHWEST_JUNCTION, NORTHWEST_JUNCTION)
	var/result = 0
	for(var/i in 1 to 8)
		if(junction & bits[i])
			var/rotated_dir = turn(dirs[i], angle)
			result |= bits[dirs.Find(rotated_dir)]
	return result

/obj/effect/abstract/tadpole_ground_sprite/proc/configure_source(atom/source, mutable_appearance/picture)
	source_picture = picture
	source_plane = source.plane + PLANE_RANGE * SSmapping.z_level_to_plane_offset[source.z]
	source_layer = source.layer
	source_direction = source.dir
	source_transform = picture.transform
	source_smoothing_flags = source.smoothing_flags
	source_base_state = source.base_icon_state
	if(source_smoothing_flags & SMOOTH_CORNERS)
		source_junction = source.calculate_adjacencies()
		source_corners = list(source.top_left_corner, source.top_right_corner, source.bottom_left_corner, source.bottom_right_corner)
	else
		source_junction = source.smoothing_junction
	// Wall weeds borrow their host wall/window junction via icon_state.
	// Their own smoothing_flags/junction are deliberately unset.
	if(istype(source, /obj/alien/weeds/weedwall))
		source_base_state = "weedwall"
		if(copytext(source.icon_state, 1, 10) == "weedwall-")
			source_smoothing_flags = SMOOTH_BITMASK
			source_junction = text2num(copytext(source.icon_state, 10))
	// Ordinary weeds and nodes encode adjacency in weed_dirN rather than
	// smoothing_junction. Keep sticky/resting colour suffixes unchanged.
	if(istype(source, /obj/alien/weeds) && copytext(source.icon_state, 1, 9) == "weed_dir")
		var/obj/alien/weeds/weeds = source
		source_weeds_state = TRUE
		source_weeds_suffix = weeds.color_variant
		source_junction = text2num(copytext(source.icon_state, 9, length(source.icon_state) - length(source_weeds_suffix) + 1))
	if(ismovable(source))
		var/atom/movable/movable_source = source
		source_width = movable_source.bound_width
		source_height = movable_source.bound_height
	// Some blast doors have separate horizontal/vertical DMI files with only
	// one direction each. A dir change alone cannot select the other footprint.
	if(istype(source, /obj/machinery/door/poddoor) && (source_width > 32 || source_height > 32))
		var/path = "[source.icon]"
		var/other_path = findtext(path, "_hor") ? replacetext(path, "_hor", "_vert") : replacetext(path, "_vert", "_hor")
		if(other_path != path && fexists(other_path))
			alternate_door_icon = file(other_path)

/obj/effect/abstract/tadpole_ground_sprite/proc/set_view_turn(cardinal_turn)
	if(source_picture)
		appearance = source_picture
	dir = turn(source_direction, cardinal_turn)
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/junction = tadpole_rotate_junction(source_junction, cardinal_turn)
	if(source_weeds_state)
		icon_state = "weed_dir[junction][source_weeds_suffix]"
	else if(source_smoothing_flags & SMOOTH_BITMASK)
		// Preserve non-smoothed states, such as a flipped or broken table.
		if(source_base_state && copytext(icon_state, 1, length(source_base_state) + 2) == "[source_base_state]-")
			var/suffix = copytext(icon_state, -2) == "-d" ? "-d" : ""
			icon_state = "[source_base_state]-[junction][suffix]"
	else if(source_smoothing_flags & SMOOTH_CORNERS)
		// Reuse the real smoothing builders on the visual proxy only. The
		// source map's topology, appearance and smoothing queue are untouched.
		top_left_corner = source_corners[1]
		top_right_corner = source_corners[2]
		bottom_left_corner = source_corners[3]
		bottom_right_corner = source_corners[4]
		clear_smooth_overlays()
		if(source_smoothing_flags & SMOOTH_DIAGONAL_CORNERS)
			corners_diagonal_smooth(junction)
		else
			corners_cardinal_smooth(junction)
	if(alternate_door_icon && (SIMPLIFY_DEGREES(cardinal_turn) % 180))
		icon = alternate_door_icon
	var/matrix/correction = source_transform ? matrix(source_transform) : matrix()
	correction.Turn(cardinal_turn)
	// DMI origins remain bottom-left even when a multi-tile footprint turns.
	// Rotate its occupied cells, then anchor the selected DMI at their minimum
	// screen x/y instead of incorrectly keeping the old leading tile.
	if(SIMPLIFY_DEGREES(cardinal_turn))
		var/c = cos(cardinal_turn)
		var/s = sin(cardinal_turn)
		var/w = max(0, source_width - world.icon_size)
		var/h = max(0, source_height - world.icon_size)
		var/min_x = min(0, w * c, -h * s, w * c - h * s)
		var/min_y = min(0, w * s, h * c, w * s + h * c)
		// BYOND transforms pivot around the full DMI canvas centre, not
		// the origin tile centre. Account for that before moving the origin.
		var/list/dimensions = icon ? get_icon_dimensions(icon) : null
		var/center_x = (dimensions ? (dimensions["width"] - world.icon_size) / 2 : 0) + pixel_x + pixel_w
		var/center_y = (dimensions ? (dimensions["height"] - world.icon_size) / 2 : 0) + pixel_y + pixel_z
		min_x += center_x - (center_x * c - center_y * s)
		min_y += center_y - (center_y * c + center_x * s)
		correction.Translate(min_x * c + min_y * s, min_y * c - min_x * s)
	transform = correction
	set_view_depth(view_depth)

/// The composite is rendered as a single plane, so reproduce SIDE_MAP depth
/// explicitly. Floors are a separate back layer; walls, props and mobs share
/// a depth band. A plane-based bank would put every mob above every wall.
/// ALL composite bands must use TOPDOWN_LAYER: otherwise SIDE_MAP sorts
/// their pixel_y/bounds before layer and neighbouring tiles cut large sprites.
/proc/tadpole_ground_depth_layer(source_plane, source_layer, view_depth)
	if(source_plane <= FLOOR_PLANE || source_layer >= TOPDOWN_LAYER)
		return TOPDOWN_LAYER + 1000 + (source_layer >= TOPDOWN_LAYER ? (source_layer - TOPDOWN_LAYER) / 100 : source_layer)
	if(source_layer >= EFFECTS_LAYER)
		return TOPDOWN_LAYER + 7000 + source_layer / 100
	return TOPDOWN_LAYER + 4000 - view_depth * 16 + source_layer

/obj/effect/abstract/tadpole_ground_sprite/proc/set_view_depth(new_depth)
	view_depth = new_depth
	layer = tadpole_ground_depth_layer(source_plane, source_layer, view_depth)

/obj/effect/abstract/tadpole_ground/proc/set_view_depth(view_depth)
	for(var/obj/effect/abstract/tadpole_ground_sprite/sprite as anything in sprites)
		sprite.set_view_depth(view_depth)

/// Loose items, vehicles and projectiles need persistent motion just like mobs.
/// Anchored scenery stays in the bounded geometry cache instead of adding
/// per-frame work for every wall, table and door in view.
/proc/tadpole_ground_tracks_movement(atom/movable/source)
	return ismob(source) || istype(source, /atom/movable/projectile) || istype(source, /obj/vehicle) || (isobj(source) && !source.anchored)

/// Do not expose a mob whose real anchor is inside an opaque closed turf.
/proc/tadpole_ground_movable_visible(atom/movable/mobile)
	if(!mobile || mobile.invisibility >= INVISIBILITY_ABSTRACT || !isturf(mobile.loc))
		return FALSE
	var/turf/location = mobile.loc
	return !(isclosedturf(location) && location.density && location.opacity)

/obj/effect/abstract/tadpole_ground/proc/set_view_turn(cardinal_turn)
	if(view_turn == cardinal_turn)
		return
	view_turn = cardinal_turn
	for(var/obj/effect/abstract/tadpole_ground_sprite/sprite as anything in sprites)
		sprite.set_view_turn(cardinal_turn)

/// Map original planes into sortable layers before the final composite. This
/// keeps ALL floors below ALL walls/objects, including multi-tile overhangs.
/proc/tadpole_ground_layer(source, plane_offset)
	var/mutable_appearance/original = new(source)
	var/local_layer = original.layer
	if(local_layer >= TOPDOWN_LAYER)
		local_layer = (local_layer - TOPDOWN_LAYER) / 100
	return TOPDOWN_LAYER + (original.plane + plane_offset - PLANE_SPACE + 1) * 100 + local_layer

/// Assemble an axis-aligned lower level first, then rotate this ONE image.
/// Rotating separate tile sprites produces cracks and visibility holes.
/obj/effect/abstract/tadpole_ground_surface
	icon = null
	layer = TOPDOWN_LAYER + 1
	blocks_emissive = EMISSIVE_BLOCK_NONE
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = KEEP_TOGETHER | PIXEL_SCALE
	plane = TADPOLE_GROUND_GEOMETRY_PLANE

/obj/effect/abstract/tadpole_ground_surface/Destroy()
	vis_contents.Cut()
	return ..()

/// Flatten the lower level's explicit planes, including nested overlays. The
/// actual source atoms and their plane masters are never modified.
/proc/tadpole_ground_appearance(source, plane_offset)
	var/mutable_appearance/result = new(source)
	result.plane = FLOAT_PLANE
	if(result.layer >= TOPDOWN_LAYER)
		result.layer = (result.layer - TOPDOWN_LAYER) / 100
	result.appearance_flags &= ~(KEEP_APART | RESET_TRANSFORM)
	// Private render targets (notably hair/wound alpha masks on corpses)
	// must stay hidden. Clearing the target exposes their white mask pixels;
	// clearing render_source also disconnects the corresponding filter graph.
	// Keep both names with their original filter references in the snapshot.
	result.overlays = list()
	result.underlays = list()
	var/mutable_appearance/original = new(source)
	for(var/child as anything in original.overlays)
		var/mutable_appearance/appearance = new(child)
		if(appearance.plane != FLOAT_PLANE && appearance.plane + plane_offset >= LIGHTING_PLANE)
			continue
		result.overlays += tadpole_ground_appearance(child, plane_offset)
	for(var/child as anything in original.underlays)
		var/mutable_appearance/appearance = new(child)
		if(appearance.plane != FLOAT_PLANE && appearance.plane + plane_offset >= LIGHTING_PLANE)
			continue
		result.underlays += tadpole_ground_appearance(child, plane_offset)
	return result

/proc/tadpole_ground_vis_contents(atom/source)
	if(isturf(source))
		var/turf/tile = source
		return tile.vis_contents
	if(ismovable(source))
		var/atom/movable/movable = source
		return movable.vis_contents
	return null

/// Native multiz relays actual vis_contents, not just atom.appearance.
/// Include attached visuals (canopies, cables, wounds, shields) in the snapshot
/// without exposing the real lower-level atoms to the shuttle's plane graph.
/proc/tadpole_ground_atom_appearance(atom/source, plane_offset, base_appearance, list/seen, inherited_dir)
	var/list/children = tadpole_ground_vis_contents(source)
	var/mutable_appearance/result = tadpole_ground_appearance(isnull(base_appearance) ? source.appearance : base_appearance, plane_offset)
	if(!isnull(inherited_dir))
		result.dir = inherited_dir
	if(!length(children))
		return result
	if(!seen)
		seen = list()
	if((source in seen) || length(seen) >= 16)
		return result
	seen += source
	for(var/atom/movable/child in children)
		if(QDELETED(child) || (child in seen) || child.invisibility || (child.vis_flags & VIS_HIDE))
			continue
		var/child_offset = child.z ? PLANE_RANGE * SSmapping.z_level_to_plane_offset[child.z] : 0
		if(child.plane != FLOAT_PLANE && !(child.vis_flags & VIS_INHERIT_PLANE) && child.plane + child_offset >= LIGHTING_PLANE)
			continue
		var/mutable_appearance/child_base = new(child.appearance)
		if(child.vis_flags & VIS_INHERIT_ICON)
			child_base.icon = result.icon
		if(child.vis_flags & VIS_INHERIT_ICON_STATE)
			child_base.icon_state = result.icon_state
		var/mutable_appearance/picture = tadpole_ground_atom_appearance(child, child_offset, child_base, seen, (child.vis_flags & VIS_INHERIT_DIR) ? result.dir : child.dir)
		if(child.vis_flags & VIS_INHERIT_LAYER)
			picture.layer = FLOAT_LAYER
		if(child.vis_flags & VIS_UNDERLAY)
			result.underlays += picture
		else
			result.overlays += picture
	seen -= source
	return result

/// Cheap immutable revision data; do not rebuild unchanged attachment trees.
/proc/tadpole_ground_visual_signature(atom/source, list/result, list/seen)
	var/list/children = tadpole_ground_vis_contents(source)
	if(!result && !length(children))
		return null
	if(!result)
		result = list()
	if(!length(children))
		return result
	if(!seen)
		seen = list()
	if((source in seen) || length(seen) >= 16)
		return result
	seen += source
	result += list(source, length(children))
	for(var/atom/movable/child in children)
		if(QDELETED(child) || (child in seen))
			continue
		result += list(child, child.appearance, child.vis_flags, child.invisibility)
		tadpole_ground_visual_signature(child, result, seen)
	seen -= source
	return result

/proc/tadpole_ground_same_list(list/left, list/right)
	if(length(left) != length(right))
		return FALSE
	for(var/i in 1 to length(left))
		if(left[i] != right[i])
			return FALSE
	return TRUE

/// Terrain geometry must not depend on lighting underlays. SSlighting changes
/// these whenever a light moves, even when the floor and its props are static.
/// Strip only top-level light/emissive passes here; recursive normalization is
/// still performed only when actual geometry or a visible overlay changes.
/proc/tadpole_ground_geometry(turf/source, plane_offset)
	var/mutable_appearance/picture = new(source.appearance)
	var/list/visible_overlays = list()
	var/list/visible_underlays = list()
	for(var/child as anything in picture.overlays)
		var/mutable_appearance/layer = new(child)
		if(layer.plane == FLOAT_PLANE || layer.plane + plane_offset < LIGHTING_PLANE)
			visible_overlays += child
	for(var/child as anything in picture.underlays)
		var/mutable_appearance/layer = new(child)
		if(layer.plane == FLOAT_PLANE || layer.plane + plane_offset < LIGHTING_PLANE)
			visible_underlays += child
	picture.overlays = visible_overlays
	picture.underlays = visible_underlays
	return picture.appearance

/obj/effect/abstract/tadpole_ground/proc/refresh_ground(turf/source)
	if(flight_helm && source != displayed_turf)
		if(displayed_turf)
			UnregisterSignal(displayed_turf, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_EXITED))
		RegisterSignal(source, COMSIG_ATOM_ENTERED, PROC_REF(on_ground_entered))
		RegisterSignal(source, COMSIG_ATOM_EXITED, PROC_REF(on_ground_exited))
	var/offset = PLANE_RANGE * SSmapping.z_level_to_plane_offset[source.z]
	var/list/source_appearances = list(tadpole_ground_geometry(source, offset))
	var/list/source_directions = list(source.dir)
	var/list/source_atoms = list(source)
	for(var/atom/movable/thing in source)
		// A bounded atom occurs in every turf it occupies. Draw its complete
		// sprite exactly once at its real loc, not once per occupied turf.
		if(thing.invisibility >= INVISIBILITY_ABSTRACT || thing.plane + offset >= LIGHTING_PLANE)
			continue
		if(flight_helm && tadpole_ground_tracks_movement(thing))
			flight_helm.track_ground_movable(thing)
			continue
		if(thing.loc != source)
			continue
		source_appearances += thing.appearance
		source_directions += thing.dir
		source_atoms += thing
	var/list/source_visuals = list()
	for(var/atom/source_atom as anything in source_atoms)
		source_visuals += list(source_atom, source_atom.invisibility)
		tadpole_ground_visual_signature(source_atom, source_visuals)
	// Appearances are immutable values. Check their identities before doing
	// recursive flattening or dirtying the holder for SendMaps().
	var/unchanged = displayed_turf == source && length(cached_ground_appearances) == length(source_appearances) && tadpole_ground_same_list(source_visuals, cached_ground_visuals)
	if(unchanged)
		for(var/i in 1 to length(source_appearances))
			if(source_appearances[i] != cached_ground_appearances[i] || source_directions[i] != cached_ground_directions[i])
				unchanged = FALSE
				break
	next_refresh = world.time + 0.5 SECONDS + ((source.x + source.y) % 3)
	if(unchanged)
		return FALSE
	displayed_turf = source
	cached_ground_appearances = source_appearances
	cached_ground_directions = source_directions
	cached_ground_visuals = source_visuals
	for(var/atom/old_source as anything in cached_ground_sources)
		UnregisterSignal(old_source, list(COMSIG_ATOM_UPDATED_ICON, COMSIG_ATOM_DIR_CHANGE, COMSIG_QDELETING, COMSIG_MOVABLE_MOVED))
	cached_ground_sources = source_atoms
	for(var/atom/new_source as anything in cached_ground_sources)
		RegisterSignals(new_source, list(COMSIG_ATOM_UPDATED_ICON, COMSIG_ATOM_DIR_CHANGE), PROC_REF(on_source_changed))
		RegisterSignal(new_source, COMSIG_QDELETING, PROC_REF(on_static_deleted))
		RegisterSignal(new_source, COMSIG_MOVABLE_MOVED, PROC_REF(on_static_moved))
	vis_contents.Cut()
	if(ground_lighting)
		vis_contents += ground_lighting
	QDEL_LIST(sprites)
	for(var/i in 1 to length(source_appearances))
		var/obj/effect/abstract/tadpole_ground_sprite/sprite = new
		var/mutable_appearance/picture = tadpole_ground_atom_appearance(source_atoms[i], offset, source_appearances[i])
		picture.layer = tadpole_ground_layer(source_appearances[i], offset)
		picture.appearance_flags = (picture.appearance_flags & ~TILE_BOUND) | KEEP_TOGETHER
		sprite.appearance = picture
		sprite.configure_source(source_atoms[i], picture)
		sprite.invisibility = source_atoms[i]:invisibility
		sprite.set_view_turn(view_turn)
		sprite.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		sprites += sprite
		vis_contents += sprite
	return TRUE

/// Independent of the relatively slow machinery subsystem. BYOND interpolates
/// each 0.2-second physics step, including fractional position and rotation.
/datum/tadpole_flight_controller
	var/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/helm
	var/last_process_time

/datum/tadpole_flight_controller/New(obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/owner)
	helm = owner
	last_process_time = world.time

/datum/tadpole_flight_controller/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	helm = null
	return ..()

/datum/tadpole_flight_controller/process(seconds_per_tick)
	if(QDELETED(helm) || helm.fly_state != SHUTTLE_IN_ATMOSPHERE)
		return PROCESS_KILL
	var/input = NONE
	if(helm.current_user?.client && !helm.current_user.incapacitated(TRUE) && helm.Adjacent(helm.current_user))
		var/client/pilot_client = helm.current_user.client
		if(!pilot_client.movement_locked)
			input = pilot_client.intended_direction
	else if(helm.current_user)
		helm.remove_eye_control(helm.current_user)
	var/elapsed = clamp((world.time - last_process_time) / 10, 0, 0.5)
	last_process_time = world.time
	helm.advance_flight(elapsed, input)
	helm.update_ground_searchlight()
	helm.update_ground_view(seconds_per_tick)

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/advance_flight(dt, input)
	if(fly_state != SHUTTLE_IN_ATMOSPHERE || shuttle_port?.mode != SHUTTLE_IDLE || isnull(flight_x))
		return
	dt = clamp(dt, 0, 0.5)
	// The docking-port heading points aft; forward thrust follows the nose.
	var/thrust = ((input & SOUTH) ? 1 : 0) - ((input & NORTH) ? 1 : 0)
	var/steering = ((input & EAST) ? 1 : 0) - ((input & WEST) ? 1 : 0)
	flight_turn_velocity = clamp(flight_turn_velocity + steering * 100 * dt, -55, 55)
	flight_turn_velocity *= 0.18 ** dt
	flight_heading = SIMPLIFY_DEGREES(flight_heading + flight_turn_velocity * dt)
	flight_velocity_x += sin(flight_heading) * thrust * 4 * dt
	flight_velocity_y += cos(flight_heading) * thrust * 4 * dt
	// Drag slows the aircraft gradually after key release; thrust in the
	// opposite direction brakes before it starts accelerating backwards.
	flight_velocity_x *= 0.65 ** dt
	flight_velocity_y *= 0.65 ** dt
	if(abs(flight_velocity_x) < 0.01)
		flight_velocity_x = 0
	if(abs(flight_velocity_y) < 0.01)
		flight_velocity_y = 0
	if(abs(flight_turn_velocity) < 0.01)
		flight_turn_velocity = 0
	var/speed = sqrt(flight_velocity_x ** 2 + flight_velocity_y ** 2)
	if(speed > 7)
		flight_velocity_x *= 7 / speed
		flight_velocity_y *= 7 / speed
	var/next_x = flight_x + flight_velocity_x * dt
	var/next_y = flight_y + flight_velocity_y * dt
	flight_x = clamp(next_x, 11, world.maxx - 11)
	flight_y = clamp(next_y, 11, world.maxy - 11)
	if(flight_x != next_x)
		flight_velocity_x = 0
	if(flight_y != next_y)
		flight_velocity_y = 0
	// Landing remains tile based. Rotate its footprint only when crossing
	// the nearest cardinal heading; visual flight never snaps to this value.
	var/landing_dir = turn(NORTH, -90 * round((flight_heading + 45) / 90))
	for(var/i in 1 to 3)
		if(eyeobj.dir == landing_dir)
			break
		rotateLandingSpot()
	var/turf/landing_turf = locate(round(flight_x + 0.5), round(flight_y + 0.5), eyeobj.z)
	if(get_turf(eyeobj) != landing_turf)
		eyeobj.abstract_move(landing_turf)
		checkLandingSpot()

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/initialize_flight_position()
	if(!eyeobj)
		CreateEye()
	if(!eyeobj || !length(z_lock))
		return
	if(eyeobj.z in z_lock)
		return
	var/turf/position
	if(last_valid_ground_port && is_ground_level(last_valid_ground_port.z))
		position = get_turf(last_valid_ground_port)
	else
		position = locate(round(world.maxx * 0.5), round(world.maxy * 0.5), z_lock[1])
	eyeobj.abstract_move(position)
	eyeobj.eye_initialized = TRUE

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/clear_ground_view()
	if(flight_controller)
		STOP_PROCESSING(SSfastprocess, flight_controller)
	for(var/turf/tile as anything in ground_tiles)
		if(istype(tile, /turf/open/space/transit/atmos))
			tile.update_appearance()
	ground_tiles.Cut()
	ground_view_bounds = null
	last_ground_bounds = null
	next_ground_bounds = 0
	last_ground_x = null
	last_ground_y = null
	last_ground_heading = null
	last_ground_z = null
	for(var/atom/movable/mobile as anything in ground_movables.Copy())
		qdel(ground_movables[mobile])
	ground_movables.Cut()
	dirty_ground_tiles.Cut()
	QDEL_NULL(ground_searchlight)
	QDEL_LIST_ASSOC_VAL(ground_lights)
	QDEL_NULL(ground_surface)
	QDEL_LIST_ASSOC_VAL(ground_holders)
	flight_velocity_x = 0
	flight_velocity_y = 0
	flight_turn_velocity = 0

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/build_ground_view()
	clear_ground_view()
	if(fly_state != SHUTTLE_IN_ATMOSPHERE || !eyeobj?.z || !shuttle_port?.assigned_transit)
		return
	flight_x = eyeobj.x
	flight_y = eyeobj.y
	flight_heading = dir2angle(eyeobj.dir)
	var/datum/turf_reservation/reservation = shuttle_port.assigned_transit.reserved_area
	for(var/turf/tile as anything in reservation.reserved_turfs)
		ground_tiles[tile] = TRUE
		if(istype(tile, /turf/open/space/transit/atmos))
			tile.icon_state = ""
	update_ground_searchlight()
	update_ground_view()
	START_PROCESSING(SSfastprocess, flight_controller)

/// Only render the union of actual viewers' screens, not the 16-tile transit
/// border. Cache this once a second; two extra tiles cover movement meanwhile.
/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/update_ground_bounds(allow_unobserved = FALSE)
	var/min_x = world.maxx
	var/min_y = world.maxy
	var/max_x = 0
	var/max_y = 0
	for(var/mob/viewer as anything in GLOB.player_list)
		if(!viewer.client)
			continue
		var/turf/center = get_turf(viewer.client.eye)
		if(!center || center.z != shuttle_port.z || !ground_tiles[center])
			continue
		var/list/dimensions = getviewsize(viewer.client.view)
		var/radius_x = CEILING(dimensions[1] / 2, 1) + 2
		var/radius_y = CEILING(dimensions[2] / 2, 1) + 2
		min_x = min(min_x, center.x - radius_x)
		max_x = max(max_x, center.x + radius_x)
		min_y = min(min_y, center.y - radius_y)
		max_y = max(max_y, center.y + radius_y)
	// Initial construction and headless tests can request an unobserved view.
	// The running controller never renders an empty shuttle for absent clients.
	if(!max_x && allow_unobserved)
		for(var/turf/tile as anything in ground_tiles)
			min_x = min(min_x, tile.x)
			max_x = max(max_x, tile.x)
			min_y = min(min_y, tile.y)
			max_y = max(max_y, tile.y)
	ground_view_bounds = max_x ? list(min_x, min_y, max_x, max_y) : null
	next_ground_bounds = world.time + 1 SECONDS

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/update_ground_view(animation_seconds = 0)
	if(!eyeobj || !shuttle_port || isnull(flight_x) || !length(ground_tiles))
		return
	if(world.time >= next_ground_bounds || (!ground_view_bounds && !animation_seconds))
		update_ground_bounds(!animation_seconds)
	if(!ground_view_bounds)
		return
	var/bounds_changed = !last_ground_bounds
	if(!bounds_changed)
		for(var/i in 1 to 4)
			if(ground_view_bounds[i] != last_ground_bounds[i])
				bounds_changed = TRUE
				break
	if(!bounds_changed && eyeobj.z == last_ground_z && flight_x == last_ground_x && flight_y == last_ground_y && flight_heading == last_ground_heading)
		animate_ground_view(animation_seconds)
		refresh_ground_slice()
		update_ground_lights()
		update_ground_movables()
		return
	if(!ground_surface)
		ground_surface = new(get_turf(src))
		SET_PLANE(ground_surface, TADPOLE_GROUND_GEOMETRY_PLANE, src)
		ground_origin_x = round(flight_x)
		ground_origin_y = round(flight_y)
	// Rebase only occasionally, keeping the composite's texture bounds small
	// on long flights. Apply the matching compensation to the whole surface.
	var/rebase = abs(flight_x - ground_origin_x) > 16 || abs(flight_y - ground_origin_y) > 16
	if(rebase)
		var/old_origin_x = ground_origin_x
		var/old_origin_y = ground_origin_y
		ground_origin_x = round(flight_x)
		ground_origin_y = round(flight_y)
		for(var/turf/lower as anything in ground_holders)
			var/obj/effect/abstract/tadpole_ground/holder = ground_holders[lower]
			holder.pixel_x = (lower.x - ground_origin_x) * world.icon_size
			holder.pixel_y = (lower.y - ground_origin_y) * world.icon_size
		for(var/atom/movable/mobile as anything in ground_movables)
			var/obj/effect/abstract/tadpole_mobile_anchor/anchor = ground_movables[mobile]
			anchor.rebase((old_origin_x - ground_origin_x) * world.icon_size, (old_origin_y - ground_origin_y) * world.icon_size)
		ground_surface.transform = ground_surface_transform(last_ground_x, last_ground_y, last_ground_heading)
	last_ground_x = flight_x
	last_ground_y = flight_y
	last_ground_heading = flight_heading
	last_ground_z = eyeobj.z
	last_ground_bounds = ground_view_bounds.Copy()
	var/angle = flight_heading - dir2angle(shuttle_port.dir)
	var/cardinal_turn = 90 * round((SIMPLIFY_DEGREES(angle) + 45) / 90)
	var/cos_angle = cos(angle)
	var/sin_angle = sin(angle)
	var/list/remaining = ground_holders.Copy()
	// Inverse-transform the four viewport corners once. Do not scan the
	// radius-square of the entire reservation on every physics step.
	var/min_gx = world.maxx
	var/min_gy = world.maxy
	var/max_gx = 0
	var/max_gy = 0
	for(var/corner_x in list(ground_view_bounds[1], ground_view_bounds[3]))
		for(var/corner_y in list(ground_view_bounds[2], ground_view_bounds[4]))
			var/ux = corner_x - shuttle_port.x
			var/uy = corner_y - shuttle_port.y
			var/gx = flight_x + ux * cos_angle + uy * sin_angle
			var/gy = flight_y + uy * cos_angle - ux * sin_angle
			min_gx = min(min_gx, gx)
			max_gx = max(max_gx, gx)
			min_gy = min(min_gy, gy)
			max_gy = max(max_gy, gy)
	for(var/gx in max(1, round(min_gx) - 2) to min(world.maxx, CEILING(max_gx, 1) + 2))
		for(var/gy in max(1, round(min_gy) - 2) to min(world.maxy, CEILING(max_gy, 1) + 2))
			var/dx = gx - flight_x
			var/dy = gy - flight_y
			var/px = (dx * cos_angle - dy * sin_angle) * world.icon_size
			var/py = (dy * cos_angle + dx * sin_angle) * world.icon_size
			var/turf/upper = locate(shuttle_port.x + round(px / world.icon_size + 0.5), shuttle_port.y + round(py / world.icon_size + 0.5), shuttle_port.z)
			if(!upper || !ground_tiles[upper] || upper.x < ground_view_bounds[1] - 1 || upper.x > ground_view_bounds[3] + 1 || upper.y < ground_view_bounds[2] - 1 || upper.y > ground_view_bounds[4] + 1)
				continue
			var/turf/lower = locate(gx, gy, eyeobj.z)
			var/obj/effect/abstract/tadpole_ground/holder = ground_holders[lower]
			var/is_new = !holder
			if(is_new)
				holder = new
				holder.plane = FLOAT_PLANE
				holder.flight_helm = src
				holder.pixel_x = (gx - ground_origin_x) * world.icon_size
				holder.pixel_y = (gy - ground_origin_y) * world.icon_size
				ground_holders[lower] = holder
				ground_surface.vis_contents += holder
			else
				remaining -= lower

			if(is_new)
				holder.refresh_ground(lower)
			holder.set_view_turn(cardinal_turn)
			holder.set_view_depth((gy - ground_origin_y) * cos_angle + (gx - ground_origin_x) * sin_angle)

	for(var/turf/unused as anything in remaining)
		ground_surface.vis_contents -= ground_holders[unused]
		qdel(ground_holders[unused])
		ground_holders -= unused
	update_ground_lights()
	animate_ground_view(animation_seconds)
	refresh_ground_slice()
	update_ground_movables()

/// Follow only confirmed coordinates. Keep a two-update interpolation window
/// so normal scheduler jitter does not exhaust the client animation. A new
/// target supersedes from the currently displayed position without END_NOW.
/// Never queue velocity extrapolation: braking or delayed physics would make
/// the next confirmed position fall behind that endpoint and visibly rewind.
/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/animate_ground_view(animation_seconds)
	if(!ground_surface)
		return
	var/duration = animation_seconds > 0 ? max(animation_seconds * 20, world.tick_lag) : 0
	animate(ground_surface, transform = ground_surface_transform(flight_x, flight_y, flight_heading), time = duration, easing = LINEAR_EASING)

/// Poll a bounded slice instead of synchronizing every tile on a half-second
/// timer. Newly visible tiles are still built immediately; movable atoms use
/// signals independently of this static-geometry budget.
/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/refresh_ground_slice(budget = 24)
	var/count = length(ground_holders)
	if(!count)
		ground_refresh_cursor = 0
		dirty_ground_tiles.Cut()
		return 0
	var/angle = flight_heading - dir2angle(shuttle_port.dir)
	var/checked = 0
	// Doors, smoothing and topology changes take priority; fallback polling
	// remains for code that changes appearance without emitting an icon signal.
	for(var/turf/lower as anything in dirty_ground_tiles.Copy())
		if(checked >= budget)
			break
		dirty_ground_tiles -= lower
		var/obj/effect/abstract/tadpole_ground/holder = ground_holders[lower]
		if(QDELETED(holder))
			continue
		checked++
		if(holder.refresh_ground(lower))
			holder.set_view_depth((lower.y - ground_origin_y) * cos(angle) + (lower.x - ground_origin_x) * sin(angle))
	for(var/i in 1 to min(budget, count))
		if(checked >= budget)
			break
		ground_refresh_cursor = (ground_refresh_cursor % count) + 1
		var/turf/lower = ground_holders[ground_refresh_cursor]
		var/obj/effect/abstract/tadpole_ground/holder = ground_holders[lower]
		if(world.time < holder.next_refresh)
			continue
		checked++
		if(holder.refresh_ground(lower))
			holder.set_view_depth((lower.y - ground_origin_y) * cos(angle) + (lower.x - ground_origin_x) * sin(angle))
	return checked

/// Transform the assembled grid around the docking origin, not around each
/// tile's separate icon center. All seams share exactly the same transform.
/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/ground_surface_transform(view_x, view_y, heading)
	var/angle = heading - dir2angle(shuttle_port.dir)
	var/dx = ground_origin_x - view_x
	var/dy = ground_origin_y - view_y
	var/matrix/result = matrix()
	result.Turn(-angle)
	result.Translate(((dx * cos(angle) - dy * sin(angle)) + shuttle_port.x - x) * world.icon_size, ((dy * cos(angle) + dx * sin(angle)) + shuttle_port.y - y) * world.icon_size)
	return result

/// Take the helm without changing eye, perspective, view size or sight flags.
/// The remote eye is only the logical ground position used by landing checks.
/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/give_eye_control(mob/user)
	if(fly_state != SHUTTLE_IN_ATMOSPHERE || shuttle_port?.mode != SHUTTLE_IDLE || current_user || !isliving(user))
		return
	initialize_flight_position()
	if(!eyeobj)
		return
	current_user = user
	eyeobj.eye_user = user
	user.remote_control = eyeobj
	give_actions(user)
	to_chat(user, span_notice("Tadpole flight controls: hold W/S for forward/reverse thrust, A/D for gradual turns. The aircraft has inertia. Land to touch down. Release flight controls to move inside the ship."))

/// There is no camera footprint in the physical shuttle view. In particular,
/// never put blue placed_images on the turfs the shuttle is about to occupy.
/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/show_landing_spot()
	return

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/clear_flight_images(mob/user)
	var/mob/camera/aiEye/remote/shuttle_docker/flight_eye = eyeobj
	if(!flight_eye)
		return
	if(user?.client)
		user.client.images -= flight_eye.placement_images
		user.client.images -= flight_eye.placed_images
		user.client.images -= flight_eye.user_image
	flight_eye.placed_images.Cut()

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/remove_eye_control(mob/living/user)
	if(!user)
		return
	// Clean up even if an interaction/UI callback already released the helm.
	clear_flight_images(user)
	if(user != current_user)
		return
	for(var/datum/action/action as anything in actions)
		action.remove_action(user)
	actions.Cut()
	if(user.remote_control == eyeobj)
		user.remote_control = null
	if(eyeobj)
		eyeobj.eye_user = null
	if(user.client?.eye == eyeobj)
		user.reset_perspective(null)
	current_user = null
	user.unset_interaction()

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/process()
	// Camera tracking is deliberately unused; the world-space terrain persists
	// when the pilot releases the controls, for everyone aboard.
	return
