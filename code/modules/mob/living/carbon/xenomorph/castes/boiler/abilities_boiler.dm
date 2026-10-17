//Defines for boiler globs. Their icon states, specifically. Also used to reference their typepaths and for the radials.
#define BOILER_GLOB_NEURO "neuro_glob"
#define BOILER_GLOB_ACID "acid_glob"
#define BOILER_GLOB_NEURO_LANCE	"neuro_lance_glob"
#define BOILER_GLOB_ACID_LANCE	"acid_lance_glob"

///List of globs, keyed by icon state. Used for radial selection.
GLOBAL_LIST_INIT(boiler_glob_list, list(
	BOILER_GLOB_ACID = /datum/ammo/xeno/boiler_gas/corrosive,
	BOILER_GLOB_ACID_LANCE = /datum/ammo/xeno/boiler_gas/corrosive/lance,
))

///List of glob action button images, used for radial selection.
GLOBAL_LIST_INIT(boiler_glob_image_list, list(
	BOILER_GLOB_ACID = image('icons/Xeno/actions/boiler.dmi', icon_state = BOILER_GLOB_ACID),
	BOILER_GLOB_ACID_LANCE = image('icons/Xeno/actions/boiler.dmi', icon_state = BOILER_GLOB_ACID_LANCE),
))

// ***************************************
// *********** Long range sight
// ***************************************

/datum/action/ability/xeno_action/toggle_long_range
	name = "Toggle Long Range Sight"
	desc = "Activates your weapon sight in the direction you are facing. Must remain stationary to use."
	action_icon_state = "toggle_long_range"
	action_icon = 'icons/Xeno/actions/boiler.dmi'
	ability_cost = 20
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_LONG_RANGE_SIGHT,
	)

/datum/action/ability/xeno_action/toggle_long_range/action_activate()
	if(xeno_owner.xeno_flags & XENO_ZOOMED)
		xeno_owner.zoom_out()
		xeno_owner.visible_message(span_notice("[xeno_owner] stops looking off into the distance."), \
		span_notice("We stop looking off into the distance."), null, 5)
	else
		xeno_owner.visible_message(span_notice("[xeno_owner] starts looking off into the distance."), \
			span_notice("We start focusing your sight to look off into the distance."), null, 5)
		if(!do_after(xeno_owner, 1 SECONDS, IGNORE_HELD_ITEM, null, BUSY_ICON_GENERIC) || xeno_owner.xeno_flags & XENO_ZOOMED)
			return
		xeno_owner.zoom_in(11)
		return ..()

// ***************************************
// *********** Gas type toggle
// ***************************************

/datum/action/ability/xeno_action/toggle_bomb
	name = "Toggle Bombard Type"
	desc = "Switches Boiler Bombard type between available glob types."
	action_icon_state = "toggle_bomb0"
	action_icon = 'icons/Xeno/actions/boiler.dmi'
	use_state_flags = ABILITY_USE_BUSY|ABILITY_USE_LYING
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_TOGGLE_BOMB,
		KEYBINDING_ALTERNATE = COMSIG_XENOABILITY_TOGGLE_BOMB_RADIAL,
	)

/datum/action/ability/xeno_action/toggle_bomb/action_activate()
	var/list/spit_types = xeno_owner.xeno_caste.spit_types
	var/found_pos = spit_types.Find(xeno_owner.ammo?.type)
	if(!found_pos)
		xeno_owner.ammo = GLOB.ammo_list[spit_types[1]]
	else
		xeno_owner.ammo = GLOB.ammo_list[spit_types[(found_pos % length(spit_types)) + 1]]	//Loop around if we would exceed the length
	var/datum/ammo/xeno/boiler_gas/corrosive/boiler_glob = xeno_owner.ammo
	to_chat(xeno_owner, span_notice(boiler_glob.select_text))
	update_button_icon()

/datum/action/ability/xeno_action/toggle_bomb/alternate_action_activate()
	. = COMSIG_KB_ACTIVATED
	if(!can_use_action())
		return
	if(length(xeno_owner.xeno_caste.spit_types) <= 2)	//If we only have two or less glob types, we just use default select anyways.
		action_activate()
		return
	INVOKE_ASYNC(src, PROC_REF(select_glob_radial))

/**
 * Opens a radial menu to select a glob in and sets current ammo to the selected result.
 * * On selecting nothing, merely keeps current ammo.
 * * Dynamically adjusts depending on which globs a boiler has access to, provided the global lists are maintained, though this fact isn't too relevant unless someone adds more.
**/
/datum/action/ability/xeno_action/toggle_bomb/proc/select_glob_radial()
	var/list/available_globs = list()
	for(var/datum/ammo/xeno/boiler_gas/corrosive/glob_type AS in xeno_owner.xeno_caste.spit_types)
		var/glob_image = GLOB.boiler_glob_image_list[initial(glob_type.icon_key)]
		if(!glob_image)
			continue
		available_globs[initial(glob_type.icon_key)] = glob_image

	var/glob_choice = show_radial_menu(owner, owner, available_globs, radius = 48)
	if(!glob_choice)
		return
	var/referenced_path = GLOB.boiler_glob_list[glob_choice]
	xeno_owner.ammo = GLOB.ammo_list[referenced_path]
	var/datum/ammo/xeno/boiler_gas/corrosive/boiler_glob = xeno_owner.ammo
	to_chat(xeno_owner, span_notice(boiler_glob.select_text))
	update_button_icon()

/datum/action/ability/xeno_action/toggle_bomb/update_button_icon()
	var/datum/ammo/xeno/boiler_gas/corrosive/boiler_glob = xeno_owner.ammo	//Should be safe as this always selects a ammo.
	action_icon_state = boiler_glob.icon_key
	return ..()

// ***************************************
// *********** Gas cloud bomb maker
// ***************************************

/datum/action/ability/xeno_action/create_boiler_bomb
	name = "Create bomb"
	action_icon_state = "toggle_bomb0" //to be changed
	action_icon = 'icons/Xeno/actions/boiler.dmi'
	desc = "Creates a Boiler Bombard of the type currently selected."
	ability_cost = 200
	use_state_flags = ABILITY_USE_BUSY|ABILITY_USE_LYING
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_CREATE_BOMB,
	)

/datum/action/ability/xeno_action/create_boiler_bomb/New(Target)
	. = ..()
	desc = "Creates a Boiler Bombard of the type currently selected. Reduces bombard cooldown by [BOILER_BOMBARD_COOLDOWN_REDUCTION] seconds for each stored. Begins to emit light when surpassing [BOILER_LUMINOSITY_THRESHOLD] globs stored."

/datum/action/ability/xeno_action/create_boiler_bomb/action_activate()
	if(xeno_owner.xeno_flags & XENO_ZOOMED)
		xeno_owner.balloon_alert(xeno_owner,"Can't while zoomed in!")
		return

	if(xeno_owner.corrosive_ammo >= xeno_owner.xeno_caste.max_ammo)
		to_chat(xeno_owner, span_notice("We can carry no more globules."))
		return

	succeed_activate()
	xeno_owner.corrosive_ammo++
	to_chat(xeno_owner, span_notice("We prepare a corrosive acid globule."))
	update_button_icon()
	xeno_owner.update_ammo_glow()

/datum/action/ability/xeno_action/create_boiler_bomb/update_button_icon()
	action_icon_state = "bomb_count_[xeno_owner.corrosive_ammo]"
	return ..()

/particles/xeno_smoke/acid_light
	color = "#9dcf30"

// ***************************************
// *********** Gas cloud bombs
// ***************************************
/datum/action/ability/activable/xeno/bombard
	name = "Bombard"
	desc = "Launch a glob of acid."
	action_icon_state = "bombard"
	action_icon = 'icons/Xeno/actions/boiler.dmi'
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_BOMBARD,
	)
	use_state_flags = NONE

/datum/action/ability/activable/xeno/bombard/get_cooldown()
	return xeno_owner.xeno_caste.bomb_delay - xeno_owner.corrosive_ammo * BOILER_BOMBARD_COOLDOWN_REDUCTION SECONDS

/datum/action/ability/activable/xeno/bombard/on_cooldown_finish()
	to_chat(xeno_owner, span_notice("We feel your toxin glands swell. We are able to bombard an area again."))
	if(xeno_owner.selected_ability == src)
		xeno_owner.set_bombard_pointer()
	return ..()

/// Signal proc for clicking at a distance
/datum/action/ability/activable/xeno/bombard/proc/on_ranged_attack(mob/living/carbon/xenomorph/xeno_owner, atom/A, params)
	SIGNAL_HANDLER
	if(can_use_ability(A, TRUE))
		INVOKE_ASYNC(src, PROC_REF(use_ability), A)

/datum/action/ability/activable/xeno/bombard/can_use_ability(atom/A, silent = FALSE, override_flags)
	. = ..()
	if(!.)
		return FALSE
	var/turf/T = get_turf(A)
	var/turf/S = get_turf(owner)

	if(xeno_owner.corrosive_ammo <= 0)
		xeno_owner.balloon_alert(xeno_owner, "No corrosive globules.")
		return FALSE

	if(!isturf(T) || T.z != S.z)
		if(!silent)
			xeno_owner.balloon_alert(xeno_owner, "Invalid target.")
		return FALSE

	if(get_dist(T, S) <= 5) //Magic number
		if(!silent)
			xeno_owner.balloon_alert(xeno_owner, "Too close!")
		return FALSE

/datum/action/ability/activable/xeno/bombard/on_selection()
	if(!xeno_owner)
		return
	var/current_ammo = xeno_owner.corrosive_ammo
	if(current_ammo <= 0)
		to_chat(xeno_owner, span_notice("We have nothing prepared to fire."))
		return FALSE

	xeno_owner.visible_message(span_notice("\The [xeno_owner] begins digging their claws into the ground."), \
	span_notice("We begin digging ourselves into place."), null, 5)
	if(!do_after(xeno_owner, 3 SECONDS, IGNORE_HELD_ITEM, null, BUSY_ICON_HOSTILE))
		on_deselection()
		xeno_owner.selected_ability = null
		xeno_owner.update_action_button_icons()
		xeno_owner.reset_bombard_pointer()
		return FALSE

	xeno_owner.visible_message(span_notice("\The [xeno_owner] digs itself into the ground!"), \
		span_notice("We dig ourselves into place! If we move, we must wait again to fire."), null, 5)
	xeno_owner.set_bombard_pointer()
	RegisterSignal(xeno_owner, COMSIG_MOB_ATTACK_RANGED, TYPE_PROC_REF(/datum/action/ability/activable/xeno/bombard, on_ranged_attack))

/datum/action/ability/activable/xeno/bombard/on_deselection()
	if(xeno_owner?.selected_ability == src)
		xeno_owner.reset_bombard_pointer()
		to_chat(xeno_owner, span_notice("We relax our stance."))
	UnregisterSignal(owner, COMSIG_MOB_ATTACK_RANGED)

/mob/living/carbon/xenomorph/boiler/Moved(atom/OldLoc, Dir)
	. = ..()
	if(selected_ability?.type == /datum/action/ability/activable/xeno/bombard)
		var/datum/action/ability/activable/xeno/bombard/bomb = actions_by_path[/datum/action/ability/activable/xeno/bombard]
		bomb.on_deselection()
		selected_ability.button.icon_state = "template"
		selected_ability = null
		update_action_button_icons()

/mob/living/carbon/xenomorph/proc/set_bombard_pointer()
	if(client)
		client.mouse_pointer_icon = 'icons/mecha/mecha_mouse.dmi'

/mob/living/carbon/xenomorph/proc/reset_bombard_pointer()
	if(client)
		client.mouse_pointer_icon = initial(client.mouse_pointer_icon)

/datum/action/ability/activable/xeno/bombard/use_ability(atom/A)
	var/turf/target = get_turf(A)

	if(!istype(target))
		return

	to_chat(xeno_owner, span_xenonotice("We begin building up pressure."))

	if(!do_after(xeno_owner, 2 SECONDS, IGNORE_HELD_ITEM, target, BUSY_ICON_DANGER))
		to_chat(xeno_owner, span_warning("We decide not to launch."))
		return fail_activate()

	if(!can_use_ability(target, FALSE, ABILITY_IGNORE_PLASMA))
		return fail_activate()

	if((locate(/obj/effect/forcefield/fog) in xeno_owner.loc) && !get_nearest_target(xeno_owner, 5, TARGET_HUMAN, xeno_owner.faction, xeno_owner.hivenumber)) //говнокод, да
		return

	xeno_owner.visible_message(span_xenowarning("\The [xeno_owner] launches a huge glob of acid hurling into the distance!"), \
	span_xenowarning("We launch a huge glob of acid hurling into the distance!"), null, 5)

	var/atom/movable/projectile/P = new /atom/movable/projectile(xeno_owner.loc)
	P.generate_bullet(xeno_owner.ammo)
	P.fire_at(target, xeno_owner, xeno_owner, xeno_owner.ammo.max_range, xeno_owner.ammo.shell_speed)
	playsound(xeno_owner, 'sound/effects/blobattack.ogg', 25, 1)
	GLOB.round_statistics.boiler_acid_smokes++
	SSblackbox.record_feedback(FEEDBACK_TALLY, "round_statistics", 1, "boiler_acid_smokes")
	xeno_owner.corrosive_ammo--
	owner.record_war_crime()

	xeno_owner.update_ammo_glow()
	update_button_icon()
	add_cooldown()

/datum/action/ability/activable/xeno/bombard/clean_action()
	xeno_owner.reset_bombard_pointer()
	return ..()

// ***************************************
// *********** Acid spray
// ***************************************

/datum/action/ability/activable/xeno/spray_acid/line/boiler
	cooldown_duration = 9 SECONDS

/datum/action/ability/activable/xeno/acid_shroud
	name = "Acid Shroud"
	action_icon_state = "acid_shroud"
	action_icon = 'icons/Xeno/actions/boiler.dmi'
	desc = "Creates a smokescreen below yourself, at the cost of a longer cooldown for firing your Bombard."
	ability_cost = 200
	cooldown_duration = 30 SECONDS
	use_state_flags = ABILITY_USE_BUSY|ABILITY_USE_LYING
	keybind_flags = ABILITY_KEYBIND_USE_ABILITY | ABILITY_IGNORE_SELECTED_ABILITY
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_ACID_SHROUD,
		KEYBINDING_ALTERNATE = COMSIG_XENOABILITY_ACID_SHROUD_SELECT,
	)

/datum/action/ability/activable/xeno/acid_shroud/use_ability(atom/A)
	var/datum/effect_system/smoke_spread/emitted_gas = new /datum/effect_system/smoke_spread/xeno/acid(xeno_owner)
	emitted_gas.set_up(4, get_turf(xeno_owner))
	emitted_gas.start()
	succeed_activate()
	add_cooldown()
	var/datum/action/ability/activable/xeno/bombard/bombard_action = xeno_owner.actions_by_path[/datum/action/ability/activable/xeno/bombard]
	if(bombard_action?.cooldown_timer) //You need to clear a cooldown to add another, so that is done here.
		deltimer(bombard_action.cooldown_timer)
		bombard_action.cooldown_timer = null
		bombard_action.countdown.stop()
	bombard_action?.add_cooldown(xeno_owner.xeno_caste.bomb_delay + 8.5 SECONDS - (xeno_owner.corrosive_ammo * BOILER_BOMBARD_COOLDOWN_REDUCTION SECONDS)) //The cooldown of Bombard that is added when this ability is used. It is the calculation of Bombard cooldown + 10 seconds.

// ***************************************
// *********** Steam Rush
// ***************************************

/datum/action/ability/xeno_action/steam_rush
	name = "Toggle Steam Rush"
	action_icon_state = "steam_rush"
	action_icon = 'icons/Xeno/actions/boiler.dmi'
	desc = "Gain a speed and damage boost while draining plasma. Slashes grant stacks which increase speed and damage. Creates smoke when at max stacks."
	ability_cost = 25
	cooldown_duration = 15 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_STEAM_RUSH,
	)
	/// Holds the particles instead of the mob.
	var/obj/effect/abstract/particle_holder/particle_holder
	///A reference to the VREF used to display the current stacks of steam rush.
	var/vref = VREF_MUTABLE_STEAMRUSH_STACKS
	/// Is the ability currently being used?
	var/active = FALSE
	/// The base increase of speed when ability is active.
	var/base_speed_buff = -0.3
	/// The per stack increase of speed when ability is active.
	var/stack_speed_buff = -0.03
	/// How often we consume plasma while active.
	var/steam_check_interval = 0.5 SECONDS
	/// Timer for checking steam rush upkeep.
	var/steam_rush_duration
	/// How much extra burn damage is dealt on slash, per stack.
	var/steam_damage = 1
	/// Current stacks of steam rush. Higher stacks increase the buffs. Slashing enemies increases stacks. Max 10.
	var/stacks = 0

/datum/action/ability/xeno_action/steam_rush/can_use_action(silent, override_flags, selecting)
	if(active)
		return TRUE
	return ..()

/datum/action/ability/xeno_action/steam_rush/give_action(mob/living/L)
	. = ..()
	var/mutable_appearance/counter_maptext = mutable_appearance(icon = null, icon_state = null, layer = ACTION_LAYER_MAPTEXT)
	counter_maptext.pixel_x = 16
	counter_maptext.pixel_y = 16
	counter_maptext.maptext = MAPTEXT("[stacks]")
	visual_references[vref] = counter_maptext

/datum/action/ability/xeno_action/steam_rush/remove_action(mob/living/carbon/xenomorph/X)
	. = ..()
	button.cut_overlay(visual_references[vref])
	visual_references[vref] = null

/datum/action/ability/xeno_action/steam_rush/action_activate()
	if(active)
		deactivate_steam_rush()
	else
		activate_steam_rush()

/// Toggles steam rush on.
/datum/action/ability/xeno_action/steam_rush/proc/activate_steam_rush()
	active = TRUE

	xeno_owner.emote("roar")
	xeno_owner.visible_message(span_danger("[xeno_owner]'s body starts to hiss with steam!"), \
	span_xenowarning("We feel steam spraying from our body!"))

	xeno_owner.add_movespeed_modifier(MOVESPEED_ID_BOILER_SIZZLER_STEAM_RUSH, TRUE, 0, NONE, TRUE, base_speed_buff)

	particle_holder = new(owner, /particles/sizzler_steam)
	particle_holder.pixel_y = -8
	particle_holder.pixel_x = 10

	RegisterSignal(xeno_owner, COMSIG_XENOMORPH_ATTACK_LIVING, PROC_REF(steam_slash))

	manage_steam_rush()

/// Handles plasma drain and upkeep of steam rush.
/datum/action/ability/xeno_action/steam_rush/proc/manage_steam_rush()
	if(xeno_owner.plasma_stored < ability_cost)
		return deactivate_steam_rush()
	xeno_owner.use_plasma(ability_cost)
	steam_rush_duration = addtimer(CALLBACK(src, PROC_REF(manage_steam_rush)), steam_check_interval, TIMER_UNIQUE|TIMER_STOPPABLE|TIMER_OVERRIDE)

/// On hit proc for steam rush slashes. Slashing increases stacks, stacks provide damage and speed buffs.
/datum/action/ability/xeno_action/steam_rush/proc/steam_slash(datum/source, mob/living/target, damage, list/damage_mod, list/armor_mod)
	SIGNAL_HANDLER
	var/mob/living/carbon/carbon_target = target

	carbon_target.apply_damage(steam_damage * stacks, damagetype = BURN, blocked = ACID)
	xenomorph_spray(get_turf(carbon_target), 5 SECONDS, steam_damage * stacks)
	playsound(carbon_target, 'sound/voice/alien/hiss2.ogg', 25)
	to_chat(carbon_target, span_danger("You are burned by the hot steam!")) //I'm just going to operate under the assumption that xvx combat will never be a meaningful thing.

	switch(stacks)
		if(0 to 8)
			stacks++
			update_button_icon()
		if(9)
			stacks++
			update_button_icon()
			QDEL_NULL(particle_holder)
			particle_holder = new(owner, /particles/sizzler_steam/intense)
			particle_holder.pixel_y = -8
			particle_holder.pixel_x = 10
			xeno_owner.visible_message(span_danger("[xeno_owner]'s body is spewing steam intensely!"), \
			span_xenowarning("Our steam reaches max intensity!"))
		if(10)
			var/datum/effect_system/smoke_spread/smoke = new /datum/effect_system/smoke_spread/xeno/acid/light()
			playsound(carbon_target, 'sound/effects/smoke.ogg', 10, 1, 2)
			smoke.set_up(0, carbon_target)
			smoke.start()

	xeno_owner.add_movespeed_modifier(MOVESPEED_ID_BOILER_SIZZLER_STEAM_RUSH, TRUE, 0, NONE, TRUE, (base_speed_buff + (stack_speed_buff * stacks)))

/// Toggles steam rush off, removing buffs and putting the ability on cooldown.
/datum/action/ability/xeno_action/steam_rush/proc/deactivate_steam_rush()
	xeno_owner.remove_movespeed_modifier(MOVESPEED_ID_BOILER_SIZZLER_STEAM_RUSH)
	xeno_owner.playsound_local(xeno_owner, 'sound/voice/alien/hiss2.ogg', 50)
	deltimer(steam_rush_duration)
	steam_rush_duration = null
	active = FALSE
	stacks = 0
	update_button_icon()
	QDEL_NULL(particle_holder)
	UnregisterSignal(xeno_owner, COMSIG_XENOMORPH_ATTACK_LIVING)
	add_cooldown()

/datum/action/ability/xeno_action/steam_rush/on_cooldown_finish()
	owner.balloon_alert(owner, "steam rush ready")
	owner.playsound_local(owner, 'sound/effects/alien/newlarva.ogg', 25, 0, 1)
	return ..()

/datum/action/ability/xeno_action/steam_rush/update_button_icon()
	button.cut_overlay(visual_references[vref])
	if(stacks)
		var/mutable_appearance/number = visual_references[vref]
		number.maptext = MAPTEXT("[stacks]")
		visual_references[vref] = number
		button.add_overlay(visual_references[vref])
	return ..()

/datum/action/ability/xeno_action/steam_rush/ai_should_start_consider()
	return TRUE

/datum/action/ability/xeno_action/steam_rush/ai_should_use(atom/target)
	if(active)
		if(!iscarbon(target))
			return TRUE
		return FALSE
	if(!iscarbon(target))
		return FALSE
	if(!line_of_sight(owner, target, 7))
		return FALSE
	if(!can_use_action(override_flags = ABILITY_IGNORE_SELECTED_ABILITY))
		return FALSE
	if(target.get_xeno_hivenumber() == owner.get_xeno_hivenumber())
		return FALSE
	return TRUE

/particles/sizzler_steam
	icon = 'icons/effects/particles/smoke.dmi'
	icon_state = list("steam_1" = 1, "steam_2" = 1, "steam_3" = 2)
	width = 100
	height = 300
	count = 50
	spawning = 3
	lifespan = 1.5 SECONDS
	fade = 3 SECONDS
	velocity = list(0, 0.3, 0)
	position = list(5, 32, 0)
	drift = generator(GEN_SPHERE, 0, 1, NORMAL_RAND)
	friction = 0.1
	gravity = list(0, 0.95)
	grow = 0.1

/particles/sizzler_steam/intense
	count = 300
	spawning = 18
	drift = generator(GEN_SPHERE, 0, 2, NORMAL_RAND)

// ***************************************
// *********** Smokescreen Spit
// ***************************************

/datum/action/ability/activable/xeno/smokescreen_spit
	name = "Smokescreen Spit"
	action_icon_state = "acid_glob"
	action_icon = 'icons/Xeno/actions/boiler.dmi'
	desc = "Spit a steam smokescreen to cover your advance or retreat. Direct hits stagger and slow."
	ability_cost = 350
	cooldown_duration = 75 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_SMOKESCREEN_SPIT,
	)
	/// The amount of time for the do_after.
	var/cast_time = 3 SECONDS
	/// The ammo type the ability fires.
	var/datum/ammo/xeno/ammo_type = /datum/ammo/xeno/acid/smokescreen
	/// Timer for increasing light range while channeling.
	var/channel_light_timer
	/// Current light range while channeling.
	var/light_range = 0

/datum/action/ability/activable/xeno/smokescreen_spit/use_ability(atom/target)
	manage_channel_glow(TRUE)
	if(cast_time > 0 && !do_after(xeno_owner, cast_time, NONE, xeno_owner, BUSY_ICON_DANGER))
		manage_channel_glow(FALSE)
		add_cooldown(15 SECONDS) // Short cooldown on fail
		return fail_activate()

	var/atom/movable/projectile/newspit = new /atom/movable/projectile(get_turf(xeno_owner))
	newspit.generate_bullet(ammo_type)
	newspit.def_zone = xeno_owner.get_limbzone_target()

	newspit.fire_at(target, xeno_owner, xeno_owner, newspit.ammo.max_range)
	manage_channel_glow(FALSE)
	succeed_activate()
	add_cooldown()

/// Turns on/off the light glow while channeling the spit and increases the light range every half second.
/datum/action/ability/activable/xeno/smokescreen_spit/proc/manage_channel_glow(continue_light = FALSE)
	if(!continue_light)
		light_range = 0
		if(xeno_owner)
			xeno_owner.set_light_on(FALSE)
			xeno_owner.set_light_range_power_color(0, 0)
		deltimer(channel_light_timer)
		return
	if(light_range < 6)
		light_range += 1
	xeno_owner.set_light_on(TRUE)
	xeno_owner.set_light_range_power_color(light_range, 4, BOILER_LUMINOSITY_BASE_COLOR)
	channel_light_timer = addtimer(CALLBACK(src, PROC_REF(manage_channel_glow), TRUE), 0.5 SECONDS, TIMER_STOPPABLE)

/datum/action/ability/activable/xeno/smokescreen_spit/ai_should_start_consider()
	return TRUE

/datum/action/ability/activable/xeno/smokescreen_spit/ai_should_use(atom/target)
	if(!iscarbon(target))
		return FALSE
	if(get_dist(target, owner) < 5 || get_dist(target, owner) > 13)
		return FALSE
	if(!can_use_ability(target, override_flags = ABILITY_IGNORE_SELECTED_ABILITY))
		return FALSE
	if(!line_of_sight(owner, target))
		return FALSE
	if(target.get_xeno_hivenumber() == owner.get_xeno_hivenumber())
		return FALSE
	action_activate()
	LAZYINCREMENT(owner.do_actions, target)
	addtimer(CALLBACK(src, PROC_REF(decrease_do_action), target), cast_time)
	return TRUE

///Decrease the do_actions of the owner
/datum/action/ability/activable/xeno/smokescreen_spit/proc/decrease_do_action(atom/target)
	LAZYDECREMENT(owner.do_actions, target)

// ***************************************
// *********** Sizzler Acid dash
// ***************************************
// In the official build this is "/datum/action/ability/activable/xeno/charge/acid_dash". That path is already used by the Praetorian's Acid Dash here, so this one has its own path.
/datum/action/ability/activable/xeno/charge/sizzler_acid_dash
	name = "Acid Dash"
	action_icon_state = "pounce"
	action_icon = 'icons/Xeno/actions/runner.dmi'
	ability_cost = 100
	cooldown_duration = 20 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_ACID_DASH,
	)
	paralyze_duration = 1 SECONDS
	charge_range = BOILER_CHARGEDISTANCE
	/// The maximum amount of times that we can recast this ability.
	var/maximum_recasts = 1
	/// The available amount of times that we can recast this ability.
	var/available_recasts = 1
	/// Have we hit a human with the last ability cast?
	var/recast_prerequisite_met = FALSE
	/// The timer id for the callback that will set the ability on cooldown if recast(s) is not used up in time.
	var/recast_decay_timer_id
	/// Should we do acid_spray_act on those we pass over?
	var/do_acid_spray_act = TRUE
	/// List of pass_flags given by this action.
	var/charge_pass_flags = PASS_LOW_STRUCTURE|PASS_DEFENSIVE_STRUCTURE|PASS_FIRE
	/// The duration in deciseconds in which a trail of opaque gas will last.
	var/gas_trail_duration = 0 SECONDS

/datum/action/ability/activable/xeno/charge/sizzler_acid_dash/New(Target)
	. = ..()
	desc = "Instantly dash for [charge_range] tiles, leaving a trail of acid in your path. If you manage to dash through someone, gain another cast of the ability."

/datum/action/ability/activable/xeno/charge/sizzler_acid_dash/on_cooldown_finish()
	available_recasts = maximum_recasts
	if(recast_decay_timer_id)
		deltimer(recast_decay_timer_id)
		recast_decay_timer_id = null
	recast_prerequisite_met = FALSE
	return ..()

/datum/action/ability/activable/xeno/charge/sizzler_acid_dash/can_use_ability(atom/A, silent, override_flags)
	. = ..()
	if(!.)
		return
	if(!A)
		return FALSE
	if(xeno_owner.xeno_flags & XENO_LEAPING)
		return FALSE
	if(!available_recasts)
		return FALSE

/datum/action/ability/activable/xeno/charge/sizzler_acid_dash/use_ability(atom/A)
	if(recast_prerequisite_met)
		available_recasts = clamp(available_recasts - 1, 0, maximum_recasts)
	xeno_owner.visible_message(span_xenodanger("[xeno_owner] slides towards \the [A]!"), \
		span_xenodanger("We dash towards \the [A], spraying acid down our path!") )
	xeno_owner.emote("roar")
	RegisterSignal(xeno_owner, COMSIG_XENO_OBJ_THROW_HIT, PROC_REF(obj_hit))
	RegisterSignal(xeno_owner, COMSIG_MOVABLE_POST_THROW, PROC_REF(charge_complete))
	RegisterSignal(xeno_owner, COMSIG_XENOMORPH_LEAP_BUMP, PROC_REF(mob_hit))
	RegisterSignal(xeno_owner, COMSIG_MOVABLE_MOVED, PROC_REF(acid_steps)) // We drop acid on every tile we pass through.
	xeno_owner.xeno_flags |= XENO_LEAPING // This has to come before throw_at, which checks impact. So we don't do end-charge specials when thrown.
	xeno_owner.add_pass_flags(charge_pass_flags, type)
	xeno_owner.throw_at(A, charge_range, 2, xeno_owner)
	succeed_activate(available_recasts >= maximum_recasts ? null : 5) // Greatly reduced cost for recasts.

/datum/action/ability/activable/xeno/charge/sizzler_acid_dash/mob_hit(datum/source, mob/living/living_target)
	SIGNAL_HANDLER
	. = TRUE
	if(living_target.stat || isxeno(living_target) || !(iscarbon(living_target))) // We leap past xenos.
		return
	var/mob/living/carbon/carbon_victim = living_target
	to_chat(carbon_victim, span_userdanger("The [xeno_owner] tackles us, sending us behind them!"))
	xeno_owner.visible_message(span_xenodanger("\The [xeno_owner] tackles [carbon_victim], swapping location with them!"), \
		span_xenodanger("We push [carbon_victim] in our acid trail!"), visible_message_flags = COMBAT_MESSAGE)
	carbon_victim.ParalyzeNoChain(paralyze_duration)
	recast_prerequisite_met = TRUE

/datum/action/ability/activable/xeno/charge/sizzler_acid_dash/charge_complete()
	SIGNAL_HANDLER
	. = ..()
	UnregisterSignal(xeno_owner, COMSIG_MOVABLE_MOVED)
	xeno_owner.remove_pass_flags(charge_pass_flags, type)
	if(!available_recasts || !recast_prerequisite_met)
		recast_decayed()
		return
	if(recast_decay_timer_id)
		deltimer(recast_decay_timer_id)
	recast_decay_timer_id = addtimer(CALLBACK(src, PROC_REF(recast_decayed)), 2 SECONDS, TIMER_UNIQUE|TIMER_STOPPABLE)

/// Drops an acid puddle on the current owner's tile which uses the owner caste's acid_spray_damage. Creates opaque gas if gas_trail_duration is set.
/datum/action/ability/activable/xeno/charge/sizzler_acid_dash/proc/acid_steps(atom/A, atom/OldLoc, Dir, Forced)
	SIGNAL_HANDLER
	xenomorph_spray(get_turf(xeno_owner), 5 SECONDS, xeno_owner.xeno_caste.acid_spray_damage, xeno_owner, FALSE, do_acid_spray_act)
	if(!gas_trail_duration || xeno_owner.stat != CONSCIOUS)
		return
	var/datum/effect_system/smoke_spread/xeno/acid/opaque/smoke = new()
	smoke.set_up(0, get_turf(xeno_owner), gas_trail_duration / (2 SECONDS))
	smoke.start()

/// Sets the ability on cooldown and cleans up everything related to recasting.
/datum/action/ability/activable/xeno/charge/sizzler_acid_dash/proc/recast_decayed(atom/A, atom/OldLoc, Dir, Forced)
	if(recast_decay_timer_id)
		deltimer(recast_decay_timer_id)
		recast_decay_timer_id = null
	available_recasts = 0
	recast_prerequisite_met = FALSE
	add_cooldown()

// ***************************************
// *********** High-Pressure Spit
// ***************************************
/datum/action/ability/activable/xeno/high_pressure_spit
	name = "High-Pressure Spit"
	action_icon_state = "acid_lance_glob"
	action_icon = 'icons/Xeno/actions/boiler.dmi'
	desc = "Fire a high pressure glob of acid that knocks back, stuns, and shatters the target."
	ability_cost = 75
	cooldown_duration = 25 SECONDS
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_HIGH_PRESSURE_SPIT,
	)

/datum/action/ability/activable/xeno/high_pressure_spit/use_ability(atom/target)
	var/mob/living/carbon/xenomorph/X = owner

	new /obj/effect/temp_visual/wraith_warp(get_turf(owner))

	if(!do_after(X, 1 SECONDS, NONE, target, BUSY_ICON_DANGER))
		return fail_activate()

	playsound(X.loc, 'sound/voice/alien/hiss2.ogg', 50, 1)

	var/datum/ammo/xeno/acid/heavy/high_pressure_spit/high_pressure_spit = GLOB.ammo_list[/datum/ammo/xeno/acid/heavy/high_pressure_spit]

	var/atom/movable/projectile/newspit = new(get_turf(X))
	newspit.generate_bullet(high_pressure_spit)
	newspit.def_zone = X.get_limbzone_target()

	newspit.fire_at(target, X, X, newspit.ammo.max_range)

	succeed_activate()
	add_cooldown()

/datum/action/ability/activable/xeno/high_pressure_spit/on_cooldown_finish()
	owner.balloon_alert(owner, "high-pressure spit ready")
	owner.playsound_local(owner, 'sound/voice/alien/hiss2.ogg', 25, 0, 1)
	return ..()
