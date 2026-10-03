/obj/item/pinpointer
	name = "Xeno structure pinpointer"
	icon = 'icons/obj/items/pinpointer.dmi'
	icon_state = "pinoff"
	atom_flags = CONDUCT
	equip_slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_TINY
	worn_icon_list = list(
		slot_l_hand_str = 'icons/mob/inhands/equipment/engineering_left.dmi',
		slot_r_hand_str = 'icons/mob/inhands/equipment/engineering_right.dmi',
	)
	worn_icon_state = "electronic"
	throw_speed = 4
	throw_range = 20
	///What we're currently tracking
	var/atom/movable/target
	///The list of things we're tracking
	var/list/tracked_list
	///The hive we're tracking
	var/tracked_hivenumber = XENO_HIVE_NORMAL
	///The list of hives we will never track
	var/static/list/blacklisted_hivenumbers = list(XENO_HIVE_NONE, XENO_HIVE_ADMEME, XENO_HIVE_FALLEN)

/obj/item/pinpointer/Initialize(mapload)
	. = ..()
	tracked_list = GLOB.xeno_critical_structures_by_hive[tracked_hivenumber]

/obj/item/pinpointer/Destroy()
	target = null
	return ..()

/obj/item/pinpointer/proc/set_target(mob/living/user)
	///The hivenumbers that we're allowed to select structures to track from
	var/list/trackable_hivenumbers = list()
	for(var/hivenumber in GLOB.xeno_critical_structures_by_hive)
		if(hivenumber in blacklisted_hivenumbers) //no reason to ever track valhalla or admin beans
			continue
		if(!length(GLOB.xeno_critical_structures_by_hive[hivenumber])) //hives with no structures don't need tracking either
			continue
		trackable_hivenumbers |= hivenumber

	if(length(trackable_hivenumbers) == 1)
		tracked_list = GLOB.xeno_critical_structures_by_hive[trackable_hivenumbers[1]]

	else if(length(trackable_hivenumbers) > 1)
		tracked_hivenumber = tgui_input_list(user, "Select the hive you wish to track.", "Pinpointer", trackable_hivenumbers)
		if(!tracked_hivenumber)
			return
		tracked_list = GLOB.xeno_critical_structures_by_hive[tracked_hivenumber]

	if(!length(tracked_list))
		balloon_alert(user, "No signal")
		return
	target = tgui_input_list(user, "Select the structure you wish to track.", "Pinpointer", tracked_list)
	if(QDELETED(target))
		return
	var/turf/pinpointer_loc = get_turf(src)
	if(target.z != pinpointer_loc.z)
		balloon_alert(user, "Signal too weak")
		target = null
		return


/obj/item/pinpointer/attack_self(mob/living/user)
	if(active)
		deactivate(user)
	else
		activate(user)


/obj/item/pinpointer/proc/activate(mob/living/user)
	set_target(user)
	if(QDELETED(target))
		return
	active = TRUE
	START_PROCESSING(SSobj, src)
	balloon_alert(user, "Pinpointer activated")


/obj/item/pinpointer/proc/deactivate(mob/living/user)
	active = FALSE
	target = null
	STOP_PROCESSING(SSobj, src)
	icon_state = "pinoff"
	balloon_alert(user, "Pinpointer deactivated")


/obj/item/pinpointer/process()
	if(QDELETED(target))
		active = FALSE
		icon_state = "pinonnull"
		return PROCESS_KILL

	setDir(get_dir(src, target))
	switch(get_dist(src, target))
		if(0)
			icon_state = "pinondirect"
		if(1 to 8)
			icon_state = "pinonclose"
		if(9 to 16)
			icon_state = "pinonmedium"
		if(16 to INFINITY)
			icon_state = "pinonfar"

/obj/item/pinpointer/archaeology
    name = "Archaeological pinpointer"
    desc = "An advanced acoustic scanner tuned to detect dense organic fossils. Tap the ground to scan for depth."

/obj/item/pinpointer/archaeology/Initialize(mapload)
    . = ..()
    tracked_list = null

/obj/item/pinpointer/archaeology/set_target(mob/living/user)
    if(!SSxeno_archaeology || !length(SSxeno_archaeology.active_sites))
        balloon_alert(user, "No signals found")
        return

    var/list/options = list()
    var/list/site_by_name = list()

    for(var/datum/dig_site/S in SSxeno_archaeology.active_sites)
        var/option_name = "[S.site_name]"
        options += option_name
        site_by_name[option_name] = S

    var/chosen = tgui_input_list(user, "Select the site you wish to track.", "Archaeology Pinpointer", options)
    if(!chosen || QDELETED(src) || QDELETED(user))
        return

    var/datum/dig_site/selected_site = site_by_name[chosen]
    target = selected_site.location

    var/turf/pinpointer_loc = get_turf(src)
    if(target.z != pinpointer_loc.z)
        balloon_alert(user, "Signal too weak")
        target = null
        return

/obj/item/pinpointer/archaeology/process()
    if(!target)
        active = FALSE
        icon_state = "pinonnull"
        return PROCESS_KILL

    setDir(get_dir(src, target))
    var/dist = get_dist(src, target)
    switch(dist)
        if(0)
            icon_state = "pinondirect"
        if(1 to 8)
            icon_state = "pinonclose"
        if(9 to 16)
            icon_state = "pinonmedium"
        if(17 to INFINITY)
            icon_state = "pinonfar"

/obj/item/pinpointer/archaeology/afterattack(atom/target_atom, mob/user, proximity_flag, click_parameters)
    if(!proximity_flag)
        return ..()

    var/turf/T = get_turf(target_atom)
    if(!T)
        return ..()

    var/datum/dig_site/S = SSxeno_archaeology?.get_site_at(T)
    if(S)
        balloon_alert(user, "Depth: [S.target_depth] cm")
        to_chat(user, span_notice("\[[src.name]\]: Acoustic sounding of sector [S.site_name] is complete. Fossil has been recorded at depth [S.target_depth] cm."))
    else
        balloon_alert(user, "Nothing found")

