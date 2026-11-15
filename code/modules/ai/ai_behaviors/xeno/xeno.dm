//Generic template for application to a xeno/ mob, contains specific obstacle dealing alongside targeting only humans, xenos of a different hive and sentry turrets

/datum/ai_behavior/xeno
	sidestep_prob = 25
	identifier = IDENTIFIER_XENO
	is_offered_on_creation = TRUE
	///If the mob parent can heal itself and so should flee
	var/can_heal = TRUE
	///Hivemind order: stand still until a new order arrives
	var/hivemind_rts_hold_position = FALSE
	///Hivemind order: walk to atom_to_walk_to (a turf) ignoring hostiles until arrival
	var/hivemind_rts_direct_move = FALSE
	///Hivemind order: acid well to fill with our plasma
	var/obj/structure/xeno/acidwell/rts_well
	/// Controller that most recently summoned this minion.
	var/datum/weakref/minion_call_owner_ref
	/// Priority of the current summon owner; higher-ranked callers may take control.
	var/minion_call_priority = 0

/// Instant hivemind orders; every proc resets the previous order.
/datum/ai_behavior/xeno/proc/rts_reset()
	clear_adv_route()
	advanced_pathing = initial(advanced_pathing)
	rts_well = null
	hivemind_rts_hold_position = FALSE
	hivemind_rts_direct_move = FALSE
	minion_call_owner_ref = null
	minion_call_priority = 0
	clean_escorted_atom()
	set_combat_target(null)

/// The current caller, if this minion is attached to one.
/datum/ai_behavior/xeno/proc/get_minion_call_owner()
	return minion_call_owner_ref?.resolve()

/// Whether a controller can take this minion from its current caller.
/datum/ai_behavior/xeno/proc/can_be_called_by(mob/living/carbon/xenomorph/controller, requested_priority)
	if(!controller || QDELETED(controller))
		return FALSE
	var/mob/living/carbon/xenomorph/minion = mob_parent
	if(minion?.personal_minion)
		return FALSE
	var/mob/living/carbon/xenomorph/current_owner = get_minion_call_owner()
	return !current_owner || current_owner == controller || requested_priority > minion_call_priority

/// Whether an external controller (currently the Hivemind RTS) may issue orders to this minion.
/datum/ai_behavior/xeno/proc/can_be_controlled_by(mob/living/carbon/xenomorph/controller)
	var/mob/living/carbon/xenomorph/minion = mob_parent
	return !minion?.personal_minion

/// Attach to a caller and enter escort mode. The caller's priority is stored for later takeovers.
/datum/ai_behavior/xeno/proc/begin_minion_call(mob/living/carbon/xenomorph/controller, requested_priority)
	if(!can_be_called_by(controller, requested_priority))
		return FALSE
	rts_guard(controller, controller)
	minion_call_owner_ref = WEAKREF(controller)
	minion_call_priority = requested_priority
	return TRUE

/// Detach only when the request comes from the current owner.
/datum/ai_behavior/xeno/proc/end_minion_call(mob/living/carbon/xenomorph/controller)
	if(get_minion_call_owner() != controller)
		return FALSE
	rts_reset()
	if(has_living_hivemind())
		change_action(IDLE)
	else
		late_initialize()
	return TRUE

/datum/ai_behavior/xeno/proc/rts_move(turf/destination)
	rts_reset()
	hivemind_rts_direct_move = TRUE
	if(rts_advanced_pathing)
		advanced_pathing = TRUE
	if(start_advanced_move(destination))
		return
	change_action(MOVING_TO_ATOM, destination)
	if(!registered_for_move)
		INVOKE_ASYNC(src, PROC_REF(scheduled_move))

/datum/ai_behavior/xeno/proc/rts_attack(atom/target)
	rts_reset()
	set_combat_target(target)
	change_action(MOVING_TO_ATOM, target)
	if(!registered_for_move)
		INVOKE_ASYNC(src, PROC_REF(scheduled_move))

/datum/ai_behavior/xeno/proc/rts_guard(atom/target, datum/source)
	rts_reset()
	set_escorted_atom(source, target)
	change_action(ESCORTING_ATOM, target)
	if(!registered_for_move)
		INVOKE_ASYNC(src, PROC_REF(scheduled_move))

/// Command: fill the acid well with our plasma until it's full or plasma runs out
/datum/ai_behavior/xeno/proc/rts_fill_well(obj/structure/xeno/acidwell/well)
	rts_reset()
	rts_well = well
	well_task_think()

/// TRUE if the tick is busy filling the acid well
/datum/ai_behavior/xeno/proc/well_task_think()
	if(!rts_well || QDELETED(mob_parent))
		return FALSE
	var/mob/living/carbon/xenomorph/X = mob_parent
	if(QDELETED(rts_well) || rts_well.charges >= XENO_ACID_WELL_MAX_CHARGES || X.plasma_stored < XENO_ACID_WELL_FILL_COST || X.z != rts_well.z)
		rts_well = null
		if(hivemind_rts_direct_move)
			rts_finish_move()
		return FALSE
	if(combat_target)
		return FALSE
	if(get_dist(X, rts_well) > 1)
		var/turf/well_turf = get_turf(rts_well)
		if(!hivemind_rts_direct_move || (atom_to_walk_to != well_turf && !adv_route_active))
			hivemind_rts_direct_move = TRUE
			if(rts_advanced_pathing)
				advanced_pathing = TRUE
			if(!start_advanced_move(well_turf))
				change_action(MOVING_TO_ATOM, well_turf)
				if(!registered_for_move)
					INVOKE_ASYNC(src, PROC_REF(scheduled_move))
		return TRUE
	if(hivemind_rts_direct_move)
		rts_finish_move()
	if(X.do_actions)
		return TRUE
	X.face_atom(rts_well)
	INVOKE_ASYNC(rts_well, TYPE_PROC_REF(/obj/structure/xeno/acidwell, fill_charge), X)
	return TRUE

/datum/ai_behavior/xeno/proc/rts_stop()
	rts_reset()
	hivemind_rts_hold_position = TRUE
	set_atom_to_walk_to(null)
	change_action(IDLE)

/// Arrived, or the spot is taken/blocked and we are adjacent to it.
/datum/ai_behavior/xeno/proc/rts_arrived()
	// Intermediate waypoint of an A* route, not the destination.
	if(adv_route_active && length(adv_path))
		return FALSE
	if(!isturf(atom_to_walk_to))
		return TRUE
	var/dist = get_dist(mob_parent, atom_to_walk_to)
	if(dist <= 0)
		return TRUE
	if(dist > 1)
		return FALSE
	var/turf/T = atom_to_walk_to
	if(T.density)
		return TRUE
	for(var/mob/living/L in T)
		if(L != mob_parent && L.density)
			return TRUE
	return FALSE

/datum/ai_behavior/xeno/proc/rts_finish_move()
	clear_adv_route()
	advanced_pathing = initial(advanced_pathing)
	hivemind_rts_direct_move = FALSE
	if(atom_to_walk_to)
		do_unset_target(atom_to_walk_to, need_new_state = FALSE, need_new_escort = FALSE)
	atom_to_walk_to = null
	change_action(IDLE)

/datum/ai_behavior/xeno/should_hold()
	return hivemind_rts_hold_position || ..()

/datum/ai_behavior/xeno/ai_do_move()
	if(hivemind_rts_direct_move && rts_arrived())
		rts_finish_move()
		return
	return ..()

/datum/ai_behavior/xeno/start_ai()
	if(has_living_hivemind())
		clean_escorted_atom()
		base_action = IDLE
	RegisterSignal(mob_parent, COMSIG_XENOMORPH_TAKING_DAMAGE, PROC_REF(check_for_critical_health))
	RegisterSignal(SSdcs, COMSIG_GLOB_AI_MINION_RALLY, PROC_REF(global_set_escorted_atom))
	return ..()

/// Returns TRUE while this xeno's hive has an active Hivemind controller/core.
/// In that state, AI xenos wait for explicit Hivemind orders instead of roaming to AI nodes.
/datum/ai_behavior/xeno/proc/has_living_hivemind()
	if(!mob_parent || QDELETED(mob_parent))
		return FALSE
	var/datum/hive_status/HS = GLOB.hive_datums[mob_parent.get_xeno_hivenumber()]
	if(HS && (HS.get_cached_hivemind_status() || length(HS.hivemindcores)))
		return TRUE
	return FALSE

/datum/ai_behavior/xeno/set_escort()
	if(has_living_hivemind())
		return FALSE
	return ..()

/datum/ai_behavior/xeno/get_atom_to_escort()
	if(has_living_hivemind())
		return null
	return ..()

/datum/ai_behavior/xeno/late_initialize()
	if(has_living_hivemind())
		clean_escorted_atom()
		refresh_abilities()
		change_action(IDLE)
		if(!registered_for_move)
			scheduled_move()
		return
	return ..()

/datum/ai_behavior/xeno/look_for_next_node(blacklist_node = current_node, should_reset_goal_nodes = FALSE)
	if(has_living_hivemind())
		change_action(IDLE)
		return
	return ..()

/datum/ai_behavior/xeno/set_goal_node(datum/source, obj/effect/ai_node/new_goal_node)
	if(has_living_hivemind())
		return FALSE
	return ..()

///Change atom to walk to if the order comes from a corresponding commander
/datum/ai_behavior/xeno/proc/global_set_escorted_atom(datum/source, atom/atom_to_escort)
	SIGNAL_HANDLER
	if(QDELETED(atom_to_escort) || atom_to_escort.get_xeno_hivenumber() != mob_parent.get_xeno_hivenumber() || mob_parent.ckey)
		return
	if(has_living_hivemind())
		return
	if(get_dist(atom_to_escort, mob_parent) > target_distance)
		return
	set_escorted_atom(source, atom_to_escort)

/datum/ai_behavior/xeno/process()
	if(adv_route_active && hivemind_rts_direct_move)
		adv_route_think()
	if(rts_well && !mob_parent?.notransform && well_task_think())
		return
	if(has_living_hivemind())
		if(mob_parent.notransform || mob_parent.do_actions || should_hold())
			return
		var/atom/next_target = get_nearest_target(mob_parent, target_distance, TARGET_HOSTILE, mob_parent.faction, mob_parent.get_xeno_hivenumber(), TRUE)
		look_for_new_state(next_target)
		state_process(next_target)
		var/atom/target_to_use = combat_target ? combat_target : atom_to_walk_to
		if(target_to_use)
			for(var/datum/action/action in ability_list)
				if(!action.ai_should_use(target_to_use))
					continue
				if(istype(action, /datum/action/ability/activable))
					var/datum/action/ability/activable/activable_action = action
					activable_action.use_ability(target_to_use)
				else
					action.action_activate()
		return

	if(mob_parent.notransform)
		return ..()
	if(mob_parent.do_actions) //No activating more abilities if they're already in the progress of doing one
		return ..()
	if(should_hold())
		return ..()

	var/atom/target_to_use = combat_target ? combat_target : atom_to_walk_to
	if(target_to_use)
		for(var/datum/action/action in ability_list)
			if(!action.ai_should_use(target_to_use))
				continue
			//xeno_action/activable is activated with a different proc for keybinded actions, so we gotta use the correct proc
			if(istype(action, /datum/action/ability/activable))
				var/datum/action/ability/activable/activable_action = action
				activable_action.use_ability(target_to_use)
			else
				action.action_activate()
	return ..()

/datum/ai_behavior/xeno/state_process(next_target)
	if(current_action != MOVING_TO_NODE && current_action != FOLLOWING_PATH)
		return
	if(can_heal && mob_parent.health <= minimum_health * 2 * mob_parent.maxHealth)
		try_to_heal() //If we have some damage, look for some healing
		return

/datum/ai_behavior/xeno/look_for_new_state(atom/next_target)
	if(has_living_hivemind())
		if(hivemind_rts_direct_move)
			if(rts_arrived())
				rts_finish_move()
			return
		if(escorted_atom)
			if(next_target && get_dist(escorted_atom, next_target) > HIVEMIND_RTS_GUARD_LEASH)
				next_target = null
			if(combat_target && get_dist(escorted_atom, combat_target) > HIVEMIND_RTS_GUARD_LEASH)
				do_unset_target(combat_target, need_new_state = FALSE)
				change_action(ESCORTING_ATOM, escorted_atom)
				return
		if(need_new_combat_target())
			if(combat_target)
				do_unset_target(combat_target, need_new_state = FALSE)
			if(next_target)
				set_combat_target(next_target)
				if(current_action != MOVING_TO_SAFETY)
					change_action(MOVING_TO_ATOM, next_target)
				return

		if(current_action == MOVING_TO_ATOM)
			if(!combat_target)
				if(escorted_atom)
					change_action(ESCORTING_ATOM, escorted_atom)
					return
				if(!atom_to_walk_to)
					change_action(IDLE)
					return
				if(atom_to_walk_to && get_dist(mob_parent, atom_to_walk_to) <= 1)
					do_unset_target(atom_to_walk_to, need_new_state = FALSE, need_new_escort = FALSE)
					atom_to_walk_to = null
					cleanup_current_action()
					change_action(IDLE)
					return

		if(current_action == MOVING_TO_SAFETY)
			if(!combat_target)
				target_distance = initial(target_distance)
				if(atom_to_walk_to)
					do_unset_target(atom_to_walk_to, need_new_state = FALSE, need_new_escort = FALSE)
					atom_to_walk_to = null
				cleanup_current_action()
				change_action(IDLE)
				RegisterSignal(mob_parent, COMSIG_XENOMORPH_TAKING_DAMAGE, PROC_REF(check_for_critical_health))
				return
			if(combat_target != atom_to_walk_to)
				change_action(null, combat_target, list(INFINITY))
		return

	. = ..()
	if(current_action == MOVING_TO_ATOM)
		if(!combat_target)
			if(escorted_atom)
				change_action(ESCORTING_ATOM, escorted_atom)
				return
			cleanup_current_action()
			late_initialize()
	if(current_action == MOVING_TO_SAFETY)
		if(!combat_target)
			target_distance = initial(target_distance)
			cleanup_current_action()
			late_initialize()
			RegisterSignal(mob_parent, COMSIG_XENOMORPH_TAKING_DAMAGE, PROC_REF(check_for_critical_health))
			return
		if(combat_target != atom_to_walk_to)
			change_action(null, combat_target, list(INFINITY))

/datum/ai_behavior/xeno/need_new_combat_target()
	. = ..()
	if(.)
		return TRUE
	if(!combat_target || QDELETED(combat_target))
		return TRUE
	if(isliving(combat_target))
		var/mob/living/L = combat_target
		if(L.stat == DEAD)
			return TRUE
	if(mob_parent.z != combat_target.z)
		return TRUE
	if(has_living_hivemind())
		if(get_dist(mob_parent, combat_target) > 20)
			return TRUE
		return FALSE
	if(get_dist(mob_parent, combat_target) > target_distance)
		return TRUE
	return FALSE

/datum/ai_behavior/xeno/cleanup_current_action(next_action)
	. = ..()
	if(next_action == MOVING_TO_NODE)
		return
	if(!isxeno(mob_parent))
		return
	if(can_heal && mob_parent.resting)
		SEND_SIGNAL(mob_parent, COMSIG_XENOABILITY_REST)
		UnregisterSignal(mob_parent, COMSIG_XENOMORPH_HEALTH_REGEN)

/datum/ai_behavior/xeno/cleanup_signals()
	. = ..()
	UnregisterSignal(mob_parent, COMSIG_XENOMORPH_TAKING_DAMAGE)
	UnregisterSignal(SSdcs, COMSIG_GLOB_AI_MINION_RALLY)

///Will try finding and resting on weeds
/datum/ai_behavior/xeno/proc/try_to_heal()
	var/mob/living/carbon/xenomorph/xeno_mob = mob_parent
	if(!xeno_mob.loc_weeds_type)
		if(xeno_mob.resting)//We are resting on no weeds
			SEND_SIGNAL(xeno_mob, COMSIG_XENOABILITY_REST)
			UnregisterSignal(xeno_mob, list(COMSIG_XENOMORPH_HEALTH_REGEN, COMSIG_XENOMORPH_PLASMA_REGEN))
		return FALSE
	if(xeno_mob.resting)//Already resting
		if(xeno_mob.on_fire)
			xeno_mob.do_resist()
		return TRUE
	SEND_SIGNAL(xeno_mob, COMSIG_XENOABILITY_REST)
	RegisterSignal(xeno_mob, COMSIG_XENOMORPH_HEALTH_REGEN, PROC_REF(check_for_health), TRUE) //resting can occasionally fail, if you're stunned etc
	RegisterSignal(xeno_mob, COMSIG_XENOMORPH_PLASMA_REGEN, PROC_REF(check_for_plasma), TRUE)
	return TRUE

///Wait for the xeno to be full life and plasma to unrest
/datum/ai_behavior/xeno/proc/check_for_health(mob/living/carbon/xenomorph/healing, list/heal_data)
	SIGNAL_HANDLER
	if(healing.health + heal_data[1] >= healing.maxHealth && healing.plasma_stored >= healing.xeno_caste.plasma_max * healing.xeno_caste.plasma_regen_limit)
		SEND_SIGNAL(mob_parent, COMSIG_XENOABILITY_REST)
		UnregisterSignal(mob_parent, list(COMSIG_XENOMORPH_HEALTH_REGEN, COMSIG_XENOMORPH_PLASMA_REGEN))

///Wait for the xeno to be full life and plasma to unrest
/datum/ai_behavior/xeno/proc/check_for_plasma(mob/living/carbon/xenomorph/healing, list/plasma_data)
	SIGNAL_HANDLER
	if(healing.health >= healing.maxHealth && healing.plasma_stored + plasma_data[1] >= healing.xeno_caste.plasma_max * healing.xeno_caste.plasma_regen_limit)
		SEND_SIGNAL(mob_parent, COMSIG_XENOABILITY_REST)
		UnregisterSignal(mob_parent, list(COMSIG_XENOMORPH_HEALTH_REGEN, COMSIG_XENOMORPH_PLASMA_REGEN))

///Called each time the ai takes damage; if we are below a certain health threshold, try to retreat
/datum/ai_behavior/xeno/proc/check_for_critical_health(datum/source, damage, mob/living/attacker)
	SIGNAL_HANDLER
	if(!can_heal || hivemind_rts_direct_move || hivemind_rts_hold_position || mob_parent.health - damage > minimum_health * mob_parent.maxHealth)
		return
	var/atom/next_target = get_nearest_target(mob_parent, target_distance, TARGET_HOSTILE, mob_parent.faction, mob_parent.get_xeno_hivenumber())
	if(!next_target)
		return
	target_distance = 15
	change_action(MOVING_TO_SAFETY, next_target, list(INFINITY))
	UnregisterSignal(mob_parent, COMSIG_XENOMORPH_TAKING_DAMAGE)

/datum/ai_behavior/xeno/ranged
	/// Orbit turn direction around the guarded target: 90 / -90
	var/orbit_turn = 90
	upper_maintain_dist = 5
	lower_maintain_dist = 4
	upper_engage_dist = 5
	lower_engage_dist = 3
	minimum_health = 0.3

/datum/ai_behavior/xeno/ranged/New(loc, mob/parent_to_assign, atom/escorted_atom)
	. = ..()
	orbit_turn = pick(90, -90)

/// Attack order: stand at spit range (lower..upper_engage_dist), no need to get close
/datum/ai_behavior/xeno/ranged/rts_attack(atom/target)
	. = ..()
	upper_engage_dist = initial(upper_engage_dist)
	lower_engage_dist = initial(lower_engage_dist)

/// While guarding, orbit the target at 2..upper_escort_dist instead of standing still
/datum/ai_behavior/xeno/ranged/find_next_dirs()
	if(current_action == ESCORTING_ATOM && !combat_target && escorted_atom && atom_to_walk_to == escorted_atom)
		var/dist = get_dist(mob_parent, escorted_atom)
		if(dist >= 2 && dist <= upper_escort_dist)
			if(prob(55))
				return
			var/dir_to = angle2dir(Get_Angle(get_turf(mob_parent), get_turf(escorted_atom)))
			return list(turn(dir_to, orbit_turn))
	return ..()

/datum/ai_behavior/xeno/suicidal
	minimum_health = 0
