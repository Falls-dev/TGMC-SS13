/mob
	var/health_scan = FALSE
	var/obj/item/healthanalyzer/integrated/health_analyzer

/mob/proc/toggle_health_scan()
	if(health_scan)
		to_chat(src, span_notice("Health scan disabled."))
		health_scan = FALSE
		QDEL_NULL(health_analyzer)
	else
		to_chat(src, span_notice("Health scan enabled."))
		health_scan = TRUE
		health_analyzer = new()

/datum/action/toggle_health_scan
	name = "Toggle Health Scan"
	action_icon_state = "suit_scan"
	action_type = ACTION_TOGGLE

/datum/action/toggle_health_scan/can_use_action()
	. = ..()
	if(!.)
		return FALSE
	if(isobserver(owner))
		return TRUE
	if(isxeno(owner))
		var/mob/living/carbon/xenomorph/X = owner
		if(X.hivenumber == XENO_HIVE_FALLEN)
			return TRUE
	return FALSE

/datum/action/toggle_health_scan/action_activate()
	owner.toggle_health_scan()
	set_toggle(owner.health_scan)
