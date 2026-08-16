#define STATUS_EFFECT_PUPPETEER_FLESH_FOR_LIFE /datum/status_effect/puppeteer/flesh_for_life
#define STATUS_EFFECT_PUPPETEER_SUFFOCATING_PRESENCE /datum/status_effect/puppeteer/suffocating_presence
#define STATUS_EFFECT_PUPPETEER_SHIFTING_COSTS /datum/status_effect/puppeteer/shifting_costs

/datum/xeno_mutation/puppeteer
	category = "Enhancement"
	caste_restrictions = list("puppeteer")

/datum/status_effect/puppeteer
	duration = -1
	status_type = STATUS_EFFECT_UNIQUE
	/// The xenomorph that owns this status effect.
	var/mob/living/carbon/xenomorph/xenomorph_owner

/datum/xeno_mutation/puppeteer/flesh_for_life
	name = "Flesh For Life"
	desc = "If damage taken would put you into critical, lose plasma instead."
	cost = 10
	icon_state = "xenobuff_generic"
	tier = 1
	parent_name = null
	child_name = null
	status_effect_type = STATUS_EFFECT_PUPPETEER_FLESH_FOR_LIFE
	buff_desc = "Critical damage is paid in plasma (1.25 plasma per damage)."

/atom/movable/screen/alert/status_effect/puppeteer/flesh_for_life
	name = "Flesh For Life"
	desc = "Critical damage is paid in plasma instead."
	icon_state = "xenobuff_attack"

/datum/status_effect/puppeteer/flesh_for_life
	id = "upgrade_puppeteer_flesh_for_life"
	alert_type = /atom/movable/screen/alert/status_effect/puppeteer/flesh_for_life
	/// Plasma consumed per point of mitigated damage.
	var/plasma_per_damage = 1.25

/datum/status_effect/puppeteer/flesh_for_life/on_apply()
	xenomorph_owner = owner
	RegisterSignals(xenomorph_owner, list(COMSIG_XENOMORPH_BRUTE_DAMAGE, COMSIG_XENOMORPH_BURN_DAMAGE), PROC_REF(on_damage))
	return TRUE

/datum/status_effect/puppeteer/flesh_for_life/on_remove()
	UnregisterSignal(xenomorph_owner, list(COMSIG_XENOMORPH_BRUTE_DAMAGE, COMSIG_XENOMORPH_BURN_DAMAGE))
	return ..()

/// If damage would put the owner into critical, spend plasma to reduce that damage.
/datum/status_effect/puppeteer/flesh_for_life/proc/on_damage(datum/source, amount, list/amount_mod)
	SIGNAL_HANDLER
	if(xenomorph_owner.stat == DEAD)
		return
	var/damage_until_threshold = xenomorph_owner.health - xenomorph_owner.get_crit_threshold()
	if(damage_until_threshold > amount)
		return
	var/damage_reduction = min(amount, xenomorph_owner.plasma_stored / plasma_per_damage)
	xenomorph_owner.use_plasma(ROUND_UP(damage_reduction * plasma_per_damage))
	amount_mod += damage_reduction

/datum/xeno_mutation/puppeteer/suffocating_presence
	name = "Suffocating Presence"
	desc = "Dreadful Presence also applies a stamina drain over time."
	cost = 10
	icon_state = "xenobuff_generic"
	tier = 1
	parent_name = null
	child_name = null
	status_effect_type = STATUS_EFFECT_PUPPETEER_SUFFOCATING_PRESENCE
	buff_desc = "Dreadful Presence drains 6 stamina per second."

/atom/movable/screen/alert/status_effect/puppeteer/suffocating_presence
	name = "Suffocating Presence"
	desc = "Dreadful Presence drains stamina over time."
	icon_state = "xenobuff_attack"

/datum/status_effect/puppeteer/suffocating_presence
	id = "upgrade_puppeteer_suffocating_presence"
	alert_type = /atom/movable/screen/alert/status_effect/puppeteer/suffocating_presence
	/// Stamina damage per second applied by Dreadful Presence.
	var/stamina_damage = 6

/datum/status_effect/puppeteer/suffocating_presence/on_apply()
	xenomorph_owner = owner
	var/datum/action/ability/xeno_action/dreadful_presence/dreadful_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/dreadful_presence]
	if(!dreadful_ability)
		return FALSE
	dreadful_ability.stamina_draining += stamina_damage
	return TRUE

/datum/status_effect/puppeteer/suffocating_presence/on_remove()
	var/datum/action/ability/xeno_action/dreadful_presence/dreadful_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/dreadful_presence]
	if(dreadful_ability)
		dreadful_ability.stamina_draining -= stamina_damage
	return ..()

/datum/xeno_mutation/puppeteer/shifting_costs
	name = "Shifting Costs"
	desc = "Stitch Puppet is much cheaper, but Bestow Blessings costs more."
	cost = 10
	icon_state = "xenobuff_generic"
	tier = 1
	parent_name = null
	child_name = null
	status_effect_type = STATUS_EFFECT_PUPPETEER_SHIFTING_COSTS
	buff_desc = "Puppet costs 20% of original; Blessings cost 130%."

/atom/movable/screen/alert/status_effect/puppeteer/shifting_costs
	name = "Shifting Costs"
	desc = "Puppet is cheaper; Blessings cost more."
	icon_state = "xenobuff_attack"

/datum/status_effect/puppeteer/shifting_costs
	id = "upgrade_puppeteer_shifting_costs"
	alert_type = /atom/movable/screen/alert/status_effect/puppeteer/shifting_costs
	/// Multiplier added to Stitch Puppet's initial cost.
	var/puppet_multiplier = -0.8
	/// Multiplier added to Bestow Blessings' initial cost.
	var/blessings_multiplier = 0.3

/datum/status_effect/puppeteer/shifting_costs/on_apply()
	xenomorph_owner = owner
	var/datum/action/ability/activable/xeno/puppet/puppet_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/puppet]
	if(!puppet_ability)
		return FALSE
	var/datum/action/ability/activable/xeno/puppet_blessings/blessings_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/puppet_blessings]
	if(!blessings_ability)
		return FALSE
	puppet_ability.ability_cost += initial(puppet_ability.ability_cost) * puppet_multiplier
	blessings_ability.ability_cost += initial(blessings_ability.ability_cost) * blessings_multiplier
	return TRUE

/datum/status_effect/puppeteer/shifting_costs/on_remove()
	var/datum/action/ability/activable/xeno/puppet/puppet_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/puppet]
	if(puppet_ability)
		puppet_ability.ability_cost -= initial(puppet_ability.ability_cost) * puppet_multiplier
	var/datum/action/ability/activable/xeno/puppet_blessings/blessings_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/puppet_blessings]
	if(blessings_ability)
		blessings_ability.ability_cost -= initial(blessings_ability.ability_cost) * blessings_multiplier
	return ..()
