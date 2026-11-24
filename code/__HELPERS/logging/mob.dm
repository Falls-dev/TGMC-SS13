/**
 * Logs a mesage to the mob_tags log, including the mobs tag
 * Arguments:
 * * text - text to log.
 */
/mob/proc/log_mob_tag(text, list/data)
	logger.Log(LOG_CATEGORY_DEBUG_MOBTAG, text, data)


/// Logs a message in a mob's individual log, and in the global logs as well if log_globally is true
/mob/log_message(message, message_type, color = null, log_globally = TRUE)
	if(!LAZYLEN(message))
		stack_trace("Empty message")
		return

	// Cannot use the list as a map if the key is a number, so we stringify it (thank you BYOND)
	var/smessage_type = num2text(message_type, MAX_BITFLAG_DIGITS)

	if(client)
		if(!islist(client.player_details.logging[smessage_type]))
			client.player_details.logging[smessage_type] = list()

	if(!islist(logging[smessage_type]))
		logging[smessage_type] = list()

	//This makes readability a bit better for admins.
	var/prefix = ""
	switch(message_type)
		if(LOG_WHISPER)
			prefix = "(WHISPER) "
		if(LOG_OOC)
			prefix = "(OOC) "
		if(LOG_ASAY)
			prefix = "(ASAY) "
		if(LOG_EMOTE)
			prefix = "(EMOTE) "

	var/list/entry = list("message" = message, "color" = color, "prefix" = prefix)
	var/list/timestamped_message = list("\[[time_stamp(format = "YYYY-MM-DD hh:mm:ss")]\] [key_name(src)] [loc_name(src)] (Event #[LAZYLEN(logging[smessage_type])])" = entry)

	logging[smessage_type] += timestamped_message

	if(client)
		client.player_details.logging[smessage_type] += timestamped_message

	..()
