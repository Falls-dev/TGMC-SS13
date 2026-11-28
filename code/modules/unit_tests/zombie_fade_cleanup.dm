/datum/unit_test/zombie_fade_cleanup/Run()
	var/mob/living/carbon/human/zombie = allocate(/mob/living/carbon/human/species/zombie/ai/patrol)
	zombie.on_fire = TRUE
	zombie.species.handle_death(zombie)

	var/datum/timedevent/fade_timer
	for(var/datum/timedevent/timer as anything in zombie._active_timers)
		if(timer.callBack?.delegate == TYPE_PROC_REF(/mob/living/carbon/human, fade_zombie_corpse))
			fade_timer = timer
			break
	TEST_ASSERT_NOTNULL(fade_timer, "The zombie must own its pending fade timer")

	qdel(zombie)
	TEST_ASSERT(QDELETED(fade_timer), "Deleting the zombie must cancel the pending fade")
