/**
 * Registry of all `/datum/player_action` subtypes, keyed by action_tag.
 * Ported from the RU-CM13 player panel action framework and adapted to TGMC's
 * admin rights model (`check_rights_for`/`R_*`) and existing admin procs/verbs.
 */
GLOBAL_LIST_INIT(pp_actions, generate_pp_actions())
GLOBAL_LIST_INIT(pp_actions_data, generate_pp_actions_data())

/**
 * A single action that can be invoked from the TGUI player panel.
 * Subtypes should only ever call into EXISTING TGMC admin procs/verbs -
 * this datum is a thin dispatch/permission layer, not a place to invent new
 * admin mechanics.
 */
/datum/player_action
	var/name
	var/action_tag
	/// R_* bitflag(s) required to use this action - checked with check_rights_for() before act() is ever called.
	var/permissions_required = R_ADMIN

/**
 * Performs the action.
 *
 * `user` is the client of the admin operating the panel (NOT the target).
 * `target` is the mob the player panel is bound to.
 *
 * Note: `usr` is also correctly set to the admin's mob at this point, since this
 * is always invoked from within `/datum/tgui`'s `on_message()`, itself only ever
 * reached through `/client/Topic()`.
 */
/datum/player_action/proc/act(client/user, mob/target, list/params)
	return TRUE

/proc/generate_pp_actions()
	. = list()
	for(var/I in subtypesof(/datum/player_action))
		var/datum/player_action/P = I
		if(initial(P.action_tag))
			.[initial(P.action_tag)] = new I()

/proc/generate_pp_actions_data()
	. = list()
	for(var/I in subtypesof(/datum/player_action))
		var/datum/player_action/P = I
		if(initial(P.action_tag))
			.["[initial(P.action_tag)]"] = list(
				"name" = initial(P.name),
				"action_tag" = initial(P.action_tag),
				"permissions_required" = initial(P.permissions_required),
			)
