///Visible effect for the held object.

#define KINESIS_COLOR "#4d59db"

/datum/looping_sound/kinesis_hold
	mid_sounds = list('sound/effects/telekinesis/kinesis_hold.ogg')
	mid_length = 3 SECONDS
	volume = 30
	range = 5

/obj/effect/kinesis_holo
	name = "telekinetic hold"
	desc = "A telekinetic field holding something in place."
	icon = null
	layer = ABOVE_ALL_MOB_LAYER
	alpha = 160
	///Held atom; objects stay on the map, while mobs are parked until release.
	var/atom/movable/stored

	///Original appearance and collision values to restore on release.
	var/stored_alpha
	var/stored_density

	///Whether anchoring must be restored on release.
	var/stored_anchored = FALSE

	///Appearance used by decorate().
	var/mutable_appearance/shown

/obj/effect/kinesis_holo/Initialize(mapload, atom/movable/_stored)
	. = ..()
	stored = _stored
	if(isnull(stored))
		return
	//Keep objects on the map so projectiles, interactions and explosions still reach them.
	if(istype(stored, /obj))
		stored_alpha = stored.alpha
		stored_density = stored.density
		stored.alpha = 0
		//Structures retain collision while carried; items do not.
		if(istype(stored, /obj/item))
			stored.density = FALSE
	var/atom/movable/parked = stored
	if(!isnull(parked) && parked.anchored)
		stored_anchored = TRUE
		parked.anchored = FALSE
	make_appearance()

///Keep the object's collision and interactions aligned with its visible effect.
/obj/effect/kinesis_holo/proc/carry_to(turf/where)
	if(isnull(stored) || !isturf(where))
		return
	if(!istype(stored, /obj))
		return
	if(stored.loc != where)
		stored.forceMove(where)
	stored.pixel_x = pixel_x
	stored.pixel_y = pixel_y

///Restore the held atom and clear its reference before deleting the effect.
/obj/effect/kinesis_holo/proc/hand_back(turf/where)
	if(isnull(stored))
		return
	//Mobs have no saved alpha or density.
	if(!isnull(stored_alpha))
		stored.alpha = stored_alpha
	if(!isnull(stored_density))
		stored.density = stored_density
	if(stored_anchored)
		var/atom/movable/standing = stored
		if(!isnull(standing))
			standing.anchored = TRUE
	stored.pixel_x = 0
	stored.pixel_y = 0
	//Return parked mobs; objects are already on the map.
	if(!istype(stored, /obj) && !isturf(stored.loc) && isturf(where))
		stored.forceMove(where)
	stored = null

/obj/effect/kinesis_holo/proc/make_appearance()
	if(isnull(stored))
		return
	var/mutable_appearance/copy = new()
	copy.appearance = stored.appearance
	copy.appearance_flags = RESET_COLOR | RESET_ALPHA | PASS_MOUSE
	copy.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	copy.setDir(stored.dir)
	copy.layer = layer
	//The source object may already be hidden.
	copy.alpha = 255
	shown = copy
	decorate()
	appearance = copy

/obj/effect/kinesis_holo/proc/decorate()
	if(isnull(shown))
		return
	shown.filters += filter(type = "outline", size = 3, color = "[KINESIS_COLOR]A0")

/obj/effect/kinesis_holo/Destroy(override = TRUE, ...)
	//Deleting the effect must not delete or leave its subject hidden.
	if(!isnull(stored))
		hand_back(get_turf(src))
	return ..()
