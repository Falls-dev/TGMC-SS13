GLOBAL_LIST_EMPTY(escape_menus)

/client/var/datum/escape_menu/escape_menu

/client/proc/initialize_escape_menu()
	set waitfor = FALSE
	sleep(3 SECONDS)
	escape_menu = new(src)

/datum/escape_menu
	var/client/client
	var/datum/tgui_window/window

	/// If we've already notified the user that their BYOND version is not cool with transparent browsers
	var/version_warned

/datum/escape_menu/New(client/client)
	src.client = client
	window = new(client, "escape_menu")
	window.is_browser = TRUE
	window.initialize(
		strict_mode = TRUE,
		inline_css = file("tgui/public/tgui-escape-menu.bundle.css"),
		inline_js = file("tgui/public/tgui-escape-menu.bundle.js"),
	)
	// initialize() re-detects control type; keep embedded-browser messaging path
	window.is_browser = TRUE
	// 516.1680+ only — older clients error on unknown inner-background-color
	if(client.byond_build >= 1680)
		winset(client, "mapwindow.escape_menu", "inner-background-color=transparent")
	window.send_asset(get_asset_datum(/datum/asset/simple/namespaced/escape_menu_font))
	window.send_asset(get_asset_datum(/datum/asset/simple/namespaced/escape_menu_sounds))
	window.send_asset(get_asset_datum(/datum/asset/spritesheet/escape_menu_icons))
	window.subscribe(src, PROC_REF(on_message))

	RegisterSignal(client, COMSIG_QDELETING, PROC_REF(on_client_qdel))
	RegisterSignal(client, COMSIG_CLIENT_MOB_LOGIN, PROC_REF(on_client_mob_login))
	RegisterSignals(client, list(COMSIG_CLIENT_VERB_ADDED, COMSIG_CLIENT_VERB_REMOVED), PROC_REF(on_verb_change))
	RegisterSignal(SSticker, COMSIG_TICKER_ROUND_STARTING, PROC_REF(on_round_start))

	GLOB.escape_menus += src
	send_init()

/datum/escape_menu/Destroy(force)
	GLOB.escape_menus -= src
	STOP_PROCESSING(SSescape_menu, src)
	window?.unsubscribe(src)
	window = null
	client = null
	return ..()

/datum/escape_menu/process(seconds_per_tick)
	send_update(list(
		"serverTime" = time_stamp("hh:mm:ss"),
		"shiftTime" = (SSticker.round_start_time == 0) ? "Pre-Game" : stationTimestamp("hh:mm:ss"),
		"timeDilation" = "[round(SStime_track.time_dilation_current, 1)]",
		"players" = build_player_list(),
		"ignoredOffline" = build_ignored_offline(),
	))

/datum/escape_menu/proc/on_client_qdel()
	SIGNAL_HANDLER
	qdel(src)

/datum/escape_menu/proc/on_client_mob_login()
	SIGNAL_HANDLER
	send_update(list(
		"canLeaveBody" = isliving(client?.mob),
	))

/datum/escape_menu/proc/on_verb_change(client/source, list/verbs_changed)
	SIGNAL_HANDLER
	if(/client/verb/adminhelp in verbs_changed)
		send_update(list(
			"canAdminHelp" = (/client/verb/adminhelp in client?.verbs),
		))

/datum/escape_menu/proc/on_round_start()
	SIGNAL_HANDLER
	send_update(list(
		"gameshipName" = get_true_gameship_name(),
		"mapName" = length(SSmapping.configs) ? SSmapping.configs[GROUND_MAP].map_name : "Загрузка...",
		"shipMapName" = length(SSmapping.configs) ? SSmapping.configs[SHIP_MAP].map_name : "Загрузка...",
		"gameModeName" = GLOB.master_mode,
		"shiftTime" = stationTimestamp("hh:mm:ss"),
		"timeDilation" = "[round(SStime_track.time_dilation_current, 1)]",
	))

/datum/escape_menu/proc/get_true_gameship_name()
	if(SSticker.mode?.esc_menu_name)
		return SSticker.mode.esc_menu_name
	return CONFIG_GET(string/server_name) || "TGMC"

/datum/escape_menu/proc/send_init()
	var/list/resources = list()

	var/githuburl = CONFIG_GET(string/githuburl)
	if(githuburl)
		resources += list(list("id" = "github", "label" = "Github", "tooltip" = "Открыть репозиторий на Github"))

	var/discordurl = CONFIG_GET(string/discordurl)
	if(discordurl)
		resources += list(list("id" = "forums", "label" = "Discord", "tooltip" = "Присоединиться к серверу Discord"))

	var/rulesurl = CONFIG_GET(string/rulesurl)
	if(rulesurl)
		resources += list(list("id" = "rules", "label" = "Правила", "tooltip" = "Просмотреть правила сервера"))

	var/wikiurl = CONFIG_GET(string/wikiurl)
	if(wikiurl)
		resources += list(list("id" = "wiki", "label" = "Вики", "tooltip" = "Почитать вики по серверу"))

	var/donationurl = CONFIG_GET(string/donationurl)
	if(donationurl)
		resources += list(list("id" = "config", "label" = "Донаты", "tooltip" = "Поддержать сервер"))

	resources += list(list("id" = "changelog", "label" = "Изменения", "tooltip" = "Посмотреть изменения в игре"))

	if(CONFIG_GET(string/webmap_host))
		resources += list(list("id" = "bug", "label" = "Карта", "tooltip" = "Посмотреть игровые карты"))

	window.send_message("init", list(
		"gameshipName" = get_true_gameship_name(),
		"roundId" = GLOB.round_id || "ДЕБАГ",
		"serverTime" = time_stamp("hh:mm:ss"),
		"shiftTime" = (SSticker.round_start_time == 0) ? "12:00:00" : stationTimestamp("hh:mm:ss"),
		"timeDilation" = "[round(SStime_track.time_dilation_current, 1)]",
		"mapName" = length(SSmapping.configs) ? SSmapping.configs[GROUND_MAP].map_name : "Загрузка...",
		"shipMapName" = length(SSmapping.configs) ? SSmapping.configs[SHIP_MAP].map_name : "Загрузка...",
		"gameModeName" = GLOB.master_mode,
		"mapFeedbackLink" = null,
		"canLeaveBody" = isliving(client?.mob),
		"canAdminHelp" = (/client/verb/adminhelp in client?.verbs),
		"canSeeNotes" = CONFIG_GET(flag/see_own_notes),
		"hasTicketNotification" = !isnull(client?.current_ticket),
		"players" = build_player_list(),
		"ignoredOffline" = build_ignored_offline(),
		"resources" = resources,
	))

/datum/escape_menu/proc/build_player_list()
	var/list/result = list()
	for(var/client/player as anything in GLOB.clients)
		result += list(list(
			"ckey" = player.ckey,
			"displayName" = player.ckey,
			"ping" = round(player.avgping, 1),
			"ignored" = (player.ckey in client?.prefs?.ignoring),
			"isSelf" = (player.ckey == client?.ckey),
		))
	return result

/datum/escape_menu/proc/build_ignored_offline()
	var/list/result = list()
	if(client?.prefs?.ignoring)
		for(var/ignored_key in client.prefs.ignoring)
			if(!(ignored_key in GLOB.directory))
				result += ignored_key
	return result

/datum/escape_menu/proc/send_update(list/data)
	window.send_message("state", data)

// Временно завёз с новотг
/datum/escape_menu/proc/player_view_ticket(datum/admin_help/ticket)
	if(!ticket)
		to_chat(client, span_warning("You have not had an ahelp ticket this round."))
		return
	var/list/dat = list("<html><head><meta http-equiv='Content-Type' content='text/html; charset=UTF-8'><title>Player Ticket</title></head>")
	dat += "<b>State: "
	switch(ticket.state)
		if(AHELP_ACTIVE)
			dat += "<font color='red'>OPEN</font></b>"
		if(AHELP_RESOLVED)
			dat += "<font color='green'>RESOLVED</font></b>"
		if(AHELP_CLOSED)
			dat += "CLOSED</b>"
		else
			dat += "UNKNOWN</b>"
	dat += "<br><br>Opened at: [stationTimestamp("hh:mm:ss", ticket.opened_at)] (Approx [DisplayTimeText(world.time - ticket.opened_at)] ago)"
	if(ticket.closed_at)
		dat += "<br>Closed at: [stationTimestamp("hh:mm:ss", ticket.closed_at)] (Approx [DisplayTimeText(world.time - ticket.closed_at)] ago)"
	dat += "<br><br><br><b>Log:</b><br><br>"
	for(var/interaction in ticket._interactions)
		dat += "[interaction]<br>"

	var/datum/browser/player_panel = new(client.mob, "ahelp[ticket.id]", "Ticket #[ticket.id]", 620, 480)
	player_panel.set_content(dat.Join())
	player_panel.open()

/datum/escape_menu/proc/on_message(type, payload, href_list)
	if(type == "ready")
		send_init()
		return TRUE

	if(type != "action")
		return FALSE

	var/action = payload["action"]
	switch(action)
		if("opened")
			if(!version_warned && client.byond_build < 1680)
				to_chat(client, span_warning("Ваша версия BYOND не достаточно новая для корректного отображения меню, пожалуйста обновитесь до версии 516.1680 или выше."))
				version_warned = TRUE

			START_PROCESSING(SSescape_menu, src)
		if("closed")
			STOP_PROCESSING(SSescape_menu, src)
		if("character")
			client?.prefs.tab_index = CHARACTER_CUSTOMIZATION
			client?.prefs.ShowChoices(client?.mob)
		if("settings")
			client?.prefs.tab_index = GAME_SETTINGS
			client?.prefs.ShowChoices(client?.mob)
		if("create_ticket")
			if(!(/client/verb/adminhelp in client?.verbs))
				return TRUE
			winset(client, null, "command=choosehelp")
		if("view_ticket")
			if(client?.current_ticket)
				player_view_ticket(client.current_ticket)
				return TRUE
			var/list/prev_tickets = list()
			for(var/datum/admin_help/resolved_ticket as anything in GLOB.ahelp_tickets.resolved_tickets)
				if(resolved_ticket.initiator_ckey == client?.ckey)
					prev_tickets += resolved_ticket
			for(var/datum/admin_help/closed_ticket as anything in GLOB.ahelp_tickets.closed_tickets)
				if(closed_ticket.initiator_ckey == client?.ckey)
					prev_tickets += closed_ticket
			if(length(prev_tickets))
				player_view_ticket(prev_tickets[length(prev_tickets)])
			else
				to_chat(client, span_warning("Открытых тикетов не найдено."))
		if("pray")
			winset(client, null, "command=Pray")
		if("see_notes")
			if(!CONFIG_GET(flag/see_own_notes))
				to_chat(client.mob, span_notice("Кажется у вас нет прав на просмотр своих заметок."))
				return TRUE
			browse_messages(null, client.ckey, null, TRUE)
		if("ghost")
			var/mob/living/living_user = client?.mob
			if(isliving(living_user))
				living_user.ghost()
		if("quit")
			winset(client, null, "command=.quit")
		if("resource_github")
			client?.github()
		if("resource_forums")
			client?.discord()
		if("resource_rules")
			client?.rules()
		if("resource_wiki")
			client?.wiki()
		if("resource_config")
			client?.boosty()
		if("resource_changelog")
			client?.changes()
		if("resource_bug")
			client?.webmap()
		if("toggle_ignore")
			var/ckey = payload["ckey"]
			if(!ckey || ckey == client?.ckey)
				return TRUE
			if(ckey in client?.prefs?.ignoring)
				client.prefs.ignoring -= ckey
			else
				LAZYADD(client.prefs.ignoring, ckey)
			client.prefs.save_preferences()
			to_chat(client, span_notice("[ckey] has been [(ckey in client.prefs.ignoring) ? "" : "un"]ignored in OOC."))

	return TRUE
