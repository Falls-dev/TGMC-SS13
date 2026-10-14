/obj/item/folded_tent
	name = "folded abstract tent"
	icon = 'icons/obj/structures/tents_folded.dmi'
	icon_state = "tent"
	w_class = WEIGHT_CLASS_BULKY
	/// Required cleared area along X axis
	var/dim_x = 1
	/// Required cleared area along Y axis
	var/dim_y = 1
	/// Tents map template typepath
	var/template_preset = "abstract"
	///Map template datum used for tent
	var/datum/map_template/template
	/// If this tent can be deployed anywhere
	var/unrestricted_deployment = FALSE
	/// Prevent overlapping deployment attempts with the same item.
	var/deploying = FALSE

/obj/item/folded_tent/Initialize(mapload, ...)
	. = ..()
	if(template_preset == "abstract") //So spawning an abstract tent won't fail create and destroy
		return
	set_template(SSmapping.tent_type_templates[template_preset])
	if(!template)
		CRASH("[src] initialized with template preset, \"[template_preset]\", that does not exist.")

/obj/item/folded_tent/proc/set_template(datum/map_template/new_template)
	if(!istype(new_template))
		return
	template = new_template
	dim_x = template.width
	dim_y = template.height

/// Check an area is clear for deployment of the tent
/obj/item/folded_tent/proc/check_area(turf/ref_turf, mob/message_receiver, display_error = FALSE)
	SHOULD_NOT_SLEEP(TRUE)
	if(!ref_turf || ref_turf.x + dim_x - 1 > world.maxx || ref_turf.y + dim_y - 1 > world.maxy)
		return FALSE
	. = TRUE
	var/list/turf_block = get_deployment_area(ref_turf)
	for(var/turf/turf as anything in turf_block)
		var/turf/open/open_turf = turf
		if((!istype(open_turf) || !open_turf.allow_construction) && !unrestricted_deployment)
			if(message_receiver)
				to_chat(message_receiver, span_warning("You cannot deploy tents on restricted areas."))
			if(display_error)
				new /obj/effect/temp_visual/tent_deployment_area/error(turf)
			return FALSE
		if(istype(get_area(turf), /area/shuttle) || isspaceturf(turf))
			if(message_receiver)
				to_chat(message_receiver, span_warning("Tents cannot be deployed on shuttles or in space."))
			return FALSE
		if(turf.density)
			if(message_receiver)
				to_chat(message_receiver, span_warning("You cannot deploy [src] here, something ([turf]) is in the way."))
			if(display_error)
				new /obj/effect/temp_visual/tent_deployment_area/error(turf)
			return FALSE
		for(var/atom/movable/atom as anything in turf)
			if(isliving(atom) || atom.density || istype(atom, /obj/structure/tent))
				if(message_receiver)
					to_chat(message_receiver, span_warning("You cannot deploy [src] here, something ([atom.name]) is in the way."))
				if(display_error)
					new /obj/effect/temp_visual/tent_deployment_area/error(turf)
				return FALSE
	return TRUE

/obj/item/folded_tent/proc/unfold(mob/user, turf/ref_turf)
	if(!istype(template))
		to_chat(user, span_boldwarning("[src] does not contain a tent! It is broken!"))
		CRASH("[src] attempted to unfold \"[template]\" as a tent.")
	return template.load(ref_turf)

/obj/item/folded_tent/proc/get_deployment_area(turf/ref_turf)
	RETURN_TYPE(/list)
	return block(ref_turf, locate(ref_turf.x + dim_x - 1, ref_turf.y + dim_y - 1, ref_turf.z))

/obj/item/folded_tent/attack_self(mob/living/user)
	. = ..()
	if(deploying || user.get_active_held_item() != src)
		return
	var/off_x = tgui_input_number(user, "Horizontal offset (entrance remains to the south).", "Tent X Offset", 0, dim_x - 1, 0)
	if(isnull(off_x) || QDELETED(src) || user.get_active_held_item() != src)
		return
	var/off_y = tgui_input_number(user, "Vertical offset (entrance remains to the south).", "Tent Y Offset", 0, dim_y - 1, 0)
	if(isnull(off_y) || QDELETED(src) || user.get_active_held_item() != src || deploying)
		return
	off_x = -off_x
	off_y = -off_y
	var/turf/deploy_turf = user.loc
	if(!istype(deploy_turf))
		return // In a locker or something. Get lost you already have a home.

	switch(user.dir) //Handles offsets when deploying
		if(NORTH)
			deploy_turf = locate(deploy_turf.x + off_x, deploy_turf.y + 1, deploy_turf.z)
		if(SOUTH)
			deploy_turf = locate(deploy_turf.x + off_x, deploy_turf.y - dim_y, deploy_turf.z)
		if(EAST)
			deploy_turf = locate(deploy_turf.x + 1, deploy_turf.y + off_y, deploy_turf.z)
		if(WEST)
			deploy_turf = locate(deploy_turf.x - dim_x, deploy_turf.y + off_y, deploy_turf.z)

	if(!istype(deploy_turf) || (deploy_turf.x + dim_x - 1 > world.maxx) || (deploy_turf.y + dim_y - 1 > world.maxy)) // Map border basically
		return

	if(!SSmapping.level_trait(deploy_turf.z, ZTRAIT_GROUND) && !unrestricted_deployment)
		to_chat(user, span_warning("TGMC Operational Tents are intended for operations, not ship or space recreation."))
		return

	var/list/turf_overlay = list()
	var/list/turf/deployment_area = get_deployment_area(deploy_turf)

	if(!check_area(deploy_turf, user, TRUE))
		for(var/turf/turf in deployment_area)
			new /obj/effect/temp_visual/tent_deployment_area(turf) // plus error in check_area
		return

	for(var/turf/turf in deployment_area)
		turf_overlay += new /obj/effect/temp_visual/tent_deployment_area/casting(turf)

	user.visible_message(span_info("[user] starts deploying [src]..."),
		span_warning("You start assembling [src]... Stand still, it might take a bit to figure it out..."))
	deploying = TRUE
	if(!do_after(user, 6 SECONDS, NONE, user, BUSY_ICON_BUILD))
		deploying = FALSE
		to_chat(user, span_warning("You were interrupted!"))
		for(var/gfx in turf_overlay)
			qdel(gfx)
		return

	deploying = FALSE
	if(QDELETED(src) || user.get_active_held_item() != src || !check_area(deploy_turf, user, TRUE))
		for(var/gfx in turf_overlay)
			QDEL_IN(gfx, 1.5 SECONDS)
		return

	if(!unfold(user, deploy_turf))
		to_chat(user, span_warning("The tent could not be deployed."))
		for(var/gfx in turf_overlay)
			qdel(gfx)
		return
	user.visible_message(span_info("[user] finishes deploying [src]!"), span_info("You finish deploying [src]!"))
	for(var/gfx in turf_overlay)
		qdel(gfx)
	qdel(src) // Success!

/obj/item/folded_tent/cmd
	name = "folded TGMC Command Tent"
	icon_state = "cmd"
	desc = "A standard TGMC Command Tent. This one comes equipped with a self-powered Overwatch Console and a command radio. Unfold in a suitable location to maximize usefulness. Staff Officer not included. ENTRANCE TO THE SOUTH."
	template_preset = "tent_cmd"

/obj/item/folded_tent/med
	name = "folded TGMC Medical Tent"
	icon_state = "med"
	desc = "A standard TGMC Medical Tent. This one comes equipped with advanced field surgery facilities. Unfold in a suitable location to maximize health gains. Surgical Tray not included. ENTRANCE TO THE SOUTH."
	template_preset = "tent_med"

/obj/item/folded_tent/reqs
	name = "folded TGMC Requisitions Tent"
	icon_state = "req"
	desc = "A standard TGMC Requisitions Tent. Now, you can enjoy req line anywhere you go! Unfold in a suitable location to maximize resource distribution. Supply shuttle not included. ENTRANCE TO THE SOUTH."
	template_preset = "tent_reqs"

/obj/item/folded_tent/big
	name = "folded TGMC Big Tent"
	icon_state = "big"
	desc = "A standard TGMC Tent. This one is just a bigger, general purpose version. Unfold in a suitable location to maximize FOB vibes. Bravo not included. ENTRANCE TO THE SOUTH."
	template_preset = "tent_big"

/obj/item/folded_tent/mess
	name = "folded TGMC Mess Tent"
	icon_state = "mess"
	desc = "A standard TGMC Mess Tent. This one comes equipped with a kitchen and dining utilities. Unfold in a suitable location to maximize meal handouts. Mess Technician not included. ENTRANCE TO THE SOUTH."
	template_preset = "tent_mess"

/obj/effect/temp_visual/tent_deployment_area
	randomdir = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	icon = 'icons/effects/tent_placement.dmi'
	icon_state = "white"
	color = "#f39e00"
	duration = 1.5 SECONDS
	layer = FLY_LAYER

/obj/effect/temp_visual/tent_deployment_area/casting
	duration = 10 SECONDS
	color = "#228822"

/obj/effect/temp_visual/tent_deployment_area/error
	layer = ABOVE_TREE_LAYER
	color = "#bb0000"
