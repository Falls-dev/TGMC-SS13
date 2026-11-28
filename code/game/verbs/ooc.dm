/client/verb/ooc_wrapper()
	set hidden = TRUE
	var/message = input("", "OOC \"text\"") as null|text
	ooc(message)


/client/proc/handle_ooc_prefix(client/target)
	var/prefix = ""
	if(CONFIG_GET(flag/ooc_country_flags) && prefs.show_ooc_country_flag && country)
		prefix += country2chaticon(country, target ? list(target) : GLOB.clients)
	return prefix

/// Color an already-escaped display name and its optional server-generated link.
/proc/format_ooc_nickname(nickname_html, rank_name, hidden_rank, custom_color_allowed, custom_color)
	if(!rank_name || hidden_rank)
		return nickname_html

	var/static/regex/hex_color = regex(@"^#[0-9a-f]{6}$", "i")
	if(custom_color_allowed && istext(custom_color) && length(custom_color) == 7 && hex_color.Find(custom_color))
		return "<span class='ooc-nickname' style='color:[custom_color]'>[nickname_html]</span>"

	var/rank_class
	switch(rank_name)
		if("Host")
			rank_class = "hostooc"
		if("Project Lead")
			rank_class = "projleadooc"
		if("Headcoder")
			rank_class = "headcoderooc"
		if("Headmin")
			rank_class = "headminooc"
		if("Headmentor")
			rank_class = "headmentorooc"
		if("Senior Admin")
			rank_class = "senioradminooc"
		if("Admin")
			rank_class = "adminooc"
		if("Trial Admin")
			rank_class = "trialminooc"
		if("Admin Candidate", "Admin Observer")
			rank_class = "candiminooc"
		if("Event Admin", "Event Staff")
			rank_class = "eventminooc"
		if("Mentor")
			rank_class = "mentorooc"
		if("Maintainer", "Art Maintainer")
			rank_class = "maintainerooc"
		if("Debugger", "Contributor")
			rank_class = "contributorooc"
		else
			rank_class = "otherooc"
	return "<span class='ooc-nickname [rank_class]'>[nickname_html]</span>"

/client/proc/color_ooc_nickname(nickname_html)
	var/use_custom_color = CONFIG_GET(flag/allow_admin_ooccolor) && check_rights_for(src, R_COLOR)
	return format_ooc_nickname(nickname_html, holder?.rank?.name, holder?.fakekey, use_custom_color, prefs.ooccolor)

/// Staff who hear OOC from elsewhere see the real identity and the existing moderation links.
/client/proc/ooc_staff_display_name()
	var/nickname_html = "<a href='byond://?priv_msg=[ckey]'>[html_encode(key)]</a>"
	var/character_name = mob.real_name || mob.name
	if(character_name)
		nickname_html += "/([html_encode(character_name)])"
	var/display_name = "[color_ooc_nickname(nickname_html)] [ADMIN_TPMONTY_NONAME(mob)]"
	if(holder?.fakekey)
		return "[span_tooltip("Stealth key", "'[html_encode(holder.fakekey)]'")] ([display_name])"
	return display_name

/client/verb/ooc(msg as text)
	set name = "OOC"
	set category = "OOC.Chat"

	if(!mob)
		return
	if(IsGuestKey(key))
		to_chat(src, "Guests may not use OOC.")
		return

	msg = copytext_char(sanitize(msg), 1, MAX_MESSAGE_LEN)

	if(!msg)
		return
	if(NON_ASCII_CHECK(msg))
		return

	msg = emoji_parse(msg)

	if(!(prefs.toggles_chat & CHAT_OOC))
		to_chat(src, span_warning("You have OOC muted."))
		return

	if(!check_rights(R_ADMIN, FALSE))
		if(!GLOB.ooc_allowed)
			to_chat(src, span_warning("OOC is globally muted"))
			return
		if(!GLOB.dooc_allowed && (mob.stat == DEAD))
			to_chat(usr, span_warning("OOC for dead mobs has been turned off."))
			return
		if(prefs.muted & MUTE_OOC)
			to_chat(src, span_warning("You cannot use OOC (muted)."))
			return
		if(handle_spam_prevention(msg, MUTE_OOC))
			return
		if(findtext(msg, "byond://"))
			to_chat(src, span_danger("Advertising other servers is not allowed."))
			log_admin_private("[key_name(usr)] has attempted to advertise in OOC: [msg]")
			message_admins("[ADMIN_TPMONTY(usr)] has attempted to advertise in OOC: [msg]")
			return

	if(is_banned_from(ckey, "OOC"))
		to_chat(src, span_warning("You have been banned from OOC."))
		return

	var/list/filter_result = is_ooc_filtered(msg)
	if(!CAN_BYPASS_FILTER(usr) && filter_result)
		REPORT_CHAT_FILTER_TO_USER(usr, filter_result)
		log_filter("OOC", msg, filter_result)
		return

	// Protect filter bypassers from themselves.
	// Demote hard filter results to soft filter results if necessary due to the danger of accidentally speaking in OOC.
	var/list/soft_filter_result = filter_result || is_soft_ooc_filtered(msg)

	if(soft_filter_result)
		if(tgui_alert(usr,"Your message contains \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\". \"[soft_filter_result[CHAT_FILTER_INDEX_REASON]]\", Are you sure you want to say it?", "Soft Blocked Word", list("Yes", "No")) != "Yes")
			return
		message_admins("[ADMIN_LOOKUPFLW(usr)] has passed the soft filter for \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\" they may be using a disallowed term. Message: \"[msg]\"")
		log_admin_private("[key_name(usr)] has passed the soft filter for \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\" they may be using a disallowed term. Message: \"[msg]\"")

	mob.log_talk(msg, LOG_OOC)

	var/keyname
	var/boosty_tier = SSdiscord.get_boosty_tier(ckey)

	if(boosty_tier)
		var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet/chat)
		keyname = "[sheet.icon_tag("emoji-tier-[boosty_tier]")][keyname]"

	for(var/client/C AS in GLOB.clients)
		if(!(C.prefs.toggles_chat & CHAT_OOC))
			continue
		if(holder?.fakekey in C.prefs.ignoring)
			continue
		if(key in C.prefs.ignoring)
			continue

		var/display_name = key
		if(holder?.fakekey)
			if(check_other_rights(C, R_ADMIN|R_MENTOR, FALSE))
				display_name = "[holder.fakekey]/([key])"
			else
				display_name = holder.fakekey

		var/nickname_html = html_encode(display_name)
		// Admins open straight to player panel
		if(check_other_rights(C, R_ADMIN, FALSE))
			nickname_html = "<a class='hidelink' href='byond://?_src_=holder;[HrefToken(TRUE)];playerpanel=[REF(mob)]'>[nickname_html]</a>"
		nickname_html = color_ooc_nickname(nickname_html)
		var/avoid_highlight = C == src
		var/ooc_prefix = handle_ooc_prefix(C)
		to_chat(C, "<span class='colorooc'><em>[keyname]</em>[ooc_prefix][span_prefix("OOC: [nickname_html]")]: <span class='message linkify'>[msg]</span></span>", avoid_highlighting = avoid_highlight)


/client/verb/xooc_wrapper()
	set hidden = TRUE
	var/message = input("", "XOOC \"text\"") as null|text
	xooc(message)

/client/verb/xooc(msg as text) // Same as MOOC, but for xenos.
	set name = "XOOC"
	set category = "OOC.Chat"

	if(!msg)
		return

	var/admin = check_rights(R_ADMIN|R_MENTOR, FALSE)

	if(!mob)
		return
	if(IsGuestKey(key))
		to_chat(src, "Guests may not use XOOC.")
		return
	if(mob.stat == DEAD && !admin)
		to_chat(src, span_warning("You must be alive to use XOOC."))
		return
	if(!(mob in GLOB.xeno_mob_list) && !admin)
		to_chat(src, span_warning("You must be a xeno to use XOOC."))
		return

	msg = copytext_char(sanitize(msg), 1, MAX_MESSAGE_LEN)

	if(!msg)
		return
	if(NON_ASCII_CHECK(msg))
		return

	msg = emoji_parse(msg)

	if(!(prefs.toggles_chat & CHAT_OOC))
		to_chat(src, span_warning("You have OOC muted."))
		return

	if(!check_rights(R_ADMIN, FALSE))
		if(!GLOB.ooc_allowed)
			to_chat(src, span_warning("OOC is globally muted"))
			return
		if(prefs.muted & MUTE_OOC)
			to_chat(src, span_warning("You cannot use OOC (muted)."))
			return
		if(handle_spam_prevention(msg, MUTE_OOC))
			return
		if(findtext(msg, "byond://"))
			to_chat(src, span_danger("Advertising other servers is not allowed."))
			log_admin_private("[key_name(usr)] has attempted to advertise in OOC: [msg]")
			message_admins("[ADMIN_TPMONTY(usr)] has attempted to advertise in OOC: [msg]")
			return

	var/list/filter_result = is_ooc_filtered(msg)
	if(!CAN_BYPASS_FILTER(usr) && filter_result)
		REPORT_CHAT_FILTER_TO_USER(usr, filter_result)
		log_filter("XOOC", msg, filter_result)
		return

	// Protect filter bypassers from themselves.
	// Demote hard filter results to soft filter results if necessary due to the danger of accidentally speaking in OOC.
	var/list/soft_filter_result = filter_result || is_soft_ooc_filtered(msg)

	if(soft_filter_result)
		if(tgui_alert(usr,"Your message contains \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\". \"[soft_filter_result[CHAT_FILTER_INDEX_REASON]]\", Are you sure you want to say it?", "Soft Blocked Word", list("Yes", "No")) != "Yes")
			return
		message_admins("[ADMIN_LOOKUPFLW(usr)] has passed the soft filter for \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\" they may be using a disallowed term. Message: \"[msg]\"")
		log_admin_private("[key_name(usr)] has passed the soft filter for \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\" they may be using a disallowed term. Message: \"[msg]\"")

	if(is_banned_from(ckey, "OOC"))
		to_chat(src, span_warning("You have been banned from OOC."))
		return

	mob.log_talk(msg, LOG_XOOC)

	var/display_name = mob.name
	if(!(mob in GLOB.xeno_mob_list) && admin)
		display_name = holder?.fakekey ? "Administrator" : key
	var/nickname_html = color_ooc_nickname(html_encode(display_name))

	// Send chat message to non-admins
	for(var/client/C AS in GLOB.clients)
		if(!(C.prefs.toggles_chat & CHAT_OOC))
			continue
		if(!(C.mob in GLOB.xeno_mob_list) && !(C.mob in GLOB.observer_list) || check_other_rights(C, R_ADMIN|R_MENTOR, FALSE)) // If the client is a xeno, an observer, and not staff.
			continue

		var/avoid_highlight = C == src
		to_chat(C, "<span class='ooc' style='color:#6D2A6D'>[span_prefix("XOOC: [nickname_html]")]: <span class='message linkify'>[msg]</span></span>", avoid_highlighting = avoid_highlight)

	var/staff_display_name = ooc_staff_display_name()
	// Send chat message to admins
	for(var/client/C AS in GLOB.admins)
		if(!check_other_rights(C, R_ADMIN|R_MENTOR, FALSE)) // Check if the client is still an admin.
			continue
		if(!C.prefs.hear_ooc_anywhere_as_staff)
			continue
		if(!(C.prefs.toggles_chat & CHAT_OOC))
			continue

		var/avoid_highlight = C == src
		var/channel_label = span_tooltip("You are seeing this because you are staff and have hearing OOC channels from anywhere enabled.", "XOOC")
		to_chat(C, "<span class='ooc' style='color:#6D2A6D'>[span_prefix("[channel_label]: [staff_display_name]")]: <span class='message linkify'>[msg]</span></span>", avoid_highlighting = avoid_highlight)


/client/verb/mooc_wrapper()
	set hidden = TRUE
	var/message = input("", "MOOC \"text\"") as null|text
	mooc(message)


/client/verb/mooc(msg as text) // Same as XOOC, but for humans.
	set name = "MOOC"
	set category = "OOC.Chat"

	var/admin = check_rights(R_ADMIN|R_MENTOR, FALSE)

	if(!mob)
		return
	if(IsGuestKey(key))
		to_chat(src, "Guests may not use MOOC.")
		return
	if(mob.stat == DEAD && !admin)
		to_chat(src, span_warning("You must be alive to use MOOC."))
		return
	if(!((mob in GLOB.human_mob_list) || (mob in GLOB.ai_list)) && !admin)
		to_chat(src, span_warning("You must be a human to use MOOC."))
		return

	msg = copytext_char(sanitize(msg), 1, MAX_MESSAGE_LEN)

	if(!msg)
		return
	if(NON_ASCII_CHECK(msg))
		return

	msg = emoji_parse(msg)

	if(!(prefs.toggles_chat & CHAT_OOC))
		to_chat(src, span_warning("You have OOC muted."))
		return

	if(!check_rights(R_ADMIN, FALSE))
		if(!GLOB.ooc_allowed)
			to_chat(src, span_warning("OOC is globally muted"))
			return
		if(prefs.muted & MUTE_OOC)
			to_chat(src, span_warning("You cannot use OOC (muted)."))
			return
		if(handle_spam_prevention(msg, MUTE_OOC))
			return
		if(findtext(msg, "byond://"))
			to_chat(src, span_danger("Advertising other servers is not allowed."))
			log_admin_private("[key_name(usr)] has attempted to advertise in OOC: [msg]")
			message_admins("[ADMIN_TPMONTY(usr)] has attempted to advertise in OOC: [msg]")
			return

	if(is_banned_from(ckey, "OOC"))
		to_chat(src, span_warning("You have been banned from OOC."))
		return

	var/list/filter_result = is_ooc_filtered(msg)
	if(!CAN_BYPASS_FILTER(usr) && filter_result)
		REPORT_CHAT_FILTER_TO_USER(usr, filter_result)
		log_filter("MOOC", msg, filter_result)
		return

	// Protect filter bypassers from themselves.
	// Demote hard filter results to soft filter results if necessary due to the danger of accidentally speaking in OOC.
	var/list/soft_filter_result = filter_result || is_soft_ooc_filtered(msg)

	if(soft_filter_result)
		if(tgui_alert(usr,"Your message contains \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\". \"[soft_filter_result[CHAT_FILTER_INDEX_REASON]]\", Are you sure you want to say it?", "Soft Blocked Word", list("Yes", "No")) != "Yes")
			return
		message_admins("[ADMIN_LOOKUPFLW(usr)] has passed the soft filter for \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\" they may be using a disallowed term. Message: \"[msg]\"")
		log_admin_private("[key_name(usr)] has passed the soft filter for \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\" they may be using a disallowed term. Message: \"[msg]\"")

	mob.log_talk(msg, LOG_MOOC)

	var/display_name = mob.name
	if(!(mob in GLOB.human_mob_list) && !(mob in GLOB.ai_list) && admin)
		display_name = holder?.fakekey ? "Administrator" : key
	var/nickname_html = color_ooc_nickname(html_encode(display_name))

	// Send chat message to non-admins
	for(var/client/C AS in GLOB.clients)
		if(!(C.prefs.toggles_chat & CHAT_OOC))
			continue
		if(!(C.mob in GLOB.human_mob_list) && !(C.mob in GLOB.observer_list) && !(C.mob in GLOB.ai_list) || check_other_rights(C, R_ADMIN|R_MENTOR, FALSE)) // If the client is a human, an observer, and not staff.
			continue

		var/avoid_highlight = C == src
		to_chat(C, "<span class='ooc' style='color:#B75800'>[span_prefix("MOOC: [nickname_html]")]: <span class='message linkify'>[msg]</span></span>", avoid_highlighting = avoid_highlight)

	var/staff_display_name = ooc_staff_display_name()
	// Send chat message to admins
	for(var/client/C AS in GLOB.admins)
		if(!check_other_rights(C, R_ADMIN|R_MENTOR, FALSE)) // Check if the client is still staff.
			continue
		if(!C.prefs.hear_ooc_anywhere_as_staff)
			continue
		if(!(C.prefs.toggles_chat & CHAT_OOC))
			continue

		var/avoid_highlight = C == src
		var/channel_label = span_tooltip("You are seeing this because you are staff and have hearing OOC channels from anywhere enabled.", "MOOC")
		to_chat(C, "<span class='ooc' style='color:#B75800'>[span_prefix("[channel_label]: [staff_display_name]")]: <span class='message linkify'>[msg]</span></span>", avoid_highlighting = avoid_highlight)


/client/verb/looc_wrapper()
	set hidden = TRUE
	var/message = input("", "LOOC \"text\"") as null|text
	looc(message)

/client/verb/looc(msg as text)
	set name = "LOOC"
	set category = "OOC.Chat"

	if(!msg)
		return
	var/admin = check_rights(R_ADMIN|R_MENTOR, FALSE)

	if(!mob)
		return

	if(mob.stat == DEAD && !admin)
		to_chat(src, span_warning("You must be alive to use LOOC."))
		return

	if(IsGuestKey(key))
		to_chat(src, "Guests may not use LOOC.")
		return

	msg = copytext_char(sanitize(msg), 1, MAX_MESSAGE_LEN)

	if(!msg)
		return

	if(!(prefs.toggles_chat & CHAT_LOOC))
		to_chat(src, span_warning("You have LOOC muted."))
		return

	if(!admin)
		if(!CONFIG_GET(flag/looc_enabled))
			to_chat(src, span_warning("LOOC is globally muted"))
			return
		if(prefs.muted & MUTE_LOOC)
			to_chat(src, span_warning("You cannot use LOOC (muted)."))
			return
		if(handle_spam_prevention(msg, MUTE_LOOC))
			return
		if(findtext(msg, "byond://"))
			to_chat(src, "<B>Advertising other servers is not allowed.</B>")
			log_admin_private("[key_name(usr)] has attempted to advertise in LOOC: [msg]")
			message_admins("[ADMIN_TPMONTY(usr)] has attempted to advertise in LOOC: [msg]")
			return

	var/list/filter_result = is_ooc_filtered(msg)
	if(!CAN_BYPASS_FILTER(usr) && filter_result)
		REPORT_CHAT_FILTER_TO_USER(usr, filter_result)
		log_filter("LOOC", msg, filter_result)
		return

	// Protect filter bypassers from themselves.
	// Demote hard filter results to soft filter results if necessary due to the danger of accidentally speaking in OOC.
	var/list/soft_filter_result = filter_result || is_soft_ooc_filtered(msg)

	if(soft_filter_result)
		if(tgui_alert(usr,"Your message contains \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\". \"[soft_filter_result[CHAT_FILTER_INDEX_REASON]]\", Are you sure you want to say it?", "Soft Blocked Word", list("Yes", "No")) != "Yes")
			return
		message_admins("[ADMIN_LOOKUPFLW(usr)] has passed the soft filter for \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\" they may be using a disallowed term. Message: \"[msg]\"")
		log_admin_private("[key_name(usr)] has passed the soft filter for \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\" they may be using a disallowed term. Message: \"[msg]\"")

	if(is_banned_from(ckey, "LOOC"))
		to_chat(src, span_warning("You have been banned from LOOC."))
		return

	mob.log_talk(msg, LOG_LOOC)

	var/display_name = mob.name
	if(admin && isobserver(mob))
		display_name = holder?.fakekey ? "Administrator" : key
	var/nickname_html = color_ooc_nickname(html_encode(display_name))
	var/message = span_looc("[span_prefix("LOOC:")] [nickname_html]: [span_message(msg)]")
	for(var/mob/M in range(mob))
		to_chat(M, message)

	var/staff_display_name = ooc_staff_display_name()
	for(var/client/C AS in GLOB.admins)
		if(!check_other_rights(C, R_ADMIN|R_MENTOR, FALSE))
			continue
		if(!C.prefs.hear_ooc_anywhere_as_staff)
			continue
		if(C.mob == mob)
			continue

		if(C.prefs.toggles_chat & CHAT_LOOC)
			var/channel_label = span_tooltip("You are seeing this because you are staff and have hearing OOC channels from anywhere enabled.", "LOOC")
			to_chat(C, span_ooc("[span_prefix("[channel_label]: [staff_display_name]:")] [span_message(msg)]"))

/client/verb/motd()
	set name = "MOTD"
	set category = "OOC"
	set desc ="Check the Message of the Day"

	if(GLOB.motd)
		to_chat(src, span_motd("[GLOB.motd]"))
	else
		to_chat(src, span_warning("The motd is not set in the server configuration."))


/client/verb/stop_sounds()
	set name = "Stop Sounds"
	set category = "OOC.Fix"
	set desc = "Stop Current Sounds"

	SEND_SOUND(src, sound(null))
	tgui_panel?.stop_music()


/client/verb/tracked_playtime()
	set category = "OOC"
	set name = "View Tracked Playtime"
	set desc = "View the amount of playtime for roles the server has tracked."

	if(!CONFIG_GET(flag/use_exp_tracking))
		to_chat(usr, span_notice("Sorry, tracking is currently disabled."))
		return

	var/list/body = list()
	body += get_exp_report()

	var/datum/browser/popup = new(src, "playerplaytime[ckey]", "<div align='center'>Playtime for [key]</div>", 550, 615)
	popup.set_content(body.Join())
	popup.open(FALSE)


/client/verb/view_admin_remarks()
	set category = "OOC"
	set name = "View Admin Remarks"

	if(!CONFIG_GET(flag/see_own_notes))
		to_chat(usr, span_notice("Sorry, that function is not enabled on this server."))
		return

	browse_messages(null, ckey, null, TRUE)


/client/verb/fit_viewport()
	set name = "Fit Viewport"
	set category = "OOC.Fix"
	set desc = "Fit the width of the map window to match the viewport"

	// Fetch aspect ratio
	var/view_size = getviewsize(view)
	var/aspect_ratio = view_size[1] / view_size[2]

	// Calculate desired pixel width using window size and aspect ratio
	var/list/sizes = params2list(winget(src, "mainwindow.split;mapwindow", "size"))

	// Client closed the window? Some other error? This is unexpected behaviour, let's
	// CRASH with some info.
	if(!sizes["mapwindow.size"])
		CRASH("sizes does not contain mapwindow.size key. This means a winget failed to return what we wanted. --- sizes var: [sizes] --- sizes length: [length(sizes)]")

	var/list/map_size = splittext(sizes["mapwindow.size"], "x")

	// Gets the type of zoom we're currently using from our view datum
	// If it's 0 we do our pixel calculations based off the size of the mapwindow
	// If it's not, we already know how big we want our window to be, since zoom is the exact pixel ratio of the map
	var/zoom_value = src.view_size?.zoom || 0

	var/desired_width = 0
	if(zoom_value)
		desired_width = round(view_size[1] * zoom_value * ICON_SIZE_X)
	else

		// Looks like we expect mapwindow.size to be "ixj" where i and j are numbers.
		// If we don't get our expected 2 outputs, let's give some useful error info.
		if(length(map_size) != 2)
			CRASH("map_size of incorrect length --- map_size var: [map_size] --- map_size length: [length(map_size)]")
		var/height = text2num(map_size[2])
		desired_width = round(height * aspect_ratio)

	if (text2num(map_size[1]) == desired_width)
		// Nothing to do
		return

	var/split_size = splittext(sizes["mainwindow.split.size"], "x")
	var/split_width = text2num(split_size[1])

	// Avoid auto-resizing the statpanel and chat into nothing.
	desired_width = min(desired_width, split_width - 300)

	// Calculate and apply a best estimate
	// +4 pixels are for the width of the splitter's handle
	var/pct = 100 * (desired_width + 4) / split_width
	winset(src, "mainwindow.split", "splitter=[pct]")

	// Apply an ever-lowering offset until we finish or fail
	var/delta
	for(var/safety in 1 to 10)
		var/after_size = winget(src, "mapwindow", "size")
		map_size = splittext(after_size, "x")
		var/got_width = text2num(map_size[1])

		if (got_width == desired_width)
			// success
			return
		else if (isnull(delta))
			// calculate a probable delta value based on the difference
			delta = 100 * (desired_width - got_width) / split_width
		else if ((delta > 0 && got_width > desired_width) || (delta < 0 && got_width < desired_width))
			// if we overshot, halve the delta and reverse direction
			delta = -delta * 0.5

		pct += delta
		winset(src, "mainwindow.split", "splitter=[pct]")

/// Attempt to automatically fit the viewport, assuming the user wants it
/client/proc/attempt_auto_fit_viewport()
	if (!prefs.auto_fit_viewport)
		return
	if(fully_created)
		INVOKE_ASYNC(src, VERB_REF(fit_viewport))
	else //Delayed to avoid wingets from Login calls.
		INVOKE_NEXT_TICK(src, VERB_REF(fit_viewport), 1 SECONDS)

/client/verb/policy()
	set name = "Show Policy"
	set desc = "Show special server rules related to your current character."
	set category = "OOC"

	//Collect keywords
	var/list/keywords = mob.get_policy_keywords()
	var/header = get_policy(POLICY_VERB_HEADER)
	var/list/policytext = list(header,"<hr>")
	var/anything = FALSE
	for(var/keyword in keywords)
		var/p = get_policy(keyword)
		if(p)
			policytext += p
			policytext += "<hr>"
			anything = TRUE
	if(!anything)
		policytext += "No related rules found."

	var/datum/browser/popup = new(usr, "policy")
	popup.set_content(policytext.Join(""))
	popup.open(FALSE)

/client/verb/update_ping(time as num)
	set instant = TRUE
	set name = ".update_ping"
	var/ping = pingfromtime(time)
	lastping = ping
	if(!avgping)
		avgping = ping
	else
		avgping = MC_AVERAGE_SLOW(avgping, ping)


/client/proc/pingfromtime(time)
	return ((world.time + world.tick_lag * TICK_USAGE_REAL * 0.01) - time) * 100


/client/verb/display_ping(time as num)
	set instant = TRUE
	set name = ".display_ping"
	to_chat(src, span_notice("Round trip ping took [round(pingfromtime(time), 1)]ms"))


/client/verb/ping()
	set name = "Ping"
	set category = "OOC.Fix"
	winset(src, null, "command=.display_ping+[world.time + world.tick_lag * TICK_USAGE_REAL * 0.01]")

/client/verb/fix_stat_panel()
	set name = "Fix Stat Panel"
	set hidden = TRUE

	init_verbs()

/client/verb/select_ignore()
	set name = "Ignore"
	set category = "OOC"
	set desc ="Ignore a player's messages on the OOC channel"

	var/list/players = list()

	// Use keys and fakekeys for the same purpose
	var/displayed_key = ""

	for(var/client/C in GLOB.clients)
		if(C == src)
			continue
		if((C.key in prefs.ignoring) && !C.holder?.fakekey)
			continue
		if(C.holder?.fakekey in prefs.ignoring)
			continue
		if(C.holder?.fakekey)
			displayed_key = C.holder.fakekey
		else
			displayed_key = C.key

		// Check if both we and the player are ghosts and they're not using a fakekey
		if(isobserver(mob) && isobserver(C.mob) && !C.holder?.fakekey)
			players["[displayed_key](ghost)"] = displayed_key
		else
			players[displayed_key] = displayed_key

	if(!length(players))
		to_chat(src, span_infoplain("There are no other players you can ignore!"))
		return

	players = sort_list(players)

	var/selection = tgui_input_list(src, "Select a player", "Ignore", players)

	if(isnull(selection) || !(selection in players))
		return

	selection = players[selection]

	if(selection in prefs.ignoring)
		to_chat(src, span_infoplain("You are already ignoring [selection]!"))
		return

	prefs.ignoring.Add(selection)
	prefs.save_preferences()

	to_chat(src, span_infoplain("You are now ignoring [selection] on the OOC channel."))

/client/verb/select_unignore()
	set name = "Unignore"
	set category = "OOC"
	set desc = "Stop ignoring a player's messages on the OOC channel"

	if(!length(prefs.ignoring))
		to_chat(src, span_infoplain("You haven't ignored any players!"))
		return

	var/selection = tgui_input_list(src, "Select a player", "Unignore", prefs.ignoring)

	if(isnull(selection))
		return

	if(!(selection in prefs.ignoring))
		to_chat(src, span_infoplain("You are not ignoring [selection]!"))
		return

	prefs.ignoring.Remove(selection)
	prefs.save_preferences()

	to_chat(src, span_infoplain("You are no longer ignoring [selection] on the OOC channel."))
