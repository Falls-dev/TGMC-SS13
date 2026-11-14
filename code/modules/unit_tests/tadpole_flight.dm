/// Continuous physics and the regression where lower-level explicit planes
/// escaped KEEP_TOGETHER and covered the Tadpole's actual floor.
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

	var/mutable_appearance/source = mutable_appearance('icons/effects/alphacolors.dmi', "red")
	source.plane = GAME_PLANE
	var/mutable_appearance/nested = mutable_appearance('icons/effects/alphacolors.dmi', "green")
	nested.plane = WALL_PLANE
	source.overlays += nested
	var/mutable_appearance/flattened = tadpole_ground_appearance(source, 0)
	TEST_ASSERT_EQUAL(source.plane, GAME_PLANE, "Flattening must preserve original ground appearances")
	TEST_ASSERT_EQUAL(flattened.plane, FLOAT_PLANE, "Ground objects must inherit the lower composite plane")
	for(var/child as anything in flattened.overlays)
		var/mutable_appearance/child_picture = new(child)
		TEST_ASSERT_EQUAL(child_picture.plane, FLOAT_PLANE, "Nested overlays must not escape over the shuttle floor")
	// Hidden alpha masks must remain offscreen after copying. Removing their
	// render_target turns corpse hair/wound masks into visible white sprites.
	var/mutable_appearance/masked_body = mutable_appearance('icons/effects/alphacolors.dmi', "red")
	var/mutable_appearance/private_mask = mutable_appearance('icons/effects/alphacolors.dmi', "white")
	private_mask.render_target = "*tadpole_corpse_test_mask"
	masked_body.overlays += private_mask
	masked_body.filters += filter(arglist(alpha_mask_filter(render_source = private_mask.render_target)))
	var/mutable_appearance/body_copy = tadpole_ground_appearance(masked_body, 0)
	var/mutable_appearance/mask_copy = new(body_copy.overlays[1])
	TEST_ASSERT_EQUAL(mask_copy.render_target, private_mask.render_target, "Corpse masks must retain their hidden render target")
	TEST_ASSERT_EQUAL(length(body_copy.filters), 1, "Copying must preserve mask filters")
	var/mutable_appearance/relay_picture = mutable_appearance()
	relay_picture.render_source = private_mask.render_target
	var/mutable_appearance/relay_copy = tadpole_ground_appearance(relay_picture, 0)
	TEST_ASSERT_EQUAL(relay_copy.render_source, relay_picture.render_source, "The copied mask render graph must stay connected")
	var/obj/effect/abstract/tadpole_ground/holder = allocate(/obj/effect/abstract/tadpole_ground, get_turf(port))
	TEST_ASSERT(holder.refresh_ground(start), "First rendering must build the ground appearance")
	var/rebuilds = 0
	for(var/i in 1 to 100)
		if(holder.refresh_ground(start))
			rebuilds++
	TEST_ASSERT_EQUAL(rebuilds, 0, "Static ground must not rebuild or resend its appearances on repeated refreshes")
	var/obj/item/ground_item = allocate(/obj/item, start)
	TEST_ASSERT(holder.refresh_ground(start), "A newly arrived object must invalidate the ground cache")
	TEST_ASSERT(!holder.refresh_ground(start), "An unchanged object must reuse the cache")
	ground_item.color = "#ff0000"
	TEST_ASSERT(holder.refresh_ground(start), "Appearance changes must invalidate the cache")
	ground_item.abstract_move(null)
	TEST_ASSERT(holder.refresh_ground(start), "Departing objects must disappear from the ground view")
	TEST_ASSERT_EQUAL(holder.plane, TADPOLE_GROUND_PLANE, "The ground composite must remain below the real floor")
	for(var/atom/movable/visual as anything in holder.vis_contents)
		TEST_ASSERT(istype(visual, /obj/effect/abstract/tadpole_ground_sprite), "Only normalized proxies may enter the ground composite")
	// Direction changes must be retained by the proxy itself, rather than
	// inherited from a south-facing tile container.
	var/obj/structure/tadpole_render_test/directional = allocate(/obj/structure/tadpole_render_test, start)
	directional.setDir(EAST)
	directional.pixel_x = -8
	directional.pixel_y = 12
	directional.pixel_w = 4
	directional.pixel_z = 6
	holder.refresh_ground(start)
	var/obj/effect/abstract/tadpole_ground_sprite/directional_copy = holder.sprites[length(holder.sprites)]
	TEST_ASSERT_EQUAL(directional_copy.dir, EAST, "An east-facing object must retain its own direction")
	TEST_ASSERT_EQUAL(directional_copy.pixel_x, -8, "Multi-tile sprite offsets must be retained")
	TEST_ASSERT_EQUAL(directional_copy.pixel_y, 12, "Vertical sprite offsets must be retained")
	TEST_ASSERT_EQUAL(directional_copy.pixel_w, 4, "SIDE_MAP horizontal offsets must be retained")
	TEST_ASSERT_EQUAL(directional_copy.pixel_z, 6, "SIDE_MAP vertical offsets must be retained")
	directional.setDir(WEST)
	TEST_ASSERT(holder.refresh_ground(start), "Direction changes must invalidate the snapshot cache")
	directional_copy = holder.sprites[length(holder.sprites)]
	TEST_ASSERT_EQUAL(directional_copy.dir, WEST, "Turning must update the proxy direction")
	var/obj/effect/abstract/tadpole_ground/neighbour_holder = allocate(/obj/effect/abstract/tadpole_ground)
	neighbour_holder.refresh_ground(get_step(start, EAST))
	TEST_ASSERT_EQUAL(length(neighbour_holder.sprites), 1, "A bounded object must not be duplicated on its secondary turf")
	TEST_ASSERT(directional_copy.layer > neighbour_holder.sprites[1]:layer, "An adjacent floor must not cover a multi-tile object's overhang")
	TEST_ASSERT(!(holder.appearance_flags & KEEP_TOGETHER), "Tile groups must not force overhangs underneath neighbouring floors")
	// The surface rotates coordinates, while every category selects the
	// corresponding DMI facing instead of remaining upside down at 180°.
	var/mob/living/ground_mob = allocate(/mob/living, start)
	ground_mob.invisibility = 0
	ground_mob.setDir(NORTH)
	holder.refresh_ground(start)
	holder.set_view_turn(180)
	for(var/i in 1 to length(holder.sprites))
		var/obj/effect/abstract/tadpole_ground_sprite/sprite = holder.sprites[i]
		TEST_ASSERT_EQUAL(sprite.dir, turn(holder.cached_ground_directions[i], 180), "Turfs, objects and mobs must use the opposite DMI facing after a half-turn")
		var/matrix/compensated = matrix(sprite.transform)
		compensated.Turn(-180)
		TEST_ASSERT(abs(compensated.a - 1) < 0.001 && abs(compensated.e - 1) < 0.001, "The surface's half-turn must not invert the sprite")
	holder.set_view_turn(90)
	for(var/obj/effect/abstract/tadpole_ground_sprite/sprite as anything in holder.sprites)
		TEST_ASSERT_EQUAL(sprite.dir, turn(sprite.source_direction, 90), "Quarter-turns must update every sprite category")
	holder.set_view_turn(0)
	for(var/obj/effect/abstract/tadpole_ground_sprite/sprite as anything in holder.sprites)
		TEST_ASSERT_EQUAL(sprite.dir, sprite.source_direction, "Returning to the initial heading must restore the original direction")
	// Rotate all eight neighbour bits; diagonal flags are not BYOND dirs.
	var/junction = NORTH_JUNCTION|EAST_JUNCTION|NORTHEAST_JUNCTION
	TEST_ASSERT_EQUAL(tadpole_rotate_junction(junction, 90), WEST_JUNCTION|NORTH_JUNCTION|NORTHWEST_JUNCTION, "Quarter-turns must rotate cardinal and diagonal connections together")
	TEST_ASSERT_EQUAL(tadpole_rotate_junction(junction, 180), SOUTH_JUNCTION|WEST_JUNCTION|SOUTHWEST_JUNCTION, "Half-turns must preserve the smoothing topology")
	TEST_ASSERT_EQUAL(tadpole_rotate_junction(junction, 360), junction, "Full turns must preserve the original junction")
	var/obj/structure/table/table_source = allocate(/obj/structure/table, start)
	table_source.set_smoothed_icon_state(junction)
	var/table_state = table_source.icon_state
	var/obj/effect/abstract/tadpole_ground_sprite/table_copy = allocate(/obj/effect/abstract/tadpole_ground_sprite)
	table_copy.configure_source(table_source, tadpole_ground_appearance(table_source.appearance, 0))
	table_copy.set_view_turn(90)
	TEST_ASSERT_EQUAL(table_copy.icon_state, "[table_source.base_icon_state]-[tadpole_rotate_junction(junction, 90)]", "Tables must select the state for rotated neighbours, not merely a new dir")
	TEST_ASSERT_EQUAL(table_source.icon_state, table_state, "View smoothing must not modify the real table")
	TEST_ASSERT_EQUAL(table_source.smoothing_junction, junction, "The actual map's connections must remain unchanged")
	var/obj/structure/tadpole_corners_test/corner_source = allocate(/obj/structure/tadpole_corners_test, start)
	corner_source.corners_cardinal_smooth(NORTH_JUNCTION)
	var/obj/effect/abstract/tadpole_ground_sprite/corner_copy = allocate(/obj/effect/abstract/tadpole_ground_sprite)
	corner_copy.configure_source(corner_source, tadpole_ground_appearance(corner_source.appearance, 0))
	// This fixture isolates corner assembly from map-dependent adjacency lookup.
	corner_copy.source_junction = NORTH_JUNCTION
	corner_copy.set_view_turn(90)
	TEST_ASSERT_EQUAL(corner_copy.top_left_corner, "1-w", "Corner smoothing must rebuild the northwest quadrant")
	TEST_ASSERT_EQUAL(corner_copy.bottom_right_corner, "3-w", "Corner smoothing must rebuild the southwest quadrant")
	var/obj/machinery/door/poddoor/two_tile_hor/door_source = allocate(/obj/machinery/door/poddoor/two_tile_hor, start)
	var/obj/effect/abstract/tadpole_ground_sprite/door_copy = allocate(/obj/effect/abstract/tadpole_ground_sprite)
	door_copy.configure_source(door_source, tadpole_ground_appearance(door_source.appearance, 0))
	door_copy.set_view_turn(90)
	TEST_ASSERT_EQUAL(door_copy.icon, 'icons/obj/doors/1x2blast_vert.dmi', "Blast doors must select the vertical asset on quarter-turns")
	var/matrix/door_matrix = door_copy.transform
	TEST_ASSERT(abs(door_matrix.c - 16) < 0.001 && abs(door_matrix.f + 16) < 0.001, "A tall door canvas must be anchored to the rotated occupied cells")
	door_copy.set_view_turn(180)
	TEST_ASSERT_EQUAL(door_copy.icon, door_source.icon, "Half-turns must restore the horizontal door asset")
	door_matrix = door_copy.transform
	TEST_ASSERT(abs(door_matrix.c) < 0.001 && abs(door_matrix.f) < 0.001, "The DMI-centre correction must not shift a reversed double door by an extra tile")
	var/obj/alien/weeds/weedwall/wall_weeds = allocate(/obj/alien/weeds/weedwall, start)
	wall_weeds.icon_state = "weedwall-[junction]"
	var/obj/effect/abstract/tadpole_ground_sprite/weeds_copy = allocate(/obj/effect/abstract/tadpole_ground_sprite)
	weeds_copy.configure_source(wall_weeds, tadpole_ground_appearance(wall_weeds.appearance, 0))
	weeds_copy.set_view_turn(90)
	TEST_ASSERT_EQUAL(weeds_copy.icon_state, "weedwall-[tadpole_rotate_junction(junction, 90)]", "Wall weeds must rotate their borrowed host junction")
	weeds_copy.set_view_turn(180)
	TEST_ASSERT_EQUAL(weeds_copy.icon_state, "weedwall-[tadpole_rotate_junction(junction, 180)]", "Wall weeds must keep matching their host after a half-turn")
	TEST_ASSERT_EQUAL(wall_weeds.icon_state, "weedwall-[junction]", "Rendering must not change the real weeds")
	var/obj/alien/weeds/sticky/ground_weeds = allocate(/obj/alien/weeds/sticky, start)
	ground_weeds.icon_state = "weed_dir5green"
	var/obj/effect/abstract/tadpole_ground_sprite/ground_weeds_copy = allocate(/obj/effect/abstract/tadpole_ground_sprite)
	ground_weeds_copy.configure_source(ground_weeds, tadpole_ground_appearance(ground_weeds.appearance, 0))
	ground_weeds_copy.set_view_turn(90)
	TEST_ASSERT_EQUAL(ground_weeds_copy.icon_state, "weed_dir9green", "Ordinary weeds must rotate the encoded adjacency and preserve their colour suffix")
	ground_weeds_copy.set_view_turn(180)
	TEST_ASSERT_EQUAL(ground_weeds_copy.icon_state, "weed_dir10green", "Ordinary weeds must select the opposite connection state after a half-turn")
	TEST_ASSERT_EQUAL(ground_weeds.icon_state, "weed_dir5green", "Rendering must not change actual weed connections")
	// A 64x64 creature can have a one-tile collision box. Its DMI centre,
	// rather than collision width, must determine the rotation compensation.
	var/mob/living/large_sprite_source = allocate(/mob/living, start)
	large_sprite_source.icon = 'icons/Xeno/castes/runner/basic.dmi'
	large_sprite_source.icon_state = "Runner Walking"
	large_sprite_source.pixel_x = -16
	large_sprite_source.pixel_y = 0
	var/obj/effect/abstract/tadpole_ground_sprite/large_sprite_copy = allocate(/obj/effect/abstract/tadpole_ground_sprite)
	large_sprite_copy.configure_source(large_sprite_source, tadpole_ground_appearance(large_sprite_source.appearance, 0))
	large_sprite_copy.set_view_turn(180)
	var/matrix/large_matrix = large_sprite_copy.transform
	TEST_ASSERT(abs(large_matrix.c) < 0.001 && abs(large_matrix.f + 32) < 0.001, "A 64x64 mob must retain its tile anchor after a half-turn")
	large_sprite_copy.set_view_depth(1)
	var/rear_mob_layer = large_sprite_copy.layer
	large_sprite_copy.set_view_turn(90)
	TEST_ASSERT_EQUAL(large_sprite_copy.layer, rear_mob_layer, "Changing direction must not reset the mob's depth behind the terrain")
	var/foreground_wall = tadpole_ground_depth_layer(WALL_PLANE, CLOSED_TURF_LAYER, 0)
	TEST_ASSERT(foreground_wall > rear_mob_layer, "A foreground wall must occlude a mob behind it")
	large_sprite_copy.set_view_depth(-1)
	TEST_ASSERT(large_sprite_copy.layer > foreground_wall, "A mob in front of a wall must remain visible")
	TEST_ASSERT(large_sprite_copy.layer > tadpole_ground_depth_layer(FLOOR_PLANE, LOW_FLOOR_LAYER, -10), "Floor tiles must never cover a mob")
	var/turf/opaque_location = locate(60, 60, start.z)
	var/previous_turf_type = opaque_location.type
	var/turf/closed/wall/opaque_test_wall = opaque_location.ChangeTurf(/turf/closed/wall)
	large_sprite_source.forceMove(opaque_test_wall)
	var/mob_hidden_in_wall = !tadpole_ground_mob_visible(large_sprite_source)
	large_sprite_source.forceMove(start)
	opaque_test_wall.ChangeTurf(previous_turf_type)
	TEST_ASSERT(mob_hidden_in_wall, "A corpse or mob inside an opaque wall must not be exposed by the flight view")
	qdel(holder)
	port.setDir(NORTH)
	eye.abstract_move(start)
	helm.flight_x = start.x + 0.25
	helm.flight_y = start.y
	helm.flight_heading = 0
	helm.ground_tiles[get_turf(port)] = TRUE
	helm.update_ground_bounds(FALSE)
	TEST_ASSERT_NULL(helm.ground_view_bounds, "An empty shuttle must not render the whole transit reservation")
	helm.update_ground_view()
	holder = helm.ground_holders[start]
	TEST_ASSERT_NOTNULL(holder, "The lower level must render beneath the shuttle")
	TEST_ASSERT_EQUAL(holder.pixel_x, 0, "Tiles must remain on the unrotated integer grid")
	TEST_ASSERT_EQUAL(length(holder.overlays), 1, "Each terrain tile must receive one cached cloud haze appearance")
	var/mutable_appearance/cloud_haze = new(holder.overlays[1])
	TEST_ASSERT_EQUAL(cloud_haze.icon, 'icons/turf/space.dmi', "Haze must reuse the original cloud sprite resource")
	TEST_ASSERT(cloud_haze.alpha > 0 && cloud_haze.alpha < 100, "Cloud haze must leave the ground visible")
	TEST_ASSERT(holder in helm.ground_surface.vis_contents, "Terrain tiles must share one compositing surface")
	var/matrix/first_transform = helm.ground_surface.transform
	TEST_ASSERT_EQUAL(first_transform.c, -8, "A quarter tile of flight must scroll the whole surface by eight pixels")
	helm.flight_x += 0.25
	helm.update_ground_view()
	TEST_ASSERT_EQUAL(helm.ground_holders[start], holder, "Scrolling must reuse the same source tile rather than swapping pictures")
	TEST_ASSERT_EQUAL(holder.pixel_x, 0, "Fractional scrolling must never move individual tiles")
	var/matrix/second_transform = helm.ground_surface.transform
	TEST_ASSERT_EQUAL(second_transform.c, -16, "Fractional motion must belong to the shared surface")
	helm.flight_heading = 45
	helm.ground_view_bounds = list(port.x - 2, port.y - 2, port.x + 2, port.y + 2)
	helm.next_ground_bounds = world.time + 10 SECONDS
	helm.update_ground_view()
	holder = helm.ground_holders[start]
	TEST_ASSERT_NOTNULL(holder, "Turning must preserve visible terrain")
	var/matrix/tile_transform = holder.transform || matrix()
	TEST_ASSERT_EQUAL(tile_transform.a, 1, "Individual tiles must retain their unrotated grid")
	TEST_ASSERT_EQUAL(tile_transform.b, 0, "Only the shared surface may rotate")
	helm.clear_ground_view()
	TEST_ASSERT_EQUAL(length(helm.ground_holders), 0, "Landing must release ground visuals")
	TEST_ASSERT_NULL(helm.ground_surface, "Landing must release the composite surface")
	TEST_ASSERT_EQUAL(helm.flight_velocity_x, 0, "Landing must clear linear inertia")
	TEST_ASSERT_EQUAL(helm.flight_turn_velocity, 0, "Landing must clear rotational inertia")
	// Landing must not use the camera placement overlays or leave control
	// state behind, including an idempotent second cleanup from UI callbacks.
	var/image/footprint = image('icons/effects/alphacolors.dmi', start, "red")
	eye.placement_images[footprint] = list(0, 0)
	helm.show_landing_spot()
	TEST_ASSERT_EQUAL(length(eye.placed_images), 0, "The Tadpole must not draw the old camera landing overlay")
	eye.placed_images += image('icons/effects/alphacolors.dmi', start, "blue")
	helm.current_user = pilot
	pilot.remote_control = eye
	helm.remove_eye_control(pilot)
	TEST_ASSERT_NULL(pilot.remote_control, "Landing must release movement control")
	TEST_ASSERT_NULL(helm.current_user, "Landing must release the helm")
	TEST_ASSERT_NULL(eye.eye_user, "Landing must detach the logical ground eye")
	TEST_ASSERT_EQUAL(length(eye.placed_images), 0, "Landing must clear stale blue footprint images")
	eye.placed_images += image('icons/effects/alphacolors.dmi', start, "blue")
	helm.remove_eye_control(pilot)
	TEST_ASSERT_EQUAL(length(eye.placed_images), 0, "Repeated UI cleanup must remove images after the helm was already released")
	var/obj/structure/tadpole_click_test/click_target = allocate(/obj/structure/tadpole_click_test, get_turf(pilot))
	pilot.next_click = 0
	pilot.next_move = 0
	pilot.ClickOn(click_target, "map", "left=1")
	TEST_ASSERT_EQUAL(click_target.hand_clicks, 1, "Ordinary map clicks must reach the clicked object after landing cleanup")
	// Movement signals must drive a persistent visual immediately, without
	// waiting for the half-second terrain cache refresh.
	var/turf/walk_start = locate(run_loc_floor_top_right.x - 2, run_loc_floor_top_right.y - 2, run_loc_floor_top_right.z)
	var/mob/living/walker = allocate(/mob/living, walk_start)
	helm.ground_surface = new(get_turf(helm))
	helm.ground_origin_x = walker.x
	helm.ground_origin_y = walker.y
	helm.track_ground_mob(walker)
	var/obj/effect/abstract/tadpole_mobile_anchor/mobile_visual = helm.ground_mobs[walker]
	TEST_ASSERT_NOTNULL(mobile_visual, "Visible mobs must get a persistent visual")
	walker.set_glide_size(8)
	TEST_ASSERT(walker.Move(get_step(walker, EAST), EAST, 8), "The movement fixture must take a real step")
	TEST_ASSERT_EQUAL(helm.ground_mobs[walker], mobile_visual, "Moving between tiles must preserve visual identity")
	TEST_ASSERT_EQUAL(mobile_visual.last_glide_duration, world.icon_size / walker.glide_size * world.tick_lag, "A real move must use the source mob's glide timing")
	TEST_ASSERT(mobile_visual.last_glide_duration > 0, "Ordinary steps must glide rather than teleport")
	TEST_ASSERT_EQUAL(mobile_visual.to_x, 32, "The movement event must update the visual target immediately")
	walker.setDir(NORTH)
	TEST_ASSERT_EQUAL(mobile_visual.sprite.dir, turn(NORTH, mobile_visual.last_turn), "Direction changes must update without waiting for the terrain cache")
	walker.forceMove(walk_start)
	TEST_ASSERT_EQUAL(mobile_visual.last_glide_duration, 0, "Real teleports must not glide across intervening tiles")
	qdel(walker)
	TEST_ASSERT_NULL(helm.ground_mobs[walker], "Deleting a mob must release its visual and movement subscriptions")
	helm.clear_ground_view()
	TEST_ASSERT_EQUAL(length(helm.ground_mobs), 0, "Landing must clear all mobile visuals")
	helm.eyeobj = null

/obj/structure/tadpole_click_test
	var/hand_clicks = 0

/obj/structure/tadpole_click_test/attack_hand(mob/living/user)
	hand_clicks++

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/flight_test/checkLandingSpot()
	return SHUTTLE_DOCKER_LANDING_CLEAR

/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/flight_test/check_hovering_spot(turf/next_turf)
	return TRUE

/// A visible two-tile source used to catch duplication and direction regressions.
/obj/structure/tadpole_render_test
	icon = 'icons/obj/doors/1x2blast_hor.dmi'
	icon_state = "pdoor1"
	bound_width = 64
	bound_height = 32

/obj/structure/tadpole_corners_test
	icon = 'icons/effects/alphacolors.dmi'
	smoothing_flags = SMOOTH_CORNERS
