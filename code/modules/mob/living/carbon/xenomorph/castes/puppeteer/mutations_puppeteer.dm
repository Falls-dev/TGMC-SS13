// Puppeteer Enhancement mutations. Existing mutations converted to levels (see datums/xeno_mutations_leveled.dm).
// Level I keeps the values this build already had, Level II uses the official values for 3 structures.

/datum/xeno_mutation/leveled/puppeteer
	caste_restrictions = list("puppeteer")

// ***************************************
// *********** Flesh For Life
// ***************************************
/datum/xeno_mutation/leveled/puppeteer/flesh_for_life
	name = "Flesh For Life"
	desc = "Если полученный урон должен отправить вас в крит, вы вместо этого тратите плазму. Чем выше уровень, тем меньше плазмы уходит на каждую единицу урона."
	level_names = list("Flesh For Life", "Flesh For Life II")
	level_costs = list(5, 10)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/puppeteer_flesh_for_life,
		/datum/status_effect/xeno_enhancement/puppeteer_flesh_for_life/two,
	)
	level_buff_descs = list(
		"Урон оплачивается плазмой: 1.25 плазмы за 1 урона.",
		"Урон оплачивается плазмой: 1.0 плазмы за 1 урона.",
	)

/datum/status_effect/xeno_enhancement/puppeteer_flesh_for_life
	id = "enhancement_puppeteer_flesh_for_life"
	/// Per level, plasma consumed per point of mitigated damage.
	var/list/plasma_per_damage_per_level = list(1.25, 1.0)

/datum/status_effect/xeno_enhancement/puppeteer_flesh_for_life/two
	level = 2

/datum/status_effect/xeno_enhancement/puppeteer_flesh_for_life/apply_enhancement()
	RegisterSignals(xenomorph_owner, list(COMSIG_XENOMORPH_BRUTE_DAMAGE, COMSIG_XENOMORPH_BURN_DAMAGE), PROC_REF(on_damage))
	return TRUE

/datum/status_effect/xeno_enhancement/puppeteer_flesh_for_life/remove_enhancement()
	UnregisterSignal(xenomorph_owner, list(COMSIG_XENOMORPH_BRUTE_DAMAGE, COMSIG_XENOMORPH_BURN_DAMAGE))

/// If damage would put the owner into critical, spend plasma to reduce that damage.
/datum/status_effect/xeno_enhancement/puppeteer_flesh_for_life/proc/on_damage(datum/source, amount, list/amount_mod)
	SIGNAL_HANDLER
	if(xenomorph_owner.stat == DEAD)
		return
	var/damage_until_threshold = xenomorph_owner.health - xenomorph_owner.get_crit_threshold()
	if(damage_until_threshold > amount)
		return
	var/plasma_per_damage = get_level_value(plasma_per_damage_per_level)
	var/damage_reduction = min(amount, xenomorph_owner.plasma_stored / plasma_per_damage)
	xenomorph_owner.use_plasma(ROUND_UP(damage_reduction * plasma_per_damage))
	amount_mod += damage_reduction

// ***************************************
// *********** Suffocating Presence
// ***************************************
/datum/xeno_mutation/leveled/puppeteer/suffocating_presence
	required_ability_types = list(/datum/action/ability/xeno_action/dreadful_presence)
	name = "Suffocating Presence"
	desc = "Dreadful Presence дополнительно высасывает stamina у людей в зоне действия."
	level_names = list("Suffocating Presence", "Suffocating Presence II")
	level_costs = list(5, 10)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/puppeteer_suffocating_presence,
		/datum/status_effect/xeno_enhancement/puppeteer_suffocating_presence/two,
	)
	level_buff_descs = list(
		"Высасывает 6 stamina в секунду.",
		"Высасывает 8 stamina в секунду.",
	)

/datum/status_effect/xeno_enhancement/puppeteer_suffocating_presence
	id = "enhancement_puppeteer_suffocating_presence"
	/// Per level, stamina damage per second applied by Dreadful Presence.
	var/list/stamina_per_level = list(6, 8)
	var/applied_stamina = 0

/datum/status_effect/xeno_enhancement/puppeteer_suffocating_presence/two
	level = 2

/datum/status_effect/xeno_enhancement/puppeteer_suffocating_presence/apply_enhancement()
	var/datum/action/ability/xeno_action/dreadful_presence/dreadful_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/dreadful_presence]
	if(!dreadful_ability)
		return FALSE
	applied_stamina = get_level_value(stamina_per_level)
	dreadful_ability.stamina_draining += applied_stamina
	return TRUE

/datum/status_effect/xeno_enhancement/puppeteer_suffocating_presence/remove_enhancement()
	var/datum/action/ability/xeno_action/dreadful_presence/dreadful_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/dreadful_presence]
	if(dreadful_ability)
		dreadful_ability.stamina_draining -= applied_stamina
	applied_stamina = 0

// ***************************************
// *********** Shifting Costs
// ***************************************
/datum/xeno_mutation/leveled/puppeteer/shifting_costs
	required_ability_types = list(
		/datum/action/ability/activable/xeno/puppet,
		/datum/action/ability/activable/xeno/puppet_blessings,
	)
	name = "Shifting Costs"
	desc = "Stitch Puppet стоит намного дешевле, но Bestow Blessings стоит дороже."
	level_names = list("Shifting Costs", "Shifting Costs II")
	level_costs = list(5, 10)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/puppeteer_shifting_costs,
		/datum/status_effect/xeno_enhancement/puppeteer_shifting_costs/two,
	)
	level_buff_descs = list(
		"Puppet стоит 20% от обычного, Blessings 130%.",
		"Puppet стоит 20% от обычного, Blessings 120%.",
	)

/datum/status_effect/xeno_enhancement/puppeteer_shifting_costs
	id = "enhancement_puppeteer_shifting_costs"
	/// Multiplier added to Stitch Puppet's initial cost.
	var/puppet_multiplier = -0.8
	/// Per level, multiplier added to Bestow Blessings' initial cost.
	var/list/blessings_multiplier_per_level = list(0.3, 0.2)
	var/applied_puppet_cost = 0
	var/applied_blessings_cost = 0

/datum/status_effect/xeno_enhancement/puppeteer_shifting_costs/two
	level = 2

/datum/status_effect/xeno_enhancement/puppeteer_shifting_costs/apply_enhancement()
	var/datum/action/ability/activable/xeno/puppet/puppet_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/puppet]
	var/datum/action/ability/activable/xeno/puppet_blessings/blessings_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/puppet_blessings]
	if(!puppet_ability || !blessings_ability)
		return FALSE
	applied_puppet_cost = initial(puppet_ability.ability_cost) * puppet_multiplier
	applied_blessings_cost = initial(blessings_ability.ability_cost) * get_level_value(blessings_multiplier_per_level)
	puppet_ability.ability_cost += applied_puppet_cost
	blessings_ability.ability_cost += applied_blessings_cost
	return TRUE

/datum/status_effect/xeno_enhancement/puppeteer_shifting_costs/remove_enhancement()
	var/datum/action/ability/activable/xeno/puppet/puppet_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/puppet]
	if(puppet_ability)
		puppet_ability.ability_cost -= applied_puppet_cost
	var/datum/action/ability/activable/xeno/puppet_blessings/blessings_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/puppet_blessings]
	if(blessings_ability)
		blessings_ability.ability_cost -= applied_blessings_cost
	applied_puppet_cost = 0
	applied_blessings_cost = 0
