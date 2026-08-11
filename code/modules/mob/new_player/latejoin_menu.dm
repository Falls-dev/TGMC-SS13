/**
 * # Latejoin menu
 *
 * TGUI-backed replacement for the old HTML "Choose Occupation" browser popup. This is a stateless
 * global controller (like a status display) - all of the actual per-user data is computed fresh in
 * ui_data()/ui_static_data(), and security-relevant decisions are delegated back to
 * /mob/new_player/proc/attempt_select_job() so the same checks apply regardless of how a job was
 * picked (TGUI, DM fallback prompt, or the legacy href).
 */
GLOBAL_DATUM_INIT(latejoin_menu, /datum/latejoin_menu, new)

/datum/latejoin_menu

/datum/latejoin_menu/ui_interact(mob/new_player/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "JobSelection", "Choose Occupation")
		ui.open()

/datum/latejoin_menu/ui_state(mob/user)
	return GLOB.new_player_state

/// Department name -> TGUI display color overrides. Only affects this UI; does not touch /datum/job/selection_color.
GLOBAL_LIST_INIT(latejoin_menu_department_colors, list(
	JOB_CAT_MARINE = "#C0C5CE", //Silver-metallic
	JOB_CAT_REQUISITIONS = "#E67E22", //Orange
))

/// Rarely-changing per-job info (color, description, command flag). Sent once and cached client-side.
/datum/latejoin_menu/ui_static_data(mob/user)
	var/list/departments = list()

	for(var/category_name in SSjob.active_joinable_occupations_by_category)
		var/list/category = SSjob.active_joinable_occupations_by_category[category_name]
		if(!length(category))
			continue

		var/datum/job/head_job = category[1] //Use the color of the first job in the category (the department head) as the category color, like the old HTML UI did.
		var/list/department_jobs = list()
		departments[category_name] = list(
			"color" = GLOB.latejoin_menu_department_colors[category_name] || head_job.selection_color,
			"jobs" = department_jobs,
		)

		for(var/datum/job/job_datum as anything in category)
			department_jobs[job_datum.title] = list(
				"command" = !!(job_datum.job_flags & JOB_FLAG_BOLD_NAME_ON_SELECTION),
				"duty" = job_datum.job_duty,
				"difficulty" = job_datum.job_difficulty,
			)

	return list("departments_static" = departments)

/// Per-round, per-user info (open slots, availability). Refreshed whenever the UI updates.
/datum/latejoin_menu/ui_data(mob/user)
	var/mob/new_player/owner = user
	var/list/departments = list()
	var/list/data = list(
		"round_duration" = DisplayTimeText(world.time - SSticker.round_start_time, round_seconds_to = 1),
		"shuttle_status" = GLOB.enter_allowed ? null : "You may no longer join the round.",
		"security_level" = SSsecurity_level.get_current_level_as_number(),
		"security_level_text" = SSsecurity_level.get_current_level_as_text(),
		"evacuation_status" = SSevacuation.evac_status,
		"self_destruct_status" = SSevacuation.dest_status,
		"departments" = departments,
	)

	for(var/category_name in SSjob.active_joinable_occupations_by_category)
		var/list/category = SSjob.active_joinable_occupations_by_category[category_name]
		var/list/department_jobs = list()
		departments[category_name] = list("jobs" = department_jobs)

		for(var/datum/job/job_datum as anything in category)
			var/list/reasons = list()
			var/available = istype(owner) && owner.IsJobAvailable(job_datum, TRUE, reasons)

			var/position_label
			if(job_datum.job_flags & JOB_FLAG_HIDE_CURRENT_POSITIONS)
				position_label = "?"
			else if(job_datum.job_flags & JOB_FLAG_SHOW_OPEN_POSITIONS)
				position_label = "[job_datum.total_positions - job_datum.current_positions] open"
			else
				position_label = "[job_datum.current_positions]"

			department_jobs[job_datum.title] = list(
				"position_label" = position_label,
				"unavailable_reason" = available ? null : (length(reasons) ? reasons[1] : "This position is not currently available."),
				"ref" = REF(job_datum),
			)

	return data

/datum/latejoin_menu/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(!ui.user.client || !isnewplayer(ui.user))
		return TRUE

	var/mob/new_player/owner = ui.user

	switch(action)
		if("select_job")
			var/datum/job/job_datum = locate(params["job"]) in SSjob.active_joinable_occupations
			if(!istype(job_datum))
				return TRUE
			owner.attempt_select_job(job_datum)
			return TRUE
