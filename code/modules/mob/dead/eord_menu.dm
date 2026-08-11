/**
 * # EORD menu
 *
 * TGUI popup offered only to /mob/new_player (lobby) when EORD starts or when they
 * log in while EORD is already running. Ghosts and in-round players still get the
 * OOC verbs but not this panel.
 *
 * This is a stateless global controller, similar to [/datum/latejoin_menu]: all of the actual work
 * (spawning the EORD body) is still done by the pre-existing do_eord_respawn()/do_xeno_eord_respawn()
 * procs. This datum is purely a presentation layer offering a TGUI alternative to manually finding
 * the "EORD Respawn"/"EORD Xeno Respawn" OOC verbs - it never replaces or bypasses them.
 */
GLOBAL_DATUM_INIT(eord_menu, /datum/eord_menu, new)

/datum/eord_menu

/datum/eord_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "EORDMenu", "Конец раунда")
		ui.open()

/datum/eord_menu/ui_state(mob/user)
	return GLOB.new_player_state

/datum/eord_menu/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/user = ui.user
	if(!user)
		return TRUE

	switch(action)
		if("wait")
			ui.close()
			return TRUE
		if("join_human")
			if(!can_eord_join(user))
				return TRUE
			do_eord_respawn(user)
			ui.close()
			return TRUE
		if("join_xeno")
			if(!can_eord_join(user, xeno = TRUE))
				return TRUE
			do_xeno_eord_respawn(user)
			ui.close()
			return TRUE

/**
 * Mirrors the crit/dead checks done by the eord_respawn()/eord_xeno_respawn() verbs
 * (see [code/modules/mob/mob_verbs.dm]), but takes an explicit mob instead of relying on `usr`,
 * since `usr` isn't reliably set from a TGUI action.
 */
/datum/eord_menu/proc/can_eord_join(mob/user, xeno = FALSE)
	if(!isliving(user))
		return TRUE
	var/mob/living/liver = user
	var/crit_threshold = xeno ? liver.health_threshold_crit : liver.get_crit_threshold()
	if(liver.health >= crit_threshold)
		to_chat(user, span_notice("Это доступно только когда вы мёртвы или в критическом состоянии."))
		return FALSE
	return TRUE

/// Opens the EORD TGUI menu for a mob/new_player sitting in the lobby while EORD is active.
/proc/open_eord_menu(mob/target)
	if(!isnewplayer(target) || !target.client)
		return
	GLOB.eord_menu.ui_interact(target)
