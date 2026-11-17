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


	// Scene relays real turfs and keeps source appearance/planes untouched.
	var/obj/effect/abstract/tadpole_native_tile/chunk = allocate(/obj/effect/abstract/tadpole_native_tile)
	var/original_picture = start.appearance
	var/original_plane = start.plane
	chunk.build(start.x, start.y, start.z)
	TEST_ASSERT_EQUAL(chunk.source, start, "A native holder must own exactly one real turf")
	TEST_ASSERT(start in chunk.vis_contents, "Native scene must share the actual turf")
	TEST_ASSERT_EQUAL(length(chunk.vis_contents), 1, "A holder must expose one turf instead of a whole 8x8 subtree")
	TEST_ASSERT(!(get_step(start, EAST) in chunk.vis_contents), "Neighbor turfs must have independent spatial holders")
	TEST_ASSERT(!(get_step(start, NORTH) in chunk.vis_contents), "A source holder must not retain a neighbor subtree")
	for(var/atom/source as anything in chunk.vis_contents)
		TEST_ASSERT(isturf(source), "Holders must reference the actual turf, not appearance or movable copies")
	TEST_ASSERT_EQUAL(start.appearance, original_picture, "Native relay must not rewrite source geometry")
	TEST_ASSERT_EQUAL(start.plane, original_plane, "Native relay must not modify source planes")
	var/obj/item/item = allocate(/obj/item, start)
	var/turf/destination = get_step(start, EAST)
	item.forceMove(destination)
	TEST_ASSERT(start in chunk.vis_contents, "Object movement must not rebuild the terrain relay")
	TEST_ASSERT_EQUAL(length(chunk.vis_contents), 1, "Object movement must allocate no motion proxies")
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
	chunk.build(destination.x, destination.y, destination.z)
	chunk.reconnect(start)
	TEST_ASSERT_EQUAL(chunk.source, destination, "A reused holder must retain its new source")
	TEST_ASSERT(destination in chunk.vis_contents, "An old turf callback must retain the new visual link")
	TEST_ASSERT(!(start in chunk.vis_contents), "An old turf callback must not restore its previous source")
	chunk.clear_source()
	TEST_ASSERT_NULL(chunk.loc, "An idle pool entry must have no spatial location")
	TEST_ASSERT_NULL(chunk.source, "An idle pool entry must release its source")
	TEST_ASSERT_EQUAL(length(chunk.vis_contents), 0, "An idle pool entry must expose no turf tree")
	qdel(chunk)
	TEST_ASSERT_EQUAL(chunk.source, null, "Scene deletion must release source subscriptions")
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
	TEST_ASSERT_EQUAL(scene.source_radius(list(19, 15)), scene.source_radius(list(61, 57)), "Ghost zoom must not enlarge the shared terrain cache")
	scene.source_z = SSmapping.ground_start
	scene.origin_x = FLOOR(helm.flight_x / 8, 1) * 8
	scene.origin_y = FLOOR(helm.flight_y / 8, 1) * 8
	scene.radius = scene.source_radius(list(19, 15))
	scene.update_sources()
	var/key = "[round(helm.flight_x)],[round(helm.flight_y)],[scene.source_z]"
	var/obj/effect/abstract/tadpole_native_tile/edge_chunk = scene.sources[key]
	TEST_ASSERT_NOTNULL(edge_chunk, "The native window must contain the central source turf")
	var/count = length(scene.sources)
	TEST_ASSERT(count <= 1024, "An idle 25x25 capture must not attach thousands of prefetched turfs")
	var/nearby_blocks = 0
	for(var/obj/effect/abstract/tadpole_native_tile/nearby in range(5, helm))
		nearby_blocks++
	TEST_ASSERT(nearby_blocks > 0 && nearby_blocks < count / 2, "Source holders must be distributed spatially, not piled on the helm")
	for(var/chunk_key in scene.sources)
		var/obj/effect/abstract/tadpole_native_tile/spatial_block = scene.sources[chunk_key]
		var/turf/first_source = spatial_block.source
		TEST_ASSERT_EQUAL(length(spatial_block.vis_contents), 1, "Every active holder must contain exactly one real turf")
		TEST_ASSERT_EQUAL((spatial_block.x - port.x) * world.icon_size + spatial_block.pixel_x, (first_source.x - helm.flight_x) * world.icon_size, "Spatial placement must preserve source x projection")
		TEST_ASSERT_EQUAL((spatial_block.y - port.y) * world.icon_size + spatial_block.pixel_y, (first_source.y - helm.flight_y) * world.icon_size, "Spatial placement must preserve source y projection")
	TEST_ASSERT(!scene.update_sources(), "An unchanged capture must skip membership scans and allocation")
	TEST_ASSERT_EQUAL(scene.sources[key], edge_chunk, "Unchanged source cells must retain their holder")
	TEST_ASSERT_EQUAL(length(scene.sources), count, "Repeated checks must not allocate extra holders")
	// Scroll exactly one source tile. Retiring the outgoing strip before
	// attaching the incoming strip must reuse objects rather than create a burst.
	var/list/before_scroll = scene.sources.Copy()
	var/list/allocated = list()
	for(var/source_key in before_scroll)
		allocated += before_scroll[source_key]
	scene.source_from_x = helm.flight_x + 1
	scene.source_to_x = helm.flight_x + 1
	scene.source_from_y = helm.flight_y
	scene.source_to_y = helm.flight_y
	scene.source_duration = 0
	scene.update_sources()
	TEST_ASSERT_EQUAL(length(scene.sources), count, "A one-tile scroll must retain the active window size")
	for(var/source_key in scene.sources)
		TEST_ASSERT(scene.sources[source_key] in allocated, "Incoming strips must reuse outgoing holders without creating new atoms")
	scene.source_from_x = null
	scene.source_to_x = null
	scene.source_to_y = null
	scene.update_sources()
	var/old_width = port.width
	var/old_height = port.height
	port.width = 7
	port.height = 9
	var/list/viewport = list(26, 26)
	scene.origin_x = FLOOR(helm.flight_x / 8, 1) * 8
	scene.origin_y = FLOOR(helm.flight_y / 8, 1) * 8
	scene.radius = scene.source_radius(viewport)
	scene.update_sources()
	TEST_ASSERT(length(scene.sources) <= 1600, "A hull-centered idle capture must not restore the retired several-thousand-turf prefetch")
	var/list/stable_blocks = scene.sources.Copy()
	var/turf/pilot_start = get_turf(pilot)
	scene.update_source_position(0)
	for(var/i in 1 to 4)
		pilot.forceMove(i % 2 ? get_step(pilot_start, EAST) : pilot_start)
		TEST_ASSERT(!scene.update_region(scene.source_radius(viewport), scene.source_z), "Passenger movement must not trigger a terrain rebuild")
		TEST_ASSERT(!scene.update_source_position(0.2), "Walking must not restart shared terrain movement")
	TEST_ASSERT_EQUAL(length(scene.sources), length(stable_blocks), "Walking must retain the same block count")
	for(var/chunk_key in stable_blocks)
		TEST_ASSERT_EQUAL(scene.sources[chunk_key], stable_blocks[chunk_key], "Walking must preserve every cached block identity")
	// A bucket transition during a source animation changes membership only.
	var/flight_before_x = helm.flight_x
	var/list/effective_before = scene.displayed_source_position()
	var/center_key = "[scene.origin_x],[scene.origin_y],[scene.source_z]"
	var/obj/effect/abstract/tadpole_native_tile/center_chunk = scene.sources[center_key]
	helm.flight_x += 8
	scene.update_source_position(1)
	scene.source_started = world.time - 5
	var/list/source_before = scene.displayed_source_position()
	TEST_ASSERT(abs(source_before[1] - effective_before[1] - 4) < 0.001, "Shared terrain must interpolate the actual flight position")
	TEST_ASSERT(scene.update_region(scene.radius, scene.source_z), "Crossing eight tiles must update source membership")
	TEST_ASSERT_EQUAL(scene.displayed_source_position().Join(","), source_before.Join(","), "Changing cache origin must not move the displayed terrain")
	TEST_ASSERT_EQUAL(scene.sources[center_key], center_chunk, "A source-window seam must retain overlapping holders")
	check_source_coverage(scene)
	helm.flight_x = flight_before_x
	pilot.forceMove(pilot_start)
	port.width = old_width
	port.height = old_height
	qdel(scene)
	TEST_ASSERT_EQUAL(length(scene.sources), 0, "Scene deletion must release all native blocks")
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
	var/walking_heading = helm.flight_heading
	helm.flight_heading = dir2angle(port.dir) + 180
	native_view.track_eye(pilot)
	walking_scene.update_view(native_view, walking_start, 0)
	var/old_camera_values = native_view.last_camera.tolist().Join(",")
	var/old_capture_y = native_view.capture_y
	var/turf/fixed_eye_before = get_turf(walking_scene.render_origin)
	pilot.set_glide_size(8)
	TEST_ASSERT(pilot.Move(walking_end, SOUTH), "Walking camera fixture must move through the ordinary Move path")
	TEST_ASSERT_EQUAL(native_view.capture_y - old_capture_y, world.icon_size, "A southward step must move the source crop north in screen coordinates, regardless of heading")
	TEST_ASSERT_EQUAL(get_turf(walking_scene.render_origin), fixed_eye_before, "Walking must leave the hull render origin fixed")
	TEST_ASSERT_EQUAL(native_view.last_camera.f, 2 * native_view.capture_y, "Half-turn projection must rotate about the current screen position of the hull")
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
/datum/unit_test/tadpole_flight/proc/check_source_coverage(datum/tadpole_scene/scene)
	var/old_heading = scene.helm.flight_heading
	for(var/angle in list(0, 37, 90, 180, 270))
		scene.helm.flight_heading = dir2angle(scene.helm.shuttle_port.dir) + angle
		scene.update_source_position(0.2)
		var/dx = scene.render_origin.x - scene.helm.shuttle_port.x
		var/dy = scene.render_origin.y - scene.helm.shuttle_port.y
		var/list/geometry = scene.capture_geometry()
		var/half_side = geometry[1] / 2
		for(var/phase in list(0, 0.5, 1))
			var/cx = scene.source_from_x + (scene.source_to_x - scene.source_from_x) * phase + dx
			var/cy = scene.source_from_y + (scene.source_to_y - scene.source_from_y) * phase + dy
			for(var/sx in list(-half_side, half_side))
				for(var/sy in list(-half_side, half_side))
					var/tx = FLOOR(cx + sx, 1)
					var/ty = FLOOR(cy + sy, 1)
					TEST_ASSERT_NOTNULL(scene.sources["[tx],[ty],[scene.source_z]"], "Source strips must cover the shared hull crop throughout flight interpolation and rotation")
	scene.helm.flight_heading = old_heading
	scene.update_source_position(0)

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
	var/list/geometry = scene.capture_geometry()
	var/datum/tadpole_viewport/adapter = allocate(/datum/tadpole_viewport)
	adapter.owner = view
	adapter.frame = allocate(/atom/movable/screen/background/tadpole_view_bounds)
	TEST_ASSERT_EQUAL(adapter.configure("19x15"), "[geometry[2]]x[geometry[3]]", "Native character camera must allocate the calculated hull margin")
	TEST_ASSERT_EQUAL(view.capture_width, geometry[1], "Viewport setup must install the shared hull crop")
	TEST_ASSERT_EQUAL(adapter.configure("61x57"), "[geometry[2]]x[geometry[3]]", "Observer zoom must not expand the hull source window")
	qdel(adapter)
	var/icon/mask = view.capture_mask(geometry[1], geometry[1])
	TEST_ASSERT_EQUAL(mask.Width(), geometry[1] * world.icon_size, "Source crop must cover the hull-centered rotation buffer")
	var/list/hull = port.return_coords(port.x, port.y, port.dir)
	var/list/visible = getviewsize(CONFIG_GET(string/default_view))
	for(var/angle in list(0, 37, 90, 180, 270))
		scene.helm.flight_heading = dir2angle(port.dir) + angle
		scene.update_source_position(0)
		var/list/source = scene.displayed_source_position()
		for(var/ex in list(hull[1], anchor_before.x, hull[3]))
			for(var/ey in list(hull[2], anchor_before.y, hull[4]))
				var/turf/eye = locate(ex, ey, port.z)
				scene.update_view(view, eye, 0)
				var/matrix/camera = view.last_camera
				var/raw_x = (port.x + scene.helm.flight_x + 2 - source[1] - eye.x) * world.icon_size
				var/raw_y = (port.y + scene.helm.flight_y - 3 - source[2] - eye.y) * world.icon_size
				var/projected_x = camera.a * raw_x + camera.b * raw_y + camera.c
				var/projected_y = camera.d * raw_x + camera.e * raw_y + camera.f
				var/expected_x = (port.x - eye.x + camera.a * 2 - camera.b * 3) * world.icon_size
				var/expected_y = (port.y - eye.y + camera.d * 2 - camera.e * 3) * world.icon_size
				TEST_ASSERT(abs(projected_x - expected_x) < 0.001 && abs(projected_y - expected_y) < 0.001, "Native-eye projection must retain actual ground/landing coordinates at every hull edge and heading")
				TEST_ASSERT_EQUAL(view.capture_x, (anchor_before.x - ex) * world.icon_size, "Crop center must follow the hull in screen space")
				TEST_ASSERT_EQUAL(view.capture_y, (anchor_before.y - ey) * world.icon_size, "Crop y must follow the hull independently of heading")
				for(var/sx in list(-visible[1] / 2, visible[1] / 2))
					for(var/sy in list(-visible[2] / 2, visible[2] / 2))
						var/dx = anchor_before.x - ex
						var/dy = anchor_before.y - ey
						// Inverse of an orthogonal rotation is its transpose.
						var/crop_x = camera.a * (sx - dx) + camera.d * (sy - dy)
						var/crop_y = camera.b * (sx - dx) + camera.e * (sy - dy)
						TEST_ASSERT(abs(crop_x) <= geometry[1] / 2 && abs(crop_y) <= geometry[1] / 2, "Rotated hull crop must cover every normal-window corner at every hull edge")
						TEST_ASSERT(abs(crop_x + dx) <= geometry[2] / 2 && abs(crop_y + dy) <= geometry[3] / 2, "Native viewport must contain the entire required source before rotation")
				TEST_ASSERT_EQUAL(scene.displayed_source_position().Join(","), source.Join(","), "Walking must not restart shared source movement")
				TEST_ASSERT_EQUAL(game_relay.transform.tolist().Join(","), game_transform_before, "Native camera following must never transform the final game relay")
				TEST_ASSERT_EQUAL(hud_relay.transform.tolist().Join(","), hud_transform_before, "Native camera following must never transform the HUD")
	view.end_capture()
	TEST_ASSERT_NULL(view.plate.get_filter("tadpole_capture_bounds"), "Release must remove its crop filter")
	TEST_ASSERT(!view.capture_active, "Release must clear capture state")
	port.width = old_width
	port.height = old_height
	scene.helm.flight_heading = old_heading
	scene.ensure_render_origin()

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
