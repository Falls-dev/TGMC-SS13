// =============================================================================
// Star Wars ERT outfits
// Factions: Rebels (CLF/dutch) | Clones (distress/imperial) | Empire (VSD) | Guards (distress)
// Guns: Rebels = TGMC lasguns | Clones/Stormtroopers = plasma
// NOTE: belt_contents / suit_contents / backpack_contents ONLY on leaf outfits
//       (spawn_humans unit-tests every /datum/outfit/job subtype, including parents)
// =============================================================================

/datum/outfit/job/sw/ert
	id = /obj/item/card/id/silver
	ears = /obj/item/radio/headset/distress
	shoes = /obj/item/clothing/shoes/marine
	gloves = /obj/item/clothing/gloves/marine
	mask = /obj/item/clothing/mask/gas
	back = /obj/item/storage/backpack/lightpack
	r_pocket = /obj/item/storage/pouch/medical_injectors/firstaid
	l_pocket = /obj/item/storage/pouch/grenade/standard

// -----------------------------------------------------------------------------
// 1) REBELS — CLF-like loot, LASGUNS (not plasma)
// -----------------------------------------------------------------------------

/datum/outfit/job/sw/ert/rebel
	ears = /obj/item/radio/headset/distress/dutch
	// leaf outfits add clothing / contents

/datum/outfit/job/sw/ert/rebel/trooper_mlaser
	name = "Rebel Trooper (Mlaser)"
	jobtype = /datum/job/sw/ert/rebel
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/rebel
	wear_suit = /obj/item/clothing/suit/storage/faction/militia/rebel
	head = /obj/item/clothing/head/helmet/marine/sw/rebel
	belt = /obj/item/storage/belt/marine
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/standard_marine_mlaser/patrol
	belt_contents = list(
		/obj/item/cell/lasgun/lasrifle = 6,
	)
	backpack_contents = list(
		/obj/item/storage/box/mre = 1,
		/obj/item/storage/box/m94 = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/radio = 1,
		/obj/item/explosive/grenade/incendiary/molotov = 2,
		/obj/item/cell/lasgun/lasrifle = 2,
	)
	suit_contents = list(
		/obj/item/explosive/grenade/stick = 2,
	)

/datum/outfit/job/sw/ert/rebel/trooper_carbine
	name = "Rebel Trooper (Carbine)"
	jobtype = /datum/job/sw/ert/rebel
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/rebel
	wear_suit = /obj/item/clothing/suit/storage/faction/militia/rebel
	head = /obj/item/clothing/head/helmet/marine/sw/rebel
	belt = /obj/item/storage/belt/marine
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/standard_marine_carbine/gyro
	belt_contents = list(
		/obj/item/cell/lasgun/lasrifle = 6,
	)
	backpack_contents = list(
		/obj/item/storage/box/mre = 1,
		/obj/item/storage/box/m94 = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/radio = 1,
		/obj/item/explosive/grenade/incendiary/molotov = 2,
		/obj/item/cell/lasgun/lasrifle = 2,
	)
	suit_contents = list(
		/obj/item/explosive/grenade/stick = 2,
	)

/datum/outfit/job/sw/ert/rebel/trooper_sniper
	name = "Rebel Trooper (Sniper)"
	jobtype = /datum/job/sw/ert/rebel
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/rebel
	wear_suit = /obj/item/clothing/suit/storage/faction/militia/rebel
	head = /obj/item/clothing/head/helmet/marine/sw/rebel
	belt = /obj/item/storage/belt/marine
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/standard_marine_sniper/beginner
	belt_contents = list(
		/obj/item/cell/lasgun/lasrifle = 6,
	)
	backpack_contents = list(
		/obj/item/storage/box/mre = 1,
		/obj/item/storage/box/m94 = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/radio = 1,
		/obj/item/explosive/grenade/incendiary/molotov = 2,
		/obj/item/binoculars = 1,
		/obj/item/cell/lasgun/lasrifle = 1,
	)
	suit_contents = list(
		/obj/item/explosive/grenade/stick = 2,
	)

/datum/outfit/job/sw/ert/rebel/medic
	name = "Rebel Medic"
	jobtype = /datum/job/sw/ert/rebel/medic
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/rebel
	wear_suit = /obj/item/clothing/suit/storage/faction/militia/rebel
	head = /obj/item/clothing/head/helmet/marine/sw/rebel
	glasses = /obj/item/clothing/glasses/hud/health
	belt = /obj/item/storage/belt/lifesaver/full
	l_pocket = /obj/item/storage/holster/flarepouch
	r_pocket = /obj/item/storage/pouch/medical_injectors/medic
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/standard_marine_carbine/gyro
	r_hand = /obj/item/defibrillator
	backpack_contents = list(
		/obj/item/storage/box/mre = 1,
		/obj/item/storage/box/m94 = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/radio = 1,
		/obj/item/roller = 1,
		/obj/item/explosive/grenade/incendiary/molotov = 1,
		/obj/item/cell/lasgun/lasrifle = 3,
	)
	suit_contents = list(
		/obj/item/explosive/grenade/stick = 2,
	)

/datum/outfit/job/sw/ert/rebel/officer
	name = "Rebel Officer"
	jobtype = /datum/job/sw/ert/rebel/officer
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/rebel/officer
	wear_suit = /obj/item/clothing/suit/storage/faction/militia/rebel/officer
	head = /obj/item/clothing/head/helmet/marine/sw/rebel/black
	belt = /obj/item/storage/belt/marine
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/standard_marine_sniper/beginner
	belt_contents = list(
		/obj/item/cell/lasgun/lasrifle = 6,
	)
	backpack_contents = list(
		/obj/item/storage/box/mre = 1,
		/obj/item/storage/box/m94 = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/radio = 1,
		/obj/item/binoculars = 1,
		/obj/item/explosive/grenade/incendiary/molotov = 2,
		/obj/item/explosive/plastique = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/combat_advanced = 1,
		/obj/item/cell/lasgun/lasrifle = 1,
	)
	suit_contents = list(
		/obj/item/explosive/grenade/stick = 2,
	)

// -----------------------------------------------------------------------------
// 2) CLONE BASIC — phase I
// -----------------------------------------------------------------------------

/datum/outfit/job/sw/ert/clone
	ears = /obj/item/radio/headset/distress
	// leaf outfits add clothing / contents

/datum/outfit/job/sw/ert/clone/trooper
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/repofficer_ensign
	wear_suit = /obj/item/clothing/suit/storage/marine/clone
	head = /obj/item/clothing/head/helmet/marine/sw/clone/phase1
	belt = /obj/item/storage/belt/marine
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard

/datum/outfit/job/sw/ert/clone/trooper/marine
	name = "Clone Trooper (Marine)"
	jobtype = /datum/job/sw/ert/clone/trooper
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/grenade = 2,
		/obj/item/storage/box/m94 = 1,
		/obj/item/cell/lasgun/plasma = 2,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/quickclot = 1,
	)

/datum/outfit/job/sw/ert/clone/trooper/infantryman
	name = "Clone Trooper (Infantryman)"
	jobtype = /datum/job/sw/ert/clone/trooper
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/grenade = 3,
		/obj/item/explosive/plastique = 2,
		/obj/item/stack/sheet/metal/medium_stack = 1,
		/obj/item/storage/box/m94 = 1,
		/obj/item/cell/lasgun/plasma = 1,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/dylovene = 1,
	)

/datum/outfit/job/sw/ert/clone/engineer
	name = "Clone Trooper Engineer"
	jobtype = /datum/job/sw/ert/clone/engineer
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/repofficer_ensign
	wear_suit = /obj/item/clothing/suit/storage/marine/clone
	head = /obj/item/clothing/head/helmet/marine/sw/clone/engineer
	glasses = /obj/item/clothing/glasses/meson
	gloves = /obj/item/clothing/gloves/marine/insulated
	belt = /obj/item/storage/belt/marine
	l_pocket = /obj/item/storage/pouch/tools/full
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/tool/extinguisher = 1,
		/obj/item/assembly/signaler = 1,
		/obj/item/explosive/plastique/detpack = 2,
		/obj/item/explosive/plastique = 2,
		/obj/item/stack/sheet/metal/large_stack = 1,
		/obj/item/stack/sheet/plasteel/medium_stack = 1,
		/obj/item/stack/barbed_wire/half_stack = 1,
		/obj/item/stack/cable_coil = 1,
		/obj/item/storage/box/mre = 1,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/dylovene = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/combat_advanced = 1,
	)

/datum/outfit/job/sw/ert/clone/mp
	name = "Clone Military Police"
	jobtype = /datum/job/sw/ert/clone/mp
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/repofficer_ensign
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/mp
	head = /obj/item/clothing/head/helmet/marine/sw/clone/mp
	glasses = /obj/item/clothing/glasses/meson
	belt = /obj/item/storage/belt/marine
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/plastique = 5,
		/obj/item/stack/sheet/metal/medium_stack = 1,
		/obj/item/explosive/grenade = 2,
		/obj/item/cell/lasgun/plasma = 1,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/quickclot = 1,
	)

/datum/outfit/job/sw/ert/clone/pilot
	name = "Clone Pilot Medic"
	jobtype = /datum/job/sw/ert/clone/pilot
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/repofficer_medical
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/pilot
	head = /obj/item/clothing/head/helmet/marine/sw/clone/pilot
	glasses = /obj/item/clothing/glasses/hud/health
	belt = /obj/item/storage/belt/lifesaver/full
	r_pocket = /obj/item/storage/pouch/medical_injectors/medic
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/smg/standard
	backpack_contents = list(
		/obj/item/defibrillator = 1,
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/roller = 1,
		/obj/item/cell/lasgun/plasma = 4,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/oxycodone = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/russian_red = 1,
	)

/datum/outfit/job/sw/ert/clone/lieutenant
	name = "Clone Lieutenant"
	jobtype = /datum/job/sw/ert/clone/lieutenant
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/repofficer_ensign
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/lieutenant
	head = /obj/item/clothing/head/helmet/marine/sw/clone/lt
	glasses = /obj/item/clothing/glasses/hud/health
	belt = /obj/item/storage/belt/marine
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/binoculars = 1,
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/plastique = 2,
		/obj/item/reagent_containers/hypospray/autoinjector/combat_advanced = 2,
		/obj/item/reagent_containers/hypospray/autoinjector/russian_red = 1,
		/obj/item/cell/lasgun/plasma = 2,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/quickclot = 1,
	)

// -----------------------------------------------------------------------------
// 3) CLONE MK.II — phase II / reinforced
// -----------------------------------------------------------------------------

/datum/outfit/job/sw/ert/clone_mk2
	ears = /obj/item/radio/headset/distress

/datum/outfit/job/sw/ert/clone_mk2/trooper
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/repofficer_ensign
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/reinforced
	head = /obj/item/clothing/head/helmet/marine/sw/clone/phase2
	belt = /obj/item/storage/belt/marine
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard

/datum/outfit/job/sw/ert/clone_mk2/trooper/marine
	name = "Clone Reinforced Trooper (Marine)"
	jobtype = /datum/job/sw/ert/clone_mk2/trooper
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/grenade = 2,
		/obj/item/storage/box/m94 = 1,
		/obj/item/cell/lasgun/plasma = 2,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/quickclot = 1,
	)

/datum/outfit/job/sw/ert/clone_mk2/trooper/infantryman
	name = "Clone Reinforced Trooper (Infantryman)"
	jobtype = /datum/job/sw/ert/clone_mk2/trooper
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/grenade = 3,
		/obj/item/explosive/plastique = 2,
		/obj/item/stack/sheet/metal/medium_stack = 1,
		/obj/item/storage/box/m94 = 1,
		/obj/item/cell/lasgun/plasma = 1,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/dylovene = 1,
	)

/datum/outfit/job/sw/ert/clone_mk2/artillery
	name = "Clone Artillery Engineer"
	jobtype = /datum/job/sw/ert/clone_mk2/artillery
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/repofficer_ensign
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/reinforced
	head = /obj/item/clothing/head/helmet/marine/sw/clone/artillery
	glasses = /obj/item/clothing/glasses/meson
	gloves = /obj/item/clothing/gloves/marine/insulated
	belt = /obj/item/storage/belt/marine
	l_pocket = /obj/item/storage/pouch/tools/full
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/tool/extinguisher = 1,
		/obj/item/assembly/signaler = 1,
		/obj/item/explosive/plastique/detpack = 4,
		/obj/item/explosive/plastique = 2,
		/obj/item/stack/sheet/metal/large_stack = 1,
		/obj/item/stack/cable_coil = 1,
		/obj/item/storage/box/mre = 1,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/dylovene = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/combat_advanced = 1,
	)

/datum/outfit/job/sw/ert/clone_mk2/mp
	name = "Clone Military Police Phase II"
	jobtype = /datum/job/sw/ert/clone_mk2/mp
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/repofficer_ensign
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/mp/phase2
	head = /obj/item/clothing/head/helmet/marine/sw/clone/mp
	glasses = /obj/item/clothing/glasses/meson
	belt = /obj/item/storage/belt/marine
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/plastique = 5,
		/obj/item/stack/sheet/metal/medium_stack = 1,
		/obj/item/explosive/grenade = 2,
		/obj/item/cell/lasgun/plasma = 1,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/quickclot = 1,
	)

/datum/outfit/job/sw/ert/clone_mk2/sgt
	name = "Clone Sergeant Medic"
	jobtype = /datum/job/sw/ert/clone_mk2/sgt
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/repofficer_medical
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/sgt
	head = /obj/item/clothing/head/helmet/marine/sw/clone/sgt
	glasses = /obj/item/clothing/glasses/hud/health
	belt = /obj/item/storage/belt/lifesaver/full
	r_pocket = /obj/item/storage/pouch/medical_injectors/medic
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/smg/standard
	backpack_contents = list(
		/obj/item/defibrillator = 1,
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/roller = 1,
		/obj/item/cell/lasgun/plasma = 4,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/oxycodone = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/russian_red = 1,
	)

/datum/outfit/job/sw/ert/clone_mk2/captain
	name = "Clone Captain"
	jobtype = /datum/job/sw/ert/clone_mk2/captain
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/repofficer_ensign
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/captain
	head = /obj/item/clothing/head/helmet/marine/sw/clone/captain
	glasses = /obj/item/clothing/glasses/hud/health
	belt = /obj/item/storage/belt/marine
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/binoculars = 1,
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/plastique = 2,
		/obj/item/reagent_containers/hypospray/autoinjector/combat_advanced = 2,
		/obj/item/reagent_containers/hypospray/autoinjector/russian_red = 1,
		/obj/item/cell/lasgun/plasma = 2,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/quickclot = 1,
	)

// -----------------------------------------------------------------------------
// 4) 501st LEGION
// -----------------------------------------------------------------------------

/datum/outfit/job/sw/ert/legion501
	ears = /obj/item/radio/headset/distress

/datum/outfit/job/sw/ert/legion501/trooper
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/repofficer_ensign
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/legion501
	head = /obj/item/clothing/head/helmet/marine/sw/clone/legion501
	belt = /obj/item/storage/belt/marine
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard

/datum/outfit/job/sw/ert/legion501/trooper/infantryman
	name = "501st Legion Trooper (Infantryman)"
	jobtype = /datum/job/sw/ert/legion501/trooper
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/grenade = 3,
		/obj/item/explosive/plastique = 2,
		/obj/item/stack/sheet/metal/medium_stack = 1,
		/obj/item/storage/box/m94 = 1,
		/obj/item/cell/lasgun/plasma = 1,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/dylovene = 1,
	)

/datum/outfit/job/sw/ert/legion501/trooper/veteran
	name = "501st Legion Trooper (Veteran)"
	jobtype = /datum/job/sw/ert/legion501/trooper
	glasses = /obj/item/clothing/glasses/meson
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/grenade = 2,
		/obj/item/explosive/plastique = 5,
		/obj/item/stack/sheet/metal/medium_stack = 1,
		/obj/item/cell/lasgun/plasma = 2,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/quickclot = 1,
	)

/datum/outfit/job/sw/ert/legion501/radiotech
	name = "501st Radiotech Engineer"
	jobtype = /datum/job/sw/ert/legion501/radiotech
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/repofficer_ensign
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/legion501
	head = /obj/item/clothing/head/helmet/marine/sw/clone/radiotech
	glasses = /obj/item/clothing/glasses/meson
	gloves = /obj/item/clothing/gloves/marine/insulated
	belt = /obj/item/storage/belt/marine
	l_pocket = /obj/item/storage/pouch/tools/full
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/smg/standard
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/uav_turret = 1,
		/obj/item/deployable_vehicle = 1,
		/obj/item/unmanned_vehicle_remote = 1,
		/obj/item/tool/weldingtool/largetank = 1,
		/obj/item/tool/wrench = 1,
		/obj/item/explosive/plastique = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/stack/cable_coil = 1,
		/obj/item/storage/box/mre = 1,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/dylovene = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/combat_advanced = 1,
	)

/datum/outfit/job/sw/ert/legion501/commander
	name = "501st Commander"
	jobtype = /datum/job/sw/ert/legion501/commander
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/repofficer_ensign
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/commander
	head = /obj/item/clothing/head/helmet/marine/sw/clone/commander
	glasses = /obj/item/clothing/glasses/hud/health
	belt = /obj/item/storage/belt/marine
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/binoculars = 1,
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/plastique = 2,
		/obj/item/reagent_containers/hypospray/autoinjector/combat_advanced = 2,
		/obj/item/reagent_containers/hypospray/autoinjector/russian_red = 1,
		/obj/item/cell/lasgun/plasma = 2,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/quickclot = 1,
	)

// -----------------------------------------------------------------------------
// 5) 212th BATTALION
// -----------------------------------------------------------------------------

/datum/outfit/job/sw/ert/battalion212
	ears = /obj/item/radio/headset/distress

/datum/outfit/job/sw/ert/battalion212/trooper
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/repofficer_ensign
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/battalion212
	head = /obj/item/clothing/head/helmet/marine/sw/clone/battalion212
	belt = /obj/item/storage/belt/marine
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard

/datum/outfit/job/sw/ert/battalion212/trooper/infantryman
	name = "212th Battalion Trooper (Infantryman)"
	jobtype = /datum/job/sw/ert/battalion212/trooper
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/grenade = 3,
		/obj/item/explosive/plastique = 2,
		/obj/item/stack/sheet/metal/medium_stack = 1,
		/obj/item/storage/box/m94 = 1,
		/obj/item/cell/lasgun/plasma = 1,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/dylovene = 1,
	)

/datum/outfit/job/sw/ert/battalion212/trooper/veteran
	name = "212th Battalion Trooper (Veteran)"
	jobtype = /datum/job/sw/ert/battalion212/trooper
	glasses = /obj/item/clothing/glasses/meson
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/grenade = 2,
		/obj/item/explosive/plastique = 5,
		/obj/item/stack/sheet/metal/medium_stack = 1,
		/obj/item/cell/lasgun/plasma = 2,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/quickclot = 1,
	)

/datum/outfit/job/sw/ert/battalion212/commando
	name = "212th Commando Leader"
	jobtype = /datum/job/sw/ert/battalion212/commando
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/repofficer_ensign
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/commando
	head = /obj/item/clothing/head/helmet/marine/sw/clone/commando
	glasses = /obj/item/clothing/glasses/hud/health
	belt = /obj/item/storage/belt/marine
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/binoculars = 1,
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/plastique = 2,
		/obj/item/reagent_containers/hypospray/autoinjector/combat_advanced = 2,
		/obj/item/reagent_containers/hypospray/autoinjector/russian_red = 1,
		/obj/item/cell/lasgun/plasma = 2,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/quickclot = 1,
	)

// -----------------------------------------------------------------------------
// 6) 442nd BATTALION (no dedicated helmet — phase2)
// -----------------------------------------------------------------------------

/datum/outfit/job/sw/ert/battalion442
	ears = /obj/item/radio/headset/distress

/datum/outfit/job/sw/ert/battalion442/trooper
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/repofficer_ensign
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/battalion442
	head = /obj/item/clothing/head/helmet/marine/sw/clone/phase2
	belt = /obj/item/storage/belt/marine
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard

/datum/outfit/job/sw/ert/battalion442/trooper/infantryman
	name = "442nd Battalion Trooper (Infantryman)"
	jobtype = /datum/job/sw/ert/battalion442/trooper
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/grenade = 3,
		/obj/item/explosive/plastique = 2,
		/obj/item/stack/sheet/metal/medium_stack = 1,
		/obj/item/storage/box/m94 = 1,
		/obj/item/cell/lasgun/plasma = 1,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/dylovene = 1,
	)

/datum/outfit/job/sw/ert/battalion442/trooper/veteran
	name = "442nd Battalion Trooper (Veteran)"
	jobtype = /datum/job/sw/ert/battalion442/trooper
	glasses = /obj/item/clothing/glasses/meson
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/grenade = 2,
		/obj/item/explosive/plastique = 5,
		/obj/item/stack/sheet/metal/medium_stack = 1,
		/obj/item/cell/lasgun/plasma = 2,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/quickclot = 1,
	)

/datum/outfit/job/sw/ert/battalion442/commando
	name = "442nd Commando Leader"
	jobtype = /datum/job/sw/ert/battalion442/commando
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/repofficer_ensign
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/commando
	head = /obj/item/clothing/head/helmet/marine/sw/clone/commando
	glasses = /obj/item/clothing/glasses/hud/health
	belt = /obj/item/storage/belt/marine
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/binoculars = 1,
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/plastique = 2,
		/obj/item/reagent_containers/hypospray/autoinjector/combat_advanced = 2,
		/obj/item/reagent_containers/hypospray/autoinjector/russian_red = 1,
		/obj/item/cell/lasgun/plasma = 2,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/quickclot = 1,
	)

// -----------------------------------------------------------------------------
// 7) SENATE GUARD
// -----------------------------------------------------------------------------

/datum/outfit/job/sw/ert/senateguard
	name = "Senate Guardsman"
	jobtype = /datum/job/sw/ert/senateguard
	ears = /obj/item/radio/headset/distress
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/impofficer_captain
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/guard/senateguard
	head = /obj/item/clothing/head/helmet/marine/sw/senateguard
	belt = /obj/item/storage/belt/marine
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard
	r_hand = /obj/item/weapon/energy/sword/blue
	l_hand = /obj/item/weapon/shield/energy
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/binoculars = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/plastique = 4,
		/obj/item/storage/box/mre = 1,
		/obj/item/cell/lasgun/plasma = 2,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/combat_advanced = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/russian_red = 1,
	)

// -----------------------------------------------------------------------------
// 8) STORMTROOPERS — VSD ears, plasma
// -----------------------------------------------------------------------------

/datum/outfit/job/sw/ert/stormtrooper
	ears = /obj/item/radio/headset/distress/vsd

/datum/outfit/job/sw/ert/stormtrooper/standard
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/imptechnician/black
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/stormtrooper
	head = /obj/item/clothing/head/helmet/marine/sw/repstormtrooper
	belt = /obj/item/storage/belt/marine
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard

/datum/outfit/job/sw/ert/stormtrooper/standard/marine
	name = "Imperial Stormtrooper (Marine)"
	jobtype = /datum/job/sw/ert/stormtrooper/standard
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/clothing/head/sw/cap/repensign = 1,
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/grenade = 2,
		/obj/item/storage/box/m94 = 1,
		/obj/item/cell/lasgun/plasma = 2,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/quickclot = 1,
	)

/datum/outfit/job/sw/ert/stormtrooper/standard/infantryman
	name = "Imperial Stormtrooper (Infantryman)"
	jobtype = /datum/job/sw/ert/stormtrooper/standard
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/clothing/head/sw/cap/repensign = 1,
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/grenade = 4,
		/obj/item/explosive/plastique = 1,
		/obj/item/storage/box/m94 = 1,
		/obj/item/cell/lasgun/plasma = 1,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/dylovene = 1,
	)

// --- Airborne (SOM breacher-style variants) ---
// All airborne: backpack OR suit holds /obj/item/clothing/head/sw/cap/repofficer_ensign

/datum/outfit/job/sw/ert/stormtrooper/airborne
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/imptechnician/black
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/stormtrooper
	head = /obj/item/clothing/head/helmet/marine/sw/imperial/airborne
	belt = /obj/item/storage/belt/marine

/datum/outfit/job/sw/ert/stormtrooper/airborne/breacher
	name = "Imperial Airborne Breacher"
	jobtype = /datum/job/sw/ert/stormtrooper/airborne
	glasses = /obj/item/clothing/glasses/welding/flipped
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard
	l_hand = /obj/item/weapon/shield/riot/marine/som
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/clothing/head/sw/cap/repofficer_ensign = 1,
		/obj/item/tool/extinguisher = 1,
		/obj/item/tool/weldingtool/largetank = 1,
		/obj/item/explosive/plastique = 4,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/grenade = 2,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/quickclot = 1,
	)

/datum/outfit/job/sw/ert/stormtrooper/airborne/rpg
	name = "Imperial Airborne RPG"
	jobtype = /datum/job/sw/ert/stormtrooper/airborne
	back = /obj/item/storage/holster/backholster/rpg/som/ert
	suit_store = /obj/item/weapon/twohanded/fireaxe/som
	l_pocket = /obj/item/storage/pouch/explosive
	belt = /obj/item/storage/belt/grenade
	belt_contents = list(
		/obj/item/explosive/grenade = 3,
		/obj/item/explosive/grenade/smokebomb = 2,
		/obj/item/explosive/grenade/incendiary = 2,
	)
	// no backpack — cap in suit pockets
	suit_contents = list(
		/obj/item/clothing/head/sw/cap/repofficer_ensign = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/combat_advanced = 1,
	)

/datum/outfit/job/sw/ert/stormtrooper/airborne/flamer
	name = "Imperial Airborne Flamer"
	jobtype = /datum/job/sw/ert/stormtrooper/airborne
	back = /obj/item/ammo_magazine/flamer_tank/backtank
	suit_store = /obj/item/weapon/gun/flamer/som/mag_harness
	belt = /obj/item/storage/holster/belt/pistol/m4a3/som
	belt_contents = list(
		/obj/item/ammo_magazine/pistol/som/extended = 6,
		/obj/item/weapon/gun/pistol/som/burst = 1,
	)
	suit_contents = list(
		/obj/item/clothing/head/sw/cap/repofficer_ensign = 1,
		/obj/item/tool/extinguisher/mini = 1,
	)

/datum/outfit/job/sw/ert/stormtrooper/airborne/culverin
	name = "Imperial Airborne Culverin"
	jobtype = /datum/job/sw/ert/stormtrooper/airborne
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/cannon/mag_harness
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/clothing/head/sw/cap/repofficer_ensign = 1,
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/tool/extinguisher/mini = 1,
		/obj/item/cell/lasgun/plasma = 3,
		/obj/item/explosive/grenade = 2,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/quickclot = 1,
	)

/datum/outfit/job/sw/ert/stormtrooper/airborne/medic
	name = "Imperial Airborne Medic"
	jobtype = /datum/job/sw/ert/stormtrooper/airborne
	glasses = /obj/item/clothing/glasses/hud/health
	belt = /obj/item/storage/belt/lifesaver/full
	r_pocket = /obj/item/storage/pouch/medical_injectors/medic
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/smg/standard
	l_hand = /obj/item/weapon/shield/riot/marine/som
	backpack_contents = list(
		/obj/item/clothing/head/sw/cap/repofficer_ensign = 1,
		/obj/item/defibrillator = 1,
		/obj/item/tool/extinguisher = 1,
		/obj/item/explosive/plastique = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/cell/lasgun/plasma = 4,
		/obj/item/storage/box/mre = 1,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/oxycodone = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/russian_red = 1,
	)

/datum/outfit/job/sw/ert/stormtrooper/surgeon
	name = "Imperial Storm Surgeon"
	jobtype = /datum/job/sw/ert/stormtrooper/surgeon
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/imptechnician
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/stormsurgeon
	head = /obj/item/clothing/head/helmet/marine/sw/stormsurgeon
	glasses = /obj/item/clothing/glasses/hud/health
	belt = /obj/item/storage/belt/lifesaver/full
	r_pocket = /obj/item/storage/pouch/medical_injectors/medic
	l_pocket = /obj/item/storage/pouch/medkit/medic
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/smg/standard
	backpack_contents = list(
		/obj/item/clothing/head/sw/cap/repofficer_med = 1,
		/obj/item/defibrillator = 1,
		/obj/item/roller = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/storage/box/mre = 1,
		/obj/item/cell/lasgun/plasma = 3,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/oxycodone = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/russian_red = 1,
	)

/datum/outfit/job/sw/ert/stormtrooper/radio
	name = "Imperial Storm Radioman"
	jobtype = /datum/job/sw/ert/stormtrooper/radio
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/imptechnician
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/stormradio
	head = /obj/item/clothing/head/helmet/marine/sw/stormradio
	glasses = /obj/item/clothing/glasses/meson
	gloves = /obj/item/clothing/gloves/marine/insulated
	belt = /obj/item/storage/belt/marine
	l_pocket = /obj/item/storage/pouch/tools/full
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/clothing/head/sw/cap/repofficer_ensign = 1,
		/obj/item/tool/extinguisher = 1,
		/obj/item/assembly/signaler = 1,
		/obj/item/explosive/plastique/detpack = 2,
		/obj/item/explosive/plastique = 2,
		/obj/item/stack/sheet/metal/large_stack = 1,
		/obj/item/stack/cable_coil = 1,
		/obj/item/storage/box/mre = 1,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/dylovene = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/combat_advanced = 1,
	)

/datum/outfit/job/sw/ert/stormtrooper/officer
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/imp_stormofficer
	belt = /obj/item/storage/belt/marine
	glasses = /obj/item/clothing/glasses/hud/health
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard

/datum/outfit/job/sw/ert/stormtrooper/officer/jacket
	name = "Imperial Stormtrooper Officer (Jacket)"
	jobtype = /datum/job/sw/ert/stormtrooper/officer
	wear_suit = /obj/item/clothing/suit/modular/style/leather_jacket/sw_officer
	head = /obj/item/clothing/head/sw/cap/repofficer_navcaptain
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	// jacket has no pocket storage — extras in backpack only
	backpack_contents = list(
		/obj/item/binoculars = 1,
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/plastique = 2,
		/obj/item/reagent_containers/hypospray/autoinjector/combat_advanced = 2,
		/obj/item/reagent_containers/hypospray/autoinjector/russian_red = 1,
		/obj/item/cell/lasgun/plasma = 2,
	)

/datum/outfit/job/sw/ert/stormtrooper/officer/armored
	name = "Imperial Stormtrooper Officer (Armored)"
	jobtype = /datum/job/sw/ert/stormtrooper/officer
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/stormtrooper
	head = /obj/item/clothing/head/helmet/marine/sw/imp_stormofficer
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/clothing/head/sw/cap/imp_stormofficer = 1,
		/obj/item/binoculars = 1,
		/obj/item/storage/box/mre = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/plastique = 2,
		/obj/item/reagent_containers/hypospray/autoinjector/combat_advanced = 2,
		/obj/item/cell/lasgun/plasma = 1,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/isotonic = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/quickclot = 1,
	)

// -----------------------------------------------------------------------------
// 9) RED GUARD
// -----------------------------------------------------------------------------

/datum/outfit/job/sw/ert/redguard
	name = "Imperial Royal Guardsman"
	jobtype = /datum/job/sw/ert/redguard
	ears = /obj/item/radio/headset/distress
	w_uniform = /obj/item/clothing/under/marine/veteran/sw/impofficer_captain
	wear_suit = /obj/item/clothing/suit/storage/marine/clone/guard
	head = /obj/item/clothing/head/helmet/marine/sw/redguard
	belt = /obj/item/storage/belt/marine
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard
	r_hand = /obj/item/weapon/energy/sword/red
	l_hand = /obj/item/weapon/shield/energy
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/binoculars = 1,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/plastique = 4,
		/obj/item/storage/box/mre = 1,
		/obj/item/cell/lasgun/plasma = 2,
	)
	suit_contents = list(
		/obj/item/reagent_containers/hypospray/autoinjector/combat_advanced = 1,
		/obj/item/reagent_containers/hypospray/autoinjector/russian_red = 1,
	)
