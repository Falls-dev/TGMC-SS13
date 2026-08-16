// ============================================================
// Antag tab.
//
// RU's mutineer/xeno-cultist gear presets have no TGMC equivalent (no such
// antag types/equipment presets exist), so they are intentionally omitted
// rather than invented. Only hive transfer - which TGMC already fully
// supports via `transfer_to_hive()` - is ported.
// ============================================================

/datum/player_action/change_hivenumber
	action_tag = "xeno_change_hivenumber"
	name = "Change Hive"
	permissions_required = R_SPAWN

/datum/player_action/change_hivenumber/act(client/user, mob/target, list/params)
	if(!params["hivenumber"] || !isxeno(target))
		return

	var/mob/living/carbon/xenomorph/xeno_target = target
	var/hivenumber = params["hivenumber"]

	if(!GLOB.hive_datums[hivenumber])
		return

	xeno_target.transfer_to_hive(hivenumber)

	log_admin("[key_name(user)] changed hivenumber of [key_name(xeno_target)] to [hivenumber].")
	message_admins("[ADMIN_TPMONTY(user.mob)] changed hivenumber of [ADMIN_TPMONTY(xeno_target)] to [hivenumber].")
	return TRUE
