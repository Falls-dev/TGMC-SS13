// Hivelord Enhancement mutations. Ported from the official Shell/Spur/Veil mutations.
// Levels I/II/III use the official values for 1/2/3 structures. See datums/xeno_mutations_leveled.dm.
// Not ported: Hostile Pylon. I could not find Recovery Pylon (place_recovery_pylon) in the provided codebase.

/datum/xeno_mutation/leveled/hivelord
	caste_restrictions = list("hivelord")

// ***************************************
// *********** Hardened Travel
// ***************************************
/datum/xeno_mutation/leveled/hivelord/hardened_travel
	required_ability_types = list(/datum/action/ability/xeno_action/toggle_speed)
	name = "Hardened Travel"
	desc = "Во время Resin Walk вы получаете дополнительную мягкую броню, но плазма не восстанавливается, пока способность включена."
	level_costs = list(5, 10, 15)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/hivelord_hardened_travel,
		/datum/status_effect/xeno_enhancement/hivelord_hardened_travel/two,
		/datum/status_effect/xeno_enhancement/hivelord_hardened_travel/three,
	)
	level_buff_descs = list(
		"Resin Walk: мягкая броня +10, нет регена плазмы.",
		"Resin Walk: мягкая броня +15, нет регена плазмы.",
		"Resin Walk: мягкая броня +20, нет регена плазмы.",
	)

/datum/status_effect/xeno_enhancement/hivelord_hardened_travel
	id = "enhancement_hivelord_hardened_travel"
	/// Per level, the armor Resin Walk grants.
	var/list/armor_per_level = list(10, 15, 20)
	/// The armor that was added to Resin Walk.
	var/applied_armor = 0

/datum/status_effect/xeno_enhancement/hivelord_hardened_travel/two
	level = 2

/datum/status_effect/xeno_enhancement/hivelord_hardened_travel/three
	level = 3

/datum/status_effect/xeno_enhancement/hivelord_hardened_travel/apply_enhancement()
	var/datum/action/ability/xeno_action/toggle_speed/speed_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/toggle_speed]
	if(!speed_ability)
		return FALSE
	applied_armor = get_level_value(armor_per_level)
	speed_ability.set_plasma(FALSE)
	speed_ability.set_armor(speed_ability.armor_amount + applied_armor)
	return TRUE

/datum/status_effect/xeno_enhancement/hivelord_hardened_travel/remove_enhancement()
	var/datum/action/ability/xeno_action/toggle_speed/speed_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/toggle_speed]
	if(speed_ability)
		speed_ability.set_plasma(initial(speed_ability.can_plasma_regenerate))
		speed_ability.set_armor(speed_ability.armor_amount - applied_armor)
	applied_armor = 0

// ***************************************
// *********** Costly Travel
// ***************************************
/datum/xeno_mutation/leveled/hivelord/costly_travel
	required_ability_types = list(/datum/action/ability/xeno_action/toggle_speed)
	name = "Costly Travel"
	desc = "Resin Walk оставляет за вами временные weeds при ходьбе, но за каждый weed платится плазма."
	level_costs = list(5, 7.5, 10)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/hivelord_costly_travel,
		/datum/status_effect/xeno_enhancement/hivelord_costly_travel/two,
		/datum/status_effect/xeno_enhancement/hivelord_costly_travel/three,
	)
	level_buff_descs = list(
		"Каждый weed стоит 75 плазмы.",
		"Каждый weed стоит 50 плазмы.",
		"Каждый weed стоит 25 плазмы.",
	)

/datum/status_effect/xeno_enhancement/hivelord_costly_travel
	id = "enhancement_hivelord_costly_travel"
	/// Per level, the plasma consumed per created weed.
	var/list/plasma_per_level = list(75, 50, 25)
	/// The cost that was added to Resin Walk.
	var/applied_cost = 0

/datum/status_effect/xeno_enhancement/hivelord_costly_travel/two
	level = 2

/datum/status_effect/xeno_enhancement/hivelord_costly_travel/three
	level = 3

/datum/status_effect/xeno_enhancement/hivelord_costly_travel/apply_enhancement()
	var/datum/action/ability/xeno_action/toggle_speed/speed_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/toggle_speed]
	if(!speed_ability)
		return FALSE
	applied_cost = get_level_value(plasma_per_level)
	speed_ability.weeding_cost += applied_cost
	return TRUE

/datum/status_effect/xeno_enhancement/hivelord_costly_travel/remove_enhancement()
	var/datum/action/ability/xeno_action/toggle_speed/speed_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/toggle_speed]
	if(speed_ability)
		speed_ability.weeding_cost -= applied_cost
	applied_cost = 0

// ***************************************
// *********** Rejuvenating Build
// ***************************************
/datum/xeno_mutation/leveled/hivelord/rejuvenating_build
	required_ability_types = list(/datum/action/ability/activable/xeno/secrete_resin/hivelord)
	name = "Rejuvenating Build"
	desc = "Каждое успешное использование Secrete Resin лечит вас на процент от максимального здоровья."
	level_costs = list(5, 10, 15)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/hivelord_rejuvenating_build,
		/datum/status_effect/xeno_enhancement/hivelord_rejuvenating_build/two,
		/datum/status_effect/xeno_enhancement/hivelord_rejuvenating_build/three,
	)
	level_buff_descs = list(
		"Secrete Resin лечит 1% макс. здоровья.",
		"Secrete Resin лечит 2% макс. здоровья.",
		"Secrete Resin лечит 3% макс. здоровья.",
	)

/datum/status_effect/xeno_enhancement/hivelord_rejuvenating_build
	id = "enhancement_hivelord_rejuvenating_build"
	/// Per level, the fraction of maximum health healed.
	var/list/heal_per_level = list(0.01, 0.02, 0.03)
	/// The amount that was added to Secrete Resin.
	var/applied_heal = 0

/datum/status_effect/xeno_enhancement/hivelord_rejuvenating_build/two
	level = 2

/datum/status_effect/xeno_enhancement/hivelord_rejuvenating_build/three
	level = 3

/datum/status_effect/xeno_enhancement/hivelord_rejuvenating_build/apply_enhancement()
	var/datum/action/ability/activable/xeno/secrete_resin/hivelord/resin_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/secrete_resin/hivelord]
	if(!resin_ability)
		return FALSE
	applied_heal = get_level_value(heal_per_level)
	resin_ability.heal_percentage += applied_heal
	return TRUE

/datum/status_effect/xeno_enhancement/hivelord_rejuvenating_build/remove_enhancement()
	var/datum/action/ability/activable/xeno/secrete_resin/hivelord/resin_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/secrete_resin/hivelord]
	if(resin_ability)
		resin_ability.heal_percentage -= applied_heal
	applied_heal = 0

// ***************************************
// *********** Combustive Jelly
// ***************************************
/datum/xeno_mutation/leveled/hivelord/combustive_jelly
	name = "Combustive Jelly"
	desc = "Вы теряете Place Resin Jelly pod. Брошенный Resin Jelly больше не защищает от огня: он создаёт липкую смолу 3x3 на 15 секунд, а при прямом попадании в человека накладывает стаггер."
	level_costs = list(7.5, 12.5, 17.5)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/hivelord_combustive_jelly,
		/datum/status_effect/xeno_enhancement/hivelord_combustive_jelly/two,
		/datum/status_effect/xeno_enhancement/hivelord_combustive_jelly/three,
	)
	level_buff_descs = list(
		"Липкая смола 3x3. Стаггер при попадании 2 сек.",
		"Липкая смола 3x3. Стаггер при попадании 4 сек.",
		"Липкая смола 3x3. Стаггер при попадании 6 сек.",
	)

/datum/status_effect/xeno_enhancement/hivelord_combustive_jelly
	id = "enhancement_hivelord_combustive_jelly"
	/// Per level, the stagger duration in deciseconds on a direct hit on a human.
	var/list/stagger_per_level = list(2 SECONDS, 4 SECONDS, 6 SECONDS)

/datum/status_effect/xeno_enhancement/hivelord_combustive_jelly/two
	level = 2

/datum/status_effect/xeno_enhancement/hivelord_combustive_jelly/three
	level = 3

/datum/status_effect/xeno_enhancement/hivelord_combustive_jelly/apply_enhancement()
	var/datum/action/ability/xeno_action/place_jelly_pod/pod_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/place_jelly_pod]
	if(pod_ability)
		pod_ability.remove_action(xenomorph_owner)
	xenomorph_owner.jelly_combustive_stagger = get_level_value(stagger_per_level)
	return TRUE

/datum/status_effect/xeno_enhancement/hivelord_combustive_jelly/remove_enhancement()
	xenomorph_owner.jelly_combustive_stagger = 0
	if(xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/place_jelly_pod])
		return
	var/datum/action/ability/xeno_action/place_jelly_pod/pod_ability = new()
	pod_ability.give_action(xenomorph_owner)

// ***************************************
// *********** Resin Splash
// ***************************************
/datum/xeno_mutation/leveled/hivelord/resin_splash
	name = "Resin Splash"
	desc = "Когда вы бьёте человека, автоматически тратится плазма и в него летит липкая смоляная граната. Срабатывает не чаще раза в 8 секунд."
	level_costs = list(7.5, 12.5, 17.5)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/hivelord_resin_splash,
		/datum/status_effect/xeno_enhancement/hivelord_resin_splash/two,
		/datum/status_effect/xeno_enhancement/hivelord_resin_splash/three,
	)
	level_buff_descs = list(
		"Стоит 600 плазмы за гранату.",
		"Стоит 400 плазмы за гранату.",
		"Стоит 200 плазмы за гранату.",
	)

/datum/status_effect/xeno_enhancement/hivelord_resin_splash
	id = "enhancement_hivelord_resin_splash"
	/// Per level, the plasma consumed per grenade.
	var/list/plasma_per_level = list(600, 400, 200)
	/// Used to determine if it is ready to use or not.
	COOLDOWN_DECLARE(grenade_cooldown)

/datum/status_effect/xeno_enhancement/hivelord_resin_splash/two
	level = 2

/datum/status_effect/xeno_enhancement/hivelord_resin_splash/three
	level = 3

/datum/status_effect/xeno_enhancement/hivelord_resin_splash/apply_enhancement()
	RegisterSignal(xenomorph_owner, COMSIG_XENOMORPH_ATTACK_HUMAN, PROC_REF(on_attack_human))
	return TRUE

/datum/status_effect/xeno_enhancement/hivelord_resin_splash/remove_enhancement()
	UnregisterSignal(xenomorph_owner, COMSIG_XENOMORPH_ATTACK_HUMAN)

/datum/status_effect/xeno_enhancement/hivelord_resin_splash/proc/on_attack_human(datum/source, mob/living/carbon/human/attacked_human)
	SIGNAL_HANDLER
	if(!COOLDOWN_FINISHED(src, grenade_cooldown))
		return
	var/required_plasma = get_level_value(plasma_per_level)
	if(xenomorph_owner.plasma_stored < required_plasma)
		return
	COOLDOWN_START(src, grenade_cooldown, 8 SECONDS)
	xenomorph_owner.use_plasma(required_plasma)
	var/obj/item/explosive/grenade/sticky/resin/sticky_grenade = new(xenomorph_owner.loc)
	sticky_grenade.activate(xenomorph_owner)
	sticky_grenade.throw_at(attacked_human, 2, 5, xenomorph_owner)

/// Sticky grenade thrown by Resin Splash. Creates thin sticky resin in a 3x3 when it primes.
/obj/item/explosive/grenade/sticky/resin
	name = "\improper resin grenade"
	desc = "A lump of compressed sticky resin."
	greyscale_colors = "#42A500"
	greyscale_config = /datum/greyscale_config/xenogrenade
	self_sticky = TRUE
	arm_sound = 'sound/voice/alien/yell_alt.ogg'
	overlay_type = null

/obj/item/explosive/grenade/sticky/resin/update_overlays()
	. = ..()
	if(active)
		. += image('icons/obj/items/grenade.dmi', "xenonade_active")

/obj/item/explosive/grenade/sticky/resin/prime()
	for(var/turf/sticky_tile AS in RANGE_TURFS(1, loc))
		if(isclosedturf(sticky_tile) || (locate(/obj/alien/resin/sticky) in sticky_tile))
			continue
		var/obj/alien/resin/sticky/thin/temporary_resin = new(sticky_tile)
		QDEL_IN(temporary_resin, 15 SECONDS)
	playsound(loc, SFX_ALIEN_RESIN_BUILD, 50, 1)
	if(stuck_to)
		clean_refs()
	qdel(src)

// ***************************************
// *********** Protective Light
// ***************************************
/datum/xeno_mutation/leveled/hivelord/protective_light
	required_ability_types = list(/datum/action/ability/activable/xeno/healing_infusion)
	name = "Protective Light"
	desc = "Healing Infusion дополнительно накладывает эффект resin jelly (защита от огня), но стоит больше плазмы."
	level_costs = list(5, 10, 15)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/hivelord_protective_light,
		/datum/status_effect/xeno_enhancement/hivelord_protective_light/two,
		/datum/status_effect/xeno_enhancement/hivelord_protective_light/three,
	)
	level_buff_descs = list(
		"Цена плазмы Healing Infusion x2.",
		"Цена плазмы Healing Infusion x1.75.",
		"Цена плазмы Healing Infusion x1.5.",
	)

/datum/status_effect/xeno_enhancement/hivelord_protective_light
	id = "enhancement_hivelord_protective_light"
	/// Per level, the multiplier of the initial cost that is added to the cost of Healing Infusion.
	var/list/multiplier_per_level = list(1, 0.75, 0.5)
	/// The cost that was added to Healing Infusion.
	var/applied_cost = 0

/datum/status_effect/xeno_enhancement/hivelord_protective_light/two
	level = 2

/datum/status_effect/xeno_enhancement/hivelord_protective_light/three
	level = 3

/datum/status_effect/xeno_enhancement/hivelord_protective_light/apply_enhancement()
	var/datum/action/ability/activable/xeno/healing_infusion/healing_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/healing_infusion]
	if(!healing_ability)
		return FALSE
	applied_cost = initial(healing_ability.ability_cost) * get_level_value(multiplier_per_level)
	healing_ability.apply_resin_jelly = TRUE
	healing_ability.ability_cost += applied_cost
	return TRUE

/datum/status_effect/xeno_enhancement/hivelord_protective_light/remove_enhancement()
	var/datum/action/ability/activable/xeno/healing_infusion/healing_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/healing_infusion]
	if(healing_ability)
		healing_ability.apply_resin_jelly = initial(healing_ability.apply_resin_jelly)
		healing_ability.ability_cost -= applied_cost
	applied_cost = 0

// ***************************************
// *********** Forward Light
// ***************************************
/datum/xeno_mutation/leveled/hivelord/forward_light
	required_ability_types = list(/datum/action/ability/activable/xeno/healing_infusion)
	name = "Forward Light"
	desc = "Healing Infusion действует короче, но лечит даже вне weeds (innate healing)."
	level_costs = list(5, 10, 15)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/hivelord_forward_light,
		/datum/status_effect/xeno_enhancement/hivelord_forward_light/two,
		/datum/status_effect/xeno_enhancement/hivelord_forward_light/three,
	)
	level_buff_descs = list(
		"Длительность 50% от обычной.",
		"Длительность 60% от обычной.",
		"Длительность 70% от обычной.",
	)

/datum/status_effect/xeno_enhancement/hivelord_forward_light
	id = "enhancement_hivelord_forward_light"
	/// Per level, the multiplier of the duration and the amount of healing ticks.
	var/list/multiplier_per_level = list(0.5, 0.6, 0.7)
	/// The amount that was subtracted from the status multiplier of Healing Infusion.
	var/applied_reduction = 0

/datum/status_effect/xeno_enhancement/hivelord_forward_light/two
	level = 2

/datum/status_effect/xeno_enhancement/hivelord_forward_light/three
	level = 3

/datum/status_effect/xeno_enhancement/hivelord_forward_light/apply_enhancement()
	var/datum/action/ability/activable/xeno/healing_infusion/healing_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/healing_infusion]
	if(!healing_ability)
		return FALSE
	applied_reduction = 1 - get_level_value(multiplier_per_level)
	healing_ability.innate_healing = TRUE
	healing_ability.status_multiplier -= applied_reduction
	return TRUE

/datum/status_effect/xeno_enhancement/hivelord_forward_light/remove_enhancement()
	var/datum/action/ability/activable/xeno/healing_infusion/healing_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/healing_infusion]
	if(healing_ability)
		healing_ability.innate_healing = initial(healing_ability.innate_healing)
		healing_ability.status_multiplier += applied_reduction
	applied_reduction = 0

// ***************************************
// *********** Weed Specialist
// ***************************************
/datum/xeno_mutation/leveled/hivelord/weed_specialist
	required_ability_types = list(/datum/action/ability/activable/xeno/plant_weeds)
	name = "Weed Specialist"
	desc = "Plant Weeds стоит дешевле, но вы больше не можете сажать обычные weeds (только специальные виды)."
	level_costs = list(5, 7.5, 10)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/hivelord_weed_specialist,
		/datum/status_effect/xeno_enhancement/hivelord_weed_specialist/two,
		/datum/status_effect/xeno_enhancement/hivelord_weed_specialist/three,
	)
	level_buff_descs = list(
		"Plant Weeds стоит 80% от обычного.",
		"Plant Weeds стоит 65% от обычного.",
		"Plant Weeds стоит 50% от обычного.",
	)

/datum/status_effect/xeno_enhancement/hivelord_weed_specialist
	id = "enhancement_hivelord_weed_specialist"
	/// Per level, the multiplier added to the cost multiplier of Plant Weeds.
	var/list/multiplier_per_level = list(-0.2, -0.35, -0.5)
	/// The multiplier that was added to Plant Weeds.
	var/applied_multiplier = 0
	/// TRUE if this effect removed the basic weeds from the selectable weeds.
	var/removed_basic_weeds = FALSE

/datum/status_effect/xeno_enhancement/hivelord_weed_specialist/two
	level = 2

/datum/status_effect/xeno_enhancement/hivelord_weed_specialist/three
	level = 3

/datum/status_effect/xeno_enhancement/hivelord_weed_specialist/apply_enhancement()
	var/datum/action/ability/activable/xeno/plant_weeds/weed_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/plant_weeds]
	if(!weed_ability)
		return FALSE
	if(/obj/alien/weeds/node in weed_ability.selectable_weed_typepaths)
		weed_ability.selectable_weed_typepaths -= /obj/alien/weeds/node
		removed_basic_weeds = TRUE
	if(weed_ability.weed_type == /obj/alien/weeds/node && length(weed_ability.selectable_weed_typepaths))
		weed_ability.weed_type = weed_ability.selectable_weed_typepaths[1]
	applied_multiplier = get_level_value(multiplier_per_level)
	weed_ability.cost_multiplier += applied_multiplier
	weed_ability.update_ability_cost()
	weed_ability.update_button_icon()
	return TRUE

/datum/status_effect/xeno_enhancement/hivelord_weed_specialist/remove_enhancement()
	var/datum/action/ability/activable/xeno/plant_weeds/weed_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/plant_weeds]
	if(weed_ability)
		if(removed_basic_weeds && !(/obj/alien/weeds/node in weed_ability.selectable_weed_typepaths))
			weed_ability.selectable_weed_typepaths += /obj/alien/weeds/node
		weed_ability.cost_multiplier -= applied_multiplier
		weed_ability.update_ability_cost()
		weed_ability.update_button_icon()
	applied_multiplier = 0
	removed_basic_weeds = FALSE
