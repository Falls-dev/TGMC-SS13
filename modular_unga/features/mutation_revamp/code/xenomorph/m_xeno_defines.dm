	hud_possible = list(HEALTH_HUD_XENO, PLASMA_HUD, PHEROMONE_HUD, ENHANCEMENT_HUD, XENO_RANK_HUD, QUEEN_OVERWATCH_HUD, ARMOR_SUNDER_HUD, XENO_DEBUFF_HUD, XENO_FIRE_HUD, XENO_BANISHED_HUD, XENO_BLESSING_HUD, XENO_EVASION_HUD, XENO_PRIMO_HUD, HUNTER_HUD)

	///Bonus to passive biomass gain rate (added to base rate)
	var/biomass_gain_bonus = 0

	///Bonus to passive biomass gain rate (added to base rate)
	var/biomass_gain_bonus = 0

	///which reagent to inject with mutation-based toxin attacks (separate from selected_reagent)
	var/datum/reagent/toxin/mutation_toxin_reagent = /datum/reagent/toxin/xeno_transvitox
	///which trail type to leave with mutation-based trail ability
	var/obj/mutation_trail_type = /obj/effect/xenomorph/spray
