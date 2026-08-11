// ============================================================
// Punish tab - Ban/Kick/Mute/Notes/related-accounts/CentCom lookup.
// Mirrors the rights + logging of the equivalent hrefs in topic.dm.
// ============================================================

/datum/player_action/ban
	action_tag = "mob_ban"
	name = "Ban"
	permissions_required = R_BAN

/datum/player_action/ban/act(client/user, mob/target, list/params)
	if(!user.holder)
		return
	user.holder.banpanel(target.key, target.client?.address, target.client?.computer_id)
	return TRUE


/datum/player_action/kick
	action_tag = "mob_kick"
	name = "Kick"
	permissions_required = R_BAN

/datum/player_action/kick/act(client/user, mob/target, list/params)
	if(!ismob(target))
		return
	if(!check_if_greater_rights_than(target.client))
		return
	if(tgui_alert(user, "Are you sure you want to kick [key_name(target)]?", "Warning", list("Yes", "No")) != "Yes")
		return
	if(!target?.client)
		to_chat(user, span_warning("Error: [target] no longer has a client!"))
		return

	to_chat_immediate(target, span_danger("You have been kicked from the server by [user.holder?.fakekey ? "an Administrator" : "[user.key]"]."))
	qdel(target.client)

	log_admin_private("[key_name(user)] kicked [key_name(target)].")
	message_admins("[ADMIN_TPMONTY(user.mob)] kicked [ADMIN_TPMONTY(target)].")
	return TRUE


/datum/player_action/mute
	action_tag = "mob_mute"
	name = "Mute"
	permissions_required = R_BAN

/datum/player_action/mute/act(client/user, mob/target, list/params)
	if(!target.client)
		return
	var/mute_type = text2num(params["mute_type"])
	if(!isnum(mute_type))
		return
	user.mute(target.client, mute_type)
	return TRUE


/datum/player_action/show_notes
	action_tag = "show_notes"
	name = "Check Notes"
	permissions_required = R_BAN

/datum/player_action/show_notes/act(client/user, mob/target, list/params)
	if(!target.ckey)
		return
	browse_messages(target_ckey = target.ckey)
	return TRUE


/datum/player_action/add_note
	action_tag = "add_note"
	name = "Add Note"
	permissions_required = R_BAN

/datum/player_action/add_note/act(client/user, mob/target, list/params)
	if(!target.ckey)
		return
	create_message("note", target.ckey)
	return TRUE


/datum/player_action/related_accounts_cid
	action_tag = "related_accounts_cid"
	name = "CID Related Accounts"
	permissions_required = R_ADMIN

/datum/player_action/related_accounts_cid/act(client/user, mob/target, list/params)
	if(!target.client)
		return
	var/list/accounts = splittext(target.client.related_accounts_cid, ", ")
	var/list/body = list("Related accounts by CID:")
	body += accounts
	var/datum/browser/browser = new(user.mob, "related_cid_[target.client]", "[target.client.ckey] Related Accounts", 420, 300)
	browser.set_content(body.Join("<br>"))
	browser.open()
	return TRUE


/datum/player_action/related_accounts_ip
	action_tag = "related_accounts_ip"
	name = "IP Related Accounts"
	permissions_required = R_ADMIN

/datum/player_action/related_accounts_ip/act(client/user, mob/target, list/params)
	if(!target.client)
		return
	var/list/accounts = splittext(target.client.related_accounts_ip, ", ")
	var/list/body = list("Related accounts by IP:")
	body += accounts
	var/datum/browser/browser = new(user.mob, "related_ip_[target.client]", "[target.client.ckey] Related Accounts", 420, 300)
	browser.set_content(body.Join("<br>"))
	browser.open()
	return TRUE


/datum/player_action/centcom_lookup
	action_tag = "centcom_lookup"
	name = "CentCom Ban Lookup"
	permissions_required = R_ADMIN

/datum/player_action/centcom_lookup/act(client/user, mob/target, list/params)
	if(!CONFIG_GET(string/centcom_ban_db))
		to_chat(user, span_warning("Centcom Galactic Ban DB is disabled!"))
		return

	var/ckey = target.ckey
	if(!ckey)
		return

	var/datum/http_request/request = new()
	request.prepare(RUSTG_HTTP_METHOD_GET, "[CONFIG_GET(string/centcom_ban_db)]/[ckey]", "", "")
	request.begin_async()
	UNTIL(request.is_complete() || !user)
	if(!user)
		return
	var/datum/http_response/response = request.into_response()

	var/list/dat = list("<meta http-equiv='Content-Type' content='text/html; charset=UTF-8'><body>")

	if(response.errored)
		dat += "<br>Failed to connect to CentCom."
	else if(response.status_code != 200)
		dat += "<br>Failed to connect to CentCom. Status code: [response.status_code]"
	else if(response.body == "[]")
		dat += "<center><b>0 bans detected for [ckey]</b></center>"
	else
		var/list/bans = json_decode(response.body)
		dat += "<center><b>[length(bans)] ban\s detected for [ckey]</b></center>"
		for(var/list/ban in bans)
			dat += "<b>Server: </b> [sanitize(ban["sourceName"])]<br>"
			dat += "<b>RP Level: </b> [sanitize(ban["sourceRoleplayLevel"])]<br>"
			dat += "<b>Type: </b> [sanitize(ban["type"])]<br>"
			dat += "<b>Banned By: </b> [sanitize(ban["bannedBy"])]<br>"
			dat += "<b>Reason: </b> [sanitize(ban["reason"])]<br>"
			dat += "<b>Datetime: </b> [sanitize(ban["bannedOn"])]<br>"
			var/expiration = ban["expires"]
			dat += "<b>Expires: </b> [expiration ? "[sanitize(expiration)]" : "Permanent"]<br>"
			if(ban["type"] == "job")
				dat += "<b>Jobs: </b> "
				var/list/jobs = ban["jobs"]
				dat += sanitize(jobs.Join(", "))
				dat += "<br>"
			dat += "<hr>"

	dat += "<br></body>"
	var/datum/browser/popup = new(user.mob, "centcomlookup-[ckey]", "<div align='center'>Central Command Galactic Ban Database</div>", 700, 600)
	popup.set_content(dat.Join())
	popup.open(0)
	return TRUE
