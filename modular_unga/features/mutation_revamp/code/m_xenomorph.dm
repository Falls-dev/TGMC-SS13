	hud_set_enhancement()

// Helper function to check if xenomorph has any enhancement mutations
/mob/living/carbon/xenomorph/proc/has_enhancement_mutation()
	if(!length(purchased_mutations))
		return FALSE

	for(var/mutation_name in purchased_mutations)
		var/datum/xeno_mutation/mutation = get_xeno_mutation_by_name(mutation_name)
		if(mutation && mutation.category == "Enhancement")
			return TRUE
	return FALSE

/mob/living/carbon/xenomorph/proc/hud_set_enhancement()
	var/image/holder = hud_list[ENHANCEMENT_HUD]
	if(!holder)
		return
	holder.overlays.Cut()
	holder.icon_state = ""
	if(stat != DEAD && has_enhancement_mutation())
		holder.overlays += image('icons/mob/hud/aura.dmi', src, "enhancement_mutation")

	hud_list[ENHANCEMENT_HUD] = holder
