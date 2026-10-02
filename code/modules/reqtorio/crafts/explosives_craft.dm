/*******************************************************************************
EXPLOSIVES
*******************************************************************************/
/datum/assembly_craft/explosives
	group = "Explosives"
	craft_time = 8 SECONDS

/datum/assembly_craft/explosives/claymore
	name = "M20 Claymore anti-personnel mine"
	input = list(/obj/item/stack/sheet/composite = 2, /obj/item/stack/gun_powder = 5)
	output = list(/obj/item/explosive/mine = 1)

//-------------------------------------------------------
//nades

/datum/assembly_craft/explosives/phosphos
	name = "M40 HPDP grenade box"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 45, /obj/item/stack/gun_powder = 100)
	output = list(/obj/item/storage/box/visual/grenade/phosphorus = 1)

/datum/assembly_craft/explosives/bignade
	name = "M15 fragmentation grenade box"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/metal = 25, /obj/item/stack/gun_powder = 50)
	output = list(/obj/item/storage/box/visual/grenade/m15 = 1)

/datum/assembly_craft/explosives/razornade
	name = "Razorburn grenade box"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/composite = 45, /obj/item/stack/gun_powder = 15)
	output = list(/obj/item/storage/box/visual/grenade/razorburn = 1)

//-------------------------------------------------------
//RL-152

/datum/assembly_craft/explosives/sadar_he
	name = "SADAR HE missile - 84mm 'L-G' high-explosive rocket"
	input = list(/obj/item/stack/sheet/jeweler_steel = 2, /obj/item/stack/gun_powder = 5)
	output = list(/obj/item/ammo_magazine/rocket/sadar = 1)

/datum/assembly_craft/explosives/sadar_he_unguided
	name = "SADAR HE unguided missile - 84mm 'Unguided' high-explosive rocket"
	input = list(/obj/item/stack/sheet/jeweler_steel = 2, /obj/item/stack/gun_powder = 5)
	output = list(/obj/item/ammo_magazine/rocket/sadar/unguided = 1)

/datum/assembly_craft/explosives/sadar_ap
	name = "SADAR AP missile - 84mm 'L-G' anti-armor rocket"
	input = list(/obj/item/stack/sheet/jeweler_steel = 5, /obj/item/stack/gun_powder = 5)
	output = list(/obj/item/ammo_magazine/rocket/sadar/ap = 1)

/datum/assembly_craft/explosives/sadar_wp
	name = "SADAR WP missile - 84mm 'L-G' white-phosphorus rocket"
	input = list(/obj/item/stack/sheet/jeweler_steel = 2, /obj/item/stack/gun_powder = 10)
	output = list(/obj/item/ammo_magazine/rocket/sadar/wp = 1)

//-------------------------------------------------------
//RL-160 recoilless rifle

/datum/assembly_craft/explosives/standard_recoilless_refill
	name = "Recoilless standard missile - 67mm high-explosive shell"
	input = list(/obj/item/stack/sheet/composite = 5, /obj/item/stack/gun_powder = 3)
	output = list(/obj/item/ammo_magazine/rocket/recoilless = 1)

/datum/assembly_craft/explosives/light_recoilless_refill
	name = "Recoilless light missile - 67mm light-explosive shell"
	input = list(/obj/item/stack/sheet/composite = 5, /obj/item/stack/gun_powder = 3)
	output = list(/obj/item/ammo_magazine/rocket/recoilless/light = 1)

/datum/assembly_craft/explosives/heat_recoilless_refill
	name = "Recoilless heat missile - 67mm HEAT shell"
	input = list(/obj/item/stack/sheet/composite = 5, /obj/item/stack/gun_powder = 3)
	output = list(/obj/item/ammo_magazine/rocket/recoilless/heat = 1)

/datum/assembly_craft/explosives/smoke_recoilless_refill
	name = "Recoilless smoke missile - 67mm Chemical (Smoke) shell"
	input = list(/obj/item/stack/sheet/composite = 5, /obj/item/stack/gun_powder = 3)
	output = list(/obj/item/ammo_magazine/rocket/recoilless/smoke = 1)

/datum/assembly_craft/explosives/cloak_recoilless_refill
	name = "Recoilless cloak missile - 67mm Chemical (Cloak) shell"
	input = list(/obj/item/stack/sheet/composite = 5, /obj/item/stack/gun_powder = 3)
	output = list(/obj/item/ammo_magazine/rocket/recoilless/cloak = 1)

/datum/assembly_craft/explosives/tfoot_recoilless_refill
	name = "Recoilless tfoot missile - 67mm Chemical (Tanglefoot) shell"
	input = list(/obj/item/stack/sheet/jeweler_steel = 5, /obj/item/stack/gun_powder = 3)
	output = list(/obj/item/ammo_magazine/rocket/recoilless/plasmaloss = 1)

/datum/assembly_craft/explosives/c4
	name = "Plastic explosive"
	input = list(/obj/item/stack/sheet/composite = 1, /obj/item/stack/gun_powder = 5)
	output = list(/obj/item/explosive/plastique = 1)

/datum/assembly_craft/explosives/detpack
	name = "Detonation pack"
	craft_time = 12 SECONDS
	input = list(/obj/item/stack/sheet/composite = 1, /obj/item/stack/gun_powder = 10)
	output = list(/obj/item/explosive/plastique/detpack = 1)

/datum/assembly_craft/explosives/genghis
	name = "EX-62 Genghis incendiary charge"
	craft_time = 18 SECONDS
	input = list(/obj/item/stack/sheet/composite = 1, /obj/item/stack/gun_powder = 15)
	output = list(/obj/item/explosive/plastique/genghis_charge = 1)
