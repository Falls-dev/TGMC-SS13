/datum/keybinding
	var/list/hotkey_keys
	var/name
	var/full_name
	var/description = ""
	var/category = CATEGORY_MISC
	var/weight = WEIGHT_LOWEST
	/// If TRUE, this binding is dispatched before ordinary bindings while its context is active.
	var/build_mode_priority = FALSE
	var/keybind_signal

/datum/keybinding/New()
	if(!keybind_signal)
		CRASH("Keybind [src] called unredefined down() without a keybind_signal.")

/datum/keybinding/proc/down(client/user)
	SHOULD_CALL_PARENT(TRUE)
	return CHECK_BITFIELD(SEND_SIGNAL(user.mob, keybind_signal, src), COMSIG_KB_ACTIVATED)

/datum/keybinding/proc/is_build_mode_priority_active(client/user)
	if(!build_mode_priority || !user?.mob)
		return FALSE
	var/mob/living/carbon/xenomorph/X = user.mob
	if(!X)
		return FALSE
	for(var/datum/action/ability/activable/xeno/secrete_resin/resin_action in X.actions)
		if(resin_action.ui_mode_active)
			return TRUE
	return FALSE

/datum/keybinding/proc/up(client/user)
	return FALSE

/datum/keybinding/proc/intercept_mouse_special(datum/source)
	SIGNAL_HANDLER
	return COMSIG_MOB_CLICK_CANCELED

/// returns the keys that the keybinding is currently triggered by
/datum/keybinding/proc/get_keys_formatted(client/user)
	if(!user)
		return ""
	var/datum/preferences/user_prefs = GLOB.preferences_datums[user.ckey]
	if(!user_prefs)
		return ""
	for(var/key in user_prefs.key_bindings)
		if(name in user_prefs.key_bindings[key])
			return "[key]"
