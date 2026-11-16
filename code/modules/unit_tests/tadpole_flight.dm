/// Continuous physics and the regression where lower-level explicit planes
/// escaped KEEP_TOGETHER and covered the Tadpole's actual floor.
/datum/unit_test/tadpole_flight
	var/relay_entered = FALSE

/datum/unit_test/tadpole_flight/proc/on_relay_entered()
	SIGNAL_HANDLER
	relay_entered = TRUE

/datum/unit_test/tadpole_flight/Run()
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
	helm.fly_state = SHUTTLE_ON_GROUND
	previous_y = helm.flight_y
	helm.advance_flight(0.2, NORTH|EAST)
	TEST_ASSERT_EQUAL(helm.flight_y, previous_y, "Grounded aircraft must ignore flight input")
	TEST_ASSERT_EQUAL(get_turf(port), run_loc_floor_bottom_left, "Flight must not move physical shuttle turfs")


	// Scene relays real turfs and keeps source appearance/planes untouched.
	var/obj/effect/abstract/tadpole_native_chunk/chunk = allocate(/obj/effect/abstract/tadpole_native_chunk)
	var/original_picture = start.appearance
	var/original_plane = start.plane
	chunk.build(start.x, start.y, start.z)
	TEST_ASSERT_EQUAL(length(chunk.tiles), 64, "A native chunk must own exactly one 8x8 cell block")
	TEST_ASSERT(start in chunk.vis_contents, "Native scene must share the actual turf")
	TEST_ASSERT_EQUAL(length(chunk.vis_contents), 64, "The native block must contain all 64 turfs directly")
	TEST_ASSERT(get_step(start, EAST) in chunk.vis_contents, "Native layout must include the adjacent east turf")
	TEST_ASSERT(get_step(start, NORTH) in chunk.vis_contents, "Native layout must include the adjacent north turf")
	for(var/atom/source as anything in chunk.vis_contents)
		TEST_ASSERT(isturf(source), "A block must allocate no per-tile movable relays for SendMaps to traverse")
	TEST_ASSERT_EQUAL(start.appearance, original_picture, "Native relay must not rewrite source geometry")
	TEST_ASSERT_EQUAL(start.plane, original_plane, "Native relay must not modify source planes")
	var/obj/item/item = allocate(/obj/item, start)
	var/turf/destination = get_step(start, EAST)
	item.forceMove(destination)
	TEST_ASSERT(start in chunk.vis_contents, "Object movement must not rebuild the terrain relay")
	TEST_ASSERT_EQUAL(length(chunk.tiles), 64, "Object movement must allocate no motion proxies")
	var/old_type = start.type
	start = start.ChangeTurf(/turf/open/floor/plating)
	sleep(world.tick_lag)
	TEST_ASSERT(start in chunk.vis_contents, "Replacing a turf must reconnect its native relay")
	start.ChangeTurf(old_type)
	var/turf/placement_target = locate(80, 80, start.z)
	RegisterSignal(placement_target, COMSIG_ATOM_ENTERED, PROC_REF(on_relay_entered))
	chunk.move_ground(placement_target.x, placement_target.y, placement_target.x, placement_target.y, placement_target.z, 0)
	TEST_ASSERT_NULL(get_turf(chunk), "Capture blocks must not enter any world turf")
	TEST_ASSERT(!relay_entered, "Placing a visual block must not invoke transit entry or airdrop hooks")
	UnregisterSignal(placement_target, COMSIG_ATOM_ENTERED)
	chunk.move_ground(-3, -2, -3, -2, start.z, 0)
	TEST_ASSERT_NULL(chunk.loc, "Capture offsets must not require a spatial world anchor")
	TEST_ASSERT_EQUAL(chunk.pixel_x, -3 * world.icon_size, "Capture must preserve negative source x offsets")
	TEST_ASSERT_EQUAL(chunk.pixel_y, -2 * world.icon_size, "Capture must preserve negative source y offsets")
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
	scene.source_z = SSmapping.ground_start
	scene.origin_x = FLOOR(helm.flight_x / 8, 1) * 8
	scene.origin_y = FLOOR(helm.flight_y / 8, 1) * 8
	scene.radius = 16
	scene.update_chunks()
	var/key = "[scene.origin_x + 16],[scene.origin_y + 16],[scene.source_z]"
	var/obj/effect/abstract/tadpole_native_chunk/edge_chunk = scene.chunks[key]
	TEST_ASSERT_NOTNULL(edge_chunk, "Prefetch must cover the last cell of an eight-tile camera bucket")
	var/count = length(scene.chunks)
	var/nearby_blocks = 0
	for(var/obj/effect/abstract/tadpole_native_chunk/nearby in range(13, helm))
		nearby_blocks++
	TEST_ASSERT_EQUAL(nearby_blocks, 0, "Capture blocks must not enter the passenger world visibility range")
	TEST_ASSERT_EQUAL(length(scene.canvas.vis_contents), count, "One shared canvas must own every source block")
	for(var/chunk_key in scene.chunks)
		var/obj/effect/abstract/tadpole_native_chunk/spatial_block = scene.chunks[chunk_key]
		var/turf/first_source = spatial_block.tiles[1]
		var/matrix/source_shift = spatial_block.transform
		TEST_ASSERT_NULL(spatial_block.loc, "Capture blocks must remain in nullspace")
		TEST_ASSERT(abs(spatial_block.pixel_x + source_shift.c - (first_source.x - helm.flight_x) * world.icon_size) < 0.001, "Source x must depend on flight rather than the passenger eye")
		TEST_ASSERT(abs(spatial_block.pixel_y + source_shift.f - (first_source.y - helm.flight_y) * world.icon_size) < 0.001, "Source y must depend on flight rather than the passenger eye")
		TEST_ASSERT_EQUAL(source_shift.a, 1, "Individual blocks must never rotate")
		TEST_ASSERT_EQUAL(source_shift.e, 1, "Individual blocks must never rotate")
	scene.update_chunks()
	TEST_ASSERT_EQUAL(scene.chunks[key], edge_chunk, "Unchanged scene cells must reuse native blocks")
	TEST_ASSERT_EQUAL(length(scene.chunks), count, "Repeated membership checks must allocate no additional blocks")
	// Reproduce the old single-step radius threshold: 24 -> 25 allocates
	// four borders at once; returning deletes them again, unlike scrolling.
	scene.radius = 24
	scene.update_chunks()
	var/list/before_step = scene.chunks.Copy()
	scene.radius = 25
	scene.update_chunks()
	var/added_blocks = 0
	for(var/chunk_key in scene.chunks)
		if(!before_step[chunk_key])
			added_blocks++
	TEST_ASSERT_EQUAL(added_blocks, 32, "The old one-tile walking threshold must reproduce its 32-block allocation burst")
	world.log << "TADPOLE_WALK_REPRO: radius 24->25 adds [added_blocks] blocks; old per-tile relays would add [added_blocks * 64] movables"
	var/old_width = port.width
	var/old_height = port.height
	port.width = 7
	port.height = 9
	var/list/viewport = list(26, 26)
	scene.origin_x = FLOOR(helm.flight_x / 8, 1) * 8
	scene.origin_y = FLOOR(helm.flight_y / 8, 1) * 8
	scene.radius = scene.source_radius(viewport)
	scene.update_chunks()
	var/list/stable_blocks = scene.chunks.Copy()
	var/turf/pilot_start = get_turf(pilot)
	scene.update_source_position(0)
	for(var/i in 1 to 4)
		pilot.forceMove(i % 2 ? get_step(pilot_start, EAST) : pilot_start)
		TEST_ASSERT(!scene.update_region(scene.source_radius(viewport), scene.source_z), "Passenger movement must not trigger a terrain rebuild")
		TEST_ASSERT(!scene.update_source_position(0.2), "Walking must not restart shared terrain movement")
	TEST_ASSERT_EQUAL(length(scene.chunks), length(stable_blocks), "Walking must retain the same block count")
	for(var/chunk_key in stable_blocks)
		TEST_ASSERT_EQUAL(scene.chunks[chunk_key], stable_blocks[chunk_key], "Walking must preserve every cached block identity")
	// A bucket transition during a source animation changes membership only.
	var/flight_before_x = helm.flight_x
	var/list/effective_before = scene.displayed_source_position()
	var/center_key = "[scene.origin_x],[scene.origin_y],[scene.source_z]"
	var/obj/effect/abstract/tadpole_native_chunk/center_chunk = scene.chunks[center_key]
	helm.flight_x += 8
	scene.update_source_position(1)
	scene.source_started = world.time - 5
	var/list/source_before = scene.displayed_source_position()
	TEST_ASSERT(abs(source_before[1] - effective_before[1] - 4) < 0.001, "Shared terrain must interpolate the actual flight position")
	TEST_ASSERT(scene.update_region(scene.radius, scene.source_z), "Crossing eight tiles must update source membership")
	TEST_ASSERT_EQUAL(scene.displayed_source_position().Join(","), source_before.Join(","), "Changing cache origin must not move the displayed terrain")
	TEST_ASSERT_EQUAL(scene.chunks[center_key], center_chunk, "A cache seam must retain overlapping source blocks")
	helm.flight_x = flight_before_x
	pilot.forceMove(pilot_start)
	port.width = old_width
	port.height = old_height
	qdel(scene)
	TEST_ASSERT_EQUAL(length(scene.chunks), 0, "Scene deletion must release all native blocks")
	helm.abstract_move(old_helm_location)
	port.abstract_move(old_port_location)
	// Flight-specific graph edits must be local to one HUD and reversible.
	var/datum/hud/display = allocate(/datum/hud, pilot)
	var/datum/hud/other_display = allocate(/datum/hud, allocate(/mob/living/carbon/human))
	var/atom/movable/screen/plane_master/other_plate = other_display.get_plane_master(GET_NEW_PLANE(RENDER_PLANE_MASTER, 1))
	var/list/original_targets = other_plate.render_relay_planes.Copy()
	var/datum/tadpole_scene/walking_scene = new(helm)
	walking_scene.origin_x = FLOOR(helm.flight_x / 8, 1) * 8
	walking_scene.origin_y = FLOOR(helm.flight_y / 8, 1) * 8
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
	check_fixed_capture(walking_scene, native_view)
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
	pilot.set_sight(SEE_INFRA)
	TEST_ASSERT_EQUAL(pilot.sight, SEE_INFRA | required_sight, "Regular sight recalculation must not restore passenger occlusion")
	// Exercise the real Move -> COMSIG_MOVABLE_MOVED path without calling
	// the 0.2-second scene processor. Headless fixture has a HUD but no client.
	// Leave room for two real southward steps inside the fixture floor.
	var/turf/walking_start = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	pilot.forceMove(walking_start)
	var/turf/walking_end = get_step(walking_start, SOUTH)
	var/list/old_ground_tiles = helm.ground_tiles
	helm.ground_tiles = list()
	helm.ground_tiles[walking_start] = TRUE
	helm.ground_tiles[walking_end] = TRUE
	var/walking_heading = helm.flight_heading
	helm.flight_heading = dir2angle(port.dir) + 180
	native_view.track_eye(pilot)
	walking_scene.update_view(native_view, walking_start, 0)
	var/matrix/camera_before_step = matrix(native_view.last_camera)
	var/source_anchor_before = walking_scene.canvas.screen_loc
	var/source_frame_before = walking_scene.frame.screen_loc
	var/old_camera_values = native_view.last_camera.tolist().Join(",")
	pilot.set_glide_size(8)
	TEST_ASSERT(pilot.Move(walking_end, SOUTH), "Walking camera fixture must move through the ordinary Move path")
	TEST_ASSERT_EQUAL(native_view.last_camera.c, camera_before_step.c, "A southward step must not shift the capture frame horizontally")
	TEST_ASSERT_EQUAL(native_view.last_camera.f - camera_before_step.f, world.icon_size, "After a 180-degree turn the capture frame must move with the ship, not twice as far in rotated local coordinates")
	TEST_ASSERT_EQUAL(walking_scene.canvas.screen_loc, source_anchor_before, "Walking must not move the source anchor")
	TEST_ASSERT_EQUAL(walking_scene.frame.screen_loc, source_frame_before, "Walking must not move the source crop")
	TEST_ASSERT_EQUAL(native_view.animation_started, world.time, "Walking projection must start in the movement tick")
	TEST_ASSERT_EQUAL(native_view.animation_duration, world.icon_size / max(pilot.glide_size, 1) * world.tick_lag, "Walking interpolation must match eye glide instead of the flight interval")
	TEST_ASSERT_EQUAL(length(walking_scene.chunks), 0, "Walking projection must not allocate or update terrain membership")
	var/turf/outside_ship = get_step(walking_end, SOUTH)
	TEST_ASSERT(pilot.Move(outside_ship, SOUTH), "Visibility fixture must step out of the Tadpole region")
	TEST_ASSERT_EQUAL(pilot.sight, SEE_INFRA, "Leaving must restore the latest underlying sight in the movement tick")
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
	// Translation belongs to source geometry, before the plane's viewport
	// crop. The completed plate must never pan by a chunk-origin residual.
	walking_scene.update_view(native_view, get_turf(pilot), 0)
	old_camera_values = native_view.last_camera.tolist().Join(",")
	var/projection_flight_x = helm.flight_x
	helm.flight_x += 0.5
	walking_scene.update_view(native_view, get_turf(pilot), 0.2)
	TEST_ASSERT_EQUAL(native_view.last_camera.tolist().Join(","), old_camera_values, "Flight translation must not shift the already cropped output plate")
	walking_scene.origin_x += 8
	walking_scene.update_view(native_view, get_turf(pilot), 0.2)
	TEST_ASSERT_EQUAL(native_view.last_camera.tolist().Join(","), old_camera_values, "A chunk boundary must not translate or rebase the output plate")
	helm.flight_x = projection_flight_x
	var/atom/movable/screen/plane_master/passenger_plate = native_view.plate
	qdel(native_view)
	TEST_ASSERT_EQUAL(pilot.sight, sight_before_view, "Scene departure must remove its sight modifier")
	TEST_ASSERT(!length(pilot.sight_modifiers), "Scene cleanup must leave no owned sight modifiers")
	qdel(walking_scene)
	TEST_ASSERT_NULL(passenger_plate.get_relay_to(TADPOLE_GROUND_PLANE), "Leaving the scene must remove the aircraft relay")
	TEST_ASSERT(passenger_plate.get_relay_to(RENDER_PLANE_TRANSPARENT), "Leaving must restore native multiz routing")
	var/turf/ground = locate(40,40,SSmapping.ground_start)
	TEST_ASSERT(SSmapping.z_level_to_plane_offset[ground.z] >= 1, "Ground planes must be allocated below transit before atom initialization")
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

/// Both visible features and the crop boundary must follow the hull while the
/// capture canvas remains untouched, including after a half turn.
/datum/unit_test/tadpole_flight/proc/check_fixed_capture(datum/tadpole_scene/scene, datum/tadpole_scene_view/view)
	var/obj/docking_port/mobile/port = scene.helm.shuttle_port
	var/old_width = port.width
	var/old_height = port.height
	var/old_heading = scene.helm.flight_heading
	port.width = 7
	port.height = 9
	var/source_anchor = scene.canvas.screen_loc
	var/source_frame = scene.frame.screen_loc
	TEST_ASSERT_EQUAL(source_anchor, "CENTER", "Capture anchor must have no passenger coordinate")
	TEST_ASSERT_EQUAL(source_frame, "CENTER-12,CENTER-12 to CENTER+12,CENTER+12", "Capture surface must allocate 25x25 tiles")
	TEST_ASSERT_EQUAL(view.capture_unlit.transform.a, 25, "Capture lighting backplane must cover the entire source width")
	TEST_ASSERT_EQUAL(view.capture_unlit.transform.e, 25, "Capture lighting backplane must cover the entire source height")
	var/datum/plane_master_group/group = view.capture_group
	for(var/key in group.plane_masters)
		var/atom/movable/screen/plane_master/master = group.plane_masters[key]
		for(var/atom/movable/render_plane_relay/relay as anything in master.relays)
			TEST_ASSERT_EQUAL(relay.screen_loc, "SCREEN_SOUTHWEST", "Capture relays must include offscreen source borders")
	for(var/angle in list(0, 37, 90, 180, 270))
		scene.helm.flight_heading = dir2angle(port.dir) + angle
		scene.update_source_position(0)
		var/list/source = scene.displayed_source_position()
		var/list/last_corner
		for(var/dy in list(0, 1))
			var/turf/eye = locate(port.x + 3, port.y + 4 - dy, port.z)
			scene.update_view(view, eye, 0)
			var/matrix/camera = view.last_camera
			var/raw_x = (scene.helm.flight_x + 4 - source[1]) * world.icon_size
			var/raw_y = (scene.helm.flight_y - 5 - source[2]) * world.icon_size
			var/projected_x = camera.a * raw_x + camera.b * raw_y + camera.c
			var/projected_y = camera.d * raw_x + camera.e * raw_y + camera.f
			var/expected_x = (port.x - eye.x + camera.a * 4 - camera.b * 5) * world.icon_size
			var/expected_y = (port.y - eye.y + camera.d * 4 - camera.e * 5) * world.icon_size
			TEST_ASSERT(abs(projected_x - expected_x) < 0.001 && abs(projected_y - expected_y) < 0.001, "Fixed capture must preserve the actual landing/ground coordinates")
			// This is a buffer corner, not a ground feature that could hide a
			// wrong crop behind eye-motion compensation.
			var/corner_x = camera.a * 12.5 * world.icon_size + camera.b * 12.5 * world.icon_size + camera.c
			var/corner_y = camera.d * 12.5 * world.icon_size + camera.e * 12.5 * world.icon_size + camera.f
			if(dy)
				TEST_ASSERT(abs(corner_x - last_corner[1]) < 0.001 && abs(corner_y - last_corner[2] - world.icon_size) < 0.001, "The crop boundary must follow the hull after a southward step at every heading")
			last_corner = list(corner_x, corner_y)
			TEST_ASSERT_EQUAL(scene.canvas.screen_loc, source_anchor, "Walking must not change the source anchor")
			TEST_ASSERT_EQUAL(scene.frame.screen_loc, source_frame, "Walking must not change the source crop")
			TEST_ASSERT_EQUAL(scene.displayed_source_position().Join(","), source.Join(","), "Walking must not change the captured ground coordinates")
	port.width = old_width
	port.height = old_height
	scene.helm.flight_heading = old_heading

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/flight_test/checkLandingSpot()
	return SHUTTLE_DOCKER_LANDING_CLEAR

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
