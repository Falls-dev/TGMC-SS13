// Pyrogen Enhancement mutations. Ported from the official Shell/Spur/Veil mutations (Flame Cloak, Only Fire, Burnt Wounds).
// Levels I/II/III use the official values for 1/2/3 structures. See datums/xeno_mutations_leveled.dm.

/datum/xeno_mutation/leveled/pyrogen
	caste_restrictions = list("pyrogen")

// ***************************************
// *********** Flame Cloak
// ***************************************
/datum/xeno_mutation/leveled/pyrogen/flame_cloak
	name = "Flame Cloak"
	desc = "Пока вы стоите в огне, вы получаете дополнительную броню от всех типов урона."
	level_costs = list(5, 10, 15)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/pyrogen_flame_cloak,
		/datum/status_effect/xeno_enhancement/pyrogen_flame_cloak/two,
		/datum/status_effect/xeno_enhancement/pyrogen_flame_cloak/three,
	)
	level_buff_descs = list(
		"Стоя в огне: броня +5 (все типы).",
		"Стоя в огне: броня +10 (все типы).",
		"Стоя в огне: броня +15 (все типы).",
	)

/datum/status_effect/xeno_enhancement/pyrogen_flame_cloak
	id = "enhancement_pyrogen_flame_cloak"
	/// Per level, the armor that is given for being ontop of any fire.
	var/list/armor_per_level = list(5, 10, 15)
	/// The attached armor that been given, if any.
	var/datum/armor/attached_armor
	/// The fire that granted the armor.
	var/obj/fire/armor_granting_fire

/datum/status_effect/xeno_enhancement/pyrogen_flame_cloak/two
	level = 2

/datum/status_effect/xeno_enhancement/pyrogen_flame_cloak/three
	level = 3

/datum/status_effect/xeno_enhancement/pyrogen_flame_cloak/apply_enhancement()
	RegisterSignal(xenomorph_owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_movement))
	grant_armor(get_fire_in_turf(get_turf(xenomorph_owner)))
	return TRUE

/datum/status_effect/xeno_enhancement/pyrogen_flame_cloak/remove_enhancement()
	UnregisterSignal(xenomorph_owner, COMSIG_MOVABLE_MOVED)
	revoke_armor()

/// Grants armor.
/datum/status_effect/xeno_enhancement/pyrogen_flame_cloak/proc/grant_armor(obj/fire/chosen_fire)
	if(attached_armor || !chosen_fire)
		return
	var/total_armor = get_level_value(armor_per_level)
	attached_armor = getArmor(total_armor, total_armor, total_armor, total_armor, total_armor, total_armor, total_armor, total_armor)
	xenomorph_owner.soft_armor = xenomorph_owner.soft_armor.attachArmor(attached_armor)
	set_armor_granting_fire(chosen_fire)

/// Removes armor.
/datum/status_effect/xeno_enhancement/pyrogen_flame_cloak/proc/revoke_armor()
	if(!attached_armor)
		set_armor_granting_fire()
		return
	xenomorph_owner.soft_armor = xenomorph_owner.soft_armor.detachArmor(attached_armor)
	attached_armor = null
	set_armor_granting_fire()

/// Sets signals for the chosen fire.
/datum/status_effect/xeno_enhancement/pyrogen_flame_cloak/proc/set_armor_granting_fire(obj/fire/chosen_fire)
	if(armor_granting_fire)
		UnregisterSignal(armor_granting_fire, COMSIG_QDELETING)
		armor_granting_fire = null
	if(chosen_fire)
		armor_granting_fire = chosen_fire
		RegisterSignal(armor_granting_fire, COMSIG_QDELETING, PROC_REF(on_fire_qdel))

/// Gets the longest lasting fire on a turf.
/datum/status_effect/xeno_enhancement/pyrogen_flame_cloak/proc/get_fire_in_turf(turf/turf_to_search)
	var/obj/fire/longest_lasting_fire
	for(var/obj/fire/fire_in_turf in turf_to_search)
		if(QDELING(fire_in_turf))
			continue
		if(!longest_lasting_fire)
			longest_lasting_fire = fire_in_turf
			continue
		var/current_duration = longest_lasting_fire.burn_ticks / max(1, longest_lasting_fire.burn_decay)
		var/opposing_duration = fire_in_turf.burn_ticks / max(1, fire_in_turf.burn_decay)
		if(current_duration >= opposing_duration)
			continue
		longest_lasting_fire = fire_in_turf
	return longest_lasting_fire

/// Revokes / grants armor based on whether the owner's location has a fire. Assigns a fire that will re-proc this if it is deleted.
/datum/status_effect/xeno_enhancement/pyrogen_flame_cloak/proc/set_armor_adjustingly()
	var/obj/fire/fire_here = get_fire_in_turf(get_turf(xenomorph_owner))
	if(!attached_armor)
		if(fire_here)
			grant_armor(fire_here)
		return
	if(!fire_here)
		revoke_armor()
		return
	set_armor_granting_fire(fire_here)

/// Called when the owner moves.
/datum/status_effect/xeno_enhancement/pyrogen_flame_cloak/proc/on_movement(datum/source, atom/old_loc, movement_dir, forced, list/old_locs)
	SIGNAL_HANDLER
	set_armor_adjustingly()

/// Called when the fire associated with the armor is deleted.
/datum/status_effect/xeno_enhancement/pyrogen_flame_cloak/proc/on_fire_qdel(datum/source, force)
	SIGNAL_HANDLER
	// The fire is still on the turf while it is being deleted, so it is ignored by get_fire_in_turf() through QDELING().
	set_armor_adjustingly()

// ***************************************
// *********** Only Fire
// ***************************************
/datum/xeno_mutation/leveled/pyrogen/only_fire
	required_ability_types = list(/datum/action/ability/activable/xeno/charge/fire_charge)
	name = "Only Fire"
	desc = "Fire Charge перестаёт наносить урон и тратить стаки Melting Fire, зато пролетает сквозь людей и накладывает на них Melting Fire."
	level_costs = list(5, 10, 15)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/pyrogen_only_fire,
		/datum/status_effect/xeno_enhancement/pyrogen_only_fire/two,
		/datum/status_effect/xeno_enhancement/pyrogen_only_fire/three,
	)
	level_buff_descs = list(
		"Fire Charge без урона, проходит сквозь людей. Цель получает 2 стака Melting Fire.",
		"Fire Charge без урона, проходит сквозь людей. Цель получает 4 стака Melting Fire.",
		"Fire Charge без урона, проходит сквозь людей. Цель получает 6 стаков Melting Fire.",
	)

/datum/status_effect/xeno_enhancement/pyrogen_only_fire
	id = "enhancement_pyrogen_only_fire"
	/// Per level, the melting fire stacks that Fire Charge inflicts.
	var/list/stacks_per_level = list(2, 4, 6)
	/// The amount of stacks that was added to the ability.
	var/applied_stacks = 0

/datum/status_effect/xeno_enhancement/pyrogen_only_fire/two
	level = 2

/datum/status_effect/xeno_enhancement/pyrogen_only_fire/three
	level = 3

/datum/status_effect/xeno_enhancement/pyrogen_only_fire/apply_enhancement()
	var/datum/action/ability/activable/xeno/charge/fire_charge/charge_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/charge/fire_charge]
	if(!charge_ability)
		return FALSE
	charge_ability.should_slash = FALSE
	charge_ability.charge_damage -= initial(charge_ability.charge_damage)
	charge_ability.stack_damage -= initial(charge_ability.stack_damage)
	charge_ability.pierces_mobs = TRUE
	applied_stacks = get_level_value(stacks_per_level)
	charge_ability.stacks_to_add += applied_stacks
	return TRUE

/datum/status_effect/xeno_enhancement/pyrogen_only_fire/remove_enhancement()
	var/datum/action/ability/activable/xeno/charge/fire_charge/charge_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/charge/fire_charge]
	if(charge_ability)
		charge_ability.should_slash = initial(charge_ability.should_slash)
		charge_ability.charge_damage += initial(charge_ability.charge_damage)
		charge_ability.stack_damage += initial(charge_ability.stack_damage)
		charge_ability.pierces_mobs = initial(charge_ability.pierces_mobs)
		charge_ability.stacks_to_add -= applied_stacks
	applied_stacks = 0

// ***************************************
// *********** Burnt Wounds
// ***************************************
/datum/xeno_mutation/leveled/pyrogen/burnt_wounds
	name = "Burnt Wounds"
	desc = "Люди, на которых вы накладываете Melting Fire, хуже лечатся: их лечение брут и берн повреждений снижается."
	level_costs = list(7.5, 12.5, 17.5)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/pyrogen_burnt_wounds,
		/datum/status_effect/xeno_enhancement/pyrogen_burnt_wounds/two,
		/datum/status_effect/xeno_enhancement/pyrogen_burnt_wounds/three,
	)
	level_buff_descs = list(
		"Лечение брут и берн цели -15%.",
		"Лечение брут и берн цели -25%.",
		"Лечение брут и берн цели -35%.",
	)

/datum/status_effect/xeno_enhancement/pyrogen_burnt_wounds
	id = "enhancement_pyrogen_burnt_wounds"
	/// Per level, the percentage (0 to 1) of brute/burn healing that is negated.
	var/list/reduction_per_level = list(0.15, 0.25, 0.35)
	/// The amount that was added to the pyrogen.
	var/applied_reduction = 0

/datum/status_effect/xeno_enhancement/pyrogen_burnt_wounds/two
	level = 2

/datum/status_effect/xeno_enhancement/pyrogen_burnt_wounds/three
	level = 3

/datum/status_effect/xeno_enhancement/pyrogen_burnt_wounds/apply_enhancement()
	if(!isxenopyrogen(xenomorph_owner))
		return FALSE
	var/mob/living/carbon/xenomorph/pyrogen/pyrogen_owner = xenomorph_owner
	applied_reduction = get_level_value(reduction_per_level)
	pyrogen_owner.melting_fire_healing_reduction += applied_reduction
	return TRUE

/datum/status_effect/xeno_enhancement/pyrogen_burnt_wounds/remove_enhancement()
	if(isxenopyrogen(xenomorph_owner))
		var/mob/living/carbon/xenomorph/pyrogen/pyrogen_owner = xenomorph_owner
		pyrogen_owner.melting_fire_healing_reduction -= applied_reduction
	applied_reduction = 0
