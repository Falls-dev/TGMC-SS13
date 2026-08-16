// ============================================================
// Fun tab - only includes actions backed by capabilities TGMC
// already exposes to R_FUN admins (direct chat message + cell_explosion,
// both of which are used elsewhere in TGMC's admin tooling).
// ============================================================

/datum/player_action/narrate
	action_tag = "mob_narrate"
	name = "Narrate"
	permissions_required = R_FUN

/datum/player_action/narrate/act(client/user, mob/target, list/params)
	if(!params["to_narrate"])
		return
	var/message = sanitize(params["to_narrate"])
	to_chat(target, span_notice(message))
	message_admins("DirectNarrate: [key_name_admin(user)] to ([key_name_admin(target)]): [message]")
	log_admin("[key_name(user)] narrated to [key_name(target)]: [message]")
	return TRUE


/datum/player_action/explode
	action_tag = "mob_explode"
	name = "Explode"
	permissions_required = R_FUN

/datum/player_action/explode/act(client/user, mob/target, list/params)
	var/power = text2num(params["power"])
	var/falloff = text2num(params["falloff"])
	if(isnull(power) || isnull(falloff))
		return

	var/turf/epicenter = get_turf(target)
	if(!epicenter)
		return

	message_admins("[key_name_admin(user)] dropped a custom cell bomb with power [power], falloff [falloff] on [target.name]!")
	log_admin("[key_name(user)] dropped a custom cell bomb with power [power], falloff [falloff] on [target.name].")
	cell_explosion(epicenter, power, falloff, EXPLOSION_FALLOFF_SHAPE_LINEAR, adminlog = TRUE)
	return TRUE
