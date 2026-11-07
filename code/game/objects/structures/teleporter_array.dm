/obj/structure/teleporter_array
	name = "Teleporter Array"
	desc = "A large scale teleporter array, capable of transporting an entire squad directly to the battlefield."
	icon = 'icons/obj/structures/teleporter.dmi'
	icon_state = "teleporter"
	obj_flags = NONE
	density = FALSE
	layer = BELOW_OBJ_LAYER
	resistance_flags = RESIST_ALL
	faction = FACTION_SOM
	///Current state of teleporter
	var/teleporter_status = TELEPORTER_ARRAY_READY
	///How many times this can be used
	var/charges = 2
	///The target turf for teleportation
	var/turf/target_turf
	///The Z-level that the teleporter can teleport to
	var/targetted_zlevel = 2
	///The radius of the teleport
	var/range = 2
	///teleport windup
	var/windup = 10 SECONDS
	///Actions to set a target for, and activate the teleporter
	var/list/datum/action/innate/interaction_actions
	///The mob currently controlling the teleporter
	var/mob/controller

/obj/structure/teleporter_array/Initialize(mapload)
	. = ..()
	var/datum/game_mode/hvh/campaign/campaign = SSticker?.mode
	if(istype(campaign))
		targetted_zlevel = campaign.current_mission?.mission_state != MISSION_STATE_FINISHED ? campaign.current_mission?.mission_z_level?.z_value : null
		if(teleporter_status != TELEPORTER_ARRAY_INOPERABLE)
			teleporter_status = TELEPORTER_ARRAY_INACTIVE
	interaction_actions = list()
	interaction_actions += new /datum/action/innate/set_teleport_target(src)
	interaction_actions += new /datum/action/innate/activate_teleporter(src)
	RegisterSignals(SSdcs, list(COMSIG_GLOB_CAMPAIGN_MISSION_LOADED, COMSIG_GLOB_CAMPAIGN_MISSION_ENDED), PROC_REF(change_targeted_z))
	GLOB.teleporter_arrays += src

/obj/structure/teleporter_array/Destroy()
	target_turf = null
	controller = null
	QDEL_LIST(interaction_actions)
	GLOB.teleporter_arrays -= src
	return ..()

//user stuff is probably placeholder for now
/obj/structure/teleporter_array/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	if(controller)
		return
	controller = user
	RegisterSignal(controller, COMSIG_MOVABLE_MOVED,PROC_REF(remove_user))
	for(var/datum/action/innate/action AS in interaction_actions)
		action.give_action(controller)

///Provides number of charges remaining to the examine message.
/obj/structure/teleporter_array/examine()
	. = ..()
	if(controller)
		. += "The teleporter is currently being aimed by [controller]."
	. += "The teleporter array has [charges] charges remaining."

///Enables the teleporter for us
/obj/structure/teleporter_array/proc/enable_teleporter(forced = FALSE)
	if(!forced && (teleporter_status == TELEPORTER_ARRAY_INOPERABLE))
		return FALSE
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_TELEPORTER_ARRAY_ENABLED, src)
	teleporter_status = TELEPORTER_ARRAY_READY
	return TRUE

///Removes the current controlling mob
/obj/structure/teleporter_array/proc/remove_user()
	if(!controller)
		return
	for(var/datum/action/innate/action AS in interaction_actions)
		action.remove_action(controller)
		UnregisterSignal(controller, COMSIG_MOVABLE_MOVED)
	controller = null

///Updates the z-level this teleporter teleports to
/obj/structure/teleporter_array/proc/change_targeted_z(datum/source, new_z)
	SIGNAL_HANDLER
	remove_user()
	targetted_zlevel = isnum(new_z) ? new_z : null
	target_turf = null
	if(teleporter_status != TELEPORTER_ARRAY_INOPERABLE)
		teleporter_status = TELEPORTER_ARRAY_INACTIVE

//starts the teleportation process
/obj/structure/teleporter_array/proc/activate()
	if(teleporter_status == TELEPORTER_ARRAY_INOPERABLE)
		to_chat(controller, span_warning("The Bluespace drive that powers the Teleporter Array has been destroyed! The Array is no longer functional."))
		return
	if(teleporter_status == TELEPORTER_ARRAY_IN_USE)
		to_chat(controller, span_warning("The Teleporter Array is already running!"))
		return
	if(teleporter_status == TELEPORTER_ARRAY_INACTIVE)
		to_chat(controller, span_warning("The Teleporter Array is not currently available for our use."))
		return
	if(!charges)
		to_chat(controller, span_warning("The Teleporter Array has no charges remaining. Buy and activate more using attrition."))
		return
	if(!target_turf)
		to_chat(controller, span_warning("The Teleporter Array Has no destination set."))
		return

	visible_message(span_danger("Teleporter Array activated. Destination: [target_turf.loc]."))
	var/list/turf/turfs_affected = list()
	var/turf/central_turf = get_turf(src)
	for(var/turf/affected_turf in RANGE_TURFS(range, central_turf))
		turfs_affected += affected_turf
		affected_turf.add_filter("wraith_magic", 2, drop_shadow_filter(color = "#031025aa", size = -10))

	teleporter_status = TELEPORTER_ARRAY_IN_USE
	addtimer(CALLBACK(src, PROC_REF(do_startup)), windup - 1.5 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(do_teleport), turfs_affected, target_turf), windup)
	playsound(src, 'sound/magic/lightning_chargeup.ogg', 75) //tele charge sound
	charges --

///Visual indicators for the teleporter about to fire
/obj/structure/teleporter_array/proc/do_startup()
	new /obj/effect/temp_visual/teleporter_array(get_turf(src))
	visible_message(span_danger("You feel a vibration build in the air as the teleporter array comes to life."))

///does the actual teleport
/obj/structure/teleporter_array/proc/do_teleport(list/turfs_affected, turf/destination)
	if(teleporter_status != TELEPORTER_ARRAY_IN_USE || !destination || destination.z != targetted_zlevel)
		return cleanup(turfs_affected)

	teleporter_status = TELEPORTER_ARRAY_READY
	cleanup(turfs_affected)
	var/list/destination_mobs = cheap_get_living_near(destination, 9)
	for(var/mob/living/victim AS in destination_mobs)
		victim.adjust_stagger(3 SECONDS)
		victim.add_slowdown(3)
		to_chat(victim, span_warning("You feel nauseous as reality warps around you!"))

	playsound(destination, 'sound/magic/lightningbolt.ogg', 75, 0)
	playsound(src, 'sound/magic/lightningbolt.ogg', 75, 0)
	new /obj/effect/temp_visual/teleporter_array(destination)

	var/list/exit_turfs = RANGE_TURFS(range, destination)
	for(var/turf/affected_turf AS in turfs_affected)
		for(var/atom/movable/AM AS in affected_turf)
			if(AM.anchored)
				continue
			AM.forceMove(exit_turfs[1])
			new /obj/effect/temp_visual/blink_drive(AM.loc)
			if(!ismob(AM))
				continue
			to_chat(AM, span_warning("You feel reality warp around you as the teleporter array activates!"))
			if(AM.loc.density)
				var/mob/victim = AM
				victim.emote("gored")
				victim.gib()
		exit_turfs -= exit_turfs[1]

///cleans up teleport effects
/obj/structure/teleporter_array/proc/cleanup(list/turfs_affected)
	for(var/turf/affected_turf AS in turfs_affected)
		affected_turf.remove_filter("wraith_magic")

/datum/action/innate/activate_teleporter
	name = "Activate teleporter array"
	action_icon = 'icons/mob/actions/actions_mecha.dmi'
	action_icon_state = "land"

/datum/action/innate/activate_teleporter/Activate()
	. = ..()
	var/obj/structure/teleporter_array/teleporter = target
	teleporter.activate()

/datum/action/innate/set_teleport_target
	name = "Set teleportation target"
	action_icon = 'icons/mob/actions/actions_mecha.dmi'
	action_icon_state = "mech_zoom_on"
	///Map currently polling the operator for a destination.
	var/atom/movable/screen/minimap/selection_map

/datum/action/innate/set_teleport_target/can_use_action(silent, override_flags, selecting)
	if(selection_map)
		return FALSE
	return ..()

/datum/action/innate/set_teleport_target/Activate()
	. = ..()
	var/obj/structure/teleporter_array/teleporter = target
	var/selected_z = teleporter.targetted_zlevel
	if(!SSminimaps.minimaps_by_z["[selected_z]"]?.hud_image)
		to_chat(owner, span_danger("No active combat zone detected."))
		return
	var/mob/operator = owner
	selection_map = SSminimaps.fetch_minimap_object(selected_z, GLOB.faction_to_minimap_flag[operator.faction])
	operator.client.screen += selection_map
	var/list/polled_coords = selection_map.get_coords_from_click(operator)
	operator.client?.screen -= selection_map
	selection_map = null
	if(!polled_coords || owner != operator || QDELETED(teleporter) || teleporter.targetted_zlevel != selected_z)
		return
	var/turf/chosen_turf = locate(polled_coords[1], polled_coords[2], selected_z)
	if(!chosen_turf || chosen_turf.density || isspaceturf(chosen_turf))
		to_chat(owner, "Invalid location selected")
	else
		teleporter.target_turf = chosen_turf
		to_chat(owner, span_danger("Target location locked in at: [chosen_turf.loc]"))

/datum/action/innate/set_teleport_target/remove_action(mob/M)
	if(selection_map && owner)
		owner.client?.screen -= selection_map
		selection_map.stop_polling[owner] = TRUE
	return ..()
