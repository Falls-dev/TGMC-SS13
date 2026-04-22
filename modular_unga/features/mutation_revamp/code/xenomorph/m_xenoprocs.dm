		// Don't remove mutation abilities as they should persist through upgrades
		if(!istype(action_already_added, /datum/action/ability/xeno_action/mutation))
			action_already_added.remove_action(src)
		else
			// Add mutation abilities back to mob_abilities list so they persist
			mob_abilities.Add(action_already_added)


	. += "Biomass: [biomass]/[biomass > 50 ? biomass : 50]"

	var/old_sunder = sunder

	SEND_SIGNAL(src, COMSIG_XENOMORPH_SUNDER_CHANGE, old_sunder, sunder)
	return sunder - old_sunder // The real difference in sunder. Negative: real loss in sunder. Positive: real gain in sunder.

	if(xeno_caste.caste_flags & CASTE_IS_A_MINION)
		to_chat(src, span_warning("We are too primitive to understand mutations."))
		return

	var/datum/mutation_menu/menu = new(src)
	menu.ui_interact(src)

// Old browser-based mutation system removed - replaced with TGUI

// Old mutation system removed - replaced with TGUI
