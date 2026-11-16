#define TADPOLE_CHUNK_SIZE 8
#define TADPOLE_CAPTURE_SIZE 25

/// Native multi-turf visual contents provide their own relative coordinates.
/// Keep one relay per block instead of adding a movable relay for every tile.
/obj/effect/abstract/tadpole_native_chunk
	icon = null
	plane = HUD_PLANE
	appearance_flags = PIXEL_SCALE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	// Bucket rebases are instantaneous; only the completed plate interpolates.
	animate_movement = NO_STEPS
	atom_flags = SHUTTLE_IMMUNE | PREVENT_CONTENTS_EXPLOSION
	var/list/tiles = list()

/// Shared blocks belong to a fixed capture canvas, never to the passenger's
/// world visibility range. Translation only; rotate the completed plane.
/obj/effect/abstract/tadpole_native_chunk/proc/move_ground(from_x, from_y, to_x, to_y, transit_z, duration)
	if(loc)
		abstract_move(null)
	var/from_pixel_x = FLOOR(from_x * world.icon_size, 1)
	var/from_pixel_y = FLOOR(from_y * world.icon_size, 1)
	var/to_pixel_x = FLOOR(to_x * world.icon_size, 1)
	var/to_pixel_y = FLOOR(to_y * world.icon_size, 1)
	var/matrix/from_shift = matrix()
	var/matrix/to_shift = matrix()
	from_shift.c = from_x * world.icon_size - from_pixel_x
	from_shift.f = from_y * world.icon_size - from_pixel_y
	to_shift.c = to_x * world.icon_size - to_pixel_x
	to_shift.f = to_y * world.icon_size - to_pixel_y
	animate(src, transform = from_shift, pixel_x = from_pixel_x, pixel_y = from_pixel_y, time = 0)
	animate(src, transform = to_shift, pixel_x = to_pixel_x, pixel_y = to_pixel_y, time = duration, easing = LINEAR_EASING)

/// Source anchor is identical for every passenger and never follows their eye.
/atom/movable/screen/tadpole_capture_canvas
	icon = null
	screen_loc = "CENTER"
	plane = HUD_PLANE
	appearance_flags = PIXEL_SCALE | TILE_BOUND
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/tadpole_capture_canvas/Destroy()
	vis_contents.Cut()
	return ..()

/// Explicit transparent border allocates a 25x25 render surface without
/// increasing client.view or changing ordinary HUD coordinates.
/atom/movable/screen/background/tadpole_capture_frame
	screen_loc = "CENTER-12,CENTER-12 to CENTER+12,CENTER+12"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/abstract/tadpole_native_chunk/proc/build(base_x, base_y, ground_z)
	var/turf/first = locate(max(1, base_x), max(1, base_y), ground_z)
	var/turf/last = locate(min(world.maxx, base_x + TADPOLE_CHUNK_SIZE - 1), min(world.maxy, base_y + TADPOLE_CHUNK_SIZE - 1), ground_z)
	if(!first || !last || base_x > world.maxx || base_y > world.maxy || base_x + TADPOLE_CHUNK_SIZE <= 1 || base_y + TADPOLE_CHUNK_SIZE <= 1)
		return
	tiles = block(first, last)
	vis_contents = tiles.Copy()
	for(var/turf/source as anything in tiles)
		RegisterSignal(source, COMSIG_TURF_CHANGE, PROC_REF(on_turf_change))

/obj/effect/abstract/tadpole_native_chunk/proc/on_turf_change(datum/source, path, baseturfs, flags, list/callbacks)
	SIGNAL_HANDLER
	callbacks += CALLBACK(src, PROC_REF(reconnect))

/obj/effect/abstract/tadpole_native_chunk/proc/reconnect(turf/replacement)
	if(QDELETED(src))
		return
	// ChangeTurf preserves references in tiles, but replaces the native visual
	// link. Refresh only this block after the replacement has completed.
	vis_contents = tiles.Copy()

/obj/effect/abstract/tadpole_native_chunk/Destroy()
	for(var/turf/source as anything in tiles)
		UnregisterSignal(source, COMSIG_TURF_CHANGE)
	vis_contents.Cut()
	tiles.Cut()
	return ..()

/// Owns a passenger's temporary connection to the completed lower render plate.
/datum/tadpole_scene_view
	var/datum/hud/hud
	var/atom/movable/screen/plane_master/rendering_plate/master/plate
	var/matrix/original_transform
	var/source_offset
	var/output_plane
	var/matrix/last_camera
	var/matrix/animation_from
	var/animation_started = 0
	var/animation_duration = 0
	var/list/forced_planes = list()
	var/atom/movable/screen/plane_master/emissive_plate
	var/had_emissive_relay = FALSE
	var/datum/tadpole_scene/scene
	var/atom/movable/tracked_eye
	var/client/capture_client
	var/datum/plane_master_group/capture_group
	var/original_relay_loc
	var/list/capture_relay_locations = list()
	var/list/unscaled_planes = list()
	var/atom/movable/screen/fullscreen/lighting_backdrop/lit_secondary/capture_lit
	var/atom/movable/screen/fullscreen/lighting_backdrop/backplane/capture_unlit
	var/mob/visibility_owner

/datum/tadpole_scene_view/New(datum/hud/display, depth, datum/tadpole_scene/owner)
	hud = display
	scene = owner
	var/client/display_client = display.mymob?.client
	if(display_client?.tadpole_capture_view)
		qdel(display_client.tadpole_capture_view)
	source_offset = depth
	plate = hud.get_plane_master(GET_NEW_PLANE(RENDER_PLANE_MASTER, depth))
	if(!plate)
		return
	capture_lit = new
	capture_unlit = new
	for(var/atom/movable/screen/backdrop as anything in list(capture_lit, capture_unlit))
		backdrop.screen_loc = "CENTER"
		backdrop.plane = GET_NEW_PLANE(LIGHTING_PLANE, depth)
		backdrop.transform = matrix(TADPOLE_CAPTURE_SIZE, 0, 0, 0, TADPOLE_CAPTURE_SIZE, 0)
	original_transform = plate.transform
	plate.remove_relay_from(GET_NEW_PLANE(RENDER_PLANE_TRANSPARENT, depth - 1))
	output_plane = GET_NEW_PLANE(TADPOLE_GROUND_PLANE, hud.current_plane_offset)
	plate.add_relay_to(output_plane)
	var/datum/plane_master_group/group = hud.get_plane_group(PLANE_GROUP_MAIN)
	capture_group = group
	original_relay_loc = group.relay_loc
	group.relay_loc = "SCREEN_SOUTHWEST"
	sync_capture_relays()
	for(var/key in group.plane_masters)
		var/atom/movable/screen/plane_master/master = group.plane_masters[key]
		if(master.offset < depth)
			continue
		if(master.multiz_scaled)
			unscaled_planes += master
			master.multiz_scaled = FALSE
			animate(master, transform = null, time = 0)
		if(master.is_outside_bounds)
			forced_planes += master
			master.inside_bounds(hud.mymob)
	emissive_plate = hud.get_plane_master(GET_NEW_PLANE(EMISSIVE_RENDER_PLATE, depth))
	if(emissive_plate?.get_relay_to(GET_NEW_PLANE(EMISSIVE_RENDER_PLATE, depth - 1)))
		had_emissive_relay = TRUE
		emissive_plate.remove_relay_from(GET_NEW_PLANE(EMISSIVE_RENDER_PLATE, depth - 1))
	bind_visibility(hud.mymob)

/datum/tadpole_scene_view/Destroy()
	track_eye(null)
	bind_visibility(null)
	QDEL_NULL(capture_lit)
	QDEL_NULL(capture_unlit)
	scene = null
	for(var/atom/movable/render_plane_relay/relay as anything in capture_relay_locations)
		if(!QDELETED(relay) && relay.screen_loc == "SCREEN_SOUTHWEST")
			relay.screen_loc = capture_relay_locations[relay]
	capture_relay_locations.Cut()
	if(!QDELETED(capture_group) && capture_group.relay_loc == "SCREEN_SOUTHWEST")
		capture_group.relay_loc = original_relay_loc
	capture_group = null
	if(!QDELETED(plate))
		animate(plate, transform = original_transform, time = 0)
		plate.remove_relay_from(output_plane)
		plate.offset_change(hud.current_plane_offset)
	if(had_emissive_relay && !QDELETED(emissive_plate))
		emissive_plate.add_relay_to(GET_NEW_PLANE(EMISSIVE_RENDER_PLATE, source_offset - 1), relay_layer = EMISSIVE_Z_BELOW_LAYER)
	if(!QDELETED(hud))
		for(var/atom/movable/screen/plane_master/master as anything in unscaled_planes)
			if(!QDELETED(master))
				master.multiz_scaled = TRUE
		var/datum/plane_master_group/group = hud.get_plane_group(PLANE_GROUP_MAIN)
		group?.build_planes_offset(hud, hud.current_plane_offset)
	hud = null
	plate = null
	emissive_plate = null
	forced_planes.Cut()
	unscaled_planes.Cut()
	return ..()

/// Living passengers need the same native scene visibility as observers.
/// The modifier is owned by this view and survives equipment sight updates.
/datum/tadpole_scene_view/proc/bind_visibility(mob/viewer)
	if(viewer == visibility_owner)
		return
	if(visibility_owner)
		UnregisterSignal(visibility_owner, list(COMSIG_MOB_LOGOUT, COMSIG_QDELETING))
		visibility_owner.remove_sight_modifier(REF(src))
	detach_capture()
	visibility_owner = viewer
	if(!viewer)
		return
	attach_capture(viewer.client)
	viewer.add_sight_modifier(REF(src), SEE_SELF | SEE_TURFS | SEE_OBJS | SEE_MOBS)
	RegisterSignals(viewer, list(COMSIG_MOB_LOGOUT, COMSIG_QDELETING), PROC_REF(on_visibility_lost))

/datum/tadpole_scene_view/proc/on_visibility_lost()
	SIGNAL_HANDLER
	track_eye(null)
	bind_visibility(null)

/// HUD borders enlarge native render slates. In 516 a slate's render_source
/// must start at the full screen's southwest, including those borders.
/datum/tadpole_scene_view/proc/sync_capture_relays()
	if(!capture_group)
		return
	for(var/key in capture_group.plane_masters)
		var/atom/movable/screen/plane_master/master = capture_group.plane_masters[key]
		for(var/atom/movable/render_plane_relay/relay as anything in master.relays)
			if(!(relay in capture_relay_locations))
				capture_relay_locations[relay] = relay.screen_loc == "SCREEN_SOUTHWEST" ? original_relay_loc : relay.screen_loc
			if(relay.screen_loc != "SCREEN_SOUTHWEST")
				relay.screen_loc = "SCREEN_SOUTHWEST"

/datum/tadpole_scene_view/proc/attach_capture(client/display)
	if(!display || capture_client == display)
		return
	if(display.tadpole_capture_view && display.tadpole_capture_view != src)
		qdel(display.tadpole_capture_view)
	capture_client = display
	display.tadpole_capture_view = src
	display.screen |= scene.canvas
	display.screen |= scene.frame
	display.screen |= capture_lit
	display.screen |= capture_unlit
	INVOKE_ASYNC(src, PROC_REF(apply_capture_zoom))

/datum/tadpole_scene_view/proc/detach_capture()
	if(capture_client)
		capture_client.screen -= scene?.canvas
		capture_client.screen -= scene?.frame
		capture_client.screen -= capture_lit
		capture_client.screen -= capture_unlit
		if(capture_client.tadpole_capture_view == src)
			capture_client.tadpole_capture_view = null
			winset(capture_client, "mapwindow.map", "zoom=[capture_client.view_size?.zoom || 0]")
	capture_client = null

/// Preserve the user's visible scale while only the offscreen slate grows.
/// No change to client.eye, client.view, or the HUD's screen coordinates.
/datum/tadpole_scene_view/proc/apply_capture_zoom()
	var/client/display = capture_client
	if(!display || display.tadpole_capture_view != src)
		return
	var/zoom = display.view_size?.zoom || 0
	if(!zoom)
		var/list/control_size = splittext(winget(display, "mapwindow.map", "size"), "x")
		if(QDELETED(src) || capture_client != display || display.tadpole_capture_view != src || length(control_size) != 2)
			return
		var/list/view_size = getviewsize(display.view)
		zoom = display.view_size?.zoom || min(text2num(control_size[1]) / (view_size[1] * world.icon_size), text2num(control_size[2]) / (view_size[2] * world.icon_size))
	if(zoom > 0)
		winset(display, "mapwindow.map", "zoom=[zoom]")

/datum/tadpole_scene_view/proc/track_eye(atom/new_eye)
	if(!ismovable(new_eye))
		new_eye = null
	if(tracked_eye == new_eye)
		return
	if(tracked_eye)
		UnregisterSignal(tracked_eye, COMSIG_MOVABLE_MOVED)
	tracked_eye = new_eye
	if(tracked_eye)
		RegisterSignal(tracked_eye, COMSIG_MOVABLE_MOVED, PROC_REF(on_eye_move))

/// React in the movement tick, not up to 0.2 seconds later in flight processing.
/// This touches one plate only; no player discovery, source polling or chunks.
/datum/tadpole_scene_view/proc/on_eye_move(atom/movable/source, atom/old_loc, direction, forced)
	SIGNAL_HANDLER
	var/turf/eye = get_turf(source)
	if(!scene || !eye)
		return
	if(!scene.helm.ground_tiles[eye])
		if(source == visibility_owner)
			bind_visibility(null)
		return
	if(source == hud?.mymob)
		bind_visibility(hud.mymob)
	var/duration = 0
	if(!forced && isturf(old_loc) && old_loc.z == eye.z && get_dist(old_loc, eye) == 1)
		var/dx = abs(eye.x - old_loc.x)
		var/dy = abs(eye.y - old_loc.y)
		var/distance = (source.appearance_flags & LONG_GLIDE) ? max(dx, dy) : sqrt(dx ** 2 + dy ** 2)
		duration = distance * world.icon_size / max(source.glide_size, 1) * world.tick_lag / 10
	scene.update_view(src, eye, duration)

/datum/tadpole_scene_view/proc/update_camera(matrix/camera, animation_seconds)
	if(QDELETED(plate))
		return
	if(last_camera && last_camera.a == camera.a && last_camera.b == camera.b && last_camera.c == camera.c && last_camera.d == camera.d && last_camera.e == camera.e && last_camera.f == camera.f)
		return
	animation_from = displayed_camera()
	animation_started = world.time
	animation_duration = animation_seconds * 10
	last_camera = camera
	animate(plate, transform = camera, time = animation_duration, easing = LINEAR_EASING)

/// Match the LINEAR_EASING matrix interpolation currently visible to clients.
/datum/tadpole_scene_view/proc/displayed_camera()
	if(!last_camera)
		return plate?.transform ? matrix(plate.transform) : matrix()
	var/progress = animation_duration ? clamp((world.time - animation_started) / animation_duration, 0, 1) : 1
	if(!animation_from || progress >= 1)
		return matrix(last_camera)
	var/matrix/result = matrix()
	result.a = animation_from.a + (last_camera.a - animation_from.a) * progress
	result.b = animation_from.b + (last_camera.b - animation_from.b) * progress
	result.c = animation_from.c + (last_camera.c - animation_from.c) * progress
	result.d = animation_from.d + (last_camera.d - animation_from.d) * progress
	result.e = animation_from.e + (last_camera.e - animation_from.e) * progress
	result.f = animation_from.f + (last_camera.f - animation_from.f) * progress
	return result

/datum/tadpole_scene
	var/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/helm
	var/list/chunks = list()
	var/list/views = list()
	var/origin_x
	var/origin_y
	var/source_z
	var/radius = 0
	var/list/viewer_candidates = list()
	var/next_viewer_scan = 0
	var/source_from_x
	var/source_from_y
	var/source_to_x
	var/source_to_y
	var/source_started = 0
	var/source_duration = 0
	var/last_port_x
	var/last_port_y
	var/last_port_z
	var/atom/movable/screen/tadpole_capture_canvas/canvas
	var/atom/movable/screen/background/tadpole_capture_frame/frame

/datum/tadpole_scene/New(obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/owner)
	helm = owner
	canvas = new
	frame = new

/datum/tadpole_scene/Destroy()
	QDEL_LIST_ASSOC_VAL(views)
	QDEL_LIST_ASSOC_VAL(chunks)
	QDEL_NULL(canvas)
	QDEL_NULL(frame)
	viewer_candidates.Cut()
	helm = null
	return ..()

/datum/tadpole_scene/proc/update(animation_seconds)
	if(!helm.eyeobj?.z || !helm.shuttle_port || !length(helm.ground_tiles))
		return
	var/depth = SSmapping.z_level_to_plane_offset[helm.eyeobj.z]
	// Only map-load allocated lower depths may enter the native render graph.
	if(!depth)
		return
	var/list/remaining = views.Copy()
	var/needed_radius = 0
	if(world.time >= next_viewer_scan)
		refresh_viewer_candidates()
	for(var/client/display as anything in viewer_candidates)
		var/mob/viewer = display?.mob
		var/turf/eye = get_turf(display?.eye)
		if(!eye || !helm.ground_tiles[eye] || !viewer?.hud_used)
			continue
		var/list/size = getviewsize(display.view)
		needed_radius = max(needed_radius, source_radius(size))
		var/datum/tadpole_scene_view/view = views[display]
		if(view && (view.hud != viewer.hud_used || view.source_offset != depth || QDELETED(view.plate) || view.plate.is_outside_bounds))
			qdel(view)
			view = null
		if(!view)
			view = new(viewer.hud_used, depth, src)
			views[display] = view
		view.track_eye(display.eye)
		view.bind_visibility(viewer)
		remaining -= display
	for(var/client/departed as anything in remaining)
		qdel(views[departed])
		views -= departed
	if(!needed_radius)
		if(length(chunks))
			canvas.vis_contents.Cut()
			QDEL_LIST_ASSOC_VAL(chunks)
		radius = 0
		source_to_x = null
		source_to_y = null
		source_duration = 0
		return
	update_region(needed_radius, helm.eyeobj.z)
	update_source_position(animation_seconds)
	for(var/client/display as anything in views)
		var/datum/tadpole_scene_view/view = views[display]
		view.sync_capture_relays()
		update_view(view, get_turf(display.eye), animation_seconds)

/datum/tadpole_scene/proc/update_view(datum/tadpole_scene_view/view, turf/eye, animation_seconds)
	if(!eye || QDELETED(view.plate) || isnull(origin_x) || isnull(origin_y))
		return
	var/angle = helm.flight_heading - dir2angle(helm.shuttle_port.dir)
	var/list/center = capture_center()
	var/matrix/camera = matrix()
	camera.Turn(-angle)
	camera.Translate((helm.shuttle_port.x + center[1] - eye.x) * world.icon_size, (helm.shuttle_port.y + center[2] - eye.y) * world.icon_size)
	view.update_camera(camera, animation_seconds)

/datum/tadpole_scene/proc/capture_center()
	var/obj/docking_port/mobile/port = helm.shuttle_port
	var/list/bounds = port.return_coords(0, 0, port.dir)
	return list((bounds[1] + bounds[3]) / 2, (bounds[2] + bounds[4]) / 2)

/// Ground point under the hull midpoint. Source-space recentering preserves
/// the actual docking/landing origin after rotating the completed plane.
/datum/tadpole_scene/proc/target_capture_position()
	var/list/center = capture_center()
	var/matrix/rotation = matrix()
	rotation.Turn(-(helm.flight_heading - dir2angle(helm.shuttle_port.dir)))
	return list(helm.flight_x + rotation.a * center[1] + rotation.d * center[2], helm.flight_y + rotation.b * center[1] + rotation.e * center[2])

/// One shared flight timeline, independent of all passenger positions.
/datum/tadpole_scene/proc/displayed_source_position()
	if(isnull(source_to_x) || isnull(source_to_y))
		return target_capture_position()
	var/progress = source_duration ? clamp((world.time - source_started) / source_duration, 0, 1) : 1
	return list(source_from_x + (source_to_x - source_from_x) * progress, source_from_y + (source_to_y - source_from_y) * progress)

/datum/tadpole_scene/proc/update_source_position(animation_seconds)
	var/obj/docking_port/mobile/port = helm.shuttle_port
	var/list/target = target_capture_position()
	if(source_to_x == target[1] && source_to_y == target[2] && last_port_x == port.x && last_port_y == port.y && last_port_z == port.z)
		return FALSE
	var/initialized = !isnull(source_to_x) && !isnull(source_to_y)
	var/list/current = displayed_source_position()
	source_from_x = current[1]
	source_from_y = current[2]
	source_to_x = target[1]
	source_to_y = target[2]
	source_started = world.time
	source_duration = initialized ? animation_seconds * 10 : 0
	last_port_x = port.x
	last_port_y = port.y
	last_port_z = port.z
	for(var/key in chunks)
		var/obj/effect/abstract/tadpole_native_chunk/chunk = chunks[key]
		if(!length(chunk.tiles))
			continue
		var/turf/first = chunk.tiles[1]
		chunk.move_ground(first.x - source_from_x, first.y - source_from_y, first.x - source_to_x, first.y - source_to_y, port.z, source_duration)
	return TRUE

/// Discovery is separate from the five-Hz flight path. Existing viewers are
/// still validated every step; new remote eyes can take up to one second.
/datum/tadpole_scene/proc/refresh_viewer_candidates()
	viewer_candidates.Cut()
	for(var/mob/viewer as anything in GLOB.player_list)
		var/client/display = viewer.client
		var/turf/eye = get_turf(display?.eye)
		if(eye && helm.ground_tiles[eye])
			viewer_candidates |= display
	next_viewer_scan = world.time + 1 SECONDS

/// Allocate for the ship footprint, not the passenger's current walking tile.
/datum/tadpole_scene/proc/source_radius(list/size)
	var/list/center = capture_center()
	return CEILING(sqrt(TADPOLE_CAPTURE_SIZE ** 2 * 2) / 2 + sqrt(center[1] ** 2 + center[2] ** 2), 1) + 1

/datum/tadpole_scene/proc/update_region(needed_radius, ground_z)
	needed_radius = max(radius, needed_radius)
	var/new_x = FLOOR(helm.flight_x / TADPOLE_CHUNK_SIZE, 1) * TADPOLE_CHUNK_SIZE
	var/new_y = FLOOR(helm.flight_y / TADPOLE_CHUNK_SIZE, 1) * TADPOLE_CHUNK_SIZE
	if(origin_x != new_x || origin_y != new_y || source_z != ground_z || radius != needed_radius)
		origin_x = new_x
		origin_y = new_y
		source_z = ground_z
		radius = needed_radius
		update_chunks()
		return TRUE
	return FALSE

/datum/tadpole_scene/proc/update_chunks()
	var/list/remaining = chunks.Copy()
	var/list/current = displayed_source_position()
	var/target_x = isnull(source_to_x) ? current[1] : source_to_x
	var/target_y = isnull(source_to_y) ? current[2] : source_to_y
	var/remaining_time = max(0, source_duration - (world.time - source_started))
	// Cover the entire origin bucket, including its last fractional cell.
	// Membership remains valid until the next eight-tile boundary.
	var/min_x = FLOOR((origin_x - radius) / TADPOLE_CHUNK_SIZE, 1) * TADPOLE_CHUNK_SIZE
	var/max_x = FLOOR((origin_x + TADPOLE_CHUNK_SIZE - 1 + radius) / TADPOLE_CHUNK_SIZE, 1) * TADPOLE_CHUNK_SIZE
	var/min_y = FLOOR((origin_y - radius) / TADPOLE_CHUNK_SIZE, 1) * TADPOLE_CHUNK_SIZE
	var/max_y = FLOOR((origin_y + TADPOLE_CHUNK_SIZE - 1 + radius) / TADPOLE_CHUNK_SIZE, 1) * TADPOLE_CHUNK_SIZE
	for(var/x in min_x to max_x step TADPOLE_CHUNK_SIZE)
		for(var/y in min_y to max_y step TADPOLE_CHUNK_SIZE)
			var/key = "[x],[y],[source_z]"
			var/obj/effect/abstract/tadpole_native_chunk/chunk = chunks[key]
			if(!chunk)
				chunk = new
				chunk.build(x, y, source_z)
				chunks[key] = chunk
				canvas.vis_contents += chunk
				chunk.move_ground(max(1, x) - current[1], max(1, y) - current[2], max(1, x) - target_x, max(1, y) - target_y, helm.z, remaining_time)
			else
				remaining -= key
	for(var/key in remaining)
		canvas.vis_contents -= chunks[key]
		qdel(chunks[key])
		chunks -= key

/obj/effect/abstract/tadpole_searchlight
	icon = null
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	atom_flags = SHUTTLE_IMMUNE|PREVENT_CONTENTS_EXPLOSION
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

#undef TADPOLE_CHUNK_SIZE
#undef TADPOLE_CAPTURE_SIZE
