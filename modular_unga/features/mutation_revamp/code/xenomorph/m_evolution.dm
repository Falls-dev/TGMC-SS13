	new_xeno.biomass_gain_bonus = biomass_gain_bonus
	if(new_xeno.hunter_data)
		new_xeno.hunter_data.clean_data()
		qdel(new_xeno.hunter_data)
		new_xeno.hunter_data = hunter_data
		hunter_data = null

	new_xeno.purchased_mutations = purchased_mutations.Copy()

	var/total_refund = 0
	var/list/refunded_mutations = list()

	// Initialize mutations if not already done
	initialize_xeno_mutations()

	// Calculate refund for all purchased mutations
	for(var/mutation_name in new_xeno.purchased_mutations)
		var/datum/xeno_mutation/mutation_datum = get_xeno_mutation_by_name(mutation_name)
		if(mutation_datum)
			// Use the OLD caste for refund calculation (the caste that originally purchased the mutation)
			var/refund_cost = get_mutation_cost_for_caste(mutation_datum, src.xeno_caste.caste_name)
			total_refund += refund_cost
			refunded_mutations += mutation_name

	// Save mutations list before clearing for later restoration
	var/list/saved_mutations = new_xeno.purchased_mutations.Copy()

	// Clear all mutations and refund biomass
	new_xeno.purchased_mutations.Cut()
	new_xeno.upgrades_holder.Cut()

	// Remove all mutation status effects from the NEW xenomorph first
	for(var/mutation_name in saved_mutations)
		var/datum/xeno_mutation/mutation_datum = get_xeno_mutation_by_name(mutation_name)
		if(mutation_datum && mutation_datum.status_effect_type)
			new_xeno.remove_status_effect(mutation_datum.status_effect_type)

	// Remove all mutation abilities
	for(var/datum/action/ability/xeno_action/mutation/ability in new_xeno.actions)
		if(istype(ability, /datum/action/ability/xeno_action/mutation))
			ability.remove_action(new_xeno)

	if(total_refund > 0)
		new_xeno.biomass += total_refund
		to_chat(new_xeno, span_xenonotice("[total_refund] biomass returned."))

	// Restore mutations after upgrade (only if no biomass was refunded)
	if(total_refund == 0)
		for(var/mutation_name in saved_mutations)
			var/datum/xeno_mutation/mutation_datum = get_xeno_mutation_by_name(mutation_name)
			if(mutation_datum)
				// Restore purchased mutations list (regardless of availability for new caste)
				new_xeno.purchased_mutations += mutation_name

				// Apply status effect if mutation has one
				if(mutation_datum.status_effect_type)
					new_xeno.apply_status_effect(mutation_datum.status_effect_type)
					new_xeno.upgrades_holder.Add(mutation_datum.status_effect_type)

				// Add ability if mutation has one
				if(mutation_datum.ability_type)
					var/datum/action/ability/ability = new mutation_datum.ability_type()
					// Check if it's a mutation ability and call set_mutation_power
					if(istype(ability, /datum/action/ability/xeno_action/mutation))
						var/datum/action/ability/xeno_action/mutation/mutation_ability = ability
						mutation_ability.set_mutation_power(mutation_datum.tier)
					ability.give_action(new_xeno)
					new_xeno.upgrades_holder.Add(mutation_datum.ability_type)

	// Update enhancement HUD
	new_xeno.hud_set_enhancement()

	// Remove all mutation status effects from the old xenomorph before deletion
	for(var/mutation_name in src.purchased_mutations)
		var/datum/xeno_mutation/mutation_datum = get_xeno_mutation_by_name(mutation_name)
		if(mutation_datum && mutation_datum.status_effect_type)
			src.remove_status_effect(mutation_datum.status_effect_type)
