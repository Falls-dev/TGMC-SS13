// Hunter Enhancement mutations. Ported from the official Shell/Spur/Veil mutations.
// Levels I/II/III use the official values for 1/2/3 structures. See datums/xeno_mutations_leveled.dm.
// Conflicts (the newer purchase replaces the owned one, no refund): Splitting Mirage / Cloaking Mirage / Mirage Flood with each other, Debilitating Strike / Faceblind / Ambush with each other (all three buff the Stealth sneak attack).
// Not ported: One Target. I could not find Silence (/datum/action/ability/activable/xeno/silence) in the provided codebase.
// In this build Sneak Attack already deals an extra hit of 1x slash damage, so Debilitating Strike adds 0.25/0.5/0.75x to it (1.25/1.5/1.75x in total).

/datum/xeno_mutation/leveled/hunter
	caste_restrictions = list("hunter")

// ***************************************
// *********** Fleeting Mirage
// ***************************************
/datum/xeno_mutation/leveled/hunter/fleeting_mirage
	required_ability_types = list(/datum/action/ability/xeno_action/mirage)
	name = "Fleeting Mirage"
	desc = "Когда ваше здоровье падает ниже порога, появляется иллюзия, которая убегает от вас. При обмене через Mirage эта иллюзия выбирается первой."
	level_costs = list(5, 10, 15)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/hunter_fleeting_mirage,
		/datum/status_effect/xeno_enhancement/hunter_fleeting_mirage/two,
		/datum/status_effect/xeno_enhancement/hunter_fleeting_mirage/three,
	)
	level_buff_descs = list(
		"Порог срабатывания: 25% здоровья.",
		"Порог срабатывания: 40% здоровья.",
		"Порог срабатывания: 55% здоровья.",
	)

/datum/status_effect/xeno_enhancement/hunter_fleeting_mirage
	id = "enhancement_hunter_fleeting_mirage"
	/// Per level, the fraction of maximum health at or below which the illusion appears.
	var/list/threshold_per_level = list(0.25, 0.4, 0.55)
	/// The effect triggers again only after the health was full once.
	var/can_be_activated = FALSE
	/// The timer that deletes the illusion.
	var/timer_id

/datum/status_effect/xeno_enhancement/hunter_fleeting_mirage/two
	level = 2

/datum/status_effect/xeno_enhancement/hunter_fleeting_mirage/three
	level = 3

/datum/status_effect/xeno_enhancement/hunter_fleeting_mirage/apply_enhancement()
	if(!xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/mirage])
		return FALSE
	RegisterSignal(xenomorph_owner, COMSIG_LIVING_UPDATE_HEALTH, PROC_REF(on_update_health))
	can_be_activated = xenomorph_owner.health >= xenomorph_owner.maxHealth
	return TRUE

/datum/status_effect/xeno_enhancement/hunter_fleeting_mirage/remove_enhancement()
	UnregisterSignal(xenomorph_owner, COMSIG_LIVING_UPDATE_HEALTH)
	can_be_activated = FALSE
	remove_illusion()

/// Activates the effect if the health is low enough, or allows it to be activated next time if the health is full.
/datum/status_effect/xeno_enhancement/hunter_fleeting_mirage/proc/on_update_health(datum/source)
	SIGNAL_HANDLER
	if(xenomorph_owner.health <= xenomorph_owner.get_death_threshold())
		return
	if(!can_be_activated)
		if(xenomorph_owner.health >= xenomorph_owner.maxHealth)
			can_be_activated = TRUE
		return
	if(timer_id || xenomorph_owner.health > xenomorph_owner.maxHealth * get_level_value(threshold_per_level))
		return
	var/datum/action/ability/xeno_action/mirage/mirage_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/mirage]
	if(!mirage_ability)
		return
	can_be_activated = FALSE
	mirage_ability.prioritized_illusion = new(xenomorph_owner.loc, xenomorph_owner, xenomorph_owner, 10 SECONDS, /datum/ai_behavior/xeno/fleeing_illusion)
	RegisterSignal(mirage_ability.prioritized_illusion, COMSIG_QDELETING, PROC_REF(on_illusion_deleted))
	timer_id = addtimer(CALLBACK(src, PROC_REF(remove_illusion)), 10 SECONDS, TIMER_STOPPABLE)

/// The illusion was deleted by something else, so Mirage must not keep a reference to it.
/datum/status_effect/xeno_enhancement/hunter_fleeting_mirage/proc/on_illusion_deleted(datum/source)
	SIGNAL_HANDLER
	var/datum/action/ability/xeno_action/mirage/mirage_ability = xenomorph_owner?.actions_by_path[/datum/action/ability/xeno_action/mirage]
	if(mirage_ability && mirage_ability.prioritized_illusion == source)
		mirage_ability.prioritized_illusion = null
	if(timer_id)
		deltimer(timer_id)
		timer_id = null

/// Deletes the illusion.
/datum/status_effect/xeno_enhancement/hunter_fleeting_mirage/proc/remove_illusion()
	if(timer_id)
		deltimer(timer_id)
		timer_id = null
	var/datum/action/ability/xeno_action/mirage/mirage_ability = xenomorph_owner?.actions_by_path[/datum/action/ability/xeno_action/mirage]
	if(mirage_ability && mirage_ability.prioritized_illusion)
		UnregisterSignal(mirage_ability.prioritized_illusion, COMSIG_QDELETING)
		QDEL_NULL(mirage_ability.prioritized_illusion)

// ***************************************
// *********** Splitting Mirage
// ***************************************
/datum/xeno_mutation/leveled/hunter/splitting_mirage
	required_ability_types = list(/datum/action/ability/xeno_action/mirage)
	conflicting_base_names = list("Cloaking Mirage", "Mirage Flood")
	name = "Splitting Mirage"
	desc = "Mirage не создаёт иллюзии сразу: вместо этого каждый ваш удар создаёт иллюзию, пока Mirage активен."
	level_costs = list(7.5, 12.5, 17.5)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/hunter_splitting_mirage,
		/datum/status_effect/xeno_enhancement/hunter_splitting_mirage/two,
		/datum/status_effect/xeno_enhancement/hunter_splitting_mirage/three,
	)
	level_buff_descs = list(
		"Mirage длится 12 секунд.",
		"Mirage длится 14 секунд.",
		"Mirage длится 16 секунд.",
	)

/datum/status_effect/xeno_enhancement/hunter_splitting_mirage
	id = "enhancement_hunter_splitting_mirage"
	/// Per level, the lifespan that is added to the illusions.
	var/list/length_per_level = list(2 SECONDS, 4 SECONDS, 6 SECONDS)
	var/applied_length = 0
	var/applied_count = 0

/datum/status_effect/xeno_enhancement/hunter_splitting_mirage/two
	level = 2

/datum/status_effect/xeno_enhancement/hunter_splitting_mirage/three
	level = 3

/datum/status_effect/xeno_enhancement/hunter_splitting_mirage/apply_enhancement()
	var/datum/action/ability/xeno_action/mirage/mirage_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/mirage]
	if(!mirage_ability)
		return FALSE
	applied_length = get_level_value(length_per_level)
	applied_count = initial(mirage_ability.illusion_count)
	mirage_ability.illusion_count -= applied_count
	mirage_ability.illusion_life_time += applied_length
	mirage_ability.illusion_on_slash = TRUE
	if(mirage_ability.timer_id) // Ability is currently active.
		mirage_ability.register_on_slash()
	return TRUE

/datum/status_effect/xeno_enhancement/hunter_splitting_mirage/remove_enhancement()
	var/datum/action/ability/xeno_action/mirage/mirage_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/mirage]
	if(mirage_ability)
		mirage_ability.illusion_count += applied_count
		mirage_ability.illusion_life_time -= applied_length
		mirage_ability.illusion_on_slash = FALSE
		if(mirage_ability.timer_id)
			mirage_ability.unregister_on_slash()
	applied_length = 0
	applied_count = 0

// ***************************************
// *********** Cloaking Mirage
// ***************************************
/datum/xeno_mutation/leveled/hunter/cloaking_mirage
	required_ability_types = list(/datum/action/ability/xeno_action/mirage)
	conflicting_base_names = list("Splitting Mirage", "Mirage Flood")
	name = "Cloaking Mirage"
	desc = "Mirage не создаёт иллюзии, а выпускает маскирующий газ радиусом 2: ксеноморфы внутри него становятся скрытными."
	level_costs = list(7.5, 12.5, 17.5)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/hunter_cloaking_mirage,
		/datum/status_effect/xeno_enhancement/hunter_cloaking_mirage/two,
		/datum/status_effect/xeno_enhancement/hunter_cloaking_mirage/three,
	)
	level_buff_descs = list(
		"Газ держится 12 секунд.",
		"Газ держится 14 секунд.",
		"Газ держится 16 секунд.",
	)

/datum/status_effect/xeno_enhancement/hunter_cloaking_mirage
	id = "enhancement_hunter_cloaking_mirage"
	/// Per level, the lifespan that is added to the gas.
	var/list/length_per_level = list(2 SECONDS, 4 SECONDS, 6 SECONDS)
	var/applied_length = 0
	var/applied_count = 0

/datum/status_effect/xeno_enhancement/hunter_cloaking_mirage/two
	level = 2

/datum/status_effect/xeno_enhancement/hunter_cloaking_mirage/three
	level = 3

/datum/status_effect/xeno_enhancement/hunter_cloaking_mirage/apply_enhancement()
	var/datum/action/ability/xeno_action/mirage/mirage_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/mirage]
	if(!mirage_ability)
		return FALSE
	applied_length = get_level_value(length_per_level)
	applied_count = initial(mirage_ability.illusion_count)
	mirage_ability.illusion_count -= applied_count
	mirage_ability.illusion_life_time += applied_length
	mirage_ability.cloaking_gas = TRUE
	return TRUE

/datum/status_effect/xeno_enhancement/hunter_cloaking_mirage/remove_enhancement()
	var/datum/action/ability/xeno_action/mirage/mirage_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/mirage]
	if(mirage_ability)
		mirage_ability.illusion_count += applied_count
		mirage_ability.illusion_life_time -= applied_length
		mirage_ability.cloaking_gas = FALSE
	applied_length = 0
	applied_count = 0

// ***************************************
// *********** Debilitating Strike
// ***************************************
/datum/xeno_mutation/leveled/hunter/debilitating_strike
	required_ability_types = list(/datum/action/ability/xeno_action/stealth)
	conflicting_base_names = list("Faceblind", "Ambush")
	name = "Debilitating Strike"
	desc = "Sneak Attack из Stealth больше не оглушает цель, зато наносит гораздо больше дополнительного урона."
	level_costs = list(5, 10, 15)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/hunter_debilitating_strike,
		/datum/status_effect/xeno_enhancement/hunter_debilitating_strike/two,
		/datum/status_effect/xeno_enhancement/hunter_debilitating_strike/three,
	)
	level_buff_descs = list(
		"Sneak Attack: без оглушения, доп. урон x1.25 от урона удара.",
		"Sneak Attack: без оглушения, доп. урон x1.5 от урона удара.",
		"Sneak Attack: без оглушения, доп. урон x1.75 от урона удара.",
	)

/datum/status_effect/xeno_enhancement/hunter_debilitating_strike
	id = "enhancement_hunter_debilitating_strike"
	/// Per level, the multiplier added to the extra damage of Sneak Attack.
	var/list/multiplier_per_level = list(0.25, 0.5, 0.75)
	var/applied_multiplier = 0
	var/applied_stun = 0

/datum/status_effect/xeno_enhancement/hunter_debilitating_strike/two
	level = 2

/datum/status_effect/xeno_enhancement/hunter_debilitating_strike/three
	level = 3

/datum/status_effect/xeno_enhancement/hunter_debilitating_strike/apply_enhancement()
	var/datum/action/ability/xeno_action/stealth/stealth_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/stealth]
	if(!stealth_ability)
		return FALSE
	applied_multiplier = get_level_value(multiplier_per_level)
	applied_stun = initial(stealth_ability.sneak_attack_stun_duration)
	stealth_ability.bonus_stealth_damage_multiplier += applied_multiplier
	stealth_ability.sneak_attack_stun_duration -= applied_stun
	return TRUE

/datum/status_effect/xeno_enhancement/hunter_debilitating_strike/remove_enhancement()
	var/datum/action/ability/xeno_action/stealth/stealth_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/stealth]
	if(stealth_ability)
		stealth_ability.bonus_stealth_damage_multiplier -= applied_multiplier
		stealth_ability.sneak_attack_stun_duration += applied_stun
	applied_multiplier = 0
	applied_stun = 0

// ***************************************
// *********** Ambush
// ***************************************
/datum/xeno_mutation/leveled/hunter/ambush
	required_ability_types = list(/datum/action/ability/xeno_action/stealth)
	conflicting_base_names = list("Debilitating Strike", "Faceblind")
	name = "Ambush"
	desc = "Движение в Stealth тратит втрое больше плазмы, но на максимальной скрытности ваш Sneak Attack получает бонус к бронепробитию (AP)."
	level_costs = list(5, 10, 15)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/hunter_ambush,
		/datum/status_effect/xeno_enhancement/hunter_ambush/two,
		/datum/status_effect/xeno_enhancement/hunter_ambush/three,
	)
	level_buff_descs = list(
		"Движение в Stealth x3 плазмы. Бонус AP +15.",
		"Движение в Stealth x3 плазмы. Бонус AP +22.5.",
		"Движение в Stealth x3 плазмы. Бонус AP +30.",
	)

/datum/status_effect/xeno_enhancement/hunter_ambush
	id = "enhancement_hunter_ambush"
	/// Per level, the bonus armor piercing at maximum stealth.
	var/list/ap_per_level = list(15, 22.5, 30)
	var/applied_ap = 0

/datum/status_effect/xeno_enhancement/hunter_ambush/two
	level = 2

/datum/status_effect/xeno_enhancement/hunter_ambush/three
	level = 3

/datum/status_effect/xeno_enhancement/hunter_ambush/apply_enhancement()
	var/datum/action/ability/xeno_action/stealth/stealth_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/stealth]
	if(!stealth_ability)
		return FALSE
	applied_ap = get_level_value(ap_per_level)
	stealth_ability.movement_cost_multiplier += 2 // 100% -> 300%
	stealth_ability.bonus_maximum_stealth_ap += applied_ap
	return TRUE

/datum/status_effect/xeno_enhancement/hunter_ambush/remove_enhancement()
	var/datum/action/ability/xeno_action/stealth/stealth_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/stealth]
	if(stealth_ability)
		stealth_ability.movement_cost_multiplier -= 2
		stealth_ability.bonus_maximum_stealth_ap -= applied_ap
	applied_ap = 0

// ***************************************
// *********** Maul
// ***************************************
/datum/xeno_mutation/leveled/hunter/maul
	required_ability_types = list(/datum/action/ability/activable/xeno/pounce)
	name = "Maul"
	desc = "Pounce больше не оглушает, но сразу бьёт цель когтями (это может сработать как Sneak Attack), а перезаряжается быстрее."
	level_costs = list(7.5, 12.5, 17.5)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/hunter_maul,
		/datum/status_effect/xeno_enhancement/hunter_maul/two,
		/datum/status_effect/xeno_enhancement/hunter_maul/three,
	)
	level_buff_descs = list(
		"Pounce без оглушения, удар цели. Перезарядка 60%.",
		"Pounce без оглушения, удар цели. Перезарядка 50%.",
		"Pounce без оглушения, удар цели. Перезарядка 40%.",
	)

/datum/status_effect/xeno_enhancement/hunter_maul
	id = "enhancement_hunter_maul"
	/// Per level, the multiplier of the initial cooldown that is added to the cooldown.
	var/list/multiplier_per_level = list(-0.4, -0.5, -0.6)
	var/applied_cooldown = 0
	var/applied_stun = 0
	var/applied_immobilize = 0

/datum/status_effect/xeno_enhancement/hunter_maul/two
	level = 2

/datum/status_effect/xeno_enhancement/hunter_maul/three
	level = 3

/datum/status_effect/xeno_enhancement/hunter_maul/apply_enhancement()
	var/datum/action/ability/activable/xeno/pounce/pounce_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/pounce]
	if(!pounce_ability)
		return FALSE
	applied_cooldown = initial(pounce_ability.cooldown_duration) * get_level_value(multiplier_per_level)
	applied_stun = initial(pounce_ability.stun_duration)
	applied_immobilize = initial(pounce_ability.self_immobilize_duration)
	pounce_ability.cooldown_duration += applied_cooldown
	pounce_ability.stun_duration -= applied_stun
	pounce_ability.self_immobilize_duration -= applied_immobilize
	pounce_ability.attack_on_pounce = TRUE
	return TRUE

/datum/status_effect/xeno_enhancement/hunter_maul/remove_enhancement()
	var/datum/action/ability/activable/xeno/pounce/pounce_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/pounce]
	if(pounce_ability)
		pounce_ability.cooldown_duration -= applied_cooldown
		pounce_ability.stun_duration += applied_stun
		pounce_ability.self_immobilize_duration += applied_immobilize
		pounce_ability.attack_on_pounce = FALSE
	applied_cooldown = 0
	applied_stun = 0
	applied_immobilize = 0

// ***************************************
// *********** Mirage Flood
// ***************************************
/datum/xeno_mutation/leveled/hunter/mirage_flood
	required_ability_types = list(/datum/action/ability/xeno_action/mirage)
	conflicting_base_names = list("Splitting Mirage", "Cloaking Mirage")
	name = "Mirage Flood"
	desc = "Mirage создаёт на 4 иллюзии больше, но иллюзии живут меньше."
	level_costs = list(5, 10, 15)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/hunter_mirage_flood,
		/datum/status_effect/xeno_enhancement/hunter_mirage_flood/two,
		/datum/status_effect/xeno_enhancement/hunter_mirage_flood/three,
	)
	level_buff_descs = list(
		"+4 иллюзии, время жизни -5 сек.",
		"+4 иллюзии, время жизни -3 сек.",
		"+4 иллюзии, время жизни -1 сек.",
	)

/datum/status_effect/xeno_enhancement/hunter_mirage_flood
	id = "enhancement_hunter_mirage_flood"
	/// Per level, the lifespan that is added to the illusions (negative is shorter).
	var/list/length_per_level = list(-5 SECONDS, -3 SECONDS, -1 SECONDS)
	var/applied_length = 0

/datum/status_effect/xeno_enhancement/hunter_mirage_flood/two
	level = 2

/datum/status_effect/xeno_enhancement/hunter_mirage_flood/three
	level = 3

/datum/status_effect/xeno_enhancement/hunter_mirage_flood/apply_enhancement()
	var/datum/action/ability/xeno_action/mirage/mirage_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/mirage]
	if(!mirage_ability)
		return FALSE
	applied_length = get_level_value(length_per_level)
	mirage_ability.illusion_count += 4
	mirage_ability.illusion_life_time += applied_length
	return TRUE

/datum/status_effect/xeno_enhancement/hunter_mirage_flood/remove_enhancement()
	var/datum/action/ability/xeno_action/mirage/mirage_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/mirage]
	if(mirage_ability)
		mirage_ability.illusion_count -= 4
		mirage_ability.illusion_life_time -= applied_length
	applied_length = 0

// ***************************************
// *********** Faceblind
// ***************************************
/datum/xeno_mutation/leveled/hunter/faceblind
	required_ability_types = list(/datum/action/ability/xeno_action/stealth, /datum/action/ability/xeno_action/mirage)
	conflicting_base_names = list("Debilitating Strike", "Ambush")
	name = "Faceblind"
	desc = "Sneak Attack из Stealth слепит цель на время, но больше не оглушает. Mirage перезаряжается быстрее."
	level_costs = list(5, 10, 15)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/hunter_faceblind,
		/datum/status_effect/xeno_enhancement/hunter_faceblind/two,
		/datum/status_effect/xeno_enhancement/hunter_faceblind/three,
	)
	level_buff_descs = list(
		"Слепота вместо оглушения. Перезарядка Mirage 90%.",
		"Слепота вместо оглушения. Перезарядка Mirage 80%.",
		"Слепота вместо оглушения. Перезарядка Mirage 70%.",
	)

/datum/status_effect/xeno_enhancement/hunter_faceblind
	id = "enhancement_hunter_faceblind"
	/// Per level, the multiplier of the initial cooldown that is added to the cooldown of Mirage.
	var/list/multiplier_per_level = list(-0.1, -0.2, -0.3)
	var/applied_cooldown = 0
	var/applied_stun = 0
	var/applied_blind = 0

/datum/status_effect/xeno_enhancement/hunter_faceblind/two
	level = 2

/datum/status_effect/xeno_enhancement/hunter_faceblind/three
	level = 3

/datum/status_effect/xeno_enhancement/hunter_faceblind/apply_enhancement()
	var/datum/action/ability/xeno_action/stealth/stealth_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/stealth]
	var/datum/action/ability/xeno_action/mirage/mirage_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/mirage]
	if(!stealth_ability || !mirage_ability)
		return FALSE
	applied_cooldown = initial(mirage_ability.cooldown_duration) * get_level_value(multiplier_per_level)
	applied_stun = initial(stealth_ability.sneak_attack_stun_duration)
	applied_blind = 2
	mirage_ability.cooldown_duration += applied_cooldown
	stealth_ability.sneak_attack_stun_duration -= applied_stun
	stealth_ability.blinding_stacks += applied_blind
	return TRUE

/datum/status_effect/xeno_enhancement/hunter_faceblind/remove_enhancement()
	var/datum/action/ability/xeno_action/stealth/stealth_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/stealth]
	var/datum/action/ability/xeno_action/mirage/mirage_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/mirage]
	if(mirage_ability)
		mirage_ability.cooldown_duration -= applied_cooldown
	if(stealth_ability)
		stealth_ability.sneak_attack_stun_duration += applied_stun
		stealth_ability.blinding_stacks -= applied_blind
	applied_cooldown = 0
	applied_stun = 0
	applied_blind = 0
