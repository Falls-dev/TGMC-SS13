#define TADPOLE_CLOUD_PASS_TIME (3 SECONDS)
#define TADPOLE_GROUND_REVEAL_TIME (2 SECONDS)
#define TADPOLE_ORBIT_BLEND_TIME (3 SECONDS)
#define TADPOLE_ORBIT_PLANET_ANIMATION "tadpole_orbit_planet"
#define TADPOLE_HIGH_ALTITUDE_SCALE 0.86

/// These layers share the ground output plane, above its relay and below the hull.
/// Fullscreen ancestry keeps the viewport's HUD remapping from repositioning them.
/atom/movable/screen/fullscreen/tadpole_transit
	icon = 'icons/effects/parallax.dmi'
	icon_state = "layer1"
	screen_loc = "CENTER:-224,CENTER:-224"
	plane = TADPOLE_GROUND_PLANE
	layer = 2
	appearance_flags = PIXEL_SCALE | TILE_BOUND
	alpha = 0

/atom/movable/screen/fullscreen/tadpole_transit/planet
	icon_state = "planet"
	layer = 3

/atom/movable/screen/fullscreen/tadpole_transit/clouds
	// The cloud texture uses the density pattern from the local space_gas sprite.
	icon = 'icons/effects/tadpole_clouds.dmi'
	icon_state = "clouds"
	layer = 4

/// A shared three-layer sequence. BYOND animates it on each attached client.
/datum/tadpole_transit_animation
	var/obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/helm
	var/list/client/viewers = list()
	/// The native planet and its original plane and transform, keyed by viewer.
	var/list/orbit_planets = list()
	var/list/atom/movable/screen/fullscreen/tadpole_transit/layers
	var/atom/movable/screen/fullscreen/tadpole_transit/stars
	var/atom/movable/screen/fullscreen/tadpole_transit/planet/planet
	var/atom/movable/screen/fullscreen/tadpole_transit/clouds/clouds
	var/returning
	var/revealing_ground = FALSE
	var/blending_into_space = FALSE
	var/phase_started
	var/initial_scale

/datum/tadpole_transit_animation/New(obj/machinery/computer/camera_advanced/shuttle_docker/minidropship/owner, returning_to_ship, ground_scale = 1)
	helm = owner
	returning = returning_to_ship
	initial_scale = ground_scale
	phase_started = world.time
	stars = new
	planet = new
	clouds = new
	layers = list(stars, planet, clouds)
	planet.icon_state = SSmapping.configs[GROUND_MAP]?.parallax_icon || initial(planet.icon_state)
	var/turf/port_turf = get_turf(helm.shuttle_port)
	for(var/atom/movable/screen/fullscreen/tadpole_transit/layer as anything in layers)
		SET_PLANE(layer, TADPOLE_GROUND_PLANE, port_turf)
	stars.transform = matrix().Scale(5)
	var/matrix/cloud_cover = matrix().Scale(3.5)
	clouds.transform = cloud_cover
	planet.transform = matrix().Scale(returning ? 4.2 : 0.9)
	if(!returning)
		stars.alpha = 255
		planet.alpha = 255
	refresh_viewers()
	if(returning)
		var/matrix/ascending = matrix(cloud_cover)
		ascending.Translate(72, -112)
		animate(clouds, alpha = 255, transform = ascending, time = TADPOLE_CLOUD_PASS_TIME, easing = SINE_EASING)
		animate(alpha = 0, transform = cloud_cover, time = 2 SECONDS, easing = SINE_EASING)
		// A newly shown screen object needs a hold keyframe, or Dream Seeker
		// can draw its final appearance before a delayed animation begins.
		animate(stars, alpha = 0, time = TADPOLE_CLOUD_PASS_TIME)
		animate(alpha = 255, time = 0)
		animate(planet, alpha = 0, time = TADPOLE_CLOUD_PASS_TIME)
		animate(alpha = 255, time = 0)
		animate(transform = matrix().Scale(0.9), time = 5 SECONDS, easing = QUAD_EASING | EASE_OUT)
		return
	var/approach_duration = helm.shuttle_port.callTime
	animate(planet, transform = matrix().Scale(4.2), time = approach_duration, easing = QUAD_EASING | EASE_IN)
	clouds.transform = matrix(cloud_cover).Translate(-80, 130)
	animate(clouds, alpha = 0, time = max(0, approach_duration - TADPOLE_CLOUD_PASS_TIME))
	animate(alpha = 255, transform = cloud_cover, time = TADPOLE_CLOUD_PASS_TIME, easing = SINE_EASING)

/datum/tadpole_transit_animation/Destroy()
	if(helm?.transit_animation == src)
		helm.transit_animation = null
	for(var/client/display as anything in viewers)
		remove_viewer(display)
	viewers.Cut()
	orbit_planets.Cut()
	QDEL_LIST(layers)
	stars = null
	planet = null
	clouds = null
	helm = null
	return ..()

/// Refresh only while in this short transition, from the normal shuttle check.
/datum/tadpole_transit_animation/proc/refresh_viewers()
	var/list/aboard = list()
	var/obj/docking_port/mobile/port = helm.shuttle_port
	for(var/mob/viewer as anything in GLOB.player_list)
		var/client/display = viewer.client
		var/turf/eye = get_turf(display?.eye)
		if(eye?.z != port.z || !port.shuttle_areas[get_area(eye)])
			continue
		if(blending_into_space && !(display in viewers))
			continue
		if(orbit_planets[display])
			display.screen |= stars
		else
			display.screen |= layers
		aboard += display
	for(var/client/departed as anything in viewers - aboard)
		remove_viewer(departed)
	viewers = aboard

/datum/tadpole_transit_animation/proc/remove_viewer(client/display)
	if(!display)
		return
	display.screen -= layers
	var/list/original = orbit_planets[display]
	if(!original)
		return
	orbit_planets -= display
	var/atom/movable/screen/parallax_layer/planet/native = original[1]
	if(!QDELETED(native) && native.plane == stars.plane)
		animate(native, tag = TADPOLE_ORBIT_PLANET_ANIMATION)
		native.transform = original[3]
		native.plane = original[2]

/// The normal orbit is now visible below the cinematic. Keep a single planet
/// above the crossfade until it reaches the viewer's own parallax position.
/datum/tadpole_transit_animation/proc/fade_to_space()
	if(blending_into_space)
		return
	refresh_viewers()
	blending_into_space = TRUE
	for(var/client/display as anything in viewers)
		var/atom/movable/screen/parallax_layer/planet/native = locate(/atom/movable/screen/parallax_layer/planet) in display.parallax_layers
		if(QDELETED(native) || !(display.parallax_rock in display.screen) || native.invisibility > display.mob.see_invisible)
			continue
		orbit_planets[display] = list(native, native.plane, native.transform)
		display.screen -= planet
		native.plane = stars.plane
		// Both sprites use the same 480px frame centered on the viewport.
		// Undo the native scroll at the start, then let it carry the planet
		// to the regular orbital position while its scale returns to normal.
		var/matrix/orbit_transform = native.transform
		native.transform = matrix(planet.transform).Translate(-native.pixel_w, -native.pixel_z)
		animate(native, transform = orbit_transform, time = TADPOLE_ORBIT_BLEND_TIME, easing = SINE_EASING, tag = TADPOLE_ORBIT_PLANET_ANIMATION)
	animate(stars, alpha = 0, time = TADPOLE_ORBIT_BLEND_TIME, easing = SINE_EASING)
	// Parallax quality settings can omit the native planet.
	animate(planet, alpha = 0, time = TADPOLE_ORBIT_BLEND_TIME, easing = SINE_EASING)
	QDEL_IN(src, TADPOLE_ORBIT_BLEND_TIME + 0.2 SECONDS)

/// Begin revealing the real map only once the shuttle arrives in atmosphere.
/datum/tadpole_transit_animation/proc/reveal_ground()
	revealing_ground = TRUE
	phase_started = world.time
	stars.alpha = 0
	animate(planet)
	planet.alpha = 0
	animate(clouds)
	clouds.alpha = 255
	var/matrix/descending = matrix(clouds.transform)
	descending.Translate(-48, 90)
	animate(clouds, alpha = 0, transform = descending, time = TADPOLE_GROUND_REVEAL_TIME, easing = QUAD_EASING | EASE_IN)
	QDEL_IN(src, TADPOLE_GROUND_REVEAL_TIME)

/// Zoom the composed map around the hull, using the existing flight matrix.
/datum/tadpole_transit_animation/proc/ground_scale(at_time = world.time)
	var/elapsed = max(0, at_time - phase_started)
	if(returning)
		return LERP(initial_scale, TADPOLE_HIGH_ALTITUDE_SCALE, clamp(elapsed / TADPOLE_CLOUD_PASS_TIME, 0, 1))
	if(revealing_ground)
		return LERP(TADPOLE_HIGH_ALTITUDE_SCALE, 1, clamp(elapsed / TADPOLE_GROUND_REVEAL_TIME, 0, 1))
	return 1

#undef TADPOLE_CLOUD_PASS_TIME
#undef TADPOLE_GROUND_REVEAL_TIME
#undef TADPOLE_ORBIT_BLEND_TIME
#undef TADPOLE_ORBIT_PLANET_ANIMATION
#undef TADPOLE_HIGH_ALTITUDE_SCALE
