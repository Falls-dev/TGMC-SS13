/datum/assembly_craft/weapons
	group = "Weapons"
	craft_time = 10 SECONDS

//-------------------------
//energy

/datum/assembly_craft/weapons/tesla
	name = "Tesla shock rifle"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 25, /obj/item/stack/sheet/mineral/osmium = 50, /obj/item/stack/sheet/mineral/platinum = 15, /obj/item/stack/sheet/mineral/silver = 10) // 200 + 300 + 180 + 80 = 760 points
	output = list(/obj/item/weapon/gun/energy/lasgun/lasrifle/tesla = 1) // 600 points

/datum/assembly_craft/weapons/e50
	name = "E-50 laser emitter"
	craft_time = 40 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 15, /obj/item/stack/sheet/mineral/osmium = 30, /obj/item/stack/sheet/mineral/silver = 10) // 120 + 180 + 80 = 380 points
	output = list(/obj/item/weapon/gun/energy/lasgun/lasrifle/e50 = 1) // 400 points

/datum/assembly_craft/weapons/rechargemag
	name = "Terra Experimental TE-X recharger battery"
	input = list(/obj/item/stack/sheet/mineral/platinum = 2, /obj/item/stack/sheet/mineral/silver = 5, /obj/item/stack/sheet/glass/glass = 5) // 24 + 40 + 10 = 74 points
	output = list(/obj/item/cell/lasgun/lasrifle/recharger = 1) // 60 points

/datum/assembly_craft/weapons/xray_gun
	name = "Terra Experimental TE-X Laser Rifle"
	craft_time = 50 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 20, /obj/item/stack/sheet/mineral/osmium = 40, /obj/item/stack/sheet/mineral/platinum = 10) // 160 + 240 + 120 = 520 points
	output = list(/obj/item/weapon/gun/energy/lasgun/lasrifle/xray = 1) // 500 points

//-------------------------
//rifles

/datum/assembly_craft/weapons/tx55
	name = "AR-55 OICW rifle"
	craft_time = 50 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 20, /obj/item/stack/sheet/mineral/osmium = 40, /obj/item/stack/sheet/mineral/platinum = 10) // 160 + 240 + 120 = 520 points
	output = list(/obj/item/weapon/gun/rifle/tx55 = 1) // 525 points

/datum/assembly_craft/weapons/pepperball
	name = "PB-12 pepperball gun"
	craft_time = 15 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 5, /obj/item/stack/sheet/composite = 5) // 40 + 40 = 80 points
	output = list(/obj/item/weapon/gun/rifle/pepperball = 1) // 100 points

/datum/assembly_craft/weapons/railgun
	name = "SR-220 railgun"
	craft_time = 40 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 15, /obj/item/stack/sheet/mineral/osmium = 30, /obj/item/stack/sheet/mineral/platinum = 10) // 120 + 180 + 120 = 420 points
	output = list(/obj/item/weapon/gun/rifle/railgun = 1) // 400 points

/datum/assembly_craft/weapons/railgun_ammo
	name = "SR-220 railgun APDS round"
	input = list(/obj/item/stack/sheet/jeweler_steel = 2, /obj/item/stack/gun_powder = 3) // 13 + 3 = 16 points
	output = list(/obj/item/ammo_magazine/railgun = 1) // 50 points

/datum/assembly_craft/weapons/railgun_ammo/hvap
	name = "SR-220 railgun HVAP round"
	input = list(/obj/item/stack/sheet/jeweler_steel = 2, /obj/item/stack/gun_powder = 4) // 13 + 4 = 17 points
	output = list(/obj/item/ammo_magazine/railgun/hvap = 1) // 50 points

/datum/assembly_craft/weapons/railgun_ammo/smart
	name = "SR-220 railgun SAP round"
	input = list(/obj/item/stack/sheet/jeweler_steel = 2, /obj/item/stack/gun_powder = 4) // 13 + 4 = 17 points
	output = list(/obj/item/ammo_magazine/railgun/smart = 1) // 50 points

/datum/assembly_craft/weapons/tx8
	name = "BR-8 scout rifle"
	craft_time = 40 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 15, /obj/item/stack/sheet/mineral/osmium = 30, /obj/item/stack/sheet/mineral/platinum = 5) // 120 + 180 + 60 = 360 points
	output = list(/obj/item/weapon/gun/rifle/tx8 = 1) // 400 points

/datum/assembly_craft/weapons/scout_regular
	name = "BR-8 scout rifle magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 3, /obj/item/stack/gun_powder = 1) // 18 + 1 = 19 points
	output = list(/obj/item/ammo_magazine/rifle/tx8 = 1) // 20 points

/datum/assembly_craft/weapons/scout_regular_box
	name = "BR-8 scout rifle ammo box"
	input = list(/obj/item/stack/sheet/mineral/osmium = 8, /obj/item/stack/gun_powder = 3) // 48 + 3 = 51 points
	output = list(/obj/item/ammo_magazine/packet/scout_rifle = 1) // 50 points

/datum/assembly_craft/weapons/scout_impact
	name = "BR-8 scout rifle impact magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 3, /obj/item/stack/gun_powder = 3) // 18 + 3 = 21 points
	output = list(/obj/item/ammo_magazine/rifle/tx8/impact = 1) // 40 points

/datum/assembly_craft/weapons/scout_impact_box
	name = "BR-8 scout rifle impact ammo box"
	input = list(/obj/item/stack/sheet/mineral/osmium = 10, /obj/item/stack/gun_powder = 5) // 60 + 5 = 65 points
	output = list(/obj/item/ammo_magazine/packet/scout_rifle/impact = 1) // 100 points

/datum/assembly_craft/weapons/scout_incendiary
	name = "BR-8 scout rifle incendiary magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 3, /obj/item/stack/gun_powder = 3, /obj/item/stack/sheet/mineral/phoron = 1) // 18 + 3 + 7 = 28 points
	output = list(/obj/item/ammo_magazine/rifle/tx8/incendiary = 1) // 40 points

/datum/assembly_craft/weapons/scout_incendiary_box
	name = "BR-8 scout rifle incendiary ammo box"
	input = list(/obj/item/stack/sheet/mineral/osmium = 10, /obj/item/stack/gun_powder = 5, /obj/item/stack/sheet/mineral/phoron = 3) // 60 + 5 + 21 = 86 points
	output = list(/obj/item/ammo_magazine/packet/scout_rifle/incendiary = 1) // 100 points

/datum/assembly_craft/weapons/zx76
	name = "ZX-76 twin-barrled burst shotgun"
	craft_time = 90 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 40, /obj/item/stack/sheet/mineral/osmium = 80, /obj/item/stack/sheet/mineral/platinum = 20) // 320 + 480 + 240 = 1040 points
	output = list(/obj/item/weapon/gun/shotgun/zx76 = 1) // 1000 points

//-------------------------
//shotgun ammo

/datum/assembly_craft/weapons/shotguntracker
	name = "12 gauge tracker shells"
	input = list(/obj/item/stack/sheet/metal = 2, /obj/item/stack/gun_powder = 2) // 8 + 2 = 10 points
	output = list(/obj/item/ammo_magazine/shotgun/tracker = 1) // 50 points

/datum/assembly_craft/weapons/incendiaryslugs
	name = "Box of incendiary slugs"
	input = list(/obj/item/stack/sheet/metal = 5, /obj/item/stack/gun_powder = 3, /obj/item/stack/sheet/mineral/phoron = 5) // 20 + 3 + 35 = 58 points
	output = list(/obj/item/ammo_magazine/shotgun/incendiary = 1) // 100 points

//-------------------------
//snipers

/datum/assembly_craft/weapons/sr81
	name = "SR-81 IFF auto sniper kit"
	craft_time = 50 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 20, /obj/item/stack/sheet/mineral/osmium = 40, /obj/item/stack/sheet/mineral/platinum = 10) // 160 + 240 + 120 = 520 points
	output = list(/obj/item/weapon/gun/rifle/sr81 = 1) // 500 points

/datum/assembly_craft/weapons/sr81_ammo
	name = "SR-81 IFF sniper magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 4, /obj/item/stack/gun_powder = 2) // 24 + 2 = 26 points
	output = list(/obj/item/ammo_magazine/rifle/sr81 = 1) // 30 points

/datum/assembly_craft/weapons/sr81_packet
	name = "SR-81 IFF sniper ammo box"
	input = list(/obj/item/stack/sheet/mineral/osmium = 8, /obj/item/stack/gun_powder = 3) // 48 + 3 = 51 points
	output = list(/obj/item/ammo_magazine/packet/sr81 = 1) // 50 points

/datum/assembly_craft/weapons/antimaterial
	name = "SR-26 antimaterial rifle (AMR) kit"
	craft_time = 75 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 30, /obj/item/stack/sheet/mineral/osmium = 60, /obj/item/stack/sheet/mineral/platinum = 20) // 240 + 360 + 240 = 840 points
	output = list(/obj/item/weapon/gun/rifle/sniper/antimaterial = 1) // 775 points

/datum/assembly_craft/weapons/antimaterial_ammo
	name = "SR-26 AMR magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 4, /obj/item/stack/gun_powder = 2) // 24 + 2 = 26 points
	output = list(/obj/item/ammo_magazine/sniper = 1) // 30 points

/datum/assembly_craft/weapons/antimaterial_incend_ammo
	name = "SR-26 AMR incendiary magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 4, /obj/item/stack/gun_powder = 3, /obj/item/stack/sheet/mineral/phoron = 3) // 24 + 3 + 21 = 48 points
	output = list(/obj/item/ammo_magazine/sniper/incendiary = 1) // 50 points

/datum/assembly_craft/weapons/antimaterial_flak_ammo
	name = "SR-26 AMR flak magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 4, /obj/item/stack/gun_powder = 3) // 24 + 3 = 27 points
	output = list(/obj/item/ammo_magazine/sniper/flak = 1) // 40 points

//-------------------------
//heavy

/datum/assembly_craft/weapons/specminigun
	name = "MG-100 Vindicator minigun"
	craft_time = 90 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 40, /obj/item/stack/sheet/mineral/osmium = 80, /obj/item/stack/sheet/mineral/platinum = 20) // 320 + 480 + 240 = 1040 points
	output = list(/obj/item/weapon/gun/minigun = 1)

/datum/assembly_craft/weapons/minigun
	name = "MG-100 Vindicator Minigun Powerpack"
	input = list(/obj/item/stack/sheet/plasteel = 5, /obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 5) // 40 + 30 + 5 = 75 points
	output = list(/obj/item/ammo_magazine/minigun_powerpack = 1) // 50 points

//-------------------------
//flamers

/datum/assembly_craft/weapons/flamethrower
	name = "FL-84 flamethrower"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 10, /obj/item/stack/sheet/mineral/osmium = 10, /obj/item/stack/sheet/mineral/phoron = 5) // 80 + 60 + 35 = 175 points
	output = list(/obj/item/weapon/gun/flamer/big_flamer/marinestandard = 1) // 150 points

/datum/assembly_craft/weapons/napalm
	name = "FL-84 standard fuel tank"
	input = list(/obj/item/stack/sheet/metal = 5, /obj/item/stack/sheet/mineral/phoron = 10) // 20 + 70 = 90 points
	output = list(/obj/item/ammo_magazine/flamer_tank/large = 1) // 60 points

/datum/assembly_craft/weapons/napalm_G
	name = "FL-84 G-fuel tank"
	input = list(/obj/item/stack/sheet/metal = 5, /obj/item/stack/sheet/mineral/phoron = 15) // 20 + 105 = 125 points
	output = list(/obj/item/ammo_magazine/flamer_tank/large/G = 1) // 75 points

/datum/assembly_craft/weapons/napalm_X
	name = "FL-84 X-fuel tank"
	input = list(/obj/item/stack/sheet/metal = 10, /obj/item/stack/sheet/mineral/phoron = 50, /obj/item/stack/sheet/mineral/platinum = 5) // 40 + 350 + 60 = 450 points
	output = list(/obj/item/ammo_magazine/flamer_tank/large/X = 1) // 300 points

/datum/assembly_craft/weapons/back_fuel_tank
	name = "Standard backpack fuel tank"
	input = list(/obj/item/stack/sheet/metal = 10, /obj/item/stack/sheet/mineral/phoron = 25) // 40 + 175 = 215 points
	output = list(/obj/item/ammo_magazine/flamer_tank/backtank = 1) // 200 points

/datum/assembly_craft/weapons/back_fuel_tank_g
	name = "G-fuel backpack fuel tank"
	input = list(/obj/item/stack/sheet/metal = 10, /obj/item/stack/sheet/mineral/phoron = 20) // 40 + 140 = 180 points
	output = list(/obj/item/ammo_magazine/flamer_tank/backtank/G = 1) // 150 points

/datum/assembly_craft/weapons/back_fuel_tank_x
	name = "X-fuel backpack fuel tank"
	input = list(/obj/item/stack/sheet/metal = 15, /obj/item/stack/sheet/mineral/phoron = 80, /obj/item/stack/sheet/mineral/platinum = 10) // 60 + 560 + 120 = 740 points
	output = list(/obj/item/ammo_magazine/flamer_tank/backtank/X = 1) // 600 points

/datum/assembly_craft/weapons/mini_fuel_tank_g
	name = "G-fuel mini fuel tank"
	input = list(/obj/item/stack/sheet/metal = 1, /obj/item/stack/sheet/mineral/phoron = 1) // 4 + 7 = 11 points
	output = list(/obj/item/ammo_magazine/flamer_tank/mini/G = 1) // 5 points

/datum/assembly_craft/weapons/mini_fuel_tank_x
	name = "X-fuel mini fuel tank"
	input = list(/obj/item/stack/sheet/metal = 1, /obj/item/stack/sheet/mineral/phoron = 3, /obj/item/stack/sheet/mineral/platinum = 1) // 4 + 21 + 12 = 37 points
	output = list(/obj/item/ammo_magazine/flamer_tank/mini/X = 1) // 20 points

//-------------------------
//revolvers & sidearms

/datum/assembly_craft/weapons/mateba
	name = "Mateba autorevolver belt"
	input = list(/obj/item/stack/sheet/plasteel = 10, /obj/item/stack/sheet/mineral/platinum = 5, /obj/item/stack/sheet/mineral/silver = 5) // 80 + 60 + 40 = 180 points
	output = list(/obj/item/storage/holster/belt/revolver/mateba/full = 1) // 150 points

/datum/assembly_craft/weapons/mateba_ammo
	name = "Mateba magazine"
	input = list(/obj/item/stack/sheet/metal = 2, /obj/item/stack/gun_powder = 3) // 8 + 3 = 11 points
	output = list(/obj/item/ammo_magazine/revolver/mateba = 1) // 30 points

/datum/assembly_craft/weapons/mateba_packet
	name = "Mateba packet"
	input = list(/obj/item/stack/sheet/metal = 5, /obj/item/stack/gun_powder = 10) // 20 + 10 = 30 points
	output = list(/obj/item/ammo_magazine/packet/mateba = 1) // 120 points

/datum/assembly_craft/weapons/sr127_flak
	name = "SR-127 flak magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 3) // 30 + 3 = 33 points
	output = list(/obj/item/ammo_magazine/rifle/sr127/flak = 1) // 50 points

//-------------------------
//melee

/datum/assembly_craft/weapons/rocketsledge
	name = "Rocket sledge"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 20, /obj/item/stack/sheet/mineral/osmium = 30, /obj/item/stack/sheet/mineral/platinum = 10) // 160 + 180 + 120 = 460 points
	output = list(/obj/item/weapon/twohanded/sledgehammer/rocketsledge = 1) // 600 points

/datum/assembly_craft/weapons/chainsaw
	name = "Chainsaw"
	craft_time = 50 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 15, /obj/item/stack/sheet/mineral/osmium = 25, /obj/item/stack/sheet/mineral/platinum = 5) // 120 + 150 + 60 = 330 points
	output = list(/obj/item/weapon/twohanded/chainsaw = 1) // 500 points

/datum/assembly_craft/weapons/valihalberd
	name = "VAL-HAL-A"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 25, /obj/item/stack/sheet/mineral/osmium = 30, /obj/item/stack/sheet/mineral/platinum = 10) // 200 + 180 + 120 = 500 points
	output = list(/obj/item/weapon/twohanded/glaive/halberd/harvester = 1) // 600 points

//-------------------------
//bundles

/datum/assembly_craft/weapons/t500case
	name = "R-500 bundle"
	input = list(/obj/item/stack/sheet/metal = 5, /obj/item/stack/sheet/cloth = 5) // 20 + 20 = 40 points
	output = list(/obj/item/storage/briefcase/t500 = 1) // 50 points

/datum/assembly_craft/weapons/r76case
	name = "R76 bundle"
	input = list(/obj/item/stack/sheet/metal = 10, /obj/item/stack/sheet/cloth = 5, /obj/item/stack/gun_powder = 5) // 40 + 20 + 5 = 65 points
	output = list(/obj/item/storage/briefcase/standard_magnum = 1) // 120 points

/datum/assembly_craft/weapons/r76_speedloader
	name = "R76 speedloader (x4)"
	input = list(/obj/item/stack/sheet/metal = 5, /obj/item/stack/gun_powder = 5) // 20 + 5 = 25 points
	output = list(/obj/item/ammo_magazine/revolver/standard_magnum = 4) // 40 points

//-------------------------
//smg/ar ammo

/datum/assembly_craft/weapons/vector_incendiary
	name = "Vector incendiary magazine"
	input = list(/obj/item/stack/sheet/metal = 2, /obj/item/stack/gun_powder = 2, /obj/item/stack/sheet/mineral/phoron = 1) // 8 + 2 + 7 = 17 points
	output = list(/obj/item/ammo_magazine/smg/vector/incendiary = 1) // 20 points

/datum/assembly_craft/weapons/ar12_incendiary
	name = "AR-12 incendiary magazine"
	input = list(/obj/item/stack/sheet/metal = 3, /obj/item/stack/gun_powder = 3, /obj/item/stack/sheet/mineral/phoron = 1) // 12 + 3 + 7 = 22 points
	output = list(/obj/item/ammo_magazine/rifle/ar12/incendiary = 1) // 30 points

/datum/assembly_craft/weapons/type16_extended_mag
	name = "Type-16 extended magazine"
	input = list(/obj/item/stack/sheet/metal = 1, /obj/item/stack/gun_powder = 1) // 4 + 1 = 5 points
	output = list(/obj/item/ammo_magazine/rifle/type16/extended = 1) // 15 points

/datum/assembly_craft/weapons/ar21_extended_mag
	name = "AR-21 extended magazine"
	input = list(/obj/item/stack/sheet/metal = 3, /obj/item/stack/gun_powder = 3) // 12 + 3 = 15 points
	output = list(/obj/item/ammo_magazine/rifle/ar21/extended = 1) // 50 points

/datum/assembly_craft/weapons/p9mm_incendiary
	name = "9mm incendiary packet"
	input = list(/obj/item/stack/sheet/metal = 2, /obj/item/stack/gun_powder = 2, /obj/item/stack/sheet/mineral/phoron = 1) // 8 + 2 + 7 = 17 points
	output = list(/obj/item/ammo_magazine/packet/p9mm/incendiary = 1) // 30 points

//-------------------------
//plasma

/datum/assembly_craft/weapons/plasma_cells
	name = "WML plasma energy cell (x3)"
	input = list(/obj/item/stack/sheet/mineral/osmium = 10, /obj/item/stack/sheet/mineral/phoron = 10) // 60 + 70 = 130 points
	output = list(/obj/item/cell/lasgun/plasma = 3) // 100 points

/datum/assembly_craft/weapons/plasma_smg
	name = "PL-51 plasma SMG"
	craft_time = 40 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 15, /obj/item/stack/sheet/mineral/osmium = 30, /obj/item/stack/sheet/mineral/phoron = 10) // 120 + 180 + 70 = 370 points
	output = list(/obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/smg = 1) // 400 points

/datum/assembly_craft/weapons/plasma_rifle
	name = "PL-38 plasma rifle"
	craft_time = 35 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 15, /obj/item/stack/sheet/mineral/osmium = 25, /obj/item/stack/sheet/mineral/phoron = 10) // 120 + 150 + 70 = 340 points
	output = list(/obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/rifle = 1) // 350 points

/datum/assembly_craft/weapons/plasma_cannon
	name = "PL-96 plasma cannon"
	craft_time = 40 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 20, /obj/item/stack/sheet/mineral/osmium = 30, /obj/item/stack/sheet/mineral/phoron = 15) // 160 + 180 + 105 = 445 points
	output = list(/obj/item/weapon/gun/energy/lasgun/lasrifle/plasma/cannon = 1) // 400 points

//-------------------------
//scopes

/datum/assembly_craft/weapons/b11
	name = "B11 smart scope"
	input = list(/obj/item/stack/sheet/glass/glass = 5, /obj/item/stack/sheet/mineral/silver = 5, /obj/item/stack/sheet/mineral/copper = 5) // 10 + 40 + 20 = 70 points
	output = list(/obj/item/attachable/b11_scope = 1) // 150 points

/datum/assembly_craft/weapons/b15
	name = "B15 smart scope"
	input = list(/obj/item/stack/sheet/glass/glass = 5, /obj/item/stack/sheet/mineral/silver = 5, /obj/item/stack/sheet/mineral/copper = 5) // 10 + 40 + 20 = 70 points
	output = list(/obj/item/attachable/b15_scope = 1) // 150 points
