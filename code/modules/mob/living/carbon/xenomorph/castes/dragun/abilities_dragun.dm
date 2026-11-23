/// Dragun's integrated weapon attacks.

#define DRAGUN_SLASH_DAMAGE 75
#define DRAGUN_SLASH_SECOND_DAMAGE 45
#define DRAGUN_SLASH_KNOCKDOWN 1 SECONDS
#define DRAGUN_SLASH_SECOND_DELAY 0.5 SECONDS

/datum/action/ability/activable/xeno/dragun_slash
	name = "Slash"
	desc = "Swing the integrated blade twice across six tiles in front of us, damaging and knocking down enemies."
	action_icon_state = "slahs"
	action_icon = 'icons/Xeno/actions/dragun.dmi'
	cooldown_duration = 4 SECONDS
	target_flags = ABILITY_TURF_TARGET

/datum/action/ability/activable/xeno/dragun_slash/can_use_ability(atom/target, silent = FALSE, override_flags)
	. = ..()
	if(!.)
		return FALSE
	return TRUE

/datum/action/ability/activable/xeno/dragun_slash
	var/slash_stage = 0
	var/slash_dir
	var/list/slash_hit_targets = list()

/datum/action/ability/activable/xeno/dragun_slash/use_ability(atom/target)
	slash_dir = get_cardinal_dir(xeno_owner, target)
	if(!slash_dir)
		return fail_activate()
	xeno_owner.setDir(slash_dir)
	slash_stage = 1
	slash_hit_targets = list()
	xeno_owner.xeno_flags |= XENO_LEAPING
	RegisterSignal(xeno_owner, COMSIG_XENOMORPH_LEAP_BUMP, PROC_REF(slash_mob_hit))
	RegisterSignal(xeno_owner, COMSIG_MOVABLE_POST_THROW, PROC_REF(slash_leap_complete))
	start_slash_leap()

/datum/action/ability/activable/xeno/dragun_slash/proc/start_slash_leap()
	var/turf/leap_target = get_ranged_target_turf(xeno_owner, slash_dir, 3)
	xeno_owner.throw_at(leap_target, 3, 1, xeno_owner)

/datum/action/ability/activable/xeno/dragun_slash/proc/slash_mob_hit(datum/source, mob/living/target)
	SIGNAL_HANDLER
	if(target)
		hit_slash_target(target, slash_stage == 1 ? DRAGUN_SLASH_DAMAGE : DRAGUN_SLASH_SECOND_DAMAGE)
	return TRUE

/datum/action/ability/activable/xeno/dragun_slash/proc/slash_leap_complete()
	SIGNAL_HANDLER
	if(slash_stage == 1)
		playsound(xeno_owner, 'sound/weapons/alien_claw_swipe.ogg', 55, TRUE, SHORT_SOUND_RANGE)
		perform_slash(DRAGUN_SLASH_DAMAGE, "slah_1")
		slash_stage = 2
		slash_hit_targets = list()
		addtimer(CALLBACK(src, PROC_REF(start_slash_leap)), DRAGUN_SLASH_SECOND_DELAY)
		return
	if(slash_stage != 2)
		return
	playsound(xeno_owner, 'sound/weapons/alien_claw_swipe.ogg', 45, TRUE, SHORT_SOUND_RANGE)
	perform_slash(DRAGUN_SLASH_SECOND_DAMAGE, "slah_2")
	UnregisterSignal(xeno_owner, list(COMSIG_XENOMORPH_LEAP_BUMP, COMSIG_MOVABLE_POST_THROW))
	xeno_owner.xeno_flags &= ~XENO_LEAPING
	slash_stage = 0
	slash_hit_targets = list()
	succeed_activate()
	add_cooldown()

/datum/action/ability/activable/xeno/dragun_slash/proc/perform_slash(damage, effect_state)
	// The leap ends on the attack point. Strike a full 3x3 area around Dragun,
	// rather than only checking the tile one step in front of the new position.
	var/turf/center_turf = get_turf(xeno_owner)
	var/list/turfs_to_attack = filled_turfs(center_turf, 1, "square", FALSE, pass_flags_checked = PASS_AIR)
	new /obj/effect/temp_visual/dragun_slash(center_turf, xeno_owner.dir, effect_state)
	for(var/turf/target_turf AS in turfs_to_attack)
		if(!target_turf)
			continue
		for(var/atom/movable/target AS in target_turf.contents.Copy())
			if(target == xeno_owner || !(target.resistance_flags & XENO_DAMAGEABLE))
				continue
			hit_slash_target(target, damage)

/datum/action/ability/activable/xeno/dragun_slash/proc/hit_slash_target(atom/movable/target, damage)
	if(target in slash_hit_targets || target == xeno_owner || !(target.resistance_flags & XENO_DAMAGEABLE))
		return TRUE
	slash_hit_targets += target
	if(ishitbox(target) || isvehicle(target))
		target.attack_alien(xeno_owner, damage)
		return TRUE
	if(!isliving(target))
		return TRUE
	var/mob/living/living_target = target
	if(living_target.stat == DEAD)
		return TRUE
	if(isxeno(living_target))
		var/mob/living/carbon/xenomorph/xeno_target = living_target
		if(xeno_owner.issamexenohive(xeno_target))
			return TRUE
		living_target.attack_alien(xeno_owner, damage)
		living_target.Knockdown(DRAGUN_SLASH_KNOCKDOWN)
		return TRUE
	if(!ishuman(living_target))
		return TRUE
	var/mob/living/carbon/human/human_target = living_target
	var/base_damage = xeno_owner.xeno_caste.melee_damage * xeno_owner.xeno_melee_damage_modifier
	var/damage_bonus = damage - base_damage
	// Use TGMC's normal alien harm path so intent, shields, armor, damage
	// signals, logging, and target zones behave like Ravager's Ravage.
	human_target.attack_alien_harm(xeno_owner, damage_bonus, FALSE, TRUE, FALSE, TRUE, INTENT_HARM)
	human_target.Knockdown(DRAGUN_SLASH_KNOCKDOWN)
	return TRUE

// Bite uses the same mouse signals as xeno spit, but commits only after a hold.
/datum/action/ability/activable/xeno/dragun_bite
	name = "Bite"
	desc = "Hold the ability mouse button to pounce at a fixed location and bite a human on impact. Releasing early cancels preparation."
	action_icon = 'icons/Xeno/actions/dragun.dmi'
	action_icon_state = "bite"
	ability_cost = 250
	cooldown_duration = 60 SECONDS
	target_flags = ABILITY_TURF_TARGET
	var/charging = FALSE
	var/leaping = FALSE
	var/turf/bite_destination
	var/mob/living/carbon/human/bite_victim
	/// Invalidates an interrupted preparation even if another is started immediately.
	var/charge_generation = 0
	var/bite_animation_timer

/datum/action/ability/activable/xeno/dragun_bite/on_selection()
	RegisterSignal(owner, COMSIG_MOB_MOUSEDOWN, PROC_REF(start_charge))
	RegisterSignal(owner, COMSIG_MOB_MOUSEUP, PROC_REF(release_charge))

/datum/action/ability/activable/xeno/dragun_bite/on_deselection()
	UnregisterSignal(owner, list(COMSIG_MOB_MOUSEDOWN, COMSIG_MOB_MOUSEUP))
	clean_bite()

/datum/action/ability/activable/xeno/dragun_bite/remove_action(mob/living/L)
	clean_bite()
	return ..()

/datum/action/ability/activable/xeno/dragun_bite/can_use_ability(atom/target, silent = FALSE, override_flags)
	if(!..())
		return FALSE
	var/turf/destination = get_turf(target)
	if(!destination || destination.z != xeno_owner.z || get_dist(xeno_owner, destination) > 5 || destination.density)
		return FALSE
	if(leaping || bite_victim || xeno_owner.throwing || (xeno_owner.xeno_flags & XENO_LEAPING) || HAS_TRAIT(xeno_owner, TRAIT_HANDS_BLOCKED))
		return FALSE
	return TRUE

/datum/action/ability/activable/xeno/dragun_bite/proc/start_charge(datum/source, atom/object, turf/location, control, params)
	SIGNAL_HANDLER
	var/list/modifiers = params2list(params)
	// Standard selected-xeno-ability controls: middle, right, or shift-left.
	if(modifiers["ctrl"] || !(modifiers["middle"] || modifiers["right"] || (modifiers["shift"] && modifiers["left"])))
		return
	var/turf/destination = get_turf_on_clickcatcher(object, xeno_owner, params)
	if(charging || !can_use_ability(destination))
		return
	charging = TRUE
	bite_destination = destination
	charge_generation++
	INVOKE_ASYNC(src, PROC_REF(prepare_bite), charge_generation)
	return COMSIG_MOB_CLICK_CANCELED

/datum/action/ability/activable/xeno/dragun_bite/proc/release_charge()
	SIGNAL_HANDLER
	charging = FALSE
	charge_generation++

/datum/action/ability/activable/xeno/dragun_bite/proc/charge_valid(generation)
	return charging && generation == charge_generation && xeno_owner?.client && can_use_ability(bite_destination, TRUE, ABILITY_USE_BUSY)

/datum/action/ability/activable/xeno/dragun_bite/proc/prepare_bite(generation)
	xeno_owner.face_atom(bite_destination)
	if(!do_after(xeno_owner, 1.5 SECONDS, NONE, xeno_owner, BUSY_ICON_HOSTILE, extra_checks = CALLBACK(src, PROC_REF(charge_valid), generation)))
		if(generation == charge_generation)
			charging = FALSE
		return
	if(!charge_valid(generation))
		return
	charging = FALSE
	leaping = TRUE
	succeed_activate()
	add_cooldown()
	RegisterSignal(xeno_owner, COMSIG_XENOMORPH_LEAP_BUMP, PROC_REF(bite_collision))
	RegisterSignal(xeno_owner, COMSIG_MOVABLE_POST_THROW, PROC_REF(bite_landed))
	xeno_owner.xeno_flags |= XENO_LEAPING
	xeno_owner.add_pass_flags(PASS_LOW_STRUCTURE|PASS_FIRE|PASS_XENO, type)
	xeno_owner.add_filter("dragun_bite_leap", 2, gauss_blur_filter(3))
	xeno_owner.throw_at(bite_destination, 5, 2, xeno_owner)

/datum/action/ability/activable/xeno/dragun_bite/proc/valid_victim(mob/living/carbon/human/target)
	return !QDELETED(xeno_owner) && istype(target) && !QDELETED(target) && target.stat != DEAD && !isnestedhost(target) && !target.issamexenohive(xeno_owner) && !(target.status_flags & (INCORPOREAL|GODMODE))

/datum/action/ability/activable/xeno/dragun_bite/proc/bite_collision(datum/source, mob/living/target)
	SIGNAL_HANDLER
	if(valid_victim(target))
		finish_leap(target)
		return TRUE
	// Other bodies stop the leap, rather than allowing a bite through them.
	finish_leap()
	return TRUE

/datum/action/ability/activable/xeno/dragun_bite/proc/bite_landed()
	SIGNAL_HANDLER
	if(!leaping || !bite_destination)
		return
	for(var/mob/living/carbon/human/target in get_turf(xeno_owner))
		if(valid_victim(target) && xeno_owner.Adjacent(target))
			finish_leap(target)
			return
	finish_leap()

/datum/action/ability/activable/xeno/dragun_bite/proc/finish_leap(mob/living/carbon/human/target)
	if(!leaping)
		return
	leaping = FALSE
	UnregisterSignal(xeno_owner, list(COMSIG_XENOMORPH_LEAP_BUMP, COMSIG_MOVABLE_POST_THROW))
	xeno_owner.xeno_flags &= ~XENO_LEAPING
	xeno_owner.stop_throw()
	xeno_owner.remove_pass_flags(PASS_LOW_STRUCTURE|PASS_FIRE|PASS_XENO, type)
	xeno_owner.remove_filter("dragun_bite_leap")
	if(valid_victim(target) && get_dist(xeno_owner, target) <= 1 && xeno_owner.check_state())
		impact_bite(target)
	else
		clean_bite()

/datum/action/ability/activable/xeno/dragun_bite/proc/impact_bite(mob/living/carbon/human/target)
	var/mob/living/carbon/xenomorph/dragun/dragun = xeno_owner
	if(!valid_victim(target))
		return
	var/approach_dir = dragun.dir
	dragun.forceMove(get_turf(target))
	dragun.setDir(approach_dir)
	if(!apply_bite(target))
		clean_bite()
		return
	bite_victim = target
	dragun.biting = TRUE
	dragun.face_atom(target)
	dragun.update_icons()
	target.Knockdown(1 SECONDS)
	shake_camera(target, 2, 1)
	bite_animation_timer = addtimer(CALLBACK(src, PROC_REF(clean_bite)), 1 SECONDS, TIMER_STOPPABLE)

/datum/action/ability/activable/xeno/dragun_bite/proc/apply_bite(mob/living/carbon/human/target)
	if(!valid_victim(target))
		return FALSE
	var/datum/limb/chest = target.get_limb(BODY_ZONE_CHEST)
	if(!chest || !chest.is_usable())
		return FALSE
	var/damage_bonus = 75 - xeno_owner.xeno_caste.melee_damage * xeno_owner.xeno_melee_damage_modifier
	if(!target.attack_alien_harm(xeno_owner, damage_bonus, BODY_ZONE_CHEST, FALSE, FALSE, TRUE, INTENT_HARM))
		return FALSE
	playsound(target, SFX_ALIEN_BITE, 60, TRUE, SHORT_SOUND_RANGE)
	if(!(chest.limb_status & LIMB_ROBOT))
		new /datum/wound/internal_bleeding(3, chest)
	var/roll = rand(1, 100)
	var/fractures = roll <= 10 ? 2 : (roll <= 45 ? 1 : 0)
	var/list/eligible_limbs = list()
	for(var/datum/limb/limb AS in target.limbs)
		if(!(limb.limb_status & (LIMB_BROKEN|LIMB_DESTROYED|LIMB_ROBOT)))
			eligible_limbs += limb
	for(var/i in 1 to fractures)
		if(!length(eligible_limbs))
			break
		var/datum/limb/limb = pick_n_take(eligible_limbs)
		limb.fracture()
	return TRUE

/datum/action/ability/activable/xeno/dragun_bite/proc/clean_bite()
	if(bite_animation_timer)
		deltimer(bite_animation_timer)
		bite_animation_timer = null
	charging = FALSE
	charge_generation++
	if(xeno_owner)
		UnregisterSignal(xeno_owner, list(COMSIG_XENOMORPH_LEAP_BUMP, COMSIG_MOVABLE_POST_THROW))
		if(leaping)
			xeno_owner.xeno_flags &= ~XENO_LEAPING
			xeno_owner.stop_throw()
		xeno_owner.remove_filter("dragun_bite_leap")
		var/mob/living/carbon/xenomorph/dragun/dragun = xeno_owner
		dragun.biting = FALSE
		dragun.update_icons()
	leaping = FALSE
	bite_victim = null
	bite_destination = null

#define DRAGUN_TARAN_RANGE 7
#define DRAGUN_TARAN_COST 50
#define DRAGUN_TARAN_KNOCKDOWN 1.5 SECONDS

/datum/action/ability/activable/xeno/dragun_taran
	name = "Taran"
	desc = "Charge up to seven tiles, knocking down marines in the way, then fire acid at the endpoint."
	action_icon_state = "taran"
	action_icon = 'icons/Xeno/actions/dragun.dmi'
	cooldown_duration = 18 SECONDS
	ability_cost = DRAGUN_TARAN_COST
	target_flags = ABILITY_TURF_TARGET
	var/turf/final_target

/datum/action/ability/activable/xeno/dragun_taran/can_use_ability(atom/target, silent = FALSE, override_flags)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/carbon/xenomorph/dragun/dragun_owner = xeno_owner
	var/obj/item/weapon/gun/dragun/rifle = dragun_owner.hand_dragun
	if(!rifle || !(rifle.item_flags & FULLY_WIELDED))
		if(!silent)
			xeno_owner.balloon_alert(xeno_owner, "raise the rifle with both hands")
		return FALSE
	if(xeno_owner.plasma_stored < ability_cost)
		if(!silent)
			xeno_owner.balloon_alert(xeno_owner, "not enough plasma")
		return FALSE
	return TRUE

/datum/action/ability/activable/xeno/dragun_taran/use_ability(atom/target)
	var/charge_dir = get_cardinal_dir(xeno_owner, target)
	if(!charge_dir)
		return fail_activate()
	xeno_owner.setDir(charge_dir)
	final_target = get_ranged_target_turf(xeno_owner, charge_dir, DRAGUN_TARAN_RANGE)
	xeno_owner.use_plasma(ability_cost)
	playsound(xeno_owner, SFX_ALIEN_ROAR, 75, TRUE, MEDIUM_SOUND_RANGE)
	playsound(xeno_owner, SFX_ALIEN_CHARGE, 60, TRUE, MEDIUM_SOUND_RANGE)
	xeno_owner.visible_message(span_danger("[xeno_owner] charges forward!"), span_xenodanger("We charge forward!"))
	xeno_owner.xeno_flags |= XENO_LEAPING
	RegisterSignal(xeno_owner, COMSIG_XENO_OBJ_THROW_HIT, PROC_REF(obj_hit))
	RegisterSignal(xeno_owner, COMSIG_XENOMORPH_LEAP_BUMP, PROC_REF(mob_hit))
	RegisterSignal(xeno_owner, COMSIG_MOVABLE_POST_THROW, PROC_REF(charge_complete))
	xeno_owner.throw_at(final_target, DRAGUN_TARAN_RANGE, 1, xeno_owner)
	play_taran_footsteps(DRAGUN_TARAN_RANGE)
	succeed_activate()
	add_cooldown()

/datum/action/ability/activable/xeno/dragun_taran/proc/obj_hit(datum/source, obj/target, speed)
	SIGNAL_HANDLER
	if(istype(target, /obj/structure/table))
		var/obj/structure/table/table = target
		table.deconstruct(FALSE)
		return TRUE
	target.hitby(xeno_owner, speed)
	charge_complete()

/datum/action/ability/activable/xeno/dragun_taran/proc/mob_hit(datum/source, mob/living/target)
	SIGNAL_HANDLER
	if(target.stat == DEAD || isxeno(target))
		return TRUE
	target.take_overall_damage(DRAGUN_SLASH_DAMAGE * xeno_owner.xeno_melee_damage_modifier, BRUTE, MELEE, max_limbs = 5, updating_health = TRUE)
	target.Knockdown(DRAGUN_TARAN_KNOCKDOWN)
	xeno_owner.do_attack_animation(target)
	return TRUE

/datum/action/ability/activable/xeno/dragun_taran/proc/play_taran_footsteps(remaining_steps)
	if(!remaining_steps || !(xeno_owner.xeno_flags & XENO_LEAPING))
		return
	playsound(xeno_owner, SFX_ALIEN_FOOTSTEP_LARGE, 65, TRUE, SHORT_SOUND_RANGE)
	addtimer(CALLBACK(src, PROC_REF(play_taran_footsteps), remaining_steps - 1), 1)

/datum/action/ability/activable/xeno/dragun_taran/proc/charge_complete()
	SIGNAL_HANDLER
	UnregisterSignal(xeno_owner, list(COMSIG_XENO_OBJ_THROW_HIT, COMSIG_XENOMORPH_LEAP_BUMP, COMSIG_MOVABLE_POST_THROW))
	xeno_owner.xeno_flags &= ~XENO_LEAPING
	var/mob/living/carbon/xenomorph/dragun/dragun_owner = xeno_owner
	var/obj/item/weapon/gun/dragun/rifle = dragun_owner.hand_dragun
	if(rifle && final_target)
		rifle.fire_acid_at(final_target)
	final_target = null

/obj/effect/temp_visual/dragun_slash
	icon = 'icons/effects/dragun_effect.dmi'
	icon_state = "slah_1"
	duration = 0.7 SECONDS
	randomdir = FALSE
	layer = MOB_LAYER + 0.1
	pixel_y = -32


/obj/effect/temp_visual/dragun_slash/Initialize(mapload, set_dir, effect_state)
	. = ..()
	if(set_dir)
		setDir(set_dir)
	if(effect_state)
		icon_state = effect_state
	alpha = 220
	animate(src, alpha = 0, time = duration, flags = ANIMATION_PARALLEL)

#undef DRAGUN_SLASH_DAMAGE
#undef DRAGUN_SLASH_SECOND_DAMAGE
#undef DRAGUN_SLASH_KNOCKDOWN
#undef DRAGUN_SLASH_SECOND_DELAY
#undef DRAGUN_TARAN_RANGE
#undef DRAGUN_TARAN_COST
#undef DRAGUN_TARAN_KNOCKDOWN
