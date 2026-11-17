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

/// Translation only. Rotation belongs to the completed lower render plate.
/obj/effect/abstract/tadpole_native_tile/proc/move_ground(from_x, from_y, to_x, to_y, transit_z, duration)
	place(FLOOR(to_x, 1), FLOOR(to_y, 1), transit_z, FALSE)
	if(!loc)
		return
	animate(src, pixel_x = (from_x - x) * world.icon_size, pixel_y = (from_y - y) * world.icon_size, time = 0)
	animate(src, pixel_x = (to_x - x) * world.icon_size, pixel_y = (to_y - y) * world.icon_size, time = duration, easing = LINEAR_EASING)

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
	animate(src, pixel_x = 0, pixel_y = 0, time = 0)
	abstract_move(null)

/obj/effect/abstract/tadpole_native_tile/Destroy()
	clear_source()
	return ..()

/// Native capture origin shared by everyone aboard; never follows a passenger.
/obj/effect/abstract/tadpole_camera_anchor
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
	var/fixed_camera = FALSE
	var/client/camera_client
	var/atom/original_eye
	var/original_perspective
	var/changing_eye = FALSE
	var/list/world_relays = list()
	var/list/world_relay_flags = list()
	var/datum/tadpole_viewport/viewport
	var/atom/movable/render_plane_relay/rotation_relay
	var/matrix/original_rotation_transform
	var/world_from_x = 0
	var/world_from_y = 0
	var/world_to_x = 0
	var/world_to_y = 0
	var/world_started = 0
	var/world_duration = 0
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
	release_camera()
	visibility_owner = viewer
	if(!viewer)
		return
	viewer.add_sight_modifier(REF(src), SEE_SELF | SEE_TURFS | SEE_OBJS | SEE_MOBS)
	RegisterSignals(viewer, list(COMSIG_MOB_LOGOUT, COMSIG_QDELETING), PROC_REF(on_visibility_lost))

/datum/tadpole_scene_view/proc/on_visibility_lost()
	SIGNAL_HANDLER
	track_eye(null)
	bind_visibility(null)

/client/proc/tadpole_logical_eye()
	var/datum/tadpole_scene_view/view = tadpole_camera_view
	if(view?.camera_client == src && eye == view.scene?.camera_anchor)
		return view.tracked_eye || mob
	return eye

/// Only ordinary character cameras are pinned. Existing remote cameras retain
/// their own perspective and the original renderer until they are released.
/datum/tadpole_scene_view/proc/pin_camera(client/display)
	if(camera_client && camera_client.eye != scene?.camera_anchor)
		release_camera(FALSE)
	if(!display || camera_client == display || tracked_eye != display.mob || display.eye != tracked_eye)
		return
	if(isliving(display.mob) && display.mob.stat == DEAD)
		return
	scene.ensure_camera_anchor()
	if(!scene.camera_anchor?.loc || !scene.helm.ground_tiles[get_turf(tracked_eye)])
		return
	if(display.tadpole_camera_view && display.tadpole_camera_view != src)
		display.tadpole_camera_view.release_camera()
	camera_client = display
	original_eye = display.eye
	original_perspective = display.perspective
	display.tadpole_camera_view = src
	RegisterSignal(display, COMSIG_CLIENT_SET_EYE, PROC_REF(on_client_eye_change))
	RegisterSignal(scene.camera_anchor, COMSIG_QDELETING, PROC_REF(on_anchor_lost))
	begin_fixed_view()
	viewport = new
	viewport.start(src, display)
	var/turf/follow = get_turf(tracked_eye)
	update_world_shift((scene.camera_anchor.x - follow.x) * world.icon_size, (scene.camera_anchor.y - follow.y) * world.icon_size, 0)
	var/matrix/capture_rotation = matrix()
	capture_rotation.Turn(-(scene.helm.flight_heading - dir2angle(scene.helm.shuttle_port.dir)))
	update_camera(capture_rotation, 0)
	changing_eye = TRUE
	display.perspective = EYE_PERSPECTIVE
	display.set_eye(scene.camera_anchor)
	changing_eye = FALSE
	if(display.eye != scene.camera_anchor)
		release_camera(FALSE)

/datum/tadpole_scene_view/proc/release_camera(restore_eye = TRUE)
	var/client/display = camera_client
	var/was_fixed = fixed_camera
	camera_client = null
	QDEL_NULL(viewport)
	if(display)
		UnregisterSignal(display, COMSIG_CLIENT_SET_EYE)
		if(display.tadpole_camera_view == src)
			display.tadpole_camera_view = null
		if(scene?.camera_anchor)
			UnregisterSignal(scene.camera_anchor, COMSIG_QDELETING)
		if(restore_eye && display.eye == scene?.camera_anchor)
			var/atom/restore_target = QDELETED(original_eye) || display.mob != hud?.mymob ? display.mob : original_eye
			display.set_eye(restore_target)
			if(display.perspective == EYE_PERSPECTIVE)
				display.perspective = restore_target == original_eye ? original_perspective : MOB_PERSPECTIVE
	original_eye = null
	end_fixed_view()
	if(was_fixed && !QDELETED(scene) && !QDELETED(plate))
		var/turf/normal_eye = get_turf(display?.eye || tracked_eye)
		if(normal_eye)
			scene.update_view(src, normal_eye, 0)

/datum/tadpole_scene_view/proc/on_client_eye_change(datum/source, atom/old_eye, atom/new_eye)
	SIGNAL_HANDLER
	if(!changing_eye && new_eye != scene?.camera_anchor)
		// Another camera has taken over. Never overwrite its eye/perspective.
		release_camera(FALSE)

/datum/tadpole_scene_view/proc/on_anchor_lost()
	SIGNAL_HANDLER
	release_camera()

/datum/tadpole_scene_view/proc/logical_click_origin(turf/origin)
	if(fixed_camera && origin == get_turf(scene?.camera_anchor))
		return get_turf(tracked_eye) || origin
	return origin

/datum/tadpole_scene_view/proc/begin_fixed_view()
	if(fixed_camera || QDELETED(hud) || !hud.mymob)
		return
	fixed_camera = TRUE
	rotation_relay = plate.get_relay_to(output_plane)
	original_rotation_transform = rotation_relay.transform || matrix()
	animate(plate, transform = original_transform, time = 0)
	plate.add_filter("tadpole_capture_bounds", 100, alpha_mask_filter(icon = capture_mask()))
	last_camera = null
	animation_from = null
	animation_duration = 0
	RegisterSignals(hud.mymob, list(SIGNAL_ADDTRAIT(TRAIT_FOV_APPLIED), SIGNAL_REMOVETRAIT(TRAIT_FOV_APPLIED)), PROC_REF(on_world_graph_change))
	sync_world_relays()

/datum/tadpole_scene_view/proc/capture_mask()
	var/static/icon/bounds
	if(!bounds)
		bounds = icon('icons/effects/alphacolors.dmi', "white")
		bounds.Scale(TADPOLE_CAPTURE_SIZE * world.icon_size, TADPOLE_CAPTURE_SIZE * world.icon_size)
	return bounds

/datum/tadpole_scene_view/proc/end_fixed_view()
	if(!fixed_camera)
		return
	fixed_camera = FALSE
	if(hud?.mymob)
		UnregisterSignal(hud.mymob, list(SIGNAL_ADDTRAIT(TRAIT_FOV_APPLIED), SIGNAL_REMOVETRAIT(TRAIT_FOV_APPLIED)))
	for(var/atom/movable/render_plane_relay/relay as anything in world_relays)
		if(QDELETED(relay))
			continue
		var/matrix/original = world_relays[relay]
		// This mode owns these final copies until release. Their current
		// transform may still be anywhere along an unfinished client glide.
		animate(relay, transform = original, time = 0)
		if(!(world_relay_flags[relay] & PIXEL_SCALE))
			relay.appearance_flags &= ~PIXEL_SCALE
	world_relays.Cut()
	world_relay_flags.Cut()
	plate?.remove_filter("tadpole_capture_bounds")
	if(!QDELETED(rotation_relay))
		animate(rotation_relay, transform = original_rotation_transform, time = 0)
	rotation_relay = null
	original_rotation_transform = null
	last_camera = null
	animation_from = null
	animation_duration = 0
	world_from_x = 0
	world_from_y = 0
	world_to_x = 0
	world_to_y = 0
	world_duration = 0

/datum/tadpole_scene_view/proc/on_world_graph_change()
	SIGNAL_HANDLER
	sync_world_relays()

/datum/tadpole_scene_view/proc/displayed_world_shift()
	var/progress = world_duration ? clamp((world.time - world_started) / world_duration, 0, 1) : 1
	return list(world_from_x + (world_to_x - world_from_x) * progress, world_from_y + (world_to_y - world_from_y) * progress)

/datum/tadpole_scene_view/proc/update_world_shift(target_x, target_y, animation_seconds)
	var/changed = target_x != world_to_x || target_y != world_to_y
	if(changed)
		var/list/current = displayed_world_shift()
		world_from_x = current[1]
		world_from_y = current[2]
		world_to_x = target_x
		world_to_y = target_y
		world_started = world.time
		world_duration = animation_seconds * 10
	sync_world_relays(changed)

/// Shift final world copies after lighting and FOV. HUD/fullscreen relays are
/// deliberately untouched. Newly enabled FOV copies join the current glide.
/datum/tadpole_scene_view/proc/sync_world_relays(update_existing = FALSE)
	if(!fixed_camera || QDELETED(hud))
		return
	var/list/current = displayed_world_shift()
	var/remaining = max(0, world_duration - (world.time - world_started))
	for(var/plane_id in list(RENDER_PLANE_GAME, RENDER_PLANE_GAME_MASKED, RENDER_PLANE_GAME_UNMASKED, GHOST_PLANE, RUNECHAT_PLANE, BALLOON_CHAT_PLANE))
		var/atom/movable/screen/plane_master/source = hud.get_plane_master(GET_NEW_PLANE(plane_id, hud.current_plane_offset))
		var/target = (plane_id in list(RENDER_PLANE_GAME, RENDER_PLANE_GAME_MASKED, RENDER_PLANE_GAME_UNMASKED)) ? RENDER_PLANE_MASTER : RENDER_PLANE_NON_GAME
		var/atom/movable/render_plane_relay/relay = source?.get_relay_to(GET_NEW_PLANE(target, hud.current_plane_offset))
		if(!relay)
			continue
		var/is_new = !(relay in world_relays)
		if(is_new)
			world_relays[relay] = relay.transform || matrix()
			world_relay_flags[relay] = relay.appearance_flags
			relay.appearance_flags |= PIXEL_SCALE
		if(!is_new && !update_existing)
			continue
		var/matrix/from_transform = matrix(world_relays[relay])
		var/matrix/to_transform = matrix(world_relays[relay])
		from_transform.Translate(current[1], current[2])
		to_transform.Translate(world_to_x, world_to_y)
		// Existing copies continue from their actual client-side interpolation.
		// Resetting to our tick-based estimate on every step caused visible snaps.
		if(is_new)
			animate(relay, transform = from_transform, time = 0)
		animate(relay, transform = to_transform, time = remaining, easing = LINEAR_EASING, flags = ANIMATION_LINEAR_TRANSFORM)

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
/// This touches one plate only; no player discovery, source polling or sources.
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
		pin_camera(hud.mymob.client)
	var/duration = 0
	if(!forced && isturf(old_loc) && old_loc.z == eye.z && get_dist(old_loc, eye) == 1)
		var/dx = abs(eye.x - old_loc.x)
		var/dy = abs(eye.y - old_loc.y)
		var/distance = (source.appearance_flags & LONG_GLIDE) ? max(dx, dy) : sqrt(dx ** 2 + dy ** 2)
		duration = distance * world.icon_size / max(source.glide_size, 1) * world.tick_lag / 10
		if(fixed_camera)
			duration = follow_duration(source, eye)
	scene.update_view(src, eye, duration)

/// Native glide has constant pixel speed. A second step/reversal may arrive
/// before the previous glide ends; include the entire remaining displacement.
/datum/tadpole_scene_view/proc/follow_duration(atom/movable/source, turf/eye)
	var/list/current = displayed_world_shift()
	var/dx = abs((scene.camera_anchor.x - eye.x) * world.icon_size - current[1])
	var/dy = abs((scene.camera_anchor.y - eye.y) * world.icon_size - current[2])
	var/distance = (source.appearance_flags & LONG_GLIDE) ? max(dx, dy) : sqrt(dx ** 2 + dy ** 2)
	return distance / max(source.glide_size, 1) * world.tick_lag / 10

/datum/tadpole_scene_view/proc/update_camera(matrix/camera, animation_seconds)
	if(QDELETED(plate))
		return
	if(last_camera && last_camera.a == camera.a && last_camera.b == camera.b && last_camera.c == camera.c && last_camera.d == camera.d && last_camera.e == camera.e && last_camera.f == camera.f)
		return
	animation_from = displayed_camera()
	animation_started = world.time
	animation_duration = animation_seconds * 10
	last_camera = camera
	var/atom/movable/target = fixed_camera ? rotation_relay : plate
	animate(target, transform = camera, time = animation_duration, easing = LINEAR_EASING)

/// Match the LINEAR_EASING matrix interpolation currently visible to clients.
/datum/tadpole_scene_view/proc/displayed_camera()
	if(!last_camera)
		var/atom/movable/target = fixed_camera ? rotation_relay : plate
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
	var/last_port_x
	var/last_port_y
	var/last_port_z
	var/obj/effect/abstract/tadpole_camera_anchor/camera_anchor

/datum/tadpole_scene/New(obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/owner)
	helm = owner
	ensure_camera_anchor()

/datum/tadpole_scene/Destroy()
	QDEL_LIST_ASSOC_VAL(views)
	QDEL_LIST_ASSOC_VAL(sources)
	QDEL_LIST(source_pool)
	QDEL_NULL(camera_anchor)
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
	ensure_camera_anchor()
	var/list/remaining = views.Copy()
	var/needed_radius = 0
	if(world.time >= next_viewer_scan)
		refresh_viewer_candidates()
	for(var/client/display as anything in viewer_candidates)
		var/mob/viewer = display?.mob
		var/turf/eye = get_turf(display?.tadpole_logical_eye())
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
		view.track_eye(display.tadpole_logical_eye())
		view.bind_visibility(viewer)
		view.pin_camera(display)
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
		return
	update_region(needed_radius, helm.eyeobj.z)
	update_source_position(animation_seconds)
	for(var/client/display as anything in views)
		var/datum/tadpole_scene_view/view = views[display]
		view.viewport?.sync_hud()
		update_view(view, get_turf(display.tadpole_logical_eye()), animation_seconds)

/datum/tadpole_scene/proc/update_view(datum/tadpole_scene_view/view, turf/eye, animation_seconds)
	if(!eye || QDELETED(view.plate) || isnull(origin_x) || isnull(origin_y))
		return
	ensure_camera_anchor()
	var/angle = helm.flight_heading - dir2angle(helm.shuttle_port.dir)
	var/turf/capture_eye = view.fixed_camera ? get_turf(camera_anchor) : eye
	var/px = camera_anchor.x - capture_eye.x
	var/py = camera_anchor.y - capture_eye.y
	var/matrix/camera = matrix()
	camera.Turn(-angle)
	camera.Translate((px - camera.a * px - camera.b * py) * world.icon_size, (py - camera.d * px - camera.e * py) * world.icon_size)
	view.update_camera(camera, animation_seconds)
	if(view.fixed_camera)
		view.update_world_shift((camera_anchor.x - eye.x) * world.icon_size, (camera_anchor.y - eye.y) * world.icon_size, animation_seconds)

/datum/tadpole_scene/proc/ensure_camera_anchor()
	var/obj/docking_port/mobile/port = helm.shuttle_port
	if(!port?.z)
		return
	if(QDELETED(camera_anchor))
		camera_anchor = new
	var/list/bounds = port.return_coords(port.x, port.y, port.dir)
	var/turf/center = locate(round((bounds[1] + bounds[3]) / 2 + 0.5), round((bounds[2] + bounds[4]) / 2 + 0.5), port.z)
	if(center && camera_anchor.loc != center)
		camera_anchor.abstract_move(center)

/// Recenter source translation around the fixed eye before composition.
/// The inverse rotation preserves P + R*(S-F) and actual landing coordinates.
/datum/tadpole_scene/proc/target_source_position()
	ensure_camera_anchor()
	var/dx = camera_anchor.x - helm.shuttle_port.x
	var/dy = camera_anchor.y - helm.shuttle_port.y
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
	update_sources(FALSE)
	for(var/key in sources)
		var/obj/effect/abstract/tadpole_native_tile/holder = sources[key]
		var/turf/tile = holder.source
		holder.move_ground(port.x + tile.x - source_from_x, port.y + tile.y - source_from_y, port.x + tile.x - source_to_x, port.y + tile.y - source_to_y, port.z, source_duration)
	return TRUE

/// Discovery is separate from the five-Hz flight path. Existing viewers are
/// still validated every step; new remote eyes can take up to one second.
/datum/tadpole_scene/proc/refresh_viewer_candidates()
	viewer_candidates.Cut()
	for(var/mob/viewer as anything in GLOB.player_list)
		var/client/display = viewer.client
		var/turf/eye = get_turf(display?.tadpole_logical_eye())
		if(eye && helm.ground_tiles[eye])
			viewer_candidates |= display
	next_viewer_scan = world.time + 1 SECONDS

/// The raw 25x25 capture precedes rotation. Its center is computed explicitly
/// below, so it needs one neighboring row, not the hull plus a diagonal radius.
/datum/tadpole_scene/proc/source_radius(list/size)
	return CEILING(TADPOLE_CAPTURE_SIZE / 2, 1) + 1

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
/datum/tadpole_scene/proc/update_sources(move_new = TRUE)
	if(!source_z || !radius)
		return FALSE
	var/list/current = displayed_source_position()
	var/target_x = isnull(source_to_x) ? current[1] : source_to_x
	var/target_y = isnull(source_to_y) ? current[2] : source_to_y
	var/remaining_time = max(0, source_duration - (world.time - source_started))
	var/obj/docking_port/mobile/port = helm.shuttle_port
	ensure_camera_anchor()
	var/dx = camera_anchor.x - port.x
	var/dy = camera_anchor.y - port.y
	var/min_x = max(1, FLOOR(min(current[1], target_x) + dx - radius, 1))
	var/max_x = min(world.maxx, CEILING(max(current[1], target_x) + dx + radius, 1))
	var/min_y = max(1, FLOOR(min(current[2], target_y) + dy - radius, 1))
	var/max_y = min(world.maxy, CEILING(max(current[2], target_y) + dy + radius, 1))
	if(source_bounds && source_bounds[1] == min_x && source_bounds[2] == min_y && source_bounds[3] == max_x && source_bounds[4] == max_y && source_bounds[5] == source_z)
		return FALSE
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
		for(var/y in min_y to max_y)
			var/key = "[x],[y],[source_z]"
			if(sources[key])
				continue
			var/obj/effect/abstract/tadpole_native_tile/holder
			if(length(source_pool))
				holder = source_pool[length(source_pool)]
				source_pool.len--
			else
				holder = new
			holder.build(x, y, source_z)
			sources[key] = holder
			if(move_new)
				holder.move_ground(port.x + x - current[1], port.y + y - current[2], port.x + x - target_x, port.y + y - target_y, port.z, remaining_time)
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
