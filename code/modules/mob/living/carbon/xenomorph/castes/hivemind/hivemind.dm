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
	///List of selected minions under our RTS command
	var/list/mob/living/carbon/xenomorph/selected_minions = list()
	///Assoc list of images applied to selected minions (minion -> image)
	var/list/selection_images = list()
	///List of active HUD card screen objects for selected minions
	var/list/atom/movable/screen/rts_unit_card/rts_hud_cards = list()
	///RTS Drag Selection Box variables
	var/drag_start_screen_x = 0
	var/drag_start_screen_y = 0
	var/turf/drag_start_turf = null
	var/drag_is_active = FALSE
	var/drag_shift_held = FALSE
	var/atom/movable/screen/rts_drag_box/box_fill = null
	var/atom/movable/screen/rts_drag_box/box_border_top = null
	var/atom/movable/screen/rts_drag_box/box_border_bottom = null
	var/atom/movable/screen/rts_drag_box/box_border_left = null
	var/atom/movable/screen/rts_drag_box/box_border_right = null

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
		for(var/mob/minion in selected_minions)
			var/image/I = selection_images[minion]
			if(I)
				client.images += I
		update_rts_hud()

/mob/living/carbon/xenomorph/hivemind/Logout()
	clear_rts_drag_box()
	if(client)
		for(var/mob/minion in selected_minions)
			var/image/I = selection_images[minion]
			if(I)
				client.images -= I
		for(var/atom/movable/screen/rts_unit_card/card in rts_hud_cards)
			client.screen -= card
	return ..()

/mob/living/carbon/xenomorph/hivemind/Destroy()
	clear_rts_drag_box()
	clear_selection()
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

/mob/living/carbon/xenomorph/hivemind/DblClickOn(atom/A, params)
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

/// Checks whether this mob can be selected and commanded by Hivemind RTS
/mob/living/carbon/xenomorph/hivemind/proc/can_control_minion(mob/living/carbon/xenomorph/target)
	if(!istype(target))
		return FALSE
	if(target == src)
		return FALSE
	if(target.stat == DEAD)
		return FALSE
	if(target.hivenumber != hivenumber)
		return FALSE
	// ПРОВЕРКА НА «ДУШУ» (ИГРОКА):
	// Если у ксеноморфа есть ckey, key или активный разум игрока — он не может управляться Hivemind как миньон
	if(target.ckey || target.key || (target.mind && target.mind.current == target && target.mind.active))
		return FALSE
	// Должен иметь ИИ контроллер (если нет — автоматически добавляем xeno ai)
	var/datum/component/ai_controller/controller = target.GetComponent(/datum/component/ai_controller)
	if(!controller)
		target.AddComponent(/datum/component/ai_controller, /datum/ai_behavior/xeno)
	var/datum/hive_status/H = GLOB.hive_datums[hivenumber]
	H?.apply_minion_buffs(target)
	return TRUE


/// Selects a minion, showing a selection circle to the client
/mob/living/carbon/xenomorph/hivemind/proc/select_minion(mob/living/carbon/xenomorph/minion, clear_previous = TRUE)
	if(clear_previous)
		clear_selection()

	if(!can_control_minion(minion))
		if(minion.ckey || minion.key || (minion.mind && minion.mind.active))
			balloon_alert(src, "У этого ксеноморфа есть собственный разум!")
		else
			balloon_alert(src, "Невозможно подчинить!")
		return FALSE

	if(minion in selected_minions)
		return TRUE

	selected_minions += minion

	var/image/select_ring = image('icons/effects/xeno_target.dmi', minion, "all")
	select_ring.color = "#00FF66"
	select_ring.layer = MOB_LAYER + 0.1
	SET_PLANE_EXPLICIT(select_ring, GAME_PLANE, minion)
	var/matrix/M = matrix()
	M.Scale(0.38, 0.38)
	select_ring.transform = M
	select_ring.pixel_x = -16
	select_ring.pixel_y = -16
	selection_images[minion] = select_ring
	if(client)
		client.images += select_ring

	RegisterSignals(minion, list(COMSIG_MOB_DEATH, COMSIG_QDELETING, COMSIG_MOB_LOGIN), PROC_REF(on_selected_minion_lost))
	update_rts_hud()
	return TRUE

/// Deselects a specific minion
/mob/living/carbon/xenomorph/hivemind/proc/deselect_minion(mob/living/carbon/xenomorph/minion)
	if(!(minion in selected_minions))
		return
	UnregisterSignal(minion, list(COMSIG_MOB_DEATH, COMSIG_QDELETING, COMSIG_MOB_LOGIN))
	if(selection_images[minion] && client)
		client.images -= selection_images[minion]
	selected_minions -= minion
	selection_images -= minion
	update_rts_hud()

/// Clears all minion selections
/mob/living/carbon/xenomorph/hivemind/proc/clear_selection()
	for(var/mob/minion in selected_minions)
		UnregisterSignal(minion, list(COMSIG_MOB_DEATH, COMSIG_QDELETING, COMSIG_MOB_LOGIN))
		if(selection_images[minion] && client)
			client.images -= selection_images[minion]
	selected_minions.Cut()
	selection_images.Cut()
	update_rts_hud()

/// Updates the Warcraft 3 style unit card panel at the bottom of the screen
/mob/living/carbon/xenomorph/hivemind/proc/update_rts_hud()
	if(client)
		for(var/atom/movable/screen/rts_unit_card/card in rts_hud_cards)
			client.screen -= card
			qdel(card)
	rts_hud_cards.Cut()

	if(!length(selected_minions) || !client)
		return

	var/total_cards = min(length(selected_minions), 10)
	var/start_offset = -round((total_cards - 1) / 2)
	for(var/i in 1 to total_cards)
		var/mob/living/carbon/xenomorph/minion = selected_minions[i]
		if(QDELETED(minion) || minion.stat == DEAD)
			continue
		var/offset = start_offset + (i - 1)
		var/offset_str = offset >= 0 ? "+[offset]" : "[offset]"
		var/pos_loc = "CENTER[offset_str]:0,SOUTH:6"
		var/atom/movable/screen/rts_unit_card/card = new(null, minion, src, pos_loc)
		rts_hud_cards += card
		client.screen += card

/// Signal callback when a selected minion dies, is deleted, or a player logs in
/mob/living/carbon/xenomorph/hivemind/proc/on_selected_minion_lost(mob/living/carbon/xenomorph/source)
	SIGNAL_HANDLER
	deselect_minion(source)

/// Issues an RTS order to all currently selected minions
/mob/living/carbon/xenomorph/hivemind/proc/issue_rts_order(atom/target)
	if(!length(selected_minions))
		return FALSE

	// Filter out invalid/dead/player-possessed minions
	for(var/mob/living/carbon/xenomorph/minion in selected_minions)
		if(QDELETED(minion) || minion.stat == DEAD || minion.ckey || minion.key)
			deselect_minion(minion)

	if(!length(selected_minions))
		return FALSE

	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return FALSE

	// 1. Hostile Target -> Attack order (Focus fire)
	var/is_enemy = FALSE
	if(isliving(target))
		var/mob/living/L = target
		if(L.stat != DEAD && L.get_xeno_hivenumber() != hivenumber)
			is_enemy = TRUE
	else if(istype(target, /obj/machinery/door) || istype(target, /obj/structure))
		var/obj/O = target
		if(O.get_xeno_hivenumber() != hivenumber)
			is_enemy = TRUE

	if(is_enemy)
		for(var/mob/living/carbon/xenomorph/minion in selected_minions)
			var/datum/component/ai_controller/controller = minion.GetComponent(/datum/component/ai_controller)
			var/datum/ai_behavior/xeno/behavior = controller?.ai_behavior
			if(behavior)
				behavior.set_combat_target(target)
				behavior.set_atom_to_walk_to(target)
				behavior.change_action(MOVING_TO_ATOM, target)
		new /obj/effect/temp_visual/rts_order/attack(target_turf)
		playsound_local(src, 'sound/effects/UI/click.ogg', 30, TRUE)
		return TRUE

	// 2. Construction Hologram -> Build order ONLY for Nymphs
	if(istype(target, /obj/effect/xeno_construction_hologram))
		var/obj/effect/xeno_construction_hologram/holo = target
		var/nymph_ordered = FALSE
		for(var/mob/living/carbon/xenomorph/minion in selected_minions)
			if(!istype(minion, /mob/living/carbon/xenomorph/nymph))
				continue
			var/datum/component/ai_controller/controller = minion.GetComponent(/datum/component/ai_controller)
			var/datum/ai_behavior/xeno/behavior = controller?.ai_behavior
			if(behavior)
				behavior.combat_target = null
				behavior.clean_escorted_atom()
				behavior.set_atom_to_walk_to(holo)
				behavior.change_action(MOVING_TO_ATOM, holo)
				nymph_ordered = TRUE
		if(nymph_ordered)
			new /obj/effect/temp_visual/rts_order/escort(target_turf)
			playsound_local(src, 'sound/effects/UI/click.ogg', 30, TRUE)
			return TRUE
		return FALSE

	// 3. Friendly Target -> Follow / Escort order
	var/is_ally = FALSE
	if(isxeno(target) && target != src)
		var/mob/living/carbon/xenomorph/ally = target
		if(ally.hivenumber == hivenumber && ally.stat != DEAD)
			is_ally = TRUE
	else if(istype(target, /obj/structure/xeno/hivemindcore))
		is_ally = TRUE

	if(is_ally)
		for(var/mob/living/carbon/xenomorph/minion in selected_minions)
			if(minion == target)
				continue
			var/datum/component/ai_controller/controller = minion.GetComponent(/datum/component/ai_controller)
			var/datum/ai_behavior/xeno/behavior = controller?.ai_behavior
			if(behavior)
				behavior.set_escorted_atom(null, target)
				behavior.change_action(ESCORTING_ATOM, target)
		new /obj/effect/temp_visual/rts_order/escort(target_turf)
		playsound_local(src, 'sound/effects/UI/click.ogg', 30, TRUE)
		return TRUE

	// 4. Turf / Move location -> Move order
	for(var/mob/living/carbon/xenomorph/minion in selected_minions)
		var/datum/component/ai_controller/controller = minion.GetComponent(/datum/component/ai_controller)
		var/datum/ai_behavior/xeno/behavior = controller?.ai_behavior
		if(behavior)
			behavior.clean_escorted_atom()
			behavior.combat_target = null
			behavior.set_atom_to_walk_to(target_turf)
			behavior.change_action(MOVING_TO_ATOM, target_turf)

	new /obj/effect/temp_visual/rts_order/move(target_turf)
	playsound_local(src, 'sound/effects/UI/click.ogg', 30, TRUE)
	return TRUE

/// Checks if at least one selected minion is a Nymph builder
/mob/living/carbon/xenomorph/hivemind/proc/has_selected_builder()
	for(var/mob/living/carbon/xenomorph/minion in selected_minions)
		if(istype(minion, /mob/living/carbon/xenomorph/nymph))
			return TRUE
	return FALSE

/// Returns list of all selected builder nymphs
/mob/living/carbon/xenomorph/hivemind/proc/get_selected_builders()
	var/list/mob/living/carbon/xenomorph/builders = list()
	for(var/mob/living/carbon/xenomorph/minion in selected_minions)
		if(istype(minion, /mob/living/carbon/xenomorph/nymph))
			builders += minion
	return builders

/// Places a construction hologram and directs builder nymphs to construct it
/mob/living/carbon/xenomorph/hivemind/proc/place_construction_hologram(turf/T, structure_type)
	if(!T)
		return FALSE

	// If clicking on an existing hologram, remove/cancel it
	for(var/obj/effect/xeno_construction_hologram/existing in T)
		balloon_alert(src, "Голограмма убрана")
		playsound_local(src, 'sound/effects/UI/click.ogg', 30, TRUE)
		qdel(existing)
		return TRUE

	// Check if turf is a closed wall
	if(isclosedturf(T) || T.density)
		balloon_alert(src, "Нельзя строить на стенах!")
		return FALSE

	// Check for existing structures on this turf
	for(var/obj/structure/S in T)
		if(S.density || istype(S, /obj/structure/mineral_door) || istype(S, /obj/structure/bed/nest) || istype(S, /obj/structure/barricade) || istype(S, /obj/alien/resin))
			balloon_alert(src, "Здесь уже есть постройка!")
			return FALSE

	for(var/obj/machinery/M in T)
		if(M.density)
			balloon_alert(src, "Здесь находится оборудование!")
			return FALSE

	// Check if valid for resin construction
	var/is_door = ispath(structure_type, /obj/structure/mineral_door/resin)
	var/valid_check = is_valid_for_resin_structure(T, is_door, structure_type)
	if(valid_check == ERROR_NO_WEED)
		balloon_alert(src, "Здесь нет смоляного покрова (травы)!")
		return FALSE
	else if(valid_check == ERROR_CANT_WEED)
		balloon_alert(src, "Это место не подходит для смолы!")
		return FALSE
	else if(valid_check == ERROR_NOT_ALLOWED)
		balloon_alert(src, "Нельзя строить здесь!")
		return FALSE

	if(!structure_type)
		structure_type = selected_resin ? selected_resin : /turf/closed/wall/resin/regenerating

	var/obj/effect/xeno_construction_hologram/holo = new(T, hivenumber, structure_type)

	var/list/builders = get_selected_builders()
	if(!length(builders))
		for(var/mob/living/carbon/xenomorph/nymph/N in range(15, T))
			if(can_control_minion(N))
				builders += N
				break

	for(var/mob/living/carbon/xenomorph/builder in builders)
		var/datum/component/ai_controller/controller = builder.GetComponent(/datum/component/ai_controller)
		var/datum/ai_behavior/xeno/behavior = controller?.ai_behavior
		if(behavior)
			behavior.combat_target = null
			behavior.clean_escorted_atom()
			behavior.set_atom_to_walk_to(holo)
			behavior.change_action(MOVING_TO_ATOM, holo)

	balloon_alert(src, "Голограмма установлена")
	playsound_local(src, 'sound/effects/UI/click.ogg', 30, TRUE)
	return TRUE

/// Helper to check if Hivemind is actively in RTS minion commanding mode
/mob/living/carbon/xenomorph/hivemind/proc/is_rts_active()
	return istype(selected_ability, /datum/action/ability/activable/xeno/rts_minion_control)

/mob/living/carbon/xenomorph/hivemind/RightClickOn(atom/A)
	var/atom/real_target = get_turf_on_clickcatcher(A, src) || A

	// If right-clicking on a hologram without nymphs, or when no builder minions are selected: remove it
	if(istype(real_target, /obj/effect/xeno_construction_hologram))
		if(!is_rts_active() || !has_selected_builder())
			balloon_alert(src, "Голограмма отменена")
			playsound_local(src, 'sound/effects/UI/click.ogg', 30, TRUE)
			qdel(real_target)
			return TRUE

	if(is_rts_active() && length(selected_minions))
		if(issue_rts_order(real_target))
			return TRUE

	return ..()

/mob/living/carbon/xenomorph/hivemind/ClickOn(atom/A, location, params)
	var/list/modifiers = params2list(params)

	// If right click, handled by RightClickOn
	if(modifiers["right"])
		return ..()

	var/atom/real_target = get_turf_on_clickcatcher(A, src, params) || A

	// If clicking directly on a hologram in resin or normal mode, remove it
	if(istype(real_target, /obj/effect/xeno_construction_hologram))
		balloon_alert(src, "Голограмма отменена")
		playsound_local(src, 'sound/effects/UI/click.ogg', 30, TRUE)
		qdel(real_target)
		return

	// If clicking on own hivemind core, open minion upgrade menu
	if(istype(real_target, /obj/structure/xeno/hivemindcore) || istype(A, /obj/structure/xeno/hivemindcore))
		var/obj/structure/xeno/hivemindcore/Hcore = istype(real_target, /obj/structure/xeno/hivemindcore) ? real_target : A
		Hcore.open_minion_upgrade_menu(src)
		return

	// Minion selection is ONLY allowed when RTS mode is actively enabled
	if(!is_rts_active())
		return ..()

	// If clicking on a xeno to select
	var/mob/living/carbon/xenomorph/target_xeno = null
	if(isxeno(real_target) && real_target != src)
		target_xeno = real_target
	else
		var/turf/T = get_turf(real_target)
		if(T)
			for(var/mob/living/carbon/xenomorph/X in T)
				if(X != src && X.stat != DEAD && X.hivenumber == hivenumber)
					target_xeno = X
					break

	if(target_xeno)
		var/add_to_group = modifiers["shift"] ? TRUE : FALSE
		if(add_to_group && (target_xeno in selected_minions))
			deselect_minion(target_xeno)
		else
			select_minion(target_xeno, clear_previous = !add_to_group)
		return

	// If clicking empty turf / non-xeno without shift and we had selected minions
	if(!modifiers["shift"] && length(selected_minions))
		clear_selection()

	return ..()

// ==========================================
// Warcraft 3 Style RTS Drag Selection Box
// ==========================================

GLOBAL_VAR(rts_1px_icon)

/proc/get_rts_1px_icon()
	if(!GLOB.rts_1px_icon)
		var/icon/I = icon('icons/effects/effects.dmi', "white")
		I.Crop(1, 1, 1, 1)
		GLOB.rts_1px_icon = I
	return GLOB.rts_1px_icon

/proc/rts_pixel_to_screen_loc(px, py)
	var/tx = 1 + round(px / 32)
	var/ox = px % 32
	var/ty = 1 + round(py / 32)
	var/oy = py % 32
	return "[tx]:[ox],[ty]:[oy]"

/atom/movable/screen/rts_drag_box
	name = ""
	plane = ABOVE_HUD_PLANE
	layer = 100
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = APPEARANCE_UI

/mob/living/carbon/xenomorph/hivemind/proc/on_rts_mousedown(mob/source, atom/object, turf/location, control, params)
	SIGNAL_HANDLER

	if(!client)
		return NONE

	if(!is_rts_active())
		return NONE

	var/list/modifiers = params2list(params)
	if(!modifiers["left"] || modifiers["right"] || modifiers["middle"])
		return NONE

	// Ignore clicks on HUD buttons/panels, but allow click_catcher (map background)
	if(istype(object, /atom/movable/screen) && !istype(object, /atom/movable/screen/click_catcher))
		return NONE

	var/list/pixel_coords = params2screenpixel(modifiers["screen-loc"])
	if(!pixel_coords || !length(pixel_coords))
		return NONE

	drag_start_screen_x = pixel_coords[1]
	drag_start_screen_y = pixel_coords[2]
	drag_start_turf = get_turf(get_turf_on_clickcatcher(object, src, params)) || location
	if(!drag_start_turf && client && modifiers["screen-loc"])
		drag_start_turf = params2turf(modifiers["screen-loc"], get_turf(client.eye ? client.eye : src), client)
	drag_is_active = FALSE
	drag_shift_held = modifiers["shift"] ? TRUE : FALSE
	return NONE

/mob/living/carbon/xenomorph/hivemind/proc/on_rts_mousedrag(mob/source, atom/src_object, atom/over_object, turf/src_location, turf/over_location, src_control, over_control, params)
	SIGNAL_HANDLER

	if(!client || !is_rts_active() || !drag_start_screen_x || !drag_start_screen_y)
		return NONE

	var/list/modifiers = params2list(params)
	var/list/cur_coords = params2screenpixel(modifiers["screen-loc"])
	if(!cur_coords || !length(cur_coords))
		return NONE

	var/cur_x = cur_coords[1]
	var/cur_y = cur_coords[2]

	var/dx = abs(cur_x - drag_start_screen_x)
	var/dy = abs(cur_y - drag_start_screen_y)

	if(dx < 6 && dy < 6 && !drag_is_active)
		return NONE

	drag_is_active = TRUE
	update_rts_drag_box(drag_start_screen_x, drag_start_screen_y, cur_x, cur_y)
	return NONE

/mob/living/carbon/xenomorph/hivemind/proc/update_rts_drag_box(x1, y1, x2, y2)
	if(!client)
		return

	var/min_x = min(x1, x2)
	var/max_x = max(x1, x2)
	var/min_y = min(y1, y2)
	var/max_y = max(y1, y2)
	var/w = max(1, max_x - min_x)
	var/h = max(1, max_y - min_y)

	var/base_loc = rts_pixel_to_screen_loc(min_x, min_y)
	var/icon/pixel_icon = get_rts_1px_icon()

	if(!box_fill)
		box_fill = new(null)
		box_fill.icon = pixel_icon
		box_fill.color = "#00FF44"
		box_fill.alpha = 25
		client.screen += box_fill

	if(!box_border_top)
		box_border_top = new(null)
		box_border_top.icon = pixel_icon
		box_border_top.color = "#00FF44"
		box_border_top.alpha = 255
		client.screen += box_border_top

	if(!box_border_bottom)
		box_border_bottom = new(null)
		box_border_bottom.icon = pixel_icon
		box_border_bottom.color = "#00FF44"
		box_border_bottom.alpha = 255
		client.screen += box_border_bottom

	if(!box_border_left)
		box_border_left = new(null)
		box_border_left.icon = pixel_icon
		box_border_left.color = "#00FF44"
		box_border_left.alpha = 255
		client.screen += box_border_left

	if(!box_border_right)
		box_border_right = new(null)
		box_border_right.icon = pixel_icon
		box_border_right.color = "#00FF44"
		box_border_right.alpha = 255
		client.screen += box_border_right

	// Position all 5 elements at the bottom-left corner
	box_fill.screen_loc = base_loc
	box_border_top.screen_loc = base_loc
	box_border_bottom.screen_loc = base_loc
	box_border_left.screen_loc = base_loc
	box_border_right.screen_loc = base_loc

	// Fill Box: scale by (w, h)
	var/matrix/M_fill = matrix()
	M_fill.Scale(w, h)
	M_fill.Translate((w - 1) / 2, (h - 1) / 2)
	box_fill.transform = M_fill

	// Top Border: scale (w, 1), translate Y by (h - 1)
	var/matrix/M_top = matrix()
	M_top.Scale(w, 1)
	M_top.Translate((w - 1) / 2, h - 1)
	box_border_top.transform = M_top

	// Bottom Border: scale (w, 1)
	var/matrix/M_bot = matrix()
	M_bot.Scale(w, 1)
	M_bot.Translate((w - 1) / 2, 0)
	box_border_bottom.transform = M_bot

	// Left Border: scale (1, h)
	var/matrix/M_left = matrix()
	M_left.Scale(1, h)
	M_left.Translate(0, (h - 1) / 2)
	box_border_left.transform = M_left

	// Right Border: scale (1, h), translate X by (w - 1)
	var/matrix/M_right = matrix()
	M_right.Scale(1, h)
	M_right.Translate(w - 1, (h - 1) / 2)
	box_border_right.transform = M_right

/mob/living/carbon/xenomorph/hivemind/proc/clear_rts_drag_box()
	if(client)
		if(box_fill)
			client.screen -= box_fill
		if(box_border_top)
			client.screen -= box_border_top
		if(box_border_bottom)
			client.screen -= box_border_bottom
		if(box_border_left)
			client.screen -= box_border_left
		if(box_border_right)
			client.screen -= box_border_right

	QDEL_NULL(box_fill)
	QDEL_NULL(box_border_top)
	QDEL_NULL(box_border_bottom)
	QDEL_NULL(box_border_left)
	QDEL_NULL(box_border_right)

	drag_start_screen_x = 0
	drag_start_screen_y = 0
	drag_start_turf = null
	drag_is_active = FALSE
	drag_shift_held = FALSE

/mob/living/carbon/xenomorph/hivemind/proc/on_rts_mouseup(mob/source, atom/object, turf/location, control, params)
	SIGNAL_HANDLER

	if(!is_rts_active())
		clear_rts_drag_box()
		return NONE

	if(!drag_start_screen_x || !drag_start_screen_y)
		clear_rts_drag_box()
		return NONE

	if(!drag_is_active)
		clear_rts_drag_box()
		return NONE

	var/list/modifiers = params2list(params)
	var/turf/end_turf = get_turf(get_turf_on_clickcatcher(object, src, params)) || location
	if(!end_turf && client && modifiers["screen-loc"])
		end_turf = params2turf(modifiers["screen-loc"], get_turf(client.eye ? client.eye : src), client)
	var/turf/start_turf = drag_start_turf

	var/was_active = drag_is_active
	var/held_shift = drag_shift_held || (modifiers["shift"] ? TRUE : FALSE)
	clear_rts_drag_box()

	if(client)
		client.click_intercepted = world.time

	if(!was_active || !start_turf || !end_turf || start_turf.z != end_turf.z)
		return COMSIG_MOB_CLICK_CANCELED

	var/min_tx = min(start_turf.x, end_turf.x)
	var/max_tx = max(start_turf.x, end_turf.x)
	var/min_ty = min(start_turf.y, end_turf.y)
	var/max_ty = max(start_turf.y, end_turf.y)
	var/target_z = start_turf.z

	var/list/mob/living/carbon/xenomorph/found_minions = list()
	for(var/turf/T in block(locate(min_tx, min_ty, target_z), locate(max_tx, max_ty, target_z)))
		for(var/mob/living/carbon/xenomorph/X in T)
			if(X == src || X.stat == DEAD || X.hivenumber != hivenumber)
				continue
			if(!can_control_minion(X))
				continue
			found_minions += X

	if(!held_shift)
		clear_selection()

	for(var/mob/living/carbon/xenomorph/minion in found_minions)
		select_minion(minion, clear_previous = FALSE)

	if(length(found_minions))
		playsound_local(src, 'sound/effects/UI/click.ogg', 30, TRUE)

	return COMSIG_MOB_CLICK_CANCELED

// ==========================================
// Warcraft 3 Style RTS Unit Selection HUD Card
// ==========================================

/atom/movable/screen/rts_unit_card
	name = "Unit"
	icon = 'icons/effects/effects.dmi'
	icon_state = "white"
	color = "#18221b"
	alpha = 210
	plane = ABOVE_HUD_PLANE
	layer = 80
	mouse_opacity = MOUSE_OPACITY_ICON
	appearance_flags = APPEARANCE_UI
	var/datum/weakref/minion_ref
	var/mob/living/carbon/xenomorph/hivemind/hivemind_owner

/atom/movable/screen/rts_unit_card/Initialize(mapload, mob/living/carbon/xenomorph/minion, mob/living/carbon/xenomorph/hivemind/H, pos_loc)
	. = ..()
	hivemind_owner = H
	minion_ref = WEAKREF(minion)
	screen_loc = pos_loc
	name = minion.name
	update_card()
	RegisterSignals(minion, list(COMSIG_XENOMORPH_TAKING_DAMAGE, COMSIG_XENOMORPH_HEALTH_REGEN), PROC_REF(on_minion_health_change))

/atom/movable/screen/rts_unit_card/Destroy()
	var/mob/living/carbon/xenomorph/minion = minion_ref?.resolve()
	if(minion)
		UnregisterSignal(minion, list(COMSIG_XENOMORPH_TAKING_DAMAGE, COMSIG_XENOMORPH_HEALTH_REGEN))
	minion_ref = null
	hivemind_owner = null
	return ..()

/atom/movable/screen/rts_unit_card/proc/update_card()
	var/mob/living/carbon/xenomorph/minion = minion_ref?.resolve()
	if(!minion || minion.stat == DEAD)
		qdel(src)
		return
	cut_overlays()
	var/mutable_appearance/portrait = mutable_appearance(minion.icon, minion.icon_state, layer = 82)
	portrait.appearance_flags = RESET_COLOR | RESET_ALPHA
	portrait.dir = SOUTH
	var/matrix/M = matrix()
	M.Scale(0.75, 0.75)
	portrait.transform = M
	portrait.pixel_y = 3
	add_overlay(portrait)

	var/health_pct = round((minion.health / minion.maxHealth) * 100)
	var/color_hex = "#00FF00"
	if(health_pct < 35)
		color_hex = "#FF3333"
	else if(health_pct < 70)
		color_hex = "#FFFF33"

	var/mutable_appearance/card_border = mutable_appearance('icons/mob/screen/generic.dmi', "selector", layer = 83)
	card_border.appearance_flags = RESET_COLOR | RESET_ALPHA
	card_border.color = "#00FF66"
	card_border.alpha = 180
	add_overlay(card_border)

	maptext = "<span style='font-size:7pt;font-weight:bold;color:[color_hex];-dm-text-outline: 1px black;'>[health_pct]%</span>"
	maptext_x = 0
	maptext_y = 0
	maptext_width = 32
	maptext_height = 12

/atom/movable/screen/rts_unit_card/proc/on_minion_health_change()
	SIGNAL_HANDLER
	update_card()

/atom/movable/screen/rts_unit_card/Click(location, control, params)
	var/list/modifiers = params2list(params)
	var/mob/living/carbon/xenomorph/minion = minion_ref?.resolve()
	if(!minion || !hivemind_owner)
		qdel(src)
		return

	if(!hivemind_owner.is_rts_active())
		return

	if(modifiers["right"] || modifiers["shift"])
		hivemind_owner.deselect_minion(minion)
		return

	if(modifiers["middle"])
		hivemind_owner.jump(minion)
		return

	hivemind_owner.select_minion(minion, clear_previous = TRUE)

/atom/movable/screen/rts_unit_card/DblClick(location, control, params)
	var/mob/living/carbon/xenomorph/minion = minion_ref?.resolve()
	if(minion && hivemind_owner)
		hivemind_owner.jump(minion)

// ==========================================
// Xenomorph Construction Hologram (Blueprint)
// ==========================================

/obj/effect/xeno_construction_hologram
	name = "resin hologram"
	desc = "A psychic projection from the hivemind, marking a structure to be built by builder nymphs."
	icon = 'icons/Xeno/actions/construction.dmi'
	icon_state = RESIN_WALL
	density = FALSE
	anchored = TRUE
	alpha = 160
	color = "#22FF88"
	plane = GAME_PLANE
	layer = ABOVE_NORMAL_TURF_LAYER
	var/target_structure = /turf/closed/wall/resin/regenerating
	var/hivenumber = XENO_HIVE_NORMAL
	var/build_time = 1.5 SECONDS

/obj/effect/xeno_construction_hologram/Initialize(mapload, new_hivenumber = XENO_HIVE_NORMAL, structure_type = /turf/closed/wall/resin/regenerating)
	. = ..()
	hivenumber = new_hivenumber
	target_structure = structure_type
	update_appearance_from_structure()

/obj/effect/xeno_construction_hologram/proc/update_appearance_from_structure()
	var/atom/A = target_structure
	name = "[initial(A.name)] (голограмма)"
	if(ispath(target_structure, /turf/closed/wall/resin))
		icon = 'icons/Xeno/actions/construction.dmi'
		icon_state = RESIN_WALL
	else if(ispath(target_structure, /obj/structure/mineral_door/resin))
		icon = 'icons/Xeno/actions/construction.dmi'
		icon_state = RESIN_DOOR
	else if(ispath(target_structure, /obj/alien/resin/sticky))
		icon = 'icons/Xeno/actions/construction.dmi'
		icon_state = STICKY_RESIN
	else if(ispath(target_structure, /obj/structure/bed/nest))
		icon = 'icons/Xeno/actions/construction.dmi'
		icon_state = ALIEN_NEST
	else
		icon = initial(A.icon)
		icon_state = initial(A.icon_state)



/obj/effect/xeno_construction_hologram/attack_alien(mob/living/carbon/xenomorph/builder, damage_amount, damage_type, damage_flag, effects, armor_penetration, isrightclick)
	if(isxenohivemind(builder))
		if(isrightclick)
			builder.balloon_alert(builder, "Голограмма отменена")
			qdel(src)
			return
		return

	if(!istype(builder, /mob/living/carbon/xenomorph/nymph))
		return
	if(builder.hivenumber != hivenumber)
		return
	if(builder.stat == DEAD)
		return

	INVOKE_ASYNC(src, PROC_REF(start_building), builder)

/obj/effect/xeno_construction_hologram/proc/start_building(mob/living/carbon/xenomorph/builder)
	if(builder.do_actions)
		return
	var/turf/T = get_turf(src)
	if(!T)
		qdel(src)
		return

	builder.face_atom(src)
	builder.visible_message(span_xenonotice("[builder] begins secreting resin onto the psychic blueprint..."), span_xenonotice("We begin secreting resin..."))
	playsound(T, SFX_ALIEN_DROOL, 25)

	if(!do_after(builder, build_time, NONE, src, BUSY_ICON_BUILD))
		return

	if(QDELETED(src))
		return

	if(ispath(target_structure, /turf))
		var/list/baseturfs = islist(T.baseturfs) ? T.baseturfs : list(T.baseturfs)
		baseturfs |= T.type
		T.ChangeTurf(target_structure, baseturfs)
	else
		new target_structure(T, hivenumber)


	playsound(T, 'sound/effects/spray3.ogg', 30, TRUE)
	new /obj/effect/temp_visual/rts_order/move(T)

	var/obj/effect/xeno_construction_hologram/next_holo = null
	for(var/obj/effect/xeno_construction_hologram/other_holo in range(12, T))
		if(other_holo != src && other_holo.hivenumber == hivenumber && !QDELETED(other_holo))
			next_holo = other_holo
			break

	qdel(src)

	if(next_holo)
		var/datum/component/ai_controller/controller = builder.GetComponent(/datum/component/ai_controller)
		var/datum/ai_behavior/xeno/behavior = controller?.ai_behavior
		if(behavior)
			behavior.set_atom_to_walk_to(next_holo)
			behavior.change_action(MOVING_TO_ATOM, next_holo)


/obj/fire/flamer/CanAllowThrough(atom/movable/mover, turf/target)
	if(isxenohivemind(mover))
		return FALSE
	return ..()

/// Getter proc for the weakref'd core
/mob/living/carbon/xenomorph/hivemind/proc/get_core()
	return core?.resolve()

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

/obj/structure/xeno/hivemindcore/attack_hand(mob/living/user)
	if(isxenohivemind(user))
		open_minion_upgrade_menu(user)
		return TRUE
	if(isxeno(user))
		to_chat(user, span_xenowarning("Только Разум Улья может мутировать миньонов через ядро!"))
		return TRUE
	return ..()

/obj/structure/xeno/hivemindcore/attack_alien(mob/living/carbon/xenomorph/xeno_attacker, damage_amount = xeno_attacker.xeno_caste.melee_damage, damage_type = BRUTE, damage_flag = MELEE, effects = TRUE, armor_penetration = xeno_attacker.xeno_caste.melee_ap, isrightclick = FALSE)
	if(isxenohivemind(xeno_attacker))
		open_minion_upgrade_menu(xeno_attacker)
		return TRUE

	if(isxenoqueen(xeno_attacker))
		var/choice = tgui_alert(xeno_attacker, "Are you sure you want to destroy the hivemind?", "Destroy hivemind", list("Yes", "Cancel"))
		if(choice == "Yes")
			deconstruct(FALSE)
			return
		return

	if(xeno_attacker.a_intent == INTENT_HARM)
		xeno_attacker.visible_message(span_danger("[xeno_attacker] nudges its head against [src]."), \
		span_danger("You nudge your head against [src]."))
		return

	to_chat(xeno_attacker, span_xenowarning("Только Разум Улья может мутировать миньонов через ядро!"))
	return TRUE

/obj/structure/xeno/hivemindcore/proc/open_minion_upgrade_menu(mob/living/carbon/xenomorph/user)
	if(!isxenohivemind(user))
		to_chat(user, span_xenowarning("Только Разум Улья может мутировать миньонов через ядро!"))
		return
	var/datum/hive_status/hive = GLOB.hive_datums[hivenumber]
	if(!hive)
		return

	var/current_psy = SSpoints.xeno_points_by_hive[hivenumber] || 0

	var/claws_cost = (hive.minion_upgrade_claws + 1) * 100
	var/carapace_cost = (hive.minion_upgrade_carapace + 1) * 100
	var/adrenal_cost = (hive.minion_upgrade_adrenal + 1) * 100
	var/regen_cost = (hive.minion_upgrade_regen + 1) * 100
	var/acid_cost = 250

	var/claws_label = hive.minion_upgrade_claws >= 3 ? "Когти: МАКС (+24 Урона)" : "Когти ур.[hive.minion_upgrade_claws + 1]/3 (+8 Урона) ([claws_cost] Пси)"
	var/carapace_label = hive.minion_upgrade_carapace >= 3 ? "Панцирь: МАКС (+180 ХП / +24 Брони)" : "Панцирь ур.[hive.minion_upgrade_carapace + 1]/3 (+60 ХП, +8 Брони) ([carapace_cost] Пси)"
	var/adrenal_label = hive.minion_upgrade_adrenal >= 3 ? "Адреналин: МАКС (+45% Скорости)" : "Адреналин ур.[hive.minion_upgrade_adrenal + 1]/3 (+15% Скорости) ([adrenal_cost] Пси)"
	var/regen_label = hive.minion_upgrade_regen >= 3 ? "Регенерация: МАКС (+12 ХП/сек)" : "Регенерация ур.[hive.minion_upgrade_regen + 1]/3 (+4 ХП/сек) ([regen_cost] Пси)"
	var/acid_label = hive.minion_upgrade_acid >= 1 ? "Кислотные когти: ИЗУЧЕНО" : "Кислотные когти ур.1/1 ([acid_cost] Пси)"

	var/list/choices = list()
	choices[claws_label] = image('icons/Xeno/actions/general.dmi', icon_state = "headbite")
	choices[carapace_label] = image('icons/Xeno/actions/general.dmi', icon_state = "Warding")
	choices[adrenal_label] = image('icons/Xeno/actions/general.dmi', icon_state = "rally_minions")
	choices[regen_label] = image('icons/Xeno/actions/general.dmi', icon_state = "Recovery")
	choices[acid_label] = image('icons/Xeno/actions/general.dmi', icon_state = "corrosive_acid")

	var/choice = show_radial_menu(user, src, choices, radius = 56, tooltips = TRUE)
	if(!choice)
		return

	if(choice == claws_label)
		if(hive.minion_upgrade_claws >= 3)
			user.balloon_alert(user, "Максимальный уровень когтей!")
			return
		if(current_psy < claws_cost)
			user.balloon_alert(user, "Недостаточно пси-очков ([current_psy]/[claws_cost])!")
			return
		SSpoints.xeno_points_by_hive[hivenumber] -= claws_cost
		hive.minion_upgrade_claws++
		hive.update_all_minion_buffs()
		xeno_message("<b>[user] усилил Острые когти миньонов до ур. [hive.minion_upgrade_claws]! (+[hive.minion_upgrade_claws * 8] урона)</b>", "xenoannounce", 5, hivenumber)
		user.playsound_local(user, 'sound/effects/spray3.ogg', 40, TRUE)
		user.balloon_alert(user, "Когти улучшены до ур. [hive.minion_upgrade_claws]!")

	else if(choice == carapace_label)
		if(hive.minion_upgrade_carapace >= 3)
			user.balloon_alert(user, "Максимальный уровень панциря!")
			return
		if(current_psy < carapace_cost)
			user.balloon_alert(user, "Недостаточно пси-очков ([current_psy]/[carapace_cost])!")
			return
		SSpoints.xeno_points_by_hive[hivenumber] -= carapace_cost
		hive.minion_upgrade_carapace++
		hive.update_all_minion_buffs()
		xeno_message("<b>[user] усилил Закалённый панцирь миньонов до ур. [hive.minion_upgrade_carapace]! (+[hive.minion_upgrade_carapace * 60] ХП, +[hive.minion_upgrade_carapace * 8] брони)</b>", "xenoannounce", 5, hivenumber)
		user.playsound_local(user, 'sound/effects/spray3.ogg', 40, TRUE)
		user.balloon_alert(user, "Панцирь улучшен до ур. [hive.minion_upgrade_carapace]!")

	else if(choice == adrenal_label)
		if(hive.minion_upgrade_adrenal >= 3)
			user.balloon_alert(user, "Максимальный уровень адреналина!")
			return
		if(current_psy < adrenal_cost)
			user.balloon_alert(user, "Недостаточно пси-очков ([current_psy]/[adrenal_cost])!")
			return
		SSpoints.xeno_points_by_hive[hivenumber] -= adrenal_cost
		hive.minion_upgrade_adrenal++
		hive.update_all_minion_buffs()
		xeno_message("<b>[user] усилил Адреналиновые железы миньонов до ур. [hive.minion_upgrade_adrenal]! (+[hive.minion_upgrade_adrenal * 15]% скорости)</b>", "xenoannounce", 5, hivenumber)
		user.playsound_local(user, 'sound/effects/spray3.ogg', 40, TRUE)
		user.balloon_alert(user, "Скорость улучшена до ур. [hive.minion_upgrade_adrenal]!")

	else if(choice == regen_label)
		if(hive.minion_upgrade_regen >= 3)
			user.balloon_alert(user, "Максимальный уровень регенерации!")
			return
		if(current_psy < regen_cost)
			user.balloon_alert(user, "Недостаточно пси-очков ([current_psy]/[regen_cost])!")
			return
		SSpoints.xeno_points_by_hive[hivenumber] -= regen_cost
		hive.minion_upgrade_regen++
		hive.update_all_minion_buffs()
		xeno_message("<b>[user] усилил Био-регенерацию миньонов до ур. [hive.minion_upgrade_regen]! (+[hive.minion_upgrade_regen * 4] ХП/сек на смоле)</b>", "xenoannounce", 5, hivenumber)
		user.playsound_local(user, 'sound/effects/spray3.ogg', 40, TRUE)
		user.balloon_alert(user, "Регенерация улучшена до ур. [hive.minion_upgrade_regen]!")

	else if(choice == acid_label)
		if(hive.minion_upgrade_acid >= 1)
			user.balloon_alert(user, "Кислотные когти уже изучены!")
			return
		if(current_psy < acid_cost)
			user.balloon_alert(user, "Недостаточно пси-очков ([current_psy]/[acid_cost])!")
			return
		SSpoints.xeno_points_by_hive[hivenumber] -= acid_cost
		hive.minion_upgrade_acid = 1
		hive.update_all_minion_buffs()
		xeno_message("<b>[user] исследовал Кислотные когти для всех миньонов улья! (Атаки миньонов наносят кислотный ожог)</b>", "xenoannounce", 5, hivenumber)
		user.playsound_local(user, 'sound/effects/spray3.ogg', 40, TRUE)
		user.balloon_alert(user, "Кислотные когти изучены!")


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
