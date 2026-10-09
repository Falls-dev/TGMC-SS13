/// Where the wearer is pointing, and the ghost that shows it.
///
/// TGMC has no mouse position at all - the build never sees the cursor, so nothing can be aimed
/// by pointing. The only channel the game offers is /client/MouseMove, and that arrives as a
/// client verb, which means every twitch of the mouse spends a slot in the server's per-tick verb
/// budget for that player. Measured with nobody else on the server this costs nothing visible:
/// the early out means a cursor that has not crossed into a new tile does no work at all.
///
/// Three things here were wrong before and are load bearing now.
///
/// The gate. One istype for every player in the game, and nearly all of them leave immediately.
/// Until a client has spawned, its mob is a /mob/new_player, which inherits /mob directly and has
/// no gloves field, so touching .gloves on it throws once per mouse move.
///
/// The ghost must outlive the mouse event. Creating one on the move and deleting it on the next
/// one looks correct and renders nothing: QDEL is deferred to the end of the frame, so the client
/// gets a creation and a deletion inside a single update and never draws the thing. The first
/// version logged 47 ghosts built and not one appeared on screen. The ghost here is therefore
/// persistent while the field is aiming, and is moved with forceMove instead of being rebuilt.
///
/// The preview is rebuilt only when the object under the cursor actually changes, because a
/// mutable_appearance is baked at creation and forceMoving it somewhere else would leave it
/// showing the previous object - which reads as the field previewing the wrong thing.
///
/// Not implemented, and it needs its own tick: sweeping the ghost along the path a cursor crossed
/// rather than jumping to the end of it. That is what the aim_queue was for. It cannot be done
/// from the mouse event, and /datum/proc/process() is already defined in
/// code/controllers/subsystem/processing/processing.dm, so a per-tick walk needs either a
/// processing component or a repeating timer. Queued, not attempted.

///Amber, and deliberately unlike the hold graphic's indigo. See /obj/effect/kinesis_aim_ghost.
#define KINESIS_PREVIEW_COLOR "#ffa63d"

///Cursor tracking, and the one thing in this branch that reaches outside kinesis: /client/MouseMove
///fires for every player in the game on every mouse movement, over the login window included.
///Six "usr.client is null" errors then appeared inside /mob/Login and took the whole session with
///them - black screen, no vision - and not one of those stack traces names a kinesis file, which
///leaves this override as the only thing of mine that could have been running at that moment.
///
///That is a suspicion, not a finding, and the logs cannot settle it. FALSE right now so that one
///re-login is a real answer: if the errors come back anyway they are not ours and this goes to TRUE
///immediately. Nothing else in this branch has any way to reach a client.
#define KINESIS_MOUSE_TRACKING TRUE

///When this client last had a mouse movement acted on, so the ones in between can be dropped.
///One decisecond is one tick, which is also how often the game actually shows anything, so
///throttling to it costs nothing visible and removes the bulk of the per-event work.
var/next_aim_handled = 0

/client/MouseMove(atom/object, location, control, params)
	#if KINESIS_MOUSE_TRACKING
	//Throttled to one handling per decisecond, and that is the whole point of it. MouseMove fires
	//several dozen times a second while the game only redraws ten times, so every event past the
	//first in a decisecond was parsing the parameter string three times, allocating lists, doing a
	//world locate and re-seating the tether - all for a frame nobody ever sees. Smooth movement still
	//stuttered because the cost was never the collision check, it was the sheer rate.
	if(world.time < next_aim_handled)
		return
	next_aim_handled = world.time + 1
	if(!istype(mob, /mob/living/carbon/human))
		return
	var/mob/living/carbon/human/wearer = mob
	//Most players wear no gauntlets. This pair of reads is the common case for everyone.
	var/obj/item/clothing/gloves/kinesis/ds13/gauntlets = wearer.gloves
	if(!istype(gauntlets))
		return
	var/datum/kinesis_field/field = gauntlets.field
	if(!field?.wants_aim())
		return
	field.note_mouse(params)
	#endif

///Whether the field is in a state where pointing means anything.
/datum/kinesis_field/proc/wants_aim()
	return marking || state == KINESIS_HELD

///The DS13 tether, on TGMC's own beam.
///
///DS13 draws it with /obj/effect/projectile/tether, which stretches a 128x64 sprite through a
///transform and keeps both ends in absolute world pixels. None of that exists here: TGMC has no
///vector2, no Atan2, no set_global_pixel_loc and no get_toplevel_global_pixel_loc, so porting it
///means writing all of it. TGMC already ships /datum/beam, which lays 32 pixel chunks along the
///line, rotates them and crops the end at the target, and redraws itself when either end moves.
///
///The DS13 sprite is deliberately not copied: it is a single 128x64 image meant to be stretched,
///while beam.dm steps in fixed 32 pixel tiles, so it would render as garbage. What is ported is
///the look - the same lightning tether, from the icons this codebase already has in use for
///zap_beam. That is lightning1 to lightning12 in icons/effects/beam.dmi.
///
///The cursor is not an atom, and /datum/beam needs two atoms, so the pointer gets an invisible one
///to be the far end of the tether. It is a real atom purely so the beam has something to point at.
///Whether the player is arming or already holding decides which end is the cursor and which is
///the carried object.
/datum/kinesis_field/proc/update_tether()
	//The beam only means something while something is actually being held. It used to also run to
	//the cursor while the marker was merely armed, and that read as a second object being carried
	//- two things outlined at once with nothing grabbed. Arming is a state, holding is the state
	//that deserves a tether.
	if(state != KINESIS_HELD)
		hide_preview()
		clear_tether()
		return
	//Standing still with something held left the amber preview outlined on whatever the cursor had
	//been over before the grab, because show_preview only reacts to the cursor changing tile and the
	//cursor had not moved since. It highlighted an object the player was plainly not about to take,
	//and moving the mouse cleared it, which is why it looked fine in motion. Nothing is being aimed
	//at while something is already held, so the preview is off entirely in that state.
	hide_preview()
	if(isnull(holo))
		clear_tether()
		return
	point_tether(user, holo)

/datum/kinesis_field/proc/point_tether(atom/near_end, atom/far_end)
	if(QDELETED(near_end) || QDELETED(far_end))
		clear_tether()
		return
	if(tether?.origin == near_end && tether?.target == far_end)
		return
	clear_tether()
	//kinesis_line was added to icons/effects/beam.dmi for this, so it lives in the same dmi as every
	//other beam in the codebase and needs nothing wired into the build.
	tether = near_end.beam(far_end, icon_state = "kinesis_line", maxdistance = drop_range + 2)

/datum/kinesis_field/proc/clear_tether()
	if(!isnull(tether))
		qdel(tether)
	tether = null

///Kept where the cursor is, so the beam has a far end and so the throw has something to aim at
///even before anything is picked up.
/obj/effect/kinesis_aim_anchor
	name = "kinesis aim point"
	icon = null
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	density = FALSE
	anchored = TRUE
	layer = ABOVE_ALL_MOB_LAYER

/datum/kinesis_field/proc/seat_aim_anchor()
	if(isnull(aim_anchor))
		aim_anchor = new
	var/turf/aim_tile = aimed
	if(!isturf(aim_tile))
		aim_tile = get_turf(user)
	if(!isturf(aim_tile))
		return
	if(aim_anchor.loc != aim_tile)
		aim_anchor.forceMove(aim_tile)
	if(aim_pixel && length(aim_pixel) == 2)
		aim_anchor.pixel_x = clamp(aim_pixel[1], -tile_pixels / 2, tile_pixels / 2)
		aim_anchor.pixel_y = clamp(aim_pixel[2], -tile_pixels / 2, tile_pixels / 2)

///Records where the cursor is and parks the preview on it.
/datum/kinesis_field/proc/note_mouse(params)
	var/list/parsed = params2list(params)
	var/turf/pointed = params2turf(parsed["screen-loc"], get_turf(user?.client?.eye), user?.client)
	if(isnull(pointed))
		return
	if(pointed.z != user.z)
		return
	//Recorded every event, not only on a tile change. The cursor is usually parked inside one
	//tile while the throw direction still needs to follow it, so gating this on a tile change
	//would freeze the aim for as long as the pointer does not move far enough to leave the cell.
	//This is also why aimed is assigned above the early out: throw_turf and update_holo read it,
	//and both have to keep working while the pointer sits still inside one tile.
	aimed = pointed
	//Where the cursor sits inside the tile it is over, centred, so -16 to 16. Deliberately NOT
	//params2screenpixel: that returns pixels counted from the middle of the client's view, because
	//params2turf has to add origin.x and subtract half the view size to turn one into a tile.
	//Feeding its result straight into a world coordinate mixes two origins, and the object walked
	//off in an arbitrary direction as soon as the view was not centred on the wearer.
	//The second number of each pair in screen-loc is the pixel within the cell, which is what is
	//wanted here and does not depend on the view at all.
	var/list/raw = splittext(parsed["screen-loc"], ",")
	if(length(raw) == 2)
		var/list/x_pair = splittext(raw[1], ":")
		var/list/y_pair = splittext(raw[2], ":")
		if(length(x_pair) == 2 && length(y_pair) == 2)
			aim_pixel = list(text2num(x_pair[2]) - tile_pixels / 2, text2num(y_pair[2]) - tile_pixels / 2)
	//Re-seats the held graphic on every mouse event, not only when the cursor changes tile. It used
	//to sit below the early out, which meant a pointer resting inside one tile never moved the
	//graphic at all - so it snapped tile to tile instead of gliding around the wearer. Sub-tile
	//movement is the whole point of reading pixels rather than tiles.
	if(state == KINESIS_HELD)
		update_holo()
	seat_aim_anchor()
	update_tether()
	if(pointed == last_aimed)
		return
	last_aimed = pointed
	//Capped: a mouse sweep makes hundreds of tile changes a second and the point of this is to
	show_preview(pointed)

///Puts the preview on a tile, rebuilding it only when the object under the cursor is a different
///one. forceMove alone would leave it drawing the previous object, since the appearance is baked
///at construction.
/datum/kinesis_field/proc/show_preview(turf/where)
	//Everything below builds the preview with TWO arguments, always. /atom/New(loc, ...) in
	//code/game/atoms/_atom.dm:359 overwrites args[1] with the mapload flag, so a single argument is
	//silently destroyed before Initialize ever sees it. That is why the preview kept being built
	//with nothing to draw - 23 times in one round - while the hold graphic, which passes two, was
	//fine. Any atom built from this file needs a spare first argument.
	var/atom/movable/would_be = grabbable_on(where)
	if(isnull(would_be))
		hide_preview()
		return
	if(isnull(aim_ghost))
		//Diagnostic. If aim_ghost_of is still set here, the ghost existed and something nulled the
		//variable without going through clear_preview - which means the atom itself was deleted
		//and DM nulled every reference to it. If it is null too, this is a brand new field, i.e.
		//the whole datum is being destroyed and rebuilt on every mouse event.
		aim_ghost = new /obj/effect/kinesis_aim_ghost(where, would_be)
		aim_ghost_of = would_be
		return
	if(aim_ghost_of != would_be)
		//Same trap as above: the appearance is baked at construction, so a different object needs
		//a different ghost. Built first, deleted after, never in the other order.
		QDEL_NULL(aim_ghost)
		aim_ghost = new /obj/effect/kinesis_aim_ghost(where, would_be)
		aim_ghost_of = would_be
		return
	if(aim_ghost.loc != where)
		aim_ghost.forceMove(where)
	if(aim_ghost.alpha != 255)
		aim_ghost.alpha = 255

///Hides the preview instead of deleting it.
///
///Deleting here was the second half of why nothing ever appeared. The cursor sweeps across bare
///floor constantly, and every sweep onto empty floor deleted the ghost and every sweep back onto
///an object rebuilt it. Mouse events arrive several per tick, so the whole cycle played out inside
///one frame: QDEL is deferred to the end of the frame, so the client was told to create and delete
///the same thing before it ever drew it. The logs showed a ghost built dozens of times and no
///amber on screen. Alpha keeps the object alive across frames, which is the whole requirement.
/datum/kinesis_field/proc/hide_preview()
	if(!isnull(aim_ghost) && aim_ghost.alpha)
		aim_ghost.alpha = 0

///The first unanchored movable on a tile that the field would actually accept.
/datum/kinesis_field/proc/grabbable_on(turf/where)
	if(!isturf(where))
		return null
	for(var/obj/thing in where)
		if(!istype(thing, /atom/movable) || thing.anchored)
			continue
		if(istype(thing, /obj/effect) || istype(thing, /obj/item/clothing/gloves/kinesis))
			continue
		if(thing == user)
			continue
		//The object already in the grip. It is a real atom on a real tile now, so the cursor passing
		//over the wearer picks it up as just another thing on the floor - which is what made the
		//highlight flicker between showing it and going blank, and it cannot be grabbed anyway.
		if(thing == subject || thing == holo?.stored)
			continue
		return thing
	return null

/datum/kinesis_field/proc/clear_preview()
	QDEL_NULL(aim_ghost)
	aim_ghost_of = null

///Called when the field stops aiming, so the preview does not hang around over the map.
/datum/kinesis_field/proc/drop_preview()
	last_aimed = null
	clear_preview()


///Deliberately a different colour from the hold graphic's indigo. The two are on screen at the
///same time while something is held, and when they looked identical the hold graphic - which by
///design floats one tile ahead of where the wearer is facing - was read as the mouse preview
///following the gaze. Different colour, different alpha, so the two can never be confused.
///The preview.
///
///Copied from /obj/effect/temp_visual/after_image in
///code/game/objects/effects/temporary_visuals/miscellaneous.dm, which is TGMC's own working way
///to draw a copy of another atom. The three details that matter, all of which I had wrong:
///
///  - the appearance is created EMPTY and the atom's appearance is assigned to it. Passing the
///    atom to new() as I did, `new /mutable_appearance(previewed)`, produces an empty appearance
///    and the effect has nothing at all to draw, which is exactly what happened.
///  - it goes on the atom's `appearance` var, not into `overlays`.
///  - RESET_COLOR|RESET_ALPHA makes the copy take its colours from the filter rather than being
///    tinted, and PASS_MOUSE stops the preview eating clicks meant for the real object.
///
///Plane and layer also come off: ABOVE_HUD_PLANE was never a tested choice, and an after_image
///that is never seen is not worth debugging around.
/obj/effect/kinesis_aim_ghost
	name = "telekinetic preview"
	icon = null
	layer = ABOVE_ALL_MOB_LAYER
	alpha = 160
	var/mutable_appearance/shown

/obj/effect/kinesis_aim_ghost/Initialize(mapload, atom/movable/previewed)
	. = ..()
	//The second argument arrived null once in a while - the stack showed Initialize(0, null) with
	//src.loc already on the previewed item, so the atom existed but lost its argument somewhere in
	//new() -> /atom/New(loc, ...) -> InitAtom -> Initialize (code/game/atoms/_atom.dm:359). Rather
	//than keep guessing at the source, this refuses to build a broken appearance and says so.
	if(isnull(previewed))
		return
	var/mutable_appearance/copy = new()
	copy.appearance = previewed.appearance
	copy.appearance_flags = RESET_COLOR | RESET_ALPHA | PASS_MOUSE
	copy.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	copy.setDir(previewed.dir)
	copy.layer = layer
	shown = copy
	//Same reasoning as the hold graphic, and for the same reason it was needed there: the object is
	//hidden with alpha 0 while carried, and a copy taken from something invisible arrives invisible
	//too. This is what made the highlight appear and vanish as the cursor crossed between a visible
	//item and one already being held - RESET_ALPHA does not rescue it, the source has nothing left.
	copy.alpha = 255
	copy.filters += filter(type = "outline", size = 2, color = KINESIS_PREVIEW_COLOR, alpha = 220)
	appearance = copy
