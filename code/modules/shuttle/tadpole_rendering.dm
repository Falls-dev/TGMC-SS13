#define TADPOLE_CHUNK_SIZE 4

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

/// Place a whole block at the integer origin of the projected source window.
/obj/effect/abstract/tadpole_native_chunk/proc/place(tile_x, tile_y, transit_z)
	var/turf/target = locate(clamp(tile_x, 1, world.maxx), clamp(tile_y, 1, world.maxy), transit_z)
	if(!target)
		return
	if(loc != target)
		// These are visual relays, not passengers: never trigger transit drops.
		abstract_move(target)
	if(tile_x != target.x || pixel_x)
		pixel_x = (tile_x - target.x) * world.icon_size
	if(tile_y != target.y || pixel_y)
		pixel_y = (tile_y - target.y) * world.icon_size

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
	var/projected_offset_x
	var/projected_offset_y
	var/projected_z
	var/matrix/last_camera
	var/matrix/animation_from
	var/animation_started = 0
	var/animation_duration = 0
	var/matrix/animation_midpoint
	var/animation_first_duration
	var/eye_from_x
	var/eye_from_y
	var/eye_to_x
	var/eye_to_y
	var/eye_started
	var/eye_duration = 0
	var/list/unscaled_planes = list()
	var/capture_active = FALSE
	var/client/capture_client
	var/datum/tadpole_viewport/viewport
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
	plate.add_relay_to(output_plane, relay_layer = 1)
	var/atom/movable/render_plane_relay/ground_relay = plate.get_relay_to(output_plane)
	// Let the relay receive the hit itself. Some composed pixels have no
	// click-catcher behind them once the source's mouse hits are disabled.
	ground_relay.mouse_opacity = MOUSE_OPACITY_OPAQUE
	ground_relay.appearance_flags &= ~PASS_MOUSE
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

/// Route background hits to the real transit map, in screen coordinates.
/// Onboard objects and other camera controls keep their native mouse targets.
/datum/tadpole_scene_view/proc/is_ground_mouse_target(atom/target, turf/eye)
	if(!eye || !scene?.helm?.ground_tiles[eye])
		return FALSE
	if(!target || istype(target, /atom/movable/screen/click_catcher))
		return TRUE
	if(target == plate?.get_relay_to(output_plane))
		return TRUE
	var/turf/target_turf = get_turf(target)
	return target_turf && target_turf.z != eye.z && target_turf.z == scene.helm.eyeobj?.z

/client/proc/tadpole_mouse_target(atom/target, control, list/modifiers)
	if(control != "mapwindow.map" || !tadpole_viewport?.active)
		return
	var/turf/origin = get_turf(eye)
	if(!tadpole_viewport.owner?.is_ground_mouse_target(target, origin))
		return
	var/screen_loc = modifiers["screen-loc"]
	var/turf/destination = params2turf(screen_loc, origin, src)
	if(!destination)
		return
	var/list/pixel = params2screenpixel(screen_loc)
	modifiers["icon-x"] = num2text(ABS_PIXEL_TO_REL(pixel[1]))
	modifiers["icon-y"] = num2text(ABS_PIXEL_TO_REL(pixel[2]))
	modifiers["catcher"] = "1"
	return destination

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
	last_camera = null
	animation_from = null
	animation_duration = 0

/datum/tadpole_scene_view/proc/end_capture()
	if(!capture_active)
		return
	capture_active = FALSE
	if(!QDELETED(plate))
		animate(plate)
		plate.transform = original_transform
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
	eye_duration = 0
	eye_to_x = null
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
	var/eye_shift_x = 0
	var/eye_shift_y = 0
	var/list/current_eye = list(old_loc?.x, old_loc?.y)
	if(!forced && isturf(old_loc) && old_loc.z == eye.z && get_dist(old_loc, eye) == 1)
		if(eye_to_x == old_loc.x && eye_to_y == old_loc.y)
			current_eye = displayed_eye()
			// Dream Seeker caps the unfinished scroll to one tile per axis
			// from the new destination. The cap applies before the new glide.
			var/start_x = clamp(current_eye[1], eye.x - 1, eye.x + 1)
			var/start_y = clamp(current_eye[2], eye.y - 1, eye.y + 1)
			eye_shift_x = start_x - current_eye[1]
			eye_shift_y = start_y - current_eye[2]
			current_eye[1] = start_x
			current_eye[2] = start_y
		var/dx = abs(eye.x - current_eye[1])
		var/dy = abs(eye.y - current_eye[2])
		var/distance = (source.appearance_flags & LONG_GLIDE) ? max(dx, dy) : sqrt(dx ** 2 + dy ** 2)
		duration = distance * world.icon_size / max(source.glide_size, 1) * world.tick_lag
	var/client/display = hud?.mymob?.client
	// Dream Seeker has already advanced the native camera one display tick
	// when the matching plane animation starts. Use the viewer's frame rate.
	var/step_lead = duration && display ? min(duration, display.tick_lag || world.tick_lag) : 0
	eye_from_x = current_eye[1]
	eye_from_y = current_eye[2]
	eye_to_x = eye.x
	eye_to_y = eye.y
	eye_started = world.time - step_lead
	eye_duration = duration
	scene.update_view(src, eye, duration / 10, step_lead, eye_shift_x, eye_shift_y)

/// Approximate the native camera glide using the eye's pixel speed.
/datum/tadpole_scene_view/proc/displayed_eye(at_time = world.time)
	var/progress = eye_duration ? clamp((at_time - eye_started) / eye_duration, 0, 1) : 1
	return list(eye_from_x + (eye_to_x - eye_from_x) * progress, eye_from_y + (eye_to_y - eye_from_y) * progress)

/// Both motion and heading live in this matrix. If a block was relocated,
/// convert the current transform to the new input coordinates before tweening.
/datum/tadpole_scene_view/proc/update_camera(matrix/camera, offset_x, offset_y, transit_z, animation_seconds, step_lead = 0, eye_shift_x = 0, eye_shift_y = 0)
	if(QDELETED(plate))
		return
	var/rebased = projected_offset_x != offset_x || projected_offset_y != offset_y || projected_z != transit_z
	if(!rebased && last_camera && last_camera.a == camera.a && last_camera.b == camera.b && last_camera.c == camera.c && last_camera.d == camera.d && last_camera.e == camera.e && last_camera.f == camera.f)
		return

	animation_from = displayed_camera()
	if(!last_camera || projected_z != transit_z || max(abs(projected_offset_x - offset_x), abs(projected_offset_y - offset_y)) > 2 * TADPOLE_SOURCE_GUARD)
		animation_seconds = 0
		step_lead = 0
	else if(rebased)
		var/dx = (projected_offset_x - offset_x) * world.icon_size
		var/dy = (projected_offset_y - offset_y) * world.icon_size
		animation_from.c += animation_from.a * dx + animation_from.b * dy
		animation_from.f += animation_from.d * dx + animation_from.e * dy

	var/eye_rebased = eye_shift_x || eye_shift_y
	if(eye_rebased)
		var/dx = eye_shift_x * world.icon_size
		var/dy = eye_shift_y * world.icon_size
		// Projection's eye term is (A - I) * eye, with A the current
		// rotation and scale. Apply the native jump in the same frame.
		animation_from.c += (animation_from.a - 1) * dx + animation_from.b * dy
		animation_from.f += animation_from.d * dx + (animation_from.e - 1) * dy

	projected_offset_x = offset_x
	projected_offset_y = offset_y
	projected_z = transit_z
	animation_started = world.time - step_lead
	animation_first_duration = animation_seconds * 10
	animation_duration = animation_first_duration
	animation_midpoint = null
	last_camera = camera
	// If the next flight update finishes before the eye glide, reach the
	// flight target using the eye position at that instant. Finish the
	// remaining walk separately instead of speeding it up to the flight tick.
	var/eye_remaining = eye_started + eye_duration - animation_started
	if(animation_first_duration > 0 && eye_remaining > animation_first_duration)
		var/list/intermediate_eye = displayed_eye(animation_started + animation_first_duration)
		var/dx = (eye_to_x - intermediate_eye[1]) * world.icon_size
		var/dy = (eye_to_y - intermediate_eye[2]) * world.icon_size
		animation_midpoint = matrix(camera)
		animation_midpoint.c += dx - camera.a * dx - camera.b * dy
		animation_midpoint.f += dy - camera.d * dx - camera.e * dy
		animation_duration = eye_remaining
	// The lower master uses a screen-centered surface. Its output relay
	// is anchored at SCREEN_SOUTHWEST on BYOND 516 and only composites it.
	if(animation_duration <= 0)
		animate(plate)
		plate.transform = camera
		return
	if(rebased || eye_rebased)
		// Stop the old animation before changing its coordinate basis.
		animate(plate)
		plate.transform = animation_from
	animate(plate, transform = animation_midpoint || camera, time = animation_first_duration, delay = -step_lead, easing = LINEAR_EASING, flags = ANIMATION_LINEAR_TRANSFORM)
	if(animation_midpoint)
		animate(transform = camera, time = animation_duration - animation_first_duration, easing = LINEAR_EASING, flags = ANIMATION_LINEAR_TRANSFORM)

/// Match the LINEAR_EASING matrix interpolation currently visible to clients.
/datum/tadpole_scene_view/proc/displayed_camera()
	if(!last_camera)
		return plate?.transform ? matrix(plate.transform) : matrix()
	var/elapsed = max(0, world.time - animation_started)
	if(!animation_from || elapsed >= animation_duration)
		return matrix(last_camera)
	var/matrix/from = animation_from
	var/matrix/endpoint = last_camera
	var/duration = animation_duration
	if(animation_midpoint)
		if(elapsed < animation_first_duration)
			endpoint = animation_midpoint
			duration = animation_first_duration
		else
			from = animation_midpoint
			elapsed -= animation_first_duration
			duration -= animation_first_duration
	var/progress = elapsed / duration
	var/matrix/result = matrix()
	result.a = from.a + (endpoint.a - from.a) * progress
	result.b = from.b + (endpoint.b - from.b) * progress
	result.c = from.c + (endpoint.c - from.c) * progress
	result.d = from.d + (endpoint.d - from.d) * progress
	result.e = from.e + (endpoint.e - from.e) * progress
	result.f = from.f + (endpoint.f - from.f) * progress
	return result

/datum/tadpole_scene
	var/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/helm
	var/list/sources = list()
	var/list/views = list()
	var/source_z
	var/radius = 0
	var/list/viewer_candidates = list()
	var/next_viewer_scan = 0
	var/source_anchor_x
	var/source_anchor_y
	var/source_offset_x
	var/source_offset_y
	var/source_transit_z
	var/list/source_bounds
	var/obj/effect/abstract/tadpole_render_origin/render_origin

/datum/tadpole_scene/New(obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/owner)
	helm = owner
	ensure_render_origin()

/datum/tadpole_scene/Destroy()
	QDEL_LIST_ASSOC_VAL(views)
	QDEL_LIST_ASSOC_VAL(sources)
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
		if(!needed_radius)
			needed_radius = source_radius()
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
		source_bounds = null
		source_offset_x = null
		source_anchor_x = null
		source_anchor_y = null
		return
	update_sources(needed_radius, helm.eyeobj.z)
	for(var/client/display as anything in views)
		var/datum/tadpole_scene_view/view = views[display]
		view.viewport?.sync_hud()
		update_view(view, get_turf(display.eye), animation_seconds)

/datum/tadpole_scene/proc/update_view(datum/tadpole_scene_view/view, turf/eye, animation_seconds, step_lead = 0, eye_shift_x = 0, eye_shift_y = 0)
	if(!eye || isnull(source_offset_x))
		return
	var/obj/docking_port/mobile/port = helm.shuttle_port
	// A ground point G lives at G + source_offset in the transit map.
	// Its destination in screen space is (port - eye) + R * (G - flight).
	var/matrix/camera = matrix()
	camera.Turn(dir2angle(port.dir) - helm.flight_heading)
	if(helm.transit_animation)
		camera.Scale(helm.transit_animation.ground_scale())
	var/input_x = helm.flight_x + source_offset_x - eye.x
	var/input_y = helm.flight_y + source_offset_y - eye.y
	camera.c = (port.x - eye.x - camera.a * input_x - camera.b * input_y) * world.icon_size
	camera.f = (port.y - eye.y - camera.d * input_x - camera.e * input_y) * world.icon_size
	view.update_camera(camera, source_offset_x, source_offset_y, source_transit_z, animation_seconds, step_lead, eye_shift_x, eye_shift_y)

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

/// A row outside the visible footprint accommodates oversized sprites.
/datum/tadpole_scene/proc/source_radius()
	var/list/geometry = capture_geometry()
	return CEILING(geometry[1] / 2, 1) + TADPOLE_SOURCE_GUARD + 1

/// Move the source window only when it outgrows its margin. Blocks overlap
/// between windows, so only entering/leaving strips change subscriptions.
/datum/tadpole_scene/proc/update_sources(needed_radius, ground_z)
	var/obj/docking_port/mobile/port = helm.shuttle_port
	var/matrix/rotation = matrix()
	rotation.Turn(dir2angle(port.dir) - helm.flight_heading)
	var/dx = render_origin.x - port.x
	var/dy = render_origin.y - port.y
	var/center_x = helm.flight_x + rotation.a * dx + rotation.d * dy
	var/center_y = helm.flight_y + rotation.b * dx + rotation.e * dy
	var/anchor_x = source_anchor_x
	var/anchor_y = source_anchor_y
	if(isnull(anchor_x) || abs(center_x - anchor_x) > TADPOLE_SOURCE_GUARD)
		anchor_x = round(center_x + 0.5)
	if(isnull(anchor_y) || abs(center_y - anchor_y) > TADPOLE_SOURCE_GUARD)
		anchor_y = round(center_y + 0.5)
	var/offset_x = render_origin.x - anchor_x
	var/offset_y = render_origin.y - anchor_y
	var/relocated = source_offset_x != offset_x || source_offset_y != offset_y || source_transit_z != port.z
	if(!relocated && anchor_x == source_anchor_x && anchor_y == source_anchor_y && source_z == ground_z && radius == needed_radius)
		return FALSE

	if(source_z != ground_z)
		QDEL_LIST_ASSOC_VAL(sources)
	source_z = ground_z
	source_anchor_x = anchor_x
	source_anchor_y = anchor_y
	source_offset_x = offset_x
	source_offset_y = offset_y
	source_transit_z = port.z
	radius = needed_radius

	var/min_x = FLOOR((max(1, anchor_x - radius) - 1) / TADPOLE_CHUNK_SIZE, 1) * TADPOLE_CHUNK_SIZE + 1
	var/max_x = min(world.maxx, anchor_x + radius)
	var/min_y = FLOOR((max(1, anchor_y - radius) - 1) / TADPOLE_CHUNK_SIZE, 1) * TADPOLE_CHUNK_SIZE + 1
	var/max_y = min(world.maxy, anchor_y + radius)
	source_bounds = list(min_x, min_y, min(world.maxx, FLOOR((max_x - 1) / TADPOLE_CHUNK_SIZE, 1) * TADPOLE_CHUNK_SIZE + TADPOLE_CHUNK_SIZE), min(world.maxy, FLOOR((max_y - 1) / TADPOLE_CHUNK_SIZE, 1) * TADPOLE_CHUNK_SIZE + TADPOLE_CHUNK_SIZE))

	var/list/retired = sources.Copy()
	for(var/x = min_x; x <= max_x; x += TADPOLE_CHUNK_SIZE)
		for(var/y = min_y; y <= max_y; y += TADPOLE_CHUNK_SIZE)
			var/key = "[x],[y]"
			var/obj/effect/abstract/tadpole_native_chunk/holder = sources[key]
			if(!holder)
				holder = new
				holder.build(x, y, ground_z)
				sources[key] = holder
				holder.place(x + offset_x, y + offset_y, port.z)
			else
				retired -= key
				if(relocated)
					holder.place(x + offset_x, y + offset_y, port.z)
	for(var/key in retired)
		qdel(sources[key])
		sources -= key
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

#undef TADPOLE_CHUNK_SIZE
