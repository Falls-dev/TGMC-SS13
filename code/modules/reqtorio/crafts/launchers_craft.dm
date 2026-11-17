/datum/assembly_craft/launchers
	group = "Launchers"
	craft_time = 5 SECONDS

//RL-72
/datum/assembly_craft/launchers/disposable_rocket_launcher
	name = "\improper RL-72 disposable rocket launcher"
	craft_time = 10 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 4, /obj/item/stack/gun_powder = 5) // 32 + 5 = 37 points
	output = list(/obj/item/weapon/gun/launcher/rocket/oneuse = 1) // 100 points

//RL-160
/datum/assembly_craft/launchers/standard_recoilless
	name = "\improper RL-160 recoilless rifle"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 20, /obj/item/stack/sheet/mineral/osmium = 20, /obj/item/stack/sheet/mineral/platinum = 5) // 160 + 120 + 60 = 340 points
	output = list(/obj/item/weapon/gun/launcher/rocket/recoillessrifle = 1) // 400 points

/datum/assembly_craft/launchers/standard_recoilless_refill
	name = "RL-160 RR HE shell"
	input = list(/obj/item/stack/sheet/jeweler_steel = 1, /obj/item/stack/gun_powder = 3) // 7 + 3 = 10 points
	output = list(/obj/item/ammo_magazine/rocket/recoilless = 1) // 30 points

/datum/assembly_craft/launchers/light_recoilless_refill
	name = "RL-160 RR LE shell"
	input = list(/obj/item/stack/sheet/jeweler_steel = 1, /obj/item/stack/gun_powder = 3) // 7 + 3 = 10 points
	output = list(/obj/item/ammo_magazine/rocket/recoilless/light = 1) // 30 points

/datum/assembly_craft/launchers/heat_recoilless_refill
	name = "RL-160 HEAT shell"
	input = list(/obj/item/stack/sheet/jeweler_steel = 1, /obj/item/stack/gun_powder = 3) // 7 + 3 = 10 points
	output = list(/obj/item/ammo_magazine/rocket/recoilless/heat = 1) // 30 points

/datum/assembly_craft/launchers/smoke_recoilless_refill
	name = "RL-160 RR smoke shell"
	input = list(/obj/item/stack/sheet/jeweler_steel = 1, /obj/item/stack/gun_powder = 3) // 7 + 3 = 10 points
	output = list(/obj/item/ammo_magazine/rocket/recoilless/smoke = 1) // 30 points

/datum/assembly_craft/launchers/cloak_recoilless_refill
	name = "RL-160 RR cloak shell"
	input = list(/obj/item/stack/sheet/jeweler_steel = 1, /obj/item/stack/gun_powder = 3) // 7 + 3 = 10 points
	output = list(/obj/item/ammo_magazine/rocket/recoilless/cloak = 1) // 30 points

//RL-57
/datum/assembly_craft/launchers/t57
	name = "RL-57 quad thermobaric launcher"
	craft_time = 30 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 25, /obj/item/stack/sheet/mineral/osmium = 25, /obj/item/stack/sheet/jeweler_steel = 10) // 200 + 150 + 66 = 416 points
	output = list(/obj/item/weapon/gun/launcher/rocket/m57a4/t57 = 1) // 550 points

/datum/assembly_craft/launchers/m57a4
	name = "84mm thermobaric rocket array"
	input = list(/obj/item/stack/sheet/jeweler_steel = 4, /obj/item/stack/gun_powder = 8) // 26 + 8 = 34 points
	output = list(/obj/item/ammo_magazine/rocket/m57a4 = 1) // 50 points

//RL-152
/datum/assembly_craft/launchers/sadar
	name = "RL-152 SADAR rocket launcher"
	craft_time = 45 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 25, /obj/item/stack/sheet/mineral/osmium = 50, /obj/item/stack/sheet/jeweler_steel = 20, /obj/item/stack/sheet/mineral/platinum = 10) // 200 + 300 + 132 + 120 = 752 points
	output = list(/obj/item/weapon/gun/launcher/rocket/sadar = 1) // 800 points

/datum/assembly_craft/launchers/sadar_he
	name = "RL-152 SADAR HE rocket"
	input = list(/obj/item/stack/sheet/jeweler_steel = 3, /obj/item/stack/gun_powder = 5) // 20 + 5 = 25 points
	output = list(/obj/item/ammo_magazine/rocket/sadar = 1) // 50 points

/datum/assembly_craft/launchers/sadar_he_unguided
	name = "RL-152 SADAR HE rocket (unguided)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 3, /obj/item/stack/gun_powder = 5) // 20 + 5 = 25 points
	output = list(/obj/item/ammo_magazine/rocket/sadar/unguided = 1) // 50 points

/datum/assembly_craft/launchers/sadar_ap
	name = "RL-152 SADAR AP rocket"
	input = list(/obj/item/stack/sheet/jeweler_steel = 3, /obj/item/stack/gun_powder = 5) // 20 + 5 = 25 points
	output = list(/obj/item/ammo_magazine/rocket/sadar/ap = 1) // 60 points

/datum/assembly_craft/launchers/sadar_wp
	name = "RL-152 SADAR WP rocket"
	input = list(/obj/item/stack/sheet/jeweler_steel = 3, /obj/item/stack/gun_powder = 8) // 20 + 8 = 28 points
	output = list(/obj/item/ammo_magazine/rocket/sadar/wp = 1) // 40 points

/datum/assembly_craft/launchers/sadar_wp_unguided
	name = "RL-152 SADAR WP rocket (unguided)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 3, /obj/item/stack/gun_powder = 8) // 20 + 8 = 28 points
	output = list(/obj/item/ammo_magazine/rocket/sadar/wp/unguided = 1) // 40 points

//GL-54
/datum/assembly_craft/launchers/tx54
	name = "GL-54 grenade launcher"
	craft_time = 30 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 15, /obj/item/stack/sheet/mineral/osmium = 20, /obj/item/stack/sheet/mineral/platinum = 3) // 120 + 120 + 36 = 276 points
	output = list(/obj/item/weapon/gun/rifle/tx54 = 1) // 300 points

/datum/assembly_craft/launchers/tx54_magazine
	name = "20mm airburst grenade magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 1, /obj/item/stack/gun_powder = 2) // 6 + 2 = 8 points
	output = list(/obj/item/ammo_magazine/rifle/tx54 = 1) // 20 points

/datum/assembly_craft/launchers/tx54_incendiary
	name = "20mm incendiary grenade magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 1, /obj/item/stack/gun_powder = 5) // 6 + 5 = 11 points
	output = list(/obj/item/ammo_magazine/rifle/tx54/incendiary = 1) // 60 points

/datum/assembly_craft/launchers/tx54_smoke
	name = "20mm tactical smoke grenade magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 1, /obj/item/stack/gun_powder = 1) // 6 + 1 = 7 points
	output = list(/obj/item/ammo_magazine/rifle/tx54/smoke = 1) // 12 points

/datum/assembly_craft/launchers/tx54_smoke_dense
	name = "20mm smoke grenade magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 1, /obj/item/stack/gun_powder = 1) // 6 + 1 = 7 points
	output = list(/obj/item/ammo_magazine/rifle/tx54/smoke/dense = 1) // 8 points

/datum/assembly_craft/launchers/tx54_smoke_tangle
	name = "20mm tanglefoot grenade magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 1, /obj/item/stack/gun_powder = 3, /obj/item/stack/sheet/mineral/phoron = 5) // 6 + 3 + 35 = 44 points
	output = list(/obj/item/ammo_magazine/rifle/tx54/smoke/tangle = 1) // 48 points

/datum/assembly_craft/launchers/tx54_razor
	name = "20mm razorburn grenade magazine"
	input = list(/obj/item/explosive/grenade/chem_grenade/razorburn_small = 10, /obj/item/stack/gun_powder = 20) // 20 points
	output = list(/obj/item/ammo_magazine/rifle/tx54/razor = 1)

//GL-81
/datum/assembly_craft/launchers/gl81
	name = "GL-81 grenade launcher"
	craft_time = 10 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 5, /obj/item/stack/sheet/mineral/osmium = 5) // 40 + 30 = 70 points
	output = list(/obj/item/weapon/gun/grenade_launcher/single_shot = 1) // 150 points

//GL-70
/datum/assembly_craft/launchers/gl70
	name = "GL-70 grenade launcher"
	craft_time = 15 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 10, /obj/item/stack/sheet/mineral/osmium = 10, /obj/item/stack/sheet/mineral/platinum = 2) // 80 + 60 + 24 = 164 points
	output = list(/obj/item/weapon/gun/grenade_launcher/multinade_launcher = 1) // 300 points
