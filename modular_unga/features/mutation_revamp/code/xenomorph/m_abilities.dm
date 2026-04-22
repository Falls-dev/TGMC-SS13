
	// Caster gets 5 biomass immediately
	xeno_owner.biomass = min(xeno_owner.biomass + 5, 50)

	// All living xenos (including caster) get +0.05 passive biomass gain
	for(var/mob/living/carbon/xenomorph/xeno AS in GLOB.alive_xeno_list_hive[xeno_owner.hivenumber])
		if(xeno.xeno_caste.caste_flags & CASTE_IS_A_MINION)
			continue
		xeno.biomass_gain_bonus += 0.05

	for(var/mob/living/carbon/xenomorph/xeno AS in GLOB.alive_xeno_list_hive[xeno_owner.hivenumber])
		if(xeno.xeno_caste.caste_flags & CASTE_IS_A_MINION)
			continue
		xeno.biomass_gain_bonus += 0.05
