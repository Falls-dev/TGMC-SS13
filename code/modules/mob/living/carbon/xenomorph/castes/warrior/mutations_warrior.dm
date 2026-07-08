//*********************//
//      DEFINES        //
//*********************//
#define STATUS_EFFECT_ZOOMIES /datum/status_effect/warrior/zoomies
#define STATUS_EFFECT_ENHANCED_STRENGTH /datum/status_effect/warrior/enhanced_strength
#define STATUS_EFFECT_FRIENDLY_TOSS /datum/status_effect/warrior/friendly_toss

//*********************//
//    BASE CLASSES     //
//*********************//
/datum/xeno_mutation/warrior
	category = "Enhancement"
	caste_restrictions = list("warrior")

/datum/status_effect/warrior
	duration = -1
	status_type = STATUS_EFFECT_UNIQUE
	var/mob/living/carbon/xenomorph/xenomorph_owner

//*********************//
//       Zoomies       //
//*********************//
/datum/xeno_mutation/warrior/zoomies
	name = "Zoomies"
	desc = "Agility даёт дополнительно 0.9 к скорости, но снижает вашу броню на 30 пунктов во всех категориях."
	cost = 10
	icon_state = "xenobuff_generic"
	tier = 1
	status_effect_type = STATUS_EFFECT_ZOOMIES
	buff_desc = "+0.9 скорости в Agility, -30 брони."

/atom/movable/screen/alert/status_effect/warrior/zoomies
	name = "Zoomies"
	desc = "Agility даёт дополнительно 0.9 к скорости, но снижает вашу броню на 30 пунктов."
	icon_state = "xenobuff_attack"

/datum/status_effect/warrior/zoomies
	id = "upgrade_zoomies"
	alert_type = /atom/movable/screen/alert/status_effect/warrior/zoomies
	var/speed_bonus = -0.9
	var/armor_penalty = -30

/datum/status_effect/warrior/zoomies/on_apply()
	xenomorph_owner = owner
	var/datum/action/ability/xeno_action/toggle_agility/agility_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/toggle_agility]
	if(!agility_ability)
		return

	agility_ability.speed_modifier += speed_bonus
	agility_ability.armor_modifier += armor_penalty

	// Если абилка уже включена, обновляем эффекты на лету
	if(agility_ability.toggled)
		xenomorph_owner.add_movespeed_modifier(MOVESPEED_ID_WARRIOR_AGILITY, TRUE, 0, NONE, TRUE, agility_ability.speed_modifier)
		if(agility_ability.attached_armor)
			xenomorph_owner.soft_armor = xenomorph_owner.soft_armor.detachArmor(agility_ability.attached_armor)
		// Используем getArmor вместо new, как принято в вашем билде
		agility_ability.attached_armor = getArmor(agility_ability.armor_modifier, agility_ability.armor_modifier, agility_ability.armor_modifier, agility_ability.armor_modifier, agility_ability.armor_modifier, agility_ability.armor_modifier, agility_ability.armor_modifier, agility_ability.armor_modifier)
		xenomorph_owner.soft_armor = xenomorph_owner.soft_armor.attachArmor(agility_ability.attached_armor)
	return TRUE

/datum/status_effect/warrior/zoomies/on_remove()
	var/datum/action/ability/xeno_action/toggle_agility/agility_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/toggle_agility]
	if(!agility_ability)
		return ..()

	agility_ability.speed_modifier -= speed_bonus
	agility_ability.armor_modifier -= armor_penalty

	if(agility_ability.toggled)
		xenomorph_owner.add_movespeed_modifier(MOVESPEED_ID_WARRIOR_AGILITY, TRUE, 0, NONE, TRUE, agility_ability.speed_modifier)
		if(agility_ability.attached_armor)
			xenomorph_owner.soft_armor = xenomorph_owner.soft_armor.detachArmor(agility_ability.attached_armor)
		agility_ability.attached_armor = getArmor(agility_ability.armor_modifier, agility_ability.armor_modifier, agility_ability.armor_modifier, agility_ability.armor_modifier, agility_ability.armor_modifier, agility_ability.armor_modifier, agility_ability.armor_modifier, agility_ability.armor_modifier)
		xenomorph_owner.soft_armor = xenomorph_owner.soft_armor.attachArmor(agility_ability.attached_armor)
	return ..()

//*********************//
//  Enhanced Strength  //
//*********************//
/datum/xeno_mutation/warrior/enhanced_strength
	name = "Enhanced Strength"
	desc = "Fling и Grapple Toss отправляют цель на 3 тайла дальше."
	cost = 10
	icon_state = "xenobuff_generic"
	tier = 1
	status_effect_type = STATUS_EFFECT_ENHANCED_STRENGTH
	buff_desc = "+3 тайла к дальности Fling и Grapple Toss."

/atom/movable/screen/alert/status_effect/warrior/enhanced_strength
	name = "Enhanced Strength"
	desc = "Fling и Grapple Toss отправляют цель на 3 тайла дальше."
	icon_state = "xenobuff_attack"

/datum/status_effect/warrior/enhanced_strength
	id = "upgrade_enhanced_strength"
	alert_type = /atom/movable/screen/alert/status_effect/warrior/enhanced_strength
	var/throw_distance_bonus = 3

/datum/status_effect/warrior/enhanced_strength/on_apply()
	xenomorph_owner = owner
	var/datum/action/ability/activable/xeno/warrior/fling/fling_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/warrior/fling]
	var/datum/action/ability/activable/xeno/warrior/grapple_toss/toss_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/warrior/grapple_toss]

	if(fling_ability)
		fling_ability.starting_fling_distance += throw_distance_bonus
	if(toss_ability)
		toss_ability.starting_toss_distance += throw_distance_bonus
	return TRUE

/datum/status_effect/warrior/enhanced_strength/on_remove()
	var/datum/action/ability/activable/xeno/warrior/fling/fling_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/warrior/fling]
	var/datum/action/ability/activable/xeno/warrior/grapple_toss/toss_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/warrior/grapple_toss]

	if(fling_ability)
		fling_ability.starting_fling_distance -= throw_distance_bonus
	if(toss_ability)
		toss_ability.starting_toss_distance -= throw_distance_bonus
	return ..()

//*********************//
//    Friendly Toss    //
//*********************//
/datum/xeno_mutation/warrior/friendly_toss
	name = "Friendly Toss"
	desc = "Кулдаун Fling и Grapple Toss снижается до 10% от оригинального, если они были использованы на союзниках."
	cost = 7.5
	icon_state = "xenobuff_generic"
	tier = 1
	status_effect_type = STATUS_EFFECT_FRIENDLY_TOSS
	buff_desc = "Кулдаун Fling/Grapple на союзниках 10%."

/atom/movable/screen/alert/status_effect/warrior/friendly_toss
	name = "Friendly Toss"
	desc = "Кулдаун Fling и Grapple Toss снижается до 10%, если использованы на союзниках."
	icon_state = "xenobuff_attack"

/datum/status_effect/warrior/friendly_toss
	id = "upgrade_friendly_toss"
	alert_type = /atom/movable/screen/alert/status_effect/warrior/friendly_toss
	var/cooldown_reduction = -0.9

/datum/status_effect/warrior/friendly_toss/on_apply()
	xenomorph_owner = owner
	var/datum/action/ability/activable/xeno/warrior/fling/fling_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/warrior/fling]
	var/datum/action/ability/activable/xeno/warrior/grapple_toss/toss_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/warrior/grapple_toss]

	if(fling_ability)
		fling_ability.ally_cooldown_multiplier += cooldown_reduction
	if(toss_ability)
		toss_ability.ally_cooldown_multiplier += cooldown_reduction
	return TRUE

/datum/status_effect/warrior/friendly_toss/on_remove()
	var/datum/action/ability/activable/xeno/warrior/fling/fling_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/warrior/fling]
	var/datum/action/ability/activable/xeno/warrior/grapple_toss/toss_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/warrior/grapple_toss]

	if(fling_ability)
		fling_ability.ally_cooldown_multiplier -= cooldown_reduction
	if(toss_ability)
		toss_ability.ally_cooldown_multiplier -= cooldown_reduction
	return ..()
