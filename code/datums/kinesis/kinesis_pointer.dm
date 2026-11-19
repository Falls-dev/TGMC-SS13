///Cursor tracking and target preview for TK-5.
#define KINESIS_PREVIEW_COLOR "#ffa63d"

#define KINESIS_MOUSE_TRACKING TRUE

///Next allowed cursor update, in deciseconds.
/client/var/next_aim_handled = 0

/client/MouseMove(atom/object, location, control, params)
	#if KINESIS_MOUSE_TRACKING
	//Limit cursor processing to ten updates per second.
	if(world.time < next_aim_handled)
		return
	next_aim_handled = world.time + 1
	if(!istype(mob, /mob/living/carbon/human))
		return
	var/mob/living/carbon/human/wearer = mob
	var/obj/item/clothing/gloves/kinesis/ds13/gauntlets = wearer.gloves
	if(!istype(gauntlets))
		return
	var/datum/kinesis_field/field = gauntlets.field
	if(!field?.wants_aim())
		return
	field.note_mouse(params)
	#endif

/datum/kinesis_field/proc/wants_aim()
	return marking || state == KINESIS_HELD

/datum/kinesis_field/proc/update_tether()
	//The beam connects the wearer to the held effect, not the target preview.
	if(state != KINESIS_HELD)
		hide_preview()
		clear_tether()
		return
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
	tether = near_end.beam(far_end, icon_state = "kinesis_line", maxdistance = drop_range + 2)

/datum/kinesis_field/proc/clear_tether()
	QDEL_NULL(tether)

///Records where the cursor is and parks the preview on it.
/datum/kinesis_field/proc/note_mouse(params)
	var/list/parsed = params2list(params)
	var/turf/pointed = params2turf(parsed["screen-loc"], get_turf(user?.client?.eye), user?.client)
	if(isnull(pointed))
		return
	if(pointed.z != user.z)
		return
	aimed = pointed
	if(state == KINESIS_HELD)
		update_holo()
	update_tether()
	//Only target selection needs a preview.
	if(!marking)
		return
	if(pointed == last_aimed)
		return
	last_aimed = pointed
	show_preview(pointed)

///Rebuild the preview only when its subject changes.
/datum/kinesis_field/proc/show_preview(turf/where)
	var/atom/movable/would_be = grabbable_on(where)
	if(isnull(would_be))
		hide_preview()
		return
	if(isnull(aim_ghost) || aim_ghost_of != would_be)
		QDEL_NULL(aim_ghost)
		aim_ghost = new /obj/effect/kinesis_aim_ghost(where, would_be)
		aim_ghost_of = would_be
		return
	if(aim_ghost.loc != where)
		aim_ghost.forceMove(where)
	if(aim_ghost.alpha != 255)
		aim_ghost.alpha = 255

///Keep the preview alive across mouse events to avoid create/delete flicker.
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
		//Do not preview the held object.
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

///Amber target preview, distinct from the indigo hold effect.
/obj/effect/kinesis_aim_ghost
	name = "telekinetic preview"
	icon = null
	layer = ABOVE_ALL_MOB_LAYER
	alpha = 160
	var/mutable_appearance/shown

/obj/effect/kinesis_aim_ghost/Initialize(mapload, atom/movable/previewed)
	. = ..()
	if(isnull(previewed))
		return
	var/mutable_appearance/copy = new()
	copy.appearance = previewed.appearance
	copy.appearance_flags = RESET_COLOR | RESET_ALPHA | PASS_MOUSE
	copy.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	copy.setDir(previewed.dir)
	copy.layer = layer
	shown = copy
	//The source object may be hidden.
	copy.alpha = 255
	copy.filters += filter(type = "outline", size = 2, color = "[KINESIS_PREVIEW_COLOR]DC")
	appearance = copy
