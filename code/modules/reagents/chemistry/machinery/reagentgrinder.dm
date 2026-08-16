/obj/machinery/reagentgrinder
	name = "\improper All-In-One Grinder"
	desc = "From BlenderTech. Will It Blend? Let's test it out!"
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "juicer1"
	layer = BELOW_OBJ_LAYER
	density = FALSE
	anchored = FALSE
	use_power = IDLE_POWER_USE
	idle_power_usage = 5
	active_power_usage = 100
	allow_pass_flags = PASS_LOW_STRUCTURE
	var/operating = FALSE
	var/speed = 1
	var/obj/item/reagent_containers/beaker = null
	var/limit = 10
	var/list/blend_items = list (

		//Sheets
		/obj/item/stack/sheet/mineral/phoron = list(/datum/reagent/toxin/phoron = 20),
		/obj/item/stack/sheet/mineral/uranium = list(/datum/reagent/uranium = 20),
		/obj/item/stack/sheet/mineral/silver = list(/datum/reagent/silver = 20),
		/obj/item/stack/sheet/mineral/gold = list(/datum/reagent/gold = 20),
		/obj/item/grown/nettle/death = list(/datum/reagent/toxin/acid/polyacid = 0),
		/obj/item/grown/nettle = list(/datum/reagent/toxin/acid = 0),
		/obj/item/alien_embryo = list(/datum/reagent/consumable/larvajelly = 5),

		//Blender Stuff
		/obj/item/reagent_containers/food/snacks/grown/soybeans = list(/datum/reagent/consumable/soymilk = 0),
		/obj/item/reagent_containers/food/snacks/grown/tomato = list(/datum/reagent/consumable/ketchup = 0),
		/obj/item/reagent_containers/food/snacks/grown/corn = list(/datum/reagent/consumable/cornoil = 0),
		///obj/item/reagent_containers/food/snacks/grown/wheat = list("flour" = -5),
		/obj/item/reagent_containers/food/snacks/grown/ricestalk = list(/datum/reagent/consumable/rice = -5),
		/obj/item/reagent_containers/food/snacks/grown/cherries = list(/datum/reagent/consumable/cherryjelly = 0),
		/obj/item/reagent_containers/food/snacks/grown/plastellium = list(/datum/reagent/toxin/plasticide = 5),


		//All types that you can put into the grinder to transfer the reagents to the beaker. !Put all recipes above this.!
		/obj/item/reagent_containers/pill = list(),
		/obj/item/reagent_containers/food = list()
	)

	var/list/juice_items = list (

		//Juicer Stuff
		/obj/item/reagent_containers/food/snacks/grown/tomato = list(/datum/reagent/consumable/tomatojuice = 0),
		/obj/item/reagent_containers/food/snacks/grown/carrot = list(/datum/reagent/consumable/carrotjuice = 0),
		/obj/item/reagent_containers/food/snacks/grown/berries = list(/datum/reagent/consumable/berryjuice = 0),
		/obj/item/reagent_containers/food/snacks/grown/banana = list(/datum/reagent/consumable/banana = 0),
		/obj/item/reagent_containers/food/snacks/grown/potato = list(/datum/reagent/consumable/nutriment = 0),
		/obj/item/reagent_containers/food/snacks/grown/lemon = list(/datum/reagent/consumable/lemonjuice = 0),
		/obj/item/reagent_containers/food/snacks/grown/orange = list(/datum/reagent/consumable/orangejuice = 0),
		/obj/item/reagent_containers/food/snacks/grown/lime = list(/datum/reagent/consumable/limejuice = 0),
		/obj/item/reagent_containers/food/snacks/watermelonslice = list(/datum/reagent/consumable/watermelonjuice = 0),
		/obj/item/reagent_containers/food/snacks/grown/grapes = list(/datum/reagent/consumable/grapejuice = 0),
		/obj/item/reagent_containers/food/snacks/grown/poisonberries = list(/datum/reagent/consumable/poisonberryjuice = 0),
	)

	var/list/holdingitems = list()

/obj/machinery/reagentgrinder/Initialize(mapload)
	. = ..()
	beaker = new /obj/item/reagent_containers/glass/beaker/large(src)

/obj/machinery/reagentgrinder/update_icon_state()
	. = ..()
	icon_state = "juicer"+num2text(!isnull(beaker))

/obj/machinery/reagentgrinder/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(.)
		return

	if(istype(I, /obj/item/reagent_containers) && I.is_open_container())
		if(beaker)
			return TRUE

		beaker = I
		user.transferItemToLoc(I, src)
		update_icon()
		return TRUE

	else if(length(holdingitems) >= limit)
		to_chat(user, "The machine cannot hold anymore items.")
		return TRUE

	else if(istype(I, /obj/item/storage/bag/plants))
		for(var/obj/item/reagent_containers/food/snacks/grown/G in I.contents)
			I.contents -= G
			G.forceMove(src)
			holdingitems += G
			if(length(holdingitems) >= limit)
				to_chat(user, "You fill the All-In-One grinder to the brim.")
				break

		if(!length(I.contents))
			to_chat(user, "You empty the plant bag into the All-In-One grinder.")

		return TRUE

	else if(!is_type_in_list(I, blend_items) && !is_type_in_list(I, juice_items))
		to_chat(user, "Cannot refine into a reagent.")
		return TRUE

	user.transferItemToLoc(I, src)
	holdingitems += I
	return TRUE

/obj/machinery/reagentgrinder/examine(mob/user)
	. = ..()
	if(operating)
		. += span_notice("It's currently working. Please wait.")
		return

	if(length(holdingitems))
		. += span_notice("Its processing chamber contains:")
		for(var/obj/item/O in holdingitems)
			. += span_notice("- \a [O.name].")
	else
		. += span_notice("Its processing chamber is empty.")

	if(beaker)
		if(length(beaker.reagents.reagent_list))
			. += span_notice("It has a beaker attached, containing:")
			for(var/datum/reagent/R in beaker.reagents.reagent_list)
				. += span_notice("- [R.volume]u of [R.name].")
		else
			. += span_notice("It has an empty beaker attached.")
	else
		. += span_warning("It has no beaker attached.")

/// Radial menu, RU/TG-style: Grind/Juice/Eject. Right-click to detach the beaker instead.
/obj/machinery/reagentgrinder/interact(mob/user)
	. = ..()
	if(.)
		return

	if(operating)
		balloon_alert(user, "still working!")
		return

	var/is_chamber_empty = !length(holdingitems)
	if(is_chamber_empty && !beaker)
		balloon_alert(user, "it's empty!")
		return

	var/list/choices = list()
	if(beaker && !is_chamber_empty && !(machine_stat & (NOPOWER|BROKEN)))
		choices["grind"] = image(icon = 'icons/mob/radial_actions.dmi', icon_state = "radial_grind")
		choices["juice"] = image(icon = 'icons/mob/radial_actions.dmi', icon_state = "radial_juice")
	if(!is_chamber_empty)
		choices["eject"] = image(icon = 'icons/mob/radial_actions.dmi', icon_state = "radial_eject")

	if(!length(choices))
		return

	var/choice = show_radial_menu(user, src, choices, custom_check = CALLBACK(src, PROC_REF(check_interactable), user), require_near = TRUE, tooltips = TRUE)
	if(!choice || !check_interactable(user))
		return

	switch(choice)
		if("grind")
			grind()
		if("juice")
			juice()
		if("eject")
			eject()

/// Whether the radial menu should stay open / the chosen action should still fire.
/obj/machinery/reagentgrinder/proc/check_interactable(mob/user)
	return !operating && !(machine_stat & (NOPOWER|BROKEN)) && Adjacent(user) && !user.incapacitated()

/// RMB: detach/eject the attached beaker without opening the radial menu.
/obj/machinery/reagentgrinder/RightClick(mob/user)
	. = ..()
	if(!istype(user))
		return .
	//Consume the click regardless, so a plain RMB doesn't also fall through into an UnarmedAttack/interact().
	. = TRUE
	if(!Adjacent(user) || user.incapacitated())
		balloon_alert(user, "you can't reach!")
		return .
	if(operating)
		balloon_alert(user, "still working!")
		return .
	detach(user)

/obj/machinery/reagentgrinder/proc/detach(mob/user)
	if(user && user.stat != CONSCIOUS)
		return
	if(!beaker)
		return
	var/obj/item/reagent_containers/old_beaker = beaker
	beaker = null
	update_icon()
	if(user)
		if(!user.put_in_active_hand(old_beaker) && !user.put_in_inactive_hand(old_beaker))
			old_beaker.forceMove(get_turf(src))
		balloon_alert(user, "detaches the beaker")
	else
		old_beaker.forceMove(get_turf(src))

/obj/machinery/reagentgrinder/proc/eject()

	if(usr.stat != 0)
		return
	if(length(holdingitems) == 0)
		return

	for(var/obj/item/O in holdingitems)
		O.loc = src.loc
		holdingitems -= O
	holdingitems = list()

/obj/machinery/reagentgrinder/proc/shake_for(duration)
	var/offset = prob(50) ? -2 : 2
	var/old_pixel_x = pixel_x
	animate(src, pixel_x = pixel_x + offset, time = 0.2, loop = -1) //start shaking
	addtimer(CALLBACK(src, PROC_REF(stop_shaking), old_pixel_x), duration)

/obj/machinery/reagentgrinder/proc/stop_shaking(old_px)
	animate(src)
	pixel_x = old_px

/obj/machinery/reagentgrinder/proc/operate_for(time, silent = FALSE, juicing = FALSE)
	shake_for(time / speed)
	operating = TRUE
	if(!silent)
		if(!juicing)
			playsound(src, 'sound/machines/blender.ogg', 50, TRUE)
		else
			playsound(src, 'sound/machines/juicer.ogg', 20, TRUE)
	addtimer(VARSET_CALLBACK(src, operating, FALSE), time / speed)

/obj/machinery/reagentgrinder/proc/is_allowed(obj/item/reagent_containers/O)
	for (var/i in blend_items)
		if(istype(O, i))
			return TRUE
	return FALSE

/obj/machinery/reagentgrinder/proc/get_allowed_by_id(obj/item/grown/O)
	for (var/i in blend_items)
		if(istype(O, i))
			return blend_items[i]

/obj/machinery/reagentgrinder/proc/get_allowed_snack_by_id(obj/item/reagent_containers/food/snacks/O)
	for(var/i in blend_items)
		if(istype(O, i))
			return blend_items[i]

/obj/machinery/reagentgrinder/proc/get_allowed_juice_by_id(obj/item/reagent_containers/food/snacks/O)
	for(var/i in juice_items)
		if(istype(O, i))
			return juice_items[i]

/obj/machinery/reagentgrinder/proc/get_grownweapon_amount(obj/item/grown/O)
	if(!istype(O))
		return 5
	else if(O.potency == -1)
		return 5
	else
		return round(O.potency)

/obj/machinery/reagentgrinder/proc/get_juice_amount(obj/item/reagent_containers/food/snacks/grown/O)
	if(!istype(O))
		return 5
	else if(O.potency == -1)
		return 5
	else
		return round(5*sqrt(O.potency))

/obj/machinery/reagentgrinder/proc/remove_object(obj/item/O)
	holdingitems -= O
	qdel(O)

/obj/machinery/reagentgrinder/proc/juice()
	power_change()
	if(machine_stat & (NOPOWER|BROKEN))
		return
	if(!beaker || (beaker?.reagents.total_volume >= beaker.reagents.maximum_volume))
		return
	operate_for(5 SECONDS, juicing = TRUE)
	//Snacks
	for (var/obj/item/reagent_containers/food/snacks/O in holdingitems)
		if(beaker.reagents.total_volume >= beaker.reagents.maximum_volume)
			break

		var/allowed = get_allowed_juice_by_id(O)
		if(isnull(allowed))
			break

		for (var/r_id in allowed)

			var/space = beaker.reagents.maximum_volume - beaker.reagents.total_volume
			var/amount = get_juice_amount(O)

			beaker.reagents.add_reagent(r_id, min(amount, space))

			if(beaker.reagents.total_volume >= beaker.reagents.maximum_volume)
				break

		remove_object(O)

/obj/machinery/reagentgrinder/proc/grind()

	power_change()
	if(machine_stat & (NOPOWER|BROKEN))
		return
	if(!beaker || (beaker?.reagents.total_volume >= beaker.reagents.maximum_volume))
		return
	operate_for(6 SECONDS)
	//Snacks and Plants
	for (var/obj/item/reagent_containers/food/snacks/O in holdingitems)
		if(beaker.reagents.total_volume >= beaker.reagents.maximum_volume)
			break

		var/allowed = get_allowed_snack_by_id(O)
		if(isnull(allowed))
			break

		for (var/r_id in allowed)
			var/space = beaker.reagents.maximum_volume - beaker.reagents.total_volume
			var/amount = allowed[r_id]
			if(amount <= 0)
				if(amount == 0)
					if(O.reagents != null && O.reagents.has_reagent(/datum/reagent/consumable/nutriment))
						beaker.reagents.add_reagent(r_id, min(O.reagents.get_reagent_amount(/datum/reagent/consumable/nutriment), space))
						O.reagents.remove_reagent(/datum/reagent/consumable/nutriment, min(O.reagents.get_reagent_amount(/datum/reagent/consumable/nutriment), space))
				else
					if(O.reagents != null && O.reagents.has_reagent(/datum/reagent/consumable/nutriment))
						beaker.reagents.add_reagent(r_id, min(round(O.reagents.get_reagent_amount(/datum/reagent/consumable/nutriment)*abs(amount)), space))
						O.reagents.remove_reagent(/datum/reagent/consumable/nutriment, min(O.reagents.get_reagent_amount(/datum/reagent/consumable/nutriment), space))
			else
				O.reagents.trans_id_to(beaker, r_id, min(amount, space))

			if(beaker.reagents.total_volume >= beaker.reagents.maximum_volume)
				break

		if(length(O.reagents.reagent_list) == 0)
			remove_object(O)

	//Sheets
	for (var/obj/item/stack/sheet/O in holdingitems)
		var/allowed = get_allowed_by_id(O)
		if(beaker.reagents.total_volume >= beaker.reagents.maximum_volume)
			break
		for(var/i = 1; i <= round(O.amount, 1); i++)
			for (var/r_id in allowed)
				var/space = beaker.reagents.maximum_volume - beaker.reagents.total_volume
				var/amount = allowed[r_id]
				beaker.reagents.add_reagent(r_id,min(amount, space))
				if(space < amount)
					break
			if(i == round(O.amount, 1))
				remove_object(O)
				break
	//Plants
	for (var/obj/item/grown/O in holdingitems)
		if(beaker.reagents.total_volume >= beaker.reagents.maximum_volume)
			break
		var/allowed = get_allowed_by_id(O)
		for (var/r_id in allowed)
			var/space = beaker.reagents.maximum_volume - beaker.reagents.total_volume
			var/amount = allowed[r_id]
			if(amount == 0)
				if(O.reagents != null && O.reagents.has_reagent(r_id))
					beaker.reagents.add_reagent(r_id,min(O.reagents.get_reagent_amount(r_id), space))
			else
				beaker.reagents.add_reagent(r_id,min(amount, space))

			if(beaker.reagents.total_volume >= beaker.reagents.maximum_volume)
				break
		remove_object(O)

	//special xeno embryo grinding
	for (var/obj/item/alien_embryo/O in holdingitems)
		if(beaker.reagents.total_volume >= beaker.reagents.maximum_volume)
			break
		var/space = beaker.reagents.maximum_volume - beaker.reagents.total_volume
		var/amount = O.grinder_amount
		beaker.reagents.add_reagent(O.grinder_datum,min(amount, space))
		if(space < amount)
			break
		remove_object(O)
		break

	//Everything else - Transfers reagents from it into beaker
	for(var/obj/item/reagent_containers/O in holdingitems)
		if(beaker.reagents.total_volume >= beaker.reagents.maximum_volume)
			break
		var/amount = O.reagents.total_volume
		O.reagents.trans_to(beaker, amount)
		if(!O.reagents.total_volume)
			remove_object(O)

/obj/machinery/reagentgrinder/nopower
	use_power = NO_POWER_USE

/obj/machinery/reagentgrinder/nopower/valhalla
	resistance_flags = INDESTRUCTIBLE

/obj/machinery/reagentgrinder/yautja
	icon = 'icons/obj/machines/yautja_machines.dmi'
	icon_state = "grinder"
