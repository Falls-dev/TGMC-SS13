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
