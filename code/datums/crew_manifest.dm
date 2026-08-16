GLOBAL_DATUM_INIT(crew_manifest, /datum/crew_manifest, new)

/**
 * TGUI-backed crew manifest. HTML get_manifest() on datacore remains for paper/consoles.
 */
/datum/crew_manifest
	/// Department name -> ordered list of job titles used for sorting/grouping.
	var/list/departments = list()
	/// Squad department names currently present (from SSjob.squads_by_name).
	var/list/squad_departments = list()

/datum/crew_manifest/New()
	. = ..()
	rebuild_departments()

/// Rebuilds department map including live Terragov squad names.
/datum/crew_manifest/proc/rebuild_departments()
	squad_departments = list()
	departments = list()
	departments["Command"] = GLOB.jobs_officers.Copy()
	departments["Auxiliary"] = GLOB.jobs_support.Copy()

	// Per-squad sections (Alpha/Bravo/…) then a catch-all Marines bucket — same idea as get_manifest().
	for(var/squad_name in LAZYACCESS(SSjob.squads_by_name, FACTION_TERRAGOV))
		departments[squad_name] = GLOB.jobs_marines.Copy()
		squad_departments += squad_name
	departments["Marines"] = GLOB.jobs_marines.Copy()

	departments["Engineering"] = GLOB.jobs_engineering.Copy()
	departments["Requisitions"] = GLOB.jobs_requisitions.Copy()
	departments["Medical"] = GLOB.jobs_medical.Copy()
	departments["Miscellaneous"] = list()

/datum/crew_manifest/ui_static_data(mob/user)
	. = ..()
	rebuild_departments()

	var/list/departments_with_jobs = list()
	for(var/department in departments)
		var/list/jobs = departments[department]
		departments_with_jobs[department] = jobs.Copy()

	.["departments_with_jobs"] = departments_with_jobs

/datum/crew_manifest/ui_data(mob/user)
	var/list/data = list()

	for(var/datum/data/record/record_entry as anything in GLOB.datacore.general)
		var/name = record_entry.fields["name"]
		var/rank = record_entry.fields["rank"]
		var/squad = record_entry.fields["squad"]
		if(isnull(name) || isnull(rank))
			continue

		// TGMC records typically have no paygrade_prefix; keep key for UI parity.
		var/paygrade_prefix = record_entry.fields["paygrade_prefix"] || ""

		var/entry_dept = null
		var/list/entry = list(
			"paygrade_prefix" = paygrade_prefix,
			"name" = name,
			"rank" = rank,
			"squad" = squad,
			"is_active" = record_entry.fields["p_stat"] || "Unknown",
		)

		for(var/iterated_dept in departments)
			if(iterated_dept in squad_departments)
				if(isnull(squad) || lowertext(squad) != lowertext(iterated_dept))
					continue
			var/list/jobs = departments[iterated_dept]
			if(rank in jobs)
				entry_dept = iterated_dept
				break
			// Same as RU: once a squad-bearing marine misses a non-squad dept, assign to squad.
			if(isnull(entry_dept) && squad)
				entry_dept = squad
				break

		if(isnull(entry_dept) && GLOB.jobs_command[rank])
			entry_dept = "Command"

		if(entry_dept)
			LAZYADD(data[entry_dept], list(entry))
		else
			LAZYADD(data["Miscellaneous"], list(entry))

	return data

/datum/crew_manifest/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CrewManifest", "Crew Manifest")
		ui.open()

/datum/crew_manifest/ui_state(mob/user)
	if(isnewplayer(user))
		return GLOB.new_player_state
	if(isobserver(user))
		return GLOB.observer_state
	if(isliving(user))
		return GLOB.conscious_state
	return GLOB.always_state

/datum/crew_manifest/proc/open_ui(mob/user)
	ui_interact(user)
