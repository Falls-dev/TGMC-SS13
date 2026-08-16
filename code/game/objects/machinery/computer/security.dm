/obj/machinery/computer/secure_data
	name = "Security Records"
	desc = "Used to view and edit personnel's security records"
	icon_state = "computer_small"
	screen_overlay = "security"
	broken_icon = "computer_small_red_broken"
	req_one_access = list(ACCESS_MARINE_BRIG, ACCESS_NT_CORPORATE, ACCESS_MARINE_BRIDGE, ACCESS_MARINE_LOGISTICS)
	circuit = /obj/item/circuitboard/computer/secure_data
	interaction_flags = INTERACT_MACHINE_TGUI
	/// Inserted ID used for authentication
	var/obj/item/card/id/scan = null
	/// Authenticated user name, or null when logged out
	var/authenticated = null
	/// Authenticated user's assignment/rank
	var/rank = null
	/// Currently viewed general record
	var/datum/data/record/active1 = null
	/// Currently viewed security record
	var/datum/data/record/active2 = null
	/// Whether a print job is in progress
	var/printing = FALSE

/obj/machinery/computer/secure_data/verb/eject_id()
	set category = "IC.Object"
	set name = "Eject ID Card"
	set src in oview(1)

	if(!usr || usr.stat || usr.lying_angle)
		return

	if(scan)
		to_chat(usr, "You remove \the [scan] from \the [src].")
		scan.loc = get_turf(src)
		if(!usr.get_active_held_item() && istype(usr,/mob/living/carbon/human))
			usr.put_in_hands(scan)
		scan = null
	else
		to_chat(usr, "There is nothing to remove from the console.")

/obj/machinery/computer/secure_data/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(.)
		return

	if(istype(I, /obj/item/card/id) && !scan)
		if(!user.drop_held_item())
			return
		I.forceMove(src)
		scan = I
		to_chat(user, "You insert [I].")

/obj/machinery/computer/secure_data/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SecurityRecords", name)
		ui.open()

/obj/machinery/computer/secure_data/ui_data(mob/user)
	. = list()
	.["authenticated"] = authenticated
	.["rank"] = rank
	.["scan_name"] = scan ? scan.name : null
	.["printing"] = printing

	if(!(GLOB.datacore.general.Find(active1)))
		active1 = null
	if(!(GLOB.datacore.security.Find(active2)))
		active2 = null

	var/list/records = list()
	for(var/datum/data/record/R in sortRecord(GLOB.datacore.general))
		var/criminal = ""
		for(var/datum/data/record/E in GLOB.datacore.security)
			if(E.fields["name"] == R.fields["name"] || E.fields["id"] == R.fields["id"])
				criminal = E.fields["criminal"]
				break
		records += list(list(
			"id" = R.fields["id"],
			"name" = R.fields["name"],
			"rank" = R.fields["rank"],
			"fingerprint" = R.fields["fingerprint"],
			"criminal" = criminal,
		))
	.["records"] = records

	.["record"] = null
	if(!active1 && !active2)
		return

	var/list/record_data = list(
		"has_general" = FALSE,
		"has_security" = FALSE,
	)

	if(istype(active1, /datum/data/record) && GLOB.datacore.general.Find(active1))
		record_data["has_general"] = TRUE
		record_data["id"] = active1.fields["id"]
		record_data["name"] = active1.fields["name"]
		record_data["rank"] = active1.fields["rank"]
		record_data["sex"] = active1.fields["sex"]
		record_data["age"] = active1.fields["age"]
		record_data["fingerprint"] = active1.fields["fingerprint"]
		record_data["p_stat"] = active1.fields["p_stat"]
		record_data["m_stat"] = active1.fields["m_stat"]

		if(istype(active1.fields["photo_front"], /obj/item/photo))
			var/obj/item/photo/P1 = active1.fields["photo_front"]
			if(P1.picture?.picture_image)
				record_data["photo_front"] = icon2html(P1.picture.picture_image, user, sourceonly = TRUE)
		if(istype(active1.fields["photo_side"], /obj/item/photo))
			var/obj/item/photo/P2 = active1.fields["photo_side"]
			if(P2.picture?.picture_image)
				record_data["photo_side"] = icon2html(P2.picture.picture_image, user, sourceonly = TRUE)

	if(istype(active2, /datum/data/record) && GLOB.datacore.security.Find(active2))
		record_data["has_security"] = TRUE
		if(!record_data["id"])
			record_data["id"] = active2.fields["id"]
		if(!record_data["name"])
			record_data["name"] = active2.fields["name"]
		record_data["criminal"] = active2.fields["criminal"]
		record_data["mi_crim"] = active2.fields["mi_crim"]
		record_data["mi_crim_d"] = active2.fields["mi_crim_d"]
		record_data["ma_crim"] = active2.fields["ma_crim"]
		record_data["ma_crim_d"] = active2.fields["ma_crim_d"]
		record_data["notes"] = html_decode(active2.fields["notes"])

		var/list/comments = list()
		var/counter = 1
		while(active2.fields["com_[counter]"])
			comments += list(list(
				"index" = counter,
				"text" = active2.fields["com_[counter]"],
			))
			counter++
		record_data["comments"] = comments

	.["record"] = record_data

/obj/machinery/computer/secure_data/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(!(GLOB.datacore.general.Find(active1)))
		active1 = null
	if(!(GLOB.datacore.security.Find(active2)))
		active2 = null

	switch(action)
		if("scan")
			handle_scan(ui.user)
			return TRUE

		if("login")
			handle_login(ui.user)
			return TRUE

		if("logout")
			authenticated = null
			rank = null
			active1 = null
			active2 = null
			return TRUE

	if(!authenticated)
		return FALSE

	switch(action)
		if("select_record")
			var/id = params["id"]
			if(!id)
				return FALSE
			var/datum/data/record/R = find_general_record(id)
			if(!R)
				to_chat(ui.user, span_warning("Record not found."))
				return FALSE
			active1 = R
			active2 = find_security_record_for(R)
			return TRUE

		if("clear_record")
			active1 = null
			active2 = null
			return TRUE

		if("search")
			var/t1 = strip_html(params["value"])
			if(!t1 || !can_edit(ui.user))
				return FALSE
			active1 = null
			active2 = null
			t1 = lowertext(t1)
			for(var/datum/data/record/R in GLOB.datacore.general)
				var/temptext = lowertext("[R.fields["name"]] [R.fields["id"]] [R.fields["fingerprint"]] [R.fields["rank"]]")
				if(findtext(temptext, t1))
					active1 = R
					active2 = find_security_record_for(R)
					return TRUE
			to_chat(ui.user, span_warning("Could not locate record [params["value"]]."))
			return TRUE

		if("set_field")
			return set_record_field(ui.user, params["field"], params["value"])

		if("add_comment")
			if(!istype(active2, /datum/data/record))
				return FALSE
			var/a2 = active2
			var/t1 = strip_html(params["value"])
			if(!t1 || !can_edit(ui.user) || active2 != a2)
				return FALSE
			var/counter = 1
			while(active2.fields["com_[counter]"])
				counter++
			active2.fields["com_[counter]"] = "Made by [authenticated] ([rank]) on [time2text(world.realtime, "DDD MMM DD hh:mm:ss")], [GAME_YEAR]<BR>[t1]"
			return TRUE

		if("delete_comment")
			var/index = text2num(params["index"])
			if(!istype(active2, /datum/data/record) || !index)
				return FALSE
			if(active2.fields["com_[index]"])
				active2.fields["com_[index]"] = "<B>Deleted</B>"
			return TRUE

		if("new_record")
			if(!istype(active1, /datum/data/record) || istype(active2, /datum/data/record))
				return FALSE
			active2 = CreateSecurityRecord(active1.fields["name"], active1.fields["id"])
			return TRUE

		if("new_general_record")
			active1 = CreateGeneralRecord()
			active2 = null
			return TRUE

		if("delete_record")
			if(active2)
				qdel(active2)
				active2 = null
			return TRUE

		if("delete_record_all")
			if(active1)
				qdel(active1)
				active1 = null
			if(active2)
				qdel(active2)
				active2 = null
			return TRUE

		if("delete_all_records")
			for(var/datum/data/record/R in GLOB.datacore.security)
				GLOB.datacore.security -= R
				qdel(R)
			active2 = null
			to_chat(ui.user, span_notice("All security records deleted."))
			return TRUE

		if("print_record")
			if(printing)
				return FALSE
			printing = TRUE
			addtimer(CALLBACK(src, PROC_REF(print_active_record)), 5 SECONDS)
			return TRUE

/obj/machinery/computer/secure_data/proc/handle_scan(mob/user)
	if(scan)
		if(ishuman(user))
			scan.forceMove(user.loc)
			if(!user.get_active_held_item())
				user.put_in_hands(scan)
			scan = null
		else
			scan.forceMove(loc)
			scan = null
		return

	var/obj/item/I = user.get_active_held_item()
	if(istype(I, /obj/item/card/id))
		if(user.drop_held_item())
			I.forceMove(src)
			scan = I

/obj/machinery/computer/secure_data/proc/handle_login(mob/user)
	if(isAI(user))
		active1 = null
		active2 = null
		authenticated = user.name
		rank = "AI"
		return

	if(istype(scan, /obj/item/card/id))
		active1 = null
		active2 = null
		if(check_access(scan))
			authenticated = scan.registered_name
			rank = scan.assignment

/obj/machinery/computer/secure_data/proc/can_edit(mob/user)
	if(!authenticated)
		return FALSE
	if(user.stat)
		return FALSE
	if(user.restrained())
		return FALSE
	if(!in_range(src, user) && !issilicon(user))
		return FALSE
	return TRUE

/obj/machinery/computer/secure_data/proc/find_general_record(id)
	for(var/datum/data/record/R in GLOB.datacore.general)
		if(R.fields["id"] == id)
			return R

/obj/machinery/computer/secure_data/proc/find_security_record_for(datum/data/record/general)
	if(!general)
		return
	for(var/datum/data/record/E in GLOB.datacore.security)
		if(E.fields["name"] == general.fields["name"] || E.fields["id"] == general.fields["id"])
			return E

/obj/machinery/computer/secure_data/proc/set_record_field(mob/user, field, value)
	if(!field || !can_edit(user))
		return FALSE

	var/a1 = active1
	var/a2 = active2

	switch(field)
		if("name")
			if(!istype(active1, /datum/data/record))
				return FALSE
			value = reject_bad_name(value)
			if(!value || active1 != a1)
				return FALSE
			active1.fields["name"] = value
			return TRUE

		if("id")
			if(!istype(active1, /datum/data/record))
				return FALSE
			value = strip_html(value)
			if(!value || active1 != a1)
				return FALSE
			active1.fields["id"] = value
			return TRUE

		if("fingerprint")
			if(!istype(active1, /datum/data/record))
				return FALSE
			value = strip_html(value)
			if(!value || active1 != a1)
				return FALSE
			active1.fields["fingerprint"] = value
			return TRUE

		if("sex")
			if(!istype(active1, /datum/data/record))
				return FALSE
			if(value == "Male" || value == "Female")
				active1.fields["sex"] = value
			else if(active1.fields["sex"] == "Male")
				active1.fields["sex"] = "Female"
			else
				active1.fields["sex"] = "Male"
			return TRUE

		if("age")
			if(!istype(active1, /datum/data/record))
				return FALSE
			var/age = text2num(value)
			if(isnull(age) || active1 != a1)
				return FALSE
			active1.fields["age"] = age
			return TRUE

		if("criminal")
			if(!istype(active2, /datum/data/record))
				return FALSE
			var/static/list/criminal_statuses = list("None", "*Arrest*", "Incarcerated", "Released")
			if(!(value in criminal_statuses))
				return FALSE
			active2.fields["criminal"] = value
			return TRUE

		if("mi_crim", "mi_crim_d", "ma_crim", "ma_crim_d")
			if(!istype(active2, /datum/data/record))
				return FALSE
			value = strip_html(value)
			if(!value || active2 != a2)
				return FALSE
			active2.fields[field] = value
			return TRUE

		if("notes")
			if(!istype(active2, /datum/data/record))
				return FALSE
			value = copytext(html_encode(trim(value)), 1, MAX_MESSAGE_LEN)
			if(!value || active2 != a2)
				return FALSE
			active2.fields["notes"] = value
			return TRUE

	return FALSE

/obj/machinery/computer/secure_data/proc/print_active_record()
	var/datum/data/record/record1 = null
	var/datum/data/record/record2 = null
	if(istype(active1, /datum/data/record) && GLOB.datacore.general.Find(active1))
		record1 = active1
	if(istype(active2, /datum/data/record) && GLOB.datacore.security.Find(active2))
		record2 = active2

	var/obj/item/paper/P = new /obj/item/paper(loc)
	P.info = "<CENTER><B>Security Record</B></CENTER><BR>"
	if(record1)
		P.info += "Name: [record1.fields["name"]] ID: [record1.fields["id"]]<BR>\nSex: [record1.fields["sex"]]<BR>\nAge: [record1.fields["age"]]<BR>\nFingerprint: [record1.fields["fingerprint"]]<BR>\nPhysical Status: [record1.fields["p_stat"]]<BR>\nMental Status: [record1.fields["m_stat"]]<BR>"
		P.name = "Security Record ([record1.fields["name"]])"
	else
		P.info += "<B>General Record Lost!</B><BR>"
		P.name = "Security Record"
	if(record2)
		P.info += "<BR>\n<CENTER><B>Security Data</B></CENTER><BR>\nCriminal Status: [record2.fields["criminal"]]<BR>\n<BR>\nMinor Crimes: [record2.fields["mi_crim"]]<BR>\nDetails: [record2.fields["mi_crim_d"]]<BR>\n<BR>\nMajor Crimes: [record2.fields["ma_crim"]]<BR>\nDetails: [record2.fields["ma_crim_d"]]<BR>\n<BR>\nImportant Notes:<BR>\n\t[decode(record2.fields["notes"])]<BR>\n<BR>\n<CENTER><B>Comments/Log</B></CENTER><BR>"
		var/counter = 1
		while(record2.fields["com_[counter]"])
			P.info += "[record2.fields["com_[counter]"]]<BR>"
			counter++
	else
		P.info += "<B>Security Record Lost!</B><BR>"
	P.info += "</TT>"
	printing = FALSE
	SStgui.update_uis(src)

/obj/machinery/computer/secure_data/proc/get_photo(mob/user)
	var/atom/A = user.get_active_held_item()
	if(!istype(A, /obj/item/photo))
		return
	return A

/obj/machinery/computer/secure_data/emp_act(severity)
	if(machine_stat & (BROKEN|NOPOWER))
		return ..()

	for(var/datum/data/record/R in GLOB.datacore.security)
		if(prob(10/severity))
			switch(rand(1,5))
				if(1)
					R.fields["name"] = GLOB.namepool[/datum/namepool].get_random_name(pick(MALE, FEMALE))
				if(2)
					R.fields["sex"] = pick("Male", "Female")
				if(3)
					R.fields["age"] = rand(5, 85)
				if(4)
					R.fields["p_stat"] = pick("*Unconcious*", "Active", "Physically Unfit")
				if(5)
					R.fields["m_stat"] = pick("*Insane*", "*Unstable*", "*Watch*", "Stable")
			continue

		else if(prob(1))
			GLOB.datacore.security -= R
			qdel(R)
			continue
	return ..()

/obj/machinery/computer/secure_data/detective_computer
	icon = 'icons/obj/machines/computer.dmi'
	icon_state = "messyfiles"
	screen_overlay = "messyfiles_screen"
