	/// The xenomorph who will receive healing.
	var/mob/living/carbon/xenomorph/xenomorph_to_heal
	/// The amount of health to restore for each stack.
	var/healing_per_stack = 0

/datum/status_effect/stacking/intoxicated/on_creation(mob/living/new_owner, stacks_to_apply, mob/living/carbon/xenomorph/expected_xenomorph_to_heal, expected_healing_per_stack = 0)
	xenomorph_to_heal = expected_xenomorph_to_heal
	healing_per_stack = expected_healing_per_stack
	xenomorph_to_heal = null
	if(healing_per_stack && xenomorph_to_heal?.Adjacent(debuff_owner))
		var/amount_to_heal = stacks * healing_per_stack
		HEAL_XENO_DAMAGE(xenomorph_to_heal, amount_to_heal, FALSE)
