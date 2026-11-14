// Hivemind RTS orders and order marker effects.

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
