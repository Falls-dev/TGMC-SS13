// CAMERA CHUNK
//
// A grid of the map with a list of turfs that can be seen, are visible and are dimmed.
// Allows the AI Eye to stream these chunks and know what it can and cannot see.

/datum/camerachunk
	///turfs our cameras cant see but are inside our grid
	var/list/obscuredTurfs = list()
	///turfs our cameras can see inside our grid
	var/list/visibleTurfs = list()
	///cameras that can see into our grid
	var/list/cameras = list()
	///The cameranet this chunk belongs to
	var/datum/cameranet/parent_cameranet
	///list of all turfs
	var/list/turfs = list()
	///camera mobs that can see turfs in our grid
	var/list/seenby = list()
	///images currently in use on obscured turfs.
	var/list/active_static_images = list()

	var/changed = FALSE
	var/x = 0
	var/y = 0
	var/lower_z
	var/upper_z

/// Add a camera eye to the chunk, then update if changed.
/datum/camerachunk/proc/add(mob/camera/eye)
	eye.visibleCameraChunks += src
	seenby += eye
	if(changed)
		update()

	var/client/client = eye.GetViewerClient()
	if(client && eye.use_static)
		client.images += active_static_images

/// Remove a camera eye from the chunk
/datum/camerachunk/proc/remove(mob/camera/eye)
	eye.visibleCameraChunks -= src
	seenby -= eye

	var/client/client = eye.GetViewerClient()
	if(client && eye.use_static)
		client.images -= active_static_images

/// Called when a chunk has changed. I.E: A wall was deleted.
/datum/camerachunk/proc/visibilityChanged(turf/loc)
	if(!visibleTurfs[loc])
		return
	hasChanged()

/**
 * Updates the chunk, makes sure that it doesn't update too much. If the chunk isn't being watched it will
 * instead be flagged to update the next time an AI Eye moves near it.
 *
 * update_delay_buffer is used for cameras that are moving around (headset cams, etc).
 */
/datum/camerachunk/proc/hasChanged(update_now = 0, update_delay_buffer = UPDATE_BUFFER_TIME)
	if(seenby.len || update_now)
		addtimer(CALLBACK(src, PROC_REF(update)), update_delay_buffer, TIMER_UNIQUE)
	else
		changed = TRUE


/// The actual updating. It gathers the visible turfs from cameras and puts them into the appropiate lists.
/datum/camerachunk/proc/update(partial_update = FALSE)
	var/list/updated_visible_turfs = list()

	for(var/z_level in lower_z to upper_z)
		for(var/obj/machinery/camera/current_camera as anything in cameras["[z_level]"])
			if(!current_camera?.can_use())
				continue

			var/turf/point = locate(src.x + (CHUNK_SIZE / 2), src.y + (CHUNK_SIZE / 2), z_level)
			if(get_dist(point, current_camera) > MAX_CAMERA_RANGE + (CHUNK_SIZE / 2))
				continue

			// Left-hand & with turfs is a load-bearing performance pattern from tgstation#94530
			for(var/turf/vis_turf as anything in current_camera.can_see() & turfs)
				updated_visible_turfs[vis_turf] = vis_turf

	update_with_turfs(updated_visible_turfs)

/// Takes a list of newly visible turfs, updates our static images to match
/datum/camerachunk/proc/update_with_turfs(list/updated_visible_turfs)
	///new turfs that we couldnt see last update but can now
	var/list/newly_visible_turfs = updated_visible_turfs - visibleTurfs
	///turfs that we could see last update but cant see now
	var/list/newly_obscured_turfs = visibleTurfs - updated_visible_turfs

	for(var/mob/camera/client_eye as anything in seenby)
		var/client/client = client_eye.GetViewerClient()
		if(!client)
			continue

		client.images -= active_static_images

	for(var/turf/visible_turf as anything in newly_visible_turfs)
		var/image/static_image = obscuredTurfs[visible_turf]
		if(!static_image)
			continue

		active_static_images -= static_image
		obscuredTurfs -= visible_turf

	for(var/turf/obscured_turf as anything in newly_obscured_turfs)
		if(obscuredTurfs[obscured_turf] || istype(obscured_turf, /turf/open/ai_visible))
			continue

		var/image/static_image = turfs[obscured_turf]
		if(!static_image)
			stack_trace("somehow a camera chunk used a turf it didn't contain!!")
			break

		obscuredTurfs[obscured_turf] = static_image
		active_static_images += static_image
	visibleTurfs = updated_visible_turfs

	changed = FALSE

	for(var/mob/camera/client_eye as anything in seenby)
		var/client/client = client_eye.GetViewerClient()
		if(!client)
			continue

		client.images += active_static_images

/// Create a new camera chunk, since the chunks are made as they are needed.
/datum/camerachunk/New(x, y, lower_z)
	x = GET_CHUNK_COORD(x)
	y = GET_CHUNK_COORD(y)

	src.x = x
	src.y = y
	src.lower_z = lower_z
	var/turf/upper_turf = get_highest_turf(locate(x, y, lower_z))
	src.upper_z = upper_turf.z

	// Local caches / AABB bounds (tgstation#94530) — avoid urange()
	var/list/cameras = src.cameras
	var/list/turfs = src.turfs
	var/list/visibleTurfs = src.visibleTurfs
	var/list/obscuredTurfs = src.obscuredTurfs
	var/list/active_static_images = src.active_static_images
	var/lower_x = x
	var/lower_y = y
	var/upper_x = min(lower_x + CHUNK_SIZE - 1, world.maxx)
	var/upper_y = min(lower_y + CHUNK_SIZE - 1, world.maxy)

	for(var/z_level in lower_z to upper_z)
		cameras["[z_level]"] = list()

		var/image/mirror_from = GLOB.cameranet.obscured_images[GET_Z_PLANE_OFFSET(z_level) + 1]
		var/turf/chunk_corner = locate(x, y, z_level)
		for(var/turf/lad as anything in CORNER_BLOCK(chunk_corner, CHUNK_SIZE, CHUNK_SIZE)) //we use CHUNK_SIZE for width and height here as it handles subtracting 1 from those two parameters by itself
			var/image/our_image = new /image(mirror_from)
			our_image.loc = lad
			turfs[lad] = our_image

	// Collect cameras that can see into this chunk via AABB (faster than urange)
	for(var/obj/machinery/camera/camera as anything in GLOB.cameranet.cameras)
		if(!camera)
			continue
		var/turf/camera_loc = get_turf(camera)
		if(!camera_loc)
			continue
		if(camera_loc.z < lower_z || camera_loc.z > upper_z)
			continue
		// AABB
		if(camera_loc.x + MAX_CAMERA_RANGE < lower_x || camera_loc.x - MAX_CAMERA_RANGE > upper_x)
			continue
		if(camera_loc.y + MAX_CAMERA_RANGE < lower_y || camera_loc.y - MAX_CAMERA_RANGE > upper_y)
			continue
		if(!camera.can_use())
			continue

		cameras["[camera_loc.z]"] += camera
		for(var/turf/vis_turf as anything in camera.can_see() & turfs)
			visibleTurfs[vis_turf] = vis_turf

	// Also pick up silicon built-in cameras (may or may not be in cameranet.cameras depending on type)
	for(var/mob/living/silicon/sillycone as anything in GLOB.silicon_mobs)
		if(!sillycone.builtInCamera?.can_use())
			continue
		var/turf/camera_loc = get_turf(sillycone)
		if(!camera_loc || camera_loc.z < lower_z || camera_loc.z > upper_z)
			continue
		if(camera_loc.x + MAX_CAMERA_RANGE < lower_x || camera_loc.x - MAX_CAMERA_RANGE > upper_x)
			continue
		if(camera_loc.y + MAX_CAMERA_RANGE < lower_y || camera_loc.y - MAX_CAMERA_RANGE > upper_y)
			continue
		cameras["[camera_loc.z]"] |= sillycone.builtInCamera
		for(var/turf/vis_turf as anything in sillycone.builtInCamera.can_see() & turfs)
			visibleTurfs[vis_turf] = vis_turf

	for(var/turf/obscured_turf as anything in turfs - visibleTurfs)
		var/image/new_static = turfs[obscured_turf]
		active_static_images += new_static
		obscuredTurfs[obscured_turf] = new_static
