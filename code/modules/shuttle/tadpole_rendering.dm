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

/// The native source is collected at a fixed screen origin, independently
/// of the passenger camera. Its completed image is attached to the ship.
/atom/movable/screen/tadpole_source_canvas
	icon = null
	screen_loc = "CENTER,CENTER"
	plane = HUD_PLANE
	appearance_flags = PIXEL_SCALE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/tadpole_source_canvas/Destroy()
	vis_contents.Cut()
	return ..()

/// Owns a passenger's temporary connection to the completed lower render plate.
/datum/tadpole_scene_view
	var/datum/hud/hud
	var/atom/movable/screen/plane_master/rendering_plate/master/plate
	var/matrix/original_transform
	var/source_offset
	var/output_plane
	var/datum/tadpole_scene/scene
	var/client/display_client
	var/atom/movable/screen/tadpole_source_canvas/source_canvas
	var/image/ship_image
	var/view_width = 0
	var/view_height = 0
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
	display_client = hud.mymob?.canon_client
	source_offset = depth
	plate = hud.get_plane_master(GET_NEW_PLANE(RENDER_PLANE_MASTER, depth))
	if(!plate)
		return
	original_transform = plate.transform
	plate.remove_relay_from(GET_NEW_PLANE(RENDER_PLANE_TRANSPARENT, depth - 1))
	output_plane = GET_NEW_PLANE(TADPOLE_GROUND_PLANE, hud.current_plane_offset)
	plate.add_relay_to(output_plane)
	if(scene)
		// Keep the native target allocated, but replace its screen-fixed output
		// with a client-private world image at the real navigation console.
		var/atom/movable/render_plane_relay/screen_relay = plate.get_relay_to(output_plane)
		screen_relay.alpha = 0
		source_canvas = new
		ship_image = image(loc = scene.helm)
		ship_image.render_source = plate.render_target
		ship_image.plane = output_plane
		ship_image.layer = TOPDOWN_LAYER + 1
		ship_image.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		ship_image.appearance_flags = KEEP_TOGETHER | PIXEL_SCALE
		if(display_client)
			display_client.screen += source_canvas
			display_client.images += ship_image
		sync_chunks()
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
	if(display_client)
		display_client.screen -= source_canvas
		display_client.images -= ship_image
	QDEL_NULL(source_canvas)
	QDEL_NULL(ship_image)
	display_client = null
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
	forced_planes.Cut()
	return ..()

/datum/tadpole_scene_view/proc/sync_chunks()
	if(!source_canvas || !scene)
		return
	source_canvas.vis_contents.Cut()
	for(var/key in scene.chunks)
		source_canvas.vis_contents += scene.chunks[key]

/datum/tadpole_scene_view/proc/refresh_layout(width, height)
	if(!ship_image || (width == view_width && height == view_height))
		return
	view_width = width
	view_height = height
	// render_source is a full-map texture whose origin is its bottom-left.
	// Place its centre at the docking origin through a real world loc.
	ship_image.pixel_x = (scene.helm.shuttle_port.x - scene.helm.x) * world.icon_size - (width - 1) * world.icon_size / 2
	ship_image.pixel_y = (scene.helm.shuttle_port.y - scene.helm.y) * world.icon_size - (height - 1) * world.icon_size / 2

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
		needed_radius = max(needed_radius, required_radius(size))
		var/datum/tadpole_scene_view/view = views[display]
		if(view && (view.hud != viewer.hud_used || view.source_offset != depth || QDELETED(view.plate) || view.plate.is_outside_bounds))
			qdel(view)
			view = null
		if(!view)
			view = new(viewer.hud_used, depth, src)
			views[display] = view
		view.refresh_layout(size[1], size[2])
		remaining -= display
	for(var/client/departed as anything in remaining)
		qdel(views[departed])
		views -= departed
	if(!needed_radius)
		if(length(chunks))
			QDEL_LIST_ASSOC_VAL(chunks)
		radius = 0
		return
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
	var/matrix/camera = camera_transform()
	for(var/client/display as anything in views)
		var/datum/tadpole_scene_view/view = views[display]
		view.update_camera(camera, animation_seconds)

/// Only aircraft state enters this matrix. A passenger's position does not.
/datum/tadpole_scene/proc/camera_transform()
	var/angle = helm.flight_heading - dir2angle(helm.shuttle_port.dir)
	var/c = cos(angle)
	var/s = sin(angle)
	var/dx = origin_x - helm.flight_x
	var/dy = origin_y - helm.flight_y
	var/matrix/camera = matrix()
	camera.Turn(-angle)
	camera.Translate((dx * c - dy * s) * world.icon_size, (dy * c + dx * s) * world.icon_size)
	return camera

/datum/tadpole_scene/proc/required_radius(list/size)
	var/footprint = max(helm.shuttle_port.width + abs(helm.shuttle_port.dwidth), helm.shuttle_port.height + abs(helm.shuttle_port.dheight))
	return CEILING(sqrt(size[1] ** 2 + size[2] ** 2) / 2, 1) + footprint + 2

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
				chunk = new
				chunk.build(x, y, source_z)
				chunks[key] = chunk
			else
				remaining -= key
			chunk.pixel_x = (max(1, x) - origin_x) * world.icon_size
			chunk.pixel_y = (max(1, y) - origin_y) * world.icon_size
	for(var/key in remaining)
		qdel(chunks[key])
		chunks -= key
	for(var/client/display as anything in views)
		var/datum/tadpole_scene_view/view = views[display]
		view.sync_chunks()

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
