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
	helm.update_ground_view(max(seconds_per_tick, elapsed))

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
	QDEL_NULL(flight_scene)
	QDEL_NULL(ground_searchlight)
	for(var/turf/tile as anything in ground_tiles)
		if(istype(tile, /turf/open/space/transit/atmos))
			tile.update_appearance()
	ground_tiles.Cut()
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
	flight_scene = new(src)
	update_ground_searchlight()
	update_ground_view()
	flight_controller.last_process_time = world.time
	START_PROCESSING(SSfastprocess, flight_controller)

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/proc/update_ground_view(animation_seconds = 0)
	flight_scene?.update(animation_seconds)

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
