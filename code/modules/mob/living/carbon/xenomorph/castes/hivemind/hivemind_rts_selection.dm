// Hivemind RTS selection, control groups, and group keybindings.

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
		return FALSE
	var/list/group = control_groups[active_control_group]
	group.Cut()
	for(var/mob/living/carbon/xenomorph/minion in selected_minions.Copy())
		if(can_control_minion(minion))
			group += minion
	return TRUE

/mob/living/carbon/xenomorph/hivemind/proc/assign_control_group(group_idx)
	if(group_idx < 1 || group_idx > HIVEMIND_RTS_GROUP_COUNT)
		return FALSE
	// Commit the outgoing active group before assigning the current selection elsewhere.
	if(active_control_group && active_control_group != group_idx)
		save_active_control_group()
	var/list/group = control_groups[group_idx]
	group.Cut()
	for(var/mob/living/carbon/xenomorph/minion in selected_minions.Copy())
		if(can_control_minion(minion))
			group += minion
	active_control_group = group_idx
	update_rts_hud()
	var/count = length(group)
	balloon_alert(src, count ? "Отряд [group_idx] сохранён ([count])" : "Отряд [group_idx] очищен")
	return TRUE

/mob/living/carbon/xenomorph/hivemind/proc/select_control_group(group_idx, force_jump = FALSE)
	if(group_idx < 1 || group_idx > HIVEMIND_RTS_GROUP_COUNT)
		return FALSE
	ensure_rts_active()
	// Snapshot the active selection before changing groups, even when the same group is selected again.
	if(active_control_group)
		save_active_control_group()
	var/list/group = control_groups[group_idx]
	var/list/valid_minions = list()
	for(var/mob/living/carbon/xenomorph/minion in group.Copy())
		if(can_control_minion(minion))
			valid_minions += minion
		else
			group -= minion
	var/is_double_tap = last_group_select_time[group_idx] && (world.time - last_group_select_time[group_idx]) <= HIVEMIND_RTS_DOUBLETAP_WINDOW
	last_group_select_time[group_idx] = world.time
	active_control_group = group_idx
	suspend_group_selection_sync = TRUE
	clear_minion_selection()
	for(var/mob/living/carbon/xenomorph/minion in valid_minions)
		select_minion(minion, FALSE)
	suspend_group_selection_sync = FALSE
	// Rebuild storage from the restored selection to keep both representations identical.
	save_active_control_group()
	if(is_double_tap || force_jump)
		if(length(valid_minions))
			jump(valid_minions[1])
	if(!length(valid_minions))
		balloon_alert(src, "Отряд [group_idx] пуст")
	update_rts_hud()
	return TRUE

/mob/living/carbon/xenomorph/hivemind/proc/add_to_control_group(group_idx)
	if(group_idx < 1 || group_idx > HIVEMIND_RTS_GROUP_COUNT)
		return FALSE
	ensure_rts_active()
	if(active_control_group)
		save_active_control_group()
	active_control_group = 0
	var/list/group = control_groups[group_idx]
	for(var/mob/living/carbon/xenomorph/minion in group.Copy())
		if(!can_control_minion(minion))
			group -= minion
			continue
		select_minion(minion, FALSE)
	update_rts_hud()
	return TRUE

/mob/living/carbon/xenomorph/hivemind/proc/get_minion_group_number(mob/living/carbon/xenomorph/minion)
	for(var/group_idx in 1 to HIVEMIND_RTS_GROUP_COUNT)
		if(minion in control_groups[group_idx])
			return group_idx
	return 0


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
