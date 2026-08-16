/obj/machinery/dropship_part_fabricator
	name = "dropship part fabricator"
	desc = "A large automated 3D printer for producing new dropship parts."
	density = TRUE
	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 20
	icon = 'icons/obj/machines/drone_fab.dmi'
	icon_state = "drone_fab_idle"
	resistance_flags = RESIST_ALL
	interaction_flags = INTERACT_MACHINE_TGUI
	/// List of everything in queue
	var/list/queue = list()
	///Current item being printed
	var/obj/structure/printing
	/// Whether the fabricator is currently printing something or not
	var/busy = FALSE

/obj/machinery/dropship_part_fabricator/update_icon_state()
	. = ..()
	if(machine_stat & NOPOWER)
		icon_state = "drone_fab_nopower"
		return
	if(busy)
		icon_state = "drone_fab_active"
		return
	else
		icon_state = "drone_fab_idle"

/obj/machinery/dropship_part_fabricator/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "DropshipFabricator", name)
		ui.open()

/obj/machinery/dropship_part_fabricator/ui_data(mob/user)
	. = list()
	.["points"] = SSpoints.dropship_points
	.["busy"] = busy
	.["nopower"] = !!(machine_stat & NOPOWER)
	.["printing"] = printing ? initial(printing.name) : null

	var/list/queue_data = list()
	for(var/queue_entry in queue)
		var/obj/structure/queued_type = queue_entry[1]
		queue_data += list(list("name" = initial(queued_type.name)))
	.["queue"] = queue_data

	.["categories"] = get_categories()

/// Returns a list of categories (name + items) available to build on this fabricator
/obj/machinery/dropship_part_fabricator/proc/get_categories()
	. = list()
	. += list(build_category("Condor Equipment", /obj/structure/dropship_equipment/cas))
	. += list(build_category("Condor Ammo", /obj/structure/ship_ammo/cas))
	. += list(build_category("Tadpole Equipment", /obj/structure/dropship_equipment/shuttle))

/// Builds the item list tgui data for every buildable type under base_type
/obj/machinery/dropship_part_fabricator/proc/build_category(category_name, base_type)
	var/list/items = list()
	for(var/build_type in typesof(base_type))
		var/obj/structure/prototype = build_type
		var/build_cost = get_cost(build_type)
		if(!build_cost)
			continue
		items += list(list(
			"id" = "[build_type]",
			"name" = initial(prototype.name),
			"desc" = initial(prototype.desc),
			"cost" = build_cost,
		))
	return list("name" = category_name, "items" = items)

/// Starts the printing process, does point calculations
/obj/machinery/dropship_part_fabricator/proc/build_dropship_part(part_type, mob/user)
	var/cost = get_cost(part_type)

	if((machine_stat & NOPOWER) || !cost)
		next_queue()
		return

	if(SSpoints.dropship_points < cost) //We'll check for points again here in case queue has taken too many points
		balloon_alert_to_viewers("Not enough points")
		next_queue()
		return

	balloon_alert_to_viewers("Printing...")
	playsound(src, 'sound/machines/dropship_fabricator.ogg', 55)
	printing = part_type
	SSpoints.dropship_points -= cost
	busy = TRUE
	update_icon()

	if(user?.ckey)
		var/datum/personal_statistics/personal_statistics = GLOB.personal_statistics_list[user.ckey]
		personal_statistics.cas_points_used += cost

	addtimer(CALLBACK(src, PROC_REF(do_build_dropship_part), part_type), 10 SECONDS)

/// Gets the cost of the product we want to make
/obj/machinery/dropship_part_fabricator/proc/get_cost(build_type)
	if(build_type in typesof(/obj/structure/dropship_equipment))
		var/obj/structure/dropship_equipment/DE = build_type
		return initial(DE.point_cost)

	if(build_type in typesof(/obj/structure/ship_ammo))
		var/obj/structure/dropship_equipment/SA = build_type
		return initial(SA.point_cost)

	//If it's not equipment or ammo, it might be something fucky..
	log_admin_private("[key_name(usr)] may have attempted a href exploit on a dropship printer [AREACOORD(usr)].")
	message_admins("[ADMIN_TPMONTY(usr)] may be attempting a href exploit on a dropship printer [ADMIN_VERBOSEJMP(usr)].")
	return FALSE

/// Finishes up printing, checks for next in queue, prints the actual part
/obj/machinery/dropship_part_fabricator/proc/do_build_dropship_part(part_type)
	var/turf/T = get_step(src, SOUTHEAST)
	playsound(src, 'sound/machines/hydraulics_1.ogg', 40, 1)
	new part_type(T)

	next_queue()

/// Processes next item in queue, if queue has not finished already
/obj/machinery/dropship_part_fabricator/proc/next_queue()
	if(length(queue) > 0) //Cont n inue queue
		//The queue is a list made up of associative lists, so we grab the elements within those lists
		var/part_to_build = queue[1][1]
		var/mob/user = queue[1][2]

		//In case the mob no longer exists by the time this action is done
		if(QDELETED(user))
			user = null

		queue.Cut(1, 2)	//Remove(queue[1]) does not work for some reason
		build_dropship_part(part_to_build, user)
		return TRUE

	//There's nothing left, finish up queue
	balloon_alert_to_viewers("Printing complete!")
	playsound(src,'sound/machines/ping.ogg', 40, FALSE)
	printing = null
	busy = FALSE
	update_icon()

/obj/machinery/dropship_part_fabricator/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("clear")
			queue = list()
			balloon_alert_to_viewers("Entire queue cleared")
			. = TRUE

		if("build")
			var/build_type = text2path(params["id"])
			if(!build_type)
				return

			if(SSpoints.dropship_points < get_cost(build_type))
				balloon_alert(usr, "Not enough points")
				return

			if(busy)
				balloon_alert(usr, "Part added to queue")
				queue.Add(list(list(build_type, usr)))
				. = TRUE
				return

			build_dropship_part(build_type, usr)
			. = TRUE

/obj/machinery/dropship_part_fabricator/attack_powerloader(mob/living/user, obj/item/powerloader_clamp/attached_clamp)
	if(busy)
		balloon_alert(user, "Busy!")
		playsound(src, 'sound/machines/buzz-two.ogg', 40, 1)
		return
	if(istype(attached_clamp.loaded, /obj/structure/dropship_equipment/cas))
		var/obj/structure/dropship_equipment/equipment = attached_clamp.loaded
		if(!equipment.point_cost)
			balloon_alert(user, "Worthless!")
			playsound(src, 'sound/machines/buzz-sigh.ogg', 40, 1)
			return
		balloon_alert(user, "Recycled for [equipment.point_cost]")
		SSpoints.dropship_points += equipment.point_cost
		equipment.moveToNullspace()
		qdel(equipment)
		attached_clamp.loaded = null
		attached_clamp.update_icon()
		playsound(src, 'sound/machines/ding.ogg', 40, 1)
	if(istype(attached_clamp.loaded, /obj/structure/ship_ammo/cas))
		var/obj/structure/ship_ammo/ammo = attached_clamp.loaded
		if(!ammo.point_cost)
			balloon_alert(user, "Worthless!")
			playsound(src, 'sound/machines/buzz-sigh.ogg', 40, 1)
			return
		if(ammo.max_ammo_count != ammo.ammo_count)
			balloon_alert(user, "Not full!")
			playsound(src, 'sound/machines/buzz-sigh.ogg', 40, 1)
			return
		balloon_alert(user, "Recycled for [ammo.point_cost]")
		SSpoints.dropship_points += ammo.point_cost
		ammo.moveToNullspace()
		qdel(ammo)
		attached_clamp.loaded = null
		attached_clamp.update_icon()
		playsound(src, 'sound/machines/ding.ogg', 40, 1)

//Tadpole fab

/obj/machinery/dropship_part_fabricator/tadpole
	name = "tadpole dropship fabricator"
	icon_state = "drone_fab_idle_tadpole"

/obj/machinery/dropship_part_fabricator/tadpole/update_icon_state()
	. = ..()
	icon_state += "_tadpole"

/obj/machinery/dropship_part_fabricator/tadpole/get_categories()
	. = list()
	. += list(build_category("Tadpole Equipment", /obj/structure/dropship_equipment/shuttle))

