// Nymph: completes blueprints around herself, fills wells, heals and plasma-feeds allies, plants weeds.
// Does not attack on her own: flees from enemies. Attacks only on a direct hivemind order.

#define NYMPH_WORK_RADIUS 7
#define NYMPH_BLUEPRINT_RADIUS 25
#define NYMPH_WEED_RADIUS 5
#define NYMPH_RECHARGE_RADIUS 22
#define NYMPH_THINK_COOLDOWN 0.5 SECONDS
#define NYMPH_BLACKLIST_TIME 20 SECONDS
#define NYMPH_STUCK_TIMEOUT 6 SECONDS
#define NYMPH_RECHARGE_RETRY 5 SECONDS
#define NYMPH_PLASMA_RESERVE 100
#define NYMPH_PLASMA_RECHARGE_START 0.65
#define NYMPH_PLASMA_RECHARGE_TARGET 0.9
#define NYMPH_JOB_BUILD 1
#define NYMPH_JOB_WEED 2
#define NYMPH_JOB_FILL 3
#define NYMPH_JOB_SUPPORT 4
#define NYMPH_FLEE_RADIUS 6
#define NYMPH_ROUTE_SMOOTH_RANGE 6

/// Job target => nymph that claimed it
GLOBAL_LIST_EMPTY(nymph_job_claims)

/datum/ai_behavior/xeno/nymph
	can_heal = TRUE
	var/atom/job_target
	var/job_type
	/// Following our own job (not a hivemind order)
	var/nymph_moving = FALSE
	var/mob/living/carbon/xenomorph/support_target
	/// Attack on a direct hivemind order (otherwise the nymph attacks no one)
	var/rts_attack_ordered = FALSE
	var/list/blacklist = list()
	/// Reversed A* path for the current autonomous move (next step is at the end).
	var/list/nymph_path = list()
	var/turf/nymph_route_destination
	var/turf/last_resin_turf
	var/route_last_progress_time = 0
	var/route_last_distance = INFINITY
	var/recharge_retry_at = 0
	var/route_is_recharge = FALSE
	/// Persist recharge intent after reaching resin so other idle chores do not interrupt regeneration.
	var/recharging_plasma = FALSE
	COOLDOWN_DECLARE(think_cooldown)

/datum/ai_behavior/xeno/nymph/Destroy(force, ...)
	UnregisterSignal(mob_parent, COMSIG_STATE_MAINTAINED_DISTANCE)
	release_job()
	clear_nymph_route()
	recharging_plasma = FALSE
	support_target = null
	return ..()

/datum/ai_behavior/xeno/nymph/rts_reset()
	. = ..()
	UnregisterSignal(mob_parent, COMSIG_STATE_MAINTAINED_DISTANCE)
	release_job()
	clear_nymph_route()
	recharging_plasma = FALSE
	support_target = null
	rts_attack_ordered = FALSE

/datum/ai_behavior/xeno/nymph/rts_attack(atom/target)
	. = ..()
	rts_attack_ordered = TRUE

/// Guarding an ally = tending to it: heal wounds, and if it's a xeno, give plasma
/datum/ai_behavior/xeno/nymph/rts_guard(atom/target, datum/source)
	. = ..()
	if(isxeno(target) && target != mob_parent)
		support_target = target

/datum/ai_behavior/xeno/nymph/look_for_new_state(atom/next_target)
	if(rts_attack_ordered && !combat_target)
		rts_attack_ordered = FALSE
	if(rts_attack_ordered || hivemind_rts_hold_position || (hivemind_rts_direct_move && !nymph_moving))
		return ..() // hivemind order
	if(nymph_moving)
		return
	return ..(null) // do not pick combat targets ourselves

/// Autonomous routes use the maintained-distance signal to advance A* tiles, not to attack the floor.
/datum/ai_behavior/xeno/nymph/register_action_signals(action_type)
	if(action_type == MOVING_TO_ATOM && nymph_moving)
		RegisterSignal(mob_parent, COMSIG_STATE_MAINTAINED_DISTANCE, PROC_REF(finished_nymph_path_step))
		return
	return ..()

/// Are we under a direct order (then we do not run)
/datum/ai_behavior/xeno/nymph/proc/can_flee()
	return !(rts_attack_ordered || hivemind_rts_hold_position || (hivemind_rts_direct_move && !nymph_moving))

/datum/ai_behavior/xeno/nymph/proc/get_nearest_nymph_threat()
	var/mob/living/carbon/xenomorph/X = mob_parent
	// Search non-xeno threats with the normal hostility rules. Xenos are checked
	// separately so the same-hive comparison is explicit for nymph behaviour.
	var/atom/nearest = get_nearest_target(X, NYMPH_FLEE_RADIUS, TARGET_HOSTILE & ~TARGET_XENO, X.faction, X.get_xeno_hivenumber(), TRUE)
	var/nearest_distance = nearest ? get_dist(X, nearest) : NYMPH_FLEE_RADIUS + 1
	for(var/mob/living/carbon/xenomorph/nearby_xeno in cheap_get_xenos_near(X, NYMPH_FLEE_RADIUS))
		if(nearby_xeno == X || nearby_xeno.stat == DEAD || (X.hive && nearby_xeno.hive == X.hive) || X.issamexenohive(nearby_xeno))
			continue
		if((nearby_xeno.status_flags & (GODMODE|INCORPOREAL)) || nearby_xeno.alpha <= HUNTER_STEALTH_RUN_ALPHA || HAS_TRAIT(nearby_xeno, TRAIT_STEALTH))
			continue
		var/distance = get_dist(X, nearby_xeno)
		if(distance >= nearest_distance || !line_of_sight(X, nearby_xeno))
			continue
		nearest = nearby_xeno
		nearest_distance = distance
	return nearest

/datum/ai_behavior/xeno/nymph/proc/flee_from(atom/threat)
	var/mob/living/carbon/xenomorph/X = mob_parent
	if(isxeno(threat) && X.issamexenohive(threat))
		return
	halt_job()
	if(current_action == MOVING_TO_SAFETY && combat_target == threat)
		return
	set_combat_target(threat)
	change_action(MOVING_TO_SAFETY, threat, list(INFINITY))
	if(!registered_for_move)
		INVOKE_ASYNC(src, PROC_REF(scheduled_move))

/// Critical-health retreat must use the same friendly-hive filtering as autonomous threat checks.
/datum/ai_behavior/xeno/nymph/check_for_critical_health(datum/source, damage, mob/living/attacker)
	if(!can_heal || hivemind_rts_direct_move || hivemind_rts_hold_position || mob_parent.health - damage > minimum_health * mob_parent.maxHealth)
		return
	var/atom/next_target = get_nearest_nymph_threat()
	if(!next_target)
		return
	target_distance = 15
	flee_from(next_target)
	UnregisterSignal(mob_parent, COMSIG_XENOMORPH_TAKING_DAMAGE)

/// No threat: return to the normal state
/datum/ai_behavior/xeno/nymph/proc/stop_fleeing()
	if(combat_target)
		do_unset_target(combat_target, need_new_state = FALSE)
	if(has_living_hivemind())
		change_action(escorted_atom ? ESCORTING_ATOM : IDLE, escorted_atom)
		return
	cleanup_current_action()
	late_initialize()

/datum/ai_behavior/xeno/nymph/process()
	if(mob_parent && !QDELETED(mob_parent))
		if(nymph_moving && (mob_parent.stat != CONSCIOUS || mob_parent.notransform || mob_parent.do_actions || should_hold()))
			// Do not count stuns, actions or ally-wrangling as pathfinding failure.
			route_last_progress_time = world.time
		else if(mob_parent.stat == CONSCIOUS && !mob_parent.notransform && !mob_parent.do_actions)
			nymph_think()
	return ..()

/datum/ai_behavior/xeno/nymph/proc/nymph_think()
	var/mob/living/carbon/xenomorph/X = mob_parent
	if(QDELETED(X) || X.stat != CONSCIOUS || X.notransform || X.do_actions || !X.canmove)
		return
	if(!COOLDOWN_FINISHED(src, think_cooldown))
		return
	COOLDOWN_START(src, think_cooldown, NYMPH_THINK_COOLDOWN)
	var/turf/current_turf = get_turf(X)
	if(X.loc_weeds_type)
		last_resin_turf = current_turf
	// A direct well order takes precedence over autonomous work and threat avoidance.
	if(rts_well)
		return
	if(can_flee())
		var/atom/threat = get_nearest_nymph_threat()
		if(threat)
			// A stale combat target must never make a nymph flee from a member of her own hive.
			if(isxeno(threat) && X.issamexenohive(threat))
				do_unset_target(threat, need_new_state = FALSE)
			else
				flee_from(threat)
				return
		if(current_action == MOVING_TO_SAFETY)
			stop_fleeing()
	if(support_target)
		if(QDELETED(support_target) || support_target.stat == DEAD || support_target.z != X.z || \
			(support_target.status_flags & INCORPOREAL) || support_target.hivenumber != X.get_xeno_hivenumber())
			// Do not leave the nymph stuck escorting a deleted/dead target.
			rts_reset()
			if(has_living_hivemind())
				change_action(IDLE)
			else
				late_initialize()
			return
		// Stay with the escorted ally, but only spend actions when they actually need help.
		if(support_need(support_target, 0.7))
			support_act(support_target, 0.7)
		return
	if(!is_free())
		return
	// Autonomous A* routes use smoothed, verified waypoints. Do not issue a new goal
	// while following a route, otherwise direct-vector movement can oscillate.
	if(nymph_moving)
		if(job_target && !job_valid())
			halt_job()
			return
		if(route_is_recharge && (!nymph_route_destination || !(locate(/obj/alien/weeds) in nymph_route_destination)))
			recharge_retry_at = world.time + NYMPH_RECHARGE_RETRY
			recharging_plasma = FALSE
			halt_job()
			return
		var/turf/next_step = get_turf(atom_to_walk_to)
		var/distance_to_step = next_step ? get_dist(X, next_step) : INFINITY
		if(distance_to_step < route_last_distance)
			route_last_distance = distance_to_step
			route_last_progress_time = world.time
		else if(world.time >= route_last_progress_time + NYMPH_STUCK_TIMEOUT)
			// No progress includes oscillating between two tiles at the same distance.
			var/atom/failed_goal = job_target ? job_target : nymph_route_destination
			if(failed_goal)
				blacklist[failed_goal] = world.time + NYMPH_BLACKLIST_TIME
			if(route_is_recharge)
				recharge_retry_at = world.time + NYMPH_RECHARGE_RETRY
				recharging_plasma = FALSE
			halt_job()
		return
	if(job_target && !job_valid())
		release_job()
	if(!job_target)
		find_job()
	// Construction is evaluated before recharge. Once there is a reachable,
	// affordable blueprint, the nymph leaves the resin and works on it.
	if(nymph_moving)
		return
	if(!job_target)
		return
	if(X.resting)
		SEND_SIGNAL(X, COMSIG_XENOABILITY_REST)
	if(job_in_reach())
		halt_job(FALSE)
		INVOKE_ASYNC(src, PROC_REF(do_job))
		return
	if(!go_to_job())
		blacklist[job_target] = world.time + NYMPH_BLACKLIST_TIME
		halt_job()

/// Free for independent work: no order, combat, or escort
/datum/ai_behavior/xeno/nymph/proc/is_free()
	if(hivemind_rts_hold_position || combat_target || escorted_atom)
		return FALSE
	if(hivemind_rts_direct_move && !nymph_moving)
		return FALSE
	return TRUE

/datum/ai_behavior/xeno/nymph/proc/go_to_job()
	var/list/route = get_route_to_job(job_target, job_type)
	if(!route)
		return FALSE
	var/list/path = route["path"]
	var/turf/destination = route["destination"]
	if(!length(path))
		return TRUE
	return start_nymph_route(path, destination)

/// Halt our own transition; drop_job = FALSE keeps the job claimed.
/datum/ai_behavior/xeno/nymph/proc/halt_job(drop_job = TRUE)
	if(nymph_moving)
		UnregisterSignal(mob_parent, COMSIG_STATE_MAINTAINED_DISTANCE)
		clear_nymph_route()
		rts_finish_move()
	if(drop_job)
		release_job()

/datum/ai_behavior/xeno/nymph/proc/release_job()
	if(job_target && GLOB.nymph_job_claims[job_target] == src)
		GLOB.nymph_job_claims -= job_target
	job_target = null
	job_type = null

/datum/ai_behavior/xeno/nymph/proc/claim(atom/target, job)
	job_target = target
	job_type = job
	GLOB.nymph_job_claims[target] = src

/// Find the shortest reachable tile from which this job can be completed.
/datum/ai_behavior/xeno/nymph/proc/get_route_to_job(atom/target, job)
	var/turf/start = get_turf(mob_parent)
	var/turf/goal = get_turf(target)
	if(!start || !goal || start.z != goal.z)
		return null
	var/list/candidates = list()
	if(job == NYMPH_JOB_WEED)
		candidates += goal
	else if(job == NYMPH_JOB_BUILD)
		// Resin blueprints are built from a cardinally adjacent tile. This avoids
		// choosing a diagonal tile that is technically close but trapped by corners.
		for(var/direction in list(NORTH, SOUTH, EAST, WEST))
			var/turf/candidate = get_step(goal, direction)
			if(!candidate || candidate.density || (candidate.atom_flags & AI_BLOCKED) || is_blocked_turf(candidate))
				continue
			candidates += candidate
	else
		for(var/turf/candidate in orange(1, goal))
			if(candidate.density || (candidate.atom_flags & AI_BLOCKED) || is_blocked_turf(candidate))
				continue
			candidates += candidate
	var/turf/best_destination
	var/list/best_path
	var/best_length = INFINITY
	for(var/turf/candidate in candidates)
		var/list/path
		if(candidate == start)
			path = list()
		else
			path = get_path(start, candidate, TILE_PATHING)
		if(isnull(path))
			continue
		if(length(path) < best_length)
			best_length = length(path)
			best_destination = candidate
			best_path = path
			if(!best_length)
				break
	if(!best_destination)
		return null
	return list("path" = best_path, "destination" = best_destination)

/// Start following a reversed tile path. Path order is goal-to-start in get_path().
/datum/ai_behavior/xeno/nymph/proc/start_nymph_route(list/path, turf/destination, recharge = FALSE)
	if(!path || !length(path) || !destination)
		return FALSE
	clear_nymph_route()
	nymph_path = path.Copy()
	nymph_route_destination = destination
	route_is_recharge = recharge
	nymph_moving = TRUE
	var/turf/next_step = pop_next_nymph_waypoint()
	if(!next_step)
		clear_nymph_route()
		return FALSE
	route_last_progress_time = world.time
	route_last_distance = get_dist(mob_parent, next_step)
	change_action(MOVING_TO_ATOM, next_step)
	return TRUE

/// Remove the next verified A* waypoint, skipping straight, unobstructed tiles.
/datum/ai_behavior/xeno/nymph/proc/pop_next_nymph_waypoint()
	if(!length(nymph_path))
		return null
	var/turf/start = get_turf(mob_parent)
	var/next_path_index = length(nymph_path)
	var/turf/next_step = nymph_path[next_path_index]
	if(start)
		// Collapse consecutive A* tiles into the furthest point reachable by a
		// shortest direct route. Walls and blocked corners keep their own waypoints.
		for(var/i = next_path_index - 1, i >= 1, i--)
			var/turf/candidate = nymph_path[i]
			var/distance = get_dist(start, candidate)
			if(distance > NYMPH_ROUTE_SMOOTH_RANGE || !line_of_sight(start, candidate, NYMPH_ROUTE_SMOOTH_RANGE))
				break
			var/list/direct_path = get_path(start, candidate, TILE_PATHING)
			if(isnull(direct_path) || length(direct_path) != distance)
				break
			next_path_index = i
			next_step = candidate
	nymph_path.Cut(next_path_index)
	return next_step

/// Called by the movement state when the current path tile is reached.
/datum/ai_behavior/xeno/nymph/proc/finished_nymph_path_step()
	SIGNAL_HANDLER
	if(!nymph_moving)
		return COMSIG_MAINTAIN_POSITION
	if(length(nymph_path))
		var/turf/next_step = pop_next_nymph_waypoint()
		if(next_step)
			set_atom_to_walk_to(next_step)
			route_last_progress_time = world.time
			route_last_distance = get_dist(mob_parent, next_step)
			return COMSIG_MAINTAIN_POSITION
	nymph_moving = FALSE
	nymph_route_destination = null
	route_is_recharge = FALSE
	nymph_path = list()
	rts_finish_move()
	return COMSIG_MAINTAIN_POSITION

/// Remove only nymph-owned route state. The caller decides whether to change the AI action.
/datum/ai_behavior/xeno/nymph/proc/clear_nymph_route()
	nymph_moving = FALSE
	nymph_path = list()
	nymph_route_destination = null
	route_last_progress_time = 0
	route_last_distance = INFINITY
	route_is_recharge = FALSE

/// Return to a resin tile when plasma is low, then rest until the reserve is replenished.
/datum/ai_behavior/xeno/nymph/proc/seek_resin()
	var/mob/living/carbon/xenomorph/X = mob_parent
	if(X.loc_weeds_type)
		recharging_plasma = TRUE
		if(!X.resting)
			SEND_SIGNAL(X, COMSIG_XENOABILITY_REST)
		return TRUE
	if(world.time < recharge_retry_at)
		return FALSE
	var/turf/start = get_turf(X)
	if(!start)
		return FALSE
	var/turf/best_destination
	var/list/best_path
	var/best_length = INFINITY
	var/checked_paths = 0
	for(var/obj/alien/weeds/weed in range(NYMPH_RECHARGE_RADIUS, start))
		var/turf/candidate = get_turf(weed)
		if(!candidate || candidate.z != start.z || candidate.density || (candidate.atom_flags & AI_BLOCKED) || (candidate != start && is_blocked_turf(candidate)))
			continue
		var/distance = get_dist(start, candidate)
		if(distance >= best_length || checked_paths >= 30 || in_blacklist(candidate))
			continue
		checked_paths++
		var/list/path
		if(candidate == start)
			path = list()
		else
			path = get_path(start, candidate, TILE_PATHING)
		if(isnull(path))
			continue
		if(length(path) < best_length)
			best_length = length(path)
			best_destination = candidate
			best_path = path
	if(last_resin_turf && !QDELETED(last_resin_turf) && last_resin_turf.z == start.z && (locate(/obj/alien/weeds) in last_resin_turf) && !is_blocked_turf(last_resin_turf) && !in_blacklist(last_resin_turf))
		var/last_distance = get_dist(start, last_resin_turf)
		if(last_distance < best_length && last_distance <= NYMPH_RECHARGE_RADIUS * 2)
			var/list/last_path
			if(last_resin_turf == start)
				last_path = list()
			else
				last_path = get_path(start, last_resin_turf, TILE_PATHING)
			if(!isnull(last_path) && length(last_path) < best_length)
				best_length = length(last_path)
				best_destination = last_resin_turf
				best_path = last_path
	if(!best_destination)
		recharge_retry_at = world.time + NYMPH_RECHARGE_RETRY
		return FALSE
	if(!length(best_path))
		if(X.loc_weeds_type || (locate(/obj/alien/weeds) in best_destination))
			recharging_plasma = TRUE
			if(!X.resting)
				SEND_SIGNAL(X, COMSIG_XENOABILITY_REST)
			return TRUE
		return FALSE
	recharging_plasma = TRUE
	return start_nymph_route(best_path, best_destination, TRUE)

/// Claimed by another nymph (stale entries are cleaned up)
/datum/ai_behavior/xeno/nymph/proc/claimed_by_other(atom/target)
	var/datum/ai_behavior/xeno/nymph/owner = GLOB.nymph_job_claims[target]
	if(!owner || owner == src)
		return FALSE
	if(QDELETED(owner) || owner.job_target != target)
		GLOB.nymph_job_claims -= target
		return FALSE
	return TRUE

/// Another's job adjacent to the turf: do not build nearby at the same time
/datum/ai_behavior/xeno/nymph/proc/other_claim_near(turf/T)
	for(var/atom/claimed AS in GLOB.nymph_job_claims)
		if(QDELETED(claimed) || !claimed_by_other(claimed))
			continue
		if(get_dist(get_turf(claimed), T) <= 1)
			return TRUE
	return FALSE

/// Find a free adjacent turf so a nymph standing on a wall blueprint can step off before building.
/datum/ai_behavior/xeno/nymph/proc/get_build_step_off_turf(turf/build_turf)
	if(!build_turf || get_turf(mob_parent) != build_turf)
		return null
	var/turf/best_turf
	var/best_score = INFINITY
	// Use cardinal neighbours: diagonal step-off points can be unreachable when
	// both adjoining cardinal tiles are blocked.
	for(var/direction in list(NORTH, SOUTH, EAST, WEST))
		var/turf/candidate = get_step(build_turf, direction)
		if(!candidate || is_blocked_turf(candidate) || candidate.z != build_turf.z)
			continue
		var/score = get_dist(mob_parent, candidate)
		if(score < best_score)
			best_score = score
			best_turf = candidate
	return best_turf

/datum/ai_behavior/xeno/nymph/proc/build_would_trap(turf/T, datum/xeno_build_entry/entry)
	if(!entry || !ispath(entry.path, /turf/closed))
		return FALSE
	for(var/mob/living/carbon/xenomorph/nymph/other in range(2, T))
		if(other.stat == DEAD)
			continue
		var/turf/their = get_turf(other)
		if(their == T)
			// Our own nymph can safely build after moving one tile away. Other nymphs
			// on the blueprint tile would be trapped, so keep refusing that build.
			if(other == mob_parent && get_build_step_off_turf(T))
				continue
			return TRUE
		var/free = 0
		for(var/turf/N in orange(1, their))
			if(N != T && !is_blocked_turf(N))
				free++
		if(free <= 0)
			return TRUE
	return FALSE

/datum/ai_behavior/xeno/nymph/proc/in_blacklist(atom/A)
	var/until = blacklist[A]
	if(!until)
		return FALSE
	if(until < world.time)
		blacklist -= A
		return FALSE
	return TRUE

/datum/ai_behavior/xeno/nymph/proc/find_job()
	var/mob/living/carbon/xenomorph/X = mob_parent
	var/turf/own = get_turf(X)
	if(!own)
		return
	var/hive = X.hivenumber
	var/plasma_capacity = X.xeno_caste.plasma_max * X.xeno_caste.plasma_regen_limit
	var/best_score = INFINITY
	var/obj/effect/xeno_blueprint/best
	var/needs_build_plasma = FALSE
	// Look across the whole nearby hive blueprint list, not just the immediate area.
	// This lets the nymph head toward construction instead of aimlessly planting weeds.
	for(var/obj/effect/xeno_blueprint/bp in GLOB.xeno_blueprints[hive])
		if(QDELETED(bp) || bp.hivenumber != hive || bp.z != own.z || get_dist(own, bp) > NYMPH_BLUEPRINT_RADIUS || claimed_by_other(bp) || in_blacklist(bp))
			continue
		var/turf/T = get_turf(bp)
		if(!bp.is_demolish)
			if(!bp.entry || bp.entry.kind != BUILD_KIND_RESIN || bp.entry.unavailable_reason(X))
				continue
			var/blueprint_error = bp.entry.check_turf(T)
			if(blueprint_error != NO_ERROR && blueprint_error != ERROR_NO_WEED)
				continue
			if(build_would_trap(T, bp.entry) || other_claim_near(T))
				continue
			var/required_plasma = 0
			if(blueprint_error == ERROR_NO_WEED)
				var/datum/action/ability/activable/xeno/plant_weeds/weeds = X.actions_by_path[/datum/action/ability/activable/xeno/plant_weeds]
				if(!weeds)
					continue
				required_plasma += weeds.ability_cost
			var/list/build_state = bp.entry.get_state_data(X)
			required_plasma += build_state["cost"]
			// Do not wait forever on a blueprint whose combined planting/build cost
			// exceeds the nymph's maximum plasma capacity.
			if(required_plasma > plasma_capacity)
				continue
			if(X.plasma_stored < required_plasma)
				needs_build_plasma = TRUE
				continue
		var/score = get_dist(own, T) + (bp.auto_rebuild ? -3 : 0)
		if(score < best_score)
			best_score = score
			best = bp
	if(best)
		recharging_plasma = FALSE
		claim(best, NYMPH_JOB_BUILD)
		return
	// Keep resting on resin until the appropriate reserve is reached. If a blueprint
	// is waiting, charge to the full capacity; otherwise keep a 90% passive reserve.
	var/recharge_target = needs_build_plasma ? plasma_capacity : plasma_capacity * NYMPH_PLASMA_RECHARGE_TARGET
	if(recharging_plasma && X.plasma_stored >= recharge_target)
		recharging_plasma = FALSE
		if(X.resting)
			SEND_SIGNAL(X, COMSIG_XENOABILITY_REST)
	if(recharging_plasma && X.loc_weeds_type && X.plasma_stored < recharge_target)
		if(!X.resting)
			SEND_SIGNAL(X, COMSIG_XENOABILITY_REST)
		return
	// Construction comes before support and well filling. When a blueprint is waiting
	// for plasma, reserve resources and head for resin before doing secondary work.
	var/return_to_weed_jobs = FALSE
	var/should_recharge = needs_build_plasma || (plasma_capacity > 0 && X.plasma_stored < plasma_capacity * NYMPH_PLASMA_RECHARGE_START)
	if(should_recharge)
		recharging_plasma = TRUE
		if(seek_resin())
			return
		// No reachable resin nearby: allow planting weeds to create a future recharge
		// point, but do not spend a low plasma reserve on support actions or acid wells.
		return_to_weed_jobs = TRUE
	// No blueprints and sufficient plasma: tend wounded/hungry allies.
	if(!return_to_weed_jobs)
		var/mob/living/carbon/xenomorph/best_patient
		best_score = INFINITY
		for(var/mob/living/carbon/xenomorph/patient in range(NYMPH_WORK_RADIUS, own))
			if(istype(patient, /mob/living/carbon/xenomorph/nymph) || claimed_by_other(patient) || in_blacklist(patient) || !support_need(patient))
				continue
			var/dist = get_dist(own, patient)
			if(dist < best_score)
				best_score = dist
				best_patient = patient
		if(best_patient)
			claim(best_patient, NYMPH_JOB_SUPPORT)
			return
		// Then fill allied wells.
		if(X.plasma_stored >= XENO_ACID_WELL_FILL_COST)
			var/obj/structure/xeno/acidwell/best_well
			best_score = INFINITY
			for(var/obj/structure/xeno/acidwell/well in range(NYMPH_WORK_RADIUS, own))
				if(well.get_xeno_hivenumber() != hive || well.charges >= XENO_ACID_WELL_MAX_CHARGES || claimed_by_other(well) || in_blacklist(well))
					continue
				var/dist = get_dist(own, well)
				if(dist < best_score)
					best_score = dist
					best_well = well
			if(best_well)
				claim(best_well, NYMPH_JOB_FILL)
				return
	// Otherwise seed the surroundings with weeds.
	var/datum/action/ability/activable/xeno/plant_weeds/weeds = X.actions_by_path[/datum/action/ability/activable/xeno/plant_weeds]
	if(!weeds || !weeds.can_use_action(TRUE, ABILITY_IGNORE_SELECTED_ABILITY))
		return
	var/list/candidates = list()
	for(var/turf/T in oview(NYMPH_WEED_RADIUS, own))
		if(T.density || !T.is_weedable() || (locate(/obj/alien/weeds) in T) || claimed_by_other(T) || in_blacklist(T))
			continue
		candidates += T
	shuffle_inplace(candidates)
	var/checked = 0
	for(var/turf/T AS in candidates)
		if(checked++ >= 10)
			break
		if(locate(/obj/alien/weeds) in range(2, T))
			continue
		if(other_claim_near(T))
			continue
		claim(T, NYMPH_JOB_WEED)
		return

/datum/ai_behavior/xeno/nymph/proc/job_valid()
	var/mob/living/carbon/xenomorph/X = mob_parent
	if(QDELETED(job_target) || claimed_by_other(job_target))
		return FALSE
	var/max_job_distance = job_type == NYMPH_JOB_BUILD ? NYMPH_BLUEPRINT_RADIUS + 3 : NYMPH_WORK_RADIUS + 3
	if(job_target.z != X.z || get_dist(X, job_target) > max_job_distance)
		return FALSE
	if(in_blacklist(job_target))
		return FALSE
	switch(job_type)
		if(NYMPH_JOB_BUILD)
			var/obj/effect/xeno_blueprint/bp = job_target
			if(bp.is_demolish)
				return TRUE
			if(!bp.entry || bp.entry.kind != BUILD_KIND_RESIN || bp.entry.unavailable_reason(X))
				return FALSE
			var/turf/build_turf = get_turf(bp)
			var/build_error = bp.entry.check_turf(build_turf)
			if(build_error != NO_ERROR && build_error != ERROR_NO_WEED)
				return FALSE
			var/list/build_state = bp.entry.get_state_data(X)
			var/required_plasma = build_state["cost"]
			if(build_error == ERROR_NO_WEED)
				var/datum/action/ability/activable/xeno/plant_weeds/weeds = X.actions_by_path[/datum/action/ability/activable/xeno/plant_weeds]
				if(!weeds)
					return FALSE
				required_plasma += weeds.ability_cost
			return X.plasma_stored >= required_plasma
		if(NYMPH_JOB_WEED)
			return !(locate(/obj/alien/weeds) in get_turf(job_target))
		if(NYMPH_JOB_FILL)
			var/obj/structure/xeno/acidwell/well = job_target
			var/mob/living/carbon/xenomorph/xeno = mob_parent
			return well.charges < XENO_ACID_WELL_MAX_CHARGES && xeno.plasma_stored >= XENO_ACID_WELL_FILL_COST
		if(NYMPH_JOB_SUPPORT)
			var/mob/living/carbon/xenomorph/patient = job_target
			return !!support_need(patient)
	return TRUE

/datum/ai_behavior/xeno/nymph/proc/job_in_reach()
	if(job_type == NYMPH_JOB_BUILD)
		var/mob/living/carbon/xenomorph/X = mob_parent
		var/turf/build_turf = get_turf(job_target)
		return get_turf(X) != build_turf && X.in_build_reach(build_turf)
	return get_dist(mob_parent, job_target) <= 1

/datum/ai_behavior/xeno/nymph/proc/do_job()
	var/mob/living/carbon/xenomorph/X = mob_parent
	var/atom/target = job_target
	var/job = job_type
	if(QDELETED(X) || QDELETED(target))
		release_job()
		return
	var/turf/T = get_turf(target)
	var/ok = FALSE
	if(job == NYMPH_JOB_WEED)
		ok = plant_weeds_at(T)
	else if(job == NYMPH_JOB_FILL)
		var/obj/structure/xeno/acidwell/well = target
		ok = well.fill_charge(X)
	else if(job == NYMPH_JOB_SUPPORT)
		var/mob/living/carbon/xenomorph/patient = target
		ok = support_act(patient, 0.5)
	else
		var/obj/effect/xeno_blueprint/bp = target
		if(bp.is_demolish)
			ok = X.try_build_blueprint(bp)
		else
			var/err = bp.entry.check_turf(T)
			if(err == ERROR_NO_WEED)
				ok = plant_weeds_at(T) // no weeds under the blueprint: plant them first, build on the next pass
				if(ok)
					release_job()
					COOLDOWN_RESET(src, think_cooldown)
					INVOKE_ASYNC(src, PROC_REF(nymph_think))
					return
			else if(err == NO_ERROR && !build_would_trap(T, bp.entry))
				ok = X.try_build_blueprint(bp)
	if(!ok)
		blacklist[target] = world.time + NYMPH_BLACKLIST_TIME
	release_job()
	if(ok)
		// Do not wait for the next one-second AI think cycle between adjacent builds.
		COOLDOWN_RESET(src, think_cooldown)
		INVOKE_ASYNC(src, PROC_REF(nymph_think))

/datum/ai_behavior/xeno/nymph/proc/plant_weeds_at(turf/T)
	var/mob/living/carbon/xenomorph/X = mob_parent
	var/datum/action/ability/activable/xeno/plant_weeds/weeds = X.actions_by_path[/datum/action/ability/activable/xeno/plant_weeds]
	if(!weeds || !T || !weeds.can_use_action(TRUE, ABILITY_IGNORE_SELECTED_ABILITY))
		return FALSE
	if(locate(/obj/alien/weeds) in T)
		return TRUE
	X.face_atom(T)
	weeds.plant_weeds(T)
	// Planting on our current turf does not emit a movement signal; refresh the
	// resin-floor state explicitly so the nymph can start regenerating immediately.
	X.handle_weeds_on_movement()
	return !!(locate(/obj/alien/weeds) in T)

/// What the patient needs: "heal" / "plasma" / null. plasma_ratio - plasma fraction threshold
/datum/ai_behavior/xeno/nymph/proc/support_need(mob/living/carbon/xenomorph/patient, plasma_ratio = 0.5)
	var/mob/living/carbon/xenomorph/X = mob_parent
	if(!patient || QDELETED(patient) || patient == X || patient.stat == DEAD || (patient.status_flags & INCORPOREAL) || patient.hivenumber != X.hivenumber)
		return null
	if(patient.health < patient.maxHealth * 0.95 && X.actions_by_path[/datum/action/ability/activable/xeno/psychic_cure/nymph_salve] && X.plasma_stored >= 40)
		return "heal"
	if((patient.xeno_caste.can_flags & CASTE_CAN_BE_GIVEN_PLASMA) && patient.xeno_caste.plasma_max > 0 && patient.plasma_stored < patient.xeno_caste.plasma_max * plasma_ratio && X.plasma_stored > NYMPH_PLASMA_RESERVE)
		return "plasma"
	return null

/// Wound -> salve, healed but low plasma -> plasma. Returns TRUE if the ability was triggered
/datum/ai_behavior/xeno/nymph/proc/support_act(mob/living/carbon/xenomorph/patient, plasma_ratio = 0.5)
	if(!patient || QDELETED(patient) || mob_parent.do_actions || get_dist(mob_parent, patient) > 2)
		return FALSE
	var/mob/living/carbon/xenomorph/X = mob_parent
	var/datum/action/ability/activable/xeno/psychic_cure/nymph_salve/salve = X.actions_by_path[/datum/action/ability/activable/xeno/psychic_cure/nymph_salve]
	var/datum/action/ability/activable/xeno/transfer_plasma/nymph/plasma = X.actions_by_path[/datum/action/ability/activable/xeno/transfer_plasma/nymph]
	var/need = support_need(patient, plasma_ratio)
	if(need == "heal" && salve?.can_use_ability(patient, TRUE, ABILITY_IGNORE_SELECTED_ABILITY))
		INVOKE_ASYNC(salve, TYPE_PROC_REF(/datum/action/ability/activable, use_ability), patient)
		return TRUE
	var/wants_plasma = (patient.xeno_caste.can_flags & CASTE_CAN_BE_GIVEN_PLASMA) && patient.plasma_stored < patient.xeno_caste.plasma_max * plasma_ratio && X.plasma_stored > NYMPH_PLASMA_RESERVE
	if(wants_plasma && plasma?.can_use_ability(patient, TRUE, ABILITY_IGNORE_SELECTED_ABILITY)) // give plasma to the wounded even if salve is on cooldown
		INVOKE_ASYNC(plasma, TYPE_PROC_REF(/datum/action/ability/activable, use_ability), patient)
		return TRUE
	return FALSE

#undef NYMPH_WORK_RADIUS
#undef NYMPH_BLUEPRINT_RADIUS
#undef NYMPH_WEED_RADIUS
#undef NYMPH_RECHARGE_RADIUS
#undef NYMPH_THINK_COOLDOWN
#undef NYMPH_BLACKLIST_TIME
#undef NYMPH_STUCK_TIMEOUT
#undef NYMPH_RECHARGE_RETRY
#undef NYMPH_PLASMA_RESERVE
#undef NYMPH_PLASMA_RECHARGE_START
#undef NYMPH_PLASMA_RECHARGE_TARGET
#undef NYMPH_JOB_BUILD
#undef NYMPH_JOB_WEED
#undef NYMPH_JOB_FILL
#undef NYMPH_JOB_SUPPORT
#undef NYMPH_FLEE_RADIUS
#undef NYMPH_ROUTE_SMOOTH_RANGE
