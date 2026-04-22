	/// Track biomass gained from quickbuild per player (max 15)
	var/list/quickbuild_biomass_gained = list()

			var/total_quickbuild_biomass = 0
		for(var/player_key in quickbuild_biomass_gained)
			total_quickbuild_biomass += quickbuild_biomass_gained[player_key]
		return "BUILT=[total_structures_built] REFUNDED=[total_structures_refunded] BIOMASS=[total_quickbuild_biomass]"


	// Check if we should give biomass (before incrementing counter)
	var/should_give_biomass = active && CHECK_BITFIELD(SSticker.mode?.round_type_flags, MODE_ALLOW_XENO_QUICKBUILD) && get_building_points(the_builder) > 0

	// Give biomass for quickbuild structures (only while quickbuild is active and had points)
	if(should_give_biomass)
		// Check if player hasn't reached the quickbuild biomass limit (15 max)
		var/current_quickbuild_biomass = quickbuild_biomass_gained[player_key] || 0
		if(current_quickbuild_biomass < 15)
			var/biomass_to_give = min(0.025, 15 - current_quickbuild_biomass)
			the_builder.biomass = min(the_builder.biomass + biomass_to_give, 50)
			quickbuild_biomass_gained[player_key] = current_quickbuild_biomass + biomass_to_give
