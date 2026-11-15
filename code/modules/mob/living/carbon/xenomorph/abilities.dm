// ***************************************
// *********** Universal abilities
// ***************************************
// Resting
/datum/action/ability/xeno_action/xeno_resting
	name = "Rest"
	desc = "Rest on weeds to regenerate health and plasma."
	action_icon_state = "resting"
	action_icon = 'icons/Xeno/actions/general.dmi'
	use_state_flags = ABILITY_USE_LYING|ABILITY_USE_CRESTED|ABILITY_USE_CLOSEDTURF|ABILITY_USE_STAGGERED|ABILITY_USE_INCAP
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_REST,
	)

/datum/action/ability/xeno_action/xeno_resting/action_activate()
	if(!istype(xeno_owner))
		return
	xeno_owner.toggle_resting()
	return succeed_activate()

// ***************************************
// *********** Drone-y abilities
// ***************************************
/datum/action/ability/activable/xeno/plant_weeds
	name = "Plant Weeds"
	desc = "Plant a weed node on your tile."
	action_icon_state = "plant_weeds"
	action_icon = 'icons/Xeno/actions/construction.dmi'
	ability_cost = 75
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_DROP_WEEDS,
		KEYBINDING_ALTERNATE = COMSIG_XENOABILITY_CHOOSE_WEEDS,
	)
	use_state_flags = ABILITY_USE_LYING
	/// The multiplier of ability cost. This is seperate of the weed type's ability cost multiplier.
	var/cost_multiplier = 1
	///the maximum range of the ability
	var/max_range = 0
	/// List of weed nodes that can be selected. Filled with every weed type when the ability is created.
	var/list/obj/alien/weeds/node/selectable_weed_typepaths
	///The seleted type of weeds
	var/obj/alien/weeds/node/weed_type = /obj/alien/weeds/node
	///Whether automatic weeding is active
	var/auto_weeding = FALSE
	///The turf that was last weeded
	var/turf/last_weeded_turf

/datum/action/ability/activable/xeno/plant_weeds/New(Target)
	. = ..()
	selectable_weed_typepaths = GLOB.weed_type_list.Copy()
	if(SSmonitor.gamestate == SHUTTERS_CLOSED)
		RegisterSignals(SSdcs, list(COMSIG_GLOB_OPEN_SHUTTERS_EARLY, COMSIG_GLOB_OPEN_TIMED_SHUTTERS_LATE), PROC_REF(update_ability_cost_shutters))

/datum/action/ability/activable/xeno/plant_weeds/can_use_action(atom/A, silent = FALSE, override_flags)
	update_ability_cost()
	return ..()

/// Updates the ability cost based on gamestate.
/datum/action/ability/activable/xeno/plant_weeds/proc/update_ability_cost(shutters_recently_opened)
	ability_cost = initial(ability_cost) * cost_multiplier * initial(weed_type.ability_cost_mult)
	ability_cost = (!shutters_recently_opened && SSmonitor.gamestate == SHUTTERS_CLOSED) ? ability_cost * 0.5 : ability_cost

/**
 * Updates the ability cost as if the gamestate was not SHUTTERS_CLOSED.
 * The signal happens at the same time of gamestate changing, so that variable cannot be depended on.
 */
/datum/action/ability/activable/xeno/plant_weeds/proc/update_ability_cost_shutters()
	SIGNAL_HANDLER
	UnregisterSignal(SSdcs, list(COMSIG_GLOB_OPEN_SHUTTERS_EARLY, COMSIG_GLOB_OPEN_TIMED_SHUTTERS_LATE))
	update_ability_cost(TRUE)
	update_button_icon()

/datum/action/ability/activable/xeno/plant_weeds/action_activate()
	if(max_range)
		return ..()
	if(can_use_action())
		plant_weeds(owner)

/datum/action/ability/activable/xeno/plant_weeds/use_ability(atom/A)
	plant_weeds(max_range ? A : get_turf(owner))

////Plant a weeds node on the selected atom
/datum/action/ability/activable/xeno/plant_weeds/proc/plant_weeds(atom/A)
	var/turf/T = get_turf(A)

	if(!T.check_alien_construction(owner, FALSE, weed_type))
		return fail_activate()

	if(!T.check_disallow_alien_fortification(null, TRUE))
		to_chat(owner, span_warning("The queen mother prohibits us from weeding here."))
		return fail_activate()

	if(locate(/obj/structure/xeno/trap) in T)
		to_chat(owner, span_warning("There is a resin trap in the way!"))
		return fail_activate()

	if(!T.is_weedable())
		to_chat(owner, span_warning("Bad place for a garden!"))
		return fail_activate()

	if(locate(weed_type) in T)
		to_chat(owner, span_warning("There's a pod here already!"))
		return fail_activate()

	owner.visible_message(span_xenonotice("\The [owner] regurgitates a pulsating node and plants it on the ground!"), \
		span_xenonotice("We regurgitate a pulsating node and plant it on the ground!"), null, 5)
	new weed_type(T)
	last_weeded_turf = T
	playsound(T, SFX_ALIEN_RESIN_BUILD, 25)
	GLOB.round_statistics.weeds_planted++
	SSblackbox.record_feedback(FEEDBACK_TALLY, "round_statistics", 1, "weeds_planted")
	if(owner.client)
		var/datum/personal_statistics/personal_statistics = GLOB.personal_statistics_list[owner.ckey]
		personal_statistics.weeds_planted++
	add_cooldown()
	succeed_activate()

/datum/action/ability/activable/xeno/plant_weeds/alternate_action_activate()
	INVOKE_ASYNC(src, PROC_REF(choose_weed))
	return COMSIG_KB_ACTIVATED

///Chose which weed will be planted by the xeno owner or toggle automatic weeding
/datum/action/ability/activable/xeno/plant_weeds/proc/choose_weed()
	var/list/available_weeds = list()
	for(var/obj/alien/weeds/node/weed_type_possible AS in selectable_weed_typepaths)
		var/weed_image = GLOB.weed_images_list[initial(weed_type_possible.name)]
		if(!weed_image)
			continue
		available_weeds[initial(weed_type_possible.name)] = weed_image
	available_weeds[AUTOMATIC_WEEDING] = GLOB.weed_images_list[AUTOMATIC_WEEDING] // For automatic weeding.
	var/weed_choice = show_radial_menu(owner, owner, available_weeds, radius = 35)
	if(!weed_choice)
		return
	if(weed_choice == AUTOMATIC_WEEDING)
		toggle_auto_weeding()
	else
		for(var/obj/alien/weeds/node/weed_type_possible AS in GLOB.weed_type_list)
			if(initial(weed_type_possible.name) == weed_choice)
				weed_type = weed_type_possible
				update_ability_cost()
				break
		to_chat(owner, span_xenonotice("We will now spawn <b>[weed_choice]\s</b> when using the plant weeds ability."))
	update_button_icon()

///Toggles automatic weeding
/datum/action/ability/activable/xeno/plant_weeds/proc/toggle_auto_weeding()
	SIGNAL_HANDLER
	if(auto_weeding)
		UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
		UnregisterSignal(owner, COMSIG_MOB_DEATH)
		auto_weeding = FALSE
		to_chat(owner, span_xenonotice("We will no longer automatically plant weeds."))
		return
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(weed_on_move))
	RegisterSignal(owner, COMSIG_MOB_DEATH, PROC_REF(toggle_auto_weeding))
	auto_weeding = TRUE
	to_chat(owner, span_xenonotice("We will now automatically plant weeds."))

///Used for performing automatic weeding
/datum/action/ability/activable/xeno/plant_weeds/proc/weed_on_move(datum/source)
	if(xeno_owner.loc_weeds_type)
		return
	if(get_dist(xeno_owner, last_weeded_turf) < AUTO_WEEDING_MIN_DIST)
		return
	if(!can_use_ability(xeno_owner.loc, TRUE, ABILITY_IGNORE_SELECTED_ABILITY))
		return
	plant_weeds(xeno_owner)

/datum/action/ability/activable/xeno/plant_weeds/update_button_icon()
	name = "Plant Weeds ([ability_cost])"
	action_icon_state = initial(weed_type.name)
	if(auto_weeding)
		if(!visual_references[VREF_IMAGE_ONTOP])
			// below maptext , above selected frames
			visual_references[VREF_IMAGE_ONTOP] = image('icons/Xeno/actions/_actions.dmi', icon_state = "repeating", layer = ACTION_LAYER_IMAGE_ONTOP)
			button.add_overlay(visual_references[VREF_IMAGE_ONTOP])
	else if(visual_references[VREF_IMAGE_ONTOP])
		button.cut_overlay(visual_references[VREF_IMAGE_ONTOP])
		visual_references[VREF_IMAGE_ONTOP] = null
	return ..()

//AI stuff
/datum/action/ability/activable/xeno/plant_weeds/ai_should_start_consider()
	return TRUE

/datum/action/ability/activable/xeno/plant_weeds/ai_should_use(target)
	if(!can_use_action(override_flags = ABILITY_IGNORE_SELECTED_ABILITY))
		return FALSE
	if(xeno_owner.loc_weeds_type)
		return FALSE
	return TRUE

/datum/action/ability/activable/xeno/plant_weeds/ranged
	max_range = 4

/datum/action/ability/activable/xeno/plant_weeds/ranged/can_use_ability(atom/A, silent = FALSE, override_flags)
	var/area/area = get_area(A)
	if(area.area_flags & MARINE_BASE)
		if(!silent)
			to_chat(owner, span_xenowarning("You cannot weed here!"))
		return FALSE
	if(!line_of_sight(owner, get_turf(A)))
		to_chat(owner, span_warning("You cannot plant weeds without line of sight!"))
		return FALSE
	return ..()

/datum/action/ability/activable/xeno/plant_weeds/ranged/can_use_action(silent = FALSE, override_flags, selecting = FALSE)
	if (owner.status_flags & INCORPOREAL)
		return FALSE
	return ..()

// Secrete Resin
/datum/action/ability/activable/xeno/secrete_resin
	name = "Secrete Resin"
	desc = "Builds whatever resin you selected"
	action_icon_state = RESIN_WALL
	action_icon = 'icons/Xeno/actions/construction.dmi'
	target_flags = ABILITY_TURF_TARGET
	ability_cost = 50
	action_type = ACTION_TOGGLE
	// Blueprint placement is handled by the click signal; resource/cooldown checks happen when building.
	use_state_flags = ABILITY_IGNORE_PLASMA|ABILITY_IGNORE_COOLDOWN
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_SECRETE_RESIN,
		KEYBINDING_ALTERNATE = COMSIG_XENOABILITY_SECRETE_RESIN_UNDO,
		KEYBINDING_SECONDARY = COMSIG_XENOABILITY_SECRETE_RESIN_REDO,
		"pattern_previous" = COMSIG_XENOABILITY_SECRETE_RESIN_PATTERN_PREVIOUS,
		"pattern_next" = COMSIG_XENOABILITY_SECRETE_RESIN_PATTERN_NEXT,
		"toggle_auto_rebuild" = COMSIG_XENOABILITY_SECRETE_RESIN_TOGGLE_AUTO_REBUILD,
		"toggle_demolish" = COMSIG_XENOABILITY_SECRETE_RESIN_TOGGLE_DEMOLISH,
	)
	/// Minimum time to build a resin structure.
	var/base_wait = 0.5 SECONDS
	/// Multiplicator factor to add to the building time, depends on the health of the structure built.
	var/scaling_wait = 1.5 SECONDS
	/// List of buildable structures. Order corresponds with resin_images_list.
	var/list/buildable_structures = list(
		/turf/closed/wall/resin/regenerating,
		/turf/closed/wall/resin/regenerating/bulletproof,
		/turf/closed/wall/resin/regenerating/fireproof,
		/turf/closed/wall/resin/regenerating/hardy,
		/obj/alien/resin/sticky,
		/obj/structure/mineral_door/resin,
		/obj/structure/bed/nest,
	)
	/// The percentage of maximum health to heal the owner whenever a structure is built.
	var/heal_percentage = 0
	/// Only place blueprints, never build directly.
	var/ghost_mode = FALSE
	/// Place demolition blueprints instead of construction blueprints.
	var/demolish_mode = FALSE
	/// Structures built with this flag leave a new blueprint in place when destroyed.
	var/auto_rebuild_mode = FALSE
	var/datum/buildingpattern/selected_pattern
	/// Keys in the catalog marked as favorites.
	var/list/favorites = list()
	var/list/atom/holograms = list()
	var/cleanup_timer
	var/cleanup_time = 4 SECONDS
	/// History is only enabled while the TGUI construction mode is open.
	var/ui_mode_active = FALSE
	var/list/undo_stack = list()
	var/list/redo_stack = list()
	var/max_history = 50


/// Nymphs are dedicated builders, so their per-structure start time is lower.
/datum/action/ability/activable/xeno/secrete_resin/nymph
	base_wait = 0.2 SECONDS
	scaling_wait = 0.8 SECONDS

/// Extra handling for adding the action for quickbuild counter.
/datum/action/ability/activable/xeno/secrete_resin/give_action(mob/living/L)
	. = ..()
	if(!CHECK_BITFIELD(SSticker?.mode?.round_type_flags, MODE_ALLOW_XENO_QUICKBUILD))
		return
	if(!SSresinshaping.active)
		return
	var/mutable_appearance/build_maptext = mutable_appearance(icon = null, icon_state = null, layer = ACTION_LAYER_MAPTEXT)
	build_maptext.pixel_x = 12
	build_maptext.pixel_y = -5
	build_maptext.maptext = MAPTEXT(SSresinshaping.get_building_points(owner))
	visual_references[VREF_MUTABLE_BUILDING_COUNTER] = build_maptext

/// Extra handling to remove the quickbuild counter.
/datum/action/ability/activable/xeno/secrete_resin/remove_action(mob/living/carbon/xenomorph/X)
	ui_mode_active = FALSE
	clear_history()
	if(!CHECK_BITFIELD(SSticker.mode?.round_type_flags, MODE_ALLOW_XENO_QUICKBUILD))
		return ..()
	update_button_icon() // owner is unassigned by parent remove_action.
	return ..()

/datum/action/ability/activable/xeno/secrete_resin/update_button_icon()
	if(xeno_owner)
		var/atom/A = xeno_owner.selected_resin
		action_icon_state = initial(A.name)
	if(!is_gameplay_level(xeno_owner?.loc?.z))
		return ..() // prevents runtimes.
	if(SSmonitor.gamestate == SHUTTERS_CLOSED && CHECK_BITFIELD(SSticker.mode?.round_type_flags, MODE_ALLOW_XENO_QUICKBUILD) && SSresinshaping.active)
		button.cut_overlay(visual_references[VREF_MUTABLE_BUILDING_COUNTER])
		var/mutable_appearance/number = visual_references[VREF_MUTABLE_BUILDING_COUNTER]
		number.maptext = MAPTEXT("[SSresinshaping.get_building_points(owner)]")
		visual_references[VREF_MUTABLE_BUILDING_COUNTER] = number
		button.add_overlay(visual_references[VREF_MUTABLE_BUILDING_COUNTER])
	else if(visual_references[VREF_MUTABLE_BUILDING_COUNTER])
		button.cut_overlay(visual_references[VREF_MUTABLE_BUILDING_COUNTER])
		visual_references[VREF_MUTABLE_BUILDING_COUNTER] = null
	return ..()

/datum/action/ability/activable/xeno/secrete_resin/New(Target)
	. = ..()
	selected_pattern = get_xeno_build_patterns()["single"]

/// Select this ability if it is not already selected.
/datum/action/ability/activable/xeno/secrete_resin/proc/ensure_selected()
	if(!xeno_owner || xeno_owner.selected_ability == src)
		return
	xeno_owner.selected_ability?.deselect()
	select()

/// Main action opens the construction UI.
/datum/action/ability/activable/xeno/secrete_resin/action_activate()
	. = ..()
	if(!.)
		return
	ui_mode_active = TRUE
	INVOKE_ASYNC(src, PROC_REF(ui_interact), xeno_owner)

/// Undo is intentionally available only while the TGUI construction mode is active.
/datum/action/ability/activable/xeno/secrete_resin/alternate_action_activate()
	if(!ui_mode_active)
		return COMSIG_KB_NOT_ACTIVATED
	step_back()
	return COMSIG_KB_ACTIVATED

/// Secondary key redoes the last UI blueprint operation.
/datum/action/ability/activable/xeno/secrete_resin/proc/secondary_action_activate()
	if(!ui_mode_active)
		return COMSIG_KB_NOT_ACTIVATED
	step_forward()
	return COMSIG_KB_ACTIVATED

/// The base action only knows normal/alternate bindings; route this action's third binding here.
/datum/action/ability/activable/xeno/secrete_resin/keybind_trigger(mob/source, datum/keybinding/kb_type)
	SIGNAL_HANDLER_DOES_SLEEP
	var/signal = kb_type?.keybind_signal
	if(signal == keybinding_signals[KEYBINDING_SECONDARY])
		return secondary_action_activate()
	if(signal == keybinding_signals["pattern_previous"])
		return cycle_pattern(-1)
	if(signal == keybinding_signals["pattern_next"])
		return cycle_pattern(1)
	if(signal == keybinding_signals["toggle_auto_rebuild"])
		return toggle_auto_rebuild_from_keybind()
	if(signal == keybinding_signals["toggle_demolish"])
		return toggle_demolish_from_keybind()
	return ..()

/// Cycle through the same placement pattern order used by the construction catalog.
/datum/action/ability/activable/xeno/secrete_resin/proc/cycle_pattern(direction)
	if(!ui_mode_active || !xeno_owner)
		return COMSIG_KB_NOT_ACTIVATED
	var/list/pattern_ids = list()
	var/list/available_patterns = get_xeno_build_patterns()
	for(var/pattern_id in available_patterns)
		pattern_ids += pattern_id
	var/current_index = pattern_ids.Find(selected_pattern?.id)
	if(!current_index)
		current_index = 1
	current_index += direction
	if(current_index < 1)
		current_index = length(pattern_ids)
	else if(current_index > length(pattern_ids))
		current_index = 1
	var/datum/buildingpattern/new_pattern = get_xeno_build_patterns()[pattern_ids[current_index]]
	if(!new_pattern)
		return COMSIG_KB_ACTIVATED
	selected_pattern = new_pattern
	ensure_selected()
	cleanup_holograms()
	xeno_owner.balloon_alert(xeno_owner, new_pattern.overheadmsg)
	SStgui.update_uis(src)
	return COMSIG_KB_ACTIVATED

/datum/action/ability/activable/xeno/secrete_resin/proc/toggle_auto_rebuild_from_keybind()
	if(!ui_mode_active || !xeno_owner)
		return COMSIG_KB_NOT_ACTIVATED
	auto_rebuild_mode = !auto_rebuild_mode
	ensure_selected()
	xeno_owner.balloon_alert(xeno_owner, auto_rebuild_mode ? "Auto-rebuild enabled" : "Auto-rebuild disabled")
	SStgui.update_uis(src)
	return COMSIG_KB_ACTIVATED

/datum/action/ability/activable/xeno/secrete_resin/proc/toggle_demolish_from_keybind()
	if(!ui_mode_active || !xeno_owner)
		return COMSIG_KB_NOT_ACTIVATED
	demolish_mode = !demolish_mode
	ensure_selected()
	cleanup_holograms()
	xeno_owner.balloon_alert(xeno_owner, demolish_mode ? "Demolition mode" : "Construction mode")
	SStgui.update_uis(src)
	return COMSIG_KB_ACTIVATED

/datum/action/ability/activable/xeno/secrete_resin/proc/select_entry(datum/xeno_build_entry/entry)
	if(!entry)
		return
	xeno_owner.selected_resin = entry.path
	xeno_owner.balloon_alert(xeno_owner, entry.name)
	update_button_icon()

/datum/action/ability/activable/xeno/secrete_resin/proc/get_selected_entry()
	var/datum/xeno_build_entry/entry = get_xeno_build_catalog()["[xeno_owner.selected_resin]"]
	if(!entry || entry.unavailable_reason(xeno_owner))
		return null
	return entry

/datum/action/ability/activable/xeno/secrete_resin/use_ability(atom/A)
	INVOKE_ASYNC(src, PROC_REF(act_on_turf), get_turf(A))

/// Handles one click, expanding it to the selected pattern.
/datum/action/ability/activable/xeno/secrete_resin/proc/can_build_directly()
	return !ghost_mode

/datum/action/ability/activable/xeno/secrete_resin/proc/act_on_turf(turf/T)
	if(!T || !xeno_owner)
		return
	var/list/turfs = get_target_turfs(T)
	if(!length(turfs))
		xeno_owner.balloon_alert(xeno_owner, "no valid ground found")
		return

	var/datum/xeno_build_entry/entry
	var/direct = FALSE
	if(!demolish_mode)
		entry = get_selected_entry()
		if(!entry)
			xeno_owner.balloon_alert(xeno_owner, "select a structure")
			return
		direct = can_build_directly() && (length(turfs) == 1 || xeno_owner.can_pattern_build())

	// Only the UI construction mode keeps an undo history.
	var/record_history = ui_mode_active && (demolish_mode || (entry && entry.kind != BUILD_KIND_PSYCHIC))
	if(ui_mode_active && !record_history)
		clear_history() // Psychic purchases have their own economy and are not reversible.
	var/list/before_states = list()
	if(record_history)
		for(var/turf/target AS in turfs)
			before_states += list(xeno_owner.capture_construction_state(target))

	if(demolish_mode)
		for(var/turf/target AS in turfs)
			xeno_owner.place_demolish_blueprint(target)
	else
		for(var/turf/target AS in turfs)
			var/obj/effect/xeno_blueprint/bp = locate() in target
			if(bp && !bp.is_demolish && bp.entry == entry && bp.auto_rebuild == auto_rebuild_mode)
				if(direct)
					xeno_owner.try_build_blueprint(bp)
				continue
			if(xeno_owner.get_blueprint_state(target, entry) == BP_STATE_BLOCKED)
				continue
			if(!direct || xeno_owner.get_blueprint_state(target, entry) != BP_STATE_FREE)
				xeno_owner.place_blueprint(target, entry, auto_rebuild_mode)
				continue
			if(xeno_owner.place_blueprint(target, entry, auto_rebuild_mode))
				xeno_owner.try_build_blueprint(locate(/obj/effect/xeno_blueprint) in target)
			else if(bp) // A click on another blueprint builds the blueprint already there.
				xeno_owner.try_build_blueprint(bp)

	if(record_history)
		var/list/changes = list()
		for(var/i in 1 to length(before_states))
			var/list/before_state = before_states[i]
			var/turf/current_turf = locate(before_state["x"], before_state["y"], before_state["z"])
			var/list/after_state = xeno_owner.capture_construction_state(current_turf)
			if(!xeno_owner.construction_states_equal(before_state, after_state))
				changes += list(list("x" = before_state["x"], "y" = before_state["y"], "z" = before_state["z"], "before" = before_state, "after" = after_state))
		if(length(changes))
			push_action(new /datum/xeno_building_action(changes))
			SStgui.update_uis(src)

// ---------------------------------------------------------------------------
// Holograms: green = can build now, blue = blueprint, red = blocked.
// ---------------------------------------------------------------------------
/datum/action/ability/activable/xeno/secrete_resin/on_selection()
	RegisterSignal(owner, COMSIG_MOB_CLICKON, PROC_REF(handle_click))
	RegisterSignal(owner, COMSIG_MOB_CLICK_RIGHT, PROC_REF(handle_right_click))
	RegisterSignal(owner, COMSIG_ATOM_MOUSE_ENTERED, PROC_REF(show_hologram_call))

/datum/action/ability/activable/xeno/secrete_resin/on_deselection()
	ui_mode_active = FALSE
	clear_history()
	if(owner)
		UnregisterSignal(owner, list(COMSIG_MOB_CLICKON, COMSIG_MOB_CLICK_RIGHT, COMSIG_ATOM_MOUSE_ENTERED))
		SStgui.update_uis(src)
	cleanup_holograms()

/datum/action/ability/activable/xeno/secrete_resin/proc/show_hologram_call(datum/source, atom/target)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(show_hologram), target)

/datum/action/ability/activable/xeno/secrete_resin/proc/show_hologram(atom/target)
	var/list/target_turfs = get_target_turfs(target)
	if(!length(target_turfs))
		cleanup_holograms()
		return
	var/datum/xeno_build_entry/entry = demolish_mode ? null : get_selected_entry()
	if(!demolish_mode && !entry)
		cleanup_holograms()
		return
	var/create_new = length(holograms) != length(target_turfs)
	if(create_new)
		cleanup_holograms()
	var/index = 1
	for(var/turf/target_turf AS in target_turfs)
		if(create_new)
			create_hologram(target_turf)
		else
			var/obj/effect/hologram = holograms[index]
			hologram.abstract_move(target_turf)
		tint_hologram(holograms[index], target_turf, entry)
		index++
	delete_timer()
	cleanup_timer = addtimer(CALLBACK(src, PROC_REF(cleanup_holograms)), cleanup_time, TIMER_STOPPABLE)

/datum/action/ability/activable/xeno/secrete_resin/proc/tint_hologram(obj/effect/hologram, turf/target_turf, datum/xeno_build_entry/entry)
	hologram.remove_filter("state_filter")
	var/color
	if(demolish_mode)
		color = get_demolish_target(target_turf) ? rgb(233, 23, 23) : rgb(120, 120, 120)
	else
		switch(xeno_owner.get_blueprint_state(target_turf, entry))
			if(BP_STATE_FREE)
				color = ghost_mode ? rgb(74, 168, 255) : rgb(60, 220, 60)
			if(BP_STATE_GHOST)
				color = rgb(74, 168, 255)
			else
				color = rgb(233, 23, 23)
	hologram.add_filter("state_filter", 1, color_matrix_filter(color))

/datum/action/ability/activable/xeno/secrete_resin/proc/create_hologram(turf/target_turf)
	var/atom/selected = demolish_mode ? /turf/closed/wall/resin/regenerating : xeno_owner.selected_resin
	var/obj/effect/build_hologram/hologram = new(target_turf, selected, FALSE, xeno_owner)
	hologram.alpha = 0
	hologram.layer = initial(selected.layer) + 1
	hologram.step_size = 4 * ICON_SIZE_ALL
	animate(hologram, 1 SECONDS, alpha = initial(hologram.alpha))
	holograms += hologram

/datum/action/ability/activable/xeno/secrete_resin/proc/delete_timer()
	deltimer(cleanup_timer)
	cleanup_timer = null

/datum/action/ability/activable/xeno/secrete_resin/proc/cleanup_holograms()
	delete_timer()
	QDEL_LIST(holograms)

/// Left click places the selected pattern. This signal handler itself never sleeps.
/datum/action/ability/activable/xeno/secrete_resin/proc/handle_click(datum/source, atom/target, params)
	SIGNAL_HANDLER
	var/list/modifiers = params2list(params)
	if(modifiers[BUTTON] != LEFT_CLICK || modifiers[SHIFT_CLICK] || modifiers[CTRL_CLICK] || modifiers[ALT_CLICK] || modifiers[MIDDLE_CLICK])
		return
	if(!xeno_owner || xeno_owner.selected_ability != src)
		return
	INVOKE_ASYNC(src, PROC_REF(act_on_turf), get_turf(target))
	return COMSIG_MOB_CLICK_CANCELED

/// Right click deselects the ability and suppresses the normal right-click interaction.
/datum/action/ability/activable/xeno/secrete_resin/proc/handle_right_click(datum/source, atom/target)
	SIGNAL_HANDLER
	if(!xeno_owner || xeno_owner.selected_ability != src)
		return
	ui_mode_active = FALSE
	SStgui.close_user_uis(xeno_owner, src)
	if(xeno_owner.selected_ability == src)
		deselect()
	return COMSIG_MOB_CLICK_HANDLED

/// Redo (secondary key): reapply the most recently undone construction edit.
/datum/action/ability/activable/xeno/secrete_resin/proc/step_forward()
	if(!ui_mode_active)
		return FALSE
	if(!length(redo_stack))
		xeno_owner.balloon_alert(xeno_owner, "Nothing to redo")
		return FALSE
	var/datum/xeno_building_action/action = redo_stack[redo_stack.len]
	if(!action.redo(xeno_owner))
		xeno_owner.balloon_alert(xeno_owner, "cannot redo: construction changed")
		return FALSE
	redo_stack.Cut(redo_stack.len)
	undo_stack += action
	SStgui.update_uis(src)
	xeno_owner.balloon_alert(xeno_owner, "Redo")
	return TRUE

/// Undo (alternate key): restore the previous blueprint state.
/datum/action/ability/activable/xeno/secrete_resin/proc/step_back()
	if(!ui_mode_active)
		return FALSE
	if(!length(undo_stack))
		xeno_owner.balloon_alert(xeno_owner, "Nothing to undo")
		return FALSE
	var/datum/xeno_building_action/action = undo_stack[undo_stack.len]
	if(!action.undo(xeno_owner))
		xeno_owner.balloon_alert(xeno_owner, "cannot undo: construction changed")
		return FALSE
	undo_stack.Cut(undo_stack.len)
	redo_stack += action
	SStgui.update_uis(src)
	xeno_owner.balloon_alert(xeno_owner, "Undo")
	return TRUE

/// Record an action and discard the redo branch.
/datum/action/ability/activable/xeno/secrete_resin/proc/push_action(datum/xeno_building_action/action)
	if(!action || !ui_mode_active)
		qdel(action)
		return
	for(var/datum/xeno_building_action/redo_action AS in redo_stack)
		qdel(redo_action)
	redo_stack.Cut()
	undo_stack += action
	while(length(undo_stack) > max_history)
		qdel(undo_stack[1])
		undo_stack.Cut(1, 2)

/datum/action/ability/activable/xeno/secrete_resin/proc/clear_history()
	for(var/datum/xeno_building_action/action AS in undo_stack)
		qdel(action)
	for(var/datum/xeno_building_action/action AS in redo_stack)
		qdel(action)
	undo_stack.Cut()
	redo_stack.Cut()

/// Cells of the selected pattern, centered on the clicked turf.
/datum/action/ability/activable/xeno/secrete_resin/proc/get_target_turfs(atom/A)
	var/turf/source = get_turf(A)
	if(!source || !selected_pattern)
		return list()
	var/starty = source.y + selected_pattern.offset_y
	var/list/turfs = list()
	for(var/layer in selected_pattern.pattern)
		var/iterx = source.x + selected_pattern.offset_x
		for(var/tile in splittext(layer, ""))
			if(tile == "X")
				var/turf/target = locate(iterx, starty, source.z)
				if(target)
					turfs += target
			iterx--
		starty++
	return turfs


/datum/action/ability/xeno_action/pheromones
	name = "Emit Pheromones"
	desc = "Opens your pheromone options."
	action_icon_state = "emit_pheromones"
	action_icon = 'icons/Xeno/actions/general.dmi'
	ability_cost = 30
	use_state_flags = ABILITY_USE_STAGGERED|ABILITY_USE_NOTTURF|ABILITY_USE_BUSY|ABILITY_USE_LYING|ABILITY_USE_BUCKLED

/datum/action/ability/xeno_action/pheromones/proc/apply_pheros(phero_choice)
	if(xeno_owner.current_aura && xeno_owner.current_aura.aura_types[1] == phero_choice)
		xeno_owner.balloon_alert(xeno_owner, "Stop emitting")
		QDEL_NULL(xeno_owner.current_aura)
		if(xeno_owner.hive?.living_xeno_ruler == xeno_owner)
			xeno_owner.hive?.update_leader_pheromones()
		xeno_owner.hud_set_pheromone()
		return fail_activate()
	QDEL_NULL(xeno_owner.current_aura)
	xeno_owner.current_aura = SSaura.add_emitter(xeno_owner, phero_choice, 6 + xeno_owner.xeno_caste.aura_strength * 2, xeno_owner.xeno_caste.aura_strength, -1, xeno_owner.faction, xeno_owner.hivenumber)
	xeno_owner.balloon_alert(xeno_owner, "[phero_choice]")
	playsound(xeno_owner.loc, SFX_ALIEN_DROOL, 25)

	if(xeno_owner.hive?.living_xeno_ruler == xeno_owner)
		xeno_owner.hive?.update_leader_pheromones()
	xeno_owner.hud_set_pheromone() //Visual feedback that the xeno has immediately started emitting pheromones
	succeed_activate()

/datum/action/ability/xeno_action/pheromones/action_activate()
	var/phero_choice = show_radial_menu(owner, owner, GLOB.pheromone_images_list, radius = 35)
	if(!phero_choice)
		return fail_activate()
	apply_pheros(phero_choice)

/datum/action/ability/xeno_action/pheromones/emit_recovery
	name = "Toggle Recovery Pheromones"
	desc = "Increases healing for yourself and nearby teammates."
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_EMIT_RECOVERY,
	)
	hidden = TRUE

/datum/action/ability/xeno_action/pheromones/emit_recovery/action_activate()
	apply_pheros(AURA_XENO_RECOVERY)

/datum/action/ability/xeno_action/pheromones/emit_warding
	name = "Toggle Warding Pheromones"
	desc = "Increases armor for yourself and nearby teammates."
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_EMIT_WARDING,
	)
	hidden = TRUE

/datum/action/ability/xeno_action/pheromones/emit_warding/action_activate()
	apply_pheros(AURA_XENO_WARDING)

/datum/action/ability/xeno_action/pheromones/emit_frenzy
	name = "Toggle Frenzy Pheromones"
	desc = "Increases damage for yourself and nearby teammates."
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_EMIT_FRENZY,
	)
	hidden = TRUE

/datum/action/ability/xeno_action/pheromones/emit_frenzy/action_activate()
	apply_pheros(AURA_XENO_FRENZY)

/datum/action/ability/activable/xeno/transfer_plasma
	name = "Transfer Plasma"
	desc = "Give some of your plasma to a teammate."
	action_icon_state = "transfer_plasma"
	action_icon = 'icons/Xeno/actions/drone.dmi'
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_TRANSFER_PLASMA,
	)
	target_flags = ABILITY_MOB_TARGET
	var/plasma_transfer_amount = PLASMA_TRANSFER_AMOUNT
	var/transfer_delay = 2 SECONDS
	var/max_range = 2

/datum/action/ability/activable/xeno/transfer_plasma/can_use_ability(atom/A, silent = FALSE, override_flags)
	. = ..()
	if(!.)
		return FALSE

	if(!isxeno(A) || A == xeno_owner || !owner.issamexenohive(A))
		return FALSE

	var/mob/living/carbon/xenomorph/target = A

	if(!(target.xeno_caste.can_flags & CASTE_CAN_BE_GIVEN_PLASMA))
		if(!silent)
			to_chat(owner, span_warning("We can't give that caste plasma."))
			return FALSE

	if(get_dist(owner, target) > max_range)
		if(!silent)
			to_chat(owner, span_warning("We need to be closer to [target]."))
		return FALSE

	if(target.plasma_stored >= target.xeno_caste.plasma_max) //We can't select targets that won't benefit
		to_chat(owner, span_xenowarning("[target] already has full plasma."))
		return FALSE

/datum/action/ability/activable/xeno/transfer_plasma/use_ability(atom/A)
	var/mob/living/carbon/xenomorph/target = A

	to_chat(xeno_owner, span_notice("We start focusing our plasma towards [target]."))
	new /obj/effect/temp_visual/transfer_plasma(get_turf(xeno_owner)) //Cool SFX that confirms our source and our target
	new /obj/effect/temp_visual/transfer_plasma(get_turf(target)) //Cool SFX that confirms our source and our target
	playsound(xeno_owner, SFX_ALIEN_DROOL, 25)

	xeno_owner.face_atom(target) //Face our target so we don't look silly

	if(!do_after(xeno_owner, transfer_delay, NONE, null, BUSY_ICON_FRIENDLY))
		return fail_activate()

	if(!can_use_ability(A))
		return fail_activate()

	target.beam(xeno_owner,"drain_life", time = 1 SECONDS, maxdistance = 10) //visual SFX
	target.add_filter("transfer_plasma_outline", 3, outline_filter(1, COLOR_STRONG_MAGENTA))
	addtimer(CALLBACK(target, TYPE_PROC_REF(/datum, remove_filter), "transfer_plasma_outline"), 1 SECONDS) //Failsafe blur removal

	var/amount = plasma_transfer_amount
	if(xeno_owner.plasma_stored < plasma_transfer_amount)
		amount = xeno_owner.plasma_stored //Just use all of it

	else //Otherwise transfer as much as the target can use
		amount = clamp(target.xeno_caste.plasma_max - target.plasma_stored, 0, plasma_transfer_amount)

	xeno_owner.use_plasma(amount)
	target.gain_plasma(amount)
	to_chat(target, span_xenodanger("[xeno_owner] has transfered [amount] units of plasma to us. We now have [target.plasma_stored]/[target.xeno_caste.plasma_max]."))
	to_chat(xeno_owner, span_xenodanger("We have transferred [amount] units of plasma to [target]. We now have [xeno_owner.plasma_stored]/[xeno_owner.xeno_caste.plasma_max]."))
	playsound(xeno_owner, SFX_ALIEN_DROOL, 25)


// ***************************************
// *********** Corrosive Acid
// ***************************************

/datum/action/ability/activable/xeno/corrosive_acid
	name = "Corrosive Acid"
	desc = "Cover an object with acid to slowly melt it. Takes a few seconds."
	action_icon_state = "corrosive_acid"
	action_icon = 'icons/Xeno/actions/general.dmi'
	ability_cost = 100
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_CORROSIVE_ACID,
	)
	use_state_flags = ABILITY_USE_BUCKLED
	/// How much to reduce acid delay? Lower is faster. Multiplicative.
	var/acid_speed_multiplier = 1
	var/obj/effect/xenomorph/acid/acid_type = /obj/effect/xenomorph/acid

/datum/action/ability/activable/xeno/corrosive_acid/can_use_ability(atom/A, silent = FALSE, override_flags)
	var/obj/effect/xenomorph/acid/current_acid_type = acid_type
	if(SSmonitor.gamestate == SHUTTERS_CLOSED && CHECK_BITFIELD(SSticker.mode?.round_type_flags, MODE_ALLOW_XENO_QUICKBUILD) && SSresinshaping.active)
		if(!is_near_survivor(A))
			current_acid_type = /obj/effect/xenomorph/acid/strong //if it is before shutters open, everyone gets strong acid
	// Check if it's an acid object we're upgrading
	if (istype(A, /obj/effect/xenomorph/acid))
		var/obj/effect/xenomorph/acid/existing_acid = A
		A = existing_acid.acid_t // Swap the target to the target of the acid
	. = ..()
	if(!.)
		return FALSE
	if(!owner.Adjacent(A))
		if(!silent)
			owner.balloon_alert(owner, "[A] is too far away")
		return FALSE
	if(ismob(A))
		if(!silent)
			owner.balloon_alert(owner, "We can't melt [A]")
		return FALSE
	switch(A.should_apply_acid(current_acid_type::acid_strength))
		if(ATOM_CANNOT_ACID)
			if(!silent)
				owner.balloon_alert(owner, "We cannot dissolve [A]")
			return FALSE
		if(ATOM_STRONGER_ACID)
			if(!silent)
				owner.balloon_alert(owner, "[A] is already subject to a more or equally powerful acid")
			return FALSE

/datum/action/ability/activable/xeno/corrosive_acid/use_ability(atom/A)
	var/obj/effect/xenomorph/acid/current_acid_type = acid_type
	// Check if it's an acid object we're upgrading
	if(istype(A, /obj/effect/xenomorph/acid))
		var/obj/effect/xenomorph/acid/existing_acid = A
		A = existing_acid.acid_t // Swap the target to the target of the acid


	var/aciddelay = max(0, A.get_acid_delay() * acid_speed_multiplier);
	if(SSmonitor.gamestate == SHUTTERS_CLOSED && CHECK_BITFIELD(SSticker.mode?.round_type_flags, MODE_ALLOW_XENO_QUICKBUILD) && SSresinshaping.active)
		if(!is_near_survivor(A))
			current_acid_type = /obj/effect/xenomorph/acid/strong //if it is before shutters open, everyone gets strong acid
			aciddelay = 0

	if(!A.dissolvability(current_acid_type::acid_strength))
		return fail_activate()

	xeno_owner.face_atom(A)
	to_chat(xeno_owner, span_xenowarning("We begin generating enough acid to melt through the [A]"))

	if(!do_after(xeno_owner, aciddelay, NONE, A, BUSY_ICON_HOSTILE))
		return fail_activate()

	if(!can_use_ability(A, TRUE))
		return fail_activate()

	new current_acid_type(get_turf(A), A, A.dissolvability(current_acid_type::acid_strength))
	succeed_activate()

	if(!isturf(A))
		log_combat(xeno_owner, A, "spat on", addition="with corrosive acid")
	xeno_owner.visible_message(span_xenowarning("\The [xeno_owner] vomits globs of vile stuff all over \the [A]. It begins to sizzle and melt under the bubbling mess of acid!"), \
	span_xenowarning("We vomit globs of vile stuff all over \the [A]. It begins to sizzle and melt under the bubbling mess of acid!"), null, 5)
	playsound(xeno_owner.loc, 'sound/bullets/acid_impact1.ogg', 25)

// ***************************************
// *********** Super strong acid
// ***************************************

/datum/action/ability/activable/xeno/corrosive_acid/strong
	name = "Corrosive Acid"
	ability_cost = 200
	acid_type = /obj/effect/xenomorph/acid/strong

/datum/action/ability/activable/xeno/spray_acid
	action_icon = 'icons/Xeno/actions/boiler.dmi'
	action_icon_state = "spray_acid"
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_SPRAY_ACID,
	)
	use_state_flags = ABILITY_USE_BUCKLED

/datum/action/ability/activable/xeno/spray_acid/can_use_ability(atom/A, silent = FALSE, override_flags)
	. = ..()
	if(!.)
		return FALSE
	if(!A)
		return FALSE

	var/turf/T = get_turf(owner)
	var/turf/T2 = get_turf(A)
	if(T == T2)
		if(!silent)
			to_chat(owner, span_warning("That's far too close!"))
		return FALSE

/datum/action/ability/activable/xeno/spray_acid/on_cooldown_finish()
	playsound(owner.loc, 'sound/voice/alien/drool1.ogg', 50, 1)
	to_chat(owner, span_xenodanger("We feel our acid glands refill. We can spray acid again."))
	return ..()

/datum/action/ability/activable/xeno/spray_acid/proc/acid_splat_turf(turf/T)
	. = locate(/obj/effect/xenomorph/spray) in T
	if(!.)
		. = new /obj/effect/xenomorph/spray(T, xeno_owner.xeno_caste.acid_spray_duration, xeno_owner.xeno_caste.acid_spray_damage, xeno_owner)

		for(var/i in T)
			var/atom/A = i
			if(!A)
				continue
			A.acid_spray_act(owner)

/datum/action/ability/activable/xeno/xeno_spit
	name = "Xeno Spit"
	desc = "Spit neurotoxin or acid at your target up to 7 tiles away."
	action_icon_state = "neurotoxin"
	action_icon = 'icons/Xeno/actions/spit.dmi'
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_XENO_SPIT,
	)
	use_state_flags = ABILITY_USE_LYING|ABILITY_USE_BUCKLED|ABILITY_DO_AFTER_ATTACK|ABILITY_USE_STAGGERED
	target_flags = ABILITY_MOB_TARGET
	///Current target that the xeno is targeting. This is for aiming.
	var/current_target

/datum/action/ability/activable/xeno/xeno_spit/give_action(mob/living/L)
	. = ..()
	owner.AddComponent(/datum/component/automatedfire/autofire, get_cooldown(), _fire_mode = GUN_FIREMODE_AUTOMATIC,  _callback_reset_fire = CALLBACK(src, PROC_REF(reset_fire)), _callback_fire = CALLBACK(src, PROC_REF(fire)))

/datum/action/ability/activable/xeno/xeno_spit/remove_action(mob/living/L)
	clean_target()
	qdel(owner.GetComponent(/datum/component/automatedfire/autofire))
	return ..()

/datum/action/ability/activable/xeno/xeno_spit/update_button_icon()
	if(xeno_owner)
		action_icon_state = "[initial(xeno_owner.ammo.icon_state)]"
	return ..()

/datum/action/ability/activable/xeno/xeno_spit/action_activate()
	if(xeno_owner.selected_ability != src)
		RegisterSignal(xeno_owner, COMSIG_MOB_MOUSEDRAG, PROC_REF(change_target))
		RegisterSignal(xeno_owner, COMSIG_MOB_MOUSEUP, PROC_REF(stop_fire))
		RegisterSignal(xeno_owner, COMSIG_MOB_MOUSEDOWN, PROC_REF(start_fire))
		return ..()
	for(var/i in 1 to length(xeno_owner.xeno_caste.spit_types))
		if(xeno_owner.ammo == GLOB.ammo_list[xeno_owner.xeno_caste.spit_types[i]])
			if(i == length(xeno_owner.xeno_caste.spit_types))
				xeno_owner.ammo = GLOB.ammo_list[xeno_owner.xeno_caste.spit_types[1]]
				break
			xeno_owner.ammo = GLOB.ammo_list[xeno_owner.xeno_caste.spit_types[i+1]]
			break
	to_chat(xeno_owner, span_notice("We will now spit [xeno_owner.ammo.name] ([xeno_owner.ammo.spit_cost] plasma)."))
	xeno_owner.update_spits(TRUE)
	update_button_icon()

/datum/action/ability/activable/xeno/xeno_spit/deselect()
	UnregisterSignal(owner, list(COMSIG_MOB_MOUSEUP, COMSIG_MOB_MOUSEDRAG, COMSIG_MOB_MOUSEDOWN))
	return ..()

/datum/action/ability/activable/xeno/xeno_spit/can_use_ability(atom/A, silent = FALSE, override_flags)
	. = ..()
	if(!.)
		return FALSE
	if(!xeno_owner.check_state())
		return FALSE
	if(xeno_owner.ammo?.spit_cost > xeno_owner.plasma_stored)
		if(!silent)
			to_chat(xeno_owner, span_warning("We need [xeno_owner.ammo?.spit_cost - xeno_owner.plasma_stored] more plasma!"))
		return FALSE

/datum/action/ability/activable/xeno/xeno_spit/get_cooldown()
	return (xeno_owner.xeno_caste.spit_delay + xeno_owner.ammo?.added_spit_delay)

/datum/action/ability/activable/xeno/xeno_spit/on_cooldown_finish()
	to_chat(xeno_owner, span_notice("We feel our neurotoxin glands swell with ichor. We can spit again."))
	return ..()

/datum/action/ability/activable/xeno/xeno_spit/use_ability(atom/A)
	if(owner.client) //If its not an ai it will register to listen for clicks instead of use this proc. We want to call start_fire from here only if the owner is an ai.
		return
	start_fire(object = A, can_use_ability_flags = ABILITY_IGNORE_SELECTED_ABILITY)

///Starts the xeno firing.
/datum/action/ability/activable/xeno/xeno_spit/proc/start_fire(datum/source, atom/object, turf/location, control, params, can_use_ability_flags)
	SIGNAL_HANDLER
	var/list/modifiers = params2list(params)
	if(((modifiers["right"] || modifiers["middle"]) && (modifiers["shift"] || modifiers["ctrl"] || modifiers["left"])) || \
	((modifiers["left"] && modifiers["shift"]) && (modifiers["ctrl"] || modifiers["middle"] || modifiers["right"])) || \
	(modifiers["left"] && !modifiers["shift"]))
		return
	if(!can_use_ability(object, TRUE, can_use_ability_flags))
		return fail_activate()
	if(QDELETED(object))
		return
	set_target(get_turf_on_clickcatcher(object, xeno_owner, params))
	if(!current_target)
		return

	SEND_SIGNAL(owner, COMSIG_XENO_FIRE)
	xeno_owner?.client?.mouse_pointer_icon = 'icons/effects/xeno_target.dmi'

///Fires the spit projectile.
/datum/action/ability/activable/xeno/xeno_spit/proc/fire()
	var/turf/current_turf = get_turf(owner)
	var/sound_to_play = pick(1, 2) == 1 ? 'sound/voice/alien/spitacid.ogg' : 'sound/voice/alien/spitacid2.ogg'
	playsound(xeno_owner.loc, sound_to_play, 25, 1)

	var/atom/movable/projectile/newspit = new /atom/movable/projectile(current_turf)
	ability_cost = xeno_owner.ammo.spit_cost
	var/spit_damage = xeno_owner.ammo.damage * SPIT_UPGRADE_BONUS(xeno_owner)
	if(xeno_owner.is_hivemind_ai_minion())
		spit_damage *= HIVEMIND_MINION_RANGED_DAMAGE_MULTIPLIER
	newspit.generate_bullet(xeno_owner.ammo, spit_damage)
	if(xeno_owner.is_hivemind_ai_minion() && ishuman(current_target))
		newspit.accuracy = max(5, newspit.accuracy - HIVEMIND_MINION_RANGED_ACCURACY_PENALTY)
	newspit.def_zone = xeno_owner.get_limbzone_target()
	newspit.fire_at(current_target, xeno_owner, xeno_owner, xeno_owner.ammo.max_range, xeno_owner.ammo.shell_speed)

	if(can_use_ability(current_target) && xeno_owner.client) //xeno_owner.client to make sure autospit doesn't continue for non player mobs.
		succeed_activate()
		return AUTOFIRE_CONTINUE
	fail_activate()
	return NONE

///Resets the autofire component.
/datum/action/ability/activable/xeno/xeno_spit/proc/reset_fire()
	set_target(null)
	owner?.client?.mouse_pointer_icon = initial(owner.client.mouse_pointer_icon)

///Changes the current target.
/datum/action/ability/activable/xeno/xeno_spit/proc/change_target(datum/source, atom/src_object, atom/over_object, turf/src_location, turf/over_location, src_control, over_control, params)
	SIGNAL_HANDLER
	set_target(get_turf_on_clickcatcher(over_object, xeno_owner, params))
	xeno_owner.face_atom(current_target)

///Sets the current target and registers for qdel to prevent hardels
/datum/action/ability/activable/xeno/xeno_spit/proc/set_target(atom/object)
	if(object == current_target || object == xeno_owner)
		return
	if(current_target)
		UnregisterSignal(current_target, COMSIG_QDELETING)
	current_target = object
	if(current_target)
		RegisterSignal(current_target, COMSIG_QDELETING, PROC_REF(clean_target))

///Cleans the current target in case of Hardel
/datum/action/ability/activable/xeno/xeno_spit/proc/clean_target()
	SIGNAL_HANDLER
	current_target = null

///Stops the Autofire component and resets the current cursor.
/datum/action/ability/activable/xeno/xeno_spit/proc/stop_fire()
	SIGNAL_HANDLER
	xeno_owner?.client?.mouse_pointer_icon = initial(xeno_owner.client.mouse_pointer_icon)
	SEND_SIGNAL(xeno_owner, COMSIG_XENO_STOP_FIRE)

/datum/action/ability/activable/xeno/xeno_spit/ai_should_start_consider()
	return TRUE

/datum/action/ability/activable/xeno/xeno_spit/ai_should_use(atom/target)
	if(!iscarbon(target))
		return FALSE
	if(get_dist(target, xeno_owner) > 6)
		return FALSE
	if(!can_use_ability(target, override_flags = ABILITY_IGNORE_SELECTED_ABILITY))
		return FALSE
	if(!line_of_sight(xeno_owner, target))
		return FALSE
	if(target.get_xeno_hivenumber() == xeno_owner.get_xeno_hivenumber())
		return FALSE
	return TRUE

/datum/action/ability/xeno_action/xenohide
	name = "Hide"
	desc = "Causes your sprite to hide behind certain objects and under tables. Not the same as stealth. Does not use plasma."
	action_icon_state = "xenohide"
	action_icon = 'icons/Xeno/actions/general.dmi'
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_HIDE,
	)

/datum/action/ability/xeno_action/xenohide/remove_action(mob/living/L)
	UnregisterSignal(L, list(COMSIG_XENOMORPH_POUNCE, COMSIG_MOB_CRIT, COMSIG_MOB_DEATH))
	return ..()

/datum/action/ability/xeno_action/xenohide/can_use_action(silent, override_flags)
	if(HAS_TRAIT(xeno_owner, TRAIT_TANK_DESANT))
		if(!silent)
			xeno_owner.balloon_alert(xeno_owner, "cannot while on vehicle")
		return FALSE
	return ..()

/datum/action/ability/xeno_action/xenohide/action_activate()
	if(xeno_owner.layer != BELOW_TABLE_LAYER)
		RegisterSignals(xeno_owner, list(COMSIG_XENOMORPH_POUNCE, COMSIG_MOB_CRIT, COMSIG_MOB_DEATH), PROC_REF(unhide))
		xeno_owner.layer = BELOW_TABLE_LAYER
		to_chat(xeno_owner, span_notice("We are now hiding."))
		button.add_overlay(mutable_appearance('icons/Xeno/actions/_actions.dmi', "selected_purple_frame", ACTION_LAYER_ACTION_ICON_STATE, null, FLOAT_PLANE))
	else
		UnregisterSignal(xeno_owner, list(COMSIG_XENOMORPH_POUNCE, COMSIG_MOB_CRIT, COMSIG_MOB_DEATH))
		xeno_owner.layer = MOB_LAYER
		to_chat(xeno_owner, span_notice("We have stopped hiding."))
		button.cut_overlay(mutable_appearance('icons/Xeno/actions/_actions.dmi', "selected_purple_frame", ACTION_LAYER_ACTION_ICON_STATE, null, FLOAT_PLANE))

/datum/action/ability/xeno_action/xenohide/proc/unhide()
	SIGNAL_HANDLER
	UnregisterSignal(xeno_owner, list(COMSIG_XENOMORPH_POUNCE, COMSIG_MOB_CRIT, COMSIG_MOB_DEATH))
	xeno_owner.layer = MOB_LAYER
	to_chat(xeno_owner, span_notice("We have stopped hiding."))
	button.cut_overlay(mutable_appearance('icons/Xeno/actions/_actions.dmi', "selected_purple_frame", ACTION_LAYER_ACTION_ICON_STATE, FLOAT_PLANE))

//Neurotox Sting
/datum/action/ability/activable/xeno/neurotox_sting
	name = "Neurotoxin Sting"
	desc = "A channeled melee attack that injects the target with neurotoxin over a few seconds, temporarily stunning them."
	action_icon_state = "neuro_sting"
	action_icon = 'icons/Xeno/actions/sentinel.dmi'
	cooldown_duration = 12 SECONDS
	ability_cost = 150
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_NEUROTOX_STING,
	)
	target_flags = ABILITY_MOB_TARGET
	use_state_flags = ABILITY_USE_BUCKLED
	/// Whatever our victim is injected with.
	var/sting_chemical = /datum/reagent/toxin/xeno_neurotoxin

/datum/action/ability/activable/xeno/neurotox_sting/can_use_ability(atom/A, silent = FALSE, override_flags)
	. = ..()
	if(!.)
		return FALSE

	if(!A?.can_sting())
		if(!silent)
			to_chat(owner, span_warning("Our sting won't affect this target!"))
		return FALSE
	if(!owner.Adjacent(A))
		if(!silent && world.time > (xeno_owner.recent_notice + xeno_owner.notice_delay)) //anti-notice spam
			to_chat(xeno_owner, span_warning("We can't reach this target!"))
			xeno_owner.recent_notice = world.time //anti-notice spam
		return FALSE
	var/mob/living/carbon/C = A
	if(isnestedhost(C))
		if(!silent)
			to_chat(owner, span_warning("Ashamed, we reconsider bullying the poor, nested host with our stinger."))
		return FALSE

/datum/action/ability/activable/xeno/neurotox_sting/on_cooldown_finish()
	playsound(owner.loc, 'sound/voice/alien/drool1.ogg', 50, 1)
	to_chat(owner, span_xenodanger("We feel our toxic glands refill. We can use our [initial(name)] again."))
	return ..()

/datum/action/ability/activable/xeno/neurotox_sting/use_ability(atom/A)
	succeed_activate()

	add_cooldown()
	xeno_owner.recurring_injection(A, sting_chemical, XENO_NEURO_CHANNEL_TIME, XENO_NEURO_AMOUNT_RECURRING)

	track_stats()

///Adds ability tally to the end-round statistics.
/datum/action/ability/activable/xeno/neurotox_sting/proc/track_stats()
	GLOB.round_statistics.sentinel_neurotoxin_stings++
	SSblackbox.record_feedback(FEEDBACK_TALLY, "round_statistics", 1, "sentinel_neurotoxin_stings")

//Ozelomelyn Sting
/datum/action/ability/activable/xeno/neurotox_sting/ozelomelyn
	name = "Ozelomelyn Sting"
	desc = "A channeled melee attack that injects the target with Ozelomelyn over a few seconds, purging chemicals and dealing minor toxin damage to a moderate cap while inside them."
	action_icon_state = "drone_sting"
	action_icon = 'icons/Xeno/actions/shrike.dmi'
	cooldown_duration = 25 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_OZELOMELYN_STING,
	)
	ability_cost = 100
	sting_chemical = /datum/reagent/toxin/xeno_ozelomelyn

///Adds ability tally to the end-round statistics.
/datum/action/ability/activable/xeno/neurotox_sting/ozelomelyn/track_stats()
	GLOB.round_statistics.ozelomelyn_stings++
	SSblackbox.record_feedback(FEEDBACK_TALLY, "round_statistics", 1, "ozelomelyn_stings")

//Transvitox Sting
/datum/action/ability/activable/xeno/neurotox_sting/transvitox
	name = "Transvitox Sting"
	desc = "A channeled melee attack that injects the target with Transvitox over a few seconds, dealing minor toxin damage to a moderate cap while inside them."
	cooldown_duration = 12 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_OZELOMELYN_STING,
	)
	ability_cost = 120
	sting_chemical = /datum/reagent/toxin/xeno_transvitox

///Adds ability tally to the end-round statistics.
/datum/action/ability/activable/xeno/neurotox_sting/transvitox/track_stats()
	GLOB.round_statistics.transvitox_stings++
	SSblackbox.record_feedback(FEEDBACK_TALLY, "round_statistics", 1, "transvitox_stings")

// ***************************************
// *********** Psychic Whisper
// ***************************************
/datum/action/ability/xeno_action/psychic_whisper
	name = "Psychic Whisper"
	action_icon_state = "psychic_whisper"
	action_icon = 'icons/Xeno/actions/shrike.dmi'
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_PSYCHIC_WHISPER,
	)
	use_state_flags = ABILITY_USE_LYING
	target_flags = ABILITY_MOB_TARGET

/datum/action/ability/xeno_action/psychic_whisper/action_activate()
	var/list/target_list = list()
	for(var/mob/living/possible_target in view(WORLD_VIEW, xeno_owner))
		if(possible_target == xeno_owner || !possible_target.client || isxeno(possible_target))
			continue
		target_list += possible_target

	if(!length(target_list))
		to_chat(xeno_owner, span_warning("There's nobody nearby to whisper to."))
		return

	var/mob/living/L = tgui_input_list(xeno_owner, "Target", "Send a Psychic Whisper to whom?", target_list)
	if(!L)
		return

	if(!xeno_owner.check_state())
		return

	var/msg = stripped_input("Message:", "Psychic Whisper")
	if(!msg)
		return

	log_directed_talk(xeno_owner, L, msg, LOG_SAY, "psychic whisper")
	to_chat(L, span_alien("You hear a strange, alien voice in your head. <i>\"[msg]\"</i>"))
	to_chat(xeno_owner, span_xenonotice("We said: \"[msg]\" to [L]"))
	message_admins("[xeno_owner] has sent [L] this psychic message: \"[msg]\" at [ADMIN_VERBOSEJMP(xeno_owner)].")

// ***************************************
// *********** Lay Egg
// ***************************************
/datum/action/ability/xeno_action/lay_egg
	name = "Lay Egg"
	desc = "Create an egg that will grow a larval hugger after a short delay. Empty eggs can have huggers inserted into them."
	action_icon_state = "lay_egg"
	action_icon = 'icons/Xeno/actions/construction.dmi'
	ability_cost = 200
	cooldown_duration = 12 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_LAY_EGG,
	)
	/// Should the egg contain the owner's selected_hugger_type instead?
	var/use_selected_hugger = FALSE
	/// The amount to multiply the created hugger's hand attach time by.
	var/hand_attach_time_multiplier = 1

/datum/action/ability/xeno_action/lay_egg/action_activate(mob/living/carbon/xenomorph/user)
	var/turf/current_turf = get_turf(xeno_owner)

	if(!current_turf.check_alien_construction(xeno_owner, planned_building = /obj/alien/egg/facehugger))
		return fail_activate()

	if(!xeno_owner.loc_weeds_type)
		to_chat(user, span_xenowarning("Our eggs wouldn't grow well enough here. Lay them on resin."))
		return fail_activate()

	xeno_owner.visible_message(span_xenonotice("[xeno_owner] starts planting an egg."), \
		span_xenonotice("We start planting an egg."), null, 5)

	if(!do_after(xeno_owner, 2.5 SECONDS, NONE, current_turf, BUSY_ICON_BUILD, extra_checks = CALLBACK(current_turf, TYPE_PROC_REF(/turf, check_alien_construction), xeno_owner)))
		return fail_activate()

	if(!xeno_owner.loc_weeds_type)
		return fail_activate()

	new /obj/alien/egg/facehugger(current_turf, xeno_owner.hivenumber, use_selected_hugger ? xeno_owner.selected_hugger_type : null, hand_attach_time_multiplier)
	playsound(current_turf, 'sound/effects/splat.ogg', 15, 1)

	succeed_activate()
	add_cooldown()
	owner.record_traps_created()

////////////////////
/// Rally Hive
///////////////////
/datum/action/ability/xeno_action/rally_hive
	name = "Rally Hive"
	desc = "Rallies the hive to a congregate at a target location, along with an arrow pointer. Gives the Hive your current health status. 60 second cooldown."
	action_icon_state = "rally_hive"
	action_icon = 'icons/Xeno/actions/general.dmi'
	ability_cost = 0
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_RALLY_HIVE,
	)
	keybind_flags = ABILITY_KEYBIND_USE_ABILITY
	cooldown_duration = 60 SECONDS
	use_state_flags = ABILITY_USE_LYING|ABILITY_USE_BUCKLED

/datum/action/ability/xeno_action/rally_hive/action_activate()
	xeno_message("Our leader [xeno_owner] is rallying the hive to [AREACOORD_NO_Z(xeno_owner.loc)]!", "xenoannounce", 6, xeno_owner.hivenumber, FALSE, xeno_owner, 'sound/voice/alien/distantroar_3.ogg',TRUE,null,/atom/movable/screen/arrow/leader_tracker_arrow)
	notify_ghosts("\ [xeno_owner] is rallying the hive to [AREACOORD_NO_Z(xeno_owner.loc)]!", source = xeno_owner, action = NOTIFY_JUMP)

	succeed_activate()
	add_cooldown()

	GLOB.round_statistics.xeno_rally_hive++ //statistics
	SSblackbox.record_feedback(FEEDBACK_TALLY, "round_statistics", 1, "xeno_rally_hive")

// =======================================
// *********** Minion Call
// =======================================

/// Images used by the minion-caste radial selector.
GLOBAL_LIST_INIT(minion_call_images, list(
	"All castes" = image('icons/Xeno/actions/general.dmi', icon_state = "minion_agressive"),
	"Beetle" = get_xeno_type_portrait(/mob/living/carbon/xenomorph/beetle, "Beetle Walking"),
	"Mantis" = get_xeno_type_portrait(/mob/living/carbon/xenomorph/mantis, "Mantis Walking"),
	"Scorpion" = get_xeno_type_portrait(/mob/living/carbon/xenomorph/scorpion, "Scorpion Walking"),
	"Nymph" = get_xeno_type_portrait(/mob/living/carbon/xenomorph/nymph, "Nymph Walking"),
	"Baneling" = get_xeno_type_portrait(/mob/living/carbon/xenomorph/baneling, "Baneling Walking")
))

GLOBAL_LIST_INIT(minion_call_drone_images, list(
	"Nymph" = get_xeno_type_portrait(/mob/living/carbon/xenomorph/nymph, "Nymph Walking")
))

#define MINION_CALL_RADIUS 9
#define MINION_CALL_WAVE_TIME 2 SECONDS
#define MINION_CALL_WAVE_STEP 2

/datum/action/ability/xeno_action/minion_call
	name = "Minion Call"
	desc = "Roar to call nearby AI minions into escort formation. Right-click to choose a caste. Use again to release your minions. Higher-ranked src_callers can take minions from lower-ranked ones."
	action_icon_state = "minion_agressive"
	action_icon = 'icons/Xeno/actions/general.dmi'
	ability_cost = 0
	cooldown_duration = 0
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_RALLY_MINION,
		KEYBINDING_ALTERNATE = COMSIG_XENOABILITY_MINION_BEHAVIOUR,
	)
	keybind_flags = ABILITY_KEYBIND_USE_ABILITY
	use_state_flags = ABILITY_USE_LYING|ABILITY_USE_BUCKLED
	/// Null means every supported AI minion caste; otherwise this is a base mob typepath.
	var/selected_minion_type
	var/call_in_progress = FALSE

/datum/action/ability/xeno_action/minion_call/proc/get_call_priority()
	var/mob/living/carbon/xenomorph/xeno_owner = owner
	if(isxenohivemind(xeno_owner))
		return 1000
	if(isxenoqueen(xeno_owner))
		return 400
	if(isxenoking(xeno_owner) || isxenoshrike(xeno_owner) || istype(xeno_owner, /mob/living/carbon/xenomorph/dragon))
		return 300
	if(xeno_owner && (xeno_owner.xeno_flags & XENO_LEADER))
		return 200
	if(isxenodrone(xeno_owner))
		return 100
	return 0

/datum/action/ability/xeno_action/minion_call/proc/get_call_capacity()
	var/mob/living/carbon/xenomorph/xeno_owner = owner
	if(isxenohivemind(xeno_owner))
		return 20
	if(isxenoqueen(xeno_owner))
		return 12
	if(isxenoking(xeno_owner) || isxenoshrike(xeno_owner) || istype(xeno_owner, /mob/living/carbon/xenomorph/dragon))
		return 8
	if(xeno_owner && (xeno_owner.xeno_flags & XENO_LEADER))
		return 5
	if(isxenodrone(xeno_owner))
		return 2
	return 0

/datum/action/ability/xeno_action/minion_call/proc/get_owned_minions(mob/living/carbon/xenomorph/controller)
	var/list/result = list()
	if(!controller || !controller.hivenumber)
		return result
	for(var/mob/living/carbon/xenomorph/minion AS in GLOB.alive_xeno_list_hive[controller.hivenumber])
		var/datum/component/ai_controller/ai_controller = minion.GetComponent(/datum/component/ai_controller)
		var/datum/ai_behavior/xeno/behavior = ai_controller?.ai_behavior
		if(behavior?.get_minion_call_owner() == controller)
			result += minion
	return result

/datum/action/ability/xeno_action/minion_call/action_activate()
	var/mob/living/carbon/xenomorph/src_caller = owner
	if(!istype(src_caller))
		return

	var/list/attached_minions = get_owned_minions(src_caller)
	if(length(attached_minions))
		call_in_progress = FALSE
		for(var/mob/living/carbon/xenomorph/minion AS in attached_minions)
			var/datum/component/ai_controller/ai_controller = minion.GetComponent(/datum/component/ai_controller)
			var/datum/ai_behavior/xeno/behavior = ai_controller?.ai_behavior
			behavior?.end_minion_call(src_caller)
		src_caller.balloon_alert(src_caller, "Minions released")
		return
	if(call_in_progress)
		call_in_progress = FALSE
		src_caller.balloon_alert(src_caller, "Call cancelled")
		return

	var/capacity = get_call_capacity()
	if(!capacity)
		return
	var/requested_type = selected_minion_type
	if(isxenodrone(src_caller))
		requested_type = /mob/living/carbon/xenomorph/nymph

	call_in_progress = TRUE
	src_caller.emote("roar")
	new /obj/effect/temp_visual/minion_call_wave(get_turf(src_caller), MINION_CALL_RADIUS)
	INVOKE_ASYNC(src, PROC_REF(do_call_wave), WEAKREF(src_caller), requested_type, get_call_priority(), capacity)
	succeed_activate()

/datum/action/ability/xeno_action/minion_call/proc/do_call_wave(datum/weakref/src_caller_ref, requested_type, requested_priority, capacity)
	var/mob/living/carbon/xenomorph/calling_xeno = src_caller_ref?.resolve()
	if(!calling_xeno || QDELETED(calling_xeno) || calling_xeno.stat == DEAD)
		call_in_progress = FALSE
		return
	var/attached_count = length(get_owned_minions(calling_xeno))
	for(var/radius in 0 to MINION_CALL_RADIUS)
		if(!call_in_progress)
			return
		calling_xeno = src_caller_ref?.resolve()
		if(!calling_xeno || QDELETED(calling_xeno) || calling_xeno.stat == DEAD)
			call_in_progress = FALSE
			return
		if(attached_count >= capacity)
			break
		for(var/mob/living/carbon/xenomorph/minion AS in GLOB.alive_xeno_list_hive[calling_xeno.hivenumber])
			if(minion == calling_xeno || minion.stat == DEAD || minion.z != calling_xeno.z || get_dist(minion, calling_xeno) != radius)
				continue
			// Minions born from a Widow are permanently hers and cannot be reassigned by a call.
			if(minion.widow_personal_minion)
				continue
			if(!minion.is_hivemind_ai_minion())
				continue
			if(isxenodrone(calling_xeno) && !istype(minion, /mob/living/carbon/xenomorph/nymph))
				continue
			if(requested_type && !istype(minion, requested_type))
				continue
			var/datum/component/ai_controller/ai_controller = minion.GetComponent(/datum/component/ai_controller)
			var/datum/ai_behavior/xeno/behavior = ai_controller?.ai_behavior
			if(!behavior || !behavior.can_be_called_by(calling_xeno, requested_priority))
				continue
			if(behavior.begin_minion_call(calling_xeno, requested_priority))
				attached_count++
				if(attached_count >= capacity)
					break
		if(radius < MINION_CALL_RADIUS)
			sleep(MINION_CALL_WAVE_STEP)
	call_in_progress = FALSE
	var/list/final_minions = get_owned_minions(calling_xeno)
	calling_xeno.balloon_alert(calling_xeno, length(final_minions) ? "Minions called: [length(final_minions)]" : "No minions answered")

/datum/action/ability/xeno_action/minion_call/alternate_action_activate()
	INVOKE_ASYNC(src, PROC_REF(select_minion_type_radial))
	return COMSIG_KB_ACTIVATED

/datum/action/ability/xeno_action/minion_call/proc/select_minion_type_radial()
	var/mob/living/carbon/xenomorph/src_caller = owner
	if(!istype(src_caller))
		return
	var/list/available_types = isxenodrone(src_caller) ? GLOB.minion_call_drone_images : GLOB.minion_call_images
	var/choice = show_radial_menu(src_caller, src_caller, available_types, radius = 48)
	if(!choice)
		return
	if(choice == "All castes")
		selected_minion_type = null
	else
		switch(choice)
			if("Beetle")
				selected_minion_type = /mob/living/carbon/xenomorph/beetle
			if("Mantis")
				selected_minion_type = /mob/living/carbon/xenomorph/mantis
			if("Scorpion")
				selected_minion_type = /mob/living/carbon/xenomorph/scorpion
			if("Nymph")
				selected_minion_type = /mob/living/carbon/xenomorph/nymph
			if("Baneling")
				selected_minion_type = /mob/living/carbon/xenomorph/baneling
	src_caller.balloon_alert(src_caller, "Minion type: [choice]")

/obj/effect/temp_visual/minion_call_wave
	name = "minion call wave"
	icon = 'icons/effects/blips.dmi'
	icon_state = "SL_locator_near"
	duration = MINION_CALL_WAVE_TIME
	plane = GAME_PLANE
	layer = ABOVE_NORMAL_TURF_LAYER
	randomdir = FALSE
	color = list(
		0, 0, 0, 0, 1,
		0, 0, 0, 0, 1,
		0, 0, 0, 0, 1,
		0, 0, 0, 1, 0
	)

/obj/effect/temp_visual/minion_call_wave/Initialize(mapload, max_radius)
	. = ..()
	transform = matrix().Scale(0.1)
	animate(src, transform = matrix().Scale(max_radius * 2), alpha = 0, time = duration, easing = QUAD_EASING|EASE_OUT)

#undef MINION_CALL_RADIUS
#undef MINION_CALL_WAVE_TIME
#undef MINION_CALL_WAVE_STEP

/datum/action/ability/xeno_action/rally_minion
	name = "Rally Minions"
	desc = "Rallies the minions around you, asking them to follow you if they don't have a leader already. Rightclick to change minion behaviour."
	action_icon_state = "minion_agressive"
	action_icon = 'icons/Xeno/actions/general.dmi'
	ability_cost = 0
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_RALLY_MINION,
		KEYBINDING_ALTERNATE = COMSIG_XENOABILITY_MINION_BEHAVIOUR,
	)
	keybind_flags = ABILITY_KEYBIND_USE_ABILITY
	cooldown_duration = 10 SECONDS
	use_state_flags = ABILITY_USE_LYING|ABILITY_USE_BUCKLED
	///If minions should be agressive
	var/minions_agressive = TRUE

/datum/action/ability/xeno_action/rally_minion/update_button_icon()
	action_icon_state = minions_agressive ? "minion_agressive" : "minion_passive"
	return ..()

/datum/action/ability/xeno_action/rally_minion/action_activate()
	succeed_activate()
	add_cooldown()
	owner.emote("roar")
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_AI_MINION_RALLY, owner)
	SEND_SIGNAL(owner, COMSIG_ESCORTING_ATOM_BEHAVIOUR_CHANGED, minions_agressive) //New escorting ais should have the same behaviour as old one

/datum/action/ability/xeno_action/rally_minion/alternate_action_activate()
	minions_agressive = !minions_agressive
	SEND_SIGNAL(owner, COMSIG_ESCORTING_ATOM_BEHAVIOUR_CHANGED, minions_agressive)
	update_button_icon()

/mob/living/carbon/xenomorph/proc/add_abilities()
	for(var/action_path in xeno_caste.actions)
		var/datum/action/ability/xeno_action/action = new action_path(src)
		if(!SSticker.mode || SSticker.mode.xeno_abilities_flags & action.gamemode_flags)
			action.give_action(src)

/mob/living/carbon/xenomorph/proc/remove_abilities()
	for(var/action_datum in mob_abilities)
		qdel(action_datum)

/datum/action/ability/xeno_action/rally_hive/hivemind //Halve the cooldown for Hiveminds as their relative omnipresence means they can actually make use of this lower cooldown.
	cooldown_duration = 30 SECONDS

//*********
// Psy Drain
//*********
/datum/action/ability/activable/xeno/psydrain
	name = "Psy drain"
	desc = "Drain the victim of its life force to gain larva and psych points"
	action_icon_state = "headbite"
	action_icon = 'icons/Xeno/actions/general.dmi'
	use_state_flags = ABILITY_USE_STAGGERED|ABILITY_USE_FORTIFIED|ABILITY_USE_CRESTED //can't use while staggered, defender fortified or crest down
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_HEADBITE,
	)
	gamemode_flags = ABILITY_DISTRESS|ABILITY_CRASH
	ability_cost = 100
	///How much larva points it gives (8 points for one larva in distress)
	var/larva_point_reward = 1

/datum/action/ability/activable/xeno/psydrain/can_use_ability(atom/A, silent = FALSE, override_flags)
	. = ..() //do after checking the below stuff
	if(!.)
		return
	if(!iscarbon(A))
		return FALSE
	var/mob/living/carbon/victim = A //target of ability
	if(xeno_owner.do_actions) //can't use if busy
		return FALSE
	if(!xeno_owner.Adjacent(victim)) //checks if owner next to target
		return FALSE
	if(xeno_owner.on_fire)
		if(!silent)
			to_chat(xeno_owner, span_warning("We're too busy being on fire to do this!"))
		return FALSE
	if(victim.stat != DEAD)
		if(!silent)
			to_chat(xeno_owner, span_warning("This creature is struggling too much for us to drain its life force."))
		return FALSE
	if(HAS_TRAIT(victim, TRAIT_PSY_DRAINED))
		if(!silent)
			to_chat(xeno_owner, span_warning("There is no longer any life force in this creature!"))
		return FALSE
	if(!ishuman(victim))
		if(!silent)
			to_chat(xeno_owner, span_warning("We can't drain something that is not human."))
		return FALSE
	if(issynth(victim)) //checks if target is a synth
		if(!silent)
			to_chat(xeno_owner, span_warning("This artificial construct has no life force to drain"))
		return FALSE
	xeno_owner.face_atom(victim) //Face towards the target so we don't look silly
	xeno_owner.visible_message(span_xenowarning("\The [xeno_owner] begins opening its mouth and extending a second jaw towards \the [victim]."), \
	span_danger("We slowly drain \the [victim]'s life force!"), null, 20)
	var/channel = SSsounds.random_available_channel()
	playsound(xeno_owner, 'sound/magic/nightfall.ogg', 40, channel = channel)
	if(!do_after(xeno_owner, 5 SECONDS, IGNORE_HELD_ITEM, victim, BUSY_ICON_DANGER, extra_checks = CALLBACK(xeno_owner, TYPE_PROC_REF(/mob, break_do_after_checks), list("health" = xeno_owner.health))))
		xeno_owner.visible_message(span_xenowarning("\The [xeno_owner] retracts its inner jaw."), \
		span_danger("We retract our inner jaw."), null, 20)
		xeno_owner.stop_sound_channel(channel)
		return FALSE
	xeno_owner.stop_sound_channel(channel)
	succeed_activate() //dew it

/datum/action/ability/activable/xeno/psydrain/use_ability(mob/M)
	var/mob/living/carbon/victim = M

	if(HAS_TRAIT(victim, TRAIT_PSY_DRAINED))
		to_chat(xeno_owner, span_warning("Someone drained the life force of our victim before we could do it!"))
		return fail_activate()

	playsound(xeno_owner, 'sound/magic/end_of_psy_drain.ogg', 40)

	xeno_owner.visible_message(span_xenodanger("\The [victim]'s life force is drained by \the [xeno_owner]!"), \
	span_xenodanger("We feel \the [victim]'s life force streaming into us!"))

	victim.do_jitter_animation(2)
	victim.adjust_clone_loss(20)

	// Caster gets 5 biomass immediately
	xeno_owner.biomass = min(xeno_owner.biomass + 5, 50)

	// All non-minion xenos in this hive get +0.05 passive biomass gain.
	xeno_owner.hive.biomass_gain_bonus += 0.05

	ADD_TRAIT(victim, TRAIT_PSY_DRAINED, TRAIT_PSY_DRAINED)
	if(HAS_TRAIT(victim, TRAIT_UNDEFIBBABLE))
		victim.med_hud_set_status()
	var/psy_points_reward = PSY_DRAIN_REWARD
	if(HAS_TRAIT(victim, TRAIT_HIVE_TARGET))
		SEND_GLOBAL_SIGNAL(COMSIG_GLOB_HIVE_TARGET_DRAINED, xeno_owner)
		psy_points_reward = psy_points_reward * 3
	SSpoints.add_psy_points(xeno_owner.hivenumber, psy_points_reward)
	GLOB.round_statistics.psypoints_from_psydrain += psy_points_reward

	if(xeno_owner.hivenumber != XENO_HIVE_NORMAL)
		return

	if(SSticker.mode && !CHECK_BITFIELD(SSticker.mode.xeno_abilities_flags, ABILITY_CRASH))
		var/datum/job/xeno_job = SSjob.GetJobType(/datum/job/xenomorph)
		xeno_job.add_job_points(larva_point_reward)
		xeno_owner.hive.update_tier_limits()
		GLOB.round_statistics.larva_from_psydrain += larva_point_reward / xeno_job.job_points_needed

	if(owner.client)
		var/datum/personal_statistics/personal_statistics = GLOB.personal_statistics_list[owner.ckey]
		personal_statistics.drained++
	log_combat(victim, owner, "was drained.")
	log_game("[key_name(victim)] was drained at [AREACOORD(victim.loc)].")

/datum/action/ability/activable/xeno/psydrain/free
	ability_cost = 0

/////////////////////////////////
// Cocoon
/////////////////////////////////
/datum/action/ability/activable/xeno/cocoon
	name = "Cocoon"
	desc = "Devour your victim to cocoon it in your belly. This cocoon will automatically be ejected later, and while the marine inside it still has life force it will give psychic points."
	action_icon_state = "regurgitate"
	action_icon = 'icons/Xeno/actions/general.dmi'
	use_state_flags = ABILITY_USE_STAGGERED|ABILITY_USE_FORTIFIED|ABILITY_USE_CRESTED //can't use while staggered, defender fortified or crest down
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_REGURGITATE,
	)
	ability_cost = 100
	gamemode_flags = ABILITY_DISTRESS|ABILITY_CRASH
	///In how much time the cocoon will be ejected
	var/cocoon_production_time = 3 SECONDS

/datum/action/ability/activable/xeno/cocoon/can_use_ability(atom/A, silent, override_flags)
	. = ..()
	if(!.)
		return
	if(!ishuman(A) || issynth(A))
		to_chat(xeno_owner, span_warning("That wouldn't taste very good."))
		return FALSE
	var/mob/living/carbon/human/victim = A
	if(xeno_owner.do_actions) //can't use if busy
		return FALSE
	if(!xeno_owner.Adjacent(victim)) //checks if owner next to target
		return FALSE
	if(victim.stat != DEAD)
		if(!silent)
			to_chat(xeno_owner, span_warning("This creature is struggling too much for us to devour it."))
		return FALSE
	if(HAS_TRAIT(victim, TRAIT_PSY_DRAINED))
		if(!silent)
			to_chat(xeno_owner, span_warning("There is no longer any life force in this creature!"))
		return FALSE
	if(victim.buckled)
		if(!silent)
			to_chat(xeno_owner, span_warning("[victim] is buckled to something."))
		return FALSE
	if(xeno_owner.on_fire)
		if(!silent)
			to_chat(xeno_owner, span_warning("We're too busy being on fire to do this!"))
		return FALSE
	if(xeno_owner.eaten_mob) //Only one thing in the stomach at a time, please
		if(!silent)
			to_chat(xeno_owner, span_warning("We already have something in our stomach, there's no way that will fit."))
		return FALSE
	for(var/obj/effect/forcefield/fog in range(1, xeno_owner))
		if(!silent)
			to_chat(xeno_owner, span_warning("We are too close to the fog."))
		return FALSE
	xeno_owner.face_atom(victim)
	xeno_owner.visible_message(span_danger("[xeno_owner] starts to devour [victim]!"), \
	span_danger("We start to devour [victim]!"), null, 5)

	succeed_activate()

/datum/action/ability/activable/xeno/cocoon/use_ability(atom/A)
	var/mob/living/carbon/human/victim = A
	var/channel = SSsounds.random_available_channel()
	playsound(xeno_owner, 'sound/vore/struggle.ogg', 40, channel = channel)
	if(!do_after(xeno_owner, 7 SECONDS, IGNORE_HELD_ITEM, victim, BUSY_ICON_DANGER, extra_checks = CALLBACK(owner, TYPE_PROC_REF(/mob, break_do_after_checks), list("health" = xeno_owner.health))))
		to_chat(owner, span_warning("We stop devouring \the [victim]. They probably tasted gross anyways."))
		xeno_owner.stop_sound_channel(channel)
		return fail_activate()
	if(HAS_TRAIT(victim, TRAIT_PSY_DRAINED))
		to_chat(owner, span_warning("Someone drained the life force of our victim before we could devour it!"))
		return fail_activate()
	owner.visible_message(span_warning("[xeno_owner] devours [victim]!"), \
	span_warning("We devour [victim]!"), null, 5)
	to_chat(owner, span_warning("We will eject the cocoon in [cocoon_production_time * 0.1] seconds! Do not move until it is done."))
	xeno_owner.eaten_mob = victim
	var/turf/starting_turf = get_turf(victim)
	victim.forceMove(xeno_owner)
	xeno_owner.do_jitter_animation()
	succeed_activate()
	channel = SSsounds.random_available_channel()
	playsound(xeno_owner, 'sound/vore/escape.ogg', 40, channel = channel)
	if(!do_after(xeno_owner, cocoon_production_time, IGNORE_HELD_ITEM, null, BUSY_ICON_DANGER))
		to_chat(owner, span_warning("We moved too soon and we will have to devour our victim again!"))
		xeno_owner.eject_victim(FALSE, starting_turf)
		xeno_owner.stop_sound_channel(channel)
		return fail_activate()
	victim.dead_ticks = 0
	ADD_TRAIT(victim, TRAIT_STASIS, TRAIT_STASIS)
	xeno_owner.eject_victim(TRUE, starting_turf)
	// All non-minion xenos in this hive get +0.05 passive biomass gain.
	xeno_owner.hive.biomass_gain_bonus += 0.05
	if(owner.client)
		var/datum/personal_statistics/personal_statistics = GLOB.personal_statistics_list[owner.ckey]
		personal_statistics.cocooned++

/////////////////////////////////
// blessing Menu
/////////////////////////////////
/datum/action/ability/xeno_action/blessing_menu
	name = "Mothers Blessings"
	desc = "Ask the Queen Mother for blessings for your hive in exchange for psychic energy."
	action_icon_state = "hivestore" // missing icon?
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_BLESSINGSMENU,
	)
	use_state_flags = ABILITY_USE_LYING|ABILITY_USE_CRESTED
	hidden = TRUE

/datum/action/ability/xeno_action/blessing_menu/action_activate()
	xeno_owner.hive.purchases.interact(xeno_owner)
	return succeed_activate()

// ***************************************
// *********** Xeno Warnings
// ***************************************
/obj/effect/temp_visual/xeno_warning
	icon = 'icons/xeno/Effects.dmi'
	icon_state = "generic_warning"
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/xeno_warning/Initialize(mapload, _duration = 0.5 SECONDS, _color = COLOR_VIOLET)
	. = ..()
	duration = _duration
	color = _color
	animate(src, time = duration - 0.5 SECONDS)
	animate(alpha = 0, time = 0.5 SECONDS, easing = CIRCULAR_EASING|EASE_OUT)
	notify_ai_hazard()

/// Warns nearby players, in any way or form, of an incoming ability and the range it will affect.
/proc/xeno_warning(list/turf/target_turfs, duration, color)
	if(!length(target_turfs))
		CRASH("do_warning([length(target_turfs)]): improper argument")
	for(var/turf/target_turf AS in target_turfs)
		new /obj/effect/temp_visual/xeno_warning(target_turf, duration, color)
