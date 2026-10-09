///The graphic that stands in for a held object, standing in for /datum/extension/kinesis_gripped
///in DS13.
///
/// DS13 does this client side on the real object: an indigo outline, a pulsing ripple filter,
///half alpha, a slight upscale and a plane above the humans. Here the real object is parked out
///of the world and this exists in its place, so all of that is built on an effect rather than
///applied to something already on the map.

#define KINESIS_COLOR "#4d59db"

///The hum of a field holding something, from DS13's kinesis_hold. A concrete subclass is required
///because the base /datum/looping_sound declares no sounds and warns when built bare.
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
	///The real object, parked out of the world while the graphic stands for it.
	var/atom/movable/stored

	///Alpha and density as they were before the field hid them, so putting the object back
	///restores it exactly rather than guessing at initial().
	var/stored_alpha
	var/stored_density

	///Whether it was bolted down before the field took it, so a crate can be bolted again when set down
	///rather than left lying on the floor as though it had fallen over.
	var/stored_anchored = FALSE

	///The appearance being drawn, kept so decorate can add a filter afterwards.
	var/mutable_appearance/shown
/obj/effect/kinesis_holo/Initialize(mapload, atom/movable/_stored)
	. = ..()
	stored = _stored
	if(isnull(stored))
		return
	//The object is kept in the world. Parking it out with loc = null made it inert: a grenade still
	//ran its arm timer, then had nothing to detonate on, failed silently and disappeared - which
	//is the exact report this replaces. Leaving it a real atom on a real turf means grenades go off,
	//doors open, and a laser or a bullet can knock it out of the wearer's hand.
	//
	//Invisible, but not gone: alpha 0 only affects drawing. Ballistics and beams go by coordinates,
	//so they still hit it, which is the behaviour worth having - being shot is a way to lose grip.
	//A person or a crate is not an item and cannot be hidden with alpha - a mob carries a HUD, a name
	//and a health readout, and an invisible one standing in the middle of a corridor is a problem
	//rather than a feature. Those are parked out of the world and represented only by the graphic,
//which is what this did for everything before the reserve of charge came along and made them
	//real atoms again.
	if(istype(stored, /obj/item))
		stored_alpha = stored.alpha
		stored_density = stored.density
		stored.alpha = 0
		//Invisible and solid is the worst combination there is: a thing you cannot see blocking a
		//doorway. It stops blocking while held and takes its real density back when put down.
		stored.density = FALSE
	//Recorded and cleared whatever it is, not just for items: a crate is anchored to the floor and
	//has to be unbolted before it can be moved at all, and putting it down has to put it back.
	var/atom/movable/parked = stored
	if(!isnull(parked) && parked.anchored)
		stored_anchored = TRUE
		parked.anchored = FALSE
	make_appearance()

///Keeps the held object on the graphic's own tile, so the real atom and the picture the player sees
///never disagree. Without this the object would sit wherever it was grabbed while the graphic
///follows the cursor, and a laser would hit thin air where the player is looking.
/obj/effect/kinesis_holo/proc/carry_to(turf/where)
	if(isnull(stored) || !isturf(where))
		return
	if(stored.loc != where)
		stored.forceMove(where)
	//Same sub-tile offset as the graphic, deliberately. The beam is drawn to this atom's
	//coordinates, so while the object sat on the tile centre and the graphic floated up to half a
	//tile towards the cursor, the tether pointed somewhere between the two and appeared to lag
	//behind what it was attached to.
	stored.pixel_x = pixel_x
	stored.pixel_y = pixel_y

///Puts the object back the way it was found. Called before the graphic goes away, because Destroy
///sees a nulled reference and deliberately leaves the object alone.
/obj/effect/kinesis_holo/proc/hand_back(turf/where)
	if(isnull(stored))
		return
	stored.alpha = stored_alpha
	stored.density = stored_density
	//Bolted back down, because a crate that came off its bolts has to go back on them when the field
	//lets go. Anything that was not anchored to begin with is untouched by this.
	if(stored_anchored)
		var/atom/movable/standing = stored
		if(!isnull(standing))
			standing.anchored = TRUE
	stored.pixel_x = 0
	stored.pixel_y = 0
	//A parked non-item has no alpha to restore, so it goes back into the world where it came from.
	if(!isturf(stored.loc) && isturf(where))
		stored.forceMove(where)
	stored = null

///Builds the visible copy. Same three details as the preview in aim.dm, and for the same reasons:
///the appearance is created empty and the atom's appearance assigned onto it, and it goes on
///`appearance` rather than `overlays`. Passing the atom to new() - which is what the first version
///did - yields an empty appearance, so the graphic had nothing to draw.
/obj/effect/kinesis_holo/proc/make_appearance()
	if(isnull(stored))
		return
	var/mutable_appearance/copy = new()
	copy.appearance = stored.appearance
	copy.appearance_flags = RESET_COLOR | RESET_ALPHA | PASS_MOUSE
	copy.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	copy.setDir(stored.dir)
	copy.layer = layer
	//Set outright, not inherited. Now that the object itself is hidden with alpha 0 the copy can
	//arrive invisible too, which is how a picked up item ended up with nothing standing in for it -
	//the object was gone from sight and so was the graphic.
	copy.alpha = 255
	shown = copy
	decorate()
	appearance = copy

///The DS13 look: an indigo outline plus a slight upscale.
///
///The pulsing ripple DS13 uses was here and has been taken out. An animate() on a filter costs
///a per-tick update for every client for as long as it loops, and with loop = -1 that is forever:
///grabbing one object pushed the server to 143% tick usage and threw "Cannot animate abstract
///filter" every time, because a filter built inline and kept in a local var is abstract and BYOND
///will not animate it. To animate filters this codebase adds them by name and reads them back
///with get_filter() - see code/__HELPERS/filters.dm:309. Neither the exception nor the cost is
///worth a decorative pulse, so the outline is static.
/obj/effect/kinesis_holo/proc/decorate()
	if(isnull(shown))
		return
	shown.filters += filter(type = "outline", size = 3, color = KINESIS_COLOR, alpha = 160)

/obj/effect/kinesis_holo/Destroy(override = TRUE, ...)
	//Hand the object back rather than deleting it, so switching the field off mid-hold does not
	//annihilate whatever was in it. Restore goes through hand_back so the object also gets its real
	//alpha and density, not just a place to stand.
	if(!isnull(stored))
		hand_back(get_turf(src))
	return ..()
