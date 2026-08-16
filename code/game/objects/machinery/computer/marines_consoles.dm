/obj/machinery/computer/marine_card
	name = "Identification Computer"
	desc = "You can use this to change ID's."
	icon_state = "computer_small"
	screen_overlay = "id"
	req_access = list(ACCESS_MARINE_LOGISTICS)
	circuit = /obj/item/circuitboard/computer/card
	resistance_flags = INDESTRUCTIBLE
	interaction_flags = INTERACT_MACHINE_TGUI
	var/obj/item/card/id/scan = null
	var/obj/item/card/id/modify = null
	var/authenticated = 0
	var/mode = 0
	var/printing = null

/obj/machinery/computer/marine_card/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(.)
		return

	if(istype(I, /obj/item/card/id))
		var/obj/item/card/id/idcard = I
		if(ACCESS_MARINE_LOGISTICS in idcard.access)
			if(scan && modify)
				to_chat(user, "Both slots are full already. Remove a card first.")
				return
			if(!scan)
				user.drop_held_item()
				idcard.forceMove(src)
				scan = idcard
			else if(!modify)
				user.drop_held_item()
				idcard.forceMove(src)
				modify = idcard
		else
			if(modify)
				to_chat(user, "The modifying slot is full already. Remove a card first.")
				return
			user.drop_held_item()
			idcard.forceMove(src)
			modify = idcard
	SStgui.update_uis(src)

/obj/machinery/computer/marine_card/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CardMod", name)
		ui.open()

/obj/machinery/computer/marine_card/ui_static_data(mob/user)
	. = list()
	.["jobs"] = (GLOB.jobs_regular_all - list(SYNTHETIC, SILICON_AI)) + "Custom"

	var/list/regions = list()
	for(var/i in 1 to 8)
		var/list/accesses = list()
		for(var/A in get_region_accesses(i))
			accesses += list(list(
				"desc" = get_access_desc(A),
				"ref" = A,
			))
		regions += list(list(
			"name" = get_region_accesses_name(i),
			"regid" = i,
			"accesses" = accesses,
		))
	.["regions"] = regions

/obj/machinery/computer/marine_card/ui_data(mob/user)
	. = list()
	.["authenticated"] = authenticated
	.["has_id"] = !!modify
	.["id_name"] = modify ? modify.name : "--------"
	.["id_rank"] = modify?.assignment ? modify.assignment : "Unassigned"
	.["id_owner"] = modify?.registered_name ? modify.registered_name : "--------"
	var/list/card_access = modify?.access
	.["access_on_card"] = card_access ? card_access.Copy() : list()
	.["id_account"] = modify ? modify.associated_account_number : 0
	.["has_auth_card"] = !!scan
	.["auth_name"] = scan ? scan.name : "--------"
	.["paygrade"] = modify ? modify.paygrade : null
	.["paygrade_name"] = modify ? get_paygrades(modify.paygrade) : null
	.["can_modify_paygrade"] = modify ? (modify.paygrade in PAYGRADES_MARINE) : FALSE
	.["mode"] = mode
	.["printing"] = !!printing
	.["manifest"] = GLOB.datacore ? GLOB.datacore.get_manifest(0) : ""

	var/list/available_paygrades = list()
	if(modify && (modify.paygrade in PAYGRADES_MARINE))
		var/i
		for(i in PAYGRADES_ENLISTED)
			available_paygrades += list(list(
				"paygrade" = i,
				"name" = get_paygrades(i),
			))
		if(scan && copytext(scan.paygrade, 1, 2) == "O")
			var/r = text2num(copytext(scan.paygrade, 2))
			r = r > 4 ? 4 : r
			while(--r > 0)
				i = "O[r]"
				available_paygrades += list(list(
					"paygrade" = i,
					"name" = get_paygrades(i),
				))
	.["available_paygrades"] = available_paygrades

/obj/machinery/computer/marine_card/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/user = ui.user

	switch(action)
		if("PRG_authenticate")
			if((!(authenticated) && (scan || (issilicon(user))) && (modify || mode)))
				if(check_access(scan))
					authenticated = 1
					. = TRUE
			else if((!(authenticated) && (issilicon(user))) && (!modify))
				to_chat(user, "You can't modify an ID without an ID inserted to modify. Once one is in the modify slot on the computer, you can log in.")

		if("PRG_logout")
			authenticated = 0
			. = TRUE

		if("PRG_eject")
			if(modify)
				GLOB.datacore.manifest_modify(modify.registered_name, modify.assignment)
				modify.name = "[modify.registered_name]'s ID Card ([modify.assignment])"
				if(ishuman(user))
					modify.forceMove(user.loc)
					if(!user.get_active_held_item())
						user.put_in_hands(modify)
					modify = null
				else
					modify.forceMove(loc)
					modify = null
			else
				var/obj/item/I = user.get_active_held_item()
				if(istype(I, /obj/item/card/id))
					user.drop_held_item()
					I.forceMove(src)
					modify = I
			authenticated = 0
			. = TRUE

		if("PRG_eject_auth")
			if(scan)
				if(ishuman(user))
					scan.forceMove(user.loc)
					if(!user.get_active_held_item())
						user.put_in_hands(scan)
					scan = null
				else
					scan.forceMove(loc)
					scan = null
			else
				var/obj/item/I = user.get_active_held_item()
				if(istype(I, /obj/item/card/id))
					user.drop_held_item()
					I.forceMove(src)
					scan = I
			authenticated = 0
			. = TRUE

		if("PRG_print")
			if(!(printing))
				printing = 1
				. = TRUE
				sleep(5 SECONDS)
				var/obj/item/paper/P = new /obj/item/paper(loc)

				var/t1 = "<h4>Crew Manifest</h4>"
				t1 += "<br>"
				if(GLOB.datacore)
					t1 += GLOB.datacore.get_manifest(0)

				P.info = t1
				P.name = "paper- 'Crew Manifest'"
				printing = null
				SStgui.update_uis(src)

		if("PRG_edit")
			if(authenticated && modify)
				var/obj/item/card/id/t2 = modify
				if(authenticated && modify == t2 && (in_range(src, user) || (issilicon(user))) && istype(loc, /turf))
					var/temp_name = reject_bad_name(params["name"])
					if(temp_name)
						modify.registered_name = temp_name
						. = TRUE
					else
						visible_message(span_notice("[src] buzzes rudely."))

		if("PRG_account")
			if(authenticated && modify)
				var/obj/item/card/id/t2 = modify
				if(authenticated && modify == t2 && (in_range(src, user) || (issilicon(user))) && istype(loc, /turf))
					var/account_num = text2num(params["account"])
					modify.associated_account_number = account_num
					. = TRUE

		if("PRG_assign")
			if(authenticated)
				var/t1 = params["assign_target"]
				if(t1 == "Custom")
					var/temp_t = params["custom_name"]
					if(!temp_t)
						temp_t = stripped_input(user, "Enter a custom job assignment.", "Assignment")
					if(temp_t && modify)
						modify.assignment = temp_t
						. = TRUE
				else
					var/datum/job/jobdatum
					for(var/jobtype in typesof(/datum/job))
						var/datum/job/J = new jobtype
						if(ckey(J.title) == ckey(t1))
							jobdatum = J
							break

					if(!jobdatum)
						to_chat(user, span_warning("No log exists for this job."))
						return FALSE

					if(!modify)
						to_chat(user, span_warning("No card to modify!"))
						return FALSE

					modify.access = jobdatum.get_access()
					modify.paygrade = jobdatum.paygrade
					modify.assignment = t1
					modify.rank = t1
					. = TRUE

		if("PRG_access")
			if(authenticated && modify)
				var/access_type = text2num(params["access_target"])
				if(access_type in ALL_MARINE_ACCESS)
					if(access_type in modify.access)
						modify.access -= access_type
					else
						modify.access += access_type
					. = TRUE

		if("PRG_grantregion")
			if(authenticated && modify)
				var/region = text2num(params["region"])
				if(!isnull(region))
					modify.access |= get_region_accesses(region)
					. = TRUE

		if("PRG_denyregion")
			if(authenticated && modify)
				var/region = text2num(params["region"])
				if(!isnull(region))
					modify.access -= get_region_accesses(region)
					. = TRUE

		if("PRG_grantall")
			if(authenticated && modify)
				modify.access |= ALL_MARINE_ACCESS
				. = TRUE

		if("PRG_denyall")
			if(authenticated && modify)
				modify.access -= ALL_MARINE_ACCESS
				. = TRUE

		if("PRG_paygrade")
			if(authenticated && modify)
				var/obj/item/card/id/t2 = modify
				if(authenticated && modify == t2 && (in_range(src, user) || (issilicon(user))) && istype(loc, /turf))
					if(!(modify.paygrade in PAYGRADES_MARINE))
						return FALSE
					var/new_paygrade = params["paygrade"]
					var/list/allowed_paygrades = list()
					for(var/grade in PAYGRADES_ENLISTED)
						allowed_paygrades += grade
					if(scan && copytext(scan.paygrade, 1, 2) == "O")
						var/r = text2num(copytext(scan.paygrade, 2))
						r = r > 4 ? 4 : r
						while(--r > 0)
							allowed_paygrades += "O[r]"
					if(new_paygrade in allowed_paygrades)
						modify.paygrade = new_paygrade
						. = TRUE

		if("PRG_mode")
			mode = text2num(params["mode"])
			. = TRUE

	if(modify)
		modify.name = "[modify.registered_name]'s ID Card ([modify.assignment])"

/obj/machinery/computer/marine_card/centcom
	name = "CentCom Identification Computer"
	circuit = /obj/item/circuitboard/computer/card/centcom
	req_access = list(ACCESS_NT_CORPORATE)

//This console changes a marine's squad. It's very simple.
//It also does not: change or increment the squad count (used in the login randomizer), nor does it check for jobs.
//Which means you could get sillyiness like "Alpha Sulaco Chief Medical Officer" or "Delta Logistics Officer".
//But in the long run it's not really a big deal.

/obj/machinery/computer/squad_changer
	name = "Squad Distribution Computer"
	desc = "You can use this to change someone's squad."
	icon_state = "computer_small"
	screen_overlay = "guest"
	req_access = list(ACCESS_MARINE_LOGISTICS)
	resistance_flags = INDESTRUCTIBLE
	interaction_flags = INTERACT_MACHINE_TGUI
	faction = FACTION_TERRAGOV
	var/obj/item/card/id/modify = null

/obj/machinery/computer/squad_changer/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(.)
		return

	if(istype(I, /obj/item/card/id))
		var/obj/item/card/id/idcard = I
		if(modify)
			to_chat(user, "Remove the inserted card first.")
			return

		user.drop_held_item()
		idcard.forceMove(src)
		modify = idcard

/obj/machinery/computer/squad_changer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SquadMod", name)
		ui.open()

/obj/machinery/computer/squad_changer/ui_static_data(mob/user)
	. = list()
	var/list/squads = list()
	for(var/datum/squad/squad AS in SSjob.active_squads[faction])
		squads += list(list(
			"name" = squad.name,
			"color" = squad.color || "#444444",
		))
	.["squads"] = squads

/obj/machinery/computer/squad_changer/ui_data(mob/user)
	. = list()
	.["has_id"] = !!modify
	.["id_name"] = modify ? modify.name : "--------"

/obj/machinery/computer/squad_changer/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/user = ui.user

	switch(action)
		if("PRG_eject")
			if(modify)
				modify.forceMove(loc)
				if(!user.get_active_held_item() && ishuman(user))
					user.put_in_hands(modify)
				modify = null
			else
				var/obj/item/card/id/id_card = user.get_active_held_item()
				if(istype(id_card))
					user.drop_held_item()
					id_card.forceMove(src)
					modify = id_card
			. = TRUE

		if("PRG_squad")
			if(!allowed(user))
				to_chat(user, span_warning("You don't have sufficient access to use this console."))
				return FALSE
			if(!modify)
				to_chat(user, span_warning("You need to insert a card to modify."))
				return FALSE
			var/squad_name = params["name"]
			var/datum/squad/selected
			for(var/datum/squad/squad AS in SSjob.active_squads[faction])
				if(squad.name == squad_name)
					selected = squad
					break
			for(var/datum/squad/old_squad AS in SSjob.squads)
				if(findtext(modify.assignment, old_squad.name))
					modify.access -= old_squad.access
					to_chat(user, "Old squad access removed.")
			if(selected)
				modify.assignment = "[selected.name] [modify.rank]"
				modify.access += selected.access
				to_chat(user, "[selected.name] Squad added to card.")
			else
				to_chat(user, "No squad selected.")
			modify.name = "[modify.registered_name]'s ID Card ([modify.assignment])"
			. = TRUE
