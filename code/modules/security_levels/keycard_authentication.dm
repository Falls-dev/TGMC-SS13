/obj/machinery/keycard_auth
	name = "Keycard Authentication Device"
	desc = "This device is used to trigger station functions, which require more than one ID card to authenticate."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "auth_off"
	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 2
	active_power_usage = 6
	power_channel = ENVIRON
	interaction_flags = INTERACT_MACHINE_TGUI
	light_power = 0.5
	light_range = 0.7
	///This gets set to TRUE on all devices except the one where the initial request was made.
	var/active = FALSE
	var/event = ""
	var/screen = 1
	///This variable is set by the device that confirms the request.
	var/confirmed = 0
	///Delay before confirm deactivates
	var/confirm_delay = 2 SECONDS
	///Busy when waiting for authentication or an event request has been sent from this device.
	var/busy = 0
	var/obj/machinery/keycard_auth/event_source
	var/mob/event_triggered_by
	var/mob/event_confirmed_by
	/// Has this event been authorized by a silicon. Most of the time, this means the AI.
	var/synth_activation = 0
	//1 = select event
	//2 = authenticate

/obj/machinery/keycard_auth/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(.)
		return

	if(machine_stat & (NOPOWER|BROKEN))
		to_chat(user, "This device is not powered.")
		return

	if(istype(I, /obj/item/card/id))
		var/obj/item/card/id/ID = I
		if(!(ACCESS_MARINE_BRIDGE in ID.access))
			return

		if(active && event_source)
			event_source.confirmed = TRUE
			event_source.event_confirmed_by = user
			SStgui.update_uis(src)
			SStgui.update_uis(event_source)

		else if(screen == 2)
			event_triggered_by = user
			broadcast_request()

/obj/machinery/keycard_auth/update_icon_state()
	. = ..()
	if(machine_stat & NOPOWER)
		icon_state = "auth_off"
	update_emissives()

/obj/machinery/keycard_auth/update_overlays()
	. = ..()
	if(machine_stat & (BROKEN|DISABLED|NOPOWER))
		return
	. += emissive_appearance(icon, "[icon_state]_emissive", src, alpha = src.alpha)

/obj/machinery/keycard_auth/proc/update_emissives()
	if(icon_state == "auth_on")
		set_light(initial(light_range), initial(light_power), LIGHT_COLOR_KEYCARD_BLUE)
		update_icon(UPDATE_OVERLAYS)
	else
		set_light(0, 0)
		update_icon(UPDATE_OVERLAYS)

/obj/machinery/keycard_auth/can_interact(mob/user)
	. = ..()
	if(!.)
		return FALSE
	if(busy)
		return FALSE
	return TRUE

/obj/machinery/keycard_auth/ui_interact(mob/user, datum/tgui/ui)
	if(issilicon(user))
		synth_activation = 1
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "KeycardAuth", name)
		ui.open()

/obj/machinery/keycard_auth/ui_data(mob/user)
	. = list()
	.["waiting"] = busy || (screen == 2 && !active)
	.["auth_required"] = active && !!event_source
	.["event"] = active && event_source ? event_source.event : event
	.["is_silicon"] = issilicon(user)
	.["maint_access"] = GLOB.maint_all_access

	var/list/available_events = list()
	for(var/iter_level_text AS in SSsecurity_level.available_levels)
		var/datum/security_level/iter_level_datum = SSsecurity_level.available_levels[iter_level_text]
		if(!(iter_level_datum.sec_level_flags & SEC_LEVEL_FLAG_CAN_SWITCH_WITH_AUTH))
			continue
		available_events += list(list(
			"name" = iter_level_datum.name,
			"ref" = iter_level_datum.name,
		))
	.["available_events"] = available_events

/obj/machinery/keycard_auth/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(busy)
		return FALSE

	var/mob/user = ui.user

	switch(action)
		if("trigger_event")
			event = params["event"]
			if(!event)
				return FALSE
			event_triggered_by = user
			if(synth_activation)
				trigger_event(event)
				log_game("[key_name(event_triggered_by)] triggered event [event].")
				message_admins("[ADMIN_TPMONTY(event_triggered_by)] triggered event [event].")
				reset()
			else
				screen = 2
				broadcast_request()
			. = TRUE

		if("auth_swipe")
			if(!(active && event_source))
				return FALSE
			var/obj/item/card/id/id_card = user.get_active_held_item()
			if(!istype(id_card))
				id_card = user.get_idcard()
			if(!istype(id_card) || !(ACCESS_MARINE_BRIDGE in id_card.access))
				to_chat(user, span_warning("You need a bridge-level ID to authorize this."))
				return FALSE
			event_source.confirmed = TRUE
			event_source.event_confirmed_by = user
			. = TRUE

		if("reset")
			reset()
			. = TRUE

/obj/machinery/keycard_auth/proc/reset()
	active = FALSE
	event = ""
	screen = 1
	confirmed = FALSE
	busy = FALSE
	synth_activation = 0
	event_source = null
	icon_state = "auth_off"
	update_emissives()
	event_triggered_by = null
	event_confirmed_by = null
	SStgui.update_uis(src)

/obj/machinery/keycard_auth/proc/broadcast_request()
	icon_state = "auth_on"
	update_emissives()
	busy = TRUE
	for(var/obj/machinery/keycard_auth/KA in GLOB.machines)
		if(KA == src)
			continue
		KA.reset()
		KA.receive_request(src)
	addtimer(CALLBACK(src, PROC_REF(finish_confirm)), confirm_delay)
	SStgui.update_uis(src)

/obj/machinery/keycard_auth/proc/finish_confirm()
	if(confirmed)
		confirmed = FALSE
		trigger_event(event)
		log_game("[key_name(event_triggered_by)] triggered and [key_name(event_confirmed_by)] confirmed keycard auth event [event].")
		message_admins("[ADMIN_TPMONTY(event_triggered_by)] triggered and [ADMIN_TPMONTY(event_confirmed_by)] confirmed keycard auth event [event].")
	reset()

/obj/machinery/keycard_auth/proc/receive_request(obj/machinery/keycard_auth/source)
	if(machine_stat & (BROKEN|NOPOWER))
		return
	event_source = source
	busy = FALSE
	active = TRUE
	icon_state = "auth_on"
	update_emissives()
	addtimer(CALLBACK(src, PROC_REF(confirm)), confirm_delay)
	SStgui.update_uis(src)

/obj/machinery/keycard_auth/proc/confirm()
	event_source = null
	icon_state = "auth_off"
	update_emissives()
	active = FALSE
	busy = FALSE
	SStgui.update_uis(src)

/obj/machinery/keycard_auth/proc/trigger_event()
	var/potential_alert_level = SSsecurity_level.text_level_to_number(event)
	if(potential_alert_level)
		SSsecurity_level.set_level(potential_alert_level)
		return
	switch(event)
		if("Grant Emergency Maintenance Access")
			make_maint_all_access()
		if("Revoke Emergency Maintenance Access")
			revoke_maint_all_access()

GLOBAL_VAR_INIT(maint_all_access, FALSE)
/// Enables all access for maintenance airlocks
/proc/make_maint_all_access()
	GLOB.maint_all_access = TRUE

	priority_announce(
		title = "Внимание!",
		subtitle = "На корабле объявлена чрезвычайная ситуация.",
		message = "Требование служебного доступа для входа в технические тоннели было аннулировано.",
		sound = 'sound/misc/notice1.ogg',
		color_override = "grey"
	)
	SSblackbox.record_feedback(FEEDBACK_NESTED_TALLY, "keycard_auth_events", 1, list("emergency maintenance access", "enabled"))

/// Disables all access for maintenance airlocks
/proc/revoke_maint_all_access()
	GLOB.maint_all_access = FALSE
	priority_announce(
		title = "Внимание!",
		subtitle = "Чрезвычайная ситуация на корабле отменена.",
		message = "Требование служебного доступа для входа в технические тоннели было восстановлено.",
		sound = 'sound/misc/notice2.ogg',
		color_override = "grey"
	)
	SSblackbox.record_feedback(FEEDBACK_NESTED_TALLY, "keycard_auth_events", 1, list("emergency maintenance access", "disabled"))

/obj/machinery/door/airlock/allowed(mob/M)
	if(is_mainship_level(z) && GLOB.maint_all_access && (ACCESS_MARINE_ENGINEERING in (req_access+req_one_access)))
		return TRUE
	return ..(M)
