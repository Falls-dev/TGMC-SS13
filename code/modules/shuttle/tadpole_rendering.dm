#define TADPOLE_BUCKET_SIZE 8

/// A spatial holder for one real turf, following upstream's z_holder model.
/// Grouping is metadata only; no render root contains an entire 8x8 tree.
/obj/effect/abstract/tadpole_native_tile
	icon = null
	plane = HUD_PLANE
	appearance_flags = PIXEL_SCALE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	animate_movement = NO_STEPS
	atom_flags = SHUTTLE_IMMUNE | PREVENT_CONTENTS_EXPLOSION
	var/turf/source

/obj/effect/abstract/tadpole_native_tile/proc/place(tile_x, tile_y, transit_z, update_pixels = TRUE)
	var/turf/target = locate(clamp(tile_x, 1, world.maxx), clamp(tile_y, 1, world.maxy), transit_z)
	if(!target)
		return
	if(loc != target)
		// Never trigger passenger transit-entry/airdrop hooks for visual holders.
		abstract_move(target)
	if(update_pixels)
		pixel_x = (tile_x - target.x) * world.icon_size
		pixel_y = (tile_y - target.y) * world.icon_size

/obj/effect/abstract/tadpole_native_tile/proc/build(tile_x, tile_y, ground_z)
	clear_source()
	source = locate(tile_x, tile_y, ground_z)
	if(!source)
		return
	vis_contents += source
	RegisterSignal(source, COMSIG_TURF_CHANGE, PROC_REF(on_turf_change))

/obj/effect/abstract/tadpole_native_tile/proc/on_turf_change(datum/old_source, path, baseturfs, flags, list/callbacks)
	SIGNAL_HANDLER
	callbacks += CALLBACK(src, PROC_REF(reconnect))

/obj/effect/abstract/tadpole_native_tile/proc/reconnect(turf/replacement)
	if(QDELETED(src) || source != replacement)
		return
	// A pooled holder may have acquired another source before this callback.
	vis_contents = list(source)

/// Pool entries have no visual tree, turf subscriptions or spatial location.
/obj/effect/abstract/tadpole_native_tile/proc/clear_source()
	if(!source && !loc && !length(vis_contents))
		return
	if(source)
		UnregisterSignal(source, COMSIG_TURF_CHANGE)
	source = null
	vis_contents.Cut()
	pixel_x = 0
	pixel_y = 0
	abstract_move(null)

/obj/effect/abstract/tadpole_native_tile/Destroy()
	clear_source()
	return ..()

/// One common translation pass for finished, lit terrain. The following
/// relay crops/rotates it; individual turf holders never animate in flight.
/atom/movable/screen/plane_master/rendering_plate/tadpole_source
	name = "Tadpole translated ground"
	documentation = "Composes the shared flight translation before hull cropping and rotation."
	plane = TADPOLE_SOURCE_PLANE
	render_relay_planes = list(TADPOLE_GROUND_PLANE)

/// Shared hull origin for ground projection; never assigned to client.eye.
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
	var/source_plane
	var/atom/movable/screen/plane_master/translated_plate
	var/atom/movable/render_plane_relay/translation_relay
	var/source_revision = -1
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
	source_plane = GET_NEW_PLANE(TADPOLE_SOURCE_PLANE, hud.current_plane_offset)
	plate.add_relay_to(source_plane)
	translation_relay = plate.get_relay_to(source_plane)
	translated_plate = hud.get_plane_master(source_plane)
	rotation_relay = translated_plate.get_relay_to(output_plane)
	original_rotation_transform = rotation_relay.transform || matrix()
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
		plate.remove_relay_from(source_plane)
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
	animate(plate, transform = original_transform, time = 0)
	set_capture_size(TADPOLE_CAPTURE_SIZE, TADPOLE_CAPTURE_SIZE)
	last_camera = null
	animation_from = null
	animation_duration = 0

/// Crop in unrotated source space, around the hull rather than the viewer.
/datum/tadpole_scene_view/proc/set_capture_size(width, height)
	capture_width = width
	capture_height = height
	rotation_relay.add_filter("tadpole_capture_bounds", 100, alpha_mask_filter(icon = capture_mask(width, height), x = capture_x, y = capture_y))

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
	var/bounds = rotation_relay.get_filter("tadpole_capture_bounds")
	animate(bounds, x = dx, y = dy, time = animation_seconds * 10, easing = LINEAR_EASING)

/datum/tadpole_scene_view/proc/end_capture()
	if(!capture_active)
		return
	capture_active = FALSE
	rotation_relay?.remove_filter("tadpole_capture_bounds")
	if(!QDELETED(rotation_relay))
		animate(rotation_relay, transform = original_rotation_transform, time = 0)
	source_revision = -1
	capture_x = 0
	capture_y = 0
	last_camera = null
	animation_from = null
	animation_duration = 0

/// Source motion is independent of passenger walking. Rebase the common
/// translation only when holder coordinates move to another integer anchor.
/datum/tadpole_scene_view/proc/sync_source_translation()
	if(!scene || isnull(scene.source_to_x) || QDELETED(translation_relay) || source_revision == scene.source_revision)
		return
	var/matrix/target = matrix()
	target.Translate((scene.source_anchor_x - scene.source_to_x) * world.icon_size, (scene.source_anchor_y - scene.source_to_y) * world.icon_size)
	// Replace the old timeline explicitly. A rebase changes the meaning of
	// every pixel offset, so the old animation must never resume afterwards.
	var/list/current = scene.displayed_source_position()
	var/matrix/from = matrix()
	from.Translate((scene.source_anchor_x - current[1]) * world.icon_size, (scene.source_anchor_y - current[2]) * world.icon_size)
	var/remaining = max(0, scene.source_duration - (world.time - scene.source_started))
	animate(translation_relay, transform = from, time = 0, flags = ANIMATION_END_NOW)
	if(remaining)
		animate(transform = target, time = remaining, easing = LINEAR_EASING, flags = ANIMATION_LINEAR_TRANSFORM)
	source_revision = scene.source_revision

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
	var/atom/movable/target = rotation_relay
	animate(target, transform = camera, time = animation_duration, easing = LINEAR_EASING)

/// Match the LINEAR_EASING matrix interpolation currently visible to clients.
/datum/tadpole_scene_view/proc/displayed_camera()
	if(!last_camera)
		var/atom/movable/target = rotation_relay
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
	var/list/sources = list()
	var/list/source_pool = list()
	var/list/source_bounds
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
	var/source_anchor_x
	var/source_anchor_y
	var/source_revision = 0
	var/last_port_x
	var/last_port_y
	var/last_port_z
	var/obj/effect/abstract/tadpole_render_origin/render_origin

/datum/tadpole_scene/New(obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/owner)
	helm = owner
	ensure_render_origin()

/datum/tadpole_scene/Destroy()
	QDEL_LIST_ASSOC_VAL(views)
	QDEL_LIST_ASSOC_VAL(sources)
	QDEL_LIST(source_pool)
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
		if(length(sources))
			QDEL_LIST_ASSOC_VAL(sources)
		QDEL_LIST(source_pool)
		source_bounds = null
		radius = 0
		source_to_x = null
		source_to_y = null
		source_duration = 0
		source_anchor_x = null
		source_anchor_y = null
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
	view.sync_source_translation()
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

/// Recenter the shared source translation around the hull before composition.
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
	// Keep the existing anchor until the common render offset exhausts its margin.
	var/anchor_x = source_anchor_x
	var/anchor_y = source_anchor_y
	if(isnull(anchor_x) || max(abs(anchor_x - current[1]), abs(anchor_x - target[1])) > TADPOLE_SOURCE_GUARD)
		anchor_x = round((current[1] + target[1]) / 2 + 0.5)
	if(isnull(anchor_y) || max(abs(anchor_y - current[2]), abs(anchor_y - target[2])) > TADPOLE_SOURCE_GUARD)
		anchor_y = round((current[2] + target[2]) / 2 + 0.5)
	var/offset = max(abs(anchor_x - current[1]), abs(anchor_x - target[1]), abs(anchor_y - current[2]), abs(anchor_y - target[2]))
	if(offset > TADPOLE_SOURCE_GUARD)
		// Teleports/long server stalls must not animate unavailable source pixels.
		current = target.Copy()
		anchor_x = round(target[1] + 0.5)
		anchor_y = round(target[2] + 0.5)
		animation_seconds = 0
	var/rebase = source_anchor_x != anchor_x || source_anchor_y != anchor_y || last_port_x != port.x || last_port_y != port.y || last_port_z != port.z
	source_from_x = current[1]
	source_from_y = current[2]
	source_to_x = target[1]
	source_to_y = target[2]
	source_started = world.time
	source_duration = initialized ? animation_seconds * 10 : 0
	source_anchor_x = anchor_x
	source_anchor_y = anchor_y
	source_revision++
	last_port_x = port.x
	last_port_y = port.y
	last_port_z = port.z
	update_sources(!rebase)
	if(rebase)
		var/offset_x = port.x - anchor_x
		var/offset_y = port.y - anchor_y
		for(var/key in sources)
			var/obj/effect/abstract/tadpole_native_tile/holder = sources[key]
			var/turf/tile = holder.source
			holder.place(offset_x + tile.x, offset_y + tile.y, port.z)
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
/// from a passenger to that crop, plus a tile for shared source translation and camera glide.
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
	return list(side, side + 2 * (dx + TADPOLE_SOURCE_GUARD), side + 2 * (dy + TADPOLE_SOURCE_GUARD))

/// One adjacent row around the shared hull crop; no per-passenger source set.
/datum/tadpole_scene/proc/source_radius(list/size)
	var/list/geometry = capture_geometry()
	return CEILING(geometry[1] / 2, 1) + 1

/datum/tadpole_scene/proc/update_region(needed_radius, ground_z)
	needed_radius = max(radius, needed_radius)
	var/new_x = FLOOR(helm.flight_x / TADPOLE_BUCKET_SIZE, 1) * TADPOLE_BUCKET_SIZE
	var/new_y = FLOOR(helm.flight_y / TADPOLE_BUCKET_SIZE, 1) * TADPOLE_BUCKET_SIZE
	if(origin_x != new_x || origin_y != new_y || source_z != ground_z || radius != needed_radius)
		origin_x = new_x
		origin_y = new_y
		source_z = ground_z
		radius = needed_radius
		update_sources()
		return TRUE
	return FALSE

/// Stream only the shared native capture and its current animation corridor.
/// Holders leaving the window are detached before allocating incoming rows,
/// allowing the same objects to serve the next source strip without GC bursts.
/datum/tadpole_scene/proc/update_sources(place_new = TRUE)
	if(!source_z || !radius)
		return FALSE
	var/list/current = displayed_source_position()
	var/target_x = isnull(source_to_x) ? current[1] : source_to_x
	var/target_y = isnull(source_to_y) ? current[2] : source_to_y
	if(isnull(source_anchor_x) || isnull(source_anchor_y))
		source_anchor_x = round(current[1] + 0.5)
		source_anchor_y = round(current[2] + 0.5)
	var/obj/docking_port/mobile/port = helm.shuttle_port
	ensure_render_origin()
	var/dx = render_origin.x - port.x
	var/dy = render_origin.y - port.y
	var/min_x = max(1, FLOOR(min(current[1], target_x) + dx - radius, 1))
	var/max_x = min(world.maxx, CEILING(max(current[1], target_x) + dx + radius, 1))
	var/min_y = max(1, FLOOR(min(current[2], target_y) + dy - radius, 1))
	var/max_y = min(world.maxy, CEILING(max(current[2], target_y) + dy + radius, 1))
	if(source_bounds && source_bounds[1] == min_x && source_bounds[2] == min_y && source_bounds[3] == max_x && source_bounds[4] == max_y && source_bounds[5] == source_z)
		return FALSE
	var/list/previous_bounds = source_bounds
	source_bounds = list(min_x, min_y, max_x, max_y, source_z)
	var/list/retired = list()
	for(var/key in sources)
		var/obj/effect/abstract/tadpole_native_tile/holder = sources[key]
		var/turf/tile = holder.source
		if(tile && tile.z == source_z && tile.x >= min_x && tile.x <= max_x && tile.y >= min_y && tile.y <= max_y)
			continue
		retired += key
		holder.clear_source()
		source_pool += holder
	for(var/key in retired)
		sources -= key
	for(var/x in min_x to max_x)
		var/has_overlap = previous_bounds && previous_bounds[5] == source_z && x >= previous_bounds[1] && x <= previous_bounds[3]
		for(var/y = min_y; y <= max_y; y++)
			if(has_overlap && y >= previous_bounds[2] && y <= previous_bounds[4])
				y = previous_bounds[4]
				continue
			var/key = "[x],[y],[source_z]"
			var/obj/effect/abstract/tadpole_native_tile/holder
			if(length(source_pool))
				holder = source_pool[length(source_pool)]
				source_pool.len--
			else
				holder = new
			holder.build(x, y, source_z)
			sources[key] = holder
			if(place_new)
				holder.place(port.x + x - source_anchor_x, port.y + y - source_anchor_y, port.z)
	// Keep a few spare strips, not a second complete visual map in nullspace.
	while(length(source_pool) > 256)
		var/obj/effect/abstract/tadpole_native_tile/extra = source_pool[length(source_pool)]
		source_pool.len--
		qdel(extra)
	return TRUE

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

#undef TADPOLE_BUCKET_SIZE
