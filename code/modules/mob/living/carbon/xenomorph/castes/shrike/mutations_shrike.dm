#define STATUS_EFFECT_LONE_HEALER /datum/status_effect/shrike/lone_healer
#define STATUS_EFFECT_RESISTANT_CURE /datum/status_effect/shrike/resistant_cure
#define STATUS_EFFECT_SMASHING_FLING /datum/status_effect/shrike/smashing_fling
#define STATUS_EFFECT_GRAVITY_TIDE /datum/status_effect/shrike/gravity_tide
#define STATUS_EFFECT_BODY_FLING /datum/status_effect/shrike/body_fling
#define STATUS_EFFECT_DELAYED_CONDITION /datum/status_effect/shrike/delayed_condition
#define STATUS_EFFECT_DEFLECTIVE_FORCE /datum/status_effect/shrike/deflective_force
#define STATUS_EFFECT_PSYCHIC_CHOKE /datum/status_effect/shrike/psychic_choke

/datum/xeno_mutation/shrike
	category = "Enhancement"
	caste_restrictions = list("shrike")

/datum/status_effect/shrike
	duration = -1
	status_type = STATUS_EFFECT_UNIQUE
	/// The xenomorph that owns this status effect.
	var/mob/living/carbon/xenomorph/xenomorph_owner

/datum/xeno_mutation/shrike/lone_healer
	name = "Lone Healer"
	desc = "Psychic Cure может использоваться на себя. Лечение себя эффективно только на 70%. Несовместим с Delayed condition."
	cost = 15
	icon_state = "xenobuff_generic"
	tier = 1
	parent_name = null
	child_name = null
	status_effect_type = STATUS_EFFECT_LONE_HEALER
	buff_desc = "Psychic Cure доступно на себя, 70% эффективности"
	conflicting_mutation_types = list(STATUS_EFFECT_DELAYED_CONDITION)

/atom/movable/screen/alert/status_effect/shrike/lone_healer
	name = "Lone Healer"
	desc = "Psychic Cure может использоваться на себя. Лечение себя эффективно только на 70%."
	icon_state = "xenobuff_attack"

/datum/status_effect/shrike/lone_healer
	id = "upgrade_lone_healer"
	alert_type = /atom/movable/screen/alert/status_effect/shrike/lone_healer

	var/self_heal_multiplier_value = -0.3  // 70% эффективности (1 - 0.3)

/datum/status_effect/shrike/lone_healer/on_apply()
	xenomorph_owner = owner
	var/datum/action/ability/activable/xeno/psychic_cure/cure_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/psychic_cure]
	if(!cure_ability)
		return FALSE
	cure_ability.use_state_flags |= ABILITY_TARGET_SELF
	cure_ability.self_heal_multiplier += self_heal_multiplier_value
	return TRUE

/datum/status_effect/shrike/lone_healer/on_remove()
	var/datum/action/ability/activable/xeno/psychic_cure/cure_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/psychic_cure]
	if(!cure_ability)
		return ..()
	cure_ability.use_state_flags &= ~(ABILITY_TARGET_SELF)
	cure_ability.self_heal_multiplier -= self_heal_multiplier_value
	return ..()

//
//
//

/datum/xeno_mutation/shrike/resistant_cure
	name = "Resistant Cure"
	desc = "Psychic Cure также применяет эффекты смолистого желе к вам и цели на 90 секунд."
	cost = 5
	icon_state = "xenobuff_generic"
	tier = 1
	parent_name = null
	child_name = null
	status_effect_type = STATUS_EFFECT_RESISTANT_CURE
	buff_desc = "Огнеустойчивость от Psychic Cure на 90с"

/atom/movable/screen/alert/status_effect/shrike/resistant_cure
	name = "Resistant Cure"
	desc = "Psychic Cure также применяет эффекты смолистого желе к вам и цели на 90 секунд."
	icon_state = "xenobuff_attack"

/datum/status_effect/shrike/resistant_cure
	id = "upgrade_resistant_cure"
	alert_type = /atom/movable/screen/alert/status_effect/shrike/resistant_cure

	var/duration_value = 90 SECONDS  // Максимум - 90 секунд

/datum/status_effect/shrike/resistant_cure/on_apply()
	xenomorph_owner = owner
	var/datum/action/ability/activable/xeno/psychic_cure/cure_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/psychic_cure]
	if(!cure_ability)
		return FALSE
	cure_ability.resin_jelly_duration += duration_value
	return TRUE

/datum/status_effect/shrike/resistant_cure/on_remove()
	var/datum/action/ability/activable/xeno/psychic_cure/cure_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/psychic_cure]
	if(!cure_ability)
		return ..()
	cure_ability.resin_jelly_duration -= duration_value
	return ..()

//
//
//

/datum/xeno_mutation/shrike/smashing_fling
	name = "Smashing Fling"
	desc = "Psychic Fling наносит 200% урона, равного вашему melee урону, позволяет столкновения, но больше не оглушает сразу. При столкновении с человеком/объектом/стеной: оба получают кратковременный паралич и снова получают урон. Несовместим с Psychic choke и Body fling."
	cost = 20
	icon_state = "xenobuff_generic"
	tier = 1
	parent_name = null
	child_name = null
	status_effect_type = STATUS_EFFECT_SMASHING_FLING
	buff_desc = "Урон Psychic Fling 200% от melee, с столкновениями"
	conflicting_mutation_types = list(STATUS_EFFECT_PSYCHIC_CHOKE, STATUS_EFFECT_BODY_FLING)

/atom/movable/screen/alert/status_effect/shrike/smashing_fling
	name = "Smashing Fling"
	desc = "Psychic Fling наносит 200% урона, равного вашему melee урону, позволяет столкновения, но больше не оглушает сразу. При столкновении с человеком/объектом/стеной: оба получают кратковременный паралич и снова получают урон."
	icon_state = "xenobuff_attack"

/datum/status_effect/shrike/smashing_fling
	id = "upgrade_smashing_fling"
	alert_type = /atom/movable/screen/alert/status_effect/shrike/smashing_fling

	var/multiplier_value = 2.0  // 200%

/datum/status_effect/shrike/smashing_fling/on_apply()
	xenomorph_owner = owner
	var/datum/action/ability/activable/xeno/psychic_fling/fling_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/psychic_fling]
	if(!fling_ability)
		return FALSE
	fling_ability.stun_duration = 0 SECONDS
	fling_ability.damage_multiplier += multiplier_value
	fling_ability.collusion_paralyze_duration = 0.1 SECONDS
	fling_ability.collusion_damage_multiplier += multiplier_value
	return TRUE

/datum/status_effect/shrike/smashing_fling/on_remove()
	var/datum/action/ability/activable/xeno/psychic_fling/fling_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/psychic_fling]
	if(!fling_ability)
		return ..()
	fling_ability.stun_duration = initial(fling_ability.stun_duration)
	fling_ability.damage_multiplier -= multiplier_value
	fling_ability.collusion_paralyze_duration = initial(fling_ability.collusion_paralyze_duration)
	fling_ability.collusion_damage_multiplier -= multiplier_value
	return ..()

/*
// ***************************************
// *********** Gravity Tide Mutation (DISABLED)
// ***************************************

/datum/xeno_mutation/shrike/gravity_tide
	name = "Gravity Tide"
	desc = "Unrelenting Force тянет объекты к вам, затем отбрасывает их. Расстояние отбрасывания увеличено на 1. Несовместим с Deflective force."
	cost = 5
	icon_state = "xenobuff_generic"
	tier = 1
	parent_name = null
	child_name = null
	status_effect_type = STATUS_EFFECT_GRAVITY_TIDE
	buff_desc = "Отбрасывание Unrelenting Force увеличено на 1"
	conflicting_mutation_types = list(STATUS_EFFECT_DEFLECTIVE_FORCE)

/atom/movable/screen/alert/status_effect/shrike/gravity_tide
	name = "Gravity Tide"
	desc = "Unrelenting Force тянет объекты к вам, затем отбрасывает их. Расстояние отбрасывания увеличено на 1."
	icon_state = "xenobuff_attack"

/datum/status_effect/shrike/gravity_tide
	id = "upgrade_gravity_tide"
	alert_type = /atom/movable/screen/alert/status_effect/shrike/gravity_tide

	var/distance_value = 1

/datum/status_effect/shrike/gravity_tide/on_apply()
	xenomorph_owner = owner
	var/datum/action/ability/activable/xeno/unrelenting_force/force_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/unrelenting_force]
	if(!force_ability)
		return FALSE
	force_ability.rebound_throwing = TRUE
	force_ability.throwing_distance += distance_value
	return TRUE

/datum/status_effect/shrike/gravity_tide/on_remove()
	var/datum/action/ability/activable/xeno/unrelenting_force/force_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/unrelenting_force]
	if(!force_ability)
		return ..()
	force_ability.rebound_throwing = initial(force_ability.rebound_throwing)
	force_ability.throwing_distance -= distance_value
	return ..()
*/

//
//
//

/datum/xeno_mutation/shrike/body_fling
	name = "Body Fling"
	desc = "Psychic Fling можно использовать на себя и союзных ксеноморфов. Люди, попавшие под брошенного ксеноморфа, парализуются на 2 секунды и получают 200% от вашего slash урона. Несовместим с Psychic choke и Smashing fling."
	cost = 10
	icon_state = "xenobuff_generic"
	tier = 1
	parent_name = null
	child_name = null
	status_effect_type = STATUS_EFFECT_BODY_FLING
	buff_desc = "Fling себя/ксенов, 200% slash урона по людям"
	conflicting_mutation_types = list(STATUS_EFFECT_PSYCHIC_CHOKE, STATUS_EFFECT_SMASHING_FLING)

/atom/movable/screen/alert/status_effect/shrike/body_fling
	name = "Body Fling"
	desc = "Psychic Fling можно использовать на себя и союзных ксеноморфов. Люди, попавшие под брошенного ксеноморфа, парализуются на 2 секунды и получают 200% от вашего slash урона."
	icon_state = "xenobuff_attack"

/datum/status_effect/shrike/body_fling
	id = "upgrade_body_fling"
	alert_type = /atom/movable/screen/alert/status_effect/shrike/body_fling

	var/multiplier_value = 2.0  // 200%

/datum/status_effect/shrike/body_fling/on_apply()
	xenomorph_owner = owner
	var/datum/action/ability/activable/xeno/psychic_fling/fling_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/psychic_fling]
	if(!fling_ability)
		return FALSE
	fling_ability.use_state_flags |= ABILITY_TARGET_SELF
	fling_ability.collusion_damage_multiplier += multiplier_value
	fling_ability.collusion_paralyze_duration += 2 SECONDS
	return TRUE

/datum/status_effect/shrike/body_fling/on_remove()
	var/datum/action/ability/activable/xeno/psychic_fling/fling_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/psychic_fling]
	if(!fling_ability)
		return ..()
	fling_ability.use_state_flags &= ~ABILITY_TARGET_SELF
	fling_ability.collusion_damage_multiplier -= multiplier_value
	fling_ability.collusion_paralyze_duration -= 2 SECONDS
	return ..()

//
//
//

/datum/xeno_mutation/shrike/delayed_condition
	name = "Delayed Condition"
	desc = "Psychic Cure дает иммунитет к замедлению и задерживает все входящие эффекты оглушения/падения/шатания на 20 секунд. По окончании задержки эффекты применяются повторно. Несовместим с Lone healer."
	cost = 15
	icon_state = "xenobuff_generic"
	tier = 1
	parent_name = null
	child_name = null
	status_effect_type = STATUS_EFFECT_DELAYED_CONDITION
	buff_desc = "Задержка статус-эффектов на 20с"
	conflicting_mutation_types = list(STATUS_EFFECT_LONE_HEALER)

/atom/movable/screen/alert/status_effect/shrike/delayed_condition
	name = "Delayed Condition"
	desc = "Psychic Cure дает иммунитет к замедлению и задерживает все входящие эффекты оглушения/падения/шатания на 20 секунд. По окончании задержки эффекты применяются повторно."
	icon_state = "xenobuff_attack"

/datum/status_effect/shrike/delayed_condition
	id = "upgrade_delayed_condition"
	alert_type = /atom/movable/screen/alert/status_effect/shrike/delayed_condition

	var/duration_value = 20 SECONDS  // Максимум - 20 секунд

/datum/status_effect/shrike/delayed_condition/on_apply()
	xenomorph_owner = owner
	var/datum/action/ability/activable/xeno/psychic_cure/cure_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/psychic_cure]
	if(!cure_ability)
		return FALSE
	cure_ability.delayed_status_duration += duration_value
	return TRUE

/datum/status_effect/shrike/delayed_condition/on_remove()
	var/datum/action/ability/activable/xeno/psychic_cure/cure_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/psychic_cure]
	if(!cure_ability)
		return ..()
	cure_ability.delayed_status_duration -= duration_value
	return ..()

//
//
//

/datum/xeno_mutation/shrike/deflective_force
	name = "Deflective Force"
	desc = "Unrelenting Force теперь отражает все снаряды в своей области. При отражении >50 урона от снародов перезарядка Psychic Scream становится 40% от оригинальной. Несовместим с Gravity tide."
	cost = 10
	icon_state = "xenobuff_generic"
	tier = 1
	parent_name = null
	child_name = null
	status_effect_type = STATUS_EFFECT_DEFLECTIVE_FORCE
	buff_desc = "Отражение снарядов, перезарядка крика 40%"

/atom/movable/screen/alert/status_effect/shrike/deflective_force
	name = "Deflective Force"
	desc = "Unrelenting Force теперь отражает все снаряды в своей области. При отражении >50 урона от снародов перезарядка Psychic Scream становится 40% от оригинальной."
	icon_state = "xenobuff_attack"

/datum/status_effect/shrike/deflective_force
	id = "upgrade_deflective_force"
	alert_type = /atom/movable/screen/alert/status_effect/shrike/deflective_force

	var/multiplier_value = 0.4  // 40%

/datum/status_effect/shrike/deflective_force/on_apply()
	xenomorph_owner = owner
	var/datum/action/ability/activable/xeno/unrelenting_force/force_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/unrelenting_force]
	if(!force_ability)
		return FALSE
	force_ability.projectile_cooldown_mulitplier += multiplier_value
	return TRUE

/datum/status_effect/shrike/deflective_force/on_remove()
	var/datum/action/ability/activable/xeno/unrelenting_force/force_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/unrelenting_force]
	if(!force_ability)
		return ..()
	force_ability.projectile_cooldown_mulitplier -= multiplier_value
	return ..()

//
//
//

/datum/xeno_mutation/shrike/psychic_choke
	name = "Psychic Choke"
	desc = "Вы теряете способность Psychic Fling и получаете Psychic Choke. Choke позволяет парализовать морпеха во время использования. Порог урона для прерывания - 80. Несовместим с Body fling и Smashing fling."
	cost = 5
	icon_state = "xenobuff_generic"
	tier = 1
	parent_name = null
	child_name = null
	status_effect_type = STATUS_EFFECT_PSYCHIC_CHOKE
	buff_desc = "Choke вместо Fling, порог прерывания 80"
	conflicting_mutation_types = list(STATUS_EFFECT_BODY_FLING, STATUS_EFFECT_SMASHING_FLING)

/atom/movable/screen/alert/status_effect/shrike/psychic_choke
	name = "Psychic Choke"
	desc = "Вы теряете способность Psychic Fling и получаете Psychic Choke. Choke позволяет парализовать морпеха во время использования. Порог урона для прерывания - 80."
	icon_state = "xenobuff_attack"

/datum/status_effect/shrike/psychic_choke
	id = "upgrade_psychic_choke"
	alert_type = /atom/movable/screen/alert/status_effect/shrike/psychic_choke

	var/threshold_value = 80  // Максимум - 80

/datum/status_effect/shrike/psychic_choke/on_apply()
	xenomorph_owner = owner
	// Удаляем ВСЕ копии Psychic Fling, чтобы не плодить дубликаты
	for(var/datum/action/ability/activable/xeno/psychic_fling/fling in xenomorph_owner.actions)
		fling.remove_action(xenomorph_owner)
	// Добавляем Choke
	var/datum/action/ability/activable/xeno/psychic_choke/choke_ability = new()
	choke_ability.give_action(xenomorph_owner)
	return TRUE

/datum/status_effect/shrike/psychic_choke/on_remove()
	// Удаляем ВСЕ копии Choke
	for(var/datum/action/ability/activable/xeno/psychic_choke/choke in xenomorph_owner.actions)
		choke.remove_action(xenomorph_owner)
	// Проверяем, есть ли уже Fling у моба
	var/has_fling = FALSE
	for(var/datum/action/ability/activable/xeno/psychic_fling/fling in xenomorph_owner.actions)
		has_fling = TRUE
		break
	// Добавляем Fling ТОЛЬКО если его нет
	if(!has_fling)
		var/datum/action/ability/activable/xeno/psychic_fling/fling_ability = new()
		fling_ability.give_action(xenomorph_owner)
	return ..()

