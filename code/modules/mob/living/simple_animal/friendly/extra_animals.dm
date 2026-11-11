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
