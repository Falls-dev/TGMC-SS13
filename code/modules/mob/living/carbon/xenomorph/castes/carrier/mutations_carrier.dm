// Carrier Enhancement mutations. Ported from the official Shell/Spur/Veil mutations.
// Levels I/II/III use the official values for 1/2/3 structures. See datums/xeno_mutations_leveled.dm.
// Not ported (I could not find this in the provided codebase): Swarm Trap, because traps here can hold only one hugger (no trap_hugger_limit).
// Conflict (the newer purchase replaces the owned one, no refund): Oviposition / Life for Life, because Oviposition removes Spawn Facehugger.

/datum/xeno_mutation/leveled/carrier
	caste_restrictions = list("carrier")

// ***************************************
// *********** Shared Jelly
// ***************************************
/datum/xeno_mutation/leveled/carrier/shared_jelly
	required_ability_types = list(/datum/action/ability/activable/xeno/throw_hugger)
	name = "Shared Jelly"
	desc = "Если на вас действует Resin Jelly, все брошенные huggers получают иммунитет к огню. Каждый брошенный hugger сокращает длительность эффекта."
	level_costs = list(10, 15, 20)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/carrier_shared_jelly,
		/datum/status_effect/xeno_enhancement/carrier_shared_jelly/two,
		/datum/status_effect/xeno_enhancement/carrier_shared_jelly/three,
	)
	level_buff_descs = list(
		"Каждый брошенный hugger сокращает эффект Resin Jelly на 3 секунды.",
		"Каждый брошенный hugger сокращает эффект Resin Jelly на 2 секунды.",
		"Каждый брошенный hugger сокращает эффект Resin Jelly на 1 секунду.",
	)

/datum/status_effect/xeno_enhancement/carrier_shared_jelly
	id = "enhancement_carrier_shared_jelly"
	/// Per level, how much the duration of Resin Jelly Coating is decreased per thrown hugger.
	var/list/length_per_level = list(3 SECONDS, 2 SECONDS, 1 SECONDS)
	var/applied_length = 0

/datum/status_effect/xeno_enhancement/carrier_shared_jelly/two
	level = 2

/datum/status_effect/xeno_enhancement/carrier_shared_jelly/three
	level = 3

/datum/status_effect/xeno_enhancement/carrier_shared_jelly/apply_enhancement()
	var/datum/action/ability/activable/xeno/throw_hugger/hugger_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/throw_hugger]
	if(!hugger_ability)
		return FALSE
	applied_length = get_level_value(length_per_level)
	hugger_ability.fire_immunity_transfer += applied_length
	return TRUE

/datum/status_effect/xeno_enhancement/carrier_shared_jelly/remove_enhancement()
	var/datum/action/ability/activable/xeno/throw_hugger/hugger_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/throw_hugger]
	if(hugger_ability)
		hugger_ability.fire_immunity_transfer -= applied_length
	applied_length = 0

// ***************************************
// *********** Hugger Overflow
// ***************************************
/datum/xeno_mutation/leveled/carrier/hugger_overflow
	required_ability_types = list(/datum/action/ability/activable/xeno/throw_hugger)
	name = "Hugger Overflow"
	desc = "Пока у вас накоплено достаточно huggers, при получении стаггера вы автоматически роняете одного larval hugger под себя."
	level_costs = list(10, 15, 20)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/carrier_hugger_overflow,
		/datum/status_effect/xeno_enhancement/carrier_hugger_overflow/two,
		/datum/status_effect/xeno_enhancement/carrier_hugger_overflow/three,
	)
	level_buff_descs = list(
		"От 8 и более huggers: при стаггере роняется larval hugger.",
		"От 7 и более huggers: при стаггере роняется larval hugger.",
		"От 6 и более huggers: при стаггере роняется larval hugger.",
	)

/datum/status_effect/xeno_enhancement/carrier_hugger_overflow
	id = "enhancement_carrier_hugger_overflow"
	/// Per level, the amount of stored huggers needed to drop one when staggered.
	var/list/threshold_per_level = list(8, 7, 6)

/datum/status_effect/xeno_enhancement/carrier_hugger_overflow/two
	level = 2

/datum/status_effect/xeno_enhancement/carrier_hugger_overflow/three
	level = 3

/datum/status_effect/xeno_enhancement/carrier_hugger_overflow/apply_enhancement()
	RegisterSignal(xenomorph_owner, COMSIG_LIVING_STATUS_STAGGER, PROC_REF(on_staggered))
	return TRUE

/datum/status_effect/xeno_enhancement/carrier_hugger_overflow/remove_enhancement()
	UnregisterSignal(xenomorph_owner, COMSIG_LIVING_STATUS_STAGGER)

/// If the threshold of stored huggers is reached, drop a larval hugger.
/datum/status_effect/xeno_enhancement/carrier_hugger_overflow/proc/on_staggered(datum/source, amount, ignore_canstun)
	SIGNAL_HANDLER
	if(get_level_value(threshold_per_level) > xenomorph_owner.huggers)
		return
	var/obj/item/clothing/mask/facehugger/new_hugger = new /obj/item/clothing/mask/facehugger/larval(get_turf(xenomorph_owner), xenomorph_owner.hivenumber, xenomorph_owner)
	step_away(new_hugger, xenomorph_owner, 1)
	addtimer(CALLBACK(new_hugger, TYPE_PROC_REF(/obj/item/clothing/mask/facehugger, go_active), TRUE), new_hugger.jump_cooldown)
	xenomorph_owner.huggers--

// ***************************************
// *********** Recurring Panic
// ***************************************
/datum/xeno_mutation/leveled/carrier/recurring_panic
	required_ability_types = list(/datum/action/ability/xeno_action/carrier_panic)
	name = "Recurring Panic"
	desc = "Пока вы не отдыхаете, Drop All Facehuggers (Carrier Panic) сам срабатывает, когда это возможно. Перезарядка 20% от обычной, тратится только часть максимальной плазмы."
	level_costs = list(10, 15, 20)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/carrier_recurring_panic,
		/datum/status_effect/xeno_enhancement/carrier_recurring_panic/two,
		/datum/status_effect/xeno_enhancement/carrier_recurring_panic/three,
	)
	level_buff_descs = list(
		"Автоактивация Carrier Panic, перезарядка 20%, тратит 50% максимальной плазмы.",
		"Автоактивация Carrier Panic, перезарядка 20%, тратит 40% максимальной плазмы.",
		"Автоактивация Carrier Panic, перезарядка 20%, тратит 30% максимальной плазмы.",
	)

/datum/status_effect/xeno_enhancement/carrier_recurring_panic
	id = "enhancement_carrier_recurring_panic"
	/// Per level, the fraction of maximum plasma that Carrier Panic consumes.
	var/list/cost_per_level = list(0.5, 0.4, 0.3)
	var/applied_cooldown = 0
	var/applied_cost = 0

/datum/status_effect/xeno_enhancement/carrier_recurring_panic/two
	level = 2

/datum/status_effect/xeno_enhancement/carrier_recurring_panic/three
	level = 3

/datum/status_effect/xeno_enhancement/carrier_recurring_panic/apply_enhancement()
	var/datum/action/ability/xeno_action/carrier_panic/panic_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/carrier_panic]
	if(!panic_ability)
		return FALSE
	applied_cooldown = initial(panic_ability.cooldown_duration) * 0.8
	// Panic consumes everything by default (1), so the difference to the wanted fraction is applied.
	applied_cost = get_level_value(cost_per_level) - 1
	panic_ability.cooldown_duration -= applied_cooldown
	panic_ability.succeed_cost += applied_cost
	panic_ability.update_button_icon()
	RegisterSignal(xenomorph_owner, COMSIG_LIVING_UPDATE_HEALTH, PROC_REF(on_update_health))
	return TRUE

/datum/status_effect/xeno_enhancement/carrier_recurring_panic/remove_enhancement()
	UnregisterSignal(xenomorph_owner, COMSIG_LIVING_UPDATE_HEALTH)
	var/datum/action/ability/xeno_action/carrier_panic/panic_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/carrier_panic]
	if(panic_ability)
		panic_ability.cooldown_duration += applied_cooldown
		panic_ability.succeed_cost -= applied_cost
		panic_ability.update_button_icon()
	applied_cooldown = 0
	applied_cost = 0

/// Activates Carrier Panic if it can be used and the owner is not resting.
/datum/status_effect/xeno_enhancement/carrier_recurring_panic/proc/on_update_health(datum/source)
	SIGNAL_HANDLER
	if(xenomorph_owner.health <= xenomorph_owner.get_death_threshold())
		return
	var/datum/action/ability/xeno_action/carrier_panic/panic_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/carrier_panic]
	if(!panic_ability)
		return
	if(xenomorph_owner.resting || panic_ability.cooldown_timer || !panic_ability.can_use_action(silent = TRUE))
		return
	INVOKE_ASYNC(panic_ability, TYPE_PROC_REF(/datum/action/ability/xeno_action/carrier_panic, action_activate))

// ***************************************
// *********** Leapfrog
// ***************************************
/datum/xeno_mutation/leveled/carrier/leapfrog
	required_ability_types = list(/datum/action/ability/activable/xeno/throw_hugger)
	name = "Leapfrog"
	desc = "Брошенные huggers прыгают на 1 клетку за раз. Все времена активации сокращены, но не быстрее 0.5 секунды."
	level_costs = list(10, 15, 20)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/carrier_leapfrog,
		/datum/status_effect/xeno_enhancement/carrier_leapfrog/two,
		/datum/status_effect/xeno_enhancement/carrier_leapfrog/three,
	)
	level_buff_descs = list(
		"Прыжок hugger 1 клетка, времена активации x0.8.",
		"Прыжок hugger 1 клетка, времена активации x0.7.",
		"Прыжок hugger 1 клетка, времена активации x0.6.",
	)

/datum/status_effect/xeno_enhancement/carrier_leapfrog
	id = "enhancement_carrier_leapfrog"
	/// Per level, the multiplier added to the activation times (negative is faster).
	var/list/multiplier_per_level = list(-0.2, -0.3, -0.4)
	var/applied_multiplier = 0
	var/applied_range = 0

/datum/status_effect/xeno_enhancement/carrier_leapfrog/two
	level = 2

/datum/status_effect/xeno_enhancement/carrier_leapfrog/three
	level = 3

/datum/status_effect/xeno_enhancement/carrier_leapfrog/apply_enhancement()
	var/datum/action/ability/activable/xeno/throw_hugger/hugger_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/throw_hugger]
	if(!hugger_ability)
		return FALSE
	applied_multiplier = get_level_value(multiplier_per_level)
	applied_range = hugger_ability.leapping_range - 1
	hugger_ability.leapping_range -= applied_range
	hugger_ability.activation_time_multiplier += applied_multiplier
	return TRUE

/datum/status_effect/xeno_enhancement/carrier_leapfrog/remove_enhancement()
	var/datum/action/ability/activable/xeno/throw_hugger/hugger_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/throw_hugger]
	if(hugger_ability)
		hugger_ability.leapping_range += applied_range
		hugger_ability.activation_time_multiplier -= applied_multiplier
	applied_multiplier = 0
	applied_range = 0

// ***************************************
// *********** Fake Huggers
// ***************************************
/datum/xeno_mutation/leveled/carrier/fake_huggers
	required_ability_types = list(/datum/action/ability/activable/xeno/throw_hugger)
	name = "Fake Huggers"
	desc = "Вместе с брошенным hugger летит фальшивый hugger, повторяющий его поведение. Его цвет приближен к цвету настоящего."
	level_costs = list(10, 15, 20)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/carrier_fake_huggers,
		/datum/status_effect/xeno_enhancement/carrier_fake_huggers/two,
		/datum/status_effect/xeno_enhancement/carrier_fake_huggers/three,
	)
	level_buff_descs = list(
		"Фальшивый hugger: цвет на 50% как у настоящего.",
		"Фальшивый hugger: цвет на 70% как у настоящего.",
		"Фальшивый hugger: цвет на 90% как у настоящего.",
	)

/datum/status_effect/xeno_enhancement/carrier_fake_huggers
	id = "enhancement_carrier_fake_huggers"
	/// Per level, the gradient between the color of the fake hugger and the real one.
	var/list/gradient_per_level = list(0.5, 0.7, 0.9)
	var/applied_gradient = 0

/datum/status_effect/xeno_enhancement/carrier_fake_huggers/two
	level = 2

/datum/status_effect/xeno_enhancement/carrier_fake_huggers/three
	level = 3

/datum/status_effect/xeno_enhancement/carrier_fake_huggers/apply_enhancement()
	var/datum/action/ability/activable/xeno/throw_hugger/hugger_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/throw_hugger]
	if(!hugger_ability)
		return FALSE
	applied_gradient = get_level_value(gradient_per_level)
	hugger_ability.fake_hugger_gradiant_percentage += applied_gradient
	return TRUE

/datum/status_effect/xeno_enhancement/carrier_fake_huggers/remove_enhancement()
	var/datum/action/ability/activable/xeno/throw_hugger/hugger_ability = xenomorph_owner.actions_by_path[/datum/action/ability/activable/xeno/throw_hugger]
	if(hugger_ability)
		hugger_ability.fake_hugger_gradiant_percentage -= applied_gradient
	applied_gradient = 0

// ***************************************
// *********** Life for Life
// ***************************************
/datum/xeno_mutation/leveled/carrier/life_for_life
	required_ability_types = list(/datum/action/ability/xeno_action/spawn_hugger)
	conflicting_base_names = list("Oviposition")
	name = "Life for Life"
	desc = "Spawn Facehugger стоит 0 плазмы, перезарядка 70% от обычной, но наносит вам чистый урон."
	level_costs = list(10, 15, 20)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/carrier_life_for_life,
		/datum/status_effect/xeno_enhancement/carrier_life_for_life/two,
		/datum/status_effect/xeno_enhancement/carrier_life_for_life/three,
	)
	level_buff_descs = list(
		"Spawn Facehugger: 0 плазмы, перезарядка 70%, 50 урона вам.",
		"Spawn Facehugger: 0 плазмы, перезарядка 70%, 40 урона вам.",
		"Spawn Facehugger: 0 плазмы, перезарядка 70%, 30 урона вам.",
	)

/datum/status_effect/xeno_enhancement/carrier_life_for_life
	id = "enhancement_carrier_life_for_life"
	/// Per level, the damage dealt to the owner.
	var/list/damage_per_level = list(50, 40, 30)
	var/applied_cost = 0
	var/applied_cooldown = 0
	var/applied_damage = 0

/datum/status_effect/xeno_enhancement/carrier_life_for_life/two
	level = 2

/datum/status_effect/xeno_enhancement/carrier_life_for_life/three
	level = 3

/datum/status_effect/xeno_enhancement/carrier_life_for_life/apply_enhancement()
	var/datum/action/ability/xeno_action/spawn_hugger/hugger_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/spawn_hugger]
	if(!hugger_ability)
		return FALSE
	applied_cost = initial(hugger_ability.ability_cost)
	applied_cooldown = initial(hugger_ability.cooldown_duration) * 0.3
	applied_damage = get_level_value(damage_per_level)
	hugger_ability.ability_cost -= applied_cost
	hugger_ability.cooldown_duration -= applied_cooldown
	hugger_ability.health_cost += applied_damage
	return TRUE

/datum/status_effect/xeno_enhancement/carrier_life_for_life/remove_enhancement()
	var/datum/action/ability/xeno_action/spawn_hugger/hugger_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/spawn_hugger]
	if(hugger_ability)
		hugger_ability.ability_cost += applied_cost
		hugger_ability.cooldown_duration += applied_cooldown
		hugger_ability.health_cost -= applied_damage
	applied_cost = 0
	applied_cooldown = 0
	applied_damage = 0

// ***************************************
// *********** Claw Delivered
// ***************************************
/datum/xeno_mutation/leveled/carrier/claw_delivered
	required_ability_types = list(/datum/action/ability/xeno_action/lay_egg)
	name = "Claw Delivered"
	desc = "Huggers из ваших яиц быстрее прикрепляются к людям вручную."
	level_costs = list(10, 15, 20)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/carrier_claw_delivered,
		/datum/status_effect/xeno_enhancement/carrier_claw_delivered/two,
		/datum/status_effect/xeno_enhancement/carrier_claw_delivered/three,
	)
	level_buff_descs = list(
		"Время ручного прикрепления hugger из яиц: 60% от обычного.",
		"Время ручного прикрепления hugger из яиц: 50% от обычного.",
		"Время ручного прикрепления hugger из яиц: 40% от обычного.",
	)

/datum/status_effect/xeno_enhancement/carrier_claw_delivered
	id = "enhancement_carrier_claw_delivered"
	/// Per level, the multiplier added to the hand attach time (negative is faster).
	var/list/multiplier_per_level = list(-0.4, -0.5, -0.6)
	var/applied_multiplier = 0

/datum/status_effect/xeno_enhancement/carrier_claw_delivered/two
	level = 2

/datum/status_effect/xeno_enhancement/carrier_claw_delivered/three
	level = 3

/datum/status_effect/xeno_enhancement/carrier_claw_delivered/apply_enhancement()
	var/datum/action/ability/xeno_action/lay_egg/egg_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/lay_egg]
	if(!egg_ability)
		return FALSE
	applied_multiplier = get_level_value(multiplier_per_level)
	egg_ability.hand_attach_time_multiplier += applied_multiplier
	return TRUE

/datum/status_effect/xeno_enhancement/carrier_claw_delivered/remove_enhancement()
	var/datum/action/ability/xeno_action/lay_egg/egg_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/lay_egg]
	if(egg_ability)
		egg_ability.hand_attach_time_multiplier -= applied_multiplier
	applied_multiplier = 0

// ***************************************
// *********** Oviposition
// ***************************************
/datum/xeno_mutation/leveled/carrier/oviposition
	required_ability_types = list(/datum/action/ability/xeno_action/lay_egg)
	conflicting_base_names = list("Life for Life")
	name = "Oviposition"
	desc = "Lay Egg создаёт яйца с выбранным типом hugger внутри. Lay Egg стоит дешевле, а перезарядка 50%. Вы теряете способность Spawn Facehugger."
	level_costs = list(10, 15, 20)
	level_effect_types = list(
		/datum/status_effect/xeno_enhancement/carrier_oviposition,
		/datum/status_effect/xeno_enhancement/carrier_oviposition/two,
		/datum/status_effect/xeno_enhancement/carrier_oviposition/three,
	)
	level_buff_descs = list(
		"Lay Egg: выбранный hugger, цена 50% плазмы, перезарядка 50%. Нет Spawn Facehugger.",
		"Lay Egg: выбранный hugger, цена 40% плазмы, перезарядка 50%. Нет Spawn Facehugger.",
		"Lay Egg: выбранный hugger, цена 30% плазмы, перезарядка 50%. Нет Spawn Facehugger.",
	)

/datum/status_effect/xeno_enhancement/carrier_oviposition
	id = "enhancement_carrier_oviposition"
	/// Per level, the multiplier of the initial cost that is added to the cost of Lay Egg (negative is cheaper).
	var/list/multiplier_per_level = list(-0.5, -0.6, -0.7)
	var/applied_cost = 0
	var/applied_cooldown = 0

/datum/status_effect/xeno_enhancement/carrier_oviposition/two
	level = 2

/datum/status_effect/xeno_enhancement/carrier_oviposition/three
	level = 3

/datum/status_effect/xeno_enhancement/carrier_oviposition/apply_enhancement()
	var/datum/action/ability/xeno_action/lay_egg/egg_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/lay_egg]
	if(!egg_ability)
		return FALSE
	var/datum/action/ability/xeno_action/spawn_hugger/spawn_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/spawn_hugger]
	if(spawn_ability)
		spawn_ability.remove_action(xenomorph_owner)
	applied_cost = initial(egg_ability.ability_cost) * get_level_value(multiplier_per_level)
	applied_cooldown = initial(egg_ability.cooldown_duration) * 0.5
	egg_ability.use_selected_hugger = TRUE
	egg_ability.ability_cost += applied_cost
	egg_ability.cooldown_duration -= applied_cooldown
	return TRUE

/datum/status_effect/xeno_enhancement/carrier_oviposition/remove_enhancement()
	var/datum/action/ability/xeno_action/lay_egg/egg_ability = xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/lay_egg]
	if(egg_ability)
		egg_ability.use_selected_hugger = initial(egg_ability.use_selected_hugger)
		egg_ability.ability_cost -= applied_cost
		egg_ability.cooldown_duration += applied_cooldown
	applied_cost = 0
	applied_cooldown = 0
	// Level changes remove and apply the effect again, so Spawn Facehugger is only given back if it is still missing and no other level takes it away again.
	if(!xenomorph_owner.actions_by_path[/datum/action/ability/xeno_action/spawn_hugger])
		var/datum/action/ability/xeno_action/spawn_hugger/spawn_ability = new()
		spawn_ability.give_action(xenomorph_owner)
