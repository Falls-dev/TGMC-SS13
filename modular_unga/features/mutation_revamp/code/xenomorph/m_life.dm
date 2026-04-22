	handle_living_biomass_updates(seconds_per_tick)

/mob/living/carbon/xenomorph/proc/handle_living_biomass_updates(seconds_per_tick)
	var/turf/T = loc
	if(!istype(T)) //Don't accumulate biomass while in things like vents
		return

	// Minions don't accumulate biomass
	if(xeno_caste.caste_flags & CASTE_IS_A_MINION)
		return

	// Get biomass gain rate per minute and convert to per-tick
	var/biomass_gain_rate = get_passive_biomass_gain_rate()
	var/biomass_gain = biomass_gain_rate * seconds_per_tick * XENO_PER_SECOND_LIFE_MOD

	if(biomass_gain <= 0)
		return

	// Cap passive biomass gain at 50 (but allow refunds to exceed this)
	if(biomass < 50)
		biomass = min(biomass + biomass_gain, 50)

/// Calculate passive biomass gain rate per minute
/mob/living/carbon/xenomorph/proc/get_passive_biomass_gain_rate()
	var/biomass_gain_rate = 0

	// Check if we're in Valhalla (testing area) - get +99.9 biomass boost
	var/area/A = get_area(src)
	var/is_valhalla = istype(A, /area/centcom/valhalla)

	// Check if generators are corrupted (like psy points system) - using cached value for performance
	var/corrupted_generators_bonus = 0
	if(GLOB.generators_on_ground > 0)
		var/corrupted_count = hive?.get_cached_corrupted_generators() || 0

		// Only accumulate biomass if we have corrupted generators AND marines on ground (like psy points)
		if(corrupted_count > 0 && (length(GLOB.humans_by_zlevel["2"]) > 0.2 * length(GLOB.alive_human_list_faction[FACTION_TERRAGOV])))
			corrupted_generators_bonus = (corrupted_count / GLOB.generators_on_ground) / 60.0

	// Calculate biomass gain rate
	biomass_gain_rate = biomass_gain_bonus / 60.0 // Psydrain bonus (always works)

	// Add corrupted generators biomass gain if conditions are met
	biomass_gain_rate += corrupted_generators_bonus

	// Hivemind bonus: +0.5 biomass per minute if hivemind is alive - using cached value for performance
	var/has_living_hivemind = hive?.get_cached_hivemind_status() || FALSE

	if(has_living_hivemind)
		biomass_gain_rate += 0.5 / 60.0 // Hivemind bonus: +0.5 per minute

	// Valhalla boost: +99.9 biomass per minute
	if(is_valhalla)
		biomass_gain_rate += 99.9 / 60.0

	// No passive gain if biomass is already above 50
	if(biomass > 50)
		biomass_gain_rate = 0.0

	return biomass_gain_rate
