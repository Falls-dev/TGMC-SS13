/mob/living/carbon/xenomorph/dragon
	caste_base_type = /datum/xeno_caste/dragon
	name = "Dragon"
	desc = "A massive, ancient beast with scales that shimmer like polished armor. The fiercest and most formidable creature."
	icon = 'icons/Xeno/castes/dragon/dragon.dmi'
	effects_icon = 'icons/Xeno/castes/dragon/dragon.dmi' // Позже закинуть в отдельный .dmi
	icon_state = "Dragon Walking"
	attacktext = "bites"
	friendly = "nuzzles"
	health = 850
	maxHealth = 850
	plasma_stored = 0
	pixel_x = -48
	mob_size = MOB_SIZE_BIG
	drag_delay = 6
	tier = XENO_TIER_FOUR
	upgrade = XENO_UPGRADE_NORMAL
	bubble_icon = "alienroyal"
	inherent_verbs = list(
		/mob/living/carbon/xenomorph/proc/hijack,
	)
	attack_effect = list("dragonslash","dragonslash2")

/mob/living/carbon/xenomorph/dragon/Initialize(mapload)
	. = ..()
	playsound(loc, 'sound/voice/alien/xenos_roaring.ogg', 75, 0)

/mob/living/carbon/xenomorph/dragon/death_cry()
	playsound(loc, 'sound/voice/alien/king_died.ogg', 75, 0)

/mob/living/carbon/xenomorph/dragon/throw_at(atom/target, range, speed = 5, thrower, spin, flying = FALSE, targetted_throw = TRUE)
	return FALSE

/mob/living/carbon/xenomorph/dragon/handle_special_state()
	if(!(status_flags & INCORPOREAL))
		return FALSE
	var/datum/action/ability/activable/xeno/fly/fly_ability = actions_by_path[/datum/action/ability/activable/xeno/fly]
	if(!fly_ability || fly_ability.performing_landing_animation || COOLDOWN_TIMELEFT(fly_ability, animation_cooldown))
		return FALSE
	icon_state = "dragon_marker"
	return TRUE

/// If they have plasma, reduces their damage accordingly by up to 50%. Ratio is 4 plasma per 1 damage.
/mob/living/carbon/xenomorph/dragon/apply_damage(damage = 0, damagetype = BRUTE, def_zone, blocked = 0, sharp = FALSE, edge = FALSE, updating_health = FALSE, penetration, mob/living/attacker)
	if((status_flags & GODMODE) || damage <= 0)
		return FALSE
	if(damagetype != BRUTE && damagetype != BURN)
		return FALSE
	if(stat != DEAD && plasma_stored)
		var/damage_reduction = min(damage / 2, plasma_stored / 5)
		use_plasma(ROUND_UP(damage_reduction * 5))
		damage -= damage_reduction
	return ..()

/mob/living/carbon/xenomorph/dragon/primordial
	upgrade = XENO_UPGRADE_PRIMO

// mutations_dragon.dm //
/*
////////////////////////////////АХТУНГ////////////////////////////////
//////////////////В ПРОЦЕССЕ ПЕРЕПИЛА ПОД НАШ БИЛД////////////////////
//////////////////////ВО ВРЕМЯ ПЕРЕНОСА МУТАЦИИ///////////////////////
//////////////////////////НЕ БУДУТ РАБОТАТЬ///////////////////////////
//////////////////////////////////////////////////////////////////////
//*********************//
//        Shell        //
//*********************//
/datum/mutation_upgrade/shell/regenerative_armor
	name = "Regenerative Armor"
	desc = "При пассивной регенерации здоровья, вы также восстанавливаете 2.5/5/7.5% от вашего максимального запаса плазмы. Это масштабируется с силой регенерации."
	/// For each structure, the percentage (0-1) of the owner's maximum plasma to regenerate.
	var/percentage_per_structure = 0.025

/datum/mutation_upgrade/shell/regenerative_armor/get_desc_for_alert(new_amount)
	if(!new_amount)
		return ..()
	return "Каждый раз, когда вы восстанавливаете здоровье, вы также будете получать [PERCENT(get_percentage(new_amount))]% от вашего максимального запаса плазмы. Это масштабируется с силой регенерации."

/datum/mutation_upgrade/shell/regenerative_armor/on_mutation_enabled()
	RegisterSignal(xenomorph_owner, COMSIG_XENOMORPH_HEALTH_REGEN, PROC_REF(on_health_regeneration))
	return ..()

/datum/mutation_upgrade/shell/regenerative_armor/on_mutation_disabled()
	UnregisterSignal(xenomorph_owner, list(COMSIG_XENOMORPH_HEALTH_REGEN))
	return ..()

/// Restores a percentage of the owner's plasma based on their maximum plasma then scaling with the amount of structure and regeneration power.
/datum/mutation_upgrade/shell/regenerative_armor/proc/on_health_regeneration(datum/source, heal_data, seconds_per_tick)
	SIGNAL_HANDLER
	if(xenomorph_owner.regen_power <= 0)
		return
	xenomorph_owner.gain_plasma(xenomorph_owner.xeno_caste.plasma_max * get_percentage(get_total_structures()) * (seconds_per_tick * XENO_PER_SECOND_LIFE_MOD) * xenomorph_owner.regen_power)

/// Returns the percentage (0-1) of the owner's maximum plasma to regenerate.
/datum/mutation_upgrade/shell/regenerative_armor/proc/get_percentage(structure_count)
	return percentage_per_structure * structure_count

//*********************//
//         Spur        //
//*********************//
/datum/mutation_upgrade/spur/breath_of_variety
	name = "Breath of Variety"
	desc = "Дыхание дракона может переключаться между дополнительными типами огня, чтобы заменить его различными эффектами: дробящий или плавящий кислотой. Время восстановления Дыхания дракона устанавливается на 150/125/100% от его первоначального времени восстановления."
	/// For the first structure, the multiplier of Dragon Breath's initial cooldown duration to add to the ability.
	var/multiplier_initial = 0.75
	/// For each structure, the multiplier of Dragon Breath's initial cooldown duration to add to the ability.
	var/multiplier_per_structure = -0.25

/datum/mutation_upgrade/spur/breath_of_variety/get_desc_for_alert(new_amount)
	if(!new_amount)
		return ..()
	return "Дыхание дракона может переключаться между дополнительными типами огня, чтобы заменить его различными эффектами: дробящий или плавящий кислотой. Время восстановления Дыхания дракона устанавливается на 150/125/100% [PERCENT((1 + get_multiplier(new_amount)))] от его первоначального времени восстановления."

/datum/mutation_upgrade/spur/breath_of_variety/on_mutation_enabled()
	. = ..()
	var/datum/action/ability/activable/xeno/backhand/dragon_breath/breath_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/backhand/dragon_breath]
	if(!breath_ability)
		return
	breath_ability.cooldown_duration += initial(breath_ability.cooldown_duration) * get_multiplier(0)
	breath_ability.selectable_fire_images_list[DRAGON_BREATH_SHATTERING] = image('icons/effects/fire.dmi', icon_state = "violet_3")
	breath_ability.selectable_fire_images_list[DRAGON_BREATH_MELTING_ACID] = image('icons/effects/fire.dmi', icon_state = "green_3")

/datum/mutation_upgrade/spur/breath_of_variety/on_mutation_disabled()
	. = ..()
	var/datum/action/ability/activable/xeno/backhand/dragon_breath/breath_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/backhand/dragon_breath]
	if(!breath_ability)
		return
	breath_ability.cooldown_duration -= initial(breath_ability.cooldown_duration) * get_multiplier(0)
	breath_ability.selectable_fire_images_list[DRAGON_BREATH_SHATTERING] = null
	breath_ability.selectable_fire_images_list[DRAGON_BREATH_MELTING_ACID] = null

/datum/mutation_upgrade/spur/breath_of_variety/on_structure_update(previous_amount, new_amount)
	. = ..()
	var/datum/action/ability/activable/xeno/backhand/dragon_breath/breath_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/backhand/dragon_breath]
	if(!breath_ability)
		return
	breath_ability.cooldown_duration += initial(breath_ability.cooldown_duration) * get_multiplier(new_amount - previous_amount, FALSE)

/// Returns the multiplier of Dragon Breath's initial cooldown duration to add to the ability.
/datum/mutation_upgrade/spur/breath_of_variety/proc/get_multiplier(structure_count, include_initial = TRUE)
	return (include_initial ? multiplier_initial : 0) + (multiplier_per_structure * structure_count)

//*********************//
//         Veil        //
//*********************//
/datum/mutation_upgrade/veil/benevolence
	name = "Benevolence"
	desc = "Вы испускаете все типы феромонов с силой 2/2.5/3 в радиусе 14/15/16."
	/// For the first structure, the amount of power to increase the pheromones by.
	var/power_increase_initial = 1.5
	/// For each structure, the amount of power to increase the pheromones by.
	var/power_increase_per_structure = 0.5
	/// The frenzy aura if it exists.
	var/datum/aura_bearer/frenzy_aura
	/// The warding aura if it exists.
	var/datum/aura_bearer/warding_aura
	/// The recovery aura if it exists.
	var/datum/aura_bearer/recovery_aura

/datum/mutation_upgrade/veil/benevolence/get_desc_for_alert(new_amount)
	if(!new_amount)
		return ..()
	return "Вы испускаете все типы феромонов с силой [get_power(new_amount)] в радиусе [get_radius(new_amount)]."

/datum/mutation_upgrade/veil/benevolence/on_structure_update(previous_amount, new_amount)
	. = ..()
	if(frenzy_aura)
		QDEL_NULL(frenzy_aura)
	if(warding_aura)
		QDEL_NULL(warding_aura)
	if(recovery_aura)
		QDEL_NULL(recovery_aura)
	if(!new_amount)
		return
	frenzy_aura = SSaura.add_emitter(xenomorph_owner, AURA_XENO_FRENZY, get_radius(new_amount), get_power(new_amount), -1, FACTION_XENO, xenomorph_owner.hivenumber)
	warding_aura = SSaura.add_emitter(xenomorph_owner, AURA_XENO_WARDING, get_radius(new_amount), get_power(new_amount), -1, FACTION_XENO, xenomorph_owner.hivenumber)
	recovery_aura = SSaura.add_emitter(xenomorph_owner, AURA_XENO_RECOVERY, get_radius(new_amount), get_power(new_amount), -1, FACTION_XENO, xenomorph_owner.hivenumber)

/// Returns the power of the aura(s).
/datum/mutation_upgrade/veil/benevolence/proc/get_power(structure_count)
	return power_increase_initial + (power_increase_per_structure * structure_count)

/// Returns the radius of the aura(s).
/datum/mutation_upgrade/veil/benevolence/proc/get_radius(power)
	return (6 + power) * 2
*/
