#define HIDE_NONE 0
#define HIDE_ON_GROUND 1
#define HIDE_ON_SHIP 2

#define SPOTLIGHT_COOLDOWN_DURATION 6 MINUTES
#define SPOTLIGHT_DURATION 2 MINUTES

#define MESSAGE_SINGLE "Message this marine"
#define ASL "Set or un-set as aSL"
#define SWITCH_SQUAD "Switch this marine's squad"

#define MARK_LASE "Mark this lase on minimap"
#define FIRE_LASE "!!FIRE OB!!"

#define ORBITAL_SPOTLIGHT "Shine orbital spotlight"
#define MESSAGE_NEAR "Message all nearby marines"
#define SQUAD_ACTIONS "Open squad actions menu"

#define MESSAGE_SQUAD "Message all marines in a squad"
#define SWITCH_SQUAD_NEAR "Move all nearby marines to a squad"

/// The maximum length we should use for sending messages with stuff like `message_member`,
/// `message_squad` etc.
#define MAX_COMMAND_MESSAGE_LENGTH 200

///Overwatch is on monitor mode
#define OVERWATCH_ON_MONITOR (1<<0)
///Sort squad list by health status
#define OVERWATCH_SORT_BY_HEALTH (1<<1)
///whether or not we show the dead marines in the squad
#define OVERWATCH_HIDE_DEAD (1<<2)
///The overwatch computer is busy doing something
#define OVERWATCH_BUSY (1<<3)

GLOBAL_LIST_EMPTY(active_orbital_beacons)
GLOBAL_LIST_EMPTY(active_laser_targets)
GLOBAL_LIST_EMPTY(active_cas_targets)

/obj/machinery/computer/camera_advanced/overwatch
	name = "Overwatch Console"
	desc = "State of the art machinery for giving orders to a squad. <b>Shift click</b> to send order when watching squads."
	density = FALSE
	icon_state = "overwatch"
	screen_overlay = "overwatch_screen"
	req_access = list(ACCESS_MARINE_BRIDGE)
	networks = list("marine")
	open_prompt = FALSE
	interaction_flags = INTERACT_MACHINE_TGUI
	faction = FACTION_TERRAGOV
	///behavior flags for overwatch
	var/overwatch_flags
	///which z level is ignored when showing marines.
	var/z_hidden = HIDE_NONE
	/// The list of all squads that can be watched
	var/list/watchable_squads
	///Squad being currently overseen
	var/datum/squad/current_squad = null
	///Groundside minimap for overwatch
	var/datum/action/minimap/marine/external/cic_mini
	///Overrides the minimap action minimap and marker flags
	var/map_flags = MINIMAP_FLAG_MARINE
	///overwatch name override
	var/overwatch_title
	///TGUI layout selector: basic, military, or main
	var/console_type = "basic"

/obj/machinery/computer/camera_advanced/overwatch/Initialize(mapload)
	. = ..()
	cic_mini = new(null, map_flags, map_flags)
	GLOB.main_overwatch_consoles += src

/obj/machinery/computer/camera_advanced/overwatch/Destroy()
	QDEL_NULL(cic_mini)
	GLOB.main_overwatch_consoles -= src
	current_squad = null
	return ..()

/obj/machinery/computer/camera_advanced/overwatch/give_actions(mob/living/user)
	. = ..()
	if(cic_mini)
		cic_mini.target = user
		cic_mini.give_action(user)
		actions += cic_mini

/obj/machinery/computer/camera_advanced/overwatch/CreateEye()
	eyeobj = new(null, parent_cameranet, faction)
	eyeobj.origin = src
	RegisterSignal(eyeobj, COMSIG_QDELETING, PROC_REF(clear_eye_ref))
	eyeobj.visible_icon = TRUE
	eyeobj.icon = 'icons/mob/cameramob.dmi'
	eyeobj.icon_state = "generic_camera"
	cic_mini.override_locator(eyeobj)

/obj/machinery/computer/camera_advanced/overwatch/can_interact(mob/user)
	. = ..()
	if(!.)
		return FALSE
	if(!allowed(user))
		return FALSE
	return TRUE

/obj/machinery/computer/camera_advanced/overwatch/ui_interact(mob/user, datum/tgui/ui)
	watchable_squads = SSjob.active_squads[faction]
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "OverwatchConsole", overwatch_title ? "[overwatch_title] Overwatch Console" : name)
		ui.open()

/obj/machinery/computer/camera_advanced/overwatch/ui_data(mob/user)
	. = list()
	.["console_type"] = console_type
	.["operator"] = operator?.name
	.["can_interact"] = (operator == user)
	.["on_monitor"] = !!(overwatch_flags & OVERWATCH_ON_MONITOR)
	.["sort_by_health"] = !!(overwatch_flags & OVERWATCH_SORT_BY_HEALTH)
	.["hide_dead"] = !!(overwatch_flags & OVERWATCH_HIDE_DEAD)
	.["z_hidden"] = z_hidden
	.["ship_map_name"] = SSmapping.configs[SHIP_MAP]?.map_name || "the ship"

	var/list/squad_list = list()
	for(var/datum/squad/squad AS in watchable_squads)
		squad_list += list(list(
			"id" = squad.id,
			"name" = squad.name,
			"color" = squad.color,
			"leader" = squad.squad_leader?.name,
			"leader_ref" = squad.squad_leader ? REF(squad.squad_leader) : null,
			"overwatch_officer" = squad.overwatch_officer?.name,
		))
	.["squads"] = squad_list

	if(current_squad)
		.["current_squad"] = list(
			"id" = current_squad.id,
			"name" = current_squad.name,
			"color" = current_squad.color,
			"leader" = current_squad.squad_leader?.name,
			"leader_ref" = current_squad.squad_leader ? REF(current_squad.squad_leader) : null,
			"overwatch_officer" = current_squad.overwatch_officer?.name,
			"primary_objective" = current_squad.primary_objective,
			"secondary_objective" = current_squad.secondary_objective,
		)
		.["monitor"] = get_squad_monitor_data()
	else
		.["current_squad"] = null
		.["monitor"] = null

/obj/machinery/computer/camera_advanced/overwatch/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/user = ui.user

	switch(action)
		if("claim")
			if(operator && operator != user)
				return FALSE
			if(console_type == "main")
				operator = user
				var/obj/item/card/id/id_card = operator.get_idcard()
				var/rank_text = id_card ? "[id_card.rank] " : ""
				if(issilicon(operator))
					to_chat(operator, span_boldnotice("Main overwatch systems initialized. Welcome, [rank_text][operator.name]."))
				visible_message(span_boldnotice("Main overwatch systems initialized. Welcome, [rank_text][operator.name]."))
			else
				if(current_squad)
					current_squad.overwatch_officer = user
				operator = user
				var/obj/item/card/id/id_card = operator.get_idcard()
				var/rank_text = id_card ? "[id_card.rank] " : ""
				if(issilicon(operator))
					to_chat(operator, span_boldnotice("Basic overwatch systems initialized. Welcome, [rank_text][operator.name]. Please select a squad."))
				visible_message(span_boldnotice("Basic overwatch systems initialized. Welcome, [rank_text][operator.name]. Please select a squad."))
			. = TRUE

		if("logout")
			if(operator != user && !isAI(user))
				return FALSE
			do_logout()
			. = TRUE

		if("pick_squad")
			if(operator != user)
				return FALSE
			if(current_squad)
				to_chat(operator, span_warning("[icon2html(src, operator)] You are already selecting a squad."))
				return FALSE
			var/selected_id = params["squad_id"]
			var/datum/squad/selected
			for(var/datum/squad/squad AS in watchable_squads)
				if("[squad.id]" == "[selected_id]")
					selected = squad
					break
			if(!selected)
				return FALSE
			selected.overwatch_officer = operator
			current_squad = selected
			if(issilicon(operator))
				to_chat(operator, span_boldnotice("Tactical data for squad '[current_squad]' loaded. All tactical functions initialized."))
			visible_message(span_boldnotice("Tactical data for squad '[current_squad]' loaded. All tactical functions initialized."))
			. = TRUE

		if("monitor")
			if(operator != user)
				return FALSE
			overwatch_flags |= OVERWATCH_ON_MONITOR
			if(params["squad_id"])
				var/new_squad_id = params["squad_id"]
				current_squad = null
				for(var/datum/squad/squad AS in watchable_squads)
					if("[squad.id]" == "[new_squad_id]")
						current_squad = squad
						break
			. = TRUE

		if("back")
			if(operator != user)
				return FALSE
			overwatch_flags &= ~OVERWATCH_ON_MONITOR
			if(console_type != "basic")
				current_squad = null
			. = TRUE

		if("toggle_sort")
			if(operator != user)
				return FALSE
			overwatch_flags ^= OVERWATCH_SORT_BY_HEALTH
			if(overwatch_flags & OVERWATCH_SORT_BY_HEALTH)
				to_chat(operator, "[icon2html(src, operator)] [span_notice("Marines are now sorted by health status.")]")
			else
				to_chat(operator, "[icon2html(src, operator)] [span_notice("Marines are now sorted by rank.")]")
			. = TRUE

		if("toggle_dead")
			if(operator != user)
				return FALSE
			overwatch_flags ^= OVERWATCH_HIDE_DEAD
			if(overwatch_flags & OVERWATCH_HIDE_DEAD)
				to_chat(operator, "[icon2html(src, operator)] [span_notice("Dead marines are no longer shown.")]")
			else
				to_chat(operator, "[icon2html(src, operator)] [span_notice("Dead marines are now shown.")]")
			. = TRUE

		if("cycle_z")
			if(operator != user)
				return FALSE
			switch(z_hidden)
				if(HIDE_NONE)
					z_hidden = HIDE_ON_SHIP
					to_chat(operator, "[icon2html(src, operator)] [span_notice("Marines on the [SSmapping.configs[SHIP_MAP].map_name] are now hidden.")]")
				if(HIDE_ON_SHIP)
					z_hidden = HIDE_ON_GROUND
					to_chat(operator, "[icon2html(src, operator)] [span_notice("Marines on the ground are now hidden.")]")
				if(HIDE_ON_GROUND)
					z_hidden = HIDE_NONE
					to_chat(operator, "[icon2html(src, operator)] [span_notice("No location is ignored anymore.")]")
			. = TRUE

		if("jump")
			if(operator != user && !isAI(user))
				return FALSE
			var/atom/cam_target = locate(params["target"])
			jump_to_target(cam_target)
			. = TRUE

///Logs the operator out of overwatch
/obj/machinery/computer/camera_advanced/overwatch/proc/do_logout()
	if(operator)
		var/obj/item/card/id/id_card = operator.get_idcard()
		var/rank_text = id_card ? "[id_card.rank] " : ""
		if(issilicon(operator))
			to_chat(operator, span_boldnotice("Overwatch systems deactivated. Goodbye, [rank_text][operator ? "[operator.name]":"sysadmin"]."))
		visible_message(span_boldnotice("Overwatch systems deactivated. Goodbye, [rank_text][operator ? "[operator.name]":"sysadmin"]."))
	if(current_squad)
		current_squad.overwatch_officer = null
	operator = null
	current_squad = null
	overwatch_flags &= ~OVERWATCH_ON_MONITOR

///Jumps the overwatch camera / AI eye to a target
/obj/machinery/computer/camera_advanced/overwatch/proc/jump_to_target(atom/cam_target)
	if(!cam_target)
		return
	var/turf/cam_target_turf = get_turf(cam_target)
	if(!cam_target_turf)
		return
	if(!isAI(operator))
		open_prompt(operator)
		eyeobj.setLoc(cam_target_turf)
		if(isliving(cam_target))
			track(cam_target)
		else
			to_chat(operator, "[icon2html(src, operator)] [span_notice("Jumping to the latest available location of [cam_target].")]")
	else
		to_chat(operator, "[icon2html(src, operator)] [span_notice("Jumping to the latest available location of [cam_target].")]")
		var/turf/target_turf = get_turf(cam_target)
		if(target_turf)
			var/mob/living/silicon/ai/recipientai = operator
			recipientai.eyeobj.setLoc(target_turf)

///Builds structured squad monitor payload for TGUI
/obj/machinery/computer/camera_advanced/overwatch/proc/get_squad_monitor_data()
	. = list()
	if(!current_squad)
		return

	var/list/marines = list()
	var/leader_count = 0
	var/medic_count = 0
	var/engi_count = 0
	var/smart_count = 0
	var/spec_count = 0
	var/marine_count = 0
	var/living_count = 0
	var/SL_z
	if(current_squad.squad_leader)
		var/turf/SL_turf = get_turf(current_squad.squad_leader)
		SL_z = SL_turf?.z

	for(var/mob/living/carbon/human/marine in current_squad.get_all_members())
		var/turf/marine_turf = get_turf(marine)
		switch(z_hidden)
			if(HIDE_ON_GROUND)
				if(is_ground_level(marine_turf?.z))
					continue
			if(HIDE_ON_SHIP)
				if(is_mainship_level(marine_turf?.z))
					continue

		if(marine.stat == DEAD && (overwatch_flags & OVERWATCH_HIDE_DEAD))
			continue

		var/role = "unknown"
		if(marine.job)
			role = marine.job.title
		else if(istype(marine.wear_id, /obj/item/card/id))
			var/obj/item/card/id/id_card = marine.wear_id
			role = id_card.rank

		var/acting_sl = FALSE
		var/dist = "???"
		if(current_squad.squad_leader)
			if(marine == current_squad.squad_leader)
				dist = "N/A"
				if(!ismarineleaderjob(marine.job))
					acting_sl = TRUE
			else if(marine_turf && SL_z && marine_turf.z == SL_z)
				dist = "[get_dist(marine, current_squad.squad_leader)] ([dir2text_short(get_dir(current_squad.squad_leader, marine))])"

		var/mob_state = "Conscious"
		var/sort_priority = 0
		switch(marine.stat)
			if(CONSCIOUS)
				mob_state = "Conscious"
				living_count++
				sort_priority = 0
			if(UNCONSCIOUS)
				mob_state = "Unconscious"
				living_count++
				sort_priority = 1
			if(DEAD)
				mob_state = "DEAD"
				sort_priority = 2

		if((!marine.key || !marine.client) && marine.stat != DEAD)
			mob_state += " (SSD)"

		var/fireteam = ""
		var/obj/item/card/id/wear_id = marine.wear_id
		if(wear_id?.assigned_fireteam)
			fireteam = wear_id.assigned_fireteam

		var/area/marine_area = get_area(marine)
		var/area_name = marine_area ? sanitize(marine_area.name) : "???"

		var/role_rank = 5
		switch(role)
			if(SQUAD_LEADER)
				leader_count++
				role_rank = 0
			if(SQUAD_CORPSMAN)
				medic_count++
				role_rank = 1
			if(SQUAD_ENGINEER)
				engi_count++
				role_rank = 2
			if(SQUAD_SMARTGUNNER)
				smart_count++
				role_rank = 3
			if(SQUAD_SPECIALIST)
				spec_count++
				role_rank = 3
			if(SQUAD_MARINE)
				marine_count++
				role_rank = 4

		marines += list(list(
			"ref" = REF(marine),
			"name" = marine.real_name,
			"role" = role,
			"acting_sl" = acting_sl,
			"fireteam" = fireteam,
			"state" = mob_state,
			"area" = area_name,
			"distance" = dist,
			"is_dead" = (marine.stat == DEAD),
			"is_leader" = (marine == current_squad.squad_leader),
			"sort_health" = sort_priority,
			"sort_rank" = role_rank,
		))

	.["marines"] = marines
	.["leader_count"] = leader_count
	.["medic_count"] = medic_count
	.["engi_count"] = engi_count
	.["smart_count"] = smart_count
	.["spec_count"] = spec_count
	.["marine_count"] = marine_count
	.["living_count"] = living_count
	.["total_deployed"] = current_squad.get_total_members()
	.["smart_label"] = (faction == FACTION_SOM) ? "Squad Veterans" : "Squad Smartgunners"
	.["primary_objective"] = current_squad.primary_objective
	.["secondary_objective"] = current_squad.secondary_objective
	.["overwatch_officer"] = current_squad.overwatch_officer?.name

//This is an effect to be sure it is properly deleted and it does not interfer with existing lights too much.
/obj/effect/overwatch_light
	name = "overwatch beam of light"
	desc = "You are not supposed to see this. Please report it."
	icon_state = "" //No sprite
	invisibility = INVISIBILITY_MAXIMUM
	resistance_flags = RESIST_ALL
	light_system = STATIC_LIGHT
	light_color = COLOR_TESLA_BLUE
	light_range = 15	//This is a HUGE light.
	light_power = SQRTWO

/obj/effect/overwatch_light/Initialize(mapload)
	. = ..()
	set_light(light_range, light_power)
	playsound(src,'sound/mecha/heavylightswitch.ogg', 25, 1, 20)
	visible_message(span_warning("You see a twinkle in the sky before your surroundings are hit with a beam of light!"))
	QDEL_IN(src, SPOTLIGHT_DURATION)
