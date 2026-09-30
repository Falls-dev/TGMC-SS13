/mob/living/carbon/xenomorph/wraith
	caste_base_type = /datum/xeno_caste/wraith
	name = "Wraith"
	desc = "A strange tendriled alien. The air around it warps and shimmers like a heat mirage."
	icon = 'icons/Xeno/castes/wraith/wraith.dmi'
	icon_state = "Wraith Walking"
	bubble_icon = "alienleft"
	health = 150
	maxHealth = 150
	plasma_stored = 150
	pixel_x = -16
	tier = XENO_TIER_TWO
	upgrade = XENO_UPGRADE_NORMAL
	inherent_verbs = list(
		/mob/living/carbon/xenomorph/proc/vent_crawl,
	)

/mob/living/carbon/xenomorph/wraith/primordial
	upgrade = XENO_UPGRADE_PRIMO

/mob/living/carbon/xenomorph/wraith/Corrupted
	hivenumber = XENO_HIVE_CORRUPTED

/mob/living/carbon/xenomorph/wraith/Alpha
	hivenumber = XENO_HIVE_ALPHA

/mob/living/carbon/xenomorph/wraith/Beta
	hivenumber = XENO_HIVE_BETA

/mob/living/carbon/xenomorph/wraith/Zeta
	hivenumber = XENO_HIVE_ZETA

/mob/living/carbon/xenomorph/wraith/admeme
	hivenumber = XENO_HIVE_ADMEME

/mob/living/carbon/xenomorph/wraith/Corrupted/fallen
	hivenumber = XENO_HIVE_FALLEN
