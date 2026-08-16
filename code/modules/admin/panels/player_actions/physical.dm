// ============================================================
// Physical tab - status flags, limbs, equipment, squad/faction.
// ============================================================

/datum/player_action/set_status_flags
	action_tag = "set_status_flags"
	name = "Set Status Flags"
	permissions_required = R_VAREDIT

/datum/player_action/set_status_flags/act(client/user, mob/target, list/params)
	if(isnull(params["status_flags"]) || !isliving(target))
		return
	var/mob/living/living_target = target
	living_target.status_flags = text2num(params["status_flags"])
	return TRUE


/datum/player_action/delimb
	action_tag = "mob_delimb"
	name = "Delimb"
	permissions_required = R_VAREDIT

/datum/player_action/delimb/act(client/user, mob/target, list/params)
	if(!params["limbs"] || !ishuman(target))
		return

	var/mob/living/carbon/human/human_target = target

	for(var/limb_zone in params["limbs"])
		if(!limb_zone)
			continue
		if(!human_target.has_limb(limb_zone))
			continue
		var/datum/limb/limb = human_target.get_limb(limb_zone)
		limb?.drop_limb()

	playsound(target, SFX_BONE_BREAK, 45, TRUE)
	target.emote("scream")

	log_admin("[key_name(user)] delimbed [key_name(target)].")
	message_admins("[ADMIN_TPMONTY(user.mob)] delimbed [ADMIN_TPMONTY(target)].")
	return TRUE


/datum/player_action/strip_equipment
	action_tag = "strip_equipment"
	name = "Strip Equipment"
	permissions_required = R_SPAWN

/datum/player_action/strip_equipment/act(client/user, mob/target, list/params)
	for(var/obj/item/current_item in target)
		if(istype(current_item, /obj/item/card/id))
			continue

		if(params["drop_items"])
			target.dropItemToGround(current_item)
			continue

		qdel(current_item)

	log_admin("[key_name(user)] stripped [key_name(target)] of their items.")
	message_admins("[ADMIN_TPMONTY(user.mob)] stripped [ADMIN_TPMONTY(target)] of their items.")
	return TRUE


/datum/player_action/select_equipment
	action_tag = "select_equipment"
	name = "Select Equipment"
	permissions_required = R_FUN

/datum/player_action/select_equipment/act(client/user, mob/target, list/params)
	if(!ishuman(target) && !isobserver(target))
		to_chat(user, span_warning("Invalid mob."))
		return
	SSadmin_verbs.dynamic_invoke_verb(user, /datum/admin_verb/cmd_select_equipment, target)
	return TRUE


/datum/player_action/set_squad
	action_tag = "set_squad"
	name = "Set Squad"
	permissions_required = R_VAREDIT

/datum/player_action/set_squad/act(client/user, mob/target, list/params)
	if(!ishuman(target))
		return
	var/mob/living/carbon/human/human_target = target
	if(!ismarinejob(human_target.job))
		to_chat(user, span_warning("Only marine jobs may be part of squads."))
		return

	var/selected_squad = tgui_input_list(user, "Select a squad.", "Squad Selection", SSjob.squads)
	if(!selected_squad || QDELETED(human_target))
		return

	var/success = human_target.change_squad(selected_squad)

	log_admin("[key_name(user)][success ? "" : " failed to"] set [key_name(human_target)]'s squad to [selected_squad].")
	message_admins("[ADMIN_TPMONTY(user.mob)][success ? "" : " failed to"] set [ADMIN_TPMONTY(human_target)]'s squad to [selected_squad].")
	return TRUE


/datum/player_action/set_faction
	action_tag = "set_faction"
	name = "Set Faction"
	permissions_required = R_VAREDIT

/datum/player_action/set_faction/act(client/user, mob/target, list/params)
	if(!isliving(target))
		return
	var/mob/living/living_target = target

	var/new_faction = tgui_input_list(user, "Select faction.", "Faction Choice", GLOB.faction_to_alignement)
	if(!new_faction || QDELETED(living_target))
		return

	living_target.faction = new_faction

	log_admin("[key_name(user)] set [key_name(living_target)]'s faction to [new_faction].")
	message_admins("[ADMIN_TPMONTY(user.mob)] set [ADMIN_TPMONTY(living_target)]'s faction to [new_faction].")
	return TRUE


/datum/player_action/check_contents
	action_tag = "check_contents"
	name = "Check Contents"
	permissions_required = R_DEBUG

/datum/player_action/check_contents/act(client/user, mob/target, list/params)
	if(!isliving(target))
		return
	var/mob/living/living_target = target

	var/dat
	for(var/atom/content_atom in living_target.GetAllContents())
		dat += "[content_atom] [ADMIN_VV(content_atom)]<br>"

	var/datum/browser/popup = new(user.mob, "contents_[key_name(living_target)]", "<div align='center'>Contents of [key_name(living_target)]</div>")
	popup.set_content(dat)
	popup.open(FALSE)

	log_admin("[key_name(user)] checked the contents of [key_name(living_target)].")
	message_admins("[ADMIN_TPMONTY(user.mob)] checked the contents of [ADMIN_TPMONTY(living_target)].")
	return TRUE


/datum/player_action/offer_mob
	action_tag = "offer_mob"
	name = "Offer Mob"
	permissions_required = R_ADMIN

/datum/player_action/offer_mob/act(client/user, mob/target, list/params)
	if(!isliving(target))
		return
	SSadmin_verbs.dynamic_invoke_verb(user, /datum/admin_verb/offer, target)
	return TRUE


/datum/player_action/give_mob
	action_tag = "give_mob_action"
	name = "Give Mob"
	permissions_required = R_ADMIN

/datum/player_action/give_mob/act(client/user, mob/target, list/params)
	if(!isliving(target))
		return
	SSadmin_verbs.dynamic_invoke_verb(user, /datum/admin_verb/give_mob, target)
	return TRUE


/datum/player_action/rank_and_equipment
	action_tag = "rank_and_equipment"
	name = "Rank and Equipment"
	permissions_required = R_FUN

/datum/player_action/rank_and_equipment/act(client/user, mob/target, list/params)
	if(!ishuman(target))
		return
	SSadmin_verbs.dynamic_invoke_verb(user, /datum/admin_verb/rank_and_equipment, target)
	return TRUE


/datum/player_action/edit_appearance
	action_tag = "edit_appearance"
	name = "Edit Appearance"
	permissions_required = R_FUN

/datum/player_action/edit_appearance/act(client/user, mob/target, list/params)
	if(!ishuman(target))
		return
	SSadmin_verbs.dynamic_invoke_verb(user, /datum/admin_verb/edit_appearance, target)
	return TRUE


/datum/player_action/randomize_name
	action_tag = "randomize_name"
	name = "Randomize Name"
	permissions_required = R_FUN

/datum/player_action/randomize_name/act(client/user, mob/target, list/params)
	if(!ishuman(target))
		return
	var/mob/living/carbon/human/human_target = target
	var/oldname = human_target.real_name

	human_target.fully_replace_character_name(human_target.real_name, human_target.species.random_name(human_target.gender))

	log_admin("[key_name(user)] randomized the name of [oldname] -> [key_name(human_target)].")
	message_admins("[ADMIN_TPMONTY(user.mob)] randomized the name of [oldname] -> [ADMIN_TPMONTY(human_target)].")
	return TRUE
