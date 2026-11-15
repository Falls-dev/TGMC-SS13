// Nymph: completes blueprints around herself, fills wells, heals and plasma-feeds allies, plants weeds.
// Does not attack on her own: flees from enemies. Attacks only on a direct hivemind order.

#define NYMPH_WORK_RADIUS 7
#define NYMPH_WEED_RADIUS 5
#define NYMPH_THINK_COOLDOWN 1 SECONDS
#define NYMPH_BLACKLIST_TIME 15 SECONDS
#define NYMPH_PLASMA_RESERVE 100
#define NYMPH_JOB_BUILD 1
#define NYMPH_JOB_WEED 2
#define NYMPH_JOB_FILL 3
#define NYMPH_JOB_SUPPORT 4
#define NYMPH_FLEE_RADIUS 6

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
	COOLDOWN_DECLARE(think_cooldown)

/datum/ai_behavior/xeno/nymph/Destroy(force, ...)
	release_job()
	support_target = null
	return ..()

/datum/ai_behavior/xeno/nymph/rts_reset()
	. = ..()
	release_job()
	nymph_moving = FALSE
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

/// Are we under a direct order (then we do not run)
/datum/ai_behavior/xeno/nymph/proc/can_flee()
	return !(rts_attack_ordered || hivemind_rts_hold_position || (hivemind_rts_direct_move && !nymph_moving))

/datum/ai_behavior/xeno/nymph/proc/flee_from(atom/threat)
	halt_job()
	if(current_action == MOVING_TO_SAFETY && combat_target == threat)
		return
	set_combat_target(threat)
	change_action(MOVING_TO_SAFETY, threat, list(INFINITY))
	if(!registered_for_move)
		INVOKE_ASYNC(src, PROC_REF(scheduled_move))

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
	if(mob_parent && !QDELETED(mob_parent) && mob_parent.stat == CONSCIOUS && !mob_parent.notransform && !mob_parent.do_actions)
		nymph_think()
	return ..()

/datum/ai_behavior/xeno/nymph/proc/nymph_think()
	if(!COOLDOWN_FINISHED(src, think_cooldown))
		return
	COOLDOWN_START(src, think_cooldown, NYMPH_THINK_COOLDOWN)
	// A direct well order takes precedence over autonomous threat avoidance; the base
	// xeno processor owns the fill task and advances it exactly once per tick.
	if(rts_well)
		return
	if(can_flee())
		var/atom/threat = get_nearest_target(mob_parent, NYMPH_FLEE_RADIUS, TARGET_HOSTILE, mob_parent.faction, mob_parent.get_xeno_hivenumber(), TRUE)
		if(threat)
			flee_from(threat)
			return
		if(current_action == MOVING_TO_SAFETY)
			stop_fleeing()
	if(support_target)
		if(QDELETED(support_target) || support_target.stat == DEAD || support_target.z != mob_parent.z || \
			(support_target.status_flags & INCORPOREAL) || support_target.hivenumber != mob_parent.get_xeno_hivenumber())
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
	if(job_target && !job_valid())
		release_job()
	if(!job_target)
		find_job()
	if(!job_target)
		if(nymph_moving)
			halt_job()
		return
	if(job_in_reach())
		halt_job(FALSE)
		INVOKE_ASYNC(src, PROC_REF(do_job))
		return
	go_to(get_turf(job_target))

/// Free for independent work: no order, combat, or escort
/datum/ai_behavior/xeno/nymph/proc/is_free()
	if(hivemind_rts_hold_position || combat_target || escorted_atom)
		return FALSE
	if(hivemind_rts_direct_move && !nymph_moving)
		return FALSE
	return TRUE

/datum/ai_behavior/xeno/nymph/proc/go_to(turf/T)
	if(nymph_moving && atom_to_walk_to == T)
		return
	nymph_moving = TRUE
	hivemind_rts_direct_move = TRUE
	change_action(MOVING_TO_ATOM, T)
	if(!registered_for_move)
		INVOKE_ASYNC(src, PROC_REF(scheduled_move))

/// Halt our own transition; drop_job = FALSE keeps the job claimed
/datum/ai_behavior/xeno/nymph/proc/halt_job(drop_job = TRUE)
	if(nymph_moving)
		nymph_moving = FALSE
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

/// A wall on the turf would trap some nymph nearby (or us)
/datum/ai_behavior/xeno/nymph/proc/build_would_trap(turf/T, datum/xeno_build_entry/entry)
	if(!ispath(entry.path, /turf/closed))
		return FALSE
	for(var/mob/living/carbon/xenomorph/nymph/other in range(2, T))
		if(other.stat == DEAD)
			continue
		var/turf/their = get_turf(other)
		if(their == T)
			return TRUE
		var/free = 0
		for(var/turf/N in orange(1, their))
			if(N != T && !N.density)
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
	var/best_score = INFINITY
	var/obj/effect/xeno_blueprint/best
	for(var/obj/effect/xeno_blueprint/bp in range(NYMPH_WORK_RADIUS, own))
		if(bp.hivenumber != hive || QDELETED(bp) || claimed_by_other(bp) || in_blacklist(bp))
			continue
		var/turf/T = get_turf(bp)
		if(!bp.is_demolish)
			if(!bp.entry || bp.entry.kind != BUILD_KIND_RESIN || bp.entry.unavailable_reason(X))
				continue
			if(X.plasma_stored < 60)
				continue
			if(bp.entry.check_turf(T) != NO_ERROR && bp.entry.check_turf(T) != ERROR_NO_WEED)
				continue
			if(build_would_trap(T, bp.entry) || other_claim_near(T))
				continue
		var/score = get_dist(own, T) + (bp.auto_rebuild ? -3 : 0) // repairing broken structures matters more
		if(score < best_score)
			best_score = score
			best = bp
	if(best)
		claim(best, NYMPH_JOB_BUILD)
		return
	// No blueprints: heal and plasma-feed the wounded/hungry
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
	// Then wells
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
	// Otherwise seed the surroundings with weeds
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
	if(QDELETED(job_target) || claimed_by_other(job_target))
		return FALSE
	if(job_target.z != mob_parent.z || get_dist(mob_parent, job_target) > NYMPH_WORK_RADIUS + 3)
		return FALSE
	if(in_blacklist(job_target))
		return FALSE
	switch(job_type)
		if(NYMPH_JOB_WEED)
			return !(locate(/obj/alien/weeds) in get_turf(job_target))
		if(NYMPH_JOB_FILL)
			var/obj/structure/xeno/acidwell/well = job_target
			var/mob/living/carbon/xenomorph/xeno = mob_parent
			return well.charges < XENO_ACID_WELL_MAX_CHARGES && xeno.plasma_stored >= XENO_ACID_WELL_FILL_COST
		if(NYMPH_JOB_SUPPORT)
			return !!support_need(job_target)
	return TRUE

/datum/ai_behavior/xeno/nymph/proc/job_in_reach()
	if(job_type == NYMPH_JOB_BUILD)
		var/mob/living/carbon/xenomorph/X = mob_parent
		return X.in_build_reach(get_turf(job_target))
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
		ok = support_act(target, 0.5)
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
					return
			else if(err == NO_ERROR && !build_would_trap(T, bp.entry))
				ok = X.try_build_blueprint(bp)
	if(!ok)
		blacklist[target] = world.time + NYMPH_BLACKLIST_TIME
	release_job()

/datum/ai_behavior/xeno/nymph/proc/plant_weeds_at(turf/T)
	var/mob/living/carbon/xenomorph/X = mob_parent
	var/datum/action/ability/activable/xeno/plant_weeds/weeds = X.actions_by_path[/datum/action/ability/activable/xeno/plant_weeds]
	if(!weeds || !T || !weeds.can_use_action(TRUE, ABILITY_IGNORE_SELECTED_ABILITY))
		return FALSE
	if(locate(/obj/alien/weeds) in T)
		return TRUE
	X.face_atom(T)
	weeds.plant_weeds(T)
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
#undef NYMPH_WEED_RADIUS
#undef NYMPH_THINK_COOLDOWN
#undef NYMPH_BLACKLIST_TIME
#undef NYMPH_PLASMA_RESERVE
#undef NYMPH_JOB_BUILD
#undef NYMPH_JOB_WEED
#undef NYMPH_JOB_FILL
#undef NYMPH_JOB_SUPPORT
#undef NYMPH_FLEE_RADIUS
