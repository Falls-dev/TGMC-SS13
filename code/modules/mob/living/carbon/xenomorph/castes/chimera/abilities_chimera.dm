/datum/action/ability/activable/xeno/blink/chimera
	cooldown_duration = 3 SECONDS
	ability_cost = 50
	cooldown_duration = 3 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_CHIMERA_BLINK,
	)

/datum/action/ability/xeno_action/phantom
	name = "Phantom"
	desc = "Create a physical clone and hide in shadows."
	action_icon_state = "phantom"
	action_icon = 'icons/Xeno/actions/chimera.dmi'
	cooldown_duration = 30 SECONDS
	ability_cost = 100
	use_state_flags = ABILITY_USE_STAGGERED
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_CHIMERA_PHANTOM,
	)
	var/stealth_duration = 5 SECONDS
	var/mob/living/carbon/xenomorph/chimera/ai/phantom
	var/clone_duration = 7 SECONDS
	var/obj/effect/abstract/particle_holder/warpdust

/datum/action/ability/xeno_action/phantom/on_cooldown_finish()
	to_chat(owner, span_xenodanger("We gather enough strength to create a new phantom."))
	owner.playsound_local(owner, 'sound/effects/alien/newlarva.ogg', 25, 0, 1)
	return ..()

/datum/action/ability/xeno_action/phantom/action_activate()
	. = ..()
	phantom = new /mob/living/carbon/xenomorph/chimera/phantom(get_turf(xeno_owner))
	phantom.hivenumber = xeno_owner.hivenumber
	addtimer(CALLBACK(phantom, TYPE_PROC_REF(/mob, gib)), clone_duration)

	succeed_activate()
	add_cooldown()

	new /obj/effect/temp_visual/alien_fruit_eaten(get_turf(xeno_owner))
	playsound(xeno_owner,'sound/effects/magic.ogg', 25, TRUE)

	if(xeno_owner.on_fire)
		phantom.IgniteMob()
		return

	xeno_owner.alpha = HUNTER_STEALTH_STILL_ALPHA
	addtimer(CALLBACK(src, PROC_REF(uncloak)), stealth_duration)

	RegisterSignals(xeno_owner, list(
		COMSIG_XENOMORPH_GRAB,
		COMSIG_XENOMORPH_THROW_HIT,
		COMSIG_LIVING_IGNITED,
		COMSIG_XENOMORPH_ATTACK_OBJ,
		COMSIG_XENOMORPH_ATTACK_LIVING,
		COMSIG_XENO_LIVING_THROW_HIT,
		COMSIG_XENOMORPH_DISARM_HUMAN), PROC_REF(uncloak))

	ADD_TRAIT(xeno_owner, TRAIT_STEALTH, TRAIT_STEALTH)

/datum/action/ability/xeno_action/phantom/proc/uncloak()
	SIGNAL_HANDLER
	xeno_owner.alpha = 255

	UnregisterSignal(xeno_owner, list(
		COMSIG_XENOMORPH_GRAB,
		COMSIG_XENOMORPH_THROW_HIT,
		COMSIG_LIVING_IGNITED,
		COMSIG_XENOMORPH_ATTACK_OBJ,
		COMSIG_XENOMORPH_ATTACK_LIVING,
		COMSIG_XENO_LIVING_THROW_HIT,
		COMSIG_XENOMORPH_DISARM_HUMAN,))

	REMOVE_TRAIT(xeno_owner, TRAIT_STEALTH, TRAIT_STEALTH)

/datum/action/ability/xeno_action/phantom/ai_should_start_consider()
	return FALSE

/datum/action/ability/xeno_action/phantom/ai_should_use(target)
	return FALSE

#define CHIMERA_POUNCE_SPEED 2

/datum/action/ability/activable/xeno/pounce/abduction
	name = "Abduction"
	desc = "Abduct the prey."
	action_icon_state = "abduction"
	action_icon = 'icons/Xeno/actions/chimera.dmi'
	cooldown_duration = 20 SECONDS
	ability_cost = 100
	use_state_flags = ABILITY_MOB_TARGET
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_CHIMERA_ABDUCTION,
	)
	use_state_flags = null
	pounce_range = 5
	var/turf/initial_turf
	var/slowdown_amount = 6
	var/stagger_duration = 3 SECONDS

/datum/action/ability/activable/xeno/pounce/abduction/on_cooldown_finish()
	to_chat(owner, span_xenodanger("We gather enough strength to abduct another one."))
	owner.playsound_local(owner, 'sound/effects/alien/newlarva.ogg', 25, 0, 1)
	return ..()

/datum/action/ability/activable/xeno/pounce/abduction/use_ability(atom/A)
	initial_turf = get_turf(owner)
	return ..()

/datum/action/ability/activable/xeno/pounce/abduction/mob_hit(datum/source, mob/living/living_target)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(abduct), living_target)

/datum/action/ability/activable/xeno/pounce/abduction/proc/abduct(mob/living/target)
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(movement_fx))
	if(!do_after(xeno_owner, 0.5 SECONDS, IGNORE_HELD_ITEM, target, BUSY_ICON_DANGER))
		UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
		return
	xeno_owner.throw_at(initial_turf, pounce_range, CHIMERA_POUNCE_SPEED, xeno_owner)
	if(target)
		target.throw_at(initial_turf, pounce_range, CHIMERA_POUNCE_SPEED, xeno_owner)
		target.add_slowdown(slowdown_amount)
		target.adjust_stagger(stagger_duration)
	UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)

/datum/action/ability/activable/xeno/pounce/abduction/ai_should_start_consider()
	return FALSE

/datum/action/ability/activable/xeno/pounce/abduction/ai_should_use(target)
	return FALSE

/datum/action/ability/xeno_action/warp_blast
	name = "Warp Blast"
	desc = "Create a pure force explosion that damages and knockbacks targets around."
	action_icon_state = "warp_blast"
	action_icon = 'icons/Xeno/actions/chimera.dmi'
	cooldown_duration = 20 SECONDS
	ability_cost = 100
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_CHIMERA_WARP_BLAST,
	)
	var/range = 2
	var/warp_blast_damage = 30

/datum/action/ability/xeno_action/warp_blast/action_activate()
	var/datum/action/ability/xeno_action/chimera_stealth/S = xeno_owner.actions_by_path[/datum/action/ability/xeno_action/chimera_stealth]
	if(S)
		S.force_break_stealth()
	. = ..()
	playsound(xeno_owner,'sound/effects/bamf.ogg', 75, TRUE)
	new /obj/effect/temp_visual/shockwave(get_turf(xeno_owner), range)
	for(var/mob/living/living_target in cheap_get_humans_near(get_turf(xeno_owner), range))

		if(living_target.stat == DEAD || living_target == xeno_owner || !line_of_sight(xeno_owner, living_target))
			continue

		playsound(living_target,'sound/weapons/alien_claw_block.ogg', 75, 1)
		living_target.apply_effects(0.5 SECONDS, 0.5 SECONDS)
		living_target.apply_damage(warp_blast_damage, BRUTE, blocked = BOMB)
		living_target.apply_damage(warp_blast_damage * 2, STAMINA, blocked = BOMB)
		var/throwlocation = living_target.loc
		for(var/x in 1 to 3)
			throwlocation = get_step(throwlocation, get_dir(xeno_owner, living_target))
		living_target.throw_at(throwlocation, 2, 1, xeno_owner, TRUE)
	succeed_activate()
	add_cooldown()

/datum/action/ability/activable/xeno/body_swap
	name = "Body swap"
	action_icon_state = "bodyswap"
	action_icon = 'icons/Xeno/actions/chimera.dmi'
	desc = "Swap places with another alien."
	use_state_flags = ABILITY_MOB_TARGET
	cooldown_duration = 20 SECONDS
	ability_cost = 100
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_CHIMERA_BODYSWAP,
	)

/datum/action/ability/activable/xeno/body_swap/on_cooldown_finish()
	to_chat(xeno_owner, span_xenodanger("We gather enough strength to perform body swap again."))
	xeno_owner.playsound_local(xeno_owner, 'sound/effects/alien/newlarva.ogg', 25, 0, 1)
	return ..()

/datum/action/ability/activable/xeno/body_swap/use_ability(atom/movable/A)
	var/datum/action/ability/xeno_action/chimera_stealth/S = xeno_owner.actions_by_path[/datum/action/ability/xeno_action/chimera_stealth]
	if(S)
		S.force_break_stealth()
	. = ..()
	if(!isxeno(A))
		xeno_owner.balloon_alert(xeno_owner, "We can only swap places with another alien.")
		return fail_activate()
	if(get_dist(xeno_owner, A) > 9 || xeno_owner.z != A.z)
		xeno_owner.balloon_alert(xeno_owner, "We are too far away!")
		return fail_activate()

	var/turf/target_turf = get_turf(A)
	var/turf/origin_turf = get_turf(xeno_owner)

	new /obj/effect/temp_visual/blink_portal(origin_turf)
	new /obj/effect/temp_visual/blink_portal(target_turf)
	new /obj/effect/particle_effect/sparks(origin_turf)
	new /obj/effect/particle_effect/sparks(target_turf)
	playsound(target_turf, 'sound/effects/EMPulse.ogg', 25, TRUE)

	xeno_owner.face_atom(target_turf)
	A.forceMove(origin_turf)
	xeno_owner.forceMove(target_turf)

	succeed_activate()
	add_cooldown()

/particles/xeno_slash/vampirism/crippling_strike
	icon_state = "x"
	color = "#440088"
	count = 0
	velocity = list(50, 50)
	drift = generator(GEN_CIRCLE, 15, 15, NORMAL_RAND)
	gravity = list(0, 0)

/datum/action/ability/xeno_action/crippling_strike
	name = "Toggle crippling strike"
	desc = "Toggle on to enable crippling attacks"
	action_icon_state = "neuroclaws_off"
	action_icon = 'icons/Xeno/actions/sentinel.dmi'
	ability_cost = 0
	cooldown_duration = 1 SECONDS
	keybind_flags = ABILITY_KEYBIND_USE_ABILITY | ABILITY_IGNORE_SELECTED_ABILITY
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_CHIMERA_CRIPPLING_STRIKE,
	)
	var/mob/living/old_target
	var/additional_damage = 2
	var/slowdown_amount = 1
	var/stagger_duration = 0.2 SECONDS
	var/heal_amount = 25
	var/plasma_gain = 30
	var/stacks = 0
	var/stacks_max = 5
	var/decay_time = 7 SECONDS
	var/obj/effect/abstract/particle_holder/particle_holder

/datum/action/ability/xeno_action/crippling_strike/update_button_icon()
	action_icon_state = xeno_owner.vampirism ? "neuroclaws_on" : "neuroclaws_off"
	return ..()

/datum/action/ability/xeno_action/crippling_strike/give_action(mob/living/L)
	. = ..()
	xeno_owner.vampirism = TRUE
	particle_holder = new(xeno_owner, /particles/xeno_slash/vampirism/crippling_strike)
	particle_holder.pixel_y = 18
	particle_holder.pixel_x = 18
	START_PROCESSING(SSprocessing, src)
	RegisterSignal(L, COMSIG_XENOMORPH_POSTATTACK_LIVING, PROC_REF(on_slash))

/datum/action/ability/xeno_action/crippling_strike/remove_action(mob/living/L)
	xeno_owner.vampirism = FALSE
	. = ..()
	stacks = 0
	QDEL_NULL(particle_holder)
	STOP_PROCESSING(SSprocessing, src)
	UnregisterSignal(L, COMSIG_XENOMORPH_POSTATTACK_LIVING)

/datum/action/ability/xeno_action/crippling_strike/action_activate()
	. = ..()
	xeno_owner.vampirism = !xeno_owner.vampirism
	if(xeno_owner.vampirism)
		particle_holder = new(xeno_owner, /particles/xeno_slash/vampirism/crippling_strike)
		particle_holder.pixel_y = 18
		particle_holder.pixel_x = 18
		START_PROCESSING(SSprocessing, src)
		RegisterSignal(xeno_owner, COMSIG_XENOMORPH_POSTATTACK_LIVING, PROC_REF(on_slash))
	else
		stacks = 0
		QDEL_NULL(particle_holder)
		STOP_PROCESSING(SSprocessing, src)
		UnregisterSignal(xeno_owner, COMSIG_XENOMORPH_POSTATTACK_LIVING)
	to_chat(xeno_owner, span_xenonotice("You will now[xeno_owner.vampirism ? "" : " no longer"] debuff targets"))

/datum/action/ability/xeno_action/crippling_strike/process()
	particle_holder.particles.count = stacks * stacks
	if(decay_time > 0)
		decay_time -= 1 SECONDS
		return
	if(stacks > 0)
		stacks--
	if(stacks == 0)
		particle_holder.particles.count = 0

/datum/action/ability/xeno_action/crippling_strike/proc/on_slash(datum/source, mob/living/target, damage, list/damage_mod, list/armor_mod)
	SIGNAL_HANDLER
	if(target.stat == DEAD)
		return
	if(!ishuman(target))
		return
	if(old_target != target)
		old_target = target
		stacks = max(0, stacks - 2)
	target.apply_damage(additional_damage * stacks, BRUTE, xeno_owner.zone_selected, blocked = MELEE)
	target.add_slowdown(slowdown_amount * stacks)
	target.adjust_stagger(stagger_duration * stacks)
	if(stacks == stacks_max)
		xeno_owner.heal_overall_damage(heal_amount, heal_amount, updating_health = TRUE)
		xeno_owner.gain_plasma(plasma_gain)
	if(stacks < stacks_max)
		stacks++
	decay_time = initial(decay_time)
	update_button_icon()

/datum/action/ability/xeno_action/chimera_stealth
	name = "Stealth"
	desc = "Enter stealth mode for 15 seconds. You can move freely while in this state, but attacking or using abilities will reveal you."
	action_icon_state = "hunter_invisibility"
	action_icon = 'icons/Xeno/actions/hunter.dmi'
	ability_cost = 25
	cooldown_duration = 8 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_CHIMERA_STEALTH,
	)

	var/stealth = FALSE
	var/stealth_duration = 15 SECONDS
	var/stealth_end_time = 0
	var/damage_threshold = 50
	var/stealth_alpha = 20
	var/initial_fade_time = 2 SECONDS
	var/mutable_appearance/timer_overlay
	var/warning_shown = FALSE

/datum/action/ability/xeno_action/chimera_stealth/give_action(mob/living/L)
	. = ..()
	timer_overlay = mutable_appearance(icon = null, icon_state = null, layer = ACTION_LAYER_MAPTEXT)
	timer_overlay.maptext_width = 32
	timer_overlay.maptext_height = 32
	timer_overlay.maptext_x = 0
	timer_overlay.maptext_y = 19
	update_button_icon()

/datum/action/ability/xeno_action/chimera_stealth/update_button_icon()
	. = ..()
	if(!button)
		return

	button.cut_overlay(timer_overlay)

	if(stealth)
		var/time_left = max(0, round((stealth_end_time - world.time) / 10))
		var/timer_text = "<div align='right' style='font-family: \"Small Fonts\"; font-size: 7pt; color: white; -dm-text-outline: 1px black;'>[time_left]s</div>"
		timer_overlay.maptext = MAPTEXT(timer_text)
		button.add_overlay(timer_overlay)

/datum/action/ability/xeno_action/chimera_stealth/action_activate()
	if(stealth)
		cancel_stealth("We manually drop our camouflage.")
		return TRUE

	if(!can_use_action())
		return FALSE

	stealth_end_time = world.time + stealth_duration
	stealth = TRUE
	warning_shown = FALSE

	ADD_TRAIT(xeno_owner, TRAIT_STEALTH, TRAIT_STEALTH)
	animate(xeno_owner, initial_fade_time, alpha = stealth_alpha, flags = ANIMATION_PARALLEL)

	RegisterSignals(xeno_owner, list(
		COMSIG_XENOMORPH_ATTACK_LIVING,
		COMSIG_XENOMORPH_DISARM_HUMAN,
		COMSIG_XENOMORPH_GRAB,
		COMSIG_XENOMORPH_ATTACK_OBJ,
		COMSIG_XENO_LIVING_THROW_HIT,
		COMSIG_LIVING_IGNITED,
		COMSIG_XENOMORPH_POUNCE,
		COMSIG_XENOMORPH_THROW_HIT
	), PROC_REF(force_break_stealth))

	RegisterSignal(xeno_owner, COMSIG_XENOMORPH_TAKING_DAMAGE, PROC_REF(damage_taken))

	START_PROCESSING(SSprocessing, src)
	return TRUE

/datum/action/ability/xeno_action/chimera_stealth/process()
	if(!stealth)
		STOP_PROCESSING(SSprocessing, src)
		return

	var/time_remaining = stealth_end_time - world.time

	if(time_remaining <= 5 SECONDS && time_remaining > 0 && !warning_shown)
		xeno_owner.balloon_alert(xeno_owner, "Camouflage fading! [round(time_remaining/10)]s")
		warning_shown = TRUE

	if(time_remaining <= 0)
		cancel_stealth("Our camouflage expires.")
	else
		update_button_icon()

/datum/action/ability/xeno_action/chimera_stealth/proc/force_break_stealth()
	if(stealth)
		cancel_stealth("Our actions reveal us!")

/datum/action/ability/xeno_action/chimera_stealth/proc/damage_taken(mob/living/carbon/xenomorph/X, damage_taken)
	SIGNAL_HANDLER
	if(damage_taken > damage_threshold)
		cancel_stealth("The heavy impact reveals us!")

/datum/action/ability/xeno_action/chimera_stealth/proc/cancel_stealth(msg)
	if(!stealth)
		return
	stealth = FALSE

	if(msg)
		to_chat(xeno_owner, span_xenodanger(msg))

	UnregisterSignal(xeno_owner, list(
		COMSIG_XENOMORPH_ATTACK_LIVING,
		COMSIG_XENOMORPH_DISARM_HUMAN,
		COMSIG_XENOMORPH_GRAB,
		COMSIG_XENOMORPH_ATTACK_OBJ,
		COMSIG_XENO_LIVING_THROW_HIT,
		COMSIG_LIVING_IGNITED,
		COMSIG_XENOMORPH_POUNCE,
		COMSIG_XENOMORPH_THROW_HIT,
		COMSIG_XENOMORPH_TAKING_DAMAGE
	))

	REMOVE_TRAIT(xeno_owner, TRAIT_STEALTH, TRAIT_STEALTH)
	animate(xeno_owner, 1 SECONDS, alpha = 255, flags = ANIMATION_PARALLEL)

	STOP_PROCESSING(SSprocessing, src)
	add_cooldown()

	update_button_icon()

// ***************************************
// *********** One Chimera Army
// ***************************************
#define ILUSSION_CHANCE 50

/datum/action/ability/xeno_action/hunter_army/chimera_army
	name = "One Chimera Army"
	desc = ""
	ability_cost = 0
	cooldown_duration = 0
	keybind_flags = ABILITY_USE_STAGGERED | ABILITY_IGNORE_SELECTED_ABILITY
	hidden = TRUE

#undef ILUSSION_CHANCE
