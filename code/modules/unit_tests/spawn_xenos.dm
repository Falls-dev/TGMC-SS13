/datum/unit_test/spawn_xenos/Run()
	var/list/mob/living/carbon/xenomorph/xenos = list()
	GLOB.xeno_stat_multiplicator_buff = 1
	for(var/castetype in GLOB.xeno_caste_datums)
		var/xeno_type = GLOB.xeno_caste_datums[castetype][XENO_UPGRADE_BASETYPE].caste_type_path
		xenos += allocate(xeno_type)

	sleep(1 SECONDS)

	for(var/mob/living/carbon/xenomorph/X AS in xenos)
		X.upgrade_xeno(X.upgrade_next())

	sleep(1 SECONDS)

/datum/unit_test/dragun_rifle/Run()
	var/mob/living/carbon/xenomorph/dragun/dragun = allocate(/mob/living/carbon/xenomorph/dragun)
	var/obj/item/weapon/gun/dragun/rifle = dragun.hand_dragun
	TEST_ASSERT(rifle && dragun.get_active_held_item() == rifle, "Dragun must spawn holding its integrated rifle.")
	TEST_ASSERT(!dragun.dropItemToGround(rifle), "The integrated rifle must not be droppable.")
	TEST_ASSERT(!rifle.able_to_fire(dragun), "The rifle must not fire one-handed.")
	TEST_ASSERT_NULL(rifle.make_worn_icon(), "The lowered rifle must not overlay the body.")
	TEST_ASSERT(rifle.make_worn_icon(null, SLOT_L_HAND, TRUE), "The rifle must retain its hand inventory icon.")
	TEST_ASSERT_EQUAL(rifle.icon, 'icons/Xeno/dragun_item.dmi', "The HUD must use the canonical item sprites.")
	TEST_ASSERT_EQUAL(rifle.ammo_datum_type, /datum/ammo/xeno/acid, "The rifle must fire acid.")
	TEST_ASSERT_EQUAL(rifle.force, 75, "The integrated rifle blade must deal 75 melee damage.")
	TEST_ASSERT_NULL(rifle.muzzle_flash, "The integrated rifle must not create a muzzle flash.")
	rifle.wield_delay = 0
	rifle.wield_penalty = 0
	rifle.wield(dragun)
	TEST_ASSERT(istype(dragun.get_inactive_held_item(), /obj/item/weapon/twohanded/offhand), "Wielding must occupy the other hand.")
	TEST_ASSERT_EQUAL(dragun.icon_state, "Dragun Up Gun", "Wielding must raise the body sprite.")
	TEST_ASSERT_NULL(rifle.make_worn_icon(), "The raised rifle must not overlay the body.")
	TEST_ASSERT(rifle.make_worn_icon(null, SLOT_L_HAND, TRUE), "The raised rifle must retain its hand inventory icon.")
	TEST_ASSERT_EQUAL(rifle.icon_state, "hand_dragun", "Wielding must retain the HUD icon.")
	dragun.set_plasma(0)
	TEST_ASSERT(!rifle.able_to_fire(dragun), "The rifle must not fire without plasma.")
	dragun.set_plasma(100)
	TEST_ASSERT(rifle.able_to_fire(dragun), "A wielded rifle with plasma must be able to fire.")
	rifle.last_fired = world.time - rifle.fire_delay
	TEST_ASSERT(!rifle.gun_on_cooldown(dragun), "The rifle cooldown must expire for a xeno without human signals.")
	var/turf/target = get_step(dragun, EAST)
	rifle.start_fire(dragun, target, target, null, null, TRUE)
	TEST_ASSERT_EQUAL(dragun.plasma_stored, 100 - rifle.plasma_cost, "One shot must spend exactly one plasma charge.")
	TEST_ASSERT(rifle.gun_on_cooldown(dragun), "A shot must start the rifle cooldown.")
	rifle.start_fire(dragun, target, target, null, null, TRUE)
	TEST_ASSERT_EQUAL(dragun.plasma_stored, 100 - rifle.plasma_cost, "A click during cooldown must not fire again.")
	rifle.last_fired = world.time - rifle.fire_delay
	TEST_ASSERT(!rifle.gun_on_cooldown(dragun), "The cooldown must expire after firing too.")
	rifle.unwield(dragun)
	TEST_ASSERT(!dragun.get_inactive_held_item(), "Unwielding must release the second hand.")
	TEST_ASSERT(dragun.icon_state != "Dragun Up Gun", "Unwielding must restore the normal body sprite.")

/datum/unit_test/dragun_rifle_melee/Run()
	var/mob/living/carbon/xenomorph/dragun/dragun = allocate(/mob/living/carbon/xenomorph/dragun)
	var/mob/living/carbon/xenomorph/runner/ally = allocate(/mob/living/carbon/xenomorph/runner)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/obj/item/weapon/gun/dragun/rifle = dragun.hand_dragun
	dragun.a_intent = INTENT_HARM
	var/ally_health = ally.health
	rifle.melee_attack_chain(dragun, ally, null, FALSE)
	TEST_ASSERT_EQUAL(ally.health, ally_health, "The integrated blade must not damage a same-hive xeno on harm intent.")
	TEST_ASSERT(ally.issamexenohive(rifle), "Projectiles fired from the integrated rifle must retain the owner's hive protection.")
	dragun.a_intent = INTENT_HELP
	var/victim_health = victim.health
	rifle.melee_attack_chain(dragun, victim, null, FALSE)
	TEST_ASSERT_EQUAL(victim.health, victim_health, "The integrated blade must respect help intent.")
	dragun.a_intent = INTENT_HARM
	ADD_TRAIT(dragun, TRAIT_HANDS_BLOCKED, TRAIT_GENERIC)
	rifle.melee_attack_chain(dragun, victim, null, FALSE)
	TEST_ASSERT_EQUAL(victim.health, victim_health, "Blocked hands must prevent integrated blade attacks.")
	REMOVE_TRAIT(dragun, TRAIT_HANDS_BLOCKED, TRAIT_GENERIC)
	rifle.melee_attack_chain(dragun, victim, null, FALSE)
	TEST_ASSERT(victim.health < victim_health, "The integrated blade must still damage an unprotected enemy on harm intent.")

/datum/unit_test/dragun_bite/Run()
	var/mob/living/carbon/xenomorph/dragun/dragun = allocate(/mob/living/carbon/xenomorph/dragun)
	var/datum/action/ability/activable/xeno/dragun_bite/bite = dragun.actions_by_path[/datum/action/ability/activable/xeno/dragun_bite]
	TEST_ASSERT(bite, "Dragun must have Bite.")
	TEST_ASSERT("Dragun bite" in icon_states(dragun.icon), "The bite animation must exist.")
	bite.select()
	var/turf/destination = get_step(dragun, EAST)
	dragun.set_plasma(249)
	TEST_ASSERT(!bite.can_use_ability(destination, TRUE), "Bite must require 250 plasma.")
	dragun.set_plasma(300)
	bite.charging = TRUE
	bite.bite_destination = destination
	var/generation = bite.charge_generation
	bite.release_charge()
	TEST_ASSERT(!bite.charge_valid(generation), "Mouse release must invalidate preparation.")
	TEST_ASSERT_EQUAL(dragun.plasma_stored, 300, "Cancelled preparation must not spend plasma.")
	TEST_ASSERT(bite.action_COOLDOWN_FINISHED(), "Cancelled preparation must not start cooldown.")
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	victim.status_flags |= GODMODE
	TEST_ASSERT(!bite.apply_bite(victim), "Bite must not harm protected targets.")
	var/datum/limb/chest = victim.get_limb(BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(length(chest.wounds), 0, "Rejected bites must not add bleeding.")
	victim.status_flags &= ~GODMODE
	var/health_before = victim.health
	TEST_ASSERT(bite.apply_bite(victim), "Bite must hit an unprotected human.")
	TEST_ASSERT(victim.health < health_before, "Bite must deal damage through the alien attack path.")
	var/found_bleeding = FALSE
	for(var/datum/wound/internal_bleeding/wound in chest.wounds)
		if(wound.damage == 3)
			found_bleeding = TRUE
	TEST_ASSERT(found_bleeding, "A successful bite must add strength-3 internal bleeding.")
	bite.clean_bite()
	TEST_ASSERT(!dragun.biting && !bite.bite_victim && !bite.leaping, "Bite cleanup must release its state.")

/datum/unit_test/dragun_rifle_charge/Run()
	var/mob/living/carbon/xenomorph/dragun/dragun = allocate(/mob/living/carbon/xenomorph/dragun)
	var/obj/item/weapon/gun/dragun/rifle = dragun.hand_dragun
	var/datum/action/ability/xeno_action/dragun_charge/charge = dragun.actions_by_path[/datum/action/ability/xeno_action/dragun_charge]
	TEST_ASSERT_EQUAL(charge.max_charge(), 3, "Normal Dragun must have three charge levels.")
	for(var/level in 0 to 5)
		rifle.charge_level = level
		TEST_ASSERT_EQUAL(rifle.get_shot_cost(), 25, "Shot cost must stay at base cost after paying for charge levels.")
	rifle.reset_charge()
	dragun.set_plasma(300)
	charge.action_activate()
	TEST_ASSERT_EQUAL(rifle.charge_level, 1, "One click must add exactly one level.")
	TEST_ASSERT_EQUAL(dragun.plasma_stored, 275, "First charge must cost 25 plasma immediately.")
	charge.action_activate()
	TEST_ASSERT_EQUAL(dragun.plasma_stored, 225, "Second charge must cost 50 plasma.")
	dragun.set_plasma(99)
	charge.action_activate()
	TEST_ASSERT_EQUAL(rifle.charge_level, 2, "Insufficient plasma must preserve the charge level.")
	TEST_ASSERT_EQUAL(dragun.plasma_stored, 99, "Rejected charging must not spend plasma.")
	dragun.set_plasma(100)
	charge.action_activate()
	TEST_ASSERT_EQUAL(rifle.charge_level, 3, "Third charge must be reachable with 100 plasma.")
	TEST_ASSERT_EQUAL(dragun.plasma_stored, 0, "Third charge must cost 100 plasma.")
	charge.action_activate()
	TEST_ASSERT_EQUAL(rifle.charge_level, 3, "Charging must not exceed the caste cap.")
	rifle.reset_charge()
	TEST_ASSERT_EQUAL(charge.action_icon_state, "0_3", "Reset must restore the normal uncharged icon.")
	var/mob/living/carbon/xenomorph/dragun/primordial/primo = allocate(/mob/living/carbon/xenomorph/dragun/primordial)
	var/datum/action/ability/xeno_action/dragun_charge/primo_charge = primo.actions_by_path[/datum/action/ability/xeno_action/dragun_charge]
	TEST_ASSERT_EQUAL(primo_charge.max_charge(), 5, "Primordial Dragun must have five charge levels.")
	TEST_ASSERT_EQUAL(primo.xeno_caste.plasma_max, 400, "Primordial Dragun must have 400 maximum plasma.")
	primo.hand_dragun.reset_charge()
	TEST_ASSERT_EQUAL(primo_charge.action_icon_state, "0_5", "Primordial reset must use the five-level icon.")

/datum/unit_test/dragun_live_ammunition/Run()
	var/mob/living/carbon/xenomorph/dragun/dragun = allocate(/mob/living/carbon/xenomorph/dragun)
	var/obj/item/weapon/gun/dragun/rifle = dragun.hand_dragun
	var/datum/action/ability/xeno_action/dragun_create_live/create = dragun.actions_by_path[/datum/action/ability/xeno_action/dragun_create_live]
	var/datum/action/ability/xeno_action/dragun_aim/aim = dragun.actions_by_path[/datum/action/ability/xeno_action/dragun_aim]
	var/datum/action/ability/xeno_action/dragun_charge/charge = dragun.actions_by_path[/datum/action/ability/xeno_action/dragun_charge]
	create.action_activate()
	TEST_ASSERT_EQUAL(rifle.live_rounds, 0, "Crafting without a held bone must fail.")
	var/obj/item/stack/dragun_bone/bones = allocate(/obj/item/stack/dragun_bone, get_turf(dragun), 2)
	dragun.put_in_hands(bones)
	rifle.charge_level = 1
	create.action_activate()
	TEST_ASSERT_EQUAL(bones.amount, 2, "Crafting must not consume bones while acid is charged.")
	rifle.reset_charge()
	create.action_activate()
	TEST_ASSERT_EQUAL(rifle.live_rounds, 3, "One bone must produce three Live rounds.")
	TEST_ASSERT_EQUAL(bones.amount, 1, "Crafting must consume exactly one bone.")
	TEST_ASSERT_EQUAL(rifle.get_shot_cost(), 0, "Live mode must cost no plasma.")
	create.action_activate()
	TEST_ASSERT_EQUAL(bones.amount, 1, "A loaded magazine must reject more bones.")
	aim.action_activate()
	TEST_ASSERT_EQUAL(rifle.get_shot_cost(), 25, "Acid mode must retain its plasma cost.")
	TEST_ASSERT_EQUAL(rifle.live_rounds, 3, "Switching modes must preserve ammunition.")
	dragun.set_plasma(300)
	charge.action_activate()
	TEST_ASSERT_EQUAL(rifle.charge_level, 0, "Loaded Live must block charging even in acid mode.")
	TEST_ASSERT_EQUAL(dragun.plasma_stored, 300, "Rejected charging must not spend plasma.")
	var/datum/ammo/live = GLOB.ammo_list[/datum/ammo/xeno/acid/heavy/passthrough/dragun_live]
	TEST_ASSERT_EQUAL(live.damage, 27, "Live must deal 27 base damage.")
	TEST_ASSERT(live.ammo_behavior_flags & AMMO_SPECIAL_PROCESS, "Live must process guidance during flight.")

/datum/unit_test/dragun_bone_storage/Run()
	var/mob/living/carbon/xenomorph/dragun/dragun = allocate(/mob/living/carbon/xenomorph/dragun)
	var/datum/action/ability/xeno_action/dragun_hide_bone/hide = dragun.actions_by_path[/datum/action/ability/xeno_action/dragun_hide_bone]
	var/obj/item/stack/dragun_bone/bones = allocate(/obj/item/stack/dragun_bone, get_turf(dragun), 7)
	dragun.put_in_hands(bones)
	hide.action_activate()
	TEST_ASSERT_EQUAL(dragun.stored_bones, 5, "Internal storage must accept five bones.")
	TEST_ASSERT_EQUAL(bones.amount, 2, "Storing bones must preserve the excess in hand.")
	hide.action_activate()
	TEST_ASSERT_EQUAL(bones.amount, 2, "Full storage must not consume more bones.")
	dragun.dropItemToGround(bones)
	hide.action_activate()
	TEST_ASSERT_EQUAL(dragun.stored_bones, 0, "Retrieving bones must empty internal storage.")
	var/obj/item/stack/dragun_bone/retrieved = dragun.get_inactive_held_item()
	if(!istype(retrieved))
		retrieved = dragun.get_active_held_item()
	TEST_ASSERT(istype(retrieved), "Retrieved bones must be placed in a hand.")
	TEST_ASSERT_EQUAL(retrieved.amount, 5, "Retrieving must preserve the stored amount.")
	hide.action_activate()
	dragun.death()
	TEST_ASSERT_EQUAL(dragun.stored_bones, 0, "Death must clear the internal bone reserve.")
	var/total_bones = 0
	for(var/obj/item/stack/dragun_bone/dropped in get_turf(dragun))
		total_bones += dropped.amount
	TEST_ASSERT_EQUAL(total_bones, 7, "Death must drop stored bones without losing or duplicating the original seven bones.")

/datum/unit_test/dragun_healing_balance/Run()
	var/mob/living/carbon/xenomorph/dragun/dragun = allocate(/mob/living/carbon/xenomorph/dragun)
	dragun.adjust_brute_loss(200)
	dragun.adjust_fire_loss(100)
	TEST_ASSERT_EQUAL(dragun.get_brute_loss(), 200, "The healing penalty must not reduce incoming damage.")
	dragun.adjust_brute_loss(-40)
	dragun.adjust_fire_loss(-40)
	TEST_ASSERT_EQUAL(dragun.get_brute_loss(), 180, "Direct brute healing must be halved.")
	TEST_ASSERT_EQUAL(dragun.get_fire_loss(), 80, "Direct burn healing must be halved.")
	dragun.heal_xeno_damage(200, TRUE)
	TEST_ASSERT_EQUAL(dragun.get_fire_loss(), 0, "Passive healing must clear burns within its halved budget.")
	TEST_ASSERT_EQUAL(dragun.get_brute_loss(), 160, "Unused passive healing must carry over to brute without a second penalty.")
	dragun.adjust_fire_loss(100)
	var/obj/item/stack/dragun_bone/bones = allocate(/obj/item/stack/dragun_bone, get_turf(dragun), 6)
	dragun.put_in_hands(bones)
	var/datum/action/ability/xeno_action/dragun_heal_bone/heal = dragun.actions_by_path[/datum/action/ability/xeno_action/dragun_heal_bone]
	heal.action_activate()
	TEST_ASSERT_EQUAL(bones.amount, 1, "Bone healing must consume five bones.")
	TEST_ASSERT_EQUAL(dragun.get_brute_loss() + dragun.get_fire_loss(), 35, "Bone healing must restore exactly 225 HP, not full health or 112.5 HP.")
	dragun.adjust_brute_loss(-20)
	TEST_ASSERT_EQUAL(dragun.get_brute_loss(), 25, "The normal healing penalty must resume after bone healing.")
	dragun.heal_from_bones()
	TEST_ASSERT_EQUAL(dragun.health, dragun.maxHealth, "Bone healing must stop at maximum health.")

/datum/unit_test/dragun_bite_landing/Run()
	var/mob/living/carbon/xenomorph/dragun/dragun = allocate(/mob/living/carbon/xenomorph/dragun)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/datum/action/ability/activable/xeno/dragun_bite/bite = dragun.actions_by_path[/datum/action/ability/activable/xeno/dragun_bite]
	victim.forceMove(get_turf(dragun))
	bite.bite_destination = get_turf(victim)
	bite.leaping = TRUE
	dragun.xeno_flags |= XENO_LEAPING
	var/health_before = victim.health
	bite.bite_landed()
	TEST_ASSERT(victim.health < health_before, "Landing on the victim's tile must immediately bite without grabbing.")
	TEST_ASSERT(!dragun.pulling, "Bite must not start pulling its victim.")
	TEST_ASSERT(dragun.biting, "A successful impact must play the bite animation.")
	TEST_ASSERT(!(dragun.xeno_flags & XENO_LEAPING), "Landing must clear the leap flag.")
	var/health_after = victim.health
	bite.bite_landed()
	TEST_ASSERT_EQUAL(victim.health, health_after, "A repeated landing signal must not bite twice.")
	bite.clean_bite()
