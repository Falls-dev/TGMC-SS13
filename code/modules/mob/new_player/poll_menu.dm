/**
 * # Poll menu
 *
 * TGUI front-end for lobby player polls. Voting still goes through the existing
 * /mob/new_player poll handlers and SSdbcore queries — this datum never talks to
 * the DB itself for writes.
 */
GLOBAL_DATUM_INIT(poll_menu, /datum/poll_menu, new)

/datum/poll_menu
	/// ckey -> REF of the poll currently being viewed (null = list view)
	var/list/viewing_by_ckey = list()

/datum/poll_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Polls", "Player Polls")
		ui.open()

/datum/poll_menu/ui_state(mob/user)
	return GLOB.new_player_state

/datum/poll_menu/ui_data(mob/user)
	var/list/data = list()
	data["is_admin"] = !!user.client?.holder

	var/list/poll_summaries = list()
	for(var/datum/poll_question/poll as anything in GLOB.polls)
		if((poll.admin_only && !user.client?.holder) || poll.future_poll)
			continue
		poll_summaries += list(list(
			"ref" = REF(poll),
			"question" = poll.question,
			"subtitle" = poll.subtitle || "",
			"poll_type" = poll.poll_type,
			"start_datetime" = poll.start_datetime,
			"end_datetime" = poll.end_datetime,
			"allow_revoting" = poll.allow_revoting,
			"admin_only" = poll.admin_only,
			"votes" = poll.poll_votes,
		))
	data["polls"] = poll_summaries

	var/viewing_ref = viewing_by_ckey[user.ckey]
	data["viewing"] = null
	if(viewing_ref && isnewplayer(user))
		var/datum/poll_question/viewing = locate(viewing_ref) in GLOB.polls
		if(istype(viewing) && !(viewing.admin_only && !user.client?.holder) && !viewing.future_poll)
			data["viewing"] = build_poll_detail(user, viewing)
		else
			viewing_by_ckey -= user.ckey

	return data

/datum/poll_menu/proc/build_poll_detail(mob/new_player/user, datum/poll_question/poll)
	var/list/detail = list(
		"ref" = REF(poll),
		"question" = poll.question,
		"subtitle" = poll.subtitle || "",
		"poll_type" = poll.poll_type,
		"start_datetime" = poll.start_datetime,
		"end_datetime" = poll.end_datetime,
		"allow_revoting" = poll.allow_revoting,
		"options_allowed" = poll.options_allowed || 1,
	)

	var/list/options_data = list()
	for(var/datum/poll_option/option as anything in poll.options)
		options_data += list(list(
			"ref" = REF(option),
			"text" = option.text,
			"min_val" = option.min_val,
			"max_val" = option.max_val,
			"desc_min" = option.desc_min || "",
			"desc_mid" = option.desc_mid || "",
			"desc_max" = option.desc_max || "",
		))
	detail["options"] = options_data

	if(!SSdbcore.Connect())
		return detail

	switch(poll.poll_type)
		if(POLLTYPE_OPTION)
			var/datum/db_query/query = SSdbcore.NewQuery({"
				SELECT optionid FROM [format_table_name("poll_vote")]
				WHERE pollid = :pollid AND ckey = :ckey AND deleted = 0
			"}, list("pollid" = poll.poll_id, "ckey" = user.ckey))
			if(query.warn_execute() && query.NextRow())
				var/voted_id = text2num(query.item[1])
				for(var/datum/poll_option/option as anything in poll.options)
					if(option.option_id == voted_id)
						detail["voted_option_ref"] = REF(option)
						break
			qdel(query)

		if(POLLTYPE_MULTI)
			var/datum/db_query/query = SSdbcore.NewQuery({"
				SELECT optionid FROM [format_table_name("poll_vote")]
				WHERE pollid = :pollid AND ckey = :ckey AND deleted = 0
			"}, list("pollid" = poll.poll_id, "ckey" = user.ckey))
			var/list/voted_refs = list()
			if(query.warn_execute())
				while(query.NextRow())
					var/voted_id = text2num(query.item[1])
					for(var/datum/poll_option/option as anything in poll.options)
						if(option.option_id == voted_id)
							voted_refs += REF(option)
							break
			qdel(query)
			detail["voted_option_refs"] = voted_refs

		if(POLLTYPE_RATING)
			var/datum/db_query/query = SSdbcore.NewQuery({"
				SELECT optionid, rating FROM [format_table_name("poll_vote")]
				WHERE pollid = :pollid AND ckey = :ckey AND deleted = 0
			"}, list("pollid" = poll.poll_id, "ckey" = user.ckey))
			var/list/voted_ratings = list()
			if(query.warn_execute())
				while(query.NextRow())
					var/voted_id = text2num(query.item[1])
					var/rating = text2num(query.item[2])
					for(var/datum/poll_option/option as anything in poll.options)
						if(option.option_id == voted_id)
							voted_ratings[REF(option)] = rating
							break
			qdel(query)
			detail["voted_ratings"] = voted_ratings

		if(POLLTYPE_TEXT)
			var/datum/db_query/query = SSdbcore.NewQuery({"
				SELECT replytext FROM [format_table_name("poll_textreply")]
				WHERE pollid = :pollid AND ckey = :ckey AND deleted = 0
			"}, list("pollid" = poll.poll_id, "ckey" = user.ckey))
			if(query.warn_execute() && query.NextRow())
				detail["reply_text"] = query.item[1]
			qdel(query)

	return detail

/datum/poll_menu/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(!isnewplayer(ui.user))
		return TRUE

	var/mob/new_player/owner = ui.user

	switch(action)
		if("back")
			viewing_by_ckey -= owner.ckey
			return TRUE

		if("view_poll")
			var/datum/poll_question/poll = locate(params["poll_ref"]) in GLOB.polls
			if(!istype(poll) || poll.future_poll)
				return TRUE
			if(poll.admin_only && !owner.client?.holder)
				return TRUE
			// IRV still needs the legacy jQuery sortable HTML window.
			if(poll.poll_type == POLLTYPE_IRV)
				owner.poll_player_irv(poll)
				return TRUE
			viewing_by_ckey[owner.ckey] = REF(poll)
			return TRUE

		if("vote_option")
			var/datum/poll_question/poll = locate(params["poll_ref"]) in GLOB.polls
			if(!istype(poll) || poll.poll_type != POLLTYPE_OPTION)
				return TRUE
			owner.vote_on_poll_handler(poll, list("voteoptionref" = params["option_ref"]))
			return TRUE

		if("vote_text")
			var/datum/poll_question/poll = locate(params["poll_ref"]) in GLOB.polls
			if(!istype(poll) || poll.poll_type != POLLTYPE_TEXT)
				return TRUE
			owner.vote_on_poll_handler(poll, list("replytext" = params["reply_text"]))
			return TRUE

		if("vote_multi")
			var/datum/poll_question/poll = locate(params["poll_ref"]) in GLOB.polls
			if(!istype(poll) || poll.poll_type != POLLTYPE_MULTI)
				return TRUE
			// vote_on_poll_multi cuts the first two Topic entries (src / votepollref).
			var/list/href_list = list("src" = "tgui", "votepollref" = REF(poll))
			var/list/option_refs = params["option_refs"]
			if(islist(option_refs))
				for(var/option_ref in option_refs)
					href_list[option_ref] = option_ref
			owner.vote_on_poll_handler(poll, href_list)
			return TRUE

		if("vote_rating")
			var/datum/poll_question/poll = locate(params["poll_ref"]) in GLOB.polls
			if(!istype(poll) || poll.poll_type != POLLTYPE_RATING)
				return TRUE
			var/list/href_list = list("src" = "tgui", "votepollref" = REF(poll))
			var/list/ratings = params["ratings"]
			if(islist(ratings))
				for(var/option_ref in ratings)
					href_list[option_ref] = ratings[option_ref]
			owner.vote_on_poll_handler(poll, href_list)
			return TRUE
