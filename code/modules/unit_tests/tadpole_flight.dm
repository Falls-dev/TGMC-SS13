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
	// Changing only native lighting underlays must not invalidate geometry.
	var/mutable_appearance/changing_light = mutable_appearance(LIGHTING_ICON)
	changing_light.plane = LIGHTING_PLANE - PLANE_RANGE * SSmapping.z_level_to_plane_offset[start.z]
	var/lighting_rebuilds = 0
	for(var/i in 1 to 25)
		changing_light.color = rgb(i * 5, 0, 0)
		start.underlays += changing_light
		if(holder.refresh_ground(start))
			lighting_rebuilds++
		start.underlays -= changing_light
	TEST_ASSERT_EQUAL(lighting_rebuilds, 0, "Moving light must not trigger repeated terrain/sprite reconstruction")
	var/obj/item/ground_item = allocate(/obj/item, start)
	TEST_ASSERT(holder.refresh_ground(start), "A newly arrived object must invalidate the ground cache")
	TEST_ASSERT(!holder.refresh_ground(start), "An unchanged object must reuse the cache")
	ground_item.color = "#ff0000"
	TEST_ASSERT(holder.refresh_ground(start), "Appearance changes must invalidate the cache")
	var/atom/movable/vis_obj/fulton_balloon/attached_canopy = allocate(/atom/movable/vis_obj/fulton_balloon)
	attached_canopy.icon_state = "fulton_balloon"
	var/item_before_attachment = ground_item.appearance
	ground_item.vis_contents += attached_canopy
	TEST_ASSERT_EQUAL(ground_item.appearance, item_before_attachment, "Fixture must exercise a vis_contents-only change")
	TEST_ASSERT(holder.refresh_ground(start), "Attached visuals must invalidate terrain snapshots even when appearance is unchanged")
	var/mutable_appearance/attached_picture = tadpole_ground_atom_appearance(ground_item, 0)
	var/mutable_appearance/plain_picture = tadpole_ground_appearance(ground_item.appearance, 0)
	TEST_ASSERT_EQUAL(length(attached_picture.overlays), length(plain_picture.overlays) + 1, "Native vis_contents such as parachutes must appear in the relay")
	var/mutable_appearance/copied_canopy = new(attached_picture.overlays[length(attached_picture.overlays)])
	TEST_ASSERT_EQUAL(copied_canopy.plane, FLOAT_PLANE, "Attached visuals must not escape above the real shuttle")
	TEST_ASSERT(!holder.refresh_ground(start), "Unchanged attachments must retain the geometry cache")
	attached_canopy.vis_flags |= VIS_HIDE
	TEST_ASSERT(attached_canopy.vis_flags & VIS_HIDE, "Fixture must actually hide its attached visual")
	TEST_ASSERT(holder.refresh_ground(start), "Changing VIS_HIDE must invalidate attachment snapshots")
	attached_picture = tadpole_ground_atom_appearance(ground_item, 0)
	TEST_ASSERT_EQUAL(length(attached_picture.overlays), length(plain_picture.overlays), "Hidden wound/mask visuals must remain hidden")
	attached_canopy.vis_flags &= ~VIS_HIDE
	attached_canopy.setDir(WEST)
	var/atom/movable/vis_obj/attached_underlay = allocate(/atom/movable/vis_obj)
	attached_underlay.icon = 'icons/effects/alphacolors.dmi'
	attached_underlay.icon_state = "blue"
	attached_underlay.vis_flags = VIS_UNDERLAY | VIS_INHERIT_DIR | VIS_INHERIT_LAYER
	attached_canopy.vis_contents += attached_underlay
	attached_picture = tadpole_ground_atom_appearance(ground_item, 0)
	copied_canopy = new(attached_picture.overlays[length(attached_picture.overlays)])
	var/mutable_appearance/copied_underlay = new(copied_canopy.underlays[length(copied_canopy.underlays)])
	TEST_ASSERT_EQUAL(copied_underlay.dir, WEST, "Nested attachments must inherit their parent's display direction")
	TEST_ASSERT_EQUAL(copied_underlay.layer, FLOAT_LAYER, "VIS_INHERIT_LAYER must remain relative to the parent")
	TEST_ASSERT_EQUAL(copied_underlay.plane, FLOAT_PLANE, "Nested underlays must remain inside the isolated ground plane")
	TEST_ASSERT(holder.refresh_ground(start), "Nested visual trees must update the terrain cache")
	TEST_ASSERT(!holder.refresh_ground(start), "An unchanged nested tree must not rebuild")
	attached_underlay.color = "#00ff00"
	TEST_ASSERT(holder.refresh_ground(start), "Nested appearance changes must invalidate cached attachments")
	attached_underlay.vis_flags |= VIS_INHERIT_ICON | VIS_INHERIT_ICON_STATE
	attached_picture = tadpole_ground_atom_appearance(ground_item, 0)
	copied_canopy = new(attached_picture.overlays[length(attached_picture.overlays)])
	copied_underlay = new(copied_canopy.underlays[length(copied_canopy.underlays)])
	TEST_ASSERT_EQUAL(copied_underlay.icon, attached_canopy.icon, "Inherited attachment icons must match the actual parent")
	TEST_ASSERT_EQUAL(copied_underlay.icon_state, attached_canopy.icon_state, "Inherited attachment states must match the actual parent")
	attached_canopy.vis_contents -= attached_underlay
	ground_item.vis_contents -= attached_canopy
	TEST_ASSERT(holder.refresh_ground(start), "Detaching a visual must remove it from terrain snapshots")
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
	// Numeric order alone is insufficient in SIDE_MAP. Every flattened
	// category must occupy the same topdown subplane, including light masks.
	var/grass_depth_layer = tadpole_ground_depth_layer(FLOOR_PLANE, XENO_WEEDS_LAYER, -20)
	TEST_ASSERT(grass_depth_layer >= TOPDOWN_LAYER && grass_depth_layer < BACKGROUND_LAYER, "Floor cover must opt out of native SIDE_MAP sorting")
	TEST_ASSERT(large_sprite_copy.layer >= TOPDOWN_LAYER && foreground_wall >= TOPDOWN_LAYER, "Mob and wall proxies must use the same topdown subplane as floors")
	TEST_ASSERT(tadpole_ground_depth_layer(GAME_PLANE, EFFECTS_LAYER, 0) >= TOPDOWN_LAYER, "Effects must not fall behind floor tiles in SIDE_MAP")
	var/obj/effect/abstract/tadpole_ground_lighting/sort_light = allocate(/obj/effect/abstract/tadpole_ground_lighting)
	TEST_ASSERT(sort_light.layer > large_sprite_copy.layer, "Lighting must shade the entire shared topdown composite")
	// Exercise a queen-sized overhang, not only the smaller runner image.
	large_sprite_source.icon = 'icons/Xeno/castes/queen/basic.dmi'
	large_sprite_source.icon_state = "Queen Walking"
	var/mutable_appearance/queen_picture = tadpole_ground_appearance(large_sprite_source.appearance, 0)
	queen_picture.appearance_flags &= ~TILE_BOUND
	large_sprite_copy.configure_source(large_sprite_source, queen_picture)
	for(var/queen_turn in list(0, 90, 180, 270))
		large_sprite_copy.set_view_turn(queen_turn)
		large_sprite_copy.set_view_depth(1)
		TEST_ASSERT(large_sprite_copy.layer >= TOPDOWN_LAYER && large_sprite_copy.layer > grass_depth_layer, "Queen overhangs must stay above floor cover at every cardinal heading")
		TEST_ASSERT(!(large_sprite_copy.appearance_flags & TILE_BOUND), "Queen proxies must not clip to their one-tile collision footprint")
	var/turf/opaque_location = locate(60, 60, start.z)
	var/previous_turf_type = opaque_location.type
	var/turf/closed/wall/opaque_test_wall = opaque_location.ChangeTurf(/turf/closed/wall)
	large_sprite_source.forceMove(opaque_test_wall)
	var/mob_hidden_in_wall = !tadpole_ground_movable_visible(large_sprite_source)
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
	TEST_ASSERT(holder.ground_lighting in holder.vis_contents, "Lighting must be a persistent child of the terrain tile")
	var/obj/effect/abstract/tadpole_ground_lighting/light_mask = holder.ground_lighting
	TEST_ASSERT_EQUAL(light_mask.plane, TADPOLE_GROUND_LIGHTING_PLANE, "Lighting must use a separate native render pass")
	TEST_ASSERT(light_mask.appearance_flags & KEEP_APART, "Lighting must escape the geometry KEEP_TOGETHER group instead of painting over terrain")
	var/atom/movable/screen/plane_master/tadpole_lighting/light_plane_type = /atom/movable/screen/plane_master/tadpole_lighting
	TEST_ASSERT_EQUAL(initial(light_plane_type.blend_mode_override), BLEND_MULTIPLY, "The light plane must multiply once after adding native light masks")
	TEST_ASSERT(holder in helm.ground_surface.vis_contents, "Terrain tiles must share one compositing surface")
	var/saved_velocity_x = helm.flight_velocity_x
	var/saved_velocity_y = helm.flight_velocity_y
	var/saved_turn_velocity = helm.flight_turn_velocity
	helm.flight_velocity_x = 3
	helm.flight_velocity_y = -2
	helm.flight_turn_velocity = 20
	helm.animate_ground_view(0.2)
	var/matrix/confirmed_transform = helm.ground_surface_transform(helm.flight_x, helm.flight_y, helm.flight_heading)
	var/matrix/animated_target = helm.ground_surface.transform
	TEST_ASSERT_EQUAL(animated_target.c, confirmed_transform.c, "Animation must not queue a horizontal endpoint ahead of confirmed flight")
	TEST_ASSERT_EQUAL(animated_target.f, confirmed_transform.f, "Animation must not queue a vertical endpoint ahead of confirmed flight")
	TEST_ASSERT_EQUAL(animated_target.a, confirmed_transform.a, "Animation must not predict angular motion beyond the confirmed heading")
	TEST_ASSERT_EQUAL(helm.flight_x, start.x + 0.25, "Render interpolation must not change the landing position")
	helm.animate_ground_view(0)
	helm.flight_velocity_x = saved_velocity_x
	helm.flight_velocity_y = saved_velocity_y
	helm.flight_turn_velocity = saved_turn_velocity
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
	// The z coordinate is part of the cache key, even when x/y/heading stay still.
	var/turf/original_eye_turf = get_turf(eye)
	var/other_ground_z = start.z == 1 ? 2 : 1
	eye.abstract_move(locate(start.x, start.y, other_ground_z))
	helm.update_ground_view()
	for(var/turf/rendered_turf as anything in helm.ground_holders)
		TEST_ASSERT_EQUAL(rendered_turf.z, other_ground_z, "Switching ground levels must discard the former level's snapshots")
	eye.abstract_move(original_eye_turf)
	helm.update_ground_view()
	// Icon updates must jump ahead of background polling while retaining
	// the same frame budget. This exercises the real update_icon signal.
	var/obj/effect/abstract/tadpole_ground/priority_holder = helm.ground_holders[start]
	var/obj/structure/tadpole_render_test/priority_prop = allocate(/obj/structure/tadpole_render_test, start)
	priority_prop.anchored = TRUE
	priority_holder.refresh_ground(start)
	helm.dirty_ground_tiles.Cut()
	priority_prop.update_icon()
	TEST_ASSERT(helm.dirty_ground_tiles[start], "Static icon updates must schedule their tile for priority refresh")
	priority_holder.next_refresh = world.time + 100 SECONDS
	TEST_ASSERT_EQUAL(helm.refresh_ground_slice(1), 1, "Dirty geometry must refresh immediately despite its background deadline")
	TEST_ASSERT(!helm.dirty_ground_tiles[start], "Processed dirty entries must leave the queue")
	var/old_static_count = length(priority_holder.sprites)
	priority_prop.forceMove(get_step(start, EAST))
	TEST_ASSERT_EQUAL(length(priority_holder.sprites), old_static_count - 1, "Moving anchored scenery must immediately remove its former static copy")
	qdel(priority_prop)
	helm.dirty_ground_tiles.Cut()
	// A synchronized deadline must never make one physics step poll the
	// entire terrain grid. Two slices must also advance rather than starve.
	for(var/i in 1 to 30)
		var/turf/poll_tile = locate(70 + i, 70, start.z)
		var/obj/effect/abstract/tadpole_ground/poll_holder = new
		helm.ground_holders[poll_tile] = poll_holder
	for(var/turf/poll_tile as anything in helm.ground_holders)
		var/obj/effect/abstract/tadpole_ground/poll_holder = helm.ground_holders[poll_tile]
		poll_holder.next_refresh = 0
	helm.ground_refresh_cursor = 0
	TEST_ASSERT_EQUAL(helm.refresh_ground_slice(2), 2, "Terrain polling must obey its per-step budget")
	TEST_ASSERT_EQUAL(helm.refresh_ground_slice(2), 2, "Terrain polling must advance to the next slice")
	var/pending_polls = 0
	for(var/turf/poll_tile as anything in helm.ground_holders)
		var/obj/effect/abstract/tadpole_ground/poll_holder = helm.ground_holders[poll_tile]
		if(!poll_holder.next_refresh)
			pending_polls++
	TEST_ASSERT_EQUAL(pending_polls, length(helm.ground_holders) - 4, "Only the bounded slices may refresh in one step")
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
	helm.track_ground_movable(walker)
	var/obj/effect/abstract/tadpole_mobile_anchor/mobile_visual = helm.ground_movables[walker]
	TEST_ASSERT_NOTNULL(mobile_visual, "Visible mobs must get a persistent visual")
	helm.flight_heading = dir2angle(port.dir)
	walker.set_glide_size(8)
	TEST_ASSERT(walker.Move(get_step(walker, EAST), EAST, 8), "The movement fixture must take a real step")
	TEST_ASSERT_EQUAL(helm.ground_movables[walker], mobile_visual, "Moving between tiles must preserve visual identity")
	TEST_ASSERT_EQUAL(mobile_visual.last_glide_duration, world.icon_size / walker.glide_size * world.tick_lag, "A real move must use the source mob's glide timing")
	TEST_ASSERT(mobile_visual.last_glide_duration > 0, "Ordinary steps must glide rather than teleport")
	TEST_ASSERT_EQUAL(mobile_visual.to_x, 32, "The movement event must update the visual target immediately")
	TEST_ASSERT(walker.Move(get_step(walker, NORTH), NORTH, 8), "The depth fixture must take a real northward step")
	TEST_ASSERT(abs(mobile_visual.sprite.view_depth) < 0.001, "Depth must start at the displayed origin instead of jumping to the destination tile")
	mobile_visual.move_started = world.time - mobile_visual.last_glide_duration / 2
	mobile_visual.sync_visual()
	TEST_ASSERT(abs(mobile_visual.sprite.view_depth - 0.5) < 0.001, "Occlusion depth must track the middle of a gliding step")
	walker.vis_contents += attached_canopy
	mobile_visual.sync_visual()
	var/mutable_appearance/walker_plain = tadpole_ground_appearance(walker.appearance, 0)
	TEST_ASSERT_EQUAL(length(mobile_visual.sprite.overlays), length(walker_plain.overlays) + 1, "Mob attachments must update independently of terrain polling")
	walker.vis_contents -= attached_canopy
	mobile_visual.sync_visual()
	TEST_ASSERT_EQUAL(length(mobile_visual.sprite.overlays), length(walker_plain.overlays), "Detached mob visuals must disappear without rebuilding terrain")
	walker.setDir(NORTH)
	TEST_ASSERT_EQUAL(mobile_visual.sprite.dir, turn(NORTH, mobile_visual.last_turn), "Direction changes must update without waiting for the terrain cache")
	walker.forceMove(walk_start)
	TEST_ASSERT_EQUAL(mobile_visual.last_glide_duration, 0, "Real teleports must not glide across intervening tiles")
	qdel(walker)
	TEST_ASSERT_NULL(helm.ground_movables[walker], "Deleting a mob must release its visual and movement subscriptions")
	TEST_ASSERT_NULL(mobile_visual.last_visuals, "Deleting a visual anchor must release cached attachment references")
	// The same persistent relay must handle real item movement without a
	// second stale copy remaining inside the periodically rebuilt terrain.
	var/obj/item/rolling_item = allocate(/obj/item, walk_start)
	helm.track_ground_movable(rolling_item)
	var/obj/effect/abstract/tadpole_mobile_anchor/item_visual = helm.ground_movables[rolling_item]
	TEST_ASSERT_NOTNULL(item_visual, "Loose items must use persistent motion relays")
	var/obj/effect/abstract/tadpole_ground/item_ground = allocate(/obj/effect/abstract/tadpole_ground)
	item_ground.flight_helm = helm
	item_ground.refresh_ground(walk_start)
	TEST_ASSERT_EQUAL(length(item_ground.sprites), 1, "A relayed item must not also remain in the static terrain image")
	rolling_item.invisibility = INVISIBILITY_OBSERVER
	item_visual.sync_visual()
	TEST_ASSERT_EQUAL(item_visual.sprite.invisibility, INVISIBILITY_OBSERVER, "Relays must preserve invisibility for the client's own see_invisible threshold")
	TEST_ASSERT(tadpole_ground_movable_visible(rolling_item), "Nonzero invisibility must not globally remove an otherwise visible world relay")
	rolling_item.invisibility = 0
	item_visual.sync_visual()
	rolling_item.set_glide_size(8)
	TEST_ASSERT(rolling_item.Move(get_step(walk_start, EAST), EAST, 8), "The item fixture must take a real step")
	TEST_ASSERT_EQUAL(helm.ground_movables[rolling_item], item_visual, "Moving items must retain their relay identity")
	TEST_ASSERT(item_visual.last_glide_duration > 0, "Ordinary item movement must interpolate")
	var/obj/item/storage/test_inventory = allocate(/obj/item/storage, walk_start)
	rolling_item.forceMove(test_inventory)
	TEST_ASSERT_NULL(helm.ground_movables[rolling_item], "Putting an item into inventory must immediately remove its world relay")
	var/obj/vehicle/ground_vehicle = allocate(/obj/vehicle, walk_start)
	helm.track_ground_movable(ground_vehicle)
	var/obj/effect/abstract/tadpole_mobile_anchor/vehicle_visual = helm.ground_movables[ground_vehicle]
	TEST_ASSERT_NOTNULL(vehicle_visual, "Vehicles must receive persistent relays even when anchored")
	ground_vehicle.bound_width = 64
	var/turf/visible_vehicle_edge = get_step(walk_start, EAST)
	helm.ground_holders[visible_vehicle_edge] = item_ground
	TEST_ASSERT(helm.ground_movable_in_view(ground_vehicle), "Visible vehicle footprints must count even if the root turf is outside the viewport")
	helm.ground_holders -= visible_vehicle_edge
	ground_vehicle.forceMove(get_step(walk_start, EAST))
	TEST_ASSERT(vehicle_visual.last_glide_duration > 0, "Adjacent vehicle forceMove steps used by driving must glide")
	ground_vehicle.forceMove(get_ranged_target_turf(walk_start, EAST, 4))
	TEST_ASSERT_EQUAL(vehicle_visual.last_glide_duration, 0, "Long vehicle relocations must remain teleports")
	qdel(ground_vehicle)
	TEST_ASSERT_NULL(helm.ground_movables[ground_vehicle], "Deleting a vehicle must release its movement relay")
	TEST_ASSERT(!tadpole_ground_tracks_movement(directional), "Anchored scenery must remain in the bounded static cache")
	helm.clear_ground_view()
	TEST_ASSERT_EQUAL(length(helm.ground_movables), 0, "Landing must clear all mobile visuals")
	// Lighting must reuse native appearances, never resample their texture or
	// recompute corner values / shadow polygons in the flight controller.
	var/turf/light_turf = locate(61, 61, start.z)
	var/obj/effect/abstract/tadpole_ground/light_holder = allocate(/obj/effect/abstract/tadpole_ground)
	var/first_light_change = light_holder.update_ground_lighting(light_turf)
	var/repeated_light_change = light_holder.update_ground_lighting(light_turf)
	var/obj/effect/abstract/tadpole_ground_lighting/persistent_mask = light_holder.ground_lighting
	TEST_ASSERT(first_light_change && !repeated_light_change, "Unchanged native lighting must not rebuild its appearance")
	light_holder.refresh_ground(light_turf)
	TEST_ASSERT(persistent_mask in light_holder.vis_contents, "Terrain refresh must retain its native lighting child")
	TEST_ASSERT_EQUAL(light_holder.ground_lighting, persistent_mask, "Native lighting must reuse the existing child")
	var/atom/movable/lighting_mask/native_mask = new
	native_mask.attached_atom = light_turf
	native_mask.set_radius(4)
	var/mutable_appearance/native_shadow = mutable_appearance(LIGHTING_ICON_BIG, "triangle")
	native_shadow.render_target = SHADOW_RENDER_TARGET
	native_mask.overlays += native_shadow
	var/original_mask_picture = native_mask.appearance
	var/list/old_lights = light_turf.hybrid_lights_affecting
	light_turf.hybrid_lights_affecting = list(native_mask)
	helm.ground_holders[light_turf] = light_holder
	helm.ground_surface = new(get_turf(helm))
	helm.ground_origin_x = light_turf.x
	helm.ground_origin_y = light_turf.y
	helm.update_ground_lights()
	var/obj/effect/abstract/tadpole_light_relay/native_relay = helm.ground_lights[native_mask]
	TEST_ASSERT_EQUAL(native_mask.appearance, original_mask_picture, "Relaying light must not change the real ground source")
	var/mutable_appearance/relayed_shadow = new(native_relay.overlays[1])
	TEST_ASSERT(relayed_shadow.render_target != SHADOW_RENDER_TARGET, "Ground shadows must not share the real shuttle's shadow target")
	TEST_ASSERT_EQUAL(relayed_shadow.plane, FLOAT_PLANE, "Shadow triangles must stay in their source mask's lighting pass")
	TEST_ASSERT_NOTNULL(native_relay, "A native hybrid light must have a shared light-pass relay")
	TEST_ASSERT(native_relay.appearance_flags & KEEP_APART, "Hybrid lights must escape the geometry group and reach their own plane master")
	var/matrix/native_transform = native_mask.transform
	var/matrix/relay_transform = native_relay.transform
	TEST_ASSERT_EQUAL(relay_transform.a, native_transform.a, "The relay must retain native beam scale")
	TEST_ASSERT_EQUAL(relay_transform.b, native_transform.b, "The relay must retain native beam orientation")
	helm.update_ground_lights()
	TEST_ASSERT_EQUAL(helm.ground_lights[native_mask], native_relay, "Repeated frames must reuse one relay per source")
	TEST_ASSERT_EQUAL(length(helm.ground_lights), 1, "Light masks must not be duplicated per affected turf")
	native_mask.set_color("#ff4040")
	helm.update_ground_lights()
	TEST_ASSERT_EQUAL(helm.ground_lights[native_mask], native_relay, "Changing light colour must reuse its existing relay")
	TEST_ASSERT_EQUAL(native_relay.color, native_mask.color, "Light colour must come from the native mask")
	light_turf.hybrid_lights_affecting = old_lights
	helm.update_ground_lights()
	TEST_ASSERT_EQUAL(length(helm.ground_lights), 0, "Lights leaving the view must release their relays")
	native_mask.attached_atom = null
	qdel(native_mask)
	helm.clear_ground_view()
	helm.fly_state = SHUTTLE_IN_ATMOSPHERE
	helm.update_ground_searchlight()
	TEST_ASSERT_NOTNULL(helm.ground_searchlight, "The Tadpole must project a real light source onto the ground")
	TEST_ASSERT_EQUAL(helm.ground_searchlight.z, eye.z, "The searchlight must illuminate the lower map")
	TEST_ASSERT_EQUAL(helm.ground_searchlight.light_system, HYBRID_LIGHT, "The moving searchlight must not invalidate the static corner-light grid")
	TEST_ASSERT_NULL(helm.ground_searchlight.static_light, "The searchlight must not allocate a moving static light source")
	helm.clear_ground_view()
	TEST_ASSERT_NULL(helm.ground_searchlight, "Landing cleanup must remove the temporary projected light")
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

/area/tadpole_light_test
	static_lighting = TRUE
	base_lighting_alpha = 0

/// Record the normal delayed airdrop entry point without injury/deconstruction.
/obj/tadpole_fall_test
	anchored = TRUE
	var/turf/drop_target

/obj/tadpole_fall_test/handle_airdrop(turf/target_turf)
	drop_target = target_turf
	forceMove(target_turf)

/area/tadpole_fall_test
	outside = TRUE
	area_flags = NONE

/area/shuttle/minidropship/tadpole_shutter_test

// Keep the fixture on its single transit turf; test the exit signal/timer,
// not unrelated throw traversal into the surrounding unit-test floor.
/obj/tadpole_fall_test/throw_at()
	return FALSE
