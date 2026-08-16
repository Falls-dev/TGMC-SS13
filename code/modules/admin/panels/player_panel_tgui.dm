/**
 * TGUI player panel, ported from RU-CM13's `/datum/player_panel` and adapted to
 * TGMC's admin infrastructure (`ui_interact`/`GLOB.admin_state`/`check_rights_for`).
 *
 * Opened by the `show_player_panel` admin verb (see player_panel.dm) in place of
 * the old raw-HTML browser panel.
 */
/mob/var/datum/player_panel/mob_panel

/mob/proc/create_player_panel()
	mob_panel = new(src)

/datum/player_panel
	var/mob/target_mob

/datum/player_panel/New(mob/target)
	. = ..()
	target_mob = target

/datum/player_panel/Destroy(force, ...)
	target_mob = null
	SStgui.close_uis(src)
	return ..()

/datum/player_panel/ui_interact(mob/user, datum/tgui/ui)
	if(!target_mob)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PlayerPanel", "[capitalize(target_mob.name)] Player Panel")
		ui.open()
		ui.set_autoupdate(FALSE)

/datum/player_panel/ui_state(mob/user)
	return GLOB.admin_state

/datum/player_panel/ui_status(mob/user, datum/ui_state/state)
	if(QDELETED(target_mob))
		return UI_CLOSE
	return ..()

/datum/player_panel/ui_data(mob/user)
	. = list()
	.["mob_name"] = capitalize(target_mob.name)

	if(isliving(target_mob))
		var/mob/living/living_target = target_mob
		.["mob_sleeping"] = living_target.IsAdminSleeping()
		.["mob_status_flags"] = living_target.status_flags
	else
		.["mob_sleeping"] = FALSE
		.["mob_status_flags"] = 0

	.["current_permissions"] = user.client?.holder?.rank?.rights

	if(target_mob.client)
		var/client/target_client = target_mob.client

		.["client_key"] = target_client.key
		.["client_ckey"] = target_client.ckey
		.["client_muted"] = target_client.prefs?.muted
		.["client_join_date"] = target_client.player_join_date
		.["account_join_date"] = target_client.account_join_date
		.["client_rank"] = target_client.holder ? target_client.holder.rank.name : "Player"
		.["client_related_cid"] = target_client.related_accounts_cid
		.["client_related_ip"] = target_client.related_accounts_ip

/datum/player_panel/ui_static_data(mob/user)
	. = list()
	.["mob_type"] = "[target_mob.type]"

	.["is_human"] = ishuman(target_mob)
	.["is_xeno"] = isxeno(target_mob)
	.["has_client"] = !!target_mob.client
	.["centcom_ban_db_enabled"] = !!CONFIG_GET(string/centcom_ban_db)

	.["glob_status_flags"] = GLOB.pp_status_flags
	.["glob_limbs"] = GLOB.pp_limbs
	.["glob_mute_bits"] = GLOB.pp_mute_bits
	.["glob_hives"] = pp_generate_hives()
	.["glob_pp_actions"] = GLOB.pp_actions_data
	.["glob_pp_transformables"] = GLOB.pp_transformables

/datum/player_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(!target_mob)
		return

	var/client/acting_client = ui.user.client
	if(!acting_client)
		return

	var/datum/player_action/action_datum = GLOB.pp_actions[action]
	if(!action_datum)
		return

	if(!check_rights_for(acting_client, action_datum.permissions_required))
		return

	return action_datum.act(acting_client, target_mob, params)

// ============================================================
// Static reference data for the panel's front-end.
// ============================================================

GLOBAL_LIST_INIT(pp_mute_bits, list(
	list(name = "IC", bitflag = MUTE_IC),
	list(name = "OOC", bitflag = MUTE_OOC),
	list(name = "LOOC", bitflag = MUTE_LOOC),
	list(name = "Pray", bitflag = MUTE_PRAY),
	list(name = "Adminhelp", bitflag = MUTE_ADMINHELP),
	list(name = "Deadchat", bitflag = MUTE_DEADCHAT),
	list(name = "TTS", bitflag = MUTE_TTS),
))

GLOBAL_LIST_INIT(pp_limbs, list(
	"Head" = BODY_ZONE_HEAD,
	"Left leg" = BODY_ZONE_L_LEG,
	"Right leg" = BODY_ZONE_R_LEG,
	"Left arm" = BODY_ZONE_L_ARM,
	"Right arm" = BODY_ZONE_R_ARM,
))

GLOBAL_LIST_INIT(pp_status_flags, list(
	"Stun" = CANSTUN,
	"Knockdown" = CANKNOCKDOWN,
	"Knockout" = CANKNOCKOUT,
	"Push" = CANPUSH,
	"Godmode" = GODMODE,
))

/proc/pp_generate_hives()
	. = list()
	for(var/hivenumber in GLOB.hive_datums)
		var/datum/hive_status/H = GLOB.hive_datums[hivenumber]
		.[H.name] = H.hivenumber
