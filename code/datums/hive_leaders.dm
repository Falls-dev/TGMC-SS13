GLOBAL_DATUM(hive_leaders_tgui, /datum/hive_leaders)

/**
 * Lobby / observer TGUI for normal-hive ruler and leaders.
 * Richer HTML remains available via datacore.get_xeno_manifest() for other consumers.
 */
/datum/hive_leaders

/datum/hive_leaders/Destroy(force, ...)
	SStgui.close_uis(src)
	return ..()

/datum/hive_leaders/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "HiveLeaders", "Hive Leaders")
		ui.open()
		ui.set_autoupdate(FALSE)

/datum/hive_leaders/ui_data(mob/user)
	var/list/data = list()
	var/datum/hive_status/normal/main_hive = GLOB.hive_datums[XENO_HIVE_NORMAL]

	var/list/queens = list()
	if(main_hive?.living_xeno_ruler)
		var/mob/living/carbon/xenomorph/ruler = main_hive.living_xeno_ruler
		queens += list(list(
			"designation" = ruler.name,
			"caste_type" = ruler.xeno_caste.display_name,
		))
	data["queens"] = queens

	var/list/leaders = list()
	if(main_hive)
		for(var/mob/living/carbon/xenomorph/xeno_leader as anything in main_hive.xeno_leader_list)
			leaders += list(list(
				"designation" = xeno_leader.name,
				"caste_type" = xeno_leader.xeno_caste.display_name,
			))
	data["leaders"] = leaders
	return data

/datum/hive_leaders/ui_state(mob/user)
	return GLOB.always_state

/proc/open_hive_leaders_tgui(mob/user)
	if(!GLOB.hive_leaders_tgui)
		GLOB.hive_leaders_tgui = new /datum/hive_leaders()
	GLOB.hive_leaders_tgui.ui_interact(user)
