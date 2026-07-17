/mob/living/carbon/xenomorph/behemoth
	caste_base_type = /datum/xeno_caste/behemoth
	name = "Behemoth"
	desc = "A ferocious monster that commands the earth itself."
	icon = 'icons/Xeno/castes/behemoth/basic.dmi'
	icon_state = "Behemoth Walking"
	effects_icon = 'icons/Xeno/castes/behemoth/effects.dmi'
	bubble_icon = "alienleft"
	health = 450
	maxHealth = 450
	plasma_stored = 300
	tier = XENO_TIER_THREE
	upgrade = XENO_UPGRADE_NORMAL
	drag_delay = 5
	mob_size = MOB_SIZE_BIG
	pixel_x = -28.5

/mob/living/carbon/xenomorph/behemoth/primordial
	upgrade = XENO_UPGRADE_PRIMO

/mob/living/carbon/xenomorph/behemoth/Corrupted
	hivenumber = XENO_HIVE_CORRUPTED

/mob/living/carbon/xenomorph/behemoth/Alpha
	hivenumber = XENO_HIVE_ALPHA

/mob/living/carbon/xenomorph/behemoth/Beta
	hivenumber = XENO_HIVE_BETA

/mob/living/carbon/xenomorph/behemoth/Zeta
	hivenumber = XENO_HIVE_ZETA

/mob/living/carbon/xenomorph/behemoth/admeme
	hivenumber = XENO_HIVE_ADMEME

/mob/living/carbon/xenomorph/behemoth/Corrupted/fallen
	hivenumber = XENO_HIVE_FALLEN
