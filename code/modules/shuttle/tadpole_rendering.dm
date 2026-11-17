#define TADPOLE_CHUNK_SIZE 8

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

/// Use spatial positions instead of putting every oversized visual tree on
/// the helm tile. Keep pixel offsets only for clipping at the world's edge.
/obj/effect/abstract/tadpole_native_chunk/proc/place(tile_x, tile_y, transit_z)
	var/turf/target = locate(clamp(tile_x, 1, world.maxx), clamp(tile_y, 1, world.maxy), transit_z)
	if(!target)
		return
	if(loc != target)
		// These are visual relays, not passengers: never trigger transit drops.
		abstract_move(target)
	pixel_x = (tile_x - target.x) * world.icon_size
	pixel_y = (tile_y - target.y) * world.icon_size

/// Translate the native source before it enters a screen-sized render plate.
/// Reanchor on whole tiles without a jump in the unfinished pixel animation.
/obj/effect/abstract/tadpole_native_chunk/proc/move_ground(from_x, from_y, to_x, to_y, transit_z, duration)
	place(FLOOR(to_x, 1), FLOOR(to_y, 1), transit_z)
	if(!loc)
		return
	animate(src, pixel_x = (from_x - x) * world.icon_size, pixel_y = (from_y - y) * world.icon_size, time = 0)
	animate(src, pixel_x = (to_x - x) * world.icon_size, pixel_y = (to_y - y) * world.icon_size, time = duration, easing = LINEAR_EASING)

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

/// Hull render origin shared by everyone aboard. Never assigned to client.eye.
/obj/effect/abstract/tadpole_render_origin
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	atom_flags = SHUTTLE_IMMUNE | PREVENT_CONTENTS_EXPLOSION

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
	var/list/unscaled_planes = list()
	var/capture_active = FALSE
	var/client/capture_client
	var/datum/tadpole_viewport/viewport
	var/atom/movable/render_plane_relay/rotation_relay
	var/matrix/original_rotation_transform
	var/capture_x = 0
	var/capture_y = 0
	var/capture_width = TADPOLE_CAPTURE_SIZE
	var/capture_height = TADPOLE_CAPTURE_SIZE
	var/atom/movable/screen/plane_master/emissive_plate
	var/had_emissive_relay = FALSE
	var/datum/tadpole_scene/scene
	var/atom/movable/tracked_eye
	var/mob/visibility_owner

/datum/tadpole_scene_view/New(datum/hud/display, depth, datum/tadpole_scene/owner)
	hud = display
	scene = owner
	source_offset = depth
	plate = hud.get_plane_master(GET_NEW_PLANE(RENDER_PLANE_MASTER, depth))
	if(!plate)
		return
	original_transform = plate.transform
	plate.remove_relay_from(GET_NEW_PLANE(RENDER_PLANE_TRANSPARENT, depth - 1))
	output_plane = GET_NEW_PLANE(TADPOLE_GROUND_PLANE, hud.current_plane_offset)
	plate.add_relay_to(output_plane)
	var/datum/plane_master_group/group = hud.get_plane_group(PLANE_GROUP_MAIN)
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
	scene = null
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
	release_capture()
	visibility_owner = viewer
	if(!viewer)
		return
	viewer.add_sight_modifier(REF(src), SEE_SELF | SEE_TURFS | SEE_OBJS | SEE_MOBS)
	RegisterSignals(viewer, list(COMSIG_MOB_LOGOUT, COMSIG_QDELETING), PROC_REF(on_visibility_lost))

/datum/tadpole_scene_view/proc/on_visibility_lost()
	SIGNAL_HANDLER
	track_eye(null)
	bind_visibility(null)

/// Keep the native camera on the character. Only the ground output is rotated;
/// no final game/FOV/ghost relay receives a synthetic camera animation.
/datum/tadpole_scene_view/proc/start_capture(client/display)
	if(!display || capture_client == display || tracked_eye != display.mob || display.eye != tracked_eye)
		return
	if(isliving(display.mob) && display.mob.stat == DEAD)
		return
	if(!scene?.helm.ground_tiles[get_turf(display.eye)])
		return
	capture_client = display
	RegisterSignal(display, COMSIG_CLIENT_SET_EYE, PROC_REF(on_client_eye_change))
	begin_capture()
	viewport = new
	viewport.start(src, display)

/datum/tadpole_scene_view/proc/release_capture()
	if(capture_client)
		UnregisterSignal(capture_client, COMSIG_CLIENT_SET_EYE)
	capture_client = null
	QDEL_NULL(viewport)
	end_capture()

/datum/tadpole_scene_view/proc/on_client_eye_change(datum/source, atom/old_eye, atom/new_eye)
	SIGNAL_HANDLER
	if(new_eye != tracked_eye)
		release_capture()

/datum/tadpole_scene_view/proc/begin_capture()
	if(capture_active || QDELETED(hud) || !hud.mymob)
		return
	capture_active = TRUE
	rotation_relay = plate.get_relay_to(output_plane)
	original_rotation_transform = rotation_relay.transform || matrix()
	animate(plate, transform = original_transform, time = 0)
	set_capture_size(TADPOLE_CAPTURE_SIZE, TADPOLE_CAPTURE_SIZE)
	last_camera = null
	animation_from = null
	animation_duration = 0

/// Crop in unrotated source space, around the hull rather than the viewer.
/datum/tadpole_scene_view/proc/set_capture_size(width, height)
	capture_width = width
	capture_height = height
	plate.add_filter("tadpole_capture_bounds", 100, alpha_mask_filter(icon = capture_mask(width, height), x = capture_x, y = capture_y))

/datum/tadpole_scene_view/proc/capture_mask(width = TADPOLE_CAPTURE_SIZE, height = TADPOLE_CAPTURE_SIZE)
	var/static/list/masks = list()
	var/key = "[width]x[height]"
	if(!masks[key])
		var/icon/bounds = icon('icons/effects/alphacolors.dmi', "white")
		bounds.Scale(width * world.icon_size, height * world.icon_size)
		masks[key] = bounds
	return masks[key]

/datum/tadpole_scene_view/proc/update_capture_origin(dx, dy, animation_seconds)
	if(capture_x == dx && capture_y == dy)
		return
	capture_x = dx
	capture_y = dy
	var/bounds = plate.get_filter("tadpole_capture_bounds")
	animate(bounds, x = dx, y = dy, time = animation_seconds * 10, easing = LINEAR_EASING)

/datum/tadpole_scene_view/proc/end_capture()
	if(!capture_active)
		return
	capture_active = FALSE
	plate?.remove_filter("tadpole_capture_bounds")
	if(!QDELETED(rotation_relay))
		animate(rotation_relay, transform = original_rotation_transform, time = 0)
	rotation_relay = null
	original_rotation_transform = null
	capture_x = 0
	capture_y = 0
	last_camera = null
	animation_from = null
	animation_duration = 0

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
/// Only ground projection/cropping changes; native camera and mob glide are untouched.
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
		start_capture(hud.mymob.client)
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
	var/atom/movable/target = capture_active ? rotation_relay : plate
	animate(target, transform = camera, time = animation_duration, easing = LINEAR_EASING)

/// Match the LINEAR_EASING matrix interpolation currently visible to clients.
/datum/tadpole_scene_view/proc/displayed_camera()
	if(!last_camera)
		var/atom/movable/target = capture_active ? rotation_relay : plate
		return target?.transform ? matrix(target.transform) : matrix()
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
	var/obj/effect/abstract/tadpole_render_origin/render_origin

/datum/tadpole_scene/New(obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/owner)
	helm = owner
	ensure_render_origin()

/datum/tadpole_scene/Destroy()
	QDEL_LIST_ASSOC_VAL(views)
	QDEL_LIST_ASSOC_VAL(chunks)
	QDEL_NULL(render_origin)
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
	ensure_render_origin()
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
		view.start_capture(display)
		remaining -= display
	for(var/client/departed as anything in remaining)
		qdel(views[departed])
		views -= departed
	if(!needed_radius)
		if(length(chunks))
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
		view.viewport?.sync_hud()
		update_view(view, get_turf(display.eye), animation_seconds)

/datum/tadpole_scene/proc/update_view(datum/tadpole_scene_view/view, turf/eye, animation_seconds)
	if(!eye || QDELETED(view.plate) || isnull(origin_x) || isnull(origin_y))
		return
	ensure_render_origin()
	var/angle = helm.flight_heading - dir2angle(helm.shuttle_port.dir)
	var/turf/capture_eye = eye
	var/px = render_origin.x - capture_eye.x
	var/py = render_origin.y - capture_eye.y
	var/matrix/camera = matrix()
	camera.Turn(-angle)
	camera.Translate((px - camera.a * px - camera.b * py) * world.icon_size, (py - camera.d * px - camera.e * py) * world.icon_size)
	view.update_camera(camera, animation_seconds)
	if(view.capture_active)
		view.update_capture_origin(px * world.icon_size, py * world.icon_size, animation_seconds)

/datum/tadpole_scene/proc/ensure_render_origin()
	var/obj/docking_port/mobile/port = helm.shuttle_port
	if(!port?.z)
		return
	if(QDELETED(render_origin))
		render_origin = new
	var/list/bounds = port.return_coords(port.x, port.y, port.dir)
	var/turf/center = locate(round((bounds[1] + bounds[3]) / 2 + 0.5), round((bounds[2] + bounds[4]) / 2 + 0.5), port.z)
	if(center && render_origin.loc != center)
		render_origin.abstract_move(center)

/// Recenter source translation around the fixed eye before composition.
/// The inverse rotation preserves P + R*(S-F) and actual landing coordinates.
/datum/tadpole_scene/proc/target_source_position()
	ensure_render_origin()
	var/dx = render_origin.x - helm.shuttle_port.x
	var/dy = render_origin.y - helm.shuttle_port.y
	var/matrix/rotation = matrix()
	rotation.Turn(-(helm.flight_heading - dir2angle(helm.shuttle_port.dir)))
	return list(helm.flight_x - dx + rotation.a * dx + rotation.d * dy, helm.flight_y - dy + rotation.b * dx + rotation.e * dy)

/// One shared flight timeline, independent of all passenger positions.
/datum/tadpole_scene/proc/displayed_source_position()
	if(isnull(source_to_x) || isnull(source_to_y))
		return target_source_position()
	var/progress = source_duration ? clamp((world.time - source_started) / source_duration, 0, 1) : 1
	return list(source_from_x + (source_to_x - source_from_x) * progress, source_from_y + (source_to_y - source_from_y) * progress)

/datum/tadpole_scene/proc/update_source_position(animation_seconds)
	var/obj/docking_port/mobile/port = helm.shuttle_port
	var/list/target = target_source_position()
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
		chunk.move_ground(port.x + first.x - source_from_x, port.y + first.y - source_from_y, port.x + first.x - source_to_x, port.y + first.y - source_to_y, port.z, source_duration)
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

/// Cover the normal visible window at every hull tile and every rotation.
/// The source crop is hull-centered; the native viewport also needs the offset
/// from a passenger to that crop, plus a tile for unfinished camera glide.
/// Logical observer zoom deliberately does not grow this shared geometry.
/datum/tadpole_scene/proc/capture_geometry()
	ensure_render_origin()
	var/obj/docking_port/mobile/port = helm.shuttle_port
	var/list/bounds = port.return_coords(port.x, port.y, port.dir)
	var/dx = max(abs(bounds[1] - render_origin.x), abs(bounds[3] - render_origin.x))
	var/dy = max(abs(bounds[2] - render_origin.y), abs(bounds[4] - render_origin.y))
	var/list/visible = getviewsize(CONFIG_GET(string/default_view))
	var/radius = sqrt((visible[1] / 2 + dx) ** 2 + (visible[2] / 2 + dy) ** 2)
	var/side = max(TADPOLE_CAPTURE_SIZE, 2 * CEILING(radius - 0.5, 1) + 1)
	return list(side, side + 2 * (dx + 1), side + 2 * (dy + 1))

/// Allocate for the shared hull buffer, never for a passenger's walking tile.
/datum/tadpole_scene/proc/source_radius(list/size)
	var/obj/docking_port/mobile/port = helm.shuttle_port
	var/footprint = max(port.width + abs(port.dwidth), port.height + abs(port.dheight))
	var/list/geometry = capture_geometry()
	return CEILING(sqrt(2 * geometry[1] ** 2) / 2, 1) + footprint + 2

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
				chunk.move_ground(helm.shuttle_port.x + max(1, x) - current[1], helm.shuttle_port.y + max(1, y) - current[2], helm.shuttle_port.x + max(1, x) - target_x, helm.shuttle_port.y + max(1, y) - target_y, helm.z, remaining_time)
			else
				remaining -= key
	for(var/key in remaining)
		qdel(chunks[key])
		chunks -= key

/obj/effect/abstract/tadpole_searchlight
	icon = null
	// The movable light is an underlay and inherits its holder's visibility.
	// An empty icon keeps the source hidden without hiding the light itself.
	invisibility = 0
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	atom_flags = SHUTTLE_IMMUNE|PREVENT_CONTENTS_EXPLOSION
	light_system = MOVABLE_LIGHT
	light_on = TRUE
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
