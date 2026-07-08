//*********************//
//      DEFINES        //
//*********************//
#define STATUS_EFFECT_HARDENED_TRAVEL /datum/status_effect/hivelord/hardened_travel
#define STATUS_EFFECT_COSTLY_TRAVEL /datum/status_effect/hivelord/costly_travel
#define STATUS_EFFECT_REJUVENATING_BUILD /datum/status_effect/hivelord/rejuvenating_build
#define STATUS_EFFECT_COMBUSTIVE_JELLY /datum/status_effect/hivelord/combustive_jelly
#define STATUS_EFFECT_RESIN_SPLASH /datum/status_effect/hivelord/resin_splash
#define STATUS_EFFECT_PROTECTIVE_LIGHT /datum/status_effect/hivelord/protective_light
#define STATUS_EFFECT_FORWARD_LIGHT /datum/status_effect/hivelord/forward_light
#define STATUS_EFFECT_WEED_SPECIALIST /datum/status_effect/hivelord/weed_specialist

//*********************//
//    BASE CLASSES     //
//*********************//
/datum/xeno_mutation/hivelord
	category = "Enhancement"
	caste_restrictions = list("hivelord")

/datum/status_effect/hivelord
	duration = -1
	status_type = STATUS_EFFECT_UNIQUE
	var/mob/living/carbon/xenomorph/xenomorph_owner

//*********************//
//    Hardened Travel  //
//*********************//
/datum/xeno_mutation/hivelord/hardened_travel
	name = "Hardened Travel"
	desc = "Resin Walk даёт 15 брони во всех категориях, но отключает регенерацию плазмы."
	cost = 7.5
	icon_state = "xenobuff_generic"
	tier = 1
	status_effect_type = STATUS_EFFECT_HARDENED_TRAVEL
	buff_desc = "+15 брони при Resin Walk, нет регена плазмы."

/atom/movable/screen/alert/status_effect/hivelord/hardened_travel
	name = "Hardened Travel"
	desc = "Resin Walk даёт 15 брони во всех категориях, но отключает регенерацию плазмы."
	icon_state = "xenobuff_attack"

/datum/status_effect/hivelord/hardened_travel
	id = "upgrade_hardened_travel"
	alert_type = /atom/movable/screen/alert/status_effect/hivelord/hardened_travel
	var/armor_amount = 15

/datum/status_effect/hivelord/hardened_travel/on_apply()
	xenomorph_owner = owner
	var/datum/action/ability/xeno_action/toggle_speed/speed_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/toggle_speed]
	if(!speed_ability)
		return
	speed_ability.set_plasma(FALSE)
	speed_ability.set_armor(speed_ability.armor_amount + armor_amount)
	return TRUE

/datum/status_effect/hivelord/hardened_travel/on_remove()
	var/datum/action/ability/xeno_action/toggle_speed/speed_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/toggle_speed]
	if(!speed_ability)
		return ..()
	speed_ability.set_plasma(initial(speed_ability.can_plasma_regenerate))
	speed_ability.set_armor(speed_ability.armor_amount - armor_amount)
	return ..()

//*********************//
//    Costly Travel    //
//*********************//
/datum/xeno_mutation/hivelord/costly_travel
	name = "Costly Travel"
	desc = "Resin Walk оставляет за собой временные сорняки, но каждый созданный тайл потребляет 75 плазмы."
	cost = 7.5
	icon_state = "xenobuff_generic"
	tier = 1
	status_effect_type = STATUS_EFFECT_COSTLY_TRAVEL
	buff_desc = "Resin Walk создаёт сорняки за 75 плазмы за тайл."

/atom/movable/screen/alert/status_effect/hivelord/costly_travel
	name = "Costly Travel"
	desc = "Resin Walk оставляет за собой временные сорняки, но каждый созданный тайл потребляет 75 плазмы."
	icon_state = "xenobuff_attack"

/datum/status_effect/hivelord/costly_travel
	id = "upgrade_costly_travel"
	alert_type = /atom/movable/screen/alert/status_effect/hivelord/costly_travel
	var/weeding_plasma_cost = 75

/datum/status_effect/hivelord/costly_travel/on_apply()
	xenomorph_owner = owner
	var/datum/action/ability/xeno_action/toggle_speed/speed_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/toggle_speed]
	if(!speed_ability)
		return
	speed_ability.weeding_cost += weeding_plasma_cost
	return TRUE

/datum/status_effect/hivelord/costly_travel/on_remove()
	var/datum/action/ability/xeno_action/toggle_speed/speed_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/toggle_speed]
	if(!speed_ability)
		return ..()
	speed_ability.weeding_cost -= weeding_plasma_cost
	return ..()

//*********************//
//  Rejuvenating Build //
//*********************//
/datum/xeno_mutation/hivelord/rejuvenating_build
	name = "Rejuvenating Build"
	desc = "Использование Secrete Resin восстанавливает 2% от максимального здоровья."
	cost = 7.5
	icon_state = "xenobuff_generic"
	tier = 1
	status_effect_type = STATUS_EFFECT_REJUVENATING_BUILD
	buff_desc = "+2% макс. здоровья при постройке через Secrete Resin."

/atom/movable/screen/alert/status_effect/hivelord/rejuvenating_build
	name = "Rejuvenating Build"
	desc = "Использование Secrete Resin восстанавливает 2% от максимального здоровья."
	icon_state = "xenobuff_attack"

/datum/status_effect/hivelord/rejuvenating_build
	id = "upgrade_rejuvenating_build"
	alert_type = /atom/movable/screen/alert/status_effect/hivelord/rejuvenating_build
	var/heal_percentage = 0.02

/datum/status_effect/hivelord/rejuvenating_build/on_apply()
	xenomorph_owner = owner
	var/datum/action/ability/activable/xeno/secrete_resin/hivelord/resin_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/secrete_resin/hivelord]
	if(!resin_ability)
		resin_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/secrete_resin]
	if(!resin_ability)
		return
	resin_ability.heal_percentage += heal_percentage
	return TRUE

/datum/status_effect/hivelord/rejuvenating_build/on_remove()
	var/datum/action/ability/activable/xeno/secrete_resin/hivelord/resin_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/secrete_resin/hivelord]
	if(!resin_ability)
		resin_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/secrete_resin]
	if(!resin_ability)
		return ..()
	resin_ability.heal_percentage -= heal_percentage
	return ..()

//*********************//
//  Combustive Jelly   //
//*********************//
/datum/xeno_mutation/hivelord/combustive_jelly
	name = "Combustive Jelly"
	desc = "Вы теряете способность устанавливать капсулы со смоляным желе. Бросаемое желе больше не даёт иммунитет к огню, но создаёт липкую смолу 3x3 и стаггерит людей при попадании на 6 секунд."
	cost = 10
	icon_state = "xenobuff_generic"
	tier = 1
	status_effect_type = STATUS_EFFECT_COMBUSTIVE_JELLY
	buff_desc = "Нет капсул желе. Бросок создаёт смолу 3x3 и стаггерит на 6с."

/atom/movable/screen/alert/status_effect/hivelord/combustive_jelly
	name = "Combustive Jelly"
	desc = "Бросаемое желе создаёт липкую смолу 3x3 и стаггерит людей при попадании на 6 секунд."
	icon_state = "xenobuff_attack"

/datum/status_effect/hivelord/combustive_jelly
	id = "upgrade_combustive_jelly"
	alert_type = /atom/movable/screen/alert/status_effect/hivelord/combustive_jelly
	var/stagger_duration = 6 SECONDS

/datum/status_effect/hivelord/combustive_jelly/on_apply()
	xenomorph_owner = owner
	var/datum/action/ability/xeno_action/place_jelly_pod/pod_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/place_jelly_pod]
	if(pod_ability)
		pod_ability.remove_action(xenomorph_owner)
	RegisterSignals(xenomorph_owner, list(COMSIG_MOB_DROPPING_ITEM, COMSIG_LIVING_PICKED_UP_ITEM), PROC_REF(update_resin_jelly))
	update_resin_jelly(null, xenomorph_owner.get_active_held_item())
	update_resin_jelly(null, xenomorph_owner.get_inactive_held_item())
	return TRUE

/datum/status_effect/hivelord/combustive_jelly/on_remove()
	var/datum/action/ability/xeno_action/place_jelly_pod/pod_ability = new()
	pod_ability.give_action(xenomorph_owner)
	UnregisterSignal(xenomorph_owner, list(COMSIG_MOB_DROPPING_ITEM, COMSIG_LIVING_PICKED_UP_ITEM))
	return ..()

/datum/status_effect/hivelord/combustive_jelly/proc/update_resin_jelly(datum/source, obj/item/item_in_question)
	SIGNAL_HANDLER
	if(!istype(item_in_question, /obj/item/resin_jelly))
		return
	var/obj/item/resin_jelly/jelly_item = item_in_question
	jelly_item.combustive_duration = initial(jelly_item.combustive_duration) + stagger_duration

//*********************//
//    Resin Splash     //
//*********************//
/datum/xeno_mutation/hivelord/resin_splash
	name = "Resin Splash"
	desc = "При ударе человека тратится 400 плазмы, чтобы метнуть в него липкую гранату. Срабатывает не чаще раза в 8 секунд."
	cost = 10
	icon_state = "xenobuff_generic"
	tier = 1
	status_effect_type = STATUS_EFFECT_RESIN_SPLASH
	buff_desc = "Удар по человеку кидает липкую гранату (400 плазмы, КД 8с)."

/atom/movable/screen/alert/status_effect/hivelord/resin_splash
	name = "Resin Splash"
	desc = "При ударе человека тратится 400 плазмы, чтобы метнуть в него липкую гранату."
	icon_state = "xenobuff_attack"

/datum/status_effect/hivelord/resin_splash
	id = "upgrade_resin_splash"
	alert_type = /atom/movable/screen/alert/status_effect/hivelord/resin_splash
	var/plasma_cost = 400
	COOLDOWN_DECLARE(grenade_cooldown)

/datum/status_effect/hivelord/resin_splash/on_apply()
	xenomorph_owner = owner
	RegisterSignal(xenomorph_owner, COMSIG_XENOMORPH_ATTACK_HUMAN, PROC_REF(on_attack_human))
	return TRUE

/datum/status_effect/hivelord/resin_splash/on_remove()
	UnregisterSignal(xenomorph_owner, COMSIG_XENOMORPH_ATTACK_HUMAN)
	return ..()

/datum/status_effect/hivelord/resin_splash/proc/on_attack_human(datum/source, mob/living/carbon/human/attacked_human)
	SIGNAL_HANDLER
	if(!COOLDOWN_FINISHED(src, grenade_cooldown))
		return
	if(xenomorph_owner.plasma_stored < plasma_cost)
		return
	COOLDOWN_START(src, grenade_cooldown, 8 SECONDS)
	xenomorph_owner.use_plasma(plasma_cost)
	var/obj/item/explosive/grenade/sticky/xeno/sticky_grenade = new(xenomorph_owner.loc)
	sticky_grenade.activate(xenomorph_owner)
	sticky_grenade.throw_at(attacked_human, 2, 5, xenomorph_owner)

//*********************//
//    Protective Light //
//*********************//
/datum/xeno_mutation/hivelord/protective_light
	name = "Protective Light"
	desc = "Healing Infusion накладывает эффект смоляного желе (Resin Jelly) на 15 секунд. Стоимость способности увеличена в 1.5 раза. КОНФЛИКТУЕТ С Forward Light."
	cost = 7.5
	icon_state = "xenobuff_generic"
	tier = 1
	status_effect_type = STATUS_EFFECT_PROTECTIVE_LIGHT
	conflicting_mutation_types = list(STATUS_EFFECT_FORWARD_LIGHT)
	buff_desc = "Healing Infusion накладывает Resin Jelly на 15с, стоимость +50%. (Конфликтует с Forward Light)"

/atom/movable/screen/alert/status_effect/hivelord/protective_light
	name = "Protective Light"
	desc = "Healing Infusion накладывает эффект смоляного желе (Resin Jelly) на 15 секунд. Стоимость способности увеличена в 1.5 раза. КОНФЛИКТУЕТ С Forward Light."
	icon_state = "xenobuff_attack"

/datum/status_effect/hivelord/protective_light
	id = "upgrade_protective_light"
	alert_type = /atom/movable/screen/alert/status_effect/hivelord/protective_light
	var/resin_jelly_length = 15 SECONDS
	var/cost_multiplier = 0.5

/datum/status_effect/hivelord/protective_light/on_apply()
	xenomorph_owner = owner
	var/datum/action/ability/activable/xeno/healing_infusion/healing_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/healing_infusion]
	if(!healing_ability)
		return
	healing_ability.resin_jelly_duration += resin_jelly_length
	healing_ability.ability_cost += initial(healing_ability.ability_cost) * cost_multiplier
	return TRUE

/datum/status_effect/hivelord/protective_light/on_remove()
	var/datum/action/ability/activable/xeno/healing_infusion/healing_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/healing_infusion]
	if(!healing_ability)
		return ..()
	healing_ability.resin_jelly_duration -= resin_jelly_length
	healing_ability.ability_cost -= initial(healing_ability.ability_cost) * cost_multiplier
	return ..()

//*********************//
//    Forward Light    //
//*********************//
/datum/xeno_mutation/hivelord/forward_light
	name = "Forward Light"
	desc = "Healing Infusion длится на 30% меньше, но даёт мощный личный эффект восстановления, который лечит вас напрямую и работает даже в движении, не полагаясь на пассивный реген от сорняков. КОНФЛИКТУЕТ С Protective Light."
	cost = 7.5
	icon_state = "xenobuff_generic"
	tier = 1
	status_effect_type = STATUS_EFFECT_FORWARD_LIGHT
	conflicting_mutation_types = list(STATUS_EFFECT_PROTECTIVE_LIGHT)
	buff_desc = "Healing Infusion на 30% короче, но даёт активный личный реген (лечит в движении). (Конфликтует с Protective Light)"

/atom/movable/screen/alert/status_effect/hivelord/forward_light
	name = "Forward Light"
	desc = "Healing Infusion короче, но даёт активный личный реген, работающий в движении. КОНФЛИКТУЕТ С Protective Light."
	icon_state = "xenobuff_attack"

/datum/status_effect/hivelord/forward_light
	id = "upgrade_forward_light"
	alert_type = /atom/movable/screen/alert/status_effect/hivelord/forward_light
	/// Множитель длительности и силы хила (отрицательный = уменьшение).
	var/duration_multiplier = -0.3

/datum/status_effect/hivelord/forward_light/on_apply()
	xenomorph_owner = owner
	var/datum/action/ability/activable/xeno/healing_infusion/healing_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/healing_infusion]
	if(!healing_ability)
		return
	healing_ability.innate_healing = TRUE
	healing_ability.status_multiplier += duration_multiplier
	return TRUE

/datum/status_effect/hivelord/forward_light/on_remove()
	var/datum/action/ability/activable/xeno/healing_infusion/healing_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/healing_infusion]
	if(!healing_ability)
		return ..()
	healing_ability.innate_healing = initial(healing_ability.innate_healing)
	healing_ability.status_multiplier -= duration_multiplier
	return ..()

//*********************//
//   Weed Specialist   //
//*********************//
/datum/xeno_mutation/hivelord/weed_specialist
	name = "Weed Specialist"
	desc = "Сажать сорняки стоит на 50% дешевле, но вы теряете возможность выбирать базовые (обычные) сорняки."
	cost = 5
	icon_state = "xenobuff_generic"
	tier = 1
	status_effect_type = STATUS_EFFECT_WEED_SPECIALIST
	buff_desc = "Plant Weeds на 50% дешевле, но без базовых сорняков."

/atom/movable/screen/alert/status_effect/hivelord/weed_specialist
	name = "Weed Specialist"
	desc = "Сажать сорняки дешевле, но базовые сорняки недоступны."
	icon_state = "xenobuff_attack"

/datum/status_effect/hivelord/weed_specialist
	id = "upgrade_weed_specialist"
	alert_type = /atom/movable/screen/alert/status_effect/hivelord/weed_specialist
	var/cost_multiplier = -0.5

/datum/status_effect/hivelord/weed_specialist/on_apply()
	xenomorph_owner = owner
	var/datum/action/ability/activable/xeno/plant_weeds/weed_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/plant_weeds]
	if(!weed_ability)
		return
	if(/obj/alien/weeds/node in weed_ability.selectable_weed_typepaths)
		weed_ability.selectable_weed_typepaths -= /obj/alien/weeds/node
	if(weed_ability.weed_type == /obj/alien/weeds/node && length(weed_ability.selectable_weed_typepaths))
		weed_ability.weed_type = pick(weed_ability.selectable_weed_typepaths)
	weed_ability.cost_multiplier += cost_multiplier
	weed_ability.update_ability_cost()
	weed_ability.update_button_icon()
	return TRUE

/datum/status_effect/hivelord/weed_specialist/on_remove()
	var/datum/action/ability/activable/xeno/plant_weeds/weed_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/plant_weeds]
	if(!weed_ability)
		return ..()
	if(!(/obj/alien/weeds/node in weed_ability.selectable_weed_typepaths))
		weed_ability.selectable_weed_typepaths += /obj/alien/weeds/node
	weed_ability.cost_multiplier -= cost_multiplier
	weed_ability.update_ability_cost()
	weed_ability.update_button_icon()
	return ..()
