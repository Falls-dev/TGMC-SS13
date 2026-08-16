// ============================================================
// General tab - matches the "Heal"/"Sleep"/PM/SM/VV/JMP/FLW/LOGS/
// lobby links that were in the old show_player_panel HTML.
// ============================================================

/datum/player_action/rejuvenate
	action_tag = "mob_rejuvenate"
	name = "Rejuvenate"
	permissions_required = R_ADMIN

/datum/player_action/rejuvenate/act(client/user, mob/target, list/params)
	if(!isliving(target))
		return
	var/mob/living/living_target = target
	if(tgui_alert(user, "Are you sure you want to rejuvenate [key_name(living_target)]?", "Confirm", list("Yes", "No")) != "Yes")
		return
	if(QDELETED(living_target))
		return
	living_target.revive(TRUE)
	log_admin("[key_name(user)] revived [key_name(living_target)].")
	message_admins("[ADMIN_TPMONTY(user.mob)] revived [ADMIN_TPMONTY(living_target)].")
	return TRUE


/datum/player_action/kill
	action_tag = "mob_kill"
	name = "Kill"
	permissions_required = R_ADMIN

/datum/player_action/kill/act(client/user, mob/target, list/params)
	if(!isliving(target))
		return
	var/mob/living/living_target = target
	if(tgui_alert(user, "Are you sure you want to kill [key_name(living_target)]?", "Confirm", list("Yes", "No")) != "Yes")
		return
	if(QDELETED(living_target))
		return
	living_target.death()
	log_admin("[key_name(user)] killed [key_name(living_target)].")
	message_admins("[ADMIN_TPMONTY(user.mob)] killed [ADMIN_TPMONTY(living_target)].")
	return TRUE


/datum/player_action/gib
	action_tag = "mob_gib"
	name = "Gib"
	permissions_required = R_ADMIN

/datum/player_action/gib/act(client/user, mob/target, list/params)
	var/mob/living/living_target = target
	if(!istype(living_target) || isobserver(living_target))
		return
	if(tgui_alert(user, "Are you sure you want to gib [key_name(living_target)]?", "Warning", list("Yes", "No")) != "Yes")
		return
	if(QDELETED(living_target))
		return
	log_admin("[key_name(user)] has gibbed [key_name(living_target)].")
	message_admins("[ADMIN_TPMONTY(user.mob)] has gibbed [ADMIN_TPMONTY(living_target)].")
	living_target.gib()
	return TRUE


/datum/player_action/mob_sleep
	action_tag = "mob_sleep"
	name = "Toggle Sleeping"
	permissions_required = R_ADMIN

/datum/player_action/mob_sleep/act(client/user, mob/target, list/params)
	if(!isliving(target))
		return
	var/mob/living/living_target = target
	living_target.ToggleAdminSleep()
	log_admin("[key_name(user)] has [living_target.IsAdminSleeping() ? "enabled" : "disabled"] sleeping on [key_name(living_target)].")
	message_admins("[ADMIN_TPMONTY(user.mob)] has [living_target.IsAdminSleeping() ? "enabled" : "disabled"] sleeping on [ADMIN_TPMONTY(living_target)].")
	return TRUE


/datum/player_action/send_to_lobby
	action_tag = "send_to_lobby"
	name = "Send To Lobby"
	permissions_required = R_ADMIN

/datum/player_action/send_to_lobby/act(client/user, mob/target, list/params)
	if(!target.client)
		to_chat(user, span_warning("[target] doesn't seem to have an active client."))
		return

	if(tgui_alert(user, "Send [key_name(target)] back to Lobby?", "Send to Lobby", list("Yes", "No")) != "Yes")
		return

	if(QDELETED(target) || !target.client)
		return

	log_admin("[key_name(user)] has sent [key_name(target)] back to the lobby.")
	message_admins("[ADMIN_TPMONTY(user.mob)] has sent [key_name_admin(target)] back to the lobby.")

	var/mob/new_player/new_player_mob = new()
	target.client.screen.Cut()
	new_player_mob.name = target.key
	new_player_mob.key = target.key
	if(isobserver(target))
		qdel(target)
	else
		target.ghostize()
	return TRUE


/datum/player_action/cryo
	action_tag = "cryo_mob"
	name = "Cryo"
	permissions_required = R_ADMIN

/datum/player_action/cryo/act(client/user, mob/target, list/params)
	if(!isliving(target))
		return
	var/mob/living/living_target = target

	if(tgui_alert(user, "Cryo [key_name(living_target)]?", "Cryosleep", list("Yes", "No")) != "Yes")
		return

	if(QDELETED(living_target))
		return

	var/client/target_client = living_target.client
	if(target_client && tgui_alert(user, "They have a client attached, are you sure?", "Cryosleep", list("Yes", "No")) != "Yes")
		return

	var/old_name = living_target.real_name

	var/lobby
	if(target_client?.mob?.mind && tgui_alert(user, "Do you also want to send them to the lobby?", "Cryosleep", list("Yes", "No")) == "Yes")
		lobby = TRUE
		var/mob/new_player/new_player_mob = new()
		var/mob/current_mob = target_client.mob
		new_player_mob.name = current_mob.name
		new_player_mob.key = current_mob.key
		target_client.screen.Cut()
		current_mob.mind.transfer_to(new_player_mob, TRUE)
		if(isobserver(current_mob))
			qdel(current_mob)
	else
		living_target.despawn()

	log_admin("[key_name(user)] has cryo'd [target_client ? key_name(target_client) : old_name][lobby ? " sending them to the lobby" : ""].")
	message_admins("[ADMIN_TPMONTY(user.mob)] has cryo'd [target_client ? key_name_admin(target_client) : old_name][lobby ? " sending them to the lobby" : ""].")
	return TRUE


/datum/player_action/force_say
	action_tag = "mob_force_say"
	name = "Force Say"
	permissions_required = R_ADMIN

/datum/player_action/force_say/act(client/user, mob/target, list/params)
	if(!params["to_say"])
		return
	target.say(params["to_say"], sanitize = FALSE)
	log_admin("[key_name(user)] made [key_name(target)] at [AREACOORD(target)] say \"[params["to_say"]]\"")
	message_admins(span_adminnotice("[key_name_admin(user)] made [ADMIN_TPMONTY(target)] say \"[params["to_say"]]\""))
	return TRUE


/datum/player_action/force_emote
	action_tag = "mob_force_emote"
	name = "Force Emote"
	permissions_required = R_ADMIN

/datum/player_action/force_emote/act(client/user, mob/target, list/params)
	if(!params["to_emote"])
		return
	target.emote("me", message = params["to_emote"])
	log_admin("[key_name(user)] forced [key_name(target)] to emote: [params["to_emote"]]")
	message_admins("[ADMIN_TPMONTY(user.mob)] forced [ADMIN_TPMONTY(target)] to emote: [params["to_emote"]]")
	return TRUE


/datum/player_action/subtle_message
	action_tag = "subtle_message"
	name = "Subtle Message"
	permissions_required = R_FUN

/datum/player_action/subtle_message/act(client/user, mob/target, list/params)
	SSadmin_verbs.dynamic_invoke_verb(user, /datum/admin_verb/subtle_message, target)
	return TRUE


/datum/player_action/private_message
	action_tag = "private_message"
	name = "Private Message"
	permissions_required = R_NONE

/datum/player_action/private_message/act(client/user, mob/target, list/params)
	if(!target.ckey)
		return
	user.private_message(target.ckey, null)
	return TRUE


/datum/player_action/access_variables
	action_tag = "access_variables"
	name = "Access Variables"
	permissions_required = R_DEBUG

/datum/player_action/access_variables/act(client/user, mob/target, list/params)
	SSadmin_verbs.dynamic_invoke_verb(user, /datum/admin_verb/debug_variables, target)
	return TRUE


/datum/player_action/access_playtimes
	action_tag = "access_playtimes"
	name = "Playtime"
	permissions_required = R_ADMIN|R_MENTOR

/datum/player_action/access_playtimes/act(client/user, mob/target, list/params)
	var/client/target_client = target.client
	if(!istype(target_client))
		to_chat(user, span_warning("Target is no longer valid."))
		return

	var/list/body = list()
	body += target_client.get_exp_report()

	var/datum/browser/popup = new(user.mob, "playtime_[target_client.key]", "<div align='center'>Playtime for [target_client.key]</div>", 550, 615)
	popup.set_content(body.Join())
	popup.open(FALSE)
	return TRUE


/datum/player_action/individual_logs
	action_tag = "individual_logs"
	name = "Individual Logs"
	permissions_required = R_ADMIN

/datum/player_action/individual_logs/act(client/user, mob/target, list/params)
	user.holder?.show_individual_logging_panel(target)
	return TRUE


/datum/player_action/jump_to
	action_tag = "jump_to"
	name = "Jump To"
	permissions_required = R_ADMIN

/datum/player_action/jump_to/act(client/user, mob/target, list/params)
	if(target == user.mob)
		return
	user.mob.forceMove(target.loc)
	log_admin("[key_name(user)] has jumped to [key_name(target)]'s mob.")
	message_admins("[ADMIN_TPMONTY(user.mob)] has jumped to [ADMIN_TPMONTY(target)]'s mob.")
	return TRUE


/datum/player_action/get_mob
	action_tag = "get_mob"
	name = "Get Mob"
	permissions_required = R_ADMIN

/datum/player_action/get_mob/act(client/user, mob/target, list/params)
	if(target == user.mob)
		return
	target.forceMove(user.mob.loc)
	log_admin("[key_name(user)] has sent [key_name(target)]'s mob to themselves.")
	message_admins("[ADMIN_TPMONTY(user.mob)] has sent [ADMIN_TPMONTY(target)]'s mob to themselves.")
	return TRUE


/datum/player_action/bring
	action_tag = "mob_bring"
	name = "Bring"
	permissions_required = R_ADMIN

/datum/player_action/bring/act(client/user, mob/target, list/params)
	if(target == user.mob)
		return
	target.forceMove(user.mob.loc)
	log_admin("[key_name(user)] teleported [key_name(target)] to themselves.")
	message_admins("[ADMIN_TPMONTY(user.mob)] teleported [ADMIN_TPMONTY(target)] to themselves.")
	return TRUE


/datum/player_action/thunderdome
	action_tag = "thunderdome"
	name = "Thunderdome"
	permissions_required = R_ADMIN

/datum/player_action/thunderdome/act(client/user, mob/target, list/params)
	if(!ismob(target) || !length(GLOB.tdome1))
		return

	if(tgui_alert(user, "Do you want to send [key_name(target)] to the Thunderdome?", "Confirmation", list("Yes", "No")) != "Yes")
		return

	if(QDELETED(target))
		return

	if(ishuman(target))
		var/mob/living/carbon/human/human_target = target
		for(var/obj/item/item_to_drop in human_target)
			if(istype(item_to_drop, /obj/item/alien_embryo))
				continue
			human_target.dropItemToGround(item_to_drop)

	target.forceMove(pick(GLOB.tdome1))
	to_chat(target, span_boldnotice("You have been sent to the Thunderdome!"))

	log_admin("[key_name(user)] has sent [key_name(target)] to the thunderdome.")
	message_admins("[ADMIN_TPMONTY(user.mob)] has sent [ADMIN_TPMONTY(target)] to the thunderdome.")
	return TRUE
