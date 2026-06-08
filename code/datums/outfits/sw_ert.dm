/datum/outfit/job/sw/ert
	id = /obj/item/card/id/silver
	ears = /obj/item/radio/headset/distress
	shoes = /obj/item/clothing/shoes/black
	gloves = /obj/item/clothing/gloves/marine
	mask = /obj/item/clothing/mask/gas
	back = /obj/item/storage/backpack/lightpack
	belt = /obj/item/storage/belt/marine
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 4,
	)
	r_pocket = /obj/item/storage/pouch/medical_injectors/firstaid
	l_pocket = /obj/item/storage/pouch/grenade

/datum/outfit/job/sw/ert/rebel
	name = "Rebel Trooper"
	jobtype = /datum/job/sw/ert/rebel
	w_uniform = /obj/item/clothing/under/sw/rebel
	wear_suit = /obj/item/clothing/suit/sw/vest
	head = /obj/item/clothing/head/sw/helmet/rebel
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard
	backpack_contents = list(
		/obj/item/cell/lasgun/plasma = 4,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/reagent_containers/food/snacks/enrg_bar = 2,
	)

/datum/outfit/job/sw/ert/rebel/officer
	name = "Rebel Officer"
	jobtype = /datum/job/sw/ert/rebel/officer
	w_uniform = /obj/item/clothing/under/sw/rebel/officer
	wear_suit = /obj/item/clothing/suit/sw/vest/officer
	head = /obj/item/clothing/head/sw/helmet/rebel/black
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard
	backpack_contents = list(
		/obj/item/cell/lasgun/plasma = 4,
		/obj/item/tool/crowbar/red = 1,
	)

/datum/outfit/job/sw/ert/rebel/medic
	name = "Rebel Medic"
	jobtype = /datum/job/sw/ert/rebel/medic
	w_uniform = /obj/item/clothing/under/sw/rebel
	wear_suit = /obj/item/clothing/suit/sw/vest
	head = /obj/item/clothing/head/sw/helmet/rebel
	belt = /obj/item/storage/belt/lifesaver/full
	belt_contents = null
	l_pocket = /obj/item/storage/pouch/medkit/medic
	r_pocket = /obj/item/storage/pouch/medical_injectors/medic
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/smg/standard
	backpack_contents = list(
		/obj/item/cell/lasgun/plasma = 4,
		/obj/item/defibrillator = 1,
	)

/datum/outfit/job/sw/ert/republic
	name = "Republic Clone Trooper"
	jobtype = /datum/job/sw/ert/republic
	w_uniform = /obj/item/clothing/under/sw/repofficer_ensign
	wear_suit = /obj/item/clothing/suit/armor/sw/replicant
	head = /obj/item/clothing/head/sw/helmet/replicant/phase2
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard
	backpack_contents = list(
		/obj/item/cell/lasgun/plasma = 4,
		/obj/item/tool/crowbar/red = 1,
		/obj/item/explosive/grenade = 2,
	)

/datum/outfit/job/sw/ert/republic/sergeant
	name = "Republic Clone Sergeant"
	jobtype = /datum/job/sw/ert/republic/sergeant
	w_uniform = /obj/item/clothing/under/sw/repofficer_ensign
	wear_suit = /obj/item/clothing/suit/armor/sw/replicant/sgt
	head = /obj/item/clothing/head/sw/helmet/replicant/sgt
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard

/datum/outfit/job/sw/ert/republic/medic
	name = "Republic Clone Medic"
	jobtype = /datum/job/sw/ert/republic/medic
	w_uniform = /obj/item/clothing/under/sw/repofficer_medical
	wear_suit = /obj/item/clothing/suit/armor/sw/replicant/mp
	head = /obj/item/clothing/head/sw/helmet/replicant/mp
	belt = /obj/item/storage/belt/lifesaver/full
	belt_contents = null
	l_pocket = /obj/item/storage/pouch/medkit/medic
	r_pocket = /obj/item/storage/pouch/medical_injectors/medic
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/smg/standard
	backpack_contents = list(
		/obj/item/cell/lasgun/plasma = 4,
		/obj/item/defibrillator = 1,
	)

/datum/outfit/job/sw/ert/republic/elite
	name = "Republic Elite Clone"
	jobtype = /datum/job/sw/ert/republic/elite
	w_uniform = /obj/item/clothing/under/sw/repofficer_ensign
	wear_suit = /obj/item/clothing/suit/armor/sw/replicant/reinforced
	head = /obj/item/clothing/head/sw/helmet/replicant/legion501
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/cell/lasgun/plasma = 4,
		/obj/item/explosive/grenade = 4,
	)

/datum/outfit/job/sw/ert/republic/elite/commando
	name = "Republic Clone Commando"
	jobtype = /datum/job/sw/ert/republic/elite/commando
	w_uniform = /obj/item/clothing/under/sw/repofficer_ensign
	wear_suit = /obj/item/clothing/suit/armor/sw/replicant/commando
	head = /obj/item/clothing/head/sw/helmet/replicant/commando
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/explosive/grenade = 4,
	)

/datum/outfit/job/sw/ert/imperial
	name = "Imperial Stormtrooper"
	jobtype = /datum/job/sw/ert/imperial
	w_uniform = /obj/item/clothing/under/sw/imptechnician/black
	wear_suit = /obj/item/clothing/suit/armor/sw/stormtrooper
	head = /obj/item/clothing/head/sw/helmet/repstormtrooper
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard
	backpack_contents = list(
		/obj/item/cell/lasgun/plasma = 4,
		/obj/item/explosive/grenade = 2,
	)

/datum/outfit/job/sw/ert/imperial/officer
	name = "Imperial Stormtrooper Officer"
	jobtype = /datum/job/sw/ert/imperial/officer
	w_uniform = /obj/item/clothing/under/sw/imp_stormofficer
	wear_suit = /obj/item/clothing/suit/armor/sw/stormtrooper
	head = /obj/item/clothing/head/sw/helmet/imp_stormofficer
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard

/datum/outfit/job/sw/ert/imperial/medic
	name = "Imperial Storm Surgeon"
	jobtype = /datum/job/sw/ert/imperial/medic
	w_uniform = /obj/item/clothing/under/sw/imptechnician
	wear_suit = /obj/item/clothing/suit/armor/sw/stormsurgeon
	head = /obj/item/clothing/head/sw/helmet/stormsurgeon
	belt = /obj/item/storage/belt/lifesaver/full
	belt_contents = null
	l_pocket = /obj/item/storage/pouch/medkit/medic
	r_pocket = /obj/item/storage/pouch/medical_injectors/medic
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/smg/standard
	backpack_contents = list(
		/obj/item/cell/lasgun/plasma = 4,
		/obj/item/defibrillator = 1,
	)

/datum/outfit/job/sw/ert/imperial/guard
	name = "Imperial Royal Guardsman"
	jobtype = /datum/job/sw/ert/imperial/guard
	w_uniform = /obj/item/clothing/under/sw/impofficer_captain
	wear_suit = /obj/item/clothing/suit/armor/sw/redguard
	head = /obj/item/clothing/head/sw/helmet/redguard
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard
	belt_contents = list(
		/obj/item/cell/lasgun/plasma = 6,
	)
	backpack_contents = list(
		/obj/item/cell/lasgun/plasma = 4,
	)

/datum/outfit/job/sw/ert/imperial/guard/senate
	name = "Imperial Senate Guardsman"
	jobtype = /datum/job/sw/ert/imperial/guard/senate
	w_uniform = /obj/item/clothing/under/sw/impofficer_captain
	wear_suit = /obj/item/clothing/suit/armor/sw/senateguard
	head = /obj/item/clothing/head/sw/helmet/senateguard
	suit_store = /obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle/standard
