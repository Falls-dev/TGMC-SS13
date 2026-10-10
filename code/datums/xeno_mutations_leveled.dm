// ***************************************
// *********** Leveled mutations
// ***************************************
// A leveled mutation is the same mechanism as the Carapace I/II/III chain in xeno_mutations.dm:
// one /datum/xeno_mutation per level, linked with parent_name / child_name, bought with biomass through
// /datum/mutation_menu/purchase_mutation(), where buying a level replaces the status effect of the previous one.
// The only difference is that the per-level datums are generated from a single template instead of being written out by hand.
//
// Adding a new leveled mutation needs only:
// 1. A subtype of /datum/xeno_mutation/leveled (see castes/bull/mutations_bull.dm) filling level_costs / level_effect_types / level_buff_descs.
// 2. A /datum/status_effect/xeno_enhancement subtype for the effect, plus a "/two" and "/three" subtype that only set `level` (see xeno_enhancements.dm).

/datum/xeno_mutation/leveled
	category = "Enhancement"
	icon_state = "xenobuff_generic"
	/// Display names of the levels. If a level has no entry, "[name] [roman numeral]" is used.
	var/list/level_names = list()
	/// Biomass cost of each level. The number of entries is the level cap.
	var/list/level_costs = list()
	/// Status effect type of each level. Must have the same number of entries as level_costs.
	var/list/level_effect_types = list()
	/// Description of each level. If a level has no entry, `desc` is used.
	var/list/level_descs = list()
	/// Short description of the numbers of each level, shown in the menu and on the status alert.
	var/list/level_buff_descs = list()

/// Returns the display name of the given level.
/datum/xeno_mutation/leveled/proc/get_level_name(level)
	if(length(level_names) >= level && level_names[level])
		return level_names[level]
	var/static/list/numerals = list("I", "II", "III", "IV", "V")
	return "[name] [numerals[level]]"

/// Builds the registered per-level mutations of this template. Returns an empty list for abstract templates and invalid definitions.
/datum/xeno_mutation/leveled/proc/build_levels()
	. = list()
	var/max_level = length(level_costs)
	if(!max_level && !length(level_effect_types)) // Abstract template, nothing to build.
		return
	if(!max_level || length(level_effect_types) != max_level)
		stack_trace("Leveled mutation [type] has mismatching level_costs ([max_level]) and level_effect_types ([length(level_effect_types)]).")
		return
	for(var/level in 1 to max_level)
		var/datum/xeno_mutation/level_mutation = new /datum/xeno_mutation()
		level_mutation.name = get_level_name(level)
		level_mutation.desc = (length(level_descs) >= level && level_descs[level]) ? level_descs[level] : desc
		level_mutation.category = category
		level_mutation.cost = level_costs[level]
		level_mutation.cost_change = cost_change.Copy()
		level_mutation.icon_state = icon_state
		level_mutation.tier = level
		level_mutation.parent_name = (level > 1) ? get_level_name(level - 1) : null
		level_mutation.child_name = (level < max_level) ? get_level_name(level + 1) : null
		level_mutation.status_effect_type = level_effect_types[level]
		level_mutation.buff_desc = (length(level_buff_descs) >= level) ? level_buff_descs[level] : ""
		level_mutation.caste_restrictions = caste_restrictions.Copy()
		level_mutation.caste_type_restrictions = caste_type_restrictions.Copy()
		level_mutation.caste_type_exclusions = caste_type_exclusions.Copy()
		level_mutation.required_ability_types = required_ability_types.Copy()
		level_mutation.base_name = name
		level_mutation.conflicting_base_names = conflicting_base_names.Copy()
		. += level_mutation
