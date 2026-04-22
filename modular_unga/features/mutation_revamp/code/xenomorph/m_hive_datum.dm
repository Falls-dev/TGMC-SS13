	// Cached values for performance optimization in get_passive_biomass_gain_rate()
	/// Cached count of corrupted generators for this hive (updated when generators change state)
	var/cached_corrupted_generators = 0
	/// Last time cached_corrupted_generators was updated
	var/last_generator_cache_update = 0
	/// Cache update frequency in ticks (30 seconds = ~300 ticks at standard tick rate)
	var/generator_cache_ttl = 300

	/// Cached hivemind status for this hive (updated when hiveminds die/spawn)
	var/cached_has_living_hivemind = FALSE
	/// Last time cached_has_living_hivemind was updated
	var/last_hivemind_cache_update = 0
	/// Hivemind cache update frequency in ticks (10 seconds = ~100 ticks)
	var/hivemind_cache_ttl = 100

			"mutations" = get_mutations_summary(xeno),

	.["user_biomass"] = isxeno(user) ? xeno_user.biomass : 0
	.["user_max_biomass"] = isxeno(user) ? (xeno_user.biomass > 50 ? xeno_user.biomass : 50) : 0

		if("Mutations")
			if(!isxeno(usr))
				return
			var/mob/living/carbon/xenomorph/xeno = usr
			if(!GLOB.mutation_menu)
				GLOB.mutation_menu = new(xeno)
			else
				GLOB.mutation_menu.xeno_owner = xeno
			GLOB.mutation_menu.ui_interact(usr)

	// Invalidate hivemind cache if the added xeno is a hivemind
	if(isxenohivemind(X))
		update_hivemind_cache()
	// Invalidate hivemind cache if the dead xeno was a hivemind
	if(isxenohivemind(dead_xeno))
		update_hivemind_cache()
/// Returns a summary of mutations by category for a xenomorph
/datum/hive_status/proc/get_mutations_summary(mob/living/carbon/xenomorph/xeno)
	if(!xeno || !length(xeno.purchased_mutations))
		return "None"

	var/survival_count = 0
	var/offensive_count = 0
	var/specialized_count = 0
	var/enhancement_count = 0

	for(var/mutation_name in xeno.purchased_mutations)
		var/datum/xeno_mutation/mutation = get_xeno_mutation_by_name(mutation_name)
		if(!mutation)
			continue
		switch(mutation.category)
			if("Survival")
				survival_count++
			if("Offensive")
				offensive_count++
			if("Specialized")
				specialized_count++
			if("Enhancement")
				enhancement_count++

	return "[survival_count] S; [offensive_count] O; [specialized_count] C; [enhancement_count] E"

// ***************************************
// *********** Cache Updates for Performance
// ***************************************

/// Update cached corrupted generator count for this hive
/datum/hive_status/proc/update_corrupted_generators_cache()
	var/corrupted_count = 0
	if(GLOB.generators_on_ground > 0)
		for(var/obj/machinery/power/geothermal/generator in GLOB.machines)
			if(generator.corrupted == hivenumber && generator.corruption_on)
				corrupted_count++

	cached_corrupted_generators = corrupted_count
	last_generator_cache_update = world.time

/// Update cached hivemind status for this hive
/datum/hive_status/proc/update_hivemind_cache()
	var/has_living_hivemind = FALSE
	for(var/mob/living/carbon/xenomorph/hivemind/hivemind AS in GLOB.alive_xeno_list_hive[hivenumber])
		if(isxenohivemind(hivemind) && !QDELETED(hivemind))
			has_living_hivemind = TRUE
			break

	cached_has_living_hivemind = has_living_hivemind
	last_hivemind_cache_update = world.time

/// Get cached corrupted generator count, updating cache if needed
/datum/hive_status/proc/get_cached_corrupted_generators()
	if(world.time - last_generator_cache_update > generator_cache_ttl)
		update_corrupted_generators_cache()
	return cached_corrupted_generators

/// Get cached hivemind status, updating cache if needed
/datum/hive_status/proc/get_cached_hivemind_status()
	if(world.time - last_hivemind_cache_update > hivemind_cache_ttl)
		update_hivemind_cache()
	return cached_has_living_hivemind
