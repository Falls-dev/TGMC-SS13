SUBSYSTEM_DEF(who)
	name = "Who"
	flags = SS_BACKGROUND
	runlevels = RUNLEVELS_DEFAULT|RUNLEVEL_LOBBY
	wait = 5 SECONDS

	var/datum/player_list/who = new
	var/datum/player_list/staff/staff_who = new

/datum/controller/subsystem/who/Initialize()
	who.update_data()
	staff_who.update_data()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/who/fire(resumed = TRUE)
	who.update_data()
	staff_who.update_data()


// WHO DATA
/datum/player_list
	var/tgui_name = "Who"
	var/tgui_interface_name = "Who"
	var/list/base_data = list()
	var/list/admin_sorted_additional = list()

/datum/player_list/proc/update_data()
	var/list/base_data = list()
	var/list/admin_sorted_additional = list()

	var/list/factions_additional = list()
	admin_sorted_additional["factions_additional"] = list("flags" = R_ADMIN, "data" = factions_additional)

	var/list/player_additional = list()
	admin_sorted_additional["player_additional"] = list("flags" = R_ADMIN, "data" = player_additional)

	// Fakekey / stealth-mode players; TGMC has no R_STEALTH, so R_ADMIN sees these.
	var/list/player_stealthed_additional = list()
	admin_sorted_additional["player_stealthed_additional"] = list("flags" = R_ADMIN, "data" = player_stealthed_additional)

	var/list/counted_additional = list(
		"lobby" = 0,
		"admin_observers" = 0,
		"observers" = 0,
		"yautja" = 0,
		"infected_preds" = 0,
		"humans" = 0,
		"infected_humans" = 0,
		"terragov" = 0,
		"terragov_marines" = 0,
		"xenos" = 0,
	)
	var/list/counted_factions = list()

	for(var/client/client as anything in sortTim(GLOB.clients.Copy(), GLOBAL_PROC_REF(cmp_ckey_asc)))
		var/list/client_payload = list()
		client_payload["text"] = client.key
		client_payload["ckey_color"] = "white"

		if(client.holder?.fakekey)
			player_stealthed_additional["total_players"] += list(list("[client.key]" = list(client_payload)))
		else
			base_data["total_players"] += list(list("[client.key]" = list(client_payload.Copy())))
			player_additional["total_players"] += list(list("[client.key]" = list(client_payload)))

		var/mob/client_mob = client.mob
		if(!client_mob)
			continue

		if(isnewplayer(client_mob))
			client_payload["text"] += " - in Lobby"
			counted_additional["lobby"]++

		else if(isobserver(client_mob))
			client_payload["text"] += " - Playing as [client_mob.real_name]"
			if(check_other_rights(client, R_ADMIN, FALSE))
				counted_additional["admin_observers"]++
			else
				counted_additional["observers"]++

			var/mob/dead/observer/observer = client_mob
			if(observer.started_as_observer)
				client_payload["color"] = "#ce89cd"
				client_payload["text"] += " - Spectating"
			else
				client_payload["color"] = "#A000D0"
				client_payload["text"] += " - DEAD"

		else
			client_payload["text"] += " - Playing as [client_mob.real_name]"

			switch(client_mob.stat)
				if(UNCONSCIOUS)
					client_payload["color"] = "#B0B0B0"
					client_payload["text"] += " - Unconscious"
				if(DEAD)
					client_payload["color"] = "#A000D0"
					client_payload["text"] += " - DEAD"

			if(client_mob.stat != DEAD)
				if(isxeno(client_mob))
					client_payload["color"] = "#ec3535"
					client_payload["text"] += " - Xenomorph"
					counted_additional["xenos"]++

				else if(ishuman(client_mob))
					var/mob/living/carbon/human/human_mob = client_mob
					if(human_mob.faction == FACTION_ZOMBIE)
						counted_factions[FACTION_ZOMBIE]++
						client_payload["color"] = "#2DACB1"
						client_payload["text"] += " - Zombie"
					else if(human_mob.faction == FACTION_YAUTJA)
						client_payload["color"] = "#7ABA19"
						client_payload["text"] += " - Yautja"
						counted_additional["yautja"]++
						if(human_mob.status_flags & XENO_HOST)
							counted_additional["infected_preds"]++
					else
						counted_additional["humans"]++
						if(human_mob.status_flags & XENO_HOST)
							counted_additional["infected_humans"]++
						if(human_mob.faction == FACTION_TERRAGOV)
							counted_additional["terragov"]++
							if(ismarinejob(human_mob.job))
								counted_additional["terragov_marines"]++
						else
							counted_factions[human_mob.faction]++

	factions_additional += list(list("content" = "In Lobby: [counted_additional["lobby"]]", "color" = "#777", "text" = "Players in lobby"))
	factions_additional += list(list("content" = "Spectating Players: [counted_additional["observers"]]", "color" = "#777", "text" = "Spectating players"))
	factions_additional += list(list("content" = "Spectating Admins: [counted_additional["admin_observers"]]", "color" = "#777", "text" = "Spectating administrators"))
	factions_additional += list(list("content" = "Humans: [counted_additional["humans"]]", "color" = "#2C7EFF", "text" = "Players playing as Human"))
	factions_additional += list(list("content" = "Infected Humans: [counted_additional["infected_humans"]]", "color" = "#ec3535", "text" = "Players playing as Infected Human"))
	factions_additional += list(list("content" = "TerraGov Personnel: [counted_additional["terragov"]]", "color" = "#5442bd", "text" = "Players playing as TerraGov Personnel"))
	factions_additional += list(list("content" = "Marines: [counted_additional["terragov_marines"]]", "color" = "#5442bd", "text" = "Players playing as Marines"))
	factions_additional += list(list("content" = "Xenos: [counted_additional["xenos"]]", "color" = "#8200FF", "text" = "Players playing as Xenomorph"))
	factions_additional += list(list("content" = "Yautja: [counted_additional["yautja"]]", "color" = "#7ABA19", "text" = "Players playing as Yautja"))
	factions_additional += list(list("content" = "Infected Predators: [counted_additional["infected_preds"]]", "color" = "#7ABA19", "text" = "Players playing as Infected Yautja"))

	for(var/faction_name in counted_factions)
		if(!counted_factions[faction_name])
			continue
		factions_additional += list(list("content" = "[faction_name]: [counted_factions[faction_name]]", "color" = "#2C7EFF", "text" = "Other"))

	if(counted_factions[FACTION_NEUTRAL])
		factions_additional += list(list("content" = "[FACTION_NEUTRAL] Humans: [counted_factions[FACTION_NEUTRAL]]", "color" = "#688944", "text" = "Neutrals"))

	for(var/hivenumber in GLOB.hive_datums)
		var/datum/hive_status/hive = GLOB.hive_datums[hivenumber]
		if(!hive)
			continue
		var/xeno_count = hive.get_total_xeno_number()
		if(!xeno_count)
			continue
		factions_additional += list(list(
			"content" = "[hive.name]: [xeno_count]",
			"color" = hive.color ? hive.color : "#8200FF",
			"text" = "Ruler: [hive.living_xeno_ruler ? "Alive" : "Dead"]",
		))

	src.base_data = base_data
	src.admin_sorted_additional = admin_sorted_additional

/datum/player_list/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, tgui_name, tgui_interface_name)
		ui.open()
		ui.set_autoupdate(TRUE)

/datum/player_list/ui_state(mob/user)
	return GLOB.always_state

/datum/player_list/ui_data(mob/user)
	. = list()
	.["base_data"] = base_data

	if(!check_other_rights(user.client, R_ADMIN, FALSE))
		return
	for(var/data_packet_name in admin_sorted_additional)
		if(!check_other_rights(user.client, admin_sorted_additional[data_packet_name]["flags"], FALSE))
			continue
		. += list("[data_packet_name]" = admin_sorted_additional[data_packet_name]["data"])

/datum/player_list/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("get_player_panel")
			if(!check_other_rights(ui.user.client, R_ADMIN, FALSE))
				return
			var/chosen_ckey = params["ckey"]
			for(var/client/target in GLOB.clients)
				if(target.key != chosen_ckey)
					continue
				if(target.mob)
					SSadmin_verbs.dynamic_invoke_verb(ui.user.client, /datum/admin_verb/show_player_panel, target.mob)
				break

/datum/player_list/ui_status(mob/user, datum/ui_state/state)
	return UI_INTERACTIVE


// STAFF DATA
/datum/player_list/staff
	tgui_name = "StaffWho"
	tgui_interface_name = "Staff Who"

	var/list/category_colors = list(
		"Administrators" = "red",
		"Mentors" = "green",
	)

/datum/player_list/staff/update_data()
	var/list/base_data = list()
	var/list/admin_sorted_additional = list()

	var/list/admin_additional = list()
	admin_sorted_additional["admin_additional"] = list("flags" = R_ADMIN, "data" = admin_additional)

	var/list/admin_stealthed_additional = list()
	admin_sorted_additional["admin_stealthed_additional"] = list("flags" = R_ADMIN, "data" = admin_stealthed_additional)

	var/list/listings = list(
		"Administrators" = list(),
		"Mentors" = list(),
	)

	for(var/client/client as anything in GLOB.admins)
		if(check_other_rights(client, R_ADMIN, FALSE))
			listings["Administrators"] += client
		else if(is_mentor(client))
			listings["Mentors"] += client

	for(var/category in listings)
		base_data["categories"] += list(list(
			"category" = category,
			"category_color" = category_colors[category],
		))

		for(var/client/client as anything in listings[category])
			var/list/admin_payload = list()
			admin_payload["category"] = category
			admin_payload["special_text"] = ""
			var/rank = client.holder?.rank?.name || "Unknown"

			if(client.holder?.fakekey)
				admin_payload["special_color"] = "#7b582f"
				admin_payload["special_text"] += " (HIDDEN)"
				admin_additional["total_admins"] += list(list("[client.key] ([rank])" = list(admin_payload)))
			else
				admin_additional["total_admins"] += list(list("[client.key] ([rank])" = list(admin_payload)))
				base_data["total_admins"] += list(list("[client.key] ([rank])" = list(admin_payload.Copy())))

			admin_payload["text"] = ""
			if(isobserver(client.mob))
				admin_payload["color"] = "#808080"
				admin_payload["text"] += "Spectating"
			else if(isnewplayer(client.mob))
				admin_payload["color"] = "#FFFFFF"
				admin_payload["text"] += "in Lobby"
			else
				admin_payload["color"] = "#688944"
				admin_payload["text"] += "Playing"

			if(client.is_afk())
				admin_payload["color"] = "#A040D0"
				admin_payload["special_text"] += " (AFK)"

	src.base_data = base_data
	src.admin_sorted_additional = admin_sorted_additional
