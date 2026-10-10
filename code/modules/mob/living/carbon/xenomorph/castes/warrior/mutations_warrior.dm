// Warrior Enhancement mutations. Ported from the official Shell/Spur/Veil mutations (Zoomies, Enhanced Strength, Friendly Toss).
// Levels I/II/III use the official values for 1/2/3 structures. See datums/xeno_mutations_leveled.dm.

/datum/xeno_mutation/leveled/warrior
	caste_restrictions = list("warrior")

// ***************************************
// *********** Zoomies
// ***************************************
/datum/xeno_mutation/leveled/warrior/zoomies
	required_ability_types = list(/datum/action/ability/xeno_action/toggle_agility)
	name = "Zoomies"
	desc = "Agility даёт дополнительную скорость, но ещё сильнее снижает броню."
	level_costs = list(10, 15, 20)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/warrior_zoomies,
		/datum/status_effect/xeno_enhancement/warrior_zoomies/two,
		/datum/status_effect/xeno_enhancement/warrior_zoomies/three,
	)
	level_buff_descs = list(
		"Agility: +0.3 скорости, -10 брони.",
		"Agility: +0.6 скорости, -20 брони.",
		"Agility: +0.9 скорости, -30 брони.",
	)

/datum/status_effect/xeno_enhancement/warrior_zoomies
	id = "enhancement_warrior_zoomies"
	/// Per level, the amount added to Agility's movespeed modifier (negative is faster).
	var/list/speed_per_level = list(-0.3, -0.6, -0.9)
	/// Per level, the additional amount of soft armor that Agility takes away.
	var/list/armor_per_level = list(10, 20, 30)
	/// What was added to Agility's speed_modifier.
	var/applied_speed = 0
	/// What was added to Agility's armor_modifier.
	var/applied_armor = 0

/datum/status_effect/xeno_enhancement/warrior_zoomies/two
	level = 2

/datum/status_effect/xeno_enhancement/warrior_zoomies/three
	level = 3

/datum/status_effect/xeno_enhancement/warrior_zoomies/apply_enhancement()
	var/datum/action/ability/xeno_action/toggle_agility/agility_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/toggle_agility]
	if(!agility_ability)
		return FALSE
	applied_speed = get_level_value(speed_per_level)
	applied_armor = get_level_value(armor_per_level)
	agility_ability.speed_modifier += applied_speed
	agility_ability.armor_modifier += applied_armor
	agility_ability.refresh_agility()
	return TRUE

/datum/status_effect/xeno_enhancement/warrior_zoomies/remove_enhancement()
	var/datum/action/ability/xeno_action/toggle_agility/agility_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/toggle_agility]
	if(agility_ability)
		agility_ability.speed_modifier -= applied_speed
		agility_ability.armor_modifier -= applied_armor
		agility_ability.refresh_agility()
	applied_speed = 0
	applied_armor = 0

// ***************************************
// *********** Enhanced Strength
// ***************************************
/datum/xeno_mutation/leveled/warrior/enhanced_strength
	required_ability_types = list(/datum/action/ability/activable/xeno/warrior/fling, /datum/action/ability/activable/xeno/warrior/grapple_toss)
	name = "Enhanced Strength"
	desc = "Fling и Grapple Toss отправляют цель дальше."
	level_costs = list(10, 15, 20)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/warrior_enhanced_strength,
		/datum/status_effect/xeno_enhancement/warrior_enhanced_strength/two,
		/datum/status_effect/xeno_enhancement/warrior_enhanced_strength/three,
	)
	level_buff_descs = list(
		"Fling и Grapple Toss отправляют цели на 1 клетку дальше.",
		"Fling и Grapple Toss отправляют цели на 2 клетки дальше.",
		"Fling и Grapple Toss отправляют цели на 3 клетки дальше.",
	)

/datum/status_effect/xeno_enhancement/warrior_enhanced_strength
	id = "enhancement_warrior_enhanced_strength"
	/// Per level, the amount of tiles added to the distance of both abilities.
	var/list/range_per_level = list(1, 2, 3)
	/// What was added to both abilities.
	var/applied_range = 0

/datum/status_effect/xeno_enhancement/warrior_enhanced_strength/two
	level = 2

/datum/status_effect/xeno_enhancement/warrior_enhanced_strength/three
	level = 3

/datum/status_effect/xeno_enhancement/warrior_enhanced_strength/apply_enhancement()
	var/datum/action/ability/activable/xeno/warrior/fling/fling_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/warrior/fling]
	var/datum/action/ability/activable/xeno/warrior/grapple_toss/toss_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/warrior/grapple_toss]
	if(!fling_ability || !toss_ability)
		return FALSE
	applied_range = get_level_value(range_per_level)
	fling_ability.starting_fling_distance += applied_range
	toss_ability.starting_toss_distance += applied_range
	return TRUE

/datum/status_effect/xeno_enhancement/warrior_enhanced_strength/remove_enhancement()
	var/datum/action/ability/activable/xeno/warrior/fling/fling_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/warrior/fling]
	if(fling_ability)
		fling_ability.starting_fling_distance -= applied_range
	var/datum/action/ability/activable/xeno/warrior/grapple_toss/toss_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/warrior/grapple_toss]
	if(toss_ability)
		toss_ability.starting_toss_distance -= applied_range
	applied_range = 0

// ***************************************
// *********** Friendly Toss
// ***************************************
/datum/xeno_mutation/leveled/warrior/friendly_toss
	required_ability_types = list(/datum/action/ability/activable/xeno/warrior/fling, /datum/action/ability/activable/xeno/warrior/grapple_toss)
	name = "Friendly Toss"
	desc = "Fling и Grapple Toss восстанавливаются гораздо быстрее, если применены на союзников."
	level_costs = list(5, 10, 15)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/warrior_friendly_toss,
		/datum/status_effect/xeno_enhancement/warrior_friendly_toss/two,
		/datum/status_effect/xeno_enhancement/warrior_friendly_toss/three,
	)
	level_buff_descs = list(
		"Перезарядка Fling и Grapple Toss на союзников: 40% от обычной.",
		"Перезарядка Fling и Grapple Toss на союзников: 25% от обычной.",
		"Перезарядка Fling и Grapple Toss на союзников: 10% от обычной.",
	)

/datum/status_effect/xeno_enhancement/warrior_friendly_toss
	id = "enhancement_warrior_friendly_toss"
	/// Per level, the amount added to both abilities' ally cooldown multiplier (it starts at 1).
	var/list/cooldown_per_level = list(-0.6, -0.75, -0.9)
	/// What was added to both abilities.
	var/applied_cooldown = 0

/datum/status_effect/xeno_enhancement/warrior_friendly_toss/two
	level = 2

/datum/status_effect/xeno_enhancement/warrior_friendly_toss/three
	level = 3

/datum/status_effect/xeno_enhancement/warrior_friendly_toss/apply_enhancement()
	var/datum/action/ability/activable/xeno/warrior/fling/fling_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/warrior/fling]
	var/datum/action/ability/activable/xeno/warrior/grapple_toss/toss_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/warrior/grapple_toss]
	if(!fling_ability || !toss_ability)
		return FALSE
	applied_cooldown = get_level_value(cooldown_per_level)
	fling_ability.ally_cooldown_multiplier += applied_cooldown
	toss_ability.ally_cooldown_multiplier += applied_cooldown
	return TRUE

/datum/status_effect/xeno_enhancement/warrior_friendly_toss/remove_enhancement()
	var/datum/action/ability/activable/xeno/warrior/fling/fling_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/warrior/fling]
	if(fling_ability)
		fling_ability.ally_cooldown_multiplier -= applied_cooldown
	var/datum/action/ability/activable/xeno/warrior/grapple_toss/toss_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/warrior/grapple_toss]
	if(toss_ability)
		toss_ability.ally_cooldown_multiplier -= applied_cooldown
	applied_cooldown = 0
