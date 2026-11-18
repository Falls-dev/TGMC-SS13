/// Continuous physics and the regression where lower-level explicit planes
/// escaped KEEP_TOGETHER and covered the Tadpole's actual floor.
/datum/unit_test/tadpole_flight
	var/relay_entered = FALSE

/datum/unit_test/tadpole_flight/proc/on_relay_entered()
	SIGNAL_HANDLER
	relay_entered = TRUE

/datum/unit_test/tadpole_flight/Run()
	check_capture_viewport()
	var/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/flight_test/helm = allocate(/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/flight_test)
	var/obj/docking_port/mobile/port = allocate(/obj/docking_port/mobile)
	port.width = 1
	port.height = 1
	var/mob/living/pilot = allocate(/mob/living/carbon/human)
	var/turf/start = locate(40, 40, run_loc_floor_bottom_left.z)
	var/mob/camera/aiEye/remote/shuttle_docker/eye = allocate(/mob/camera/aiEye/remote/shuttle_docker, start, helm)
	helm.shuttle_port = port
	helm.eyeobj = eye
	helm.fly_state = SHUTTLE_IN_ATMOSPHERE
	helm.flight_x = start.x
	helm.flight_y = start.y
	helm.flight_heading = 0
	port.mode = SHUTTLE_IDLE
	eye.eye_user = pilot
	eye.setDir(NORTH)
	eye.relaymove(pilot, EAST)
	TEST_ASSERT_EQUAL(helm.flight_heading, 0, "Repeated movement events must not cause discrete turns")
	helm.advance_flight(0.2, EAST)
	TEST_ASSERT(helm.flight_heading > 0 && helm.flight_heading < 90, "D must begin a gradual turn, not snap 90 degrees")
	TEST_ASSERT_EQUAL(helm.flight_x, start.x, "Turning at rest must not translate the aircraft")
	helm.flight_heading = 0
	helm.flight_turn_velocity = 0
	helm.advance_flight(0.2, NORTH)
	TEST_ASSERT(helm.flight_y < start.y && helm.flight_y > start.y - 1, "W must move a fraction of a tile toward the nose, opposite the docking heading")
	var/first_speed = helm.flight_velocity_y
	helm.advance_flight(0.2, NORTH)
	TEST_ASSERT(helm.flight_velocity_y < first_speed, "Holding thrust must accelerate")
	var/previous_y = helm.flight_y
	var/previous_speed = helm.flight_velocity_y
	helm.advance_flight(0.2, NONE)
	TEST_ASSERT(helm.flight_y < previous_y, "Aircraft must coast after key release")
	TEST_ASSERT(helm.flight_velocity_y < 0 && helm.flight_velocity_y > previous_speed, "Drag must slow the aircraft gradually")
	previous_speed = helm.flight_velocity_y
	helm.advance_flight(0.2, SOUTH)
	TEST_ASSERT(helm.flight_velocity_y > previous_speed, "Reverse thrust must brake forward motion")
	helm.flight_velocity_x = 0
	helm.flight_velocity_y = 0
	helm.flight_heading = 90
	helm.advance_flight(0.2, NORTH)
	TEST_ASSERT(helm.flight_x < start.x, "Thrust must follow the continuous heading")
	var/previous_heading = helm.flight_heading
	helm.advance_flight(0.2, WEST)
	TEST_ASSERT(helm.flight_heading < previous_heading, "A must turn counterclockwise")
	previous_heading = helm.flight_heading
	helm.advance_flight(0.2, NONE)
	TEST_ASSERT(helm.flight_heading < previous_heading, "Rotational inertia must survive key release")
	TEST_ASSERT_EQUAL(helm.landing_checks, 0, "Flying and rotating must not validate a landing footprint")
	// Exercise the actual Land action: blocked terrain must still be checked
	// on demand and must not start a shuttle movement.
	helm.current_user = pilot
	pilot.remote_control = eye
	helm.landing_result = SHUTTLE_DOCKER_BLOCKED
	helm.land_action.target = pilot
	helm.land_action.owner = pilot
	helm.land_action.Activate()
	TEST_ASSERT_EQUAL(helm.landing_checks, 1, "Pressing Land must validate the current footprint")
	TEST_ASSERT_EQUAL(port.mode, SHUTTLE_IDLE, "Blocked landing must not start a shuttle movement")
	TEST_ASSERT_NULL(helm.my_port, "Blocked landing must not create a destination port")
	helm.landing_result = SHUTTLE_DOCKER_LANDING_CLEAR
	helm.current_user = null
	pilot.remote_control = null
	helm.fly_state = SHUTTLE_ON_GROUND
	previous_y = helm.flight_y
	helm.advance_flight(0.2, NORTH|EAST)
	TEST_ASSERT_EQUAL(helm.flight_y, previous_y, "Grounded aircraft must ignore flight input")
	TEST_ASSERT_EQUAL(get_turf(port), run_loc_floor_bottom_left, "Flight must not move physical shuttle turfs")

	var/datum/tadpole_transit_animation/outbound = new(helm, FALSE)
	helm.transit_animation = outbound
	TEST_ASSERT_EQUAL(length(outbound.layers), 3, "The cinematic must use three shared overlays")
	TEST_ASSERT_EQUAL(outbound.ground_scale(), 1, "Orbital travel must not scale the ground before arrival")
	outbound.reveal_ground()
	var/reveal_scale = outbound.ground_scale(outbound.phase_started)
	TEST_ASSERT(reveal_scale < 1, "Arrival must start with the ground receding below the hull")
	TEST_ASSERT_EQUAL(outbound.ground_scale(outbound.phase_started + 10 SECONDS), 1, "Descent must restore normal ground scale")
	qdel(outbound)
	TEST_ASSERT_NULL(helm.transit_animation, "Deleting the effect must detach it from the helm")
	var/datum/tadpole_transit_animation/inbound = new(helm, TRUE)
	helm.transit_animation = inbound
	TEST_ASSERT_EQUAL(inbound.ground_scale(inbound.phase_started), 1, "Return to ship must begin at the current altitude")
	TEST_ASSERT_EQUAL(inbound.ground_scale(inbound.phase_started + 10 SECONDS), reveal_scale, "The two directions must converge at the same altitude")
	inbound.fade_to_space()
	TEST_ASSERT(inbound.blending_into_space, "Entering space must start the parallax handoff")
	TEST_ASSERT_EQUAL(helm.transit_animation, inbound, "The transition must remain attached while space fades in")
	qdel(inbound)
	TEST_ASSERT_NULL(helm.transit_animation, "Ending the handoff must release the temporary layers")

	// Scene relays real turfs and keeps source appearance/planes untouched.
	var/obj/effect/abstract/tadpole_native_chunk/chunk = allocate(/obj/effect/abstract/tadpole_native_chunk)
	var/original_picture = start.appearance
	var/original_plane = start.plane
	chunk.build(start.x, start.y, start.z)
	TEST_ASSERT_EQUAL(chunk.tiles[1], start, "Block begins at its actual ground origin")
	TEST_ASSERT(start in chunk.vis_contents, "Native scene must share the actual turf")
	TEST_ASSERT_EQUAL(length(chunk.vis_contents), 16, "Use one holder per 4x4 source block")
	TEST_ASSERT(get_step(start, EAST) in chunk.vis_contents, "Adjacent ground turfs share the block")
	for(var/atom/source as anything in chunk.vis_contents)
		TEST_ASSERT(isturf(source), "Holders must reference the actual turf, not appearance or movable copies")
	TEST_ASSERT_EQUAL(start.appearance, original_picture, "Native relay must not rewrite source geometry")
	TEST_ASSERT_EQUAL(start.plane, original_plane, "Native relay must not modify source planes")
	var/obj/item/item = allocate(/obj/item, start)
	var/turf/destination = get_step(start, EAST)
	item.forceMove(destination)
	TEST_ASSERT(start in chunk.vis_contents, "Object movement must not rebuild the terrain relay")
	TEST_ASSERT_EQUAL(length(chunk.vis_contents), 16, "Object movement must allocate no motion proxies")
	var/old_type = start.type
	start = start.ChangeTurf(/turf/open/floor/plating)
	sleep(world.tick_lag)
	TEST_ASSERT(start in chunk.vis_contents, "Replacing a turf must reconnect its native relay")
	start.ChangeTurf(old_type)
	var/turf/placement_target = locate(80, 80, start.z)
	RegisterSignal(placement_target, COMSIG_ATOM_ENTERED, PROC_REF(on_relay_entered))
	chunk.place(placement_target.x, placement_target.y, placement_target.z)
	TEST_ASSERT_EQUAL(get_turf(chunk), placement_target, "Native blocks must occupy their displayed world position")
	TEST_ASSERT(!relay_entered, "Placing a visual block must not invoke transit entry or airdrop hooks")
	UnregisterSignal(placement_target, COMSIG_ATOM_ENTERED)
	chunk.place(-3, -2, start.z)
	TEST_ASSERT_EQUAL(chunk.x, 1, "World-edge relays must retain a valid spatial anchor")
	TEST_ASSERT_EQUAL(chunk.x * world.icon_size + chunk.pixel_x, -3 * world.icon_size, "Clamping must preserve the displayed x coordinate")
	TEST_ASSERT_EQUAL(chunk.y * world.icon_size + chunk.pixel_y, -2 * world.icon_size, "Clamping must preserve the displayed y coordinate")
	qdel(chunk)
	TEST_ASSERT_EQUAL(length(chunk.tiles), 0, "Scene deletion must release source subscriptions")
	TEST_ASSERT_EQUAL(length(chunk.vis_contents), 0, "Scene deletion must release native visual links")
	// Exercise the actual transit-enter signal and delayed fall callback.
	var/turf/fall_floor = locate(110, 110, start.z)
	var/old_floor_type = fall_floor.type
	fall_floor = fall_floor.ChangeTurf(/turf/open/floor/plating)
	var/area/old_fall_area = fall_floor.loc
	var/area/tadpole_fall_test/fall_area = new
	fall_area.contents += fall_floor
	var/turf/fall_transit = locate(130, 130, start.z)
	var/old_transit_type = fall_transit.type
	fall_transit = fall_transit.ChangeTurf(/turf/open/space/transit/atmos)
	var/datum/turf_reservation/reservation = new
	var/datum/turf_reservation/old_reservation = SSmapping.used_turfs[fall_transit]
	SSmapping.used_turfs[fall_transit] = reservation
	var/obj/docking_port/stationary/transit/fall_dock = allocate(/obj/docking_port/stationary/transit)
	var/obj/docking_port/mobile/marine_dropship/minidropship/fall_port = allocate(/obj/docking_port/mobile/marine_dropship/minidropship)
	fall_dock.reserved_area = reservation
	fall_dock.owner = fall_port
	fall_port.shuttle_computer = helm
	helm.fly_state = SHUTTLE_IN_ATMOSPHERE
	helm.flight_x = fall_floor.x
	helm.flight_y = fall_floor.y
	var/turf/captured_origin = tadpole_airdrop_origin(fall_transit)
	var/obj/tadpole_fall_test/falling_item = allocate(/obj/tadpole_fall_test, fall_floor)
	// A rescued object must not be taken from a floor by an old timer.
	handle_crosser(falling_item, fall_floor)
	var/rescued_stayed = !falling_item.drop_target
	falling_item.forceMove(fall_transit)
	// Moving the craft after departure must not change the captured origin.
	helm.flight_x += 30
	sleep(0.7 SECONDS)
	// The focused runner does not start the master controller. Drain due
	// timers across ticks: one fire can yield before reaching this callback.
	for(var/timer_tick in 1 to 40)
		SStimer.fire()
		sleep(world.tick_lag)
		if(falling_item.drop_target)
			break
	var/turf/fallen_at = falling_item.drop_target
	if(old_reservation)
		SSmapping.used_turfs[fall_transit] = old_reservation
	else
		SSmapping.used_turfs -= fall_transit
	fall_dock.reserved_area = null
	fall_dock.owner = null
	fall_transit.ChangeTurf(old_transit_type)
	old_fall_area.contents += fall_floor
	fall_floor.ChangeTurf(old_floor_type)
	qdel(reservation)
	qdel(fall_area)
	TEST_ASSERT_EQUAL(captured_origin, fall_floor, "Falling objects must resolve the Tadpole reservation and ground coordinates")
	TEST_ASSERT(rescued_stayed, "A delayed transit callback must not drop a rescued object")
	TEST_ASSERT_NOTNULL(fallen_at, "Entering Tadpole transit must invoke the delayed airdrop")
	TEST_ASSERT(fallen_at.z == fall_floor.z && get_dist(fallen_at, fall_floor) <= 12, "Drops must remain near the captured Tadpole position despite subsequent movement")

	// Real shutter movement hook must preserve both pilot-selected states.
	var/turf/shutter_tile = locate(115, 115, start.z)
	var/area/old_shutter_area = shutter_tile.loc
	var/area/shuttle/minidropship/tadpole_shutter_test/shutter_area = new
	shutter_area.contents += shutter_tile
	var/obj/machinery/door/poddoor/shutters/transit/shutter = allocate(/obj/machinery/door/poddoor/shutters/transit, shutter_tile)
	TEST_ASSERT(!shutter.density && !shutter.opacity, "Tadpole shutters must spawn open so the pilot can board")
	TEST_ASSERT_EQUAL(shutter.icon_state, "shutter0", "Initial shutter appearance must match its open collision state")
	shutter.density = FALSE
	shutter.after_shuttle_move(shutter_tile, null, NORTH, NORTH, NORTH, 0)
	var/open_preserved = !shutter.density && !shutter.operating
	shutter.density = TRUE
	shutter.after_shuttle_move(shutter_tile, null, NORTH, NORTH, NORTH, 0)
	var/closed_preserved = shutter.density && !shutter.operating
	qdel(shutter)
	old_shutter_area.contents += shutter_tile
	qdel(shutter_area)
	TEST_ASSERT(open_preserved && closed_preserved, "Flight and landing must preserve the pilot-selected shutter state")
	var/turf/old_helm_location = get_turf(helm)
	var/turf/old_port_location = get_turf(port)
	var/turf/relay_center = locate(180, 180, helm.z)
	helm.abstract_move(relay_center)
	port.abstract_move(relay_center)
	var/datum/tadpole_scene/scene = new(helm)
	var/old_width = port.width
	var/old_height = port.height
	port.width = 7
	port.height = 9
	var/ground_z = SSmapping.ground_start
	var/radius = scene.source_radius()
	TEST_ASSERT(scene.update_sources(radius, ground_z), "Initial capture builds its window")
	TEST_ASSERT(length(scene.sources) > 0 && length(scene.sources) <= 144, "Only a bounded window of 4x4 blocks may be attached")
	TEST_ASSERT(!scene.update_sources(radius, ground_z), "Stationary flight must skip the source sweep")
	var/list/stable_blocks = scene.sources.Copy()
	var/flight_before_x = helm.flight_x
	helm.flight_x += 0.25
	TEST_ASSERT(!scene.update_sources(radius, ground_z), "Subtile flight within the margin must skip the source sweep")
	helm.flight_x += 3
	TEST_ASSERT(scene.update_sources(radius, ground_z), "Crossing the margin must rebase the window")
	var/overlap = 0
	for(var/key in scene.sources)
		var/obj/effect/abstract/tadpole_native_chunk/holder = scene.sources[key]
		var/turf/source = holder.tiles[1]
		TEST_ASSERT_EQUAL(holder.x * world.icon_size + holder.pixel_x, (source.x + scene.source_offset_x) * world.icon_size, "Block x must match the common projection offset")
		TEST_ASSERT_EQUAL(holder.y * world.icon_size + holder.pixel_y, (source.y + scene.source_offset_y) * world.icon_size, "Block y must match the common projection offset")
		if(stable_blocks[key])
			overlap++
			TEST_ASSERT_EQUAL(holder, stable_blocks[key], "Overlapping blocks retain their roots across a rebase")
	TEST_ASSERT(overlap > 0, "Nearby capture windows must share blocks")
	helm.flight_x = flight_before_x
	port.width = old_width
	port.height = old_height
	qdel(scene)
	TEST_ASSERT_EQUAL(length(scene.sources), 0, "Scene deletion must release every block")
	helm.abstract_move(old_helm_location)
	port.abstract_move(old_port_location)
	// Flight-specific graph edits must be local to one HUD and reversible.
	var/datum/hud/display = allocate(/datum/hud, pilot)
	var/datum/hud/other_display = allocate(/datum/hud, allocate(/mob/living/carbon/human))
	var/atom/movable/screen/plane_master/other_plate = other_display.get_plane_master(GET_NEW_PLANE(RENDER_PLANE_MASTER, 1))
	var/list/original_targets = other_plate.render_relay_planes.Copy()
	var/datum/tadpole_scene/walking_scene = new(helm)
	// Temporary visibility must survive equipment updates without overwriting
	// the underlying sight or another owner's modifier.
	var/mob/living/carbon/human/sight_subject = allocate(/mob/living/carbon/human)
	sight_subject.set_sight(SEE_SELF)
	sight_subject.add_sight_modifier("tadpole_test_a", SEE_TURFS | SEE_OBJS)
	sight_subject.add_sight_modifier("tadpole_test_b", SEE_MOBS)
	sight_subject.set_sight(SEE_INFRA)
	TEST_ASSERT_EQUAL(sight_subject.sight, SEE_INFRA | SEE_TURFS | SEE_OBJS | SEE_MOBS, "Equipment sight updates must preserve active visibility modifiers")
	sight_subject.add_sight(SEE_SELF)
	sight_subject.clear_sight(SEE_INFRA)
	sight_subject.remove_sight_modifier("tadpole_test_a")
	TEST_ASSERT_EQUAL(sight_subject.sight, SEE_SELF | SEE_MOBS, "Removing one sight owner must retain another owner's flags")
	sight_subject.remove_sight_modifier("tadpole_test_b")
	TEST_ASSERT_EQUAL(sight_subject.sight, SEE_SELF, "Temporary flags must not leak into the underlying sight")
	sight_subject.add_sight_modifier("tadpole_test_a", SEE_TURFS)
	sight_subject.set_sight(SEE_SELF | SEE_TURFS)
	sight_subject.remove_sight_modifier("tadpole_test_a")
	TEST_ASSERT_EQUAL(sight_subject.sight, SEE_SELF | SEE_TURFS, "A sight update equal to effective sight must still update the underlying flags")
	var/sight_before_view = pilot.sight
	var/invisibility_before_view = pilot.see_invisible
	var/mob/other_passenger = other_display.mymob
	var/other_sight_before = other_passenger.sight
	var/datum/tadpole_scene_view/native_view = new(display, 1, walking_scene)
	check_native_eye_projection(walking_scene, native_view)
	native_view.begin_capture()
	TEST_ASSERT_NOTNULL(native_view.plate, "Ground must have a preallocated native lower render plate")
	TEST_ASSERT(native_view.plate.get_relay_to(TADPOLE_GROUND_PLANE), "Passenger plate must relay below the physical craft")
	TEST_ASSERT_EQUAL(other_plate.render_relay_planes.Join(","), original_targets.Join(","), "Another observer must retain their native graph")
	var/required_sight = SEE_SELF | SEE_TURFS | SEE_OBJS | SEE_MOBS
	TEST_ASSERT_EQUAL(pilot.sight & required_sight, required_sight, "Living passengers must receive observer-style native scene visibility")
	TEST_ASSERT_EQUAL(pilot.see_invisible, invisibility_before_view, "Removing scene occlusion must not reveal invisible entities")
	TEST_ASSERT_EQUAL(other_passenger.sight, other_sight_before, "A view must not change another mob's visibility")
	// This fixture has no client; deliver the native Logout signal through
	// the actual subscription instead of invoking client disconnection.
	SEND_SIGNAL(pilot, COMSIG_MOB_LOGOUT)
	TEST_ASSERT_EQUAL(pilot.sight, sight_before_view, "Logout must release temporary passenger vision")
	TEST_ASSERT_NULL(native_view.tracked_eye, "Logout must stop movement callbacks from reactivating vision")
	native_view.bind_visibility(pilot)
	native_view.begin_capture()
	pilot.set_sight(SEE_INFRA)
	TEST_ASSERT_EQUAL(pilot.sight, SEE_INFRA | required_sight, "Regular sight recalculation must not restore passenger occlusion")
	// Exercise the real Move -> COMSIG_MOVABLE_MOVED path without calling
	// the 0.2-second scene processor. Headless fixture has a HUD but no client.
	var/turf/walking_start = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	pilot.forceMove(walking_start)
	var/turf/walking_end = get_step(walking_start, SOUTH)
	var/list/old_ground_tiles = helm.ground_tiles
	helm.ground_tiles = list()
	helm.ground_tiles[walking_start] = TRUE
	helm.ground_tiles[walking_end] = TRUE
	var/turf/ground_mouse_target = locate(walking_start.x, walking_start.y, SSmapping.ground_start)
	var/turf/old_eye_turf = get_turf(helm.eyeobj)
	helm.eyeobj.abstract_move(ground_mouse_target)
	TEST_ASSERT(native_view.is_ground_mouse_target(ground_mouse_target, walking_start), "Ground below the Tadpole must be treated like the background")
	var/atom/movable/render_plane_relay/background_relay = native_view.plate.get_relay_to(TADPOLE_GROUND_PLANE)
	TEST_ASSERT_EQUAL(background_relay.mouse_opacity, MOUSE_OPACITY_OPAQUE, "Background relay must receive mouse hits")
	TEST_ASSERT(native_view.is_ground_mouse_target(background_relay, walking_start), "Relay hits must be routed to the transit map")
	TEST_ASSERT(native_view.is_ground_mouse_target(null, walking_start), "An empty map hit must still resolve to a transit target")
	TEST_ASSERT(!native_view.is_ground_mouse_target(walking_end, walking_start), "Onboard targets must keep their original click behavior")
	TEST_ASSERT(!native_view.is_ground_mouse_target(ground_mouse_target, get_step(walking_start, NORTH)), "Ground clicks must only be redirected for viewers aboard")
	helm.eyeobj.abstract_move(old_eye_turf)
	var/walking_heading = helm.flight_heading
	helm.flight_heading = dir2angle(port.dir) + 180
	native_view.track_eye(pilot)
	walking_scene.update_view(native_view, walking_start, 0)
	var/old_camera_values = native_view.last_camera.tolist().Join(",")
	var/old_projection_y = native_view.last_camera.f
	var/turf/fixed_eye_before = get_turf(walking_scene.render_origin)
	pilot.set_glide_size(8)
	TEST_ASSERT(pilot.Move(walking_end, SOUTH), "Walking camera fixture must move through the ordinary Move path")
	TEST_ASSERT_EQUAL(native_view.last_camera.f - old_projection_y, 2 * world.icon_size, "A half-turn must compensate a southward eye step in the lower plane")
	var/step_duration = native_view.eye_duration
	helm.flight_heading += 15
	walking_scene.update_view(native_view, walking_end, step_duration / 20)
	TEST_ASSERT_NOTNULL(native_view.animation_midpoint, "A flight update during a walk must preserve the remaining glide")
	TEST_ASSERT_EQUAL(native_view.animation_duration, step_duration, "Flight interpolation must not shorten the walking correction")
	// A connected client advances its native scroll before drawing the first
	// animation frame. Reproduce that lead in the headless projection fixture.
	var/step_lead = step_duration / 4
	native_view.eye_started = world.time - step_lead
	helm.flight_heading += 5
	walking_scene.update_view(native_view, walking_end, step_duration / 10, step_lead)
	TEST_ASSERT_EQUAL(native_view.animation_started, native_view.eye_started, "The projection timeline must include the client's step lead")
	helm.flight_heading += 5
	walking_scene.update_view(native_view, walking_end, step_duration / 20)
	TEST_ASSERT_EQUAL(native_view.animation_duration, step_duration - step_lead, "A flight update must retain just the unplayed part of a phase-aligned step")
	TEST_ASSERT_EQUAL(get_turf(walking_scene.render_origin), fixed_eye_before, "Walking must leave the hull render origin fixed")
	TEST_ASSERT(pilot.Move(walking_start, NORTH), "Walking fixture must reverse through the ordinary movement path")
	TEST_ASSERT(pilot.Move(walking_end, SOUTH), "Walking fixture must return inside the ship before testing exit")
	TEST_ASSERT_EQUAL(length(walking_scene.sources), 0, "Walking projection must not allocate or update terrain membership")
	var/turf/outside_ship = get_step(walking_end, SOUTH)
	TEST_ASSERT(pilot.Move(outside_ship, SOUTH), "Visibility fixture must step out of the Tadpole region")
	TEST_ASSERT_EQUAL(pilot.sight, SEE_INFRA, "Leaving must restore the latest underlying sight in the movement tick")
	TEST_ASSERT(!native_view.capture_active, "Leaving must release its ground capture immediately")
	TEST_ASSERT(pilot.Move(walking_end, NORTH), "Visibility fixture must reenter the Tadpole region")
	TEST_ASSERT_EQUAL(pilot.sight, SEE_INFRA | required_sight, "Reentry must reactivate native scene visibility")
	pilot.set_sight(sight_before_view)
	native_view.track_eye(eye)
	old_camera_values = native_view.last_camera.tolist().Join(",")
	pilot.forceMove(walking_start)
	TEST_ASSERT_EQUAL(native_view.last_camera.tolist().Join(","), old_camera_values, "Changing the watched eye must unregister the old movement signal")
	native_view.track_eye(null)
	helm.flight_heading = walking_heading
	helm.ground_tiles = old_ground_tiles
	// Change the input coordinates while a turn is in progress. The same
	// physical ground point must retain its screen position at the seam.
	var/turf/test_eye = get_turf(pilot)
	walking_scene.update_view(native_view, test_eye, 0)
	helm.flight_heading += 30
	walking_scene.update_view(native_view, test_eye, 1)
	native_view.animation_started = world.time - 5
	var/matrix/before_rebase = native_view.displayed_camera()
	walking_scene.source_offset_x -= 3
	walking_scene.update_view(native_view, test_eye, 0.2)
	var/matrix/after_rebase = native_view.animation_from
	TEST_ASSERT(abs(after_rebase.c - after_rebase.a * 3 * world.icon_size - before_rebase.c) < 0.001, "Changing holder coordinates must not jump the rendered ground in x")
	TEST_ASSERT(abs(after_rebase.f - after_rebase.d * 3 * world.icon_size - before_rebase.f) < 0.001, "Changing holder coordinates must not jump the rendered ground in y")
	helm.flight_heading = walking_heading
	var/atom/movable/screen/plane_master/passenger_plate = native_view.plate
	qdel(native_view)
	TEST_ASSERT_EQUAL(pilot.sight, sight_before_view, "Scene departure must remove its sight modifier")
	TEST_ASSERT(!length(pilot.sight_modifiers), "Scene cleanup must leave no owned sight modifiers")
	qdel(walking_scene)
	TEST_ASSERT_NULL(passenger_plate.get_relay_to(TADPOLE_GROUND_PLANE), "Leaving the scene must remove the aircraft relay")
	TEST_ASSERT(passenger_plate.get_relay_to(RENDER_PLANE_TRANSPARENT), "Leaving must restore native multiz routing")
	var/turf/ground = locate(40,40,SSmapping.ground_start)
	TEST_ASSERT(SSmapping.z_level_to_plane_offset[ground.z] >= 1, "Ground planes must be allocated below transit before atom initialization")
	check_movable_searchlight(ground)
	var/obj/effect/lighting_mask_holder/light_holder = allocate(/obj/effect/lighting_mask_holder, ground)
	var/atom/movable/lighting_mask/light = new
	light_holder.assign_mask(light)
	TEST_ASSERT_EQUAL(light.plane, LIGHTING_PLANE - PLANE_RANGE * SSmapping.z_level_to_plane_offset[ground.z], "Nullspace hybrid mask must use its holder's ground plane")
	var/atom/movable/screen/map_view/remote_map = allocate(/atom/movable/screen/map_view)
	TEST_ASSERT_EQUAL(remote_map.source_depth(), 0, "Empty/nullspace previews must render at their own depth zero")
	remote_map.vis_contents = list(ground)
	TEST_ASSERT_EQUAL(remote_map.source_depth(), SSmapping.z_level_to_plane_offset[ground.z], "Remote maps must follow the camera source rather than the observer's z")
	var/datum/plane_master_group/popup/popup = allocate(/datum/plane_master_group/popup, "tadpole_test_popup")
	popup.source_plane_offset = 1
	TEST_ASSERT_EQUAL(popup.view_offset(0), 1, "Ground camera must remain on depth one for a shipside observer")
	popup.source_plane_offset = 0
	TEST_ASSERT_EQUAL(popup.view_offset(1), 0, "Nullspace preview must remain on depth zero for a ground observer")
	// Destroy HUDs while their owners are still alive; the generic fixture
	// cleanup otherwise deletes mobs before the lighting backdrop timers.
	qdel(display)
	qdel(other_display)
	helm.eyeobj = null

/// Headless renderer/state test. Actual client eye assignment and mouse-hit
/// rasterization require a connected-client check, not a matrix assertion.
/datum/unit_test/tadpole_flight/proc/check_native_eye_projection(datum/tadpole_scene/scene, datum/tadpole_scene_view/view)
	var/obj/docking_port/mobile/port = scene.helm.shuttle_port
	var/old_width = port.width
	var/old_height = port.height
	var/old_heading = scene.helm.flight_heading
	port.width = 7
	port.height = 9
	scene.ensure_render_origin()
	var/turf/anchor_before = get_turf(scene.render_origin)
	var/atom/movable/screen/plane_master/game = view.hud.get_plane_master(RENDER_PLANE_GAME)
	var/atom/movable/render_plane_relay/game_relay = game.get_relay_to(RENDER_PLANE_MASTER)
	var/game_transform_before = game_relay.transform.tolist().Join(",")
	var/atom/movable/screen/plane_master/hud_plane = view.hud.get_plane_master(HUD_PLANE)
	var/atom/movable/render_plane_relay/hud_relay = hud_plane.get_relay_to(RENDER_PLANE_NON_GAME)
	var/hud_transform_before = hud_relay.transform.tolist().Join(",")
	view.begin_capture()
	var/atom/movable/render_plane_relay/ground_relay = view.plate.get_relay_to(TADPOLE_GROUND_PLANE)
	var/relay_transform_before = ground_relay.transform.tolist().Join(",")
	var/list/geometry = scene.capture_geometry()
	var/datum/tadpole_viewport/adapter = allocate(/datum/tadpole_viewport)
	adapter.owner = view
	adapter.frame = allocate(/atom/movable/screen/background/tadpole_view_bounds)
	TEST_ASSERT_EQUAL(adapter.configure("19x15"), "[geometry[2]]x[geometry[3]]", "Native character camera must allocate the calculated hull margin")
	TEST_ASSERT_EQUAL(adapter.configure("61x57"), "[geometry[2]]x[geometry[3]]", "Observer zoom must not expand the hull source window")
	qdel(adapter)
	var/list/hull = port.return_coords(port.x, port.y, port.dir)
	var/list/visible = getviewsize(CONFIG_GET(string/default_view))
	for(var/angle in list(0, 37, 90, 180, 270))
		scene.helm.flight_heading = dir2angle(port.dir) + angle
		scene.update_sources(scene.source_radius(), SSmapping.ground_start)
		for(var/ex in list(hull[1], anchor_before.x, hull[3]))
			for(var/ey in list(hull[2], anchor_before.y, hull[4]))
				var/turf/eye = locate(ex, ey, port.z)
				scene.update_view(view, eye, 0)
				var/matrix/camera = view.plate.transform
				TEST_ASSERT_EQUAL(ground_relay.transform.tolist().Join(","), relay_transform_before, "The corner-anchored output relay must stay untransformed")
				var/raw_x = (scene.helm.flight_x + 2 + scene.source_offset_x - eye.x) * world.icon_size
				var/raw_y = (scene.helm.flight_y - 3 + scene.source_offset_y - eye.y) * world.icon_size
				var/projected_x = camera.a * raw_x + camera.b * raw_y + camera.c
				var/projected_y = camera.d * raw_x + camera.e * raw_y + camera.f
				var/expected_x = (port.x - eye.x + camera.a * 2 - camera.b * 3) * world.icon_size
				var/expected_y = (port.y - eye.y + camera.d * 2 - camera.e * 3) * world.icon_size
				TEST_ASSERT(abs(projected_x - expected_x) < 0.001 && abs(projected_y - expected_y) < 0.001, "Native-eye projection must retain actual ground/landing coordinates at every hull edge and heading")
				for(var/sx in list(-visible[1] / 2, visible[1] / 2))
					for(var/sy in list(-visible[2] / 2, visible[2] / 2))
						var/dx = sx - camera.c / world.icon_size
						var/dy = sy - camera.f / world.icon_size
						var/input_x = camera.a * dx + camera.d * dy
						var/input_y = camera.b * dx + camera.e * dy
						TEST_ASSERT(abs(input_x) <= geometry[2] / 2 && abs(input_y) <= geometry[3] / 2, "Native viewport must contain the source of each visible corner")
						var/ground_x = input_x + eye.x - scene.source_offset_x
						var/ground_y = input_y + eye.y - scene.source_offset_y
						var/list/bounds = scene.source_bounds
						TEST_ASSERT(ground_x >= bounds[1] - 0.5 && ground_x <= bounds[3] + 0.5 && ground_y >= bounds[2] - 0.5 && ground_y <= bounds[4] + 0.5, "Each visible corner must have a streamed ground block")
				TEST_ASSERT_EQUAL(game_relay.transform.tolist().Join(","), game_transform_before, "Native camera following must never transform the final game relay")
				TEST_ASSERT_EQUAL(hud_relay.transform.tolist().Join(","), hud_transform_before, "Native camera following must never transform the HUD")
	view.end_capture()
	TEST_ASSERT(!view.capture_active, "Release must clear capture state")
	port.width = old_width
	port.height = old_height
	scene.helm.flight_heading = old_heading
	scene.ensure_render_origin()
	QDEL_LIST_ASSOC_VAL(scene.sources)
	scene.source_anchor_x = null
	scene.source_anchor_y = null

/datum/unit_test/tadpole_flight/proc/check_movable_searchlight(turf/ground)
	var/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/flight_test/helm = allocate(/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/flight_test)
	var/obj/docking_port/mobile/port = allocate(/obj/docking_port/mobile, ground)
	port.width = 1
	port.height = 1
	helm.shuttle_port = port
	helm.eyeobj = allocate(/mob/camera/aiEye/remote/shuttle_docker, ground, helm)
	helm.fly_state = SHUTTLE_IN_ATMOSPHERE
	helm.flight_x = ground.x
	helm.flight_y = ground.y
	helm.flight_heading = dir2angle(port.dir)
	helm.update_ground_searchlight()
	var/obj/effect/abstract/tadpole_searchlight/source = helm.ground_searchlight
	var/datum/component/overlay_lighting/overlay = source.GetComponent(/datum/component/overlay_lighting)
	TEST_ASSERT_NOTNULL(overlay, "Searchlight must initialize movable overlay lighting")
	TEST_ASSERT_NULL(source.light, "Searchlight must not create a hybrid shadow source")
	TEST_ASSERT_EQUAL(source.invisibility, 0, "The empty source must not hide its light underlay from living passengers")
	// Component holder attachment is deferred through the timer subsystem.
	sleep(1 SECONDS)
	TEST_ASSERT_EQUAL(overlay.current_holder, source, "Movable searchlight must attach to its ground source")
	// Underlays stores appearances, not the component's image reference.
	TEST_ASSERT(length(source.underlays), "Movable searchlight must attach its visible light mask")
	TEST_ASSERT_EQUAL(overlay.visible_mask.plane, GET_NEW_PLANE(O_LIGHTING_VISUAL_PLANE, SSmapping.z_level_to_plane_offset[ground.z]), "Searchlight must render on the ground lighting plane")
	var/turf/previous = get_turf(source)
	helm.flight_x++
	helm.update_ground_searchlight()
	TEST_ASSERT_EQUAL(helm.ground_searchlight, source, "Movement must reuse the same movable source")
	TEST_ASSERT_EQUAL(source.x, previous.x + 1, "Movable searchlight must follow flight position")
	helm.clear_ground_view()
	TEST_ASSERT_NULL(helm.ground_searchlight, "Leaving flight must remove its searchlight")
	TEST_ASSERT(QDELETED(source) && QDELETED(overlay), "Source cleanup must also delete its lighting component")
	helm.eyeobj = null

/datum/unit_test/tadpole_flight/proc/check_capture_viewport()
	var/datum/tadpole_viewport/cache_test/viewport = allocate(/datum/tadpole_viewport/cache_test)
	viewport.frame = allocate(/atom/movable/screen/background/tadpole_view_bounds)
	TEST_ASSERT_EQUAL(viewport.configure("19x15"), "25x25", "Native capture must use 25x25")
	TEST_ASSERT_EQUAL(viewport.map_location("WEST:6,1:5"), "4:6,6:5", "HUD must retain visible placement when capture grows")
	var/calls = viewport.parse_calls
	for(var/i in 1 to 100)
		viewport.map_location("WEST:6,1:5")
	TEST_ASSERT_EQUAL(viewport.parse_calls, calls, "Unchanged HUD locations must not be reparsed")
	TEST_ASSERT_EQUAL(viewport.configure("61x57"), "25x25", "Ghost zoom must not resize native capture")
	TEST_ASSERT_EQUAL(viewport.map_location("CENTER"), "13,13", "Ghost zoom must keep the capture center fixed")
	TEST_ASSERT_EQUAL(viewport.frame.screen_loc, "CENTER-30,CENTER-28 to CENTER+30,CENTER+28", "Zoomed HUD bounds must stay symmetric around the fixed capture")
	viewport.configure("26x24")
	TEST_ASSERT_EQUAL(viewport.map_location("WEST,SOUTH"), "0:16,1:16", "Even logical sizes must use pixel offsets rather than fractional tile strings")
	TEST_ASSERT_EQUAL(viewport.map_location("CENTER"), "13,13", "Even logical sizes must preserve capture centering")
	TEST_ASSERT_EQUAL(viewport.map_location("popup:1,1"), "popup:1,1", "Auxiliary map coordinates must remain untouched")
	var/atom/movable/screen/fullscreen/lighting_backdrop/backplane/backdrop = allocate(/atom/movable/screen/fullscreen/lighting_backdrop/backplane)
	backdrop.update_for_view("25x25")
	TEST_ASSERT_EQUAL(backdrop.transform.a, 25, "Lighting background must cover the larger capture")
	TEST_ASSERT_EQUAL(backdrop.transform.e, 25, "Lighting background must cover the larger capture")

/datum/tadpole_viewport/cache_test
	var/parse_calls = 0

/datum/tadpole_viewport/cache_test/map_axis(text, axis)
	parse_calls++
	return ..()

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/flight_test
	var/landing_checks = 0
	var/landing_result = SHUTTLE_DOCKER_LANDING_CLEAR

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/flight_test/checkLandingSpot()
	landing_checks++
	return landing_result

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/flight_test/check_hovering_spot(turf/next_turf)
	return TRUE


/obj/tadpole_fall_test
	anchored = TRUE
	var/turf/drop_target

/obj/tadpole_fall_test/handle_airdrop(turf/target_turf)
	drop_target = target_turf
	forceMove(target_turf)

/obj/tadpole_fall_test/throw_at()
	return FALSE

/area/tadpole_fall_test
	outside = TRUE
	area_flags = NONE

/area/shuttle/minidropship/tadpole_shutter_test
