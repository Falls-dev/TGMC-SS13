// Spitter and Globadier Enhancement mutations. Ported from the official Shell/Spur/Veil mutations.
// Levels I/II/III use the official values for 1/2/3 structures. See datums/xeno_mutations_leveled.dm.
// The Spitter and Globadier share their caste name, so they are told apart by caste type.

/datum/xeno_mutation/leveled/spitter
	caste_restrictions = list("spitter")
	caste_type_restrictions = list(/datum/xeno_caste/spitter)
	caste_type_exclusions = list(/datum/xeno_caste/spitter/globadier)

/datum/xeno_mutation/leveled/globadier
	caste_restrictions = list("spitter")
	caste_type_restrictions = list(/datum/xeno_caste/spitter/globadier)
	required_ability_types = list(/datum/action/ability/activable/xeno/toss_grenade)

// ***************************************
// *********** Acid Sweat
// ***************************************
/datum/xeno_mutation/leveled/spitter/acid_sweat
	name = "Acid Sweat"
	desc = "Если вы горите, тратит плазму, чтобы потушить вас и весь огонь под вами. Срабатывает не чаще раза в секунду."
	level_costs = list(10, 15, 20)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/spitter_acid_sweat,
		/datum/status_effect/xeno_enhancement/spitter_acid_sweat/two,
		/datum/status_effect/xeno_enhancement/spitter_acid_sweat/three,
	)
	level_buff_descs = list(
		"Если вы горите, тратит 20 плазмы, чтобы потушить вас и весь огонь под вами. Не чаще раза в секунду.",
		"Если вы горите, тратит 15 плазмы, чтобы потушить вас и весь огонь под вами. Не чаще раза в секунду.",
		"Если вы горите, тратит 10 плазмы, чтобы потушить вас и весь огонь под вами. Не чаще раза в секунду.",
	)

/datum/status_effect/xeno_enhancement/spitter_acid_sweat
	id = "enhancement_spitter_acid_sweat"
	/// Per level, the amount of plasma consumed.
	var/list/cost_per_level = list(20, 15, 10)
	/// The ID of a timer that will check if the owner needs to be re-extinguished.
	var/timer_id
	/// How long is the timer?
	var/timer_length = 1 SECONDS

/datum/status_effect/xeno_enhancement/spitter_acid_sweat/two
	level = 2

/datum/status_effect/xeno_enhancement/spitter_acid_sweat/three
	level = 3

/datum/status_effect/xeno_enhancement/spitter_acid_sweat/apply_enhancement()
	RegisterSignal(xenomorph_owner, COMSIG_LIVING_IGNITED, PROC_REF(on_ignited))
	try_extinguish()
	return TRUE

/datum/status_effect/xeno_enhancement/spitter_acid_sweat/remove_enhancement()
	UnregisterSignal(xenomorph_owner, COMSIG_LIVING_IGNITED)
	if(timer_id)
		deltimer(timer_id)
		timer_id = null

/// Extinguishes the owner and qdel all fires underneath them if possible.
/datum/status_effect/xeno_enhancement/spitter_acid_sweat/proc/try_extinguish(timed_extinguished = FALSE)
	if(timer_id)
		if(!timed_extinguished)
			return
		deltimer(timer_id)
		timer_id = null
	if(!xenomorph_owner || !xenomorph_owner.on_fire)
		return
	var/plasma_cost = get_level_value(cost_per_level)
	if(xenomorph_owner.plasma_stored < plasma_cost)
		return
	xenomorph_owner.use_plasma(plasma_cost)
	xenomorph_owner.ExtinguishMob()
	for(var/obj/fire/fire_in_turf in get_turf(xenomorph_owner))
		qdel(fire_in_turf)
	if(timer_length) // To re-extinguish them if they were set on fire while the timer is active.
		timer_id = addtimer(CALLBACK(src, PROC_REF(try_extinguish), TRUE), timer_length, TIMER_STOPPABLE|TIMER_UNIQUE)

/// Immediately after being set on fire, tries to extinguish the owner and qdel all fires underneath them if possible.
/datum/status_effect/xeno_enhancement/spitter_acid_sweat/proc/on_ignited(datum/source, fire_stacks)
	SIGNAL_HANDLER
	try_extinguish()

// ***************************************
// *********** Hit and Run
// ***************************************
/datum/xeno_mutation/leveled/spitter/hit_and_run
	required_ability_types = list(/datum/action/ability/activable/xeno/scatter_spit)
	name = "Hit and Run"
	desc = "Cast time у Scatter Spit уменьшается, но он больше не получает бонус к урону."
	level_costs = list(10, 15, 20)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/spitter_hit_and_run,
		/datum/status_effect/xeno_enhancement/spitter_hit_and_run/two,
		/datum/status_effect/xeno_enhancement/spitter_hit_and_run/three,
	)
	level_buff_descs = list(
		"Cast time у Scatter Spit составляет 60% от обычного. Бонус к урону не применяется.",
		"Cast time у Scatter Spit составляет 40% от обычного. Бонус к урону не применяется.",
		"Cast time у Scatter Spit составляет 20% от обычного. Бонус к урону не применяется.",
	)

/datum/status_effect/xeno_enhancement/spitter_hit_and_run
	id = "enhancement_spitter_hit_and_run"
	/// Per level, the multiplier that is added to the initial cast time of Scatter Spit.
	var/list/cast_multiplier_per_level = list(-0.4, -0.6, -0.8)
	/// The amount of deciseconds that was added to the cast time.
	var/applied_cast_time = 0

/datum/status_effect/xeno_enhancement/spitter_hit_and_run/two
	level = 2

/datum/status_effect/xeno_enhancement/spitter_hit_and_run/three
	level = 3

/datum/status_effect/xeno_enhancement/spitter_hit_and_run/apply_enhancement()
	var/datum/action/ability/activable/xeno/scatter_spit/scatter_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/scatter_spit]
	if(!scatter_ability)
		return FALSE
	applied_cast_time = initial(scatter_ability.cast_time) * get_level_value(cast_multiplier_per_level)
	scatter_ability.cast_time += applied_cast_time
	scatter_ability.should_get_upgrade_bonus = FALSE
	return TRUE

/datum/status_effect/xeno_enhancement/spitter_hit_and_run/remove_enhancement()
	var/datum/action/ability/activable/xeno/scatter_spit/scatter_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/scatter_spit]
	if(scatter_ability)
		scatter_ability.cast_time -= applied_cast_time
		scatter_ability.should_get_upgrade_bonus = initial(scatter_ability.should_get_upgrade_bonus)
	applied_cast_time = 0

// ***************************************
// *********** Wet Claws
// ***************************************
/datum/xeno_mutation/leveled/spitter/wet_claws
	name = "Wet Claws"
	desc = "Удары по горящим людям уменьшают количество их fire stacks."
	level_costs = list(10, 15, 20)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/spitter_wet_claws,
		/datum/status_effect/xeno_enhancement/spitter_wet_claws/two,
		/datum/status_effect/xeno_enhancement/spitter_wet_claws/three,
	)
	level_buff_descs = list(
		"Удары по горящим людям уменьшают их fire stacks на 1.",
		"Удары по горящим людям уменьшают их fire stacks на 2.",
		"Удары по горящим людям уменьшают их fire stacks на 3.",
	)

/datum/status_effect/xeno_enhancement/spitter_wet_claws
	id = "enhancement_spitter_wet_claws"
	/// Per level, the amount of fire stacks to add (negative reduces them).
	var/list/stacks_per_level = list(-1, -2, -3)

/datum/status_effect/xeno_enhancement/spitter_wet_claws/two
	level = 2

/datum/status_effect/xeno_enhancement/spitter_wet_claws/three
	level = 3

/datum/status_effect/xeno_enhancement/spitter_wet_claws/apply_enhancement()
	RegisterSignal(xenomorph_owner, COMSIG_XENOMORPH_POSTATTACK_LIVING, PROC_REF(on_postattack_living))
	return TRUE

/datum/status_effect/xeno_enhancement/spitter_wet_claws/remove_enhancement()
	UnregisterSignal(xenomorph_owner, COMSIG_XENOMORPH_POSTATTACK_LIVING)

/// Adjusts fire stacks of the hit target.
/datum/status_effect/xeno_enhancement/spitter_wet_claws/proc/on_postattack_living(mob/living/carbon/xenomorph/source, mob/living/target, damage)
	SIGNAL_HANDLER
	if(!target.on_fire)
		return
	target.adjust_fire_stacks(get_level_value(stacks_per_level))

// ***************************************
// *********** Self Explosion
// ***************************************
/datum/xeno_mutation/leveled/globadier/self_explosion
	name = "Self Explosion"
	desc = "Toss Grenade можно нацелить на себя: граната упадёт под вами, а время до детонации сократится. Оно не может стать меньше 0.5 секунды."
	level_costs = list(10, 15, 20)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/globadier_self_explosion,
		/datum/status_effect/xeno_enhancement/globadier_self_explosion/two,
		/datum/status_effect/xeno_enhancement/globadier_self_explosion/three,
	)
	level_buff_descs = list(
		"Toss Grenade можно нацелить на себя. Время до детонации сокращается на 0.5 секунды (минимум 0.5 секунды).",
		"Toss Grenade можно нацелить на себя. Время до детонации сокращается на 0.75 секунды (минимум 0.5 секунды).",
		"Toss Grenade можно нацелить на себя. Время до детонации сокращается на 1 секунду (минимум 0.5 секунды).",
	)

/datum/status_effect/xeno_enhancement/globadier_self_explosion
	id = "enhancement_globadier_self_explosion"
	/// Per level, the amount of deciseconds added to the detonation time of grenades thrown at the owner.
	var/list/duration_per_level = list(-0.5 SECONDS, -0.75 SECONDS, -1 SECONDS)
	/// The amount that was added to the ability.
	var/applied_duration = 0

/datum/status_effect/xeno_enhancement/globadier_self_explosion/two
	level = 2

/datum/status_effect/xeno_enhancement/globadier_self_explosion/three
	level = 3

/datum/status_effect/xeno_enhancement/globadier_self_explosion/apply_enhancement()
	var/datum/action/ability/activable/xeno/toss_grenade/grenade_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/toss_grenade]
	if(!grenade_ability)
		return FALSE
	applied_duration = get_level_value(duration_per_level)
	grenade_ability.use_state_flags |= ABILITY_TARGET_SELF
	grenade_ability.bonus_self_detonation_time += applied_duration
	return TRUE

/datum/status_effect/xeno_enhancement/globadier_self_explosion/remove_enhancement()
	var/datum/action/ability/activable/xeno/toss_grenade/grenade_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/toss_grenade]
	if(grenade_ability)
		grenade_ability.use_state_flags &= ~ABILITY_TARGET_SELF
		grenade_ability.bonus_self_detonation_time -= applied_duration
	applied_duration = 0

// ***************************************
// *********** Blood Grenades
// ***************************************
/datum/xeno_mutation/leveled/globadier/blood_grenades
	name = "Blood Grenades"
	desc = "Toss Grenade наносит вам урон в процентах от максимального здоровья и позволяет бросить гранату, даже если их не осталось (кроме healing гранаты)."
	level_costs = list(10, 15, 20)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/globadier_blood_grenades,
		/datum/status_effect/xeno_enhancement/globadier_blood_grenades/two,
		/datum/status_effect/xeno_enhancement/globadier_blood_grenades/three,
	)
	level_buff_descs = list(
		"Бросок без гранат стоит 20% максимального здоровья (кроме healing гранаты).",
		"Бросок без гранат стоит 17.5% максимального здоровья (кроме healing гранаты).",
		"Бросок без гранат стоит 15% максимального здоровья (кроме healing гранаты).",
	)

/datum/status_effect/xeno_enhancement/globadier_blood_grenades
	id = "enhancement_globadier_blood_grenades"
	/// Per level, the percentage (0 to 1) of maximum health lost to throw a grenade while having none.
	var/list/percentage_per_level = list(0.2, 0.175, 0.15)
	/// The amount that was added to the ability.
	var/applied_percentage = 0

/datum/status_effect/xeno_enhancement/globadier_blood_grenades/two
	level = 2

/datum/status_effect/xeno_enhancement/globadier_blood_grenades/three
	level = 3

/datum/status_effect/xeno_enhancement/globadier_blood_grenades/apply_enhancement()
	var/datum/action/ability/activable/xeno/toss_grenade/grenade_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/toss_grenade]
	if(!grenade_ability)
		return FALSE
	applied_percentage = get_level_value(percentage_per_level)
	grenade_ability.health_loss_percentage_per_grenade += applied_percentage
	return TRUE

/datum/status_effect/xeno_enhancement/globadier_blood_grenades/remove_enhancement()
	var/datum/action/ability/activable/xeno/toss_grenade/grenade_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/toss_grenade]
	if(grenade_ability)
		grenade_ability.health_loss_percentage_per_grenade -= applied_percentage
	applied_percentage = 0

// ***************************************
// *********** Repurposed Capacity
// ***************************************
/datum/xeno_mutation/leveled/globadier/repurposed_capacity
	name = "Repurposed Capacity"
	desc = "Toss Grenade хранит меньше гранат, но восстанавливает гранату быстрее."
	level_costs = list(10, 15, 20)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/globadier_repurposed_capacity,
		/datum/status_effect/xeno_enhancement/globadier_repurposed_capacity/two,
		/datum/status_effect/xeno_enhancement/globadier_repurposed_capacity/three,
	)
	level_buff_descs = list(
		"Toss Grenade хранит на 1 гранату меньше, но восстанавливает гранату на 2 секунды быстрее.",
		"Toss Grenade хранит на 2 гранаты меньше, но восстанавливает гранату на 4 секунды быстрее.",
		"Toss Grenade хранит на 3 гранаты меньше, но восстанавливает гранату на 6 секунд быстрее.",
	)

/datum/status_effect/xeno_enhancement/globadier_repurposed_capacity
	id = "enhancement_globadier_repurposed_capacity"
	/// Per level, the amount that is added to the maximum grenade capacity (negative reduces it).
	var/list/capacity_per_level = list(-1, -2, -3)
	/// Per level, the amount of deciseconds that is added to the recharge cooldown of a grenade (negative is faster).
	var/list/recharge_per_level = list(-2 SECONDS, -4 SECONDS, -6 SECONDS)
	/// The capacity that was added to the ability.
	var/applied_capacity = 0
	/// The recharge time that was added to the ability.
	var/applied_recharge = 0

/datum/status_effect/xeno_enhancement/globadier_repurposed_capacity/two
	level = 2

/datum/status_effect/xeno_enhancement/globadier_repurposed_capacity/three
	level = 3

/datum/status_effect/xeno_enhancement/globadier_repurposed_capacity/apply_enhancement()
	var/datum/action/ability/activable/xeno/toss_grenade/grenade_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/toss_grenade]
	if(!grenade_ability)
		return FALSE
	applied_capacity = get_level_value(capacity_per_level)
	applied_recharge = get_level_value(recharge_per_level)
	grenade_ability.max_grenades += applied_capacity
	grenade_ability.grenade_cooldown += applied_recharge
	grenade_ability.current_grenades = min(grenade_ability.current_grenades, grenade_ability.max_grenades)
	grenade_ability.update_button_icon()
	return TRUE

/datum/status_effect/xeno_enhancement/globadier_repurposed_capacity/remove_enhancement()
	var/datum/action/ability/activable/xeno/toss_grenade/grenade_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/toss_grenade]
	if(grenade_ability)
		grenade_ability.max_grenades -= applied_capacity
		grenade_ability.grenade_cooldown -= applied_recharge
		grenade_ability.update_button_icon()
	applied_capacity = 0
	applied_recharge = 0
