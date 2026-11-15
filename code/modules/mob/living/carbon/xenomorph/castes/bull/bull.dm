/mob/living/carbon/xenomorph/bull
	caste_base_type = /datum/xeno_caste/bull
	name = "Bull"
	desc = "A bright red alien with a matching temper."
	icon = 'icons/Xeno/castes/bull/basic.dmi'
	icon_state = "Bull Walking"
	effects_icon = 'icons/Xeno/castes/bull/effects.dmi'
	bubble_icon = "alien"
	health = 160
	maxHealth = 160
	plasma_stored = 200
	tier = XENO_TIER_TWO
	upgrade = XENO_UPGRADE_NORMAL

	pixel_x = -16
	pixel_y = -3

	skins = list(
		/datum/xenomorph_skin/bull,
		/datum/xenomorph_skin/bull/rouny,
	)

/mob/living/carbon/xenomorph/bull/handle_special_state()
	if(is_charging >= CHARGE_ON)
		icon_state = "[xeno_caste.caste_name] Charging"
		return TRUE
	return FALSE

/mob/living/carbon/xenomorph/bull/handle_special_wound_states(severity)
	. = ..()
	if(is_charging >= CHARGE_ON)
		return "wounded_charging_[severity]"

/mob/living/carbon/xenomorph/bull/primordial
	upgrade = XENO_UPGRADE_PRIMO

/mob/living/carbon/xenomorph/bull/Corrupted
	hivenumber = XENO_HIVE_CORRUPTED

/mob/living/carbon/xenomorph/bull/Alpha
	hivenumber = XENO_HIVE_ALPHA

/mob/living/carbon/xenomorph/bull/Beta
	hivenumber = XENO_HIVE_BETA

/mob/living/carbon/xenomorph/bull/Zeta
	hivenumber = XENO_HIVE_ZETA

/mob/living/carbon/xenomorph/bull/admeme
	hivenumber = XENO_HIVE_ADMEME

/mob/living/carbon/xenomorph/bull/Corrupted/fallen
	hivenumber = XENO_HIVE_FALLEN

/// Returns the duration of a charge, which is lengthened by the Railgun mutation.
/mob/living/carbon/xenomorph/proc/get_charge_duration(base_duration)
	return base_duration * (1 + charge_duration_bonus)

/// Called when a charge starts. Gives stagger immunity once the Unstoppable fraction of the charge has passed.
/mob/living/carbon/xenomorph/proc/on_charge_start(charge_length)
	if(charge_immunity_timer)
		deltimer(charge_immunity_timer)
		charge_immunity_timer = null
	if(charge_stagger_immunity_fraction <= 0)
		return
	charge_immunity_timer = addtimer(CALLBACK(src, PROC_REF(grant_charge_stagger_immunity)), charge_length * charge_stagger_immunity_fraction, TIMER_STOPPABLE)

/// Gives the stagger immunity of the Unstoppable mutation.
/mob/living/carbon/xenomorph/proc/grant_charge_stagger_immunity()
	charge_immunity_timer = null
	if(!bull_charging)
		return
	ADD_TRAIT(src, TRAIT_STAGGERIMMUNE, BULL_ABILITY_TRAIT)

/// Called when a charge ends. Removes the stagger immunity of the Unstoppable mutation.
/mob/living/carbon/xenomorph/proc/on_charge_end()
	if(charge_immunity_timer)
		deltimer(charge_immunity_timer)
		charge_immunity_timer = null
	REMOVE_TRAIT(src, TRAIT_STAGGERIMMUNE, BULL_ABILITY_TRAIT)
