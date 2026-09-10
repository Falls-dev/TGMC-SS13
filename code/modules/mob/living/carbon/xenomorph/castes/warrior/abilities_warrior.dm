// ***************************************
// *********** Empower
// ***************************************
/// After how many abilities should a Warrior get an empowered cast (2 means the 3rd one is empowered).
#define WARRIOR_EMPOWER_COMBO_THRESHOLD 2
/// The duration of a combo, after which it will disappear by itself.
#define WARRIOR_EMPOWER_COMBO_FADE_TIME 10 SECONDS

/datum/action/ability/xeno_action/empower
	name = "Empower"
	hidden = TRUE
	/// Holds the fade-out timer.
	var/fade_timer
	/// The amount of abilities we've chained together.
	var/combo_count = 0
	/// List of abilities that can be empowered.
	var/list/empowerable_actions = list(
		/datum/action/ability/activable/xeno/warrior/fling,
		/datum/action/ability/activable/xeno/warrior/grapple_toss,
		/datum/action/ability/activable/xeno/warrior/punch,
		/datum/action/ability/activable/xeno/warrior/punch/jab,
		/datum/action/ability/activable/xeno/warrior/punch/flurry,
	)

/// Checks if Empower is capped and gives bonuses if so, otherwise increases combo count.
/datum/action/ability/xeno_action/empower/proc/check_empower(atom/target)
	if(isliving(target))
		var/mob/living/living_target = target
		if(living_target.stat == DEAD || living_target.issamexenohive(owner))
			return FALSE
	if(combo_count >= WARRIOR_EMPOWER_COMBO_THRESHOLD)
		xeno_owner.emote("roar")
		clear_empower()
		return TRUE
	activate_empower()
	return FALSE

/// Handles empowering, and gives visual feedback if applicable.
/datum/action/ability/xeno_action/empower/proc/activate_empower()
	combo_count++
	if(combo_count >= WARRIOR_EMPOWER_COMBO_THRESHOLD)
		for(var/datum/action/ability/activable/xeno/warrior/warrior_action AS in xeno_owner.actions)
			if(warrior_action.type in empowerable_actions)
				warrior_action.add_empowered_frame()
				warrior_action.update_button_icon()
	fade_timer = addtimer(CALLBACK(src, PROC_REF(empower_fade)), WARRIOR_EMPOWER_COMBO_FADE_TIME, TIMER_OVERRIDE|TIMER_UNIQUE|TIMER_STOPPABLE)

/// Clears empowering, as well as visual feedback and combo count.
/datum/action/ability/xeno_action/empower/proc/clear_empower()
	for(var/datum/action/ability/activable/xeno/warrior/warrior_action AS in xeno_owner.actions)
		if(warrior_action.type in empowerable_actions)
			warrior_action.remove_empowered_frame()
			warrior_action.update_button_icon()
	combo_count = initial(combo_count)
	deltimer(fade_timer)

/// Happens when Empower fades.
/datum/action/ability/xeno_action/empower/proc/empower_fade()
	owner.playsound_local(owner, 'sound/voice/alien/hiss8.ogg', 25, 0, 1)
	clear_empower()

// ***************************************
// *********** Agility
// ***************************************
#define WARRIOR_AGILITY_SPEED_MODIFIER -0.6
#define WARRIOR_AGILITY_ARMOR_MODIFIER 30

/datum/action/ability/xeno_action/toggle_agility
	name = "Agility"
	action_icon_state = "agility_on"
	action_icon = 'icons/Xeno/actions/warrior.dmi'
	cooldown_duration = 0.4 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_TOGGLE_AGILITY,
	)
	action_type = ACTION_TOGGLE

/datum/action/ability/xeno_action/toggle_agility/New(Target)
	. = ..()
	desc = "Move on all fours and loosen our scales. Increases movement speed by [abs(WARRIOR_AGILITY_SPEED_MODIFIER)], but reduces all soft armor by [WARRIOR_AGILITY_ARMOR_MODIFIER]. Automatically disabled after using an ability."

/datum/action/ability/xeno_action/toggle_agility/action_activate()
	GLOB.round_statistics.warrior_agility_toggles++
	SSblackbox.record_feedback(FEEDBACK_TALLY, "round_statistics", 1, "warrior_agility_toggles")
	toggled = !toggled
	TOGGLE_BITFIELD(xeno_owner.xeno_flags, XENO_AGILITY)
	set_toggle(toggled)
	xeno_owner.update_icons()
	add_cooldown()
	if(!toggled)
		xeno_owner.remove_movespeed_modifier(MOVESPEED_ID_WARRIOR_AGILITY)
		xeno_owner.soft_armor = xeno_owner.soft_armor.modifyAllRatings(WARRIOR_AGILITY_ARMOR_MODIFIER)
		return
	xeno_owner.add_movespeed_modifier(MOVESPEED_ID_WARRIOR_AGILITY, TRUE, 0, NONE, TRUE, WARRIOR_AGILITY_SPEED_MODIFIER)
	xeno_owner.soft_armor = xeno_owner.soft_armor.modifyAllRatings(-WARRIOR_AGILITY_ARMOR_MODIFIER)
	xeno_owner.toggle_move_intent(MOVE_INTENT_RUN)
	if(xeno_owner.xeno_flags & XENO_AGILITY)
		owner.drop_all_held_items() // drop items (hugger/jelly)

// ***************************************
// *********** Parent Ability
// ***************************************
#define WARRIOR_IMPACT_DAMAGE_MULTIPLIER 0.5
#define WARRIOR_DISPLACE_KNOCKDOWN 0.4 SECONDS

/datum/action/ability/activable/xeno/warrior/use_ability(atom/A)
	var/datum/action/ability/xeno_action/toggle_agility/agility_action = xeno_owner.actions_by_path[/datum/action/ability/xeno_action/toggle_agility]
	if(agility_action?.toggled)
		agility_action.action_activate()

/// Adds an outline around the ability button to represent Empower.
/datum/action/ability/activable/xeno/warrior/proc/add_empowered_frame()
	button.add_overlay(visual_references[VREF_MUTABLE_EMPOWERED_FRAME])

/// Removes the Empower outline.
/datum/action/ability/activable/xeno/warrior/proc/remove_empowered_frame()
	button.cut_overlay(visual_references[VREF_MUTABLE_EMPOWERED_FRAME])

/// Handles anything that would happen when a target is thrown into an atom using an ability.
/datum/action/ability/activable/xeno/warrior/proc/thrown_into(datum/source, atom/hit_atom, impact_speed)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_MOVABLE_IMPACT)
	var/mob/living/living_target = source
	INVOKE_ASYNC(living_target, TYPE_PROC_REF(/mob, emote), "scream")
	living_target.Knockdown(WARRIOR_DISPLACE_KNOCKDOWN)
	new /obj/effect/temp_visual/warrior/impact(get_turf(living_target), get_dir(living_target, xeno_owner))
	// mob/living/turf_collision() does speed * 5 damage on impact with a turf, and we don't want to go overboard, so we deduce that here.
	var/thrown_damage = ((xeno_owner.xeno_caste.melee_damage * xeno_owner.xeno_melee_damage_modifier) - (impact_speed * 5)) * WARRIOR_IMPACT_DAMAGE_MULTIPLIER
	living_target.apply_damage(thrown_damage, BRUTE, blocked = MELEE)
	if(isliving(hit_atom))
		var/mob/living/hit_living = hit_atom
		if(hit_living.issamexenohive(xeno_owner))
			return
		INVOKE_ASYNC(hit_living, TYPE_PROC_REF(/mob, emote), "scream")
		hit_living.apply_damage(thrown_damage, BRUTE, blocked = MELEE)
		hit_living.Knockdown(WARRIOR_DISPLACE_KNOCKDOWN)
		step_away(hit_living, living_target, 1, 1)
	if(isobj(hit_atom))
		var/obj/hit_object = hit_atom
		if(istype(hit_object, /obj/structure/xeno))
			return
		hit_object.take_damage(thrown_damage, BRUTE, MELEE)
	if(iswallturf(hit_atom))
		var/turf/closed/wall/hit_wall = hit_atom
		if(!(hit_wall.resistance_flags & INDESTRUCTIBLE))
			hit_wall.take_damage(thrown_damage, BRUTE, MELEE)

/// Ends the target's throw.
/datum/action/ability/activable/xeno/warrior/proc/throw_ended(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_MOVABLE_POST_THROW)
	/* So the reason why we do not flat out unregister this is because, when an atom makes impact with something, it calls throw_impact(). Calling it this way causes
	stop_throw() to be called in most cases, because impacts can cause a bounce effect and ending the throw makes it happen. Given the way we have signals setup, unregistering
	it at that point would cause thrown_into() to never get called, and that is exactly the reason why the line of code below exists. */
	addtimer(CALLBACK(src, TYPE_PROC_REF(/datum, UnregisterSignal), source, COMSIG_MOVABLE_IMPACT, COMSIG_MOVABLE_POST_THROW), 1)
	var/mob/living/living_target = source
	living_target.Knockdown(0.5 SECONDS)
	living_target.remove_pass_flags(PASS_XENO, THROW_TRAIT)

/obj/effect/temp_visual/warrior/impact
	icon = 'icons/effects/96x96.dmi'
	icon_state = "throw_impact"
	duration = 3.5
	layer = ABOVE_ALL_MOB_LAYER
	pixel_x = -32
	pixel_y = -32

/obj/effect/temp_visual/warrior/impact/Initialize(mapload, direction)
	. = ..()
	animate(src, alpha = 0, time = duration - 1.5)
	// directions refuse to work naturally so i improvised, suck it byond
	direction = closest_cardinal_dir(direction)
	switch(direction)
		if(NORTH)
			icon_state = "[initial(icon_state)]_n"
			pixel_y -= 20
		if(SOUTH)
			icon_state = "[initial(icon_state)]_s"
			pixel_y += 20
		if(WEST)
			icon_state = "[initial(icon_state)]_w"
			pixel_x += 20
		if(EAST)
			icon_state = "[initial(icon_state)]_e"
			pixel_x -= 20

// ***************************************
// *********** Lunge
// ***************************************
#define WARRIOR_LUNGE_RANGE 5 // in tiles

/datum/action/ability/activable/xeno/warrior/lunge
	name = "Lunge"
	action_icon_state = "lunge"
	action_icon = 'icons/Xeno/actions/warrior.dmi'
	ability_cost = 30
	cooldown_duration = 10 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_LUNGE,
	)
	target_flags = ABILITY_MOB_TARGET
	/// The target of our lunge, we keep it to check if we are adjacent every time we move.
	var/atom/lunge_target

/datum/action/ability/activable/xeno/warrior/lunge/New(Target)
	. = ..()
	desc = "Lunge towards a target within [WARRIOR_LUNGE_RANGE] tiles, putting them in our grasp. Usable on allies."

/datum/action/ability/activable/xeno/warrior/lunge/on_cooldown_finish()
	xeno_owner.balloon_alert(xeno_owner, "[initial(name)] ready")
	return ..()

/datum/action/ability/activable/xeno/warrior/lunge/can_use_ability(atom/A, silent = FALSE, override_flags)
	. = ..()
	if(!.)
		return FALSE
	if(!isliving(A))
		if(!silent)
			owner.balloon_alert(owner, "Invalid target")
		return FALSE
	var/mob/living/living_target = A
	if(living_target.stat == DEAD && !living_target.issamexenohive(owner))
		if(!silent)
			owner.balloon_alert(owner, "Dead")
		return FALSE
	if(get_dist_euclidean_square(living_target, owner) > WARRIOR_LUNGE_RANGE * 5)
		if(!silent)
			owner.balloon_alert(owner, "Too far")
		return FALSE

/datum/action/ability/activable/xeno/warrior/lunge/use_ability(atom/A)
	. = ..()
	GLOB.round_statistics.warrior_lunges++
	SSblackbox.record_feedback(FEEDBACK_TALLY, "round_statistics", 1, "warrior_lunges")
	xeno_owner.add_filter("warrior_lunge", 2, gauss_blur_filter(3))
	lunge_target = A
	succeed_activate()
	add_cooldown()
	if(lunge_target.Adjacent(xeno_owner)) // They're already in range, neck grab without lunging.
		lunge_grab(lunge_target)
		return
	RegisterSignal(lunge_target, COMSIG_QDELETING, PROC_REF(clean_lunge_target))
	RegisterSignal(xeno_owner, COMSIG_MOVABLE_MOVED, PROC_REF(check_if_lunge_possible))
	RegisterSignal(xeno_owner, COMSIG_MOVABLE_POST_THROW, PROC_REF(clean_lunge_target))
	xeno_owner.throw_at(get_step_towards(A, xeno_owner), WARRIOR_LUNGE_RANGE, 2, xeno_owner)

/// Check if we are close enough to grab.
/datum/action/ability/activable/xeno/warrior/lunge/proc/check_if_lunge_possible(datum/source)
	SIGNAL_HANDLER
	if(lunge_target.Adjacent(source))
		INVOKE_ASYNC(src, PROC_REF(lunge_grab), lunge_target)

/// Null lunge target and reset related vars.
/datum/action/ability/activable/xeno/warrior/lunge/proc/clean_lunge_target()
	SIGNAL_HANDLER
	UnregisterSignal(lunge_target, COMSIG_QDELETING)
	UnregisterSignal(owner, list(COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_POST_THROW))
	lunge_target = null
	owner.stop_throw()
	owner.remove_filter("warrior_lunge")

/// Do the grab on the target, and clean all previous vars
/datum/action/ability/activable/xeno/warrior/lunge/proc/lunge_grab(atom/A)
	clean_lunge_target()
	xeno_owner.swap_hand()
	if(xeno_owner.start_pulling(A) && isliving(A) && !xeno_owner.issamexenohive(A))
		var/mob/living/living_target = A
		GLOB.round_statistics.warrior_grabs++
		SSblackbox.record_feedback("tally", "round_statistics", 1, "warrior_grabs")
		xeno_owner.setGrabState(GRAB_NECK)
		living_target.resistance_flags |= RESTRAINED_NECKGRAB
		living_target.drop_all_held_items()
		living_target.Paralyze(0.1 SECONDS)
		living_target.balloon_alert(xeno_owner, "Grabbed [living_target]")

	xeno_owner.swap_hand()
	var/datum/action/ability/xeno_action/empower/empower_action = xeno_owner.actions_by_path[/datum/action/ability/xeno_action/empower]
	if(empower_action?.combo_count < WARRIOR_EMPOWER_COMBO_THRESHOLD)
		empower_action?.activate_empower()

////////////////////////
/datum/action/ability/activable/xeno/warrior/lunge/ai_should_start_consider()
	return TRUE

/datum/action/ability/activable/xeno/warrior/lunge/ai_should_use(atom/target)
	if(!iscarbon(target))
		return FALSE
	if(!line_of_sight(owner, target, 2))
		return FALSE
	if(!can_use_ability(target, override_flags = ABILITY_IGNORE_SELECTED_ABILITY))
		return FALSE
	if(target.get_xeno_hivenumber() == owner.get_xeno_hivenumber())
		return FALSE
	return TRUE

// ***************************************
// *********** Fling
// ***************************************
#define WARRIOR_FLING_TOSS_COOLDOWN 20 SECONDS
#define WARRIOR_FLING_DISTANCE 4 // in tiles
#define WARRIOR_FLING_EMPOWER_MULTIPLIER 2

/datum/action/ability/activable/xeno/warrior/fling
	name = "Fling"
	action_icon_state = "fling"
	action_icon = 'icons/Xeno/actions/shrike.dmi'
	ability_cost = 20
	cooldown_duration = WARRIOR_FLING_TOSS_COOLDOWN
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_FLING,
	)
	target_flags = ABILITY_MOB_TARGET

/datum/action/ability/activable/xeno/warrior/fling/New(Target)
	. = ..()
	desc = "Send a target flying up to [WARRIOR_FLING_DISTANCE] tiles away. Distance reduced for bigger targets. Usable on allies."

/datum/action/ability/activable/xeno/warrior/fling/can_use_ability(atom/A, silent = FALSE, override_flags)
	. = ..()
	if(!.)
		return FALSE
	if(!A)
		return FALSE
	if(!isliving(A))
		if(!silent)
			owner.balloon_alert(owner, "Invalid target")
		return FALSE
	var/mob/living/living_target = A
	if(living_target.stat == DEAD && !living_target.issamexenohive(owner))
		if(!silent)
			owner.balloon_alert(owner, "Dead")
		return FALSE
	if(!living_target.Adjacent(owner))
		if(!silent)
			owner.balloon_alert(owner, "Not adjacent")
		return FALSE

/datum/action/ability/activable/xeno/warrior/fling/use_ability(atom/A)
	. = ..()
	GLOB.round_statistics.warrior_flings++
	SSblackbox.record_feedback(FEEDBACK_TALLY, "round_statistics", 1, "warrior_flings")
	var/mob/living/living_target = A
	xeno_owner.face_atom(living_target)
	playsound(living_target, 'sound/weapons/alien_claw_block.ogg', 75, 1)
	shake_camera(living_target, 1, 1)
	xeno_owner.do_attack_animation(living_target, ATTACK_EFFECT_DISARM2)
	var/fling_distance = WARRIOR_FLING_DISTANCE
	if(living_target.mob_size >= MOB_SIZE_BIG) // Penalize fling distance for big creatures.
		fling_distance--
	var/datum/action/ability/xeno_action/empower/empower_action = xeno_owner.actions_by_path[/datum/action/ability/xeno_action/empower]
	if(empower_action?.check_empower(living_target))
		fling_distance *= WARRIOR_FLING_EMPOWER_MULTIPLIER
	if(!living_target.issamexenohive(xeno_owner))
		RegisterSignal(living_target, COMSIG_MOVABLE_IMPACT, PROC_REF(thrown_into))
		RegisterSignal(living_target, COMSIG_MOVABLE_POST_THROW, PROC_REF(throw_ended))
	living_target.add_pass_flags(PASS_XENO, THROW_TRAIT)
	var/fling_direction = get_dir(xeno_owner, living_target)
	living_target.throw_at(get_ranged_target_turf(xeno_owner, fling_direction ? fling_direction : xeno_owner.dir, fling_distance), fling_distance, 2, xeno_owner, TRUE)
	succeed_activate()
	add_cooldown()
	var/datum/action/ability/activable/xeno/warrior/grapple_toss/toss_action = xeno_owner.actions_by_path[/datum/action/ability/activable/xeno/warrior/grapple_toss]
	toss_action?.add_cooldown()

/datum/action/ability/activable/xeno/warrior/fling/ai_should_start_consider()
	return TRUE

/datum/action/ability/activable/xeno/warrior/fling/ai_should_use(atom/target)
	if(!iscarbon(target))
		return FALSE
	if(get_dist(target, owner) > 1)
		return FALSE
	if(!can_use_ability(target, override_flags = ABILITY_IGNORE_SELECTED_ABILITY))
		return FALSE
	if(target.get_xeno_hivenumber() == owner.get_xeno_hivenumber())
		return FALSE
	return TRUE

// ***************************************
// *********** Grapple Toss
// ***************************************
#define WARRIOR_GRAPPLE_TOSS_DISTANCE 4 // in tiles
#define WARRIOR_GRAPPLE_TOSS_STAGGER 3 SECONDS
#define WARRIOR_GRAPPLE_TOSS_SLOWDOWN 3
#define WARRIOR_GRAPPLE_TOSS_EMPOWER_MULTIPLIER 2
#define WARRIOR_GRAPPLE_TOSS_THROW_PARALYZE 0.5 SECONDS

/datum/action/ability/activable/xeno/warrior/grapple_toss
	name = "Grapple Toss"
	action_icon_state = "grapple_toss"
	action_icon = 'icons/Xeno/actions/warrior.dmi'
	ability_cost = 20
	cooldown_duration = WARRIOR_FLING_TOSS_COOLDOWN
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_GRAPPLE_TOSS,
	)
	target_flags = ABILITY_TURF_TARGET

/datum/action/ability/activable/xeno/warrior/grapple_toss/New(Target)
	. = ..()
	desc = "Throw a creature under our grasp up to [WARRIOR_GRAPPLE_TOSS_DISTANCE] tiles away. Distance reduced on larger targets. Usable on allies."

/datum/action/ability/activable/xeno/warrior/grapple_toss/on_cooldown_finish()
	var/datum/action/ability/activable/xeno/warrior/fling/fling_action = xeno_owner.actions_by_path[/datum/action/ability/activable/xeno/warrior/fling]
	xeno_owner.balloon_alert(xeno_owner, "[fling_action ? "[initial(fling_action.name)] / " : ""][initial(name)] ready")
	return ..()

/datum/action/ability/activable/xeno/warrior/grapple_toss/can_use_ability(atom/A, silent = FALSE, override_flags)
	. = ..()
	if(!.)
		return FALSE
	if(!owner.pulling)
		if(!silent)
			owner.balloon_alert(owner, "Nothing to toss")
		return FALSE
	if(!owner.issamexenohive(owner.pulling)) //xenos should be able to fling xenos into xeno passable areas!
		for(var/obj/effect/forcefield/fog/fog in owner.loc)
			owner.pulling.balloon_alert(owner, "Cannot, fog")
			return fail_activate()
	if(!owner.Adjacent(owner.pulling))
		if(!silent)
			owner.balloon_alert(owner, "Target not adjacent")
		return FALSE

/datum/action/ability/activable/xeno/warrior/grapple_toss/use_ability(atom/A)
	. = ..()
	var/atom/movable/atom_target = xeno_owner.pulling
	var/fling_distance = WARRIOR_GRAPPLE_TOSS_DISTANCE
	var/datum/action/ability/xeno_action/empower/empower_action = xeno_owner.actions_by_path[/datum/action/ability/xeno_action/empower]
	if(empower_action?.check_empower(atom_target))
		fling_distance *= WARRIOR_GRAPPLE_TOSS_EMPOWER_MULTIPLIER
	if(isliving(atom_target))
		var/mob/living/living_target = atom_target
		if(living_target.mob_size >= MOB_SIZE_BIG)
			fling_distance--
		if(!living_target.issamexenohive(xeno_owner))
			living_target.add_pass_flags(PASS_XENO, THROW_TRAIT)
			shake_camera(living_target, 1, 1)
			living_target.adjust_stagger(WARRIOR_GRAPPLE_TOSS_STAGGER)
			living_target.add_slowdown(WARRIOR_GRAPPLE_TOSS_SLOWDOWN)
			living_target.adjust_blurriness(WARRIOR_GRAPPLE_TOSS_SLOWDOWN)
			living_target.Paralyze(WARRIOR_GRAPPLE_TOSS_THROW_PARALYZE) // very important otherwise the guy can move right as you throw them
			RegisterSignal(living_target, COMSIG_MOVABLE_IMPACT, PROC_REF(thrown_into))
			RegisterSignal(living_target, COMSIG_MOVABLE_POST_THROW, PROC_REF(throw_ended))
	xeno_owner.face_atom(atom_target)
	atom_target.forceMove(get_turf(xeno_owner))
	xeno_owner.do_attack_animation(atom_target, ATTACK_EFFECT_DISARM2)
	playsound(atom_target, 'sound/weapons/alien_claw_block.ogg', 75, 1)
	atom_target.throw_at(get_turf(A), fling_distance, 2, xeno_owner, TRUE)
	succeed_activate()
	add_cooldown()
	var/datum/action/ability/activable/xeno/warrior/fling/fling_action = xeno_owner.actions_by_path[/datum/action/ability/activable/xeno/warrior/fling]
	fling_action?.add_cooldown()

// ***************************************
// *********** Punch
// ***************************************

/datum/action/ability/activable/xeno/warrior/punch
	name = "Punch"
	desc = "Strike a target, inflicting stamina damage, stagger and slowdown. Deals double damage, stagger and slowdown to grappled targets. Deals quadruple damage to structures and machinery."
	action_icon_state = "punch"
	action_icon = 'icons/Xeno/actions/warrior.dmi'
	ability_cost = 15
	cooldown_duration = 10 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_PUNCH,
	)
	target_flags = ABILITY_MOB_TARGET
	var/range = 1

/datum/action/ability/activable/xeno/warrior/punch/on_cooldown_finish()
	xeno_owner.balloon_alert(xeno_owner, "[initial(name)] ready")
	return ..()

/datum/action/ability/activable/xeno/warrior/punch/can_use_ability(atom/A, silent = FALSE, override_flags)
	. = ..()
	if(!.)
		return
	if(!isliving(A) && !isstructure(A) && !ismachinery(A) && !isvehicle(A))
		if(!silent)
			owner.balloon_alert(owner, "Cannot punch")
		return FALSE
	if(A.resistance_flags & (INDESTRUCTIBLE|CRUSHER_IMMUNE))
		if(!silent)
			owner.balloon_alert(owner, "Cannot damage")
		return FALSE
	if(isliving(A))
		var/mob/living/living_target = A
		if(living_target.issamexenohive(owner))
			if(!silent)
				owner.balloon_alert(owner, "Cannot punch")
			return FALSE
		if(living_target.stat == DEAD)
			if(!silent)
				owner.balloon_alert(owner, "Dead")
			return FALSE
	if(!line_of_sight(owner, A, range))
		if(!silent)
			owner.balloon_alert(owner, "Too far")
		return FALSE

/datum/action/ability/activable/xeno/warrior/punch/use_ability(atom/A)
	. = ..()
	GLOB.round_statistics.warrior_punches++
	SSblackbox.record_feedback(FEEDBACK_TALLY, "round_statistics", 1, "warrior_punches")
	do_ability(A)

/// Does the ability. Exists because Punch is the parent of another ability, so this lets us separate functionality and avoid repeating a few lines of code.
/datum/action/ability/activable/xeno/warrior/punch/proc/do_ability(atom/A)
	var/punch_damage = xeno_owner.xeno_caste.melee_damage * xeno_owner.xeno_melee_damage_modifier
	var/datum/action/ability/xeno_action/empower/empower_action = xeno_owner.actions_by_path[/datum/action/ability/xeno_action/empower]
	if(empower_action?.check_empower(A))
		punch_damage *= WARRIOR_PUNCH_EMPOWER_MULTIPLIER
	if(!A.punch_act(xeno_owner, punch_damage))
		return fail_activate()
	succeed_activate()
	add_cooldown()

/datum/action/ability/activable/xeno/warrior/punch/ai_should_start_consider()
	return TRUE

/datum/action/ability/activable/xeno/warrior/punch/ai_should_use(atom/target)
	if(!iscarbon(target))
		return FALSE
	if(get_dist(target, owner) > 1)
		return FALSE
	if(!can_use_ability(target, override_flags = ABILITY_IGNORE_SELECTED_ABILITY))
		return FALSE
	if(target.get_xeno_hivenumber() == owner.get_xeno_hivenumber())
		return FALSE
	return TRUE

/obj/effect/temp_visual/warrior/punch
	icon = 'icons/effects/effects.dmi'
	icon_state = "weak_punch"
	duration = 2.5
	layer = ABOVE_ALL_MOB_LAYER

/obj/effect/temp_visual/warrior/punch/weak/Initialize(mapload)
	. = ..()
	animate(src, time = duration + 1, alpha = 0)

/obj/effect/temp_visual/warrior/punch/strong
	icon = 'icons/effects/64x64.dmi'
	icon_state = "strong_punch"
	duration = 3
	pixel_x = -16
	pixel_y = -16

// ***************************************
// *********** Flurry
// ***************************************
#define WARRIOR_JAB_DAMAGE_MULTIPLIER 1.3
#define WARRIOR_JAB_BLIND 1
#define WARRIOR_JAB_BLUR 1
#define WARRIOR_JAB_CONFUSION_DURATION 3 SECONDS

/datum/action/ability/activable/xeno/warrior/punch/flurry
	name = "Flurry"
	desc = "Strike at your target with blinding speed."
	action_icon_state = "jab"
	ability_cost = 10
	cooldown_duration = 7 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_FLURRY,
	)
	/// The amount of charges we currently have. Initial value is assumed to be the maximum.
	var/current_charges = 3

/datum/action/ability/activable/xeno/warrior/punch/flurry/give_action(mob/living/L)
	. = ..()
	var/mutable_appearance/counter_maptext = mutable_appearance(icon = null, icon_state = null, layer = ACTION_LAYER_MAPTEXT)
	counter_maptext.pixel_x = 16
	counter_maptext.pixel_y = -4
	counter_maptext.maptext = MAPTEXT("[current_charges]/[initial(current_charges)]")
	visual_references[VREF_MUTABLE_JAB] = counter_maptext

/datum/action/ability/activable/xeno/warrior/punch/flurry/remove_action(mob/living/carbon/xenomorph/X)
	. = ..()
	button.cut_overlay(visual_references[VREF_MUTABLE_JAB])
	visual_references[VREF_MUTABLE_JAB] = null

/datum/action/ability/activable/xeno/warrior/punch/flurry/update_button_icon()
	button.cut_overlay(visual_references[VREF_MUTABLE_JAB])
	var/mutable_appearance/number = visual_references[VREF_MUTABLE_JAB]
	number?.maptext = MAPTEXT("[current_charges]/[initial(current_charges)]")
	visual_references[VREF_MUTABLE_JAB] = number
	button.add_overlay(visual_references[VREF_MUTABLE_JAB])
	return ..()

/datum/action/ability/activable/xeno/warrior/punch/flurry/on_cooldown_finish()
	current_charges = clamp(current_charges+1, 0, initial(current_charges))
	owner.balloon_alert(owner, "[initial(name)] ready[current_charges > 1 ? " ([current_charges]/[initial(current_charges)])" : ""]")
	update_button_icon()
	if(current_charges < initial(current_charges))
		cooldown_timer = addtimer(CALLBACK(src, PROC_REF(on_cooldown_finish)), cooldown_duration, TIMER_STOPPABLE)
		return
	return ..()

/datum/action/ability/activable/xeno/warrior/punch/flurry/can_use_action(silent, override_flags)
	. = ..()
	if(cooldown_timer && current_charges > 0)
		return TRUE

/datum/action/ability/activable/xeno/warrior/punch/flurry/do_ability(atom/A)
	var/jab_damage = round((xeno_owner.xeno_caste.melee_damage * xeno_owner.xeno_melee_damage_modifier) * WARRIOR_JAB_DAMAGE_MULTIPLIER)
	if(!A.punch_act(xeno_owner, jab_damage, FALSE))
		return fail_activate()
	current_charges--
	succeed_activate()
	add_cooldown()
	if(!isliving(A))
		return
	var/datum/action/ability/xeno_action/empower/empower_action = xeno_owner.actions_by_path[/datum/action/ability/xeno_action/empower]
	if(!empower_action?.check_empower(A))
		return
	var/mob/living/living_target = A
	living_target.adjust_blindness(WARRIOR_JAB_BLIND)
	living_target.adjust_blurriness(WARRIOR_JAB_BLUR)
	living_target.apply_status_effect(STATUS_EFFECT_CONFUSED, WARRIOR_JAB_CONFUSION_DURATION)

// ***************************************
// *********** Jab
// ***************************************
/datum/action/ability/activable/xeno/warrior/punch/jab
	name = "Jab"
	desc = "Precisely strike your target from further away, heavily slowing them."
	action_icon_state = "jab"
	ability_cost = 10
	range = 2
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_JAB,
	)

/datum/action/ability/activable/xeno/warrior/punch/jab/use_ability(atom/A)
	var/jab_damage = xeno_owner.xeno_caste.melee_damage * xeno_owner.xeno_melee_damage_modifier
	var/datum/action/ability/xeno_action/empower/empower_action = xeno_owner.actions_by_path[/datum/action/ability/xeno_action/empower]
	if(!A.punch_act(xeno_owner, jab_damage))
		return fail_activate()
	if(empower_action?.check_empower(A))
		jab_damage *= WARRIOR_PUNCH_EMPOWER_MULTIPLIER
		if(ishuman(A))
			var/mob/living/carbon/human/target = A
			to_chat(target, span_userdanger("The concussion from the [xeno_owner]'s blow blinds us!"))
			target.apply_status_effect(STATUS_EFFECT_CONFUSED, 3 SECONDS)
			target.Paralyze(0.5 SECONDS)
	GLOB.round_statistics.warrior_punches++
	SSblackbox.record_feedback(FEEDBACK_TALLY, "round_statistics", 1, "warrior_punches")
	succeed_activate()
	add_cooldown()

/datum/action/ability/activable/xeno/warrior/punch/jab/on_cooldown_finish()
	xeno_owner.balloon_alert(xeno_owner, "Jab ready")
	owner.playsound_local(owner, 'sound/effects/alien/newlarva.ogg', 25, 0, 1)
	return ..()\

// ***************************************
// *********** Encased Plates
// ***************************************

/datum/action/ability/xeno_action/toggle_plates
	name = "Encased Plates"
	desc = "Raise your plates: +front armor and knockdown immunity, but slower movement and weaker claws."
	action_icon_state = "encased_plates"
	action_icon = 'icons/Xeno/actions/warrior.dmi'
	cooldown_duration = 1 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_ENCASED_PLATES,
	)

/datum/action/ability/xeno_action/toggle_plates/action_activate()
	var/mob/living/carbon/xenomorph/warrior/bulwark/B = xeno_owner
	if(!istype(B))
		return fail_activate()
	if(B.plates_active)
		var/datum/action/ability/xeno_action/reflective_shield/RS = xeno_owner.actions_by_path[/datum/action/ability/xeno_action/reflective_shield]
		if(RS?.active)
			RS.deactivate()
		set_plates(FALSE)
	else
		set_plates(TRUE)
	add_cooldown()
	return succeed_activate()

/datum/action/ability/xeno_action/toggle_plates/proc/set_plates(on, silent = FALSE)
	var/mob/living/carbon/xenomorph/warrior/bulwark/B = xeno_owner
	if(!istype(B))
		return
	var/datum/xeno_caste/warrior/bulwark/caste = B.xeno_caste
	if(on)
		if(!silent)
			to_chat(B, span_xenowarning("We raise our plates and form a shield."))
		ADD_TRAIT(B, TRAIT_STAGGERIMMUNE, TRAIT_PLATES)
		B.move_resist = MOVE_FORCE_EXTREMELY_STRONG
		B.front_armor_bonus += caste.plates_armor
		B.side_armor_bonus -= caste.plates_armor
		B.xeno_melee_damage_modifier -= 0.35
		B.add_movespeed_modifier(MOVESPEED_ID_BULWARK_PLATES, TRUE, 0, NONE, TRUE, caste.plates_slowdown)
	else
		if(!silent)
			to_chat(B, span_xenowarning("We lower our plates."))
		REMOVE_TRAIT(B, TRAIT_STAGGERIMMUNE, TRAIT_PLATES)
		B.move_resist = initial(B.move_resist)
		B.front_armor_bonus -= caste.plates_armor
		B.side_armor_bonus += caste.plates_armor
		B.xeno_melee_damage_modifier += 0.35
		B.remove_movespeed_modifier(MOVESPEED_ID_BULWARK_PLATES)
	B.plates_active = on
	B.update_icons()

/datum/action/ability/xeno_action/toggle_plates/remove_action(mob/living/carbon/xenomorph/X)
	var/mob/living/carbon/xenomorph/warrior/bulwark/B = X
	if(B?.plates_active)
		set_plates(FALSE, TRUE)
	return ..()

// ***************************************
// *********** Plate Bash
// ***************************************

/datum/action/ability/activable/xeno/plate_bash
	name = "Plate Bash"
	desc = "Dash up to 2 tiles and shove the target 1 tile away. While encased: adjacent only, but launches 3 tiles with knockdown and stun."
	action_icon_state = "plate_bash"
	action_icon = 'icons/Xeno/actions/warrior.dmi'
	cooldown_duration = 5 SECONDS
	ability_cost = 35
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_PLATE_BASH,
	)
	target_flags = ABILITY_MOB_TARGET
	var/base_damage = 30

/datum/action/ability/activable/xeno/plate_bash/can_use_ability(atom/target, silent = FALSE, override_flags)
	. = ..()
	if(!.)
		return FALSE
	if(QDELETED(target) || !ishuman(target))
		return FALSE
	var/mob/living/carbon/xenomorph/warrior/bulwark/B = xeno_owner
	var/max_dist = (B && B.plates_active) ? 1 : 2
	if(!line_of_sight(owner, target, max_dist))
		if(!silent)
			to_chat(owner, span_warning("We must get closer!"))
		return FALSE
	var/mob/living/carbon/human/victim = target
	if(isnestedhost(victim) || victim.stat == DEAD)
		return FALSE

/datum/action/ability/activable/xeno/plate_bash/use_ability(mob/living/victim)
	var/mob/living/carbon/xenomorph/warrior/bulwark/B = xeno_owner

	if(!B.plates_active)
		xeno_owner.throw_at(get_step_towards(victim, xeno_owner), 2, 3, owner)
	if(!xeno_owner.Adjacent(victim))
		succeed_activate()
		add_cooldown()
		return

	owner.visible_message(
		span_xenowarning("[owner] slams [victim] with its armored plates!"),
		span_xenowarning("We slam [victim] with our armored plates!"))
	victim.apply_damage(base_damage, BRUTE, BODY_ZONE_CHEST, MELEE)
	xeno_owner.do_attack_animation(victim)

	var/facing = get_dir(xeno_owner, victim)
	if(B.plates_active)
		victim.throw_at(get_ranged_target_turf(victim, facing, 3), 3, 4, owner, TRUE)
		victim.Knockdown(2 SECONDS)
		victim.Paralyze(0.5 SECONDS)
	else
		victim.throw_at(get_ranged_target_turf(victim, facing, 1), 1, 1, owner, TRUE)
		shake_camera(victim, 1, 1)

	playsound(victim, 'sound/weapons/alien_claw_block.ogg', 75, 1)
	succeed_activate()
	add_cooldown()

// ***************************************
// *********** Tail Sweep (Bulwark)
// ***************************************

/datum/action/ability/xeno_action/tail_sweep/bulwark
	cooldown_duration = 15 SECONDS
	ability_cost = 30

/datum/action/ability/xeno_action/tail_sweep/bulwark/action_activate()
	var/hit_mob = FALSE
	for(var/mob/living/carbon/human/H in orange(1, xeno_owner))
		if(H.stat == DEAD || !xeno_owner.Adjacent(H))
			continue
		if(H.get_xeno_hivenumber() == xeno_owner.get_xeno_hivenumber())
			continue
		hit_mob = TRUE
		break

	. = ..()

	if(!hit_mob)
		cooldown_duration = cooldown_duration / 3
		add_cooldown()
		cooldown_duration = initial(cooldown_duration)

// ***************************************
// *********** Reflective Shield
// ***************************************

/datum/action/ability/xeno_action/reflective_shield
	name = "Reflective Shield"
	desc = "Lock your facing and reflect frontal bullets back for half damage, up to 6 seconds. You cannot attack while active. Cooldown 6-18s."
	action_icon_state = "reflective_shield"
	action_icon = 'icons/Xeno/actions/warrior.dmi'
	ability_cost = 80
	cooldown_duration = 6 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_REFLECTIVE_SHIELD,
	)
	var/active = FALSE
	var/start_time = 0
	var/reflect_timer_id = 0

/datum/action/ability/xeno_action/reflective_shield/can_use_action(silent, override_flags)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/carbon/xenomorph/warrior/bulwark/B = xeno_owner
	if(!istype(B))
		return FALSE
	if(!active && !B.plates_active)
		if(!silent)
			to_chat(owner, span_xenowarning("We need to encase our plates first!"))
		return FALSE

/datum/action/ability/xeno_action/reflective_shield/action_activate()
	var/mob/living/carbon/xenomorph/warrior/bulwark/B = xeno_owner
	if(active)
		deactivate()
		return succeed_activate(0)

	active = TRUE
	start_time = world.time
	B.reflective_active = TRUE
	ADD_TRAIT(B, TRAIT_REFLECTIVE_SHIELD, TRAIT_REFLECTIVESHIELD)
	B.stop_pulling()
	B.update_icons()
	to_chat(B, span_xenowarning("We lock our stance, focusing on incoming frontal attacks!"))
	reflect_timer_id = addtimer(CALLBACK(src, PROC_REF(deactivate)), 6 SECONDS, TIMER_STOPPABLE)
	succeed_activate()

/datum/action/ability/xeno_action/reflective_shield/proc/deactivate()
	if(!active)
		return
	active = FALSE
	if(reflect_timer_id)
		deltimer(reflect_timer_id)
		reflect_timer_id = 0
	var/mob/living/carbon/xenomorph/warrior/bulwark/B = xeno_owner
	if(!B)
		return
	B.reflective_active = FALSE
	REMOVE_TRAIT(B, TRAIT_REFLECTIVE_SHIELD, TRAIT_REFLECTIVESHIELD)
	B.update_icons()
	var/held = (world.time - start_time) / 10
	cooldown_duration = clamp(6 SECONDS + held * 2 SECONDS, 6 SECONDS, 18 SECONDS)
	add_cooldown()
	cooldown_duration = initial(cooldown_duration)
	to_chat(B, span_xenowarning("We adjust our plates and stance back to normal."))

// ***************************************
// *********** Shield Shatter (Primordial)
// ***************************************

/datum/action/ability/xeno_action/shield_shatter
	name = "Shield Shatter"
	desc = "Detonate your plates outward, throwing nearby enemies back. Sends your Reflective Shield into an 18 second cooldown. Primordial only."
	action_icon_state = "psy_shield_reflect" // посмотри в warlock.dmi state взрыва щита и подставь нужный
	action_icon = 'icons/Xeno/actions/warlock.dmi'
	cooldown_duration = 30 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_SHIELD_SHATTER,
	)

/datum/action/ability/xeno_action/shield_shatter/can_use_action(silent, override_flags)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/carbon/xenomorph/warrior/bulwark/B = xeno_owner
	if(!istype(B))
		return FALSE
	if(!istype(B.xeno_caste, /datum/xeno_caste/warrior/bulwark/primordial))
		if(!silent)
			to_chat(owner, span_xenowarning("Only a primordial bulwark can shatter its plates!"))
		return FALSE
	if(!B.plates_active)
		if(!silent)
			to_chat(owner, span_xenowarning("We must encase our plates first!"))
		return FALSE

/datum/action/ability/xeno_action/shield_shatter/action_activate()
	var/mob/living/carbon/xenomorph/warrior/bulwark/B = xeno_owner

	playsound(B, 'sound/effects/bamf.ogg', 75, TRUE)
	playsound(B, 'sound/voice/alien/roar_warlock.ogg', 25)
	B.visible_message(
		span_xenowarning("[B] shatters its plates outward!"),
		span_xenowarning("We shatter our plates outward!"))


	for(var/turf/T AS in RANGE_TURFS(1, B))
		T.Shake(duration = 0.5 SECONDS)
		for(var/atom/movable/AM AS in T)
			if(!ishuman(AM))
				AM.Shake(duration = 0.5 SECONDS)

	for(var/mob/living/carbon/human/H in orange(1, B))
		if(H.stat == DEAD || H.issamexenohive(B))
			continue
		H.apply_damage(30, BRUTE, blocked = MELEE)
		H.Knockdown(1 SECONDS)
		shake_camera(H, 2, 1)
		var/throw_dir = get_dir(B, H)
		if(throw_dir)
			H.throw_at(get_ranged_target_turf(H, throw_dir, 3), 3, 2, B, TRUE)


	shake_camera(B, 1, 1)

	var/datum/action/ability/xeno_action/reflective_shield/RS = xeno_owner.actions_by_path[/datum/action/ability/xeno_action/reflective_shield]
	if(RS?.active)
		RS.deactivate()
	if(RS)
		RS.cooldown_duration = 18 SECONDS
		RS.add_cooldown()
		RS.cooldown_duration = initial(RS.cooldown_duration)

	succeed_activate()
	add_cooldown()

/obj/effect/temp_visual/shield_shatter
	icon = 'icons/effects/96x96.dmi'
	icon_state = "shield_shatter"
	duration = 1 SECONDS
	layer = ABOVE_ALL_MOB_LAYER
	pixel_x = -32
	pixel_y = -32
