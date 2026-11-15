// Advanced (A*) tile pathing for xeno AI. Shared by every /datum/ai_behavior/xeno subtype.
// Routes are reversed get_path() lists (next step at the end), smoothed into verified waypoints.
// Toggle: advanced_pathing. Nymphs keep it on; other minions get it enabled for the duration of Hivemind RTS move orders.

#define ADV_PATH_SMOOTH_RANGE 6
#define ADV_PATH_STUCK_TIMEOUT 6 SECONDS
#define ADV_PATH_MAX_REPATHS 2
#define ADV_PATH_MAX_DIST 50

/datum/ai_behavior/xeno
	/// Master switch: when FALSE, movement orders use plain direct-vector walking.
	var/advanced_pathing = FALSE
	/// If TRUE, Hivemind RTS move orders turn advanced_pathing on until the order ends.
	var/rts_advanced_pathing = TRUE
	/// Reversed A* path for the current route (next step is at the end).
	var/list/adv_path = list()
	var/turf/adv_route_destination
	var/adv_route_active = FALSE
	var/adv_route_last_progress_time = 0
	var/adv_route_last_distance = INFINITY
	var/adv_route_repaths = 0

/// Builds an A* route to destination and starts following it. FALSE = caller should fall back to direct movement.
/datum/ai_behavior/xeno/proc/start_advanced_move(turf/destination)
	if(!advanced_pathing || !destination || QDELETED(mob_parent))
		return FALSE
	var/turf/start = get_turf(mob_parent)
	if(!start || start.z != destination.z || get_dist(start, destination) <= 1 || get_dist(start, destination) > ADV_PATH_MAX_DIST)
		return FALSE
	if(destination.density || (destination.atom_flags & AI_BLOCKED))
		return FALSE
	var/list/path = get_path(start, destination, TILE_PATHING)
	if(!length(path))
		return FALSE
	return start_adv_route(path, destination)

/// Start following a reversed tile path (goal first, next step last).
/datum/ai_behavior/xeno/proc/start_adv_route(list/path, turf/destination, repaths = 0)
	if(!length(path) || !destination)
		return FALSE
	clear_adv_route()
	adv_path = path.Copy()
	adv_route_destination = destination
	adv_route_repaths = repaths
	adv_route_active = TRUE
	var/turf/next_step = pop_next_adv_waypoint()
	if(!next_step)
		clear_adv_route()
		return FALSE
	adv_route_last_progress_time = world.time
	adv_route_last_distance = get_dist(mob_parent, next_step)
	change_action(MOVING_TO_ATOM, next_step)
	if(!registered_for_move)
		INVOKE_ASYNC(src, PROC_REF(scheduled_move))
	return TRUE

/// Remove the next verified waypoint, skipping straight, unobstructed tiles.
/datum/ai_behavior/xeno/proc/pop_next_adv_waypoint()
	if(!length(adv_path))
		return null
	var/turf/start = get_turf(mob_parent)
	var/next_path_index = length(adv_path)
	var/turf/next_step = adv_path[next_path_index]
	if(start)
		// Collapse consecutive A* tiles into the furthest point reachable by a shortest direct route.
		for(var/i = next_path_index - 1, i >= 1, i--)
			var/turf/candidate = adv_path[i]
			var/distance = get_dist(start, candidate)
			if(distance > ADV_PATH_SMOOTH_RANGE || !line_of_sight(start, candidate, ADV_PATH_SMOOTH_RANGE))
				break
			var/list/direct_path = get_path(start, candidate, TILE_PATHING)
			if(isnull(direct_path) || length(direct_path) != distance)
				break
			next_path_index = i
			next_step = candidate
	adv_path.Cut(next_path_index)
	return next_step

/// Movement-state signal: current waypoint reached.
/datum/ai_behavior/xeno/proc/finished_adv_path_step()
	SIGNAL_HANDLER
	if(!adv_route_active)
		return COMSIG_MAINTAIN_POSITION
	if(length(adv_path))
		var/turf/next_step = pop_next_adv_waypoint()
		if(next_step)
			set_atom_to_walk_to(next_step)
			adv_route_last_progress_time = world.time
			adv_route_last_distance = get_dist(mob_parent, next_step)
			return COMSIG_MAINTAIN_POSITION
	clear_adv_route()
	rts_finish_move()
	return COMSIG_MAINTAIN_POSITION

/// Drops route state only; the caller decides the next AI action.
/datum/ai_behavior/xeno/proc/clear_adv_route()
	adv_route_active = FALSE
	adv_path = list()
	adv_route_destination = null
	adv_route_last_progress_time = 0
	adv_route_last_distance = INFINITY
	adv_route_repaths = 0

/// Routes advance via the maintained-distance signal instead of attacking/interacting with the floor.
/datum/ai_behavior/xeno/register_action_signals(action_type)
	if(action_type == MOVING_TO_ATOM && adv_route_active)
		RegisterSignal(mob_parent, COMSIG_STATE_MAINTAINED_DISTANCE, PROC_REF(finished_adv_path_step))
		return
	return ..()

/// Stuck detection for order-driven routes (nymph job routes use their own watchdog).
/datum/ai_behavior/xeno/proc/adv_route_think()
	var/mob/living/carbon/xenomorph/X = mob_parent
	if(QDELETED(X))
		return
	if(X.stat != CONSCIOUS || X.notransform || X.do_actions || should_hold())
		adv_route_last_progress_time = world.time
		return
	var/turf/next_step = get_turf(atom_to_walk_to)
	var/distance_to_step = next_step ? get_dist(X, next_step) : INFINITY
	if(distance_to_step < adv_route_last_distance)
		adv_route_last_distance = distance_to_step
		adv_route_last_progress_time = world.time
		return
	if(world.time < adv_route_last_progress_time + ADV_PATH_STUCK_TIMEOUT)
		return
	var/turf/destination = adv_route_destination
	var/repaths = adv_route_repaths
	if(destination && repaths < ADV_PATH_MAX_REPATHS)
		var/list/path = get_path(get_turf(X), destination, TILE_PATHING)
		if(length(path) && start_adv_route(path, destination, repaths + 1))
			return
	rts_finish_move()

#undef ADV_PATH_SMOOTH_RANGE
#undef ADV_PATH_STUCK_TIMEOUT
#undef ADV_PATH_MAX_REPATHS
#undef ADV_PATH_MAX_DIST
