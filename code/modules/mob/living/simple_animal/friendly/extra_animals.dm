/mob/living/simple_animal/pig
	name = "pig"
	desc = "A stocky mammal with a flat snout. Oink. Drag yourself onto it to ride."
	icon = 'icons/mob/animal.dmi'
	icon_state = "pig"
	icon_living = "pig"
	icon_dead = "pig_dead"
	buckle_flags = CAN_BUCKLE|BUCKLE_PREVENTS_PULL
	max_buckled_mobs = 1
	buckle_lying = -1
	speak = list("Oink.", "Oink?", "Oink!")
	speak_emote = list("oinks")
	emote_hear = list("oinks.")
	emote_see = list("snuffles around.", "wiggles its snout.")
	speak_chance = 2
	turns_per_move = 5
	response_help = "pets"
	response_disarm = "gently pushes aside"
	response_harm = "kicks"
	attacktext = "bites"
	health = 40
	maxHealth = 40
	melee_damage = 2
	mob_size = MOB_SIZE_SMALL
	stop_automated_movement_when_pulled = TRUE

/mob/living/simple_animal/pig/Initialize(mapload)
	. = ..()
	if(!istype(src, /mob/living/simple_animal/pig/mini))
		AddElement(/datum/element/ridable, /datum/component/riding/creature/pig)

/mob/living/simple_animal/pig/user_buckle_mob(mob/living/buckling_mob, mob/user, check_loc = TRUE, silent)
	if(!Adjacent(buckling_mob, src) || !Adjacent(user, src))
		return FALSE
	return ..(buckling_mob, user, FALSE, silent)

/mob/living/simple_animal/pig/buckle_mob(mob/living/buckling_mob, force = FALSE, check_loc = TRUE, lying_buckle = FALSE, hands_needed = 0, target_hands_needed = 0, silent)
	buckling_mob.density = FALSE
	. = ..()
	if(!.)
		buckling_mob.density = initial(buckling_mob.density)

/mob/living/simple_animal/pig/post_unbuckle_mob(mob/living/buckled_mob)
	buckled_mob.density = initial(buckled_mob.density)

/mob/living/simple_animal/pig/relaymove(mob/living/user, direction)
	if(user.buckled != src)
		return ..()
	return relaydrive(user, direction)

/mob/living/simple_animal/pig/mini
	name = "mini pig"
	desc = "An adorably tiny pig. Still oinks with authority."
	icon = 'icons/mob/animal.dmi'
	icon_state = "pig_mini"
	icon_living = "pig_mini"
	icon_dead = "pig_mini_dead"
	health = 20
	maxHealth = 20
	melee_damage = 1
	mob_size = MOB_SIZE_SMALL
	density = FALSE

/mob/living/simple_animal/horse
	name = "horse"
	desc = "A friendly horse. Seems to be tamed. Drag yourself onto it to ride."
	icon = 'icons/mob/animal_96.dmi'
	icon_state = "horse"
	icon_living = "horse"
	icon_dead = "horse_dead"
	buckle_flags = CAN_BUCKLE|BUCKLE_PREVENTS_PULL
	max_buckled_mobs = 1
	buckle_lying = -1
	speak = list("Neigh!", "Neigh?", "Neigh!")
	speak_emote = list("neighs")
	emote_hear = list("neighs.")
	emote_see = list("shakes its head.")
	speak_chance = 2
	turns_per_move = 2
	response_help = "pets"
	response_disarm = "gently pushes aside"
	response_harm = "kicks"
	attacktext = "kicked"
	health = 180
	maxHealth = 180
	melee_damage = 8
	mob_size = MOB_SIZE_BIG
	layer = BELOW_MOB_LAYER
	pixel_w = -32
	pixel_z = -16
	var/icon_riding = "horse_riding"
	var/mutable_appearance/riding_overlay

/mob/living/simple_animal/horse/Initialize(mapload)
	. = ..()
	icon_riding = "[icon_living]_riding"
	AddElement(/datum/element/ridable, /datum/component/riding/creature/horse)
	RegisterSignal(src, COMSIG_ATOM_DIR_CHANGE, PROC_REF(on_horse_dir_change))
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(on_horse_moved))

/mob/living/simple_animal/horse/proc/on_horse_dir_change(datum/source, old_dir, new_dir)
	SIGNAL_HANDLER
	update_riding_appearance()

/mob/living/simple_animal/horse/proc/on_horse_moved(datum/source, atom/old_loc, direction)
	SIGNAL_HANDLER
	if(LAZYLEN(buckled_mobs))
		update_riding_appearance()

/mob/living/simple_animal/horse/proc/update_riding_appearance()
	if(!LAZYLEN(buckled_mobs))
		if(riding_overlay)
			cut_overlay(riding_overlay)
			riding_overlay = null
		if(stat != DEAD)
			icon_state = icon_living
		return
	if(riding_overlay)
		cut_overlay(riding_overlay)
	riding_overlay = mutable_appearance(icon, icon_riding, MOB_BELOW_PIGGYBACK_LAYER)
	riding_overlay.dir = dir
	cut_overlay(riding_overlay)
	add_overlay(riding_overlay)
	if(stat != DEAD)
		icon_state = icon_living
	update_appearance()

/mob/living/simple_animal/horse/proc/reset_rider_position(mob/living/rider)
	rider.pixel_x = initial(rider.pixel_x)
	rider.pixel_y = initial(rider.pixel_y)
	if(rider.client)
		rider.client.view_size.reset_to_default()

/mob/living/simple_animal/horse/user_buckle_mob(mob/living/buckling_mob, mob/user, check_loc = TRUE, silent)
	if(!Adjacent(buckling_mob, src) || !Adjacent(user, src))
		return FALSE
	return ..(buckling_mob, user, FALSE, silent)

/mob/living/simple_animal/horse/buckle_mob(mob/living/buckling_mob, force = FALSE, check_loc = TRUE, lying_buckle = FALSE, hands_needed = 0, target_hands_needed = 0, silent)
	buckling_mob.density = FALSE
	. = ..()
	if(!.)
		buckling_mob.density = initial(buckling_mob.density)

/mob/living/simple_animal/horse/post_buckle_mob(mob/living/buckled_mob)
	reset_rider_position(buckled_mob)
	update_riding_appearance()

/mob/living/simple_animal/horse/post_unbuckle_mob(mob/living/buckled_mob)
	buckled_mob.density = initial(buckled_mob.density)
	reset_rider_position(buckled_mob)
	if(!LAZYLEN(buckled_mobs))
		update_riding_appearance()

/mob/living/simple_animal/horse/relaymove(mob/living/user, direction)
	if(user.buckled != src)
		return ..()
	return relaydrive(user, direction)
