/datum/unit_test/gunslinger/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/site = get_step(start, EAST)
	var/mob/living/carbon/human/engineer = allocate(/mob/living/carbon/human)
	engineer.faction = FACTION_TERRAGOV
	var/obj/machinery/marine_selector/gear/engi/vendor = allocate(/obj/machinery/marine_selector/gear/engi, run_loc_floor_top_right)
	TEST_ASSERT(vendor.listed_products[/obj/item/gunslinger], "The engineer vendor does not stock the Gunslinger.")
	var/obj/item/gunslinger/glove = allocate(/obj/item/gunslinger)
	TEST_ASSERT(engineer.put_in_active_hand(glove), "Could not equip the Gunslinger.")
	engineer.next_click = world.time - 1
	engineer.ClickOn(glove, start, "left=1")
	TEST_ASSERT(HAS_TRAIT(glove, TRAIT_NODROP), "Activating the Gunslinger should bind it to the hand.")
	TEST_ASSERT(!engineer.dropItemToGround(glove), "A bound Gunslinger could be dropped.")

	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack, engineer)
	var/obj/item/stack/sheet/metal/first = allocate(/obj/item/stack/sheet/metal, bag, 13)
	var/obj/item/stack/sheet/metal/ground_stack = allocate(/obj/item/stack/sheet/metal, start, 25)
	engineer.next_click = world.time - 1
	engineer.ClickOn(site, site, "right=1")
	TEST_ASSERT_NULL(glove.mini_sentry, "The Gunslinger built a sentry without enough metal.")
	TEST_ASSERT_EQUAL(first.get_amount(), 13, "A failed build took metal.")
	TEST_ASSERT_EQUAL(ground_stack.get_amount(), 25, "The Gunslinger must only use carried metal.")
	TEST_ASSERT(!engineer.do_actions, "An unaffordable deploy should not start a build.")

	var/obj/item/stack/sheet/metal/second = allocate(/obj/item/stack/sheet/metal, engineer, 16)
	engineer.next_click = world.time - 1
	engineer.ClickOn(site, site, "right=1")
	TEST_ASSERT_NULL(glove.mini_sentry, "Deployment should wait for the build action.")
	TEST_ASSERT(engineer.do_actions, "A valid deployment should start a timed action.")
	engineer.forceMove(get_step(start, NORTH))
	sleep(1.2 SECONDS)
	TEST_ASSERT_NULL(glove.mini_sentry, "Moving should cancel the build.")
	TEST_ASSERT_EQUAL(first.get_amount(), 13, "A cancelled build spent metal from the backpack.")
	TEST_ASSERT_EQUAL(second.get_amount(), 16, "A cancelled build spent carried metal.")
	engineer.forceMove(start)
	engineer.next_click = world.time - 1
	engineer.ClickOn(site, site, "right=1")
	sleep(1.2 SECONDS)
	var/obj/machinery/deployable/mounted/sentry/gunslinger/sentry = glove.mini_sentry
	TEST_ASSERT_NOTNULL(sentry, "Right-click did not deploy a sentry.")
	TEST_ASSERT_EQUAL(sentry.loc, site, "The sentry should be on the clicked turf.")
	TEST_ASSERT_EQUAL(sentry.iff_signal, TGMC_LOYALIST_IFF, "The sentry should use the engineer's IFF.")
	TEST_ASSERT(QDELETED(second), "Deployment should use the loose stack before opening the backpack.")
	TEST_ASSERT_EQUAL(first.get_amount(), 4, "Deployment should consume exactly 25 sheets across stacks.")
	var/obj/item/weapon/gun/gun = sentry.get_internal_item()
	TEST_ASSERT_EQUAL(gun.rounds, 100, "The initial build should have a full magazine.")
	TEST_ASSERT_EQUAL(gun.loc, sentry, "The gun should fire from inside the sentry.")
	var/obj/item/ammo_magazine/magazine = gun.chamber_items[1]
	magazine.current_rounds = 0
	QDEL_NULL(gun.in_chamber)
	gun.update_ammo_count()
	sentry.take_damage(30, effects = FALSE)

	var/turf/ally_site = get_step(site, NORTH)
	var/mob/living/carbon/human/ally = allocate(/mob/living/carbon/human, ally_site)
	ally.faction = FACTION_TERRAGOV
	var/obj/item/gunslinger/ally_glove = allocate(/obj/item/gunslinger, ally_site)
	TEST_ASSERT(ally.put_in_active_hand(ally_glove), "Could not equip the ally's Gunslinger.")
	ally.next_click = world.time - 1
	ally.ClickOn(ally_glove, ally_site, "left=1")
	var/obj/item/stack/sheet/metal/ally_metal = allocate(/obj/item/stack/sheet/metal, ally, 2)
	ally.next_click = world.time - 1
	ally.ClickOn(sentry, site, "left=1")
	TEST_ASSERT_EQUAL(sentry.obj_integrity, 90, "An allied Gunslinger should repair another player's sentry.")
	TEST_ASSERT_EQUAL(gun.rounds, 20, "A service hit should refill the built-in magazine.")
	TEST_ASSERT(gun.in_chamber, "Servicing an empty sentry should chamber a round.")
	TEST_ASSERT_EQUAL(ally_metal.get_amount(), 1, "An allied service hit should consume the repairer's metal.")
	TEST_ASSERT_EQUAL(first.get_amount(), 4, "An allied service hit must not consume the owner's metal.")

	engineer.next_click = world.time - 1
	engineer.ClickOn(site, site, "right=1")
	TEST_ASSERT(QDELETED(sentry) && QDELETED(gun), "Recall should remove the sentry and its gun.")
	TEST_ASSERT_NULL(glove.mini_sentry, "Recall should free the deployment slot.")
	TEST_ASSERT_EQUAL(first.get_amount(), 17, "90% integrity and 20% ammunition should refund 13 sheets.")
	TEST_ASSERT(locate(/obj/effect/temp_visual/explosion) in site, "Recall should show an explosion at the sentry's tile.")

	allocate(/obj/item/stack/sheet/metal, engineer, 10)
	engineer.next_click = world.time - 1
	engineer.ClickOn(site, site, "right=1")
	sleep(1.2 SECONDS)
	sentry = glove.mini_sentry
	TEST_ASSERT_NOTNULL(sentry, "The sentry should redeploy after recall.")
	gun = sentry.get_internal_item()
	TEST_ASSERT_EQUAL(sentry.obj_integrity, 100, "The newly built sentry should have full integrity.")
	TEST_ASSERT_EQUAL(gun.rounds, 100, "The newly built sentry should have a full magazine.")
	engineer.next_click = world.time - 1
	engineer.ClickOn(site, site, "right=1")
	TEST_ASSERT_EQUAL(first.get_amount(), 27, "Recall at full integrity and ammo should refund all 25 sheets.")

	engineer.next_click = world.time - 1
	engineer.ClickOn(site, site, "right=1")
	sleep(1.2 SECONDS)
	sentry = glove.mini_sentry
	TEST_ASSERT_NOTNULL(sentry, "Full refund should allow another build.")
	gun = sentry.get_internal_item()
	TEST_ASSERT(!sentry.scan(), "The sentry should ignore the nearby engineer.")
	var/turf/hostile_site = get_step(site, EAST)
	var/mob/living/carbon/xenomorph/drone/hostile = allocate(/mob/living/carbon/xenomorph/drone, hostile_site)
	TEST_ASSERT(sentry.scan(), "The sentry should detect a nearby xenomorph.")
	TEST_ASSERT_EQUAL(sentry.get_target(), hostile, "The sentry should select the xenomorph as its target.")
	engineer.forceMove(site)
	engineer.next_click = world.time - 1
	engineer.ClickOn(hostile, hostile_site, "left=1")
	TEST_ASSERT_EQUAL(hostile.AmountStaggered(), 1 SECONDS, "A melee hit should stagger the target for one second.")
	TEST_ASSERT_EQUAL(hostile.IsSlowed(), XENO_SLOWDOWN_REGEN, "A melee hit should apply one tick of standard slowdown.")
	hostile.handle_slowdown()
	TEST_ASSERT(!hostile.IsSlowed(), "Standard slowdown recovery should clear the penalty.")
	sentry.sentry_start_fire()
	sleep(1 SECONDS)
	TEST_ASSERT(gun.rounds < 100, "The sentry should fire using the built-in magazine.")
	qdel(sentry)
	TEST_ASSERT_NULL(glove.mini_sentry, "Destruction should free the deployment slot.")
	TEST_ASSERT_EQUAL(first.get_amount(), 2, "A destroyed sentry should not refund metal.")
