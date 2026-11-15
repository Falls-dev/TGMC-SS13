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
	scene.source_z = SSmapping.ground_start
	scene.origin_x = 40
	scene.origin_y = 40
	scene.radius = 16
	scene.update_chunks()
	var/key = "56,56,[scene.source_z]"
	var/obj/effect/abstract/tadpole_native_chunk/edge_chunk = scene.chunks[key]
	TEST_ASSERT_NOTNULL(edge_chunk, "Prefetch must cover the last cell of an eight-tile camera bucket")
	var/count = length(scene.chunks)
	var/nearby_blocks = 0
	for(var/obj/effect/abstract/tadpole_native_chunk/nearby in range(13, helm))
		nearby_blocks++
	TEST_ASSERT(nearby_blocks > 0 && nearby_blocks < count / 2, "An eye near the helm must not have every cached block on its local turfs")
	for(var/chunk_key in scene.chunks)
		var/obj/effect/abstract/tadpole_native_chunk/spatial_block = scene.chunks[chunk_key]
		var/turf/first_source = spatial_block.tiles[1]
		TEST_ASSERT_EQUAL((spatial_block.x - port.x) * world.icon_size + spatial_block.pixel_x, (first_source.x - scene.origin_x) * world.icon_size, "Spatial placement must preserve source x projection")
		TEST_ASSERT_EQUAL((spatial_block.y - port.y) * world.icon_size + spatial_block.pixel_y, (first_source.y - scene.origin_y) * world.icon_size, "Spatial placement must preserve source y projection")
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
	for(var/i in 1 to 4)
		pilot.forceMove(i % 2 ? get_step(pilot_start, EAST) : pilot_start)
		TEST_ASSERT(!scene.update_region(scene.source_radius(viewport), scene.source_z), "Passenger movement must not trigger a terrain rebuild or zero-shift camera rebase")
	TEST_ASSERT_EQUAL(length(scene.chunks), length(stable_blocks), "Walking must retain the same block count")
	for(var/chunk_key in stable_blocks)
		TEST_ASSERT_EQUAL(scene.chunks[chunk_key], stable_blocks[chunk_key], "Walking must preserve every cached block identity")
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
	var/datum/tadpole_scene_view/native_view = new(display, 1, walking_scene)
	TEST_ASSERT_NOTNULL(native_view.plate, "Ground must have a preallocated native lower render plate")
	TEST_ASSERT(native_view.plate.get_relay_to(TADPOLE_GROUND_PLANE), "Passenger plate must relay below the physical craft")
	TEST_ASSERT_EQUAL(other_plate.render_relay_planes.Join(","), original_targets.Join(","), "Another observer must retain their native graph")
	// Exercise the real Move -> COMSIG_MOVABLE_MOVED path without calling
	// the 0.2-second scene processor. Headless fixture has a HUD but no client.
	var/turf/walking_start = get_turf(pilot)
	var/turf/walking_end = get_step(walking_start, EAST)
	var/list/old_ground_tiles = helm.ground_tiles
	helm.ground_tiles = list()
	helm.ground_tiles[walking_start] = TRUE
	helm.ground_tiles[walking_end] = TRUE
	var/walking_heading = helm.flight_heading
	helm.flight_heading = dir2angle(port.dir) + 37
	native_view.track_eye(pilot)
	walking_scene.update_view(native_view, walking_start, 0)
	var/old_camera_values = native_view.last_camera.tolist().Join(",")
	pilot.set_glide_size(8)
	TEST_ASSERT(pilot.Move(walking_end, EAST), "Walking camera fixture must move through the ordinary Move path")
	TEST_ASSERT_NOTEQUAL(native_view.last_camera.tolist().Join(","), old_camera_values, "A passenger step must update projection before flight processing runs")
	TEST_ASSERT_EQUAL(native_view.animation_started, world.time, "Walking projection must start in the movement tick")
	TEST_ASSERT_EQUAL(native_view.animation_duration, world.icon_size / max(pilot.glide_size, 1) * world.tick_lag, "Walking interpolation must match eye glide instead of the flight interval")
	TEST_ASSERT_EQUAL(length(walking_scene.chunks), 0, "Walking projection must not allocate or update terrain membership")
	native_view.track_eye(eye)
	old_camera_values = native_view.last_camera.tolist().Join(",")
	pilot.forceMove(walking_start)
	TEST_ASSERT_EQUAL(native_view.last_camera.tolist().Join(","), old_camera_values, "Changing the watched eye must unregister the old movement signal")
	native_view.track_eye(null)
	helm.flight_heading = walking_heading
	helm.ground_tiles = old_ground_tiles
	// Rebase halfway through an actual camera interpolation. Shifting the
	// source grid and inverse-shifting the camera must preserve every pixel.
	var/matrix/target = matrix()
	target.Turn(-37)
	target.Translate(14, -7)
	native_view.update_camera(target, 1)
	native_view.animation_started = world.time - 5
	var/matrix/before_rebase = native_view.displayed_camera()
	var/screen_x = before_rebase.a * 64 + before_rebase.b * 128 + before_rebase.c
	var/screen_y = before_rebase.d * 64 + before_rebase.e * 128 + before_rebase.f
	native_view.rebase_camera(256, -256)
	var/matrix/after_rebase = native_view.displayed_camera()
	TEST_ASSERT(abs(after_rebase.a * (64 - 256) + after_rebase.b * (128 + 256) + after_rebase.c - screen_x) < 0.001, "An eight-tile rebase must preserve displayed x during a turn")
	TEST_ASSERT(abs(after_rebase.d * (64 - 256) + after_rebase.e * (128 + 256) + after_rebase.f - screen_y) < 0.001, "An eight-tile rebase must preserve displayed y during a turn")
	TEST_ASSERT_EQUAL(native_view.animation_duration, 5, "Rebase must retain only the unfinished half of the animation")
	var/atom/movable/screen/plane_master/passenger_plate = native_view.plate
	qdel(native_view)
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
