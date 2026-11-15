#define TADPOLE_CHUNK_SIZE 8

/// A world-space turf relay must have an explicit tile anchor. Bulk map_view
/// layout is intended for screen maps, not separately shifted world blocks.
/obj/effect/abstract/tadpole_native_tile
	icon = null
	plane = HUD_PLANE
	appearance_flags = PIXEL_SCALE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/abstract/tadpole_native_tile/Destroy()
	vis_contents.Cut()
	return ..()

/obj/effect/abstract/tadpole_native_chunk
	icon = null
	plane = HUD_PLANE
	appearance_flags = PIXEL_SCALE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/list/tiles = list()
	var/list/anchors = list()

/obj/effect/abstract/tadpole_native_chunk/proc/build(base_x, base_y, ground_z)
	var/turf/first = locate(max(1, base_x), max(1, base_y), ground_z)
	var/turf/last = locate(min(world.maxx, base_x + TADPOLE_CHUNK_SIZE - 1), min(world.maxy, base_y + TADPOLE_CHUNK_SIZE - 1), ground_z)
	if(!first || !last || base_x > world.maxx || base_y > world.maxy || base_x + TADPOLE_CHUNK_SIZE <= 1 || base_y + TADPOLE_CHUNK_SIZE <= 1)
		return
	tiles = block(first, last)
	for(var/turf/source as anything in tiles)
		var/obj/effect/abstract/tadpole_native_tile/anchor = new
		anchor.pixel_x = (source.x - first.x) * world.icon_size
		anchor.pixel_y = (source.y - first.y) * world.icon_size
		anchor.vis_contents += source
		anchors[source] = anchor
		vis_contents += anchor
		RegisterSignal(source, COMSIG_TURF_CHANGE, PROC_REF(on_turf_change))

/obj/effect/abstract/tadpole_native_chunk/proc/on_turf_change(datum/source, path, baseturfs, flags, list/callbacks)
	SIGNAL_HANDLER
	callbacks += CALLBACK(src, PROC_REF(reconnect))

/obj/effect/abstract/tadpole_native_chunk/proc/reconnect(turf/replacement)
	if(QDELETED(src))
		return
	var/obj/effect/abstract/tadpole_native_tile/anchor = anchors[replacement]
	if(anchor)
		anchor.vis_contents = list(replacement)

/obj/effect/abstract/tadpole_native_chunk/Destroy()
	for(var/turf/source as anything in tiles)
		UnregisterSignal(source, COMSIG_TURF_CHANGE)
	vis_contents.Cut()
	QDEL_LIST_ASSOC_VAL(anchors)
	tiles.Cut()
	return ..()

/// Owns a passenger's temporary connection to the completed lower render plate.
/datum/tadpole_scene_view
	var/datum/hud/hud
	var/atom/movable/screen/plane_master/rendering_plate/master/plate
	var/matrix/original_transform
	var/source_offset
	var/output_plane
	var/atom/movable/render_plane_relay/output_relay
	var/datum/tadpole_scene/scene
	var/atom/movable/eye_source
	var/eye_from_x
	var/eye_from_y
	var/eye_to_x
	var/eye_to_y
	var/eye_started = 0
	var/eye_duration = 0
	var/matrix/last_camera
	var/matrix/animation_from
	var/animation_started = 0
	var/animation_duration = 0
	var/list/forced_planes = list()
	var/atom/movable/screen/plane_master/emissive_plate
	var/had_emissive_relay = FALSE

/datum/tadpole_scene_view/New(datum/hud/display, depth, datum/tadpole_scene/owner)
	hud = display
	scene = owner
	source_offset = depth
	plate = hud.get_plane_master(GET_NEW_PLANE(RENDER_PLANE_MASTER, depth))
	if(!plate)
		return
	original_transform = plate.transform
	plate.remove_relay_from(GET_NEW_PLANE(RENDER_PLANE_TRANSPARENT, depth - 1))
	// The lower plate is ALREADY lit. Rendering it before upper lighting
	// applies the passenger's visibility/darkness a second time.
	output_plane = GET_NEW_PLANE(RENDER_PLANE_GAME, hud.current_plane_offset)
	var/late_layer = GET_NEW_PLANE(LIGHT_MASK_PLANE, hud.current_plane_offset) + abs(LOWEST_EVER_PLANE * 30) + 0.5
	plate.add_relay_to(output_plane, relay_layer = late_layer)
	output_relay = plate.get_relay_to(output_plane)
	var/atom/movable/screen/plane_master/ship_geometry = hud.get_plane_master(GET_NEW_PLANE(RENDER_PLANE_GAME_WORLD, hud.current_plane_offset))
	if(ship_geometry?.render_target)
		// Keep the completed lower scene behind native hull/occupant pixels.
		output_relay.add_filter("ship_cutout", 1, alpha_mask_filter(render_source = ship_geometry.render_target, flags = MASK_INVERSE))
	// Floors and several effect planes relay directly to GAME, not GAME_WORLD.
	for(var/upper_plane in list(FLOOR_PLANE, MASSIVE_OBJ_PLANE, GHOST_PLANE, POINT_PLANE))
		var/atom/movable/screen/plane_master/upper = hud.get_plane_master(GET_NEW_PLANE(upper_plane, hud.current_plane_offset))
		if(upper?.render_target)
			output_relay.add_filter("upper_cutout_[upper_plane]", 2, alpha_mask_filter(render_source = upper.render_target, flags = MASK_INVERSE))
	var/datum/plane_master_group/group = hud.get_plane_group(PLANE_GROUP_MAIN)
	for(var/key in group.plane_masters)
		var/atom/movable/screen/plane_master/master = group.plane_masters[key]
		if(master.offset < depth)
			continue
		if(master.is_outside_bounds)
			forced_planes += master
			master.inside_bounds(hud.mymob)
	emissive_plate = hud.get_plane_master(GET_NEW_PLANE(EMISSIVE_RENDER_PLATE, depth))
	if(emissive_plate?.get_relay_to(GET_NEW_PLANE(EMISSIVE_RENDER_PLATE, depth - 1)))
		had_emissive_relay = TRUE
		emissive_plate.remove_relay_from(GET_NEW_PLANE(EMISSIVE_RENDER_PLATE, depth - 1))

/datum/tadpole_scene_view/Destroy()
	bind_eye(null)
	scene = null
	if(!QDELETED(plate))
		animate(plate, transform = original_transform, time = 0)
		plate.remove_relay_from(output_plane)
		plate.offset_change(hud.current_plane_offset)
	if(had_emissive_relay && !QDELETED(emissive_plate))
		emissive_plate.add_relay_to(GET_NEW_PLANE(EMISSIVE_RENDER_PLATE, source_offset - 1), relay_layer = EMISSIVE_Z_BELOW_LAYER)
	if(!QDELETED(hud))
		var/datum/plane_master_group/group = hud.get_plane_group(PLANE_GROUP_MAIN)
		group?.build_planes_offset(hud, hud.current_plane_offset)
	hud = null
	plate = null
	emissive_plate = null
	output_relay = null
	forced_planes.Cut()
	return ..()

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

/// Blocks change coordinate frames instantly. Apply the inverse displacement
/// to the displayed camera instantly, before animating the next physics step.
/datum/tadpole_scene_view/proc/rebase_camera(shift_x, shift_y)
	if(QDELETED(plate) || !last_camera)
		return
	var/matrix/current = displayed_camera()
	var/remaining = max(0, animation_duration - (world.time - animation_started))
	current.c += current.a * shift_x + current.b * shift_y
	current.f += current.d * shift_x + current.e * shift_y
	var/matrix/target = matrix(last_camera)
	target.c += target.a * shift_x + target.b * shift_y
	target.f += target.d * shift_x + target.e * shift_y
	animation_from = current
	last_camera = target
	animation_started = world.time
	animation_duration = remaining
	animate(plate, transform = current, time = 0)
	if(remaining)
		animate(plate, transform = target, time = remaining, easing = LINEAR_EASING)

/// Track the actual eye's native glide instead of its destination turf.
/datum/tadpole_scene_view/proc/bind_eye(atom/movable/source)
	if(source == eye_source)
		return
	if(eye_source)
		UnregisterSignal(eye_source, list(COMSIG_MOVABLE_MOVED, COMSIG_QDELETING))
	eye_source = source
	eye_duration = 0
	if(!source)
		return
	var/turf/location = get_turf(source)
	eye_from_x = location?.x
	eye_to_x = location?.x
	eye_from_y = location?.y
	eye_to_y = location?.y
	RegisterSignal(source, COMSIG_MOVABLE_MOVED, PROC_REF(on_eye_moved))
	RegisterSignal(source, COMSIG_QDELETING, PROC_REF(on_eye_deleted))

/datum/tadpole_scene_view/proc/eye_position(at_time)
	var/progress = eye_duration ? clamp((at_time - eye_started) / eye_duration, 0, 1) : 1
	return list(eye_from_x + (eye_to_x - eye_from_x) * progress, eye_from_y + (eye_to_y - eye_from_y) * progress)

/datum/tadpole_scene_view/proc/on_eye_moved(atom/movable/source, atom/old_loc, movement_dir, forced)
	SIGNAL_HANDLER
	var/list/current = eye_position(world.time)
	var/turf/previous = get_turf(old_loc)
	var/turf/next = get_turf(source)
	if(!next)
		return
	eye_from_x = current[1]
	eye_from_y = current[2]
	eye_to_x = next.x
	eye_to_y = next.y
	eye_started = world.time
	eye_duration = !forced && previous && previous.z == next.z && get_dist(previous, next) <= 1 ? world.icon_size / max(source.glide_size, 1) * world.tick_lag : 0
	if(!eye_duration)
		eye_from_x = next.x
		eye_from_y = next.y
	// Start with the movement signal, not up to 0.2 seconds later.
	scene?.update_view_camera(src, eye_duration / 10)

/datum/tadpole_scene_view/proc/on_eye_deleted()
	SIGNAL_HANDLER
	bind_eye(null)

/datum/tadpole_scene
	var/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/helm
	var/list/chunks = list()
	var/list/views = list()
	var/origin_x
	var/origin_y
	var/source_z
	var/radius = 0

/datum/tadpole_scene/New(obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/owner)
	helm = owner

/datum/tadpole_scene/Destroy()
	QDEL_LIST_ASSOC_VAL(views)
	QDEL_LIST_ASSOC_VAL(chunks)
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
	for(var/mob/viewer as anything in GLOB.player_list)
		var/client/display = viewer.client
		var/turf/eye = get_turf(display?.eye)
		if(!eye || !helm.ground_tiles[eye] || !viewer.hud_used)
			continue
		var/list/size = getviewsize(display.view)
		needed_radius = max(needed_radius, view_radius(size, get_dist(eye, helm.shuttle_port)))
		var/datum/tadpole_scene_view/view = views[display]
		if(view && (view.hud != viewer.hud_used || view.source_offset != depth || QDELETED(view.plate) || view.plate.is_outside_bounds))
			qdel(view)
			view = null
		if(!view)
			view = new(viewer.hud_used, depth, src)
			views[display] = view
		view.bind_eye(ismovable(display.eye) ? display.eye : null)
		remaining -= display
	for(var/client/departed as anything in remaining)
		qdel(views[departed])
		views -= departed
	if(!needed_radius)
		if(length(chunks))
			QDEL_LIST_ASSOC_VAL(chunks)
		radius = 0
		return
	// Do not shrink/rebuild the scene for each passenger step. The footprint
	// margin covers normal walking; unusual remote eyes can grow it once.
	needed_radius = max(radius, needed_radius)
	var/new_x = FLOOR(helm.flight_x / TADPOLE_CHUNK_SIZE, 1) * TADPOLE_CHUNK_SIZE
	var/new_y = FLOOR(helm.flight_y / TADPOLE_CHUNK_SIZE, 1) * TADPOLE_CHUNK_SIZE
	if(origin_x != new_x || origin_y != new_y || source_z != helm.eyeobj.z || radius != needed_radius)
		if(!isnull(origin_x) && !isnull(origin_y) && (new_x != origin_x || new_y != origin_y))
			for(var/client/display as anything in views)
				var/datum/tadpole_scene_view/view = views[display]
				view.rebase_camera((new_x - origin_x) * world.icon_size, (new_y - origin_y) * world.icon_size)
		origin_x = new_x
		origin_y = new_y
		source_z = helm.eyeobj.z
		radius = needed_radius
		update_chunks()
	for(var/client/display as anything in views)
		update_view_camera(views[display], animation_seconds)

/datum/tadpole_scene/proc/update_view_camera(datum/tadpole_scene_view/view, animation_seconds)
	if(!helm?.shuttle_port || QDELETED(view.plate) || !view.eye_source || isnull(origin_x) || !helm.ground_tiles[get_turf(view.eye_source)])
		return
	var/remaining_eye_glide = max(0, view.eye_started + view.eye_duration - world.time)
	if(remaining_eye_glide && animation_seconds)
		animation_seconds = min(animation_seconds, remaining_eye_glide / 10)
	// Target the eye position at the END of the same interpolation interval.
	// Sampling only its current tile makes the background jump while walking.
	var/list/eye = view.eye_position(world.time + animation_seconds * 10)
	var/angle = helm.flight_heading - dir2angle(helm.shuttle_port.dir)
	var/c = cos(angle)
	var/s = sin(angle)
	var/px = helm.shuttle_port.x - eye[1]
	var/py = helm.shuttle_port.y - eye[2]
	var/dx = origin_x - helm.flight_x
	var/dy = origin_y - helm.flight_y
	var/matrix/camera = matrix()
	camera.Turn(-angle)
	camera.Translate((px - (px * c - py * s) + dx * c - dy * s) * world.icon_size, (py - (py * c + px * s) + dy * c + dx * s) * world.icon_size)
	view.update_camera(camera, animation_seconds)

/datum/tadpole_scene/proc/view_radius(list/size, eye_distance)
	var/footprint = max(helm.shuttle_port.width + abs(helm.shuttle_port.dwidth), helm.shuttle_port.height + abs(helm.shuttle_port.dheight))
	return max(radius, CEILING(sqrt(size[1] ** 2 + size[2] ** 2) / 2, 1) + max(footprint, eye_distance) + 2)

/datum/tadpole_scene/proc/update_chunks()
	var/list/remaining = chunks.Copy()
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
				chunk = new(get_turf(helm))
				chunk.build(x, y, source_z)
				chunks[key] = chunk
			else
				remaining -= key
			chunk.pixel_x = (max(1, x) - origin_x + helm.shuttle_port.x - helm.x) * world.icon_size
			chunk.pixel_y = (max(1, y) - origin_y + helm.shuttle_port.y - helm.y) * world.icon_size
	for(var/key in remaining)
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
