/obj/machinery/suit_storage_unit
	name = "Suit Storage Unit"
	desc = "An industrial U-Stor-It Storage unit designed to accomodate all kinds of space suits. Its on-board equipment also allows the user to decontaminate the contents through a UV-ray purging cycle. There's a warning label dangling from the control pad, reading \"STRICTLY NO BIOLOGICALS IN THE CONFINES OF THE UNIT\"."
	icon = 'icons/obj/machines/suitstorage.dmi'
	icon_state = "closed" //order is: [has helmet][has suit][has human][is open][is locked][is UV cycling][is powered][is dirty/broken] [is superUVcycling]
	anchored = TRUE
	density = TRUE
	var/obj/item/clothing/suit/space/inserted_suit
	var/obj/item/clothing/head/helmet/space/inserted_helmet
	var/obj/item/clothing/mask/inserted_mask
	var/obj/item/tank/inserted_tank
	var/starting_suit_type
	var/starting_helmet_type
	var/starting_mask_type
	var/starting_tank_type
	var/isopen = FALSE
	var/isUV = FALSE

/obj/machinery/suit_storage_unit/Initialize(mapload)
	. = ..()
	if(starting_suit_type)
		inserted_suit = new starting_suit_type(src)
	if(starting_helmet_type)
		inserted_helmet = new starting_helmet_type(src)
	if(starting_mask_type)
		inserted_mask = new starting_mask_type(src)
	if(starting_tank_type)
		inserted_tank = new starting_tank_type(src)
	update_icon()

/obj/machinery/suit_storage_unit/update_overlays()
	. = ..()
	if(isUV || !isopen)
		return

	if(inserted_helmet)
		. += image("helmet")
	if(inserted_suit)
		. += image("suit")
	if(inserted_mask)
		. += image("mask")
	if(inserted_tank)
		. += image("tank")

/obj/machinery/suit_storage_unit/update_icon_state()
	. = ..()
	if(isUV)
		return
	if(isopen)
		icon_state = "open"
	else
		icon_state = "closed"
	if(machine_stat & NOPOWER)
		icon_state += "_off"

/obj/machinery/suit_storage_unit/power_change()
	. = ..()
	if(machine_stat & NOPOWER)
		dump_everything()
		isUV = 0

/obj/machinery/suit_storage_unit/ex_act(severity)
	if(prob(severity * 0.3))
		if(prob(50))
			dump_everything()
		qdel(src)

/obj/machinery/suit_storage_unit/examine(mob/user)
	. = ..()
	if(isUV)
		. += span_warning("It's currently running a UV cauterisation cycle. Please wait.")
		return
	. += span_notice("Helmet compartment: [inserted_helmet ? inserted_helmet.name : "empty"].")
	. += span_notice("Suit compartment: [inserted_suit ? inserted_suit.name : "empty"].")
	. += span_notice("Mask compartment: [inserted_mask ? inserted_mask.name : "empty"].")
	. += span_notice("Tank compartment: [inserted_tank ? inserted_tank.name : "empty"].")
	. += span_notice("The unit's doors are [isopen ? "open" : "closed"].")

/// Radial menu, RU/TG-style: buttons for the actions/contents that are actually available right now.
/obj/machinery/suit_storage_unit/interact(mob/user)
	. = ..()
	if(.)
		return

	if(machine_stat & NOPOWER)
		balloon_alert(user, "no power!")
		return

	if(isUV) //The thing is running its cauterisation cycle. You have to wait.
		balloon_alert(user, "unit is cauterising, please wait!")
		return

	var/list/choices = list()

	if(isopen)
		choices["close"] = image(icon = 'icons/mob/radial_actions.dmi', icon_state = "radial_close")
		if(inserted_helmet)
			choices["dispense_helmet"] = inserted_helmet
		if(inserted_suit)
			choices["dispense_suit"] = inserted_suit
		if(inserted_mask)
			choices["dispense_mask"] = inserted_mask
		if(inserted_tank)
			choices["dispense_tank"] = inserted_tank
	else
		choices["open"] = image(icon = 'icons/mob/radial_actions.dmi', icon_state = "radial_open")
		choices["disinfect"] = image(icon = 'icons/mob/radial_actions.dmi', icon_state = "radial_disinfect")

	if(!length(choices))
		balloon_alert(user, "nothing to do!")
		return

	var/choice = show_radial_menu(user, src, choices, custom_check = CALLBACK(src, PROC_REF(check_interactable), user), require_near = TRUE, tooltips = TRUE)
	if(!choice || !check_interactable(user))
		return

	switch(choice)
		if("open")
			if(!isopen)
				toggle_open(user)
		if("close")
			if(isopen)
				toggle_open(user)
		if("disinfect")
			start_UV(user)
		if("dispense_helmet")
			dispense_helmet()
		if("dispense_suit")
			dispense_suit()
		if("dispense_mask")
			dispense_mask()
		if("dispense_tank")
			dispense_tank()

	update_icon()

/// Whether the radial menu should stay open / the chosen action should still fire.
/obj/machinery/suit_storage_unit/proc/check_interactable(mob/user)
	return !(machine_stat & NOPOWER) && !isUV && Adjacent(user) && !user.incapacitated()

/obj/machinery/suit_storage_unit/proc/dispense_helmet()
	if(inserted_helmet)
		inserted_helmet.forceMove(loc)
		inserted_helmet = null

/obj/machinery/suit_storage_unit/proc/dispense_suit()
	if(inserted_suit)
		inserted_suit.forceMove(loc)
		inserted_suit = null

/obj/machinery/suit_storage_unit/proc/dispense_mask()
	if(inserted_mask)
		inserted_mask.forceMove(loc)
		inserted_mask = null

/obj/machinery/suit_storage_unit/proc/dispense_tank()
	if(inserted_tank)
		inserted_tank.forceMove(loc)
		inserted_tank = null

/obj/machinery/suit_storage_unit/proc/dump_everything()
	dispense_helmet()
	dispense_suit()
	dispense_mask()
	dispense_tank()

/obj/machinery/suit_storage_unit/proc/toggle_open(mob/user as mob)
	if(isUV)
		to_chat(user, "<font color='red'>Unable to open unit.</font>")
		return
	isopen = !isopen
	update_icon()

/obj/machinery/suit_storage_unit/proc/start_UV(mob/user)
	set waitfor = 0

	if(isopen)
		to_chat(user, "<font color='red'>Unit storage is not closed -- Aborting.</font>")
		return

	if(isUV)
		return

	if(!inserted_helmet && !inserted_mask && !inserted_suit) //shit's empty yo
		to_chat(user, "<font color='red'>Unit storage bays empty. Nothing to disinfect -- Aborting.</font>")
		return
	to_chat(user, span_notice("You start the Unit's cauterisation cycle."))
	isUV = 1
	update_icon()
	updateUsrDialog()

	sleep(15 SECONDS)

	if(gc_destroyed)
		return
	if(inserted_helmet)
		inserted_helmet.clean_blood()
	if(inserted_suit)
		inserted_suit.clean_blood()
	if(inserted_mask)
		inserted_mask.clean_blood()
	if(inserted_tank)
		inserted_tank.clean_blood()
	isUV = 0 //Cycle ends
	update_icon()
	updateUsrDialog()

/obj/machinery/suit_storage_unit/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(.)
		return
	if(machine_stat & NOPOWER)
		return

	if(!isopen)
		return

	if(istype(I, /obj/item/clothing/suit/space))
		var/obj/item/clothing/suit/space/S = I
		if(inserted_suit)
			to_chat(user, span_warning("The unit already contains a suit."))
			return

		if(!user.transferItemToLoc(S, src))
			return

		to_chat(user, span_notice("You load the [S.name] into the storage compartment."))
		inserted_suit = S

	else if(istype(I,/obj/item/clothing/head/helmet))
		var/obj/item/clothing/head/helmet/H = I
		if(inserted_helmet)
			to_chat(user, span_warning("The unit already contains a helmet."))
			return

		if(!user.transferItemToLoc(H, src))
			return

		to_chat(user, span_notice("You load the [H.name] into the storage compartment."))
		inserted_helmet = H

	else if(istype(I, /obj/item/clothing/mask))
		var/obj/item/clothing/mask/M = I
		if(inserted_mask)
			to_chat(user, span_warning("The unit already contains a mask."))
			return

		if(!user.transferItemToLoc(M, src))
			return

		to_chat(user, span_notice("You load the [M.name] into the storage compartment."))
		inserted_mask = M

	else if(istype(I, /obj/item/tank))
		var/obj/item/tank/T = I
		if(inserted_tank)
			to_chat(user, span_warning("The unit already contains a tank."))
			return

		if(!user.transferItemToLoc(T, src))
			return

		to_chat(user, span_notice("You load the [T.name] into the storage compartment."))
		inserted_tank = T

	update_icon()
	updateUsrDialog()

/obj/machinery/suit_storage_unit/carbon_unit
	starting_suit_type = /obj/item/clothing/suit/space/tgmc
	starting_helmet_type = /obj/item/clothing/head/helmet/space/tgmc
	starting_mask_type = /obj/item/clothing/mask/breath
	starting_tank_type = /obj/item/tank/oxygen

/obj/machinery/suit_storage_unit/standard_unit
	starting_suit_type = /obj/item/clothing/suit/space
	starting_helmet_type = /obj/item/clothing/head/helmet/space
	starting_mask_type = /obj/item/clothing/mask/breath
	starting_tank_type = /obj/item/tank/oxygen
