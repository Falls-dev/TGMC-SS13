/// Back-slot safety gear for transit falls, including free-flight Tadpole exits.
/obj/item/parachute
	name = "parachute pack"
	desc = "An automatic parachute. Wear it on your back before leaving an aircraft. After landing, use it in hand to repack the canopy."
	icon = 'icons/obj/items/parachute.dmi'
	icon_state = "parachute"
	worn_icon_state = "parachute"
	worn_icon_list = list(
		slot_back_str = 'icons/mob/clothing/parachute.dmi',
		slot_l_hand_str = 'icons/mob/inhands/equipment/parachute_left.dmi',
		slot_r_hand_str = 'icons/mob/inhands/equipment/parachute_right.dmi',
	)
	equip_slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	var/used = FALSE
	var/mob/living/carbon/human/descending_wearer
	var/atom/movable/vis_obj/fulton_balloon/canopy
	var/original_pixel_z

/obj/item/parachute/Destroy()
	finish_descent()
	return ..()

/obj/item/parachute/examine(mob/user)
	. = ..()
	. += used ? "The canopy needs repacking before another jump." : "The canopy is packed and ready."

/obj/item/parachute/attack_self(mob/user)
	if(!used || descending_wearer || !user.is_holding(src))
		return
	to_chat(user, span_notice("You begin repacking [src]."))
	if(!do_after(user, 5 SECONDS, NONE, src) || descending_wearer || !used || !user.is_holding(src))
		return
	used = FALSE
	to_chat(user, span_notice("You finish repacking [src]."))

/// Return TRUE only when this fall is handled by a worn, packed parachute.
/obj/item/parachute/proc/deploy(mob/living/carbon/human/jumper, turf/target)
	if(descending_wearer == jumper)
		return TRUE
	if(used || descending_wearer || jumper.back != src || loc != jumper || !isturf(jumper.loc) || !istype(target, /turf/open) || isspaceturf(target))
		return FALSE
	used = TRUE
	descending_wearer = jumper
	original_pixel_z = jumper.pixel_z
	ADD_TRAIT(jumper, TRAIT_IMMOBILE, REF(src))
	ADD_TRAIT(src, TRAIT_NODROP, REF(src))
	canopy = new
	canopy.icon_state = "fulton_balloon"
	// The canopy is a nullspace visual. Follow the wearer's plane across the drop.
	canopy.vis_flags |= VIS_INHERIT_PLANE
	canopy.appearance_flags |= KEEP_APART
	canopy.layer = ABOVE_MOB_LAYER
	jumper.vis_contents += canopy
	flick("fulton_expand", canopy)
	jumper.pixel_z = 360
	jumper.forceMove(target)
	jumper.remove_status_effect(/datum/status_effect/spacefreeze)
	playsound(jumper, 'sound/items/fultext_deploy.ogg', 50, TRUE)
	jumper.visible_message(span_notice("[jumper]'s parachute opens!"), span_notice("Your parachute opens, slowing your fall."))
	animate(jumper, pixel_z = original_pixel_z, time = 3 SECONDS, tag = "parachute-[REF(src)]")
	sleep(3 SECONDS)
	if(!QDELETED(src))
		finish_descent()
	return TRUE

/// Remove only this pack's effects, including if it is deleted mid-descent.
/obj/item/parachute/proc/finish_descent()
	if(descending_wearer && !QDELETED(descending_wearer))
		animate(descending_wearer, tag = "parachute-[REF(src)]")
		descending_wearer.vis_contents -= canopy
		REMOVE_TRAIT(descending_wearer, TRAIT_IMMOBILE, REF(src))
		descending_wearer.pixel_z = original_pixel_z
	descending_wearer = null
	REMOVE_TRAIT(src, TRAIT_NODROP, REF(src))
	QDEL_NULL(canopy)
