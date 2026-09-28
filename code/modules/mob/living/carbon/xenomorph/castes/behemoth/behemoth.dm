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

/mob/living/carbon/xenomorph/behemoth/ancient
	caste_base_type = /datum/xeno_caste/behemoth/ancient
	name = "Ancient Behemoth"
	desc = "The original Behemoth strain: slow, massive and built to break a frontline."
	icon = 'icons/Xeno/castes/behemoth/basic.dmi'
	icon_state = "Behemoth Walking"
	health = 750
	maxHealth = 750
	plasma_stored = 200
	tier = XENO_TIER_THREE
	upgrade = XENO_UPGRADE_NORMAL
	drag_delay = 6
	mob_size = MOB_SIZE_BIG
	max_buckled_mobs = 2
	pixel_x = -28.5
	footstep_type = FOOTSTEP_XENO_HEAVY

/mob/living/carbon/xenomorph/behemoth/ancient/handle_special_state()
	var/datum/action/ability/xeno_action/ready_charge/ancient_behemoth_roll/roll = actions_by_path[/datum/action/ability/xeno_action/ready_charge/ancient_behemoth_roll]
	if(!roll?.charge_ability_on)
		return FALSE
	if(roll.valid_steps_taken == roll.max_steps_buildup)
		icon_state = "Behemoth Charging"
	else
		icon_state = "Behemoth Rolling"
	return TRUE

/mob/living/carbon/xenomorph/behemoth/ancient/handle_special_wound_states(severity)
	. = ..()
	var/datum/action/ability/xeno_action/ready_charge/ancient_behemoth_roll/roll = actions_by_path[/datum/action/ability/xeno_action/ready_charge/ancient_behemoth_roll]
	if(roll?.charge_ability_on)
		return "wounded_charging_[severity]"

/mob/living/carbon/xenomorph/behemoth/ancient/get_status_tab_items()
	. = ..()
	if(xeno_caste.wrath_max > 0)
		. += "Wrath: [wrath_stored] / [xeno_caste.wrath_max]"

/mob/living/carbon/xenomorph/behemoth/ancient/can_mount(mob/living/user, target_mounting = FALSE)
	. = ..()
	if(!target_mounting)
		user = pulling
	if(!isxeno(user))
		return FALSE
	var/mob/living/carbon/xenomorph/grabbed = user
	if(grabbed.incapacitated() || !(grabbed.xeno_caste.can_flags & CASTE_CAN_RIDE_CRUSHER))
		return FALSE
	return TRUE

/mob/living/carbon/xenomorph/behemoth/ancient/resisted_against(datum/source)
	user_unbuckle_mob(source, source)

/mob/living/carbon/xenomorph/behemoth/ancient/primordial
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
