// Bull Enhancement mutations. Ported from the official Shell/Spur/Veil mutations (Unstoppable, Speed Demon, Railgun).
// The official Bull charges by building up steps (ready_charge/bull_charge), which this build does not use: here the Bull has the timed
// Acid Charge, Headbutt Charge and Gore Charge. The values of the official 1/2/3 structures are therefore converted to this system:
// - Unstoppable: immunity after (max steps - N) of 10 steps, so after 90/80/70% of the duration of the charge.
// - Speed Demon: +0.02/0.04/0.06 speed per step over 10 steps, so +0.2/0.4/0.6 speed during the whole charge. Plasma cost is doubled like the official one.
// - Railgun: +4/8/12 steps on 10 steps, so a charge lasts 40/80/120% longer.
// See datums/xeno_mutations_leveled.dm.

/datum/xeno_mutation/leveled/bull
	caste_restrictions = list("bull")
	required_ability_types = list(
		/datum/action/ability/xeno_action/acid_charge,
		/datum/action/ability/xeno_action/headbutt,
		/datum/action/ability/xeno_action/gore,
	)

// ***************************************
// *********** Unstoppable
// ***************************************
/datum/xeno_mutation/leveled/bull/unstoppable
	name = "Unstoppable"
	desc = "Во время рывка вы становитесь полностью невосприимчивы к стаггеру, как только рывок длится достаточно долго."
	level_costs = list(10, 15, 20)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/bull_unstoppable,
		/datum/status_effect/xeno_enhancement/bull_unstoppable/two,
		/datum/status_effect/xeno_enhancement/bull_unstoppable/three,
	)
	level_buff_descs = list(
		"Иммунитет к стаггеру в Acid Charge, Headbutt Charge и Gore Charge после 90% их длительности.",
		"Иммунитет к стаггеру в Acid Charge, Headbutt Charge и Gore Charge после 80% их длительности.",
		"Иммунитет к стаггеру в Acid Charge, Headbutt Charge и Gore Charge после 70% их длительности.",
	)

/datum/status_effect/xeno_enhancement/bull_unstoppable
	id = "enhancement_bull_unstoppable"
	/// Per level, the fraction of the charge duration after which the stagger immunity starts.
	var/list/fraction_per_level = list(0.9, 0.8, 0.7)

/datum/status_effect/xeno_enhancement/bull_unstoppable/two
	level = 2

/datum/status_effect/xeno_enhancement/bull_unstoppable/three
	level = 3

/datum/status_effect/xeno_enhancement/bull_unstoppable/apply_enhancement()
	xenomorph_owner.charge_stagger_immunity_fraction = get_level_value(fraction_per_level)
	return TRUE

/datum/status_effect/xeno_enhancement/bull_unstoppable/remove_enhancement()
	xenomorph_owner.charge_stagger_immunity_fraction = 0
	xenomorph_owner.on_charge_end()

// ***************************************
// *********** Speed Demon
// ***************************************
/datum/xeno_mutation/leveled/bull/speed_demon
	name = "Speed Demon"
	desc = "Acid Charge, Headbutt Charge и Gore Charge стоят вдвое больше плазмы, но скорость во время рывка увеличена."
	level_costs = list(10, 15, 20)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/bull_speed_demon,
		/datum/status_effect/xeno_enhancement/bull_speed_demon/two,
		/datum/status_effect/xeno_enhancement/bull_speed_demon/three,
	)
	level_buff_descs = list(
		"Acid Charge, Headbutt Charge и Gore Charge стоят вдвое больше плазмы. +0.2 скорости во время рывка.",
		"Acid Charge, Headbutt Charge и Gore Charge стоят вдвое больше плазмы. +0.4 скорости во время рывка.",
		"Acid Charge, Headbutt Charge и Gore Charge стоят вдвое больше плазмы. +0.6 скорости во время рывка.",
	)

/datum/status_effect/xeno_enhancement/bull_speed_demon
	id = "enhancement_bull_speed_demon"
	/// Per level, the speed that is added to the charges.
	var/list/speed_per_level = list(0.2, 0.4, 0.6)
	/// The speed that was added to the xenomorph.
	var/applied_speed = 0
	/// The plasma cost that was added to each charge, by the type of the charge.
	var/list/applied_costs

/datum/status_effect/xeno_enhancement/bull_speed_demon/two
	level = 2

/datum/status_effect/xeno_enhancement/bull_speed_demon/three
	level = 3

/datum/status_effect/xeno_enhancement/bull_speed_demon/apply_enhancement()
	applied_costs = list()
	add_cost(/datum/action/ability/xeno_action/acid_charge)
	add_cost(/datum/action/ability/xeno_action/headbutt)
	add_cost(/datum/action/ability/xeno_action/gore)
	if(!length(applied_costs))
		applied_costs = null
		return FALSE
	applied_speed = get_level_value(speed_per_level)
	xenomorph_owner.charge_speed_bonus += applied_speed
	return TRUE

/datum/status_effect/xeno_enhancement/bull_speed_demon/remove_enhancement()
	remove_cost(/datum/action/ability/xeno_action/acid_charge)
	remove_cost(/datum/action/ability/xeno_action/headbutt)
	remove_cost(/datum/action/ability/xeno_action/gore)
	applied_costs = null
	xenomorph_owner.charge_speed_bonus -= applied_speed
	applied_speed = 0

/// Doubles the plasma cost of the given charge, if the owner has it.
/datum/status_effect/xeno_enhancement/bull_speed_demon/proc/add_cost(charge_path)
	var/datum/action/ability/xeno_action/charge_ability = xenomorph_owner.actions_by_path[charge_path]
	if(!charge_ability)
		return
	var/added_cost = initial(charge_ability.ability_cost)
	charge_ability.ability_cost += added_cost
	applied_costs[charge_path] = added_cost

/// Reverts exactly what add_cost() added to the given charge.
/datum/status_effect/xeno_enhancement/bull_speed_demon/proc/remove_cost(charge_path)
	if(!applied_costs || !applied_costs[charge_path])
		return
	var/datum/action/ability/xeno_action/charge_ability = xenomorph_owner.actions_by_path[charge_path]
	if(!charge_ability)
		return
	charge_ability.ability_cost -= applied_costs[charge_path]

// ***************************************
// *********** Railgun
// ***************************************
/datum/xeno_mutation/leveled/bull/railgun
	name = "Railgun"
	desc = "Увеличивает длительность Acid Charge, Headbutt Charge и Gore Charge."
	level_costs = list(10, 15, 20)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/bull_railgun,
		/datum/status_effect/xeno_enhancement/bull_railgun/two,
		/datum/status_effect/xeno_enhancement/bull_railgun/three,
	)
	level_buff_descs = list(
		"Acid Charge, Headbutt Charge и Gore Charge длятся на 40% дольше.",
		"Acid Charge, Headbutt Charge и Gore Charge длятся на 80% дольше.",
		"Acid Charge, Headbutt Charge и Gore Charge длятся на 120% дольше.",
	)

/datum/status_effect/xeno_enhancement/bull_railgun
	id = "enhancement_bull_railgun"
	/// Per level, the fraction that is added to the duration of the charges.
	var/list/duration_per_level = list(0.4, 0.8, 1.2)
	/// The amount that was added to the xenomorph.
	var/applied_duration = 0

/datum/status_effect/xeno_enhancement/bull_railgun/two
	level = 2

/datum/status_effect/xeno_enhancement/bull_railgun/three
	level = 3

/datum/status_effect/xeno_enhancement/bull_railgun/apply_enhancement()
	applied_duration = get_level_value(duration_per_level)
	xenomorph_owner.charge_duration_bonus += applied_duration
	return TRUE

/datum/status_effect/xeno_enhancement/bull_railgun/remove_enhancement()
	xenomorph_owner.charge_duration_bonus -= applied_duration
	applied_duration = 0
