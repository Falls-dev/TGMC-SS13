#define TIME_TO_TRANSFORM 1 SECONDS

/mob/living/carbon/xenomorph/hivemind
	caste_base_type =/datum/xeno_caste/hivemind
	name = "Hivemind"
	real_name = "Hivemind"
	desc = "A glorious singular entity."

	icon_state = "hivemind_marker"
	bubble_icon = "alienroyal"
	icon = 'icons/Xeno/castes/hivemind/basic.dmi'
	effects_icon = 'icons/Xeno/castes/hivemind/effects.dmi'
	status_flags = GODMODE | INCORPOREAL
	resistance_flags = RESIST_ALL
	density = FALSE
	a_intent = INTENT_HELP
	health = 1000
	maxHealth = 1000
	plasma_stored = 5
	tier = XENO_TIER_ZERO
	upgrade = XENO_UPGRADE_BASETYPE

	see_invisible = SEE_INVISIBLE_LIVING
	invisibility = INVISIBILITY_MAXIMUM
	sight = SEE_MOBS|SEE_TURFS|SEE_OBJS
	move_on_shuttle = TRUE
	initial_language_holder = /datum/language_holder/hivemind

	hud_type = /datum/hud/hivemind
	hud_possible = list(PLASMA_HUD, HEALTH_HUD_XENO, PHEROMONE_HUD, XENO_RANK_HUD, QUEEN_OVERWATCH_HUD, XENO_BLESSING_HUD, XENO_EVASION_HUD)
	///The core of our hivemind
	var/datum/weakref/core
	///The minimum health we can have
	var/minimum_health = -300
	///pass_flags given when going incorporeal
	var/incorporeal_pass_flags = PASS_LOW_STRUCTURE|PASS_THROW|PASS_PROJECTILE|PASS_AIR|PASS_FIRE
	///pass_flags given when manifested
	var/manifest_pass_flags = PASS_LOW_STRUCTURE|PASS_MOB|PASS_XENO
	/// Whether direct RTS selection/commands are currently enabled.
	var/rts_mode_active = FALSE
	/// Currently selected AI minions.
	var/list/mob/living/carbon/xenomorph/selected_minions = list()
	/// Client-only outline overlays, keyed by minion.
	var/list/selection_images = list()
	/// Five groups containing weak references so removed mobs are not retained.
	var/list/list/control_groups = list(list(), list(), list(), list(), list())
	/// Currently active control group. Zero means a free-form selection.
	var/active_control_group = 0
	/// Prevent group membership from changing while restoring a saved group.
	var/suspend_group_selection_sync = FALSE
	/// World-time of the last group selection for double-tap camera centering.
	var/list/last_group_select_time = list(0, 0, 0, 0, 0)
	/// Current RTS group buttons.
	var/list/rts_group_buttons = list()
	/// Current RTS unit cards.
	var/list/atom/movable/screen/hivemind_rts_unit_card/rts_unit_cards = list()
	/// Drag-selection state.
	var/turf/rts_drag_start_turf
	var/rts_drag_start_screen_x = 0
	var/rts_drag_start_screen_y = 0
	var/rts_drag_active = FALSE
	var/rts_drag_additive = FALSE
	/// Visible drag-selection box, rendered on the client's HUD plane.
	var/atom/movable/screen/hivemind_rts_drag_box/rts_drag_fill
	var/atom/movable/screen/hivemind_rts_drag_box/rts_drag_border_top
	var/atom/movable/screen/hivemind_rts_drag_box/rts_drag_border_bottom
	var/atom/movable/screen/hivemind_rts_drag_box/rts_drag_border_left
	var/atom/movable/screen/hivemind_rts_drag_box/rts_drag_border_right

/mob/living/carbon/xenomorph/hivemind/Initialize(mapload)
	var/obj/structure/xeno/hivemindcore/new_core = new /obj/structure/xeno/hivemindcore(loc, hivenumber)
	core = WEAKREF(new_core)
	. = ..()
	new_core.parent = WEAKREF(src)
	RegisterSignal(src, COMSIG_XENOMORPH_CORE_RETURN, PROC_REF(return_to_core))
	RegisterSignal(src, COMSIG_XENOMORPH_HIVEMIND_CHANGE_FORM, PROC_REF(change_form))
	RegisterSignal(src, COMSIG_MOB_MOUSEDOWN, PROC_REF(on_rts_mousedown))
	RegisterSignal(src, COMSIG_MOB_MOUSEDRAG, PROC_REF(on_rts_mousedrag))
	RegisterSignal(src, COMSIG_MOB_MOUSEUP, PROC_REF(on_rts_mouseup))
	RegisterSignal(src, COMSIG_MOB_HUD_REFRESHED, PROC_REF(on_rts_hud_refreshed))
	RegisterSignal(src, COMSIG_XENOABILITY_CONTROL_GROUP_1, PROC_REF(on_kb_select_group_1))
	RegisterSignal(src, COMSIG_XENOABILITY_CREATE_GROUP_1, PROC_REF(on_kb_create_group_1))
	RegisterSignal(src, COMSIG_XENOABILITY_ADD_GROUP_1, PROC_REF(on_kb_add_group_1))
	RegisterSignal(src, COMSIG_XENOABILITY_CONTROL_GROUP_2, PROC_REF(on_kb_select_group_2))
	RegisterSignal(src, COMSIG_XENOABILITY_CREATE_GROUP_2, PROC_REF(on_kb_create_group_2))
	RegisterSignal(src, COMSIG_XENOABILITY_ADD_GROUP_2, PROC_REF(on_kb_add_group_2))
	RegisterSignal(src, COMSIG_XENOABILITY_CONTROL_GROUP_3, PROC_REF(on_kb_select_group_3))
	RegisterSignal(src, COMSIG_XENOABILITY_CREATE_GROUP_3, PROC_REF(on_kb_create_group_3))
	RegisterSignal(src, COMSIG_XENOABILITY_ADD_GROUP_3, PROC_REF(on_kb_add_group_3))
	RegisterSignal(src, COMSIG_XENOABILITY_CONTROL_GROUP_4, PROC_REF(on_kb_select_group_4))
	RegisterSignal(src, COMSIG_XENOABILITY_CREATE_GROUP_4, PROC_REF(on_kb_create_group_4))
	RegisterSignal(src, COMSIG_XENOABILITY_ADD_GROUP_4, PROC_REF(on_kb_add_group_4))
	RegisterSignal(src, COMSIG_XENOABILITY_CONTROL_GROUP_5, PROC_REF(on_kb_select_group_5))
	RegisterSignal(src, COMSIG_XENOABILITY_CREATE_GROUP_5, PROC_REF(on_kb_create_group_5))
	RegisterSignal(src, COMSIG_XENOABILITY_ADD_GROUP_5, PROC_REF(on_kb_add_group_5))
	add_pass_flags(incorporeal_pass_flags, INNATE_TRAIT)
	update_action_buttons()

/mob/living/carbon/xenomorph/hivemind/get_evolution_options()
	return

/mob/living/carbon/xenomorph/hivemind/upgrade_possible()
	return FALSE

/mob/living/carbon/xenomorph/hivemind/upgrade_xeno(newlevel, silent = FALSE)
	newlevel = XENO_UPGRADE_BASETYPE
	return ..()

/mob/living/carbon/xenomorph/hivemind/update_health()
	if(on_fire)
		ExtinguishMob()
	health = maxHealth - get_fire_loss() - get_brute_loss() //Xenos can only take brute and fire damage.
	if(health <= 0 && !(status_flags & INCORPOREAL))
		set_brute_loss(0)
		set_fire_loss(-minimum_health)
		change_form()
		remove_status_effect(/datum/status_effect/spacefreeze)
	health = maxHealth - get_fire_loss() - get_brute_loss()
	med_hud_set_health()
	if(TIMER_COOLDOWN_RUNNING(src, COOLDOWN_HIVEMIND_MANIFESTATION))
		return
	update_wounds()
	handle_regular_hud_updates()

/mob/living/carbon/xenomorph/hivemind/handle_living_health_updates()
	if(TIMER_COOLDOWN_RUNNING(src, COOLDOWN_HIVEMIND_MANIFESTATION))
		return
	var/turf/T = loc
	if(!istype(T))
		return
	// If manifested and off weeds, lets deal some damage.
	if(!(status_flags & INCORPOREAL) && !loc_weeds_type)
		adjust_brute_loss(20 * XENO_RESTING_HEAL, TRUE)
		return
	// If not manifested
	if(health < minimum_health + maxHealth)
		set_brute_loss(0)
		set_fire_loss(-minimum_health)
	if(health >= maxHealth) //can't regenerate.
		update_health() //Update health-related stats, like health itself (using brute and fireloss), health HUD and status.
		return
	heal_wounds(XENO_RESTING_HEAL)
	update_health()

/mob/living/carbon/xenomorph/hivemind/Login()
	. = ..()
	if(client)
		for(var/mob/living/carbon/xenomorph/minion in selected_minions)
			var/image/selection = selection_images[minion]
			if(selection)
				client.images += selection
		update_rts_hud()

/mob/living/carbon/xenomorph/hivemind/Logout()
	clear_rts_drag_state()
	if(client)
		save_active_control_group()
		for(var/mob/living/carbon/xenomorph/minion in selected_minions)
			var/image/selection = selection_images[minion]
			if(selection)
				client.images -= selection
		for(var/atom/movable/screen/hivemind_rts_unit_card/card in rts_unit_cards)
			client.screen -= card
		for(var/atom/movable/screen/screen_object in rts_group_buttons)
			client.screen -= screen_object
	return ..()

/mob/living/carbon/xenomorph/hivemind/Destroy()
	clear_rts_drag_state()
	clear_minion_selection()
	clear_rts_hud()
	var/obj/structure/xeno/hivemindcore/hive_core = get_core()
	if(hive_core)
		qdel(hive_core)
	return ..()

/mob/living/carbon/xenomorph/hivemind/on_death()
	var/obj/structure/xeno/hivemindcore/hive_core = get_core()
	if(!QDELETED(hive_core))
		qdel(hive_core)
	return ..()

/mob/living/carbon/xenomorph/hivemind/gib()
	return_to_core()

/mob/living/carbon/xenomorph/hivemind/set_resting()
	return

/mob/living/carbon/xenomorph/hivemind/change_form()
	if(status_flags & INCORPOREAL && health != maxHealth)
		to_chat(src, span_xenowarning("You do not have the strength to manifest yet!"))
		return
	if(TIMER_COOLDOWN_RUNNING(src, COOLDOWN_HIVEMIND_MANIFESTATION))
		return
	wound_overlay.icon_state = "none"
	TIMER_COOLDOWN_START(src, COOLDOWN_HIVEMIND_MANIFESTATION, TIME_TO_TRANSFORM)
	invisibility = 0
	flick(status_flags & INCORPOREAL ? "Hivemind_[initial(loc_weeds_type.color_variant)]_materialisation" : "Hivemind_[initial(loc_weeds_type.color_variant)]_materialisation_reverse", src)
	setDir(SOUTH)
	addtimer(CALLBACK(src, PROC_REF(do_change_form)), TIME_TO_TRANSFORM)

/mob/living/carbon/xenomorph/hivemind/set_jump_component(duration = 0.5 SECONDS, cooldown = 2 SECONDS, cost = 0, height = 16, sound = null, flags = JUMP_SHADOW, jump_pass_flags = PASS_LOW_STRUCTURE|PASS_FIRE|PASS_TANK)
	return //no jumping, bad hivemind

///Finish the form changing of the hivemind and give the needed stats
/mob/living/carbon/xenomorph/hivemind/proc/do_change_form()
	LAZYCLEARLIST(movespeed_modification)
	update_movespeed()
	if(status_flags & INCORPOREAL)
		status_flags = NONE
		resistance_flags = NONE
		remove_pass_flags(incorporeal_pass_flags, INNATE_TRAIT)
		add_pass_flags(manifest_pass_flags, MANIFESTED_TRAIT)
		density = TRUE
		hive.xenos_by_upgrade[upgrade] -= src
		upgrade = XENO_UPGRADE_MANIFESTATION
		set_datum(FALSE)
		hive.xenos_by_upgrade[upgrade] += src
		update_wounds()
		update_icon()
		update_action_buttons()
		return
	status_flags = initial(status_flags)
	resistance_flags = initial(resistance_flags)
	remove_pass_flags(manifest_pass_flags, MANIFESTED_TRAIT)
	add_pass_flags(incorporeal_pass_flags, INNATE_TRAIT)
	density = FALSE
	hive.xenos_by_upgrade[upgrade] -= src
	upgrade = XENO_UPGRADE_BASETYPE
	set_datum(FALSE)
	hive.xenos_by_upgrade[upgrade] += src
	setDir(SOUTH)
	update_wounds()
	update_icon()
	update_action_buttons()
	handle_weeds_adjacent_removed()

/mob/living/carbon/xenomorph/hivemind/fire_act(burn_level, flame_color)
	return_to_core()
	to_chat(src, span_xenonotice("We were on top of fire, we got moved to our core."))

/mob/living/carbon/xenomorph/hivemind/handle_weeds_adjacent_removed()
	if(loc_weeds_type || check_weeds(get_turf(src)))
		return
	return_to_core()
	to_chat(src, span_xenonotice("We had no weeds nearby, we got moved to our core."))
	return

/mob/living/carbon/xenomorph/hivemind/proc/return_to_core()
	if(!(status_flags & INCORPOREAL) && TIMER_COOLDOWN_FINISHED(src, COOLDOWN_HIVEMIND_MANIFESTATION))
		do_change_form()
	for(var/obj/item/explosive/grenade/sticky/sticky_bomb in contents)
		sticky_bomb.clean_refs()
		sticky_bomb.forceMove(loc)
	forceMove(get_turf(get_core()))

///Start the teleportation process to send the hivemind manifestation to the selected turf
/mob/living/carbon/xenomorph/hivemind/proc/start_teleport(turf/T)
	if(!isopenturf(T))
		balloon_alert(src, "Can't teleport into a wall")
		return
	TIMER_COOLDOWN_START(src, COOLDOWN_HIVEMIND_MANIFESTATION, TIME_TO_TRANSFORM * 2)
	flick("Hivemind_[initial(loc_weeds_type.color_variant)]_materialisation_reverse", src)
	setDir(SOUTH)
	addtimer(CALLBACK(src, PROC_REF(end_teleport), T), TIME_TO_TRANSFORM)

///Finish the teleportation process to send the hivemind manifestation to the selected turf
/mob/living/carbon/xenomorph/hivemind/proc/end_teleport(turf/T)
	if(!check_weeds(T, TRUE))
		balloon_alert(src, "No weeds in destination")
		return
	forceMove(T)
	flick("Hivemind_[initial(loc_weeds_type.color_variant)]_materialisation", src)
	setDir(SOUTH)

/mob/living/carbon/xenomorph/hivemind/Move(atom/newloc, direction, glide_size_override)
	if(TIMER_COOLDOWN_RUNNING(src, COOLDOWN_HIVEMIND_MANIFESTATION))
		return
	if(!(status_flags & INCORPOREAL))
		return ..()
	if(!check_weeds(newloc))
		return FALSE

	// FIXME: Port canpass refactor from tg
	// Don't allow them over the timed_late doors
	var/obj/machinery/door/poddoor/timed_late/door = locate() in newloc
	if(door && !door.CanPass(src, newloc))
		return FALSE

	abstract_move(newloc)

/mob/living/carbon/xenomorph/hivemind/receive_hivemind_message(mob/living/carbon/xenomorph/speaker, message)
	var/track = "<a href='byond://?src=[REF(src)];hivemind_jump=[REF(speaker)]'>(F)</a>"
	return show_message("[track] [speaker.hivemind_start()] [span_message("hisses, '[message]'")][speaker.hivemind_end()]", 2)

/mob/living/carbon/xenomorph/hivemind/Topic(href, href_list)
	. = ..()
	if(.)
		return
	if(TIMER_COOLDOWN_RUNNING(src, COOLDOWN_HIVEMIND_MANIFESTATION))
		return
	if(href_list["hivemind_jump"])
		var/mob/living/carbon/xenomorph/xeno = locate(href_list["hivemind_jump"])
		if(!istype(xeno))
			return
		jump(xeno)

/// Jump hivemind's camera to the passed xeno, if they are on/near weeds
/mob/living/carbon/xenomorph/hivemind/proc/jump(mob/living/carbon/xenomorph/xeno)
	if(!check_weeds(get_turf(xeno), TRUE))
		balloon_alert(src, "No nearby weeds")
		return
	if(!(status_flags & INCORPOREAL))
		start_teleport(get_turf(xeno))
		return
	abstract_move(get_turf(xeno))

/// handles hivemind updating with their respective weedtype
/mob/living/carbon/xenomorph/hivemind/update_icon_state()
	. = ..()
	if(status_flags & INCORPOREAL)
		icon_state = "hivemind_marker"
		return
	icon_state = "Hivemind_[initial(loc_weeds_type.color_variant)]"

/mob/living/carbon/xenomorph/hivemind/update_icons()
	return

/mob/living/carbon/xenomorph/hivemind/ClickOn(atom/A, location, params)
	if(!rts_mode_active)
		return ..()
	var/list/modifiers = params2list(params)
	if(modifiers["middle"] || modifiers["ctrl"] || modifiers["alt"])
		return ..()
	A = rts_resolve_click_target(A, params)
	if(!A)
		return
	if(modifiers["right"])
		issue_rts_order(A)
		return
	var/additive = !!modifiers["shift"]
	if(isxeno(A) && A != src)
		var/mob/living/carbon/xenomorph/clicked = A
		if(additive && (clicked in selected_minions))
			deselect_minion(clicked)
			return
		if(!additive)
			clear_minion_selection()
		select_minion(clicked, FALSE)
		return
	if(!additive)
		clear_minion_selection()

/mob/living/carbon/xenomorph/hivemind/DblClickOn(atom/A, params)
	if(rts_mode_active)
		return
	if(TIMER_COOLDOWN_RUNNING(src, COOLDOWN_HIVEMIND_MANIFESTATION))
		return
	var/list/modifiers = params2list(params)
	if(modifiers["right"])
		return
	var/turf/target_turf = get_turf(A)
	if(!check_weeds(target_turf, TRUE))
		return
	if(!(status_flags & INCORPOREAL))
		start_teleport(target_turf)
		return
	setDir(SOUTH)
	abstract_move(target_turf)

/mob/living/carbon/xenomorph/hivemind/CtrlClick(mob/user)
	if(!(status_flags & INCORPOREAL))
		return ..()
	return FALSE

/mob/living/carbon/xenomorph/hivemind/CtrlShiftClickOn(atom/A)
	if(!(status_flags & INCORPOREAL))
		return ..()
	return FALSE

/mob/living/carbon/xenomorph/hivemind/a_intent_change()
	return //Unable to change intent, forced help intent

/mob/living/carbon/xenomorph/hivemind/update_progression()
	return


/obj/structure/xeno/spawner/melee
	name = "melee minion spawner"
	desc = "Produces Mantis, Beetle, and Baneling assault minions."
	spawn_interval = HIVEMIND_MINION_MELEE_SPAWN_INTERVAL

/obj/structure/xeno/spawner/melee/Initialize(mapload, _hivenumber)
	minion_spawn_types = list(
		/mob/living/carbon/xenomorph/mantis/ai = HIVEMIND_MINION_MANTIS_SPAWN_WEIGHT,
		/mob/living/carbon/xenomorph/beetle/ai = HIVEMIND_MINION_DEFAULT_SPAWN_WEIGHT,
		/mob/living/carbon/xenomorph/baneling/ai = HIVEMIND_MINION_DEFAULT_SPAWN_WEIGHT,
	)
	. = ..()

/obj/structure/xeno/spawner/ranged
	name = "ranged minion spawner"
	desc = "Produces Scorpion acid-support minions."
	spawn_interval = HIVEMIND_MINION_RANGED_SPAWN_INTERVAL
	max_active_minions = HIVEMIND_MINION_RANGED_SPAWNER_CAP

/obj/structure/xeno/spawner/ranged/Initialize(mapload, _hivenumber)
	minion_spawn_types = list(/mob/living/carbon/xenomorph/scorpion/ai = HIVEMIND_MINION_DEFAULT_SPAWN_WEIGHT)
	. = ..()

/obj/structure/xeno/spawner/builder
	name = "builder minion spawner"
	desc = "Produces Nymph construction minions."
	spawn_interval = HIVEMIND_MINION_BUILDER_SPAWN_INTERVAL
	max_active_minions = HIVEMIND_MINION_BUILDER_SPAWNER_CAP

/obj/structure/xeno/spawner/builder/Initialize(mapload, _hivenumber)
	minion_spawn_types = list(/mob/living/carbon/xenomorph/nymph/ai = HIVEMIND_MINION_DEFAULT_SPAWN_WEIGHT)
	. = ..()

/obj/fire/flamer/CanAllowThrough(atom/movable/mover, turf/target)
	if(isxenohivemind(mover))
		return FALSE
	return ..()

/// Getter proc for the weakref'd core
/mob/living/carbon/xenomorph/hivemind/proc/get_core()
	return core?.resolve()


/atom/movable/screen/hivemind_rts_drag_box
	name = "RTS selection box"
	icon = 'icons/effects/alphacolors.dmi'
	icon_state = "white"
	plane = ABOVE_HUD_PLANE
	layer = 120
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = APPEARANCE_UI

// ==========================================
// Hivemind RTS selection and command logic
// ==========================================

/mob/living/carbon/xenomorph/hivemind/proc/is_rts_active()
	return rts_mode_active

/mob/living/carbon/xenomorph/hivemind/proc/ensure_rts_active()
	set_rts_mode(TRUE)

/// RTS mode is independent from selected_ability, so switching abilities never drops selection or HUD.
/mob/living/carbon/xenomorph/hivemind/proc/set_rts_mode(enabled)
	if(rts_mode_active == enabled)
		return
	rts_mode_active = enabled
	var/datum/action/ability/xeno_action/rts_minion_control/rts_action = locate() in actions
	rts_action?.set_toggle(enabled)
	if(!enabled)
		clear_rts_drag_state()
		save_active_control_group()
		suspend_group_selection_sync = TRUE
		clear_minion_selection()
		suspend_group_selection_sync = FALSE
		active_control_group = 0
	update_rts_hud()
	balloon_alert(src, enabled ? "RTS-режим включён" : "RTS-режим выключен")

/// Dark tiles are clicked through the clickcatcher; resolve it to the real turf.
/mob/living/carbon/xenomorph/hivemind/proc/rts_resolve_click_target(atom/A, params)
	if(!A)
		return null
	return get_turf_on_clickcatcher(A, src, params)

/// Controllable minions currently visible to the client's camera.
/mob/living/carbon/xenomorph/hivemind/proc/get_minions_in_view()
	var/list/result = list()
	var/atom/viewer = client && client.eye ? client.eye : src
	var/view_size = client ? client.view : world.view
	for(var/mob/living/carbon/xenomorph/minion in view(view_size, viewer))
		if(can_control_minion(minion))
			result += minion
	return result

/// Only AI-controlled minion castes belonging to our hive are eligible.
/mob/living/carbon/xenomorph/hivemind/proc/can_control_minion(mob/living/carbon/xenomorph/target)
	if(!istype(target) || target == src || QDELETED(target) || target.stat == DEAD)
		return FALSE
	if(target.hivenumber != hivenumber || !target.is_hivemind_ai_minion())
		return FALSE
	if(istype(target, /mob/living/carbon/xenomorph/spiderling) || istype(target, /mob/living/carbon/xenomorph/puppet))
		return FALSE

	// Keep AI behavior compatible with the minion's caste even if it was spawned without a controller.
	var/datum/component/ai_controller/controller = target.GetComponent(/datum/component/ai_controller)
	var/desired_ai_type = /datum/ai_behavior/xeno
	if(istype(target, /mob/living/carbon/xenomorph/scorpion) || istype(target, /mob/living/carbon/xenomorph/sentinel) || istype(target, /mob/living/carbon/xenomorph/spitter) || istype(target, /mob/living/carbon/xenomorph/praetorian))
		desired_ai_type = /datum/ai_behavior/xeno/ranged
	else if(istype(target, /mob/living/carbon/xenomorph/baneling) || istype(target, /mob/living/carbon/xenomorph/beetle) || istype(target, /mob/living/carbon/xenomorph/mantis))
		desired_ai_type = /datum/ai_behavior/xeno/suicidal

	if(!controller)
		target.AddComponent(/datum/component/ai_controller, desired_ai_type)
	else if(!istype(controller.ai_behavior, desired_ai_type))
		qdel(controller)
		target.AddComponent(/datum/component/ai_controller, desired_ai_type)
	return TRUE

/mob/living/carbon/xenomorph/hivemind/proc/select_minion(mob/living/carbon/xenomorph/minion, clear_previous = TRUE)
	if(clear_previous)
		clear_minion_selection()
	if(!can_control_minion(minion))
		if(minion && (minion.client || minion.ckey || minion.key || (minion.mind && minion.mind.active)))
			balloon_alert(src, "У этого ксеноморфа есть собственный разум")
		return FALSE
	if(minion in selected_minions)
		return TRUE
	selected_minions += minion
	update_minion_selection_overlay(minion)
	RegisterSignals(minion, list(COMSIG_MOB_DEATH, COMSIG_QDELETING, COMSIG_MOB_LOGIN), PROC_REF(on_selected_minion_lost))
	RegisterSignal(minion, COMSIG_ATOM_DIR_CHANGE, PROC_REF(on_selected_minion_dir_changed))
	RegisterSignal(minion, COMSIG_ATOM_UPDATED_ICON, PROC_REF(on_selected_minion_icon_updated))
	if(active_control_group && !suspend_group_selection_sync)
		save_active_control_group()
	update_rts_hud()
	return TRUE

/mob/living/carbon/xenomorph/hivemind/proc/deselect_minion(mob/living/carbon/xenomorph/minion)
	if(!(minion in selected_minions))
		return
	UnregisterSignal(minion, list(COMSIG_MOB_DEATH, COMSIG_QDELETING, COMSIG_MOB_LOGIN))
	UnregisterSignal(minion, COMSIG_ATOM_DIR_CHANGE)
	UnregisterSignal(minion, COMSIG_ATOM_UPDATED_ICON)
	var/image/selection = selection_images[minion]
	if(client && selection)
		client.images -= selection
	selected_minions -= minion
	selection_images -= minion
	if(active_control_group && !suspend_group_selection_sync)
		save_active_control_group()
	update_rts_hud()

/mob/living/carbon/xenomorph/hivemind/proc/clear_minion_selection()
	for(var/mob/living/carbon/xenomorph/minion in selected_minions.Copy())
		UnregisterSignal(minion, list(COMSIG_MOB_DEATH, COMSIG_QDELETING, COMSIG_MOB_LOGIN))
		UnregisterSignal(minion, COMSIG_ATOM_DIR_CHANGE)
		UnregisterSignal(minion, COMSIG_ATOM_UPDATED_ICON)
		var/image/selection = selection_images[minion]
		if(client && selection)
			client.images -= selection
	selected_minions.Cut()
	selection_images.Cut()
	if(active_control_group && !suspend_group_selection_sync)
		save_active_control_group()
	update_rts_hud()

/mob/living/carbon/xenomorph/hivemind/proc/update_minion_selection_overlay(mob/living/carbon/xenomorph/minion, dir_override = null)
	if(!minion || QDELETED(minion) || !(minion in selected_minions))
		return
	var/image/old_selection = selection_images[minion]
	if(client && old_selection)
		client.images -= old_selection
	var/mutable_appearance/selection_appearance = new /mutable_appearance(minion)
	if(dir_override)
		selection_appearance.dir = dir_override
	selection_appearance.filters += filter(type = "outline", size = 3, color = HIVEMIND_RTS_MINION_SELECTION_COLOR)
	selection_appearance.appearance_flags = RESET_COLOR|RESET_ALPHA|KEEP_APART
	var/image/selection = image(selection_appearance)
	selection.loc = minion
	selection.layer = MOB_LAYER + HIVEMIND_RTS_SELECTION_LAYER_OFFSET
	SET_PLANE_EXPLICIT(selection, GAME_PLANE, minion)
	selection_images[minion] = selection
	if(client)
		client.images += selection

/mob/living/carbon/xenomorph/hivemind/proc/on_selected_minion_dir_changed(mob/living/carbon/xenomorph/minion, old_dir, new_dir)
	SIGNAL_HANDLER
	update_minion_selection_overlay(minion, new_dir)

/mob/living/carbon/xenomorph/hivemind/proc/on_selected_minion_icon_updated(mob/living/carbon/xenomorph/minion, updates, did_anything)
	SIGNAL_HANDLER
	update_minion_selection_overlay(minion)

/mob/living/carbon/xenomorph/hivemind/proc/on_selected_minion_lost(mob/living/carbon/xenomorph/minion)
	SIGNAL_HANDLER
	deselect_minion(minion)

/mob/living/carbon/xenomorph/hivemind/proc/save_active_control_group()
	if(!active_control_group || suspend_group_selection_sync)
		return
	var/list/group = control_groups[active_control_group]
	group.Cut()
	for(var/mob/living/carbon/xenomorph/minion in selected_minions)
		if(can_control_minion(minion))
			group += WEAKREF(minion)

/mob/living/carbon/xenomorph/hivemind/proc/assign_control_group(group_idx)
	if(group_idx < 1 || group_idx > HIVEMIND_RTS_GROUP_COUNT)
		return FALSE
	var/list/group = control_groups[group_idx]
	group.Cut()
	for(var/mob/living/carbon/xenomorph/minion in selected_minions)
		if(can_control_minion(minion))
			group += WEAKREF(minion)
	active_control_group = group_idx
	update_rts_hud()
	balloon_alert(src, length(group) ? "Отряд [group_idx] сохранён ([length(group)])" : "Отряд [group_idx] очищен")
	return TRUE

/mob/living/carbon/xenomorph/hivemind/proc/select_control_group(group_idx, force_jump = FALSE)
	if(group_idx < 1 || group_idx > HIVEMIND_RTS_GROUP_COUNT)
		return FALSE
	ensure_rts_active()
	if(active_control_group && active_control_group != group_idx)
		save_active_control_group()
	var/list/group = control_groups[group_idx]
	var/list/valid_minions = list()
	var/list/stale_refs = list()
	for(var/datum/weakref/ref in group)
		var/mob/living/carbon/xenomorph/minion = ref.resolve()
		if(!can_control_minion(minion))
			stale_refs += ref
		else
			valid_minions += minion
	for(var/datum/weakref/ref in stale_refs)
		group -= ref
	var/is_double_tap = last_group_select_time[group_idx] && (world.time - last_group_select_time[group_idx]) <= HIVEMIND_RTS_DOUBLETAP_WINDOW
	last_group_select_time[group_idx] = world.time
	active_control_group = group_idx
	suspend_group_selection_sync = TRUE
	clear_minion_selection()
	for(var/mob/living/carbon/xenomorph/minion in valid_minions)
		select_minion(minion, FALSE)
	suspend_group_selection_sync = FALSE
	if(is_double_tap || force_jump)
		if(length(valid_minions))
			jump(valid_minions[1])
	if(!length(valid_minions))
		balloon_alert(src, "Отряд [group_idx] пуст")
	update_rts_hud()
	return TRUE

/mob/living/carbon/xenomorph/hivemind/proc/add_to_control_group(group_idx)
	if(group_idx < 1 || group_idx > HIVEMIND_RTS_GROUP_COUNT)
		return
	ensure_rts_active()
	if(active_control_group)
		save_active_control_group()
	active_control_group = 0
	var/list/group = control_groups[group_idx]
	for(var/datum/weakref/ref in group.Copy())
		var/mob/living/carbon/xenomorph/minion = ref.resolve()
		if(!can_control_minion(minion))
			group -= ref
		else
			select_minion(minion, FALSE)
	update_rts_hud()

/mob/living/carbon/xenomorph/hivemind/proc/get_minion_group_number(mob/living/carbon/xenomorph/minion)
	for(var/group_idx in 1 to HIVEMIND_RTS_GROUP_COUNT)
		for(var/datum/weakref/ref in control_groups[group_idx])
			if(ref.resolve() == minion)
				return group_idx
	return 0

/mob/living/carbon/xenomorph/hivemind/proc/get_minion_behavior(mob/living/carbon/xenomorph/minion)
	RETURN_TYPE(/datum/ai_behavior/xeno)
	var/datum/component/ai_controller/controller = minion.GetComponent(/datum/component/ai_controller)
	return controller?.ai_behavior

/// Enemy = living non-hive mob, or a non-hive structure/machine/vehicle.
/mob/living/carbon/xenomorph/hivemind/proc/is_rts_enemy(atom/A)
	if(isliving(A))
		var/mob/living/L = A
		return L.stat != DEAD && L.get_xeno_hivenumber() != hivenumber
	if(istype(A, /obj/structure) || istype(A, /obj/machinery) || istype(A, /obj/vehicle))
		return A.get_xeno_hivenumber() != hivenumber && !istype(A, /obj/structure/xeno/hivemindcore)
	return FALSE

/mob/living/carbon/xenomorph/hivemind/proc/is_rts_friend(atom/A)
	if(istype(A, /obj/structure/xeno/hivemindcore))
		return TRUE
	if(!isxeno(A) || A == src)
		return FALSE
	var/mob/living/carbon/xenomorph/xeno_target = A
	return xeno_target.hivenumber == hivenumber && xeno_target.stat != DEAD

/// Closest free turfs around center, nearest first.
/mob/living/carbon/xenomorph/hivemind/proc/get_rts_formation_turfs(turf/center, count)
	var/list/spots = list()
	for(var/radius in 0 to HIVEMIND_RTS_FORMATION_RADIUS)
		for(var/turf/T in (radius ? orange(radius, center) : list(center)))
			if(radius && get_dist(T, center) != radius)
				continue
			if(T.density || (T.atom_flags & AI_BLOCKED))
				continue
			spots += T
			if(length(spots) >= count)
				return spots
	if(!length(spots))
		spots += center
	return spots

/// Orders apply instantly: ground = formation move, enemy = attack, friendly = guard.
/mob/living/carbon/xenomorph/hivemind/proc/issue_rts_order(atom/target)
	if(!length(selected_minions) || QDELETED(target))
		return FALSE
	var/turf/target_turf = get_turf(target)
	if(!target_turf || target_turf.z != z)
		return FALSE
	var/atom/actual_target = target
	if(isturf(target))
		for(var/mob/living/L in target_turf)
			if(is_rts_enemy(L))
				actual_target = L
				break
		if(actual_target == target)
			for(var/obj/O in target_turf)
				if(is_rts_enemy(O) || is_rts_friend(O))
					actual_target = O
					break
	var/list/units = list()
	for(var/mob/living/carbon/xenomorph/minion in selected_minions.Copy())
		if(!can_control_minion(minion))
			deselect_minion(minion)
			continue
		units += minion
	if(!length(units))
		return FALSE
	if(is_rts_enemy(actual_target))
		for(var/mob/living/carbon/xenomorph/minion in units)
			get_minion_behavior(minion)?.rts_attack(actual_target)
		new /obj/effect/temp_visual/rts_order/attack(target_turf)
		return TRUE
	if(is_rts_friend(actual_target))
		for(var/mob/living/carbon/xenomorph/minion in units)
			if(minion != actual_target)
				get_minion_behavior(minion)?.rts_guard(actual_target, src)
		new /obj/effect/temp_visual/rts_order/escort(target_turf)
		return TRUE
	var/list/remaining = units.Copy()
	for(var/turf/spot in get_rts_formation_turfs(target_turf, length(units)))
		var/mob/living/carbon/xenomorph/best
		var/best_dist = INFINITY
		for(var/mob/living/carbon/xenomorph/minion in remaining)
			var/dist = get_dist(minion, spot)
			if(dist < best_dist)
				best = minion
				best_dist = dist
		if(!best)
			break
		remaining -= best
		get_minion_behavior(best)?.rts_move(spot)
	for(var/mob/living/carbon/xenomorph/minion in remaining)
		get_minion_behavior(minion)?.rts_move(target_turf)
	new /obj/effect/temp_visual/rts_order/move(target_turf)
	return TRUE

/mob/living/carbon/xenomorph/hivemind/proc/stop_minion(mob/living/carbon/xenomorph/minion)
	if(!can_control_minion(minion))
		deselect_minion(minion)
		return
	get_minion_behavior(minion)?.rts_stop()

/mob/living/carbon/xenomorph/hivemind/proc/on_rts_mousedown(mob/source, atom/object, turf/location, control, params)
	SIGNAL_HANDLER
	if(!client || !rts_mode_active)
		return
	var/list/modifiers = params2list(params)
	if(modifiers[BUTTON] != LEFT_CLICK || modifiers["right"] || modifiers["middle"])
		return
	// HUD elements must keep their own clicks; the map click-catcher is selectable.
	if(istype(object, /atom/movable/screen) && !istype(object, /atom/movable/screen/click_catcher))
		return
	if(!modifiers["screen-loc"])
		return
	var/list/start_coords = params2screenpixel(modifiers["screen-loc"])
	if(!start_coords || !length(start_coords))
		return
	rts_drag_start_screen_x = start_coords[1]
	rts_drag_start_screen_y = start_coords[2]
	var/atom/start_target = get_turf_on_clickcatcher(object, src, params)
	if(!start_target)
		start_target = location
	rts_drag_start_turf = get_turf(start_target)
	if(!rts_drag_start_turf && modifiers["screen-loc"])
		var/atom/viewer = client.eye ? client.eye : src
		rts_drag_start_turf = params2turf(modifiers["screen-loc"], get_turf(viewer), client)
	rts_drag_active = FALSE
	rts_drag_additive = !!modifiers["shift"]
	// Show a small visible preview immediately; plain clicks remove it on MouseUp.
	update_rts_drag_box(rts_drag_start_screen_x, rts_drag_start_screen_y, rts_drag_start_screen_x + 2, rts_drag_start_screen_y + 2)

/// Mark a drag only after the cursor has moved far enough to distinguish it from a click.
/mob/living/carbon/xenomorph/hivemind/proc/on_rts_mousedrag(mob/source, atom/src_object, atom/over_object, turf/src_location, turf/over_location, src_control, over_control, params)
	SIGNAL_HANDLER
	if(!client || !rts_mode_active || !rts_drag_start_turf)
		return
	var/list/modifiers = params2list(params)
	if(!modifiers["screen-loc"])
		return
	var/list/current_coords = params2screenpixel(modifiers["screen-loc"])
	if(!current_coords || !length(current_coords))
		return
	if(!rts_drag_active && abs(current_coords[1] - rts_drag_start_screen_x) < 6 && abs(current_coords[2] - rts_drag_start_screen_y) < 6)
		return
	rts_drag_active = TRUE
	update_rts_drag_box(rts_drag_start_screen_x, rts_drag_start_screen_y, current_coords[1], current_coords[2])

/// Box select only; plain clicks are handled in ClickOn.
/mob/living/carbon/xenomorph/hivemind/proc/on_rts_mouseup(mob/source, atom/object, turf/location, control, params)
	SIGNAL_HANDLER
	if(!rts_mode_active || !rts_drag_active || !rts_drag_start_turf)
		clear_rts_drag_state()
		return
	var/list/modifiers = params2list(params)
	var/atom/end_target = get_turf_on_clickcatcher(object, src, params)
	if(!end_target)
		end_target = location
	var/turf/end_turf = get_turf(end_target)
	if(!end_turf && modifiers["screen-loc"] && client)
		var/atom/viewer = client.eye ? client.eye : src
		end_turf = params2turf(modifiers["screen-loc"], get_turf(viewer), client)
	var/turf/start_turf = rts_drag_start_turf
	var/additive = rts_drag_additive || !!modifiers["shift"]
	clear_rts_drag_state()
	if(client)
		client.click_intercepted = world.time
	if(!start_turf || !end_turf || end_turf.z != start_turf.z)
		return COMSIG_MOB_CLICK_CANCELED
	if(!additive)
		clear_minion_selection()
	for(var/turf/T in block(locate(min(start_turf.x, end_turf.x), min(start_turf.y, end_turf.y), start_turf.z), locate(max(start_turf.x, end_turf.x), max(start_turf.y, end_turf.y), start_turf.z)))
		for(var/mob/living/carbon/xenomorph/minion in T)
			if(can_control_minion(minion))
				select_minion(minion, FALSE)
	return COMSIG_MOB_CLICK_CANCELED

/mob/living/carbon/xenomorph/hivemind/proc/rts_pixel_to_screen_loc(pixel_x, pixel_y)
	var/x_tile = FLOOR((pixel_x - 1) / 32, 1) + 1
	var/y_tile = FLOOR((pixel_y - 1) / 32, 1) + 1
	var/x_offset = ((pixel_x - 1) % 32) + 1
	var/y_offset = ((pixel_y - 1) % 32) + 1
	return "[x_tile]:[x_offset],[y_tile]:[y_offset]"

/mob/living/carbon/xenomorph/hivemind/proc/update_rts_drag_box(start_x, start_y, end_x, end_y)
	if(!client)
		return
	var/min_x = min(start_x, end_x)
	var/max_x = max(start_x, end_x)
	var/min_y = min(start_y, end_y)
	var/max_y = max(start_y, end_y)
	var/box_width = max(1, max_x - min_x + 1)
	var/box_height = max(1, max_y - min_y + 1)
	var/base_screen_loc = rts_pixel_to_screen_loc(min_x, min_y)
	var/static/icon/one_pixel = icon('icons/effects/alphacolors.dmi', "white")
	if(!rts_drag_fill)
		rts_drag_fill = new /atom/movable/screen/hivemind_rts_drag_box(null)
		rts_drag_fill.icon = one_pixel
		rts_drag_fill.color = "#18FF68"
		rts_drag_fill.alpha = 56
		client.screen += rts_drag_fill
	if(!rts_drag_border_top)
		rts_drag_border_top = new /atom/movable/screen/hivemind_rts_drag_box(null)
		rts_drag_border_top.icon = one_pixel
		rts_drag_border_top.color = "#35FF80"
		client.screen += rts_drag_border_top
	if(!rts_drag_border_bottom)
		rts_drag_border_bottom = new /atom/movable/screen/hivemind_rts_drag_box(null)
		rts_drag_border_bottom.icon = one_pixel
		rts_drag_border_bottom.color = "#35FF80"
		client.screen += rts_drag_border_bottom
	if(!rts_drag_border_left)
		rts_drag_border_left = new /atom/movable/screen/hivemind_rts_drag_box(null)
		rts_drag_border_left.icon = one_pixel
		rts_drag_border_left.color = "#35FF80"
		client.screen += rts_drag_border_left
	if(!rts_drag_border_right)
		rts_drag_border_right = new /atom/movable/screen/hivemind_rts_drag_box(null)
		rts_drag_border_right.icon = one_pixel
		rts_drag_border_right.color = "#35FF80"
		client.screen += rts_drag_border_right
	for(var/atom/movable/screen/hivemind_rts_drag_box/box_part in list(rts_drag_fill, rts_drag_border_top, rts_drag_border_bottom, rts_drag_border_left, rts_drag_border_right))
		box_part.screen_loc = base_screen_loc
	var/matrix/fill_transform = matrix()
	fill_transform.Scale(box_width, box_height)
	fill_transform.Translate((box_width - 1) * 0.5, (box_height - 1) * 0.5)
	rts_drag_fill.transform = fill_transform
	var/matrix/top_transform = matrix()
	top_transform.Scale(box_width, 2)
	top_transform.Translate((box_width - 1) * 0.5, box_height - 1.5)
	rts_drag_border_top.transform = top_transform
	var/matrix/bottom_transform = matrix()
	bottom_transform.Scale(box_width, 2)
	bottom_transform.Translate((box_width - 1) * 0.5, 0.5)
	rts_drag_border_bottom.transform = bottom_transform
	var/matrix/left_transform = matrix()
	left_transform.Scale(2, box_height)
	left_transform.Translate(0.5, (box_height - 1) * 0.5)
	rts_drag_border_left.transform = left_transform
	var/matrix/right_transform = matrix()
	right_transform.Scale(2, box_height)
	right_transform.Translate(box_width - 1.5, (box_height - 1) * 0.5)
	rts_drag_border_right.transform = right_transform

/mob/living/carbon/xenomorph/hivemind/proc/clear_rts_drag_state()
	if(client)
		for(var/atom/movable/screen/hivemind_rts_drag_box/box_part in list(rts_drag_fill, rts_drag_border_top, rts_drag_border_bottom, rts_drag_border_left, rts_drag_border_right))
			if(box_part)
				client.screen -= box_part
	QDEL_NULL(rts_drag_fill)
	QDEL_NULL(rts_drag_border_top)
	QDEL_NULL(rts_drag_border_bottom)
	QDEL_NULL(rts_drag_border_left)
	QDEL_NULL(rts_drag_border_right)
	rts_drag_start_turf = null
	rts_drag_start_screen_x = 0
	rts_drag_start_screen_y = 0
	rts_drag_active = FALSE
	rts_drag_additive = FALSE

/mob/living/carbon/xenomorph/hivemind/proc/on_kb_select_group_1()
	SIGNAL_HANDLER
	select_control_group(1)
	return COMSIG_KB_ACTIVATED
/mob/living/carbon/xenomorph/hivemind/proc/on_kb_select_group_2()
	SIGNAL_HANDLER
	select_control_group(2)
	return COMSIG_KB_ACTIVATED
/mob/living/carbon/xenomorph/hivemind/proc/on_kb_select_group_3()
	SIGNAL_HANDLER
	select_control_group(3)
	return COMSIG_KB_ACTIVATED
/mob/living/carbon/xenomorph/hivemind/proc/on_kb_select_group_4()
	SIGNAL_HANDLER
	select_control_group(4)
	return COMSIG_KB_ACTIVATED
/mob/living/carbon/xenomorph/hivemind/proc/on_kb_select_group_5()
	SIGNAL_HANDLER
	select_control_group(5)
	return COMSIG_KB_ACTIVATED
/mob/living/carbon/xenomorph/hivemind/proc/on_kb_create_group_1()
	SIGNAL_HANDLER
	assign_control_group(1)
	return COMSIG_KB_ACTIVATED
/mob/living/carbon/xenomorph/hivemind/proc/on_kb_create_group_2()
	SIGNAL_HANDLER
	assign_control_group(2)
	return COMSIG_KB_ACTIVATED
/mob/living/carbon/xenomorph/hivemind/proc/on_kb_create_group_3()
	SIGNAL_HANDLER
	assign_control_group(3)
	return COMSIG_KB_ACTIVATED
/mob/living/carbon/xenomorph/hivemind/proc/on_kb_create_group_4()
	SIGNAL_HANDLER
	assign_control_group(4)
	return COMSIG_KB_ACTIVATED
/mob/living/carbon/xenomorph/hivemind/proc/on_kb_create_group_5()
	SIGNAL_HANDLER
	assign_control_group(5)
	return COMSIG_KB_ACTIVATED
/mob/living/carbon/xenomorph/hivemind/proc/on_kb_add_group_1()
	SIGNAL_HANDLER
	add_to_control_group(1)
	return COMSIG_KB_ACTIVATED
/mob/living/carbon/xenomorph/hivemind/proc/on_kb_add_group_2()
	SIGNAL_HANDLER
	add_to_control_group(2)
	return COMSIG_KB_ACTIVATED
/mob/living/carbon/xenomorph/hivemind/proc/on_kb_add_group_3()
	SIGNAL_HANDLER
	add_to_control_group(3)
	return COMSIG_KB_ACTIVATED
/mob/living/carbon/xenomorph/hivemind/proc/on_kb_add_group_4()
	SIGNAL_HANDLER
	add_to_control_group(4)
	return COMSIG_KB_ACTIVATED
/mob/living/carbon/xenomorph/hivemind/proc/on_kb_add_group_5()
	SIGNAL_HANDLER
	add_to_control_group(5)
	return COMSIG_KB_ACTIVATED

/mob/living/carbon/xenomorph/hivemind/proc/update_rts_hud()
	if(!client)
		return
	for(var/atom/movable/screen/hivemind_rts_unit_card/card in rts_unit_cards)
		client.screen -= card
		qdel(card)
	rts_unit_cards.Cut()
	var/total = length(selected_minions)
	if(rts_mode_active && total)
		var/visible_cards = min(total, HIVEMIND_RTS_MAX_SELECTION_CARDS)
		var/start_offset = -round((visible_cards - 1) / 2)
		for(var/i in 1 to visible_cards)
			var/mob/living/carbon/xenomorph/minion = selected_minions[i]
			if(!can_control_minion(minion))
				continue
			var/offset = start_offset + i - 1
			var/atom/movable/screen/hivemind_rts_unit_card/card = new(null, null, minion, src, "CENTER[offset >= 0 ? "+" : ""][offset]:0,SOUTH:[HIVEMIND_RTS_UNIT_HUD_Y]")
			rts_unit_cards += card
			client.screen += card
	update_rts_group_hud()

/// Group + order buttons stay on screen regardless of the selected ability.
/mob/living/carbon/xenomorph/hivemind/proc/update_rts_group_hud()
	if(!client)
		return
	var/needs_rebuild = length(rts_group_buttons) != HIVEMIND_RTS_GROUP_COUNT + 4
	for(var/atom/movable/screen/screen_object in rts_group_buttons)
		if(QDELETED(screen_object))
			needs_rebuild = TRUE
			break
	if(needs_rebuild)
		for(var/atom/movable/screen/old_button in rts_group_buttons)
			client.screen -= old_button
		QDEL_LIST(rts_group_buttons)
		rts_group_buttons = list()
		for(var/group_idx in 1 to HIVEMIND_RTS_GROUP_COUNT)
			rts_group_buttons += new /atom/movable/screen/hivemind_rts_group_button(null, null, group_idx, src, "CENTER,SOUTH:[HIVEMIND_RTS_GROUP_HUD_Y]")
		var/order_idx = HIVEMIND_RTS_GROUP_COUNT
		for(var/order in list(RTS_ORDER_SELECT_ALL, RTS_ORDER_STOP, RTS_ORDER_CLEAR))
			order_idx++
			rts_group_buttons += new /atom/movable/screen/hivemind_rts_order_button(null, null, order, order_idx, src, "CENTER,SOUTH:[HIVEMIND_RTS_GROUP_HUD_Y]")
		rts_group_buttons += new /atom/movable/screen/hivemind_rts_group_summary(null, null, src, "CENTER,SOUTH:[HIVEMIND_RTS_GROUP_SUMMARY_HUD_Y]")
	for(var/atom/movable/screen/screen_object in rts_group_buttons)
		if(istype(screen_object, /atom/movable/screen/hivemind_rts_group_summary))
			var/atom/movable/screen/hivemind_rts_group_summary/group_summary = screen_object
			group_summary.update_summary()
			if(active_control_group)
				if(!(group_summary in client.screen))
					client.screen += group_summary
			else
				client.screen -= group_summary
			continue
		if(!(screen_object in client.screen))
			client.screen += screen_object
		if(istype(screen_object, /atom/movable/screen/hivemind_rts_group_button))
			var/atom/movable/screen/hivemind_rts_group_button/group_button = screen_object
			group_button.update_button()

/// The normal HUD rebuild replaces client.screen, so restore the RTS controls afterwards.
/mob/living/carbon/xenomorph/hivemind/proc/on_rts_hud_refreshed(datum/source, datum/hud/refreshed_hud)
	SIGNAL_HANDLER
	update_rts_hud()

/mob/living/carbon/xenomorph/hivemind/proc/clear_rts_hud()
	if(client)
		for(var/atom/movable/screen/hivemind_rts_unit_card/card in rts_unit_cards)
			client.screen -= card
		for(var/atom/movable/screen/screen_object in rts_group_buttons)
			client.screen -= screen_object
	QDEL_LIST(rts_unit_cards)
	QDEL_LIST(rts_group_buttons)
	rts_unit_cards = list()
	rts_group_buttons = list()

/atom/movable/screen/hivemind_rts_unit_card
	name = "Minion"
	icon = 'icons/effects/effects.dmi'
	icon_state = "white"
	plane = ABOVE_HUD_PLANE
	layer = 80
	mouse_opacity = MOUSE_OPACITY_ICON
	appearance_flags = APPEARANCE_UI
	var/datum/weakref/minion_ref
	var/mob/living/carbon/xenomorph/hivemind/hivemind_owner

/atom/movable/screen/hivemind_rts_unit_card/Initialize(mapload, datum/hud/hud_owner, mob/living/carbon/xenomorph/minion, mob/living/carbon/xenomorph/hivemind/H, position)
	. = ..(mapload, hud_owner)
	minion_ref = WEAKREF(minion)
	hivemind_owner = H
	screen_loc = position
	name = minion.name
	update_card()
	RegisterSignals(minion, list(COMSIG_XENOMORPH_TAKING_DAMAGE, COMSIG_XENOMORPH_HEALTH_REGEN), PROC_REF(update_card))

/atom/movable/screen/hivemind_rts_unit_card/Destroy()
	var/mob/living/carbon/xenomorph/minion = minion_ref?.resolve()
	if(minion)
		UnregisterSignal(minion, list(COMSIG_XENOMORPH_TAKING_DAMAGE, COMSIG_XENOMORPH_HEALTH_REGEN))
	minion_ref = null
	hivemind_owner = null
	return ..()

/atom/movable/screen/hivemind_rts_unit_card/proc/update_card()
	SIGNAL_HANDLER
	var/mob/living/carbon/xenomorph/minion = minion_ref?.resolve()
	if(!minion || QDELETED(minion))
		qdel(src)
		return
	cut_overlays()
	var/mutable_appearance/portrait = mutable_appearance(minion.icon, minion.icon_state, layer = 81)
	portrait.dir = SOUTH
	add_overlay(portrait)
	var/health_percent = round((minion.health / max(minion.maxHealth, 1)) * 100)
	var/group_number = hivemind_owner?.get_minion_group_number(minion)
	var/group_text = group_number ? "G[group_number] " : ""
	maptext = "<span style='font-size:7pt;font-weight:bold;color:#FFFFFF;-dm-text-outline:1px black;'>[group_text][health_percent]%</span>"
	maptext_x = 0
	maptext_y = 0
	maptext_width = HIVEMIND_RTS_UNIT_CARD_WIDTH
	maptext_height = HIVEMIND_RTS_UNIT_CARD_HEIGHT

/atom/movable/screen/hivemind_rts_unit_card/Click(location, control, params)
	var/mob/living/carbon/xenomorph/minion = minion_ref?.resolve()
	if(!minion || !hivemind_owner)
		return
	if(!hivemind_owner.rts_mode_active)
		return
	var/list/modifiers = params2list(params)
	if(modifiers["right"] || modifiers["shift"])
		hivemind_owner.deselect_minion(minion)
	else if(modifiers["middle"])
		hivemind_owner.jump(minion)
	else
		hivemind_owner.select_minion(minion, TRUE)

/atom/movable/screen/hivemind_rts_group_button
	name = "Control Group"
	icon = 'icons/effects/effects.dmi'
	icon_state = "white"
	plane = ABOVE_HUD_PLANE
	layer = 80
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	appearance_flags = APPEARANCE_UI
	var/group_idx = 1
	var/mob/living/carbon/xenomorph/hivemind/hivemind_owner

/atom/movable/screen/hivemind_rts_group_button/Initialize(mapload, datum/hud/hud_owner, group_number, mob/living/carbon/xenomorph/hivemind/H, position)
	. = ..(mapload, hud_owner)
	group_idx = group_number
	hivemind_owner = H
	var/x_offset = group_idx - HIVEMIND_RTS_GROUP_CENTER_INDEX
	var/x_position = x_offset ? "CENTER[x_offset > 0 ? "+" : ""][x_offset]" : "CENTER"
	screen_loc = "[x_position],SOUTH:[HIVEMIND_RTS_GROUP_HUD_Y]"
	pixel_x = 0
	update_button()

/atom/movable/screen/hivemind_rts_group_button/Destroy()
	hivemind_owner = null
	return ..()

/// Every slot remains visible. The selected slot has a bright border; each slot shows a caste portrait and its saved unit count.
/atom/movable/screen/hivemind_rts_group_button/proc/update_button()
	if(!hivemind_owner)
		return
	var/list/group = hivemind_owner.control_groups[group_idx]
	var/count = 0
	var/mob/living/carbon/xenomorph/representative
	for(var/datum/weakref/ref in group.Copy())
		var/mob/living/carbon/xenomorph/minion = ref.resolve()
		if(!hivemind_owner.can_control_minion(minion))
			group -= ref
			continue
		count++
		if(!representative)
			representative = minion
	var/is_active = hivemind_owner.active_control_group == group_idx
	cut_overlays()
	color = null
	alpha = 255

	// A visible frame exists for every group; the active group gets a bright green border.
	var/mutable_appearance/frame = mutable_appearance('icons/effects/alphacolors.dmi', "white", layer = 82)
	frame.color = is_active ? "#43FF86" : "#718078"
	frame.appearance_flags = APPEARANCE_UI|RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM
	var/matrix/frame_transform = matrix()
	frame_transform.Scale(HIVEMIND_RTS_GROUP_CARD_WIDTH, HIVEMIND_RTS_GROUP_CARD_HEIGHT)
	frame_transform.Translate((HIVEMIND_RTS_GROUP_CARD_WIDTH - 1) * 0.5, (HIVEMIND_RTS_GROUP_CARD_HEIGHT - 1) * 0.5)
	frame.transform = frame_transform
	add_overlay(frame)

	var/mutable_appearance/plate = mutable_appearance('icons/effects/alphacolors.dmi', "white", layer = 83)
	plate.color = "#111A15"
	plate.alpha = 250
	plate.appearance_flags = APPEARANCE_UI|RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM
	var/matrix/plate_transform = matrix()
	plate_transform.Scale(HIVEMIND_RTS_GROUP_CARD_WIDTH - 4, HIVEMIND_RTS_GROUP_CARD_HEIGHT - 4)
	plate_transform.Translate(2, 2)
	plate.transform = plate_transform
	add_overlay(plate)

	if(representative)
		var/mutable_appearance/portrait = new /mutable_appearance(representative)
		portrait.layer = 84
		portrait.plane = ABOVE_HUD_PLANE
		portrait.appearance_flags = APPEARANCE_UI|RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM
		var/matrix/portrait_transform = matrix()
		portrait_transform.Scale(0.68, 0.68)
		portrait_transform.Translate(5, 7)
		portrait.transform = portrait_transform
		add_overlay(portrait)

	var/mutable_appearance/count_backing = mutable_appearance('icons/effects/alphacolors.dmi', "white", layer = 85)
	count_backing.color = "#07100B"
	count_backing.alpha = 235
	count_backing.appearance_flags = APPEARANCE_UI|RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM
	var/matrix/count_backing_transform = matrix()
	count_backing_transform.Scale(HIVEMIND_RTS_GROUP_CARD_WIDTH - 4, 9)
	count_backing_transform.Translate(2, 2)
	count_backing.transform = count_backing_transform
	add_overlay(count_backing)

	var/mutable_appearance/index_label = mutable_appearance(icon = null, icon_state = null, layer = 86)
	index_label.appearance_flags = APPEARANCE_UI|RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM
	index_label.maptext = "<span style='font-size:8pt;font-weight:bold;color:#FFFFFF;-dm-text-outline:1px black;'>[group_idx]</span>"
	index_label.maptext_x = 2
	index_label.maptext_y = 21
	index_label.maptext_width = 10
	index_label.maptext_height = 10
	add_overlay(index_label)

	var/mutable_appearance/count_label = mutable_appearance(icon = null, icon_state = null, layer = 87)
	count_label.appearance_flags = APPEARANCE_UI|RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM
	count_label.maptext = "<div style='text-align:center;font-size:7pt;font-weight:bold;color:#FFFFFF;-dm-text-outline:1px black;'>[count]</div>"
	count_label.maptext_x = 0
	count_label.maptext_y = 1
	count_label.maptext_width = HIVEMIND_RTS_GROUP_CARD_WIDTH
	count_label.maptext_height = 9
	add_overlay(count_label)
	name = "Отряд [group_idx]: [count] миньонов ([is_active ? "активный" : "не выбран"]); ЛКМ - выбрать, ПКМ - выбрать и перейти, Ctrl - сохранить, Shift - добавить"

/atom/movable/screen/hivemind_rts_group_button/Click(location, control, params)
	if(!hivemind_owner)
		return
	var/list/modifiers = params2list(params)
	if(modifiers["right"])
		hivemind_owner.select_control_group(group_idx, TRUE)
	else if(modifiers["ctrl"])
		hivemind_owner.assign_control_group(group_idx)
	else if(modifiers["shift"])
		hivemind_owner.add_to_control_group(group_idx)
	else
		hivemind_owner.select_control_group(group_idx)

/// Small composition card placed directly beneath the currently active control group.
/atom/movable/screen/hivemind_rts_group_summary
	name = "Active group composition"
	icon = null
	icon_state = ""
	plane = ABOVE_HUD_PLANE
	layer = 90
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = APPEARANCE_UI
	var/mob/living/carbon/xenomorph/hivemind/hivemind_owner

/atom/movable/screen/hivemind_rts_group_summary/Initialize(mapload, datum/hud/hud_owner, mob/living/carbon/xenomorph/hivemind/H, position)
	. = ..(mapload, hud_owner)
	hivemind_owner = H
	update_summary()

/atom/movable/screen/hivemind_rts_group_summary/Destroy()
	hivemind_owner = null
	return ..()

/atom/movable/screen/hivemind_rts_group_summary/proc/update_summary()
	if(!hivemind_owner || !hivemind_owner.active_control_group)
		return
	var/group_idx = hivemind_owner.active_control_group
	var/x_offset = group_idx - HIVEMIND_RTS_GROUP_CENTER_INDEX
	var/x_position = x_offset ? "CENTER[x_offset > 0 ? "+" : ""][x_offset]" : "CENTER"
	screen_loc = "[x_position],SOUTH:[HIVEMIND_RTS_GROUP_SUMMARY_HUD_Y]"
	var/list/group = hivemind_owner.control_groups[group_idx]
	var/count = 0
	var/mob/living/carbon/xenomorph/representative
	for(var/datum/weakref/ref in group.Copy())
		var/mob/living/carbon/xenomorph/minion = ref.resolve()
		if(!hivemind_owner.can_control_minion(minion))
			group -= ref
			continue
		count++
		if(!representative)
			representative = minion
	cut_overlays()
	var/mutable_appearance/frame = mutable_appearance('icons/effects/alphacolors.dmi', "white", layer = 91)
	frame.color = "#39FF83"
	frame.appearance_flags = APPEARANCE_UI|RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM
	var/matrix/frame_transform = matrix()
	frame_transform.Scale(HIVEMIND_RTS_GROUP_CARD_WIDTH, HIVEMIND_RTS_GROUP_CARD_HEIGHT - 10)
	frame_transform.Translate((HIVEMIND_RTS_GROUP_CARD_WIDTH - 1) * 0.5, (HIVEMIND_RTS_GROUP_CARD_HEIGHT - 11) * 0.5)
	frame.transform = frame_transform
	add_overlay(frame)
	var/mutable_appearance/plate = mutable_appearance('icons/effects/alphacolors.dmi', "white", layer = 92)
	plate.color = "#111A15"
	plate.alpha = 250
	plate.appearance_flags = APPEARANCE_UI|RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM
	var/matrix/plate_transform = matrix()
	plate_transform.Scale(HIVEMIND_RTS_GROUP_CARD_WIDTH - 4, HIVEMIND_RTS_GROUP_CARD_HEIGHT - 14)
	plate_transform.Translate(2, 2)
	plate.transform = plate_transform
	add_overlay(plate)
	if(representative)
		var/mutable_appearance/portrait = new /mutable_appearance(representative)
		portrait.layer = 93
		portrait.plane = ABOVE_HUD_PLANE
		portrait.appearance_flags = APPEARANCE_UI|RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM
		var/matrix/portrait_transform = matrix()
		portrait_transform.Scale(0.48, 0.48)
		portrait_transform.Translate(2, 3)
		portrait.transform = portrait_transform
		add_overlay(portrait)
	var/mutable_appearance/group_label = mutable_appearance(icon = null, icon_state = null, layer = 94)
	group_label.appearance_flags = APPEARANCE_UI|RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM
	group_label.maptext = "<div style='font-size:7pt;font-weight:bold;color:#FFFFFF;-dm-text-outline:1px black;'>G[group_idx]</div>"
	group_label.maptext_x = 17
	group_label.maptext_y = 11
	group_label.maptext_width = 15
	group_label.maptext_height = 9
	add_overlay(group_label)
	var/mutable_appearance/count_label = mutable_appearance(icon = null, icon_state = null, layer = 95)
	count_label.appearance_flags = APPEARANCE_UI|RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM
	count_label.maptext = "<div style='font-size:8pt;font-weight:bold;color:#FFFFFF;-dm-text-outline:1px black;'>[count]</div>"
	count_label.maptext_x = 18
	count_label.maptext_y = 1
	count_label.maptext_width = 13
	count_label.maptext_height = 10
	add_overlay(count_label)
	name = "Состав отряда [group_idx]: [count] миньонов"

/// Order buttons next to the group row: select all in view, stop, clear selection.
/atom/movable/screen/hivemind_rts_order_button
	name = "Order"
	icon = 'icons/Xeno/actions/general.dmi'
	icon_state = "rally_minions"
	plane = ABOVE_HUD_PLANE
	layer = 80
	mouse_opacity = MOUSE_OPACITY_ICON
	appearance_flags = APPEARANCE_UI
	var/order
	var/mob/living/carbon/xenomorph/hivemind/hivemind_owner

/atom/movable/screen/hivemind_rts_order_button/Initialize(mapload, datum/hud/hud_owner, order_type, slot, mob/living/carbon/xenomorph/hivemind/H, position)
	. = ..(mapload, hud_owner)
	order = order_type
	hivemind_owner = H
	var/x_offset = slot - HIVEMIND_RTS_GROUP_CENTER_INDEX
	var/x_position = x_offset ? "CENTER[x_offset > 0 ? "+" : ""][x_offset]" : "CENTER"
	screen_loc = "[x_position],SOUTH:[HIVEMIND_RTS_GROUP_HUD_Y]"
	pixel_x = 0
	switch(order)
		if(RTS_ORDER_SELECT_ALL)
			name = "Выбрать всех миньонов в поле зрения"
			icon_state = "rally_minions"
		if(RTS_ORDER_STOP)
			name = "Стоп (выбранные, иначе все в поле зрения)"
			icon_state = "minion_passive"
		if(RTS_ORDER_CLEAR)
			name = "Снять выделение"
			icon_state = "minion_agressive"

/atom/movable/screen/hivemind_rts_order_button/Destroy()
	hivemind_owner = null
	return ..()

/atom/movable/screen/hivemind_rts_order_button/Click(location, control, params)
	if(!hivemind_owner)
		return
	switch(order)
		if(RTS_ORDER_SELECT_ALL)
			hivemind_owner.select_all_in_view()
		if(RTS_ORDER_STOP)
			hivemind_owner.stop_selected_or_visible()
		if(RTS_ORDER_CLEAR)
			hivemind_owner.clear_minion_selection()

/mob/living/carbon/xenomorph/hivemind/proc/select_all_in_view()
	ensure_rts_active()
	clear_minion_selection()
	var/count = 0
	for(var/mob/living/carbon/xenomorph/minion in get_minions_in_view())
		if(select_minion(minion, FALSE))
			count++
	balloon_alert(src, count ? "Выбрано миньонов: [count]" : "Нет доступных миньонов в поле зрения")

/mob/living/carbon/xenomorph/hivemind/proc/stop_selected_or_visible()
	var/list/targets = length(selected_minions) ? selected_minions.Copy() : get_minions_in_view()
	for(var/mob/living/carbon/xenomorph/minion in targets)
		stop_minion(minion)
	balloon_alert(src, "Миньоны остановлены")

/obj/effect/temp_visual/rts_order
	name = "order marker"
	icon = 'icons/effects/blips.dmi'
	icon_state = "attack"
	duration = 0.8 SECONDS
	layer = ABOVE_NORMAL_TURF_LAYER
	plane = GAME_PLANE

/obj/effect/temp_visual/rts_order/move
	icon_state = "defend"
	color = "#00FF00"

/obj/effect/temp_visual/rts_order/attack
	icon_state = "attack"
	color = "#FF0000"

/obj/effect/temp_visual/rts_order/escort
	icon_state = "rally"
	color = "#00FFFF"

// =================
// hivemind core
/obj/structure/xeno/hivemindcore
	name = "hivemind core"
	desc = "A very weird, pulsating node. This looks almost alive."
	max_integrity = 600
	icon = 'icons/Xeno/1x1building.dmi'
	icon_state = "hivemind_core"
	xeno_structure_flags = IGNORE_WEED_REMOVAL|CRITICAL_STRUCTURE|DEPART_DESTRUCTION_IMMUNE|XENO_STRUCT_WARNING_RADIUS|XENO_STRUCT_DAMAGE_ALERT
	///The weakref to the parent hivemind mob that we're attached to
	var/datum/weakref/parent

/obj/structure/xeno/hivemindcore/Initialize(mapload)
	. = ..()
	GLOB.hive_datums[hivenumber].hivemindcores += src
	new /obj/alien/weeds/node(loc)
	set_light(7, 5, LIGHT_COLOR_PURPLE)
	update_minimap_icon()

/obj/structure/xeno/hivemindcore/Destroy()
	GLOB.hive_datums[hivenumber].hivemindcores -= src
	var/mob/living/carbon/xenomorph/hivemind/our_parent = get_parent()
	if(isnull(our_parent))
		return ..()
	our_parent.playsound_local(our_parent, SFX_ALIEN_HELP, 30, TRUE)
	to_chat(our_parent, span_xenouserdanger("Your core has been destroyed!"))
	xeno_message("A sudden tremor ripples through the hive... \the [our_parent] has been slain!", "xenoannounce", 5, our_parent.hivenumber)
	GLOB.key_to_time_of_role_death[our_parent.key] = world.time
	GLOB.key_to_time_of_death[our_parent.key] = world.time
	our_parent.ghostize()
	if(!QDELETED(our_parent))
		qdel(our_parent)
	return ..()

//hivemind cores

/obj/structure/xeno/hivemindcore/attack_alien(mob/living/carbon/xenomorph/xeno_attacker, damage_amount = xeno_attacker.xeno_caste.melee_damage, damage_type = BRUTE, damage_flag = MELEE, effects = TRUE, armor_penetration = xeno_attacker.xeno_caste.melee_ap, isrightclick = FALSE)
	if(isxenoqueen(xeno_attacker))
		var/choice = tgui_alert(xeno_attacker, "Are you sure you want to destroy the hivemind?", "Destroy hivemind", list("Yes", "Cancel"))
		if(choice == "Yes")
			deconstruct(FALSE)
			return

	xeno_attacker.visible_message(span_danger("[xeno_attacker] nudges its head against [src]."), \
	span_danger("You nudge your head against [src]."))

/obj/structure/xeno/hivemindcore/take_damage(damage_amount, damage_type, damage_flag = null, effects = TRUE, attack_dir, armour_penetration, mob/living/blame_mob)
	. = ..()
	var/mob/living/carbon/xenomorph/hivemind/our_parent = get_parent()
	if(isnull(our_parent))
		return
	var/health_percent = round((max_integrity / obj_integrity) * 100)
	switch(health_percent)
		if(-INFINITY to 25)
			to_chat(our_parent, span_xenouserdanger("Your core is under attack, and dangerous low on health!"))
		if(26 to 75)
			to_chat(our_parent, span_xenodanger("Your core is under attack, and low on health!"))
		if(76 to INFINITY)
			to_chat(our_parent, span_xenodanger("Your core is under attack!"))

/obj/structure/xeno/hivemindcore/update_minimap_icon()
	SSminimaps.remove_marker(src)
	SSminimaps.add_marker(src, MINIMAP_FLAG_XENO, image('icons/UI_icons/map_blips.dmi', null, "hivemindcore[threat_warning ? "_warn" : "_passive"]", MINIMAP_LABELS_LAYER))

/// Getter for the parent of this hive core
/obj/structure/xeno/hivemindcore/proc/get_parent()
	return parent?.resolve()

/mob/living/carbon/xenomorph/hivemind/add_inherent_verbs()
	return

/mob/living/carbon/xenomorph/hivemind/remove_inherent_verbs()
	return

/mob/living/carbon/xenomorph/hivemind/add_to_hive(datum/hive_status/HS, force = FALSE, prevent_ruler=FALSE)
	. = ..()
	if(!GLOB.xeno_structures_by_hive[HS.hivenumber])
		GLOB.xeno_structures_by_hive[HS.hivenumber] = list()

	var/obj/structure/xeno/hivemindcore/hive_core = get_core()

	if(!hive_core) //how are you even alive then?
		qdel(src)
		return

	GLOB.xeno_structures_by_hive[HS.hivenumber] |= hive_core

	if(!GLOB.xeno_critical_structures_by_hive[HS.hivenumber])
		GLOB.xeno_critical_structures_by_hive[HS.hivenumber] = list()

	GLOB.xeno_critical_structures_by_hive[HS.hivenumber] |= hive_core
	hive_core.hivenumber = HS.hivenumber
	hive_core.name = "[HS.hivenumber == XENO_HIVE_NORMAL ? "" : "[HS.name] "]hivemind core"
	hive_core.color = HS.color

/mob/living/carbon/xenomorph/hivemind/remove_from_hive()
	var/obj/structure/xeno/hivemindcore/hive_core = get_core()
	GLOB.xeno_structures_by_hive[hivenumber] -= hive_core
	GLOB.xeno_critical_structures_by_hive[hivenumber] -= hive_core
	. = ..()
	if(!QDELETED(src)) //if we aren't dead, somehow?
		hive_core.name = "banished hivemind core"
		hive_core.color = null

/mob/living/carbon/xenomorph/hivemind/Corrupted
	hivenumber = XENO_HIVE_CORRUPTED

/mob/living/carbon/xenomorph/hivemind/Alpha
	hivenumber = XENO_HIVE_ALPHA

/mob/living/carbon/xenomorph/hivemind/Beta
	hivenumber = XENO_HIVE_BETA

/mob/living/carbon/xenomorph/hivemind/Zeta
	hivenumber = XENO_HIVE_ZETA

/mob/living/carbon/xenomorph/hivemind/admeme
	hivenumber = XENO_HIVE_ADMEME

/mob/living/carbon/xenomorph/hivemind/Corrupted/fallen
	hivenumber = XENO_HIVE_FALLEN

#undef TIME_TO_TRANSFORM
