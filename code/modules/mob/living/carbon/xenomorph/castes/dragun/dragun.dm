/mob/living/carbon/xenomorph/dragun
	caste_base_type = /datum/xeno_caste/dragun
	name = "Dragun"
	desc = "A powerful xenomorph with a heavy frame and a threatening silhouette."
	icon = 'icons/Xeno/castes/dragun/basic.dmi'
	icon_state = "Dragun Walking"
	effects_icon = 'icons/Xeno/castes/dragun/effeects.dmi'
	bubble_icon = "alienroyal"
	health = 450
	maxHealth = 450
	plasma_stored = 250
	pixel_x = -16
	tier = XENO_TIER_THREE
	upgrade = XENO_UPGRADE_NORMAL
	drag_delay = 5
	mob_size = MOB_SIZE_BIG
	/// The weapon is part of this body and is deleted along with it.
	var/obj/item/weapon/gun/dragun/hand_dragun
	/// Keep the bite animation visible for the duration of its hold.
	var/biting = FALSE

/mob/living/carbon/xenomorph/dragun/Initialize(mapload, do_not_set_as_ruler)
	. = ..()
	hand_dragun = new(src)
	put_in_active_hand(hand_dragun)

/mob/living/carbon/xenomorph/dragun/Destroy()
	QDEL_NULL(hand_dragun)
	return ..()

/mob/living/carbon/xenomorph/dragun/handle_special_state()
	if(biting)
		icon_state = "Dragun bite"
		return TRUE
	if(hand_dragun?.item_flags & WIELDED)
		icon_state = "Dragun Up Gun"
		return TRUE
	return ..()

/mob/living/carbon/xenomorph/dragun/handle_special_wound_states(health_thresholds)
	return "wounded_[health_thresholds]"

/mob/living/carbon/xenomorph/dragun/primordial
	upgrade = XENO_UPGRADE_PRIMO

// The supplied sprite uses "Dragun run" while the shared xeno icon updater
// requests "Dragun Running" for the run movement intent.
/mob/living/carbon/xenomorph/dragun/update_icons(state_change = TRUE)
	. = ..()
	if(state_change && icon_state == "Dragun Running")
		icon_state = "Dragun run"
