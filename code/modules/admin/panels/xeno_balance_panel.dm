GLOBAL_DATUM_INIT(xeno_balance_panel, /datum/xeno_balance_panel, new)

/datum/xeno_balance_panel

/datum/xeno_balance_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "XenoBalancePanel")
		ui.open()

/datum/xeno_balance_panel/ui_state(mob/user)
	return GLOB.admin_state

/datum/xeno_balance_panel/ui_data(mob/user)
	var/datum/job/xeno_job = SSjob.GetJobType(/datum/job/xenomorph)
	var/list/data = list()

	data["current_buff"] = GLOB.xeno_stat_multiplicator_buff
	data["is_automatic_on"] = SSmonitor.is_automatic_balance_on
	data["current_state"] = SSmonitor.current_state
	data["current_points"] = SSmonitor.current_points

	switch(SSmonitor.current_state)
		if(XENOS_DELAYING)
			data["state_name"] = "XENOS DELAYING"
		if(XENOS_LOSING)
			data["state_name"] = "XENOS LOSING"
		if(STATE_BALANCED)
			data["state_name"] = "BALANCED"
		if(MARINES_LOSING)
			data["state_name"] = "MARINES LOSING"
		if(MARINES_DELAYING)
			data["state_name"] = "MARINES DELAYING"
		else
			data["state_name"] = "UNKNOWN"

	data["burrowed"] = max(0, xeno_job.total_positions - xeno_job.current_positions)
	data["alive_xenos"] = length(GLOB.alive_xeno_list_hive[XENO_HIVE_NORMAL])
	data["humans_on_ground"] = SSmonitor.human_on_ground
	data["humans_on_ship"] = SSmonitor.human_on_ship

	return data

/datum/xeno_balance_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("toggle_auto")
			SSmonitor.is_automatic_balance_on = !SSmonitor.is_automatic_balance_on
			text2file(SSmonitor.is_automatic_balance_on ? "1" : "0", "data/xeno_auto_balance.txt")
			var/msg = "[key_name_admin(usr)] [SSmonitor.is_automatic_balance_on ? "enabled" : "disabled"] xeno automatic balance system."
			message_admins(msg)
			log_admin(msg)
			. = TRUE

		if("set_buff")
			var/new_percent = text2num(params["value"])
			if(isnull(new_percent))
				return
			new_percent = clamp(new_percent, 10, 500)

			GLOB.xeno_stat_multiplicator_buff = new_percent / 100
			SSmonitor.is_automatic_balance_on = FALSE
			text2file("0", "data/xeno_auto_balance.txt")
			SSmonitor.apply_balance_changes()
			var/msg = "[key_name_admin(usr)] set xeno stat buff to [new_percent]%."
			message_admins(msg)
			log_admin(msg)
			. = TRUE

		if("reset")
			GLOB.xeno_stat_multiplicator_buff = 1
			SSmonitor.is_automatic_balance_on = FALSE
			text2file("0", "data/xeno_auto_balance.txt")
			SSmonitor.apply_balance_changes()
			var/msg = "[key_name_admin(usr)] reset xeno stat buff to 100%."
			message_admins(msg)
			log_admin(msg)
			. = TRUE
