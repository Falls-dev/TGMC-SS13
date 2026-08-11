/obj/machinery/computer/sleep_console
	name = "Sleeper Console"
	icon = 'icons/obj/machines/cryogenics.dmi'
	icon_state = "sleeperconsole"
	screen_overlay = "sleeperconsole_emissive"
	dir = EAST
	density = FALSE
	idle_power_usage = 40
	interaction_flags = INTERACT_MACHINE_TGUI
	///The connected sleeper
	var/obj/machinery/sleeper/connected = null

/obj/machinery/computer/sleep_console/Initialize(mapload)
	. = ..()
	set_connected(locate(/obj/machinery/sleeper, get_step(src, REVERSE_DIR(dir))))
	connected?.set_connected(src)

///Set the connected var
/obj/machinery/computer/sleep_console/proc/set_connected(obj/future_connected)
	if(connected)
		UnregisterSignal(connected, COMSIG_QDELETING)
	connected = null
	if(future_connected)
		connected = future_connected
		RegisterSignal(connected, COMSIG_QDELETING, PROC_REF(clean_connected))

///Clean the connected var
/obj/machinery/computer/sleep_console/proc/clean_connected()
	SIGNAL_HANDLER
	set_connected(null)

/obj/machinery/computer/sleep_console/process()
	if(machine_stat & (NOPOWER|BROKEN))
		return
	SStgui.update_uis(src)

/obj/machinery/computer/sleep_console/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Sleeper", "Sleeper Console")
		ui.open()

/obj/machinery/computer/sleep_console/ui_data(mob/user)
	. = list()
	.["connected"] = !!connected
	.["connected_operable"] = connected && !(connected.machine_stat & (NOPOWER|BROKEN))
	.["hasOccupant"] = connected?.occupant ? TRUE : FALSE
	.["dialysis"] = connected?.filtering
	.["stasis"] = connected?.stasis
	.["amounts"] = connected?.amounts || list()
	.["maxchem"] = 20

	var/mob/living/occupant = connected?.occupant
	if(occupant)
		var/list/occupant_data = list(
			"name" = occupant.name,
			"stat" = occupant.stat,
			"health" = occupant.health,
			"maxHealth" = occupant.maxHealth,
			"bruteLoss" = occupant.get_brute_loss(),
			"oxyLoss" = occupant.get_oxy_loss(),
			"toxLoss" = occupant.get_tox_loss(),
			"fireLoss" = occupant.get_fire_loss(),
			"bodyTemperature" = occupant.bodytemperature,
			"btCelsius" = occupant.bodytemperature - T0C,
			"btFaren" = ((occupant.bodytemperature - T0C) * (9.0 / 5.0)) + 32,
			"temperatureSuitability" = 0,
			"hasBlood" = FALSE,
			"totalreagents" = occupant.reagents?.total_volume || 0,
		)

		if(ishuman(occupant))
			var/mob/living/carbon/human/human_occupant = occupant
			if(human_occupant.species)
				var/datum/species/species = human_occupant.species
				if(occupant.bodytemperature < species.cold_level_3)
					occupant_data["temperatureSuitability"] = -3
				else if(occupant.bodytemperature < species.cold_level_2)
					occupant_data["temperatureSuitability"] = -2
				else if(occupant.bodytemperature < species.cold_level_1)
					occupant_data["temperatureSuitability"] = -1
				else if(occupant.bodytemperature > species.heat_level_3)
					occupant_data["temperatureSuitability"] = 3
				else if(occupant.bodytemperature > species.heat_level_2)
					occupant_data["temperatureSuitability"] = 2
				else if(occupant.bodytemperature > species.heat_level_1)
					occupant_data["temperatureSuitability"] = 1

			var/pulse = human_occupant.handle_pulse()
			occupant_data["pulse"] = human_occupant.get_pulse(GETPULSE_TOOL)
			occupant_data["pulse_bad"] = (pulse == PULSE_NONE || pulse == PULSE_THREADY)
			if(!(human_occupant.species.species_flags & NO_BLOOD))
				occupant_data["hasBlood"] = TRUE
				occupant_data["bloodLevel"] = floor(occupant.blood_volume)
				occupant_data["bloodMax"] = BLOOD_VOLUME_MAXIMUM
				occupant_data["bloodPercent"] = round(100 * (occupant.blood_volume / BLOOD_VOLUME_MAXIMUM), 0.01)

		.["occupant"] = occupant_data

	var/list/chemicals = list()
	if(connected)
		for(var/chemical_path in connected.available_chemicals)
			var/title = connected.available_chemicals[chemical_path]
			var/reagent_amount = 0
			var/injectable = occupant ? TRUE : FALSE
			var/overdosing = FALSE
			var/od_warning = FALSE

			if(occupant?.reagents)
				reagent_amount = occupant.reagents.get_reagent_amount(chemical_path)
				var/datum/reagent/reagent = occupant.reagents.get_reagent(chemical_path)
				if(reagent?.overdose_threshold && reagent_amount + 10 > reagent.overdose_threshold)
					od_warning = TRUE
				if(reagent?.overdose_threshold && reagent_amount >= reagent.overdose_threshold)
					overdosing = TRUE

			if(occupant?.stat == DEAD || ismonkey(occupant))
				injectable = FALSE

			chemicals += list(list(
				"title" = title,
				"id" = "[chemical_path]",
				"occ_amount" = reagent_amount,
				"pretty_amount" = round(reagent_amount, 0.01),
				"injectable" = injectable,
				"overdosing" = overdosing,
				"od_warning" = od_warning,
			))

	.["chemicals"] = chemicals

/obj/machinery/computer/sleep_console/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(!connected || (connected.machine_stat & (NOPOWER|BROKEN)))
		return

	switch(action)
		if("chemical")
			if(!connected.occupant)
				return
			if(connected.occupant.stat == DEAD)
				to_chat(ui.user, span_warning("This person has no life for to preserve anymore."))
				return
			if(ismonkey(connected.occupant))
				to_chat(ui.user, span_scanner("Unknown biological subject detected, chemical injection not available. Please contact a licensed supplier for further assistance."))
				return
			var/chemical = text2path(params["chemid"])
			if(!(chemical in connected.available_chemicals))
				message_admins("[ADMIN_TPMONTY(ui.user)] has tried to inject an invalid chem with the sleeper. Looks like an exploit attempt, or a bug.")
				return
			var/amount = text2num(params["amount"])
			if(amount == 5 || amount == 10)
				connected.inject_chemical(ui.user, chemical, amount)
			return TRUE
		if("togglefilter")
			connected.toggle_filter()
			return TRUE
		if("togglestasis")
			connected.toggle_stasis()
			return TRUE
		if("ejectify")
			connected.eject()
			return TRUE

/obj/machinery/computer/sleep_console/pred
	icon = 'icons/obj/machines/yautja_machines.dmi'

/////////////////////////////////////////
// THE SLEEPER ITSELF
/////////////////////////////////////////

/obj/machinery/sleeper
	name = "Sleeper"
	desc = "A fancy bed with built-in injectors, a dialysis machine, and a limited health scanner."
	icon = 'icons/obj/machines/cryogenics.dmi'
	icon_state = "sleeper"
	density = TRUE
	light_range = 1
	light_power = 0.5
	light_color = LIGHT_COLOR_BLUE
	dir = EAST
	var/mob/living/carbon/human/occupant = null
	var/available_chemicals = list(/datum/reagent/medicine/inaprovaline = "Inaprovaline", /datum/reagent/toxin/sleeptoxin = "Soporific", /datum/reagent/medicine/paracetamol = "Paracetamol", /datum/reagent/medicine/bicaridine = "Bicaridine", /datum/reagent/medicine/kelotane = "Kelotane", /datum/reagent/medicine/dylovene = "Dylovene", /datum/reagent/medicine/dexalin = "Dexalin", /datum/reagent/medicine/tricordrazine = "Tricordrazine", /datum/reagent/medicine/spaceacillin = "Spaceacillin")
	var/amounts = list(5, 10)
	var/filtering = FALSE
	var/stasis = FALSE
	var/obj/machinery/computer/sleep_console/connected

	use_power = IDLE_POWER_USE
	idle_power_usage = 15
	active_power_usage = 200 //builtin health analyzer, dialysis machine, injectors.

/obj/machinery/sleeper/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_MOVABLE_SHUTTLE_CRUSH, PROC_REF(shuttle_crush))
	update_icon()

/obj/machinery/sleeper/proc/shuttle_crush()
	SIGNAL_HANDLER
	if(occupant)
		var/mob/living/carbon/human/H = occupant
		go_out()
		H.gib()

///Set the connected var
/obj/machinery/sleeper/proc/set_connected(obj/future_connected)
	if(connected)
		UnregisterSignal(connected, COMSIG_QDELETING)
	connected = null
	if(future_connected)
		connected = future_connected
		RegisterSignal(connected, COMSIG_QDELETING, PROC_REF(clean_connected))

///Clean the connected var
/obj/machinery/sleeper/proc/clean_connected()
	SIGNAL_HANDLER
	set_connected(null)

/obj/machinery/sleeper/Destroy()
	//clean up; end stasis; remove from processing
	if(occupant)
		REMOVE_TRAIT(occupant, TRAIT_STASIS, SLEEPER_TRAIT)
		go_out()
	occupant = null
	STOP_PROCESSING(SSobj, src)
	stop_processing()
	return ..()

/obj/machinery/sleeper/examine(mob/living/user)
	. = ..()
	if(!occupant) //Allows us to reference medical files/scan reports for cryo via examination.
		return
	if(!ishuman(occupant))
		return
	var/feedback = ""
	if(stasis)
		feedback += " Cryostasis is active."
	if(filtering)
		feedback += " Dialysis is active."
	if(!hasHUD(user,"medical"))
		. += span_notice("It contains: [occupant].[feedback]")
		return
	var/mob/living/carbon/human/H = occupant
	for(var/datum/data/record/R in GLOB.datacore.medical)
		if (!R.fields["name"] == H.real_name)
			continue
		if(!(R.fields["last_scan_time"]))
			. += span_deptradio("No scan report on record")
		else
			. += span_deptradio("<a href='byond://?src=[text_ref(src)];scanreport=1'>It contains [occupant]: Scan from [R.fields["last_scan_time"]].[feedback]</a>")
		break

/obj/machinery/sleeper/Topic(href, href_list)
	. = ..()
	if(.)
		return
	if (!href_list["scanreport"])
		return
	if(!hasHUD(usr,"medical"))
		return
	if(get_dist(usr, src) > 7)
		to_chat(usr, span_warning("[src] is too far away."))
		return
	if(!ishuman(occupant))
		return
	var/mob/living/carbon/human/H = occupant
	for(var/datum/data/record/R in GLOB.datacore.medical)
		if (!R.fields["name"] == H.real_name)
			continue
		if(R.fields["last_scan_time"] && R.fields["last_scan_result"])
			var/datum/browser/popup = new(usr, "scanresults", "<div align='center'>Last Scan Result</div>", 430, 600)
			popup.set_content(R.fields["last_scan_result"])
			popup.open(FALSE)
		break

/obj/machinery/sleeper/process()
	if (machine_stat & (NOPOWER|BROKEN))
		if(occupant)
			REMOVE_TRAIT(occupant, TRAIT_STASIS, SLEEPER_TRAIT)
		stasis = FALSE
		filtering = FALSE
		stop_processing() //Shut down; stasis off, filtering off, stop processing.
		return

	//Life support
	occupant?.adjust_oxy_loss(-occupant.get_oxy_loss()) // keep them breathing, pretend they get IV dexalinplus

	if(filtering)
		for(var/datum/reagent/x in occupant.reagents.reagent_list)
			occupant.reagents.remove_reagent(x.type, 10)
	updateUsrDialog()

/obj/machinery/sleeper/update_icon()
	. = ..()
	if((machine_stat & (BROKEN|DISABLED|NOPOWER)) || !occupant)
		set_light(0)
	else
		set_light(initial(light_range))

/obj/machinery/sleeper/update_icon_state()
	. = ..()
	if(occupant)
		icon_state = "sleeper_occupied"
	else
		icon_state = "sleeper"

/obj/machinery/sleeper/update_overlays()
	. = ..()
	if(machine_stat & (BROKEN|DISABLED|NOPOWER))
		return
	if(!occupant)
		return
	. += emissive_appearance(icon, "[icon_state]_emissive", src, alpha = src.alpha)
	. += mutable_appearance(icon, "[icon_state]_emissive", alpha = src.alpha)

/obj/machinery/sleeper/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(.)
		return

	if(istype(I, /obj/item/healthanalyzer) && occupant) //Allows us to use the analyzer on the occupant without taking him out.
		var/obj/item/healthanalyzer/J = I
		J.attack(occupant, user)

/obj/machinery/sleeper/grab_interact(obj/item/grab/grab, mob/user, base_damage = BASE_OBJ_SLAM_DAMAGE, is_sharp = FALSE)
	. = ..()
	if(.)
		return
	if(isxeno(user))
		return
	if(machine_stat & (NOPOWER|BROKEN))
		to_chat(user, span_notice("\ [src] is non-functional!"))
		return
	if(occupant)
		to_chat(user, span_notice("\ [src] is already occupied!"))
		return

	var/mob/grabbed_mob

	if(ismob(grab.grabbed_thing))
		grabbed_mob = grab.grabbed_thing
	else if(istype(grab.grabbed_thing,/obj/structure/closet/bodybag/cryobag))
		var/obj/structure/closet/bodybag/cryobag/cryobag = grab.grabbed_thing
		if(!cryobag.bodybag_occupant)
			to_chat(user, span_warning("The stasis bag is empty!"))
			return
		grabbed_mob = cryobag.bodybag_occupant
		cryobag.open()
		user.start_pulling(grabbed_mob)
	if(!grabbed_mob)
		return

	if(!grabbed_mob.forceMove(src))
		return
	visible_message("[user] puts [grabbed_mob] into the sleeper.", 3)
	occupant = grabbed_mob
	start_processing()
	if(connected)
		connected.start_processing()
	update_icon()
	return TRUE

/obj/machinery/sleeper/ex_act(severity)
	if(filtering)
		toggle_filter()
	if(prob(severity * 0.3))
		qdel(src)

/obj/machinery/sleeper/emp_act(severity)
	. = ..()
	if(filtering)
		toggle_filter()
	if(stasis)
		toggle_stasis()
	if(machine_stat & (BROKEN|NOPOWER))
		return
	if(occupant)
		go_out()

/obj/machinery/sleeper/proc/toggle_filter()
	if(!occupant)
		filtering = 0
		return
	if(ismonkey(occupant))
		to_chat(usr, span_scanner("Unknown biological subject detected, dialysis not available. Please contact a licensed supplier for further assistance."))
		filtering = 0
		return
	if(filtering)
		filtering = FALSE
	else
		filtering = TRUE

/obj/machinery/sleeper/proc/toggle_stasis()
	if(!occupant)
		stasis = FALSE
		return
	if(stasis)
		REMOVE_TRAIT(occupant, TRAIT_STASIS, SLEEPER_TRAIT)
		stasis = FALSE
	else
		ADD_TRAIT(occupant, TRAIT_STASIS, SLEEPER_TRAIT)
		stasis = TRUE

/obj/machinery/sleeper/proc/go_out()
	if(filtering)
		toggle_filter()
	if(!occupant)
		return
	if(occupant in contents)
		occupant.forceMove(loc)
	REMOVE_TRAIT(occupant, TRAIT_STASIS, SLEEPER_TRAIT)
	stasis = FALSE
	occupant = null
	stop_processing()
	if(connected)
		connected.stop_processing()
	update_icon()

/obj/machinery/sleeper/proc/inject_chemical(mob/living/user as mob, chemical, amount)
	if(occupant?.reagents)
		if(occupant.reagents.get_reagent_amount(chemical) + amount <= 20)
			occupant.reagents.add_reagent(chemical, amount)
			to_chat(user, span_notice("Occupant now has [occupant.reagents.get_reagent_amount(chemical)] units of [available_chemicals[chemical]] in his/her bloodstream."))
			return
	to_chat(user, span_warning("There's no occupant in the sleeper or the subject has too many chemicals!"))

/obj/machinery/sleeper/proc/check(mob/living/user)
	if(occupant)
		to_chat(user, span_boldnotice("Occupant ([occupant]) Statistics:"))
		var/t1
		switch(occupant.stat)
			if(0)
				t1 = "Conscious"
			if(1)
				t1 = "Unconscious"
			if(2)
				t1 = "*dead*"
		var/health_ratio = occupant.health * 100 / occupant.maxHealth
		to_chat(user, "[health_ratio > 50 ? "<font color='#487553'> " : "<font color='#b54646'> "]\t Health %: [health_ratio] ([t1])</font>")
		to_chat(user, "[occupant.bodytemperature > 50 ? "<font color='#487553'>" : "<font color='#b54646'>"]\t -Core Temperature: [occupant.bodytemperature-T0C]&deg;C ([occupant.bodytemperature*1.8-459.67]&deg;F)</FONT><BR>")
		to_chat(user, "[occupant.get_brute_loss() < 60 ? "<font color='#487553'> " : "<font class='#b54646'> "]\t -Brute Damage %: [occupant.get_brute_loss()]</font>")
		to_chat(user, "[occupant.get_oxy_loss() < 60 ? "<span color='#487553'> " : "<font color='#b54646'> "]\t -Respiratory Damage %: [occupant.get_oxy_loss()]</font>")
		to_chat(user, "[occupant.get_tox_loss() < 60 ? "<font color='#487553'> " : "<font color='#b54646'> "]\t -Toxin Content %: [occupant.get_tox_loss()]</font>")
		to_chat(user, "[occupant.get_fire_loss() < 60 ? "<font color='#487553'> " : "<font color='#b54646'> "]\t -Burn Severity %: [occupant.get_fire_loss()]</font>")
		to_chat(user, span_notice("Expected time till occupant can safely awake: (note: If health is below 20% these times are inaccurate)"))
		to_chat(user, span_notice("\t [occupant.AmountUnconscious() * 0.1] second\s (if around 1 or 2 the sleeper is keeping them asleep.)"))
	else
		to_chat(user, span_notice("There is no one inside!"))

/obj/machinery/sleeper/attack_alien(mob/living/carbon/xenomorph/xeno_attacker, damage_amount, damage_type, damage_flag, effects, armor_penetration, isrightclick)
	if(!occupant)
		to_chat(xeno_attacker, span_xenowarning("There is nothing of interest in there."))
		return
	if(xeno_attacker.status_flags & INCORPOREAL || xeno_attacker.do_actions)
		return
	visible_message(span_warning("[xeno_attacker] begins to pry the [src]'s cover!"), 3)
	playsound(src,'sound/effects/metal_creaking.ogg', 25, 1)
	if(!do_after(xeno_attacker, 2 SECONDS))
		return
	playsound(loc, 'sound/effects/metal_creaking.ogg', 25, 1)
	go_out()

/obj/machinery/sleeper/verb/eject()
	set name = "Eject Sleeper"
	set category = "IC.Mob"
	set src in oview(1)

	if(usr.stat != CONSCIOUS)
		return
	go_out()

/obj/machinery/sleeper/relaymove(mob/user)
	if(user.incapacitated(TRUE))
		return
	go_out()

/obj/machinery/sleeper/proc/move_inside_wrapper(mob/living/target, mob/user)
	if(!ishuman(target) || !ishuman(user) || user.incapacitated(TRUE))
		return

	if(occupant)
		to_chat(user, span_notice("The sleeper is already occupied!"))
		return

	if(ismob(target.pulledby))
		var/mob/grabmob = target.pulledby
		grabmob.stop_pulling()
	target.stop_pulling()

	if(!target.forceMove(src))
		return

	visible_message("[target] climbs into the sleeper.", null, null, 3)
	occupant = target

	start_processing()
	if(connected)
		connected.start_processing()
	update_icon()

	for(var/obj/O in src)
		qdel(O)

/obj/machinery/sleeper/MouseDrop_T(mob/M, mob/user)
	. = ..()
	move_inside_wrapper(M, user)

/obj/machinery/sleeper/verb/move_inside()
	set name = "Enter Sleeper"
	set category = "IC.Mob"
	set src in oview(1)

	move_inside_wrapper(usr, usr)
