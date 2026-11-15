#define TADPOLE_CHUNK_SIZE 8

/// One world-space transform shared by every passenger. Do not flatten the
/// native child planes with KEEP_TOGETHER: their lighting graph is still used.
/obj/effect/abstract/tadpole_native_scene
	icon = null
	plane = HUD_PLANE
	appearance_flags = PIXEL_SCALE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/matrix/last_transform

/obj/effect/abstract/tadpole_native_scene/proc/update_transform(matrix/target, animation_seconds)
	if(last_transform && last_transform.a == target.a && last_transform.b == target.b && last_transform.c == target.c && last_transform.d == target.d && last_transform.e == target.e && last_transform.f == target.f)
		return FALSE
	last_transform = target
	animate(src, transform = target, time = animation_seconds * 10, easing = LINEAR_EASING)
	return TRUE

/obj/effect/abstract/tadpole_native_scene/Destroy()
	vis_contents.Cut()
	last_transform = null
	return ..()

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
	var/source_offset
	var/output_plane
	var/list/forced_planes = list()
	var/atom/movable/screen/plane_master/emissive_plate
	var/had_emissive_relay = FALSE

/datum/tadpole_scene_view/New(datum/hud/display, depth)
	hud = display
	source_offset = depth
	plate = hud.get_plane_master(GET_NEW_PLANE(RENDER_PLANE_MASTER, depth))
	if(!plate)
		return
	plate.remove_relay_from(GET_NEW_PLANE(RENDER_PLANE_TRANSPARENT, depth - 1))
	output_plane = GET_NEW_PLANE(TADPOLE_GROUND_PLANE, hud.current_plane_offset)
	plate.add_relay_to(output_plane)
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
	if(!QDELETED(plate))
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

/datum/tadpole_scene
	var/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/helm
	var/obj/effect/abstract/tadpole_native_scene/root
	/// Immutable ground reference; chunk buckets below only control membership.
	var/reference_x
	var/reference_y
	var/list/chunks = list()
	var/list/views = list()
	var/origin_x
	var/origin_y
	var/source_z
	var/radius = 0
	var/list/viewer_candidates = list()
	var/next_viewer_scan = 0

/datum/tadpole_scene/New(obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/owner)
	helm = owner
	root = new(get_turf(helm))
	reference_x = helm.flight_x
	reference_y = helm.flight_y

/datum/tadpole_scene/Destroy()
	QDEL_LIST_ASSOC_VAL(views)
	QDEL_NULL(root)
	QDEL_LIST_ASSOC_VAL(chunks)
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
			view = new(viewer.hud_used, depth)
			views[display] = view
		remaining -= display
	for(var/client/departed as anything in remaining)
		qdel(views[departed])
		views -= departed
	if(!needed_radius)
		if(length(chunks))
			root.vis_contents.Cut()
			QDEL_LIST_ASSOC_VAL(chunks)
		radius = 0
		return
	update_region(needed_radius, helm.eyeobj.z)
	root.update_transform(scene_transform(), animation_seconds)

/// Ground and docking coordinates only. Walking is handled by the engine's
/// ordinary world camera, just like the physical shuttle interior.
/datum/tadpole_scene/proc/scene_transform()
	var/angle = helm.flight_heading - dir2angle(helm.shuttle_port.dir)
	var/c = cos(angle)
	var/s = sin(angle)
	var/dx = reference_x - helm.flight_x
	var/dy = reference_y - helm.flight_y
	var/matrix/result = matrix()
	result.Turn(-angle)
	result.Translate((dx * c - dy * s + helm.shuttle_port.x - helm.x) * world.icon_size, (dy * c + dx * s + helm.shuttle_port.y - helm.y) * world.icon_size)
	return result

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
	var/obj/docking_port/mobile/port = helm.shuttle_port
	var/footprint = max(port.width + abs(port.dwidth), port.height + abs(port.dheight))
	return CEILING(sqrt(size[1] ** 2 + size[2] ** 2) / 2, 1) + footprint + 2

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
				chunk.pixel_x = (max(1, x) - reference_x) * world.icon_size
				chunk.pixel_y = (max(1, y) - reference_y) * world.icon_size
				root.vis_contents += chunk
			else
				remaining -= key
	for(var/key in remaining)
		root.vis_contents -= chunks[key]
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
