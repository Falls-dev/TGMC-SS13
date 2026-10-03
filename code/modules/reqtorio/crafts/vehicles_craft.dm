/datum/assembly_craft/vehicles
	group = "Vehicles"
	craft_time = 5 SECONDS

/datum/assembly_craft/vehicles/ltb_shells
	name = "LTB tank shell"
	input = list(/obj/item/stack/sheet/jeweler_steel = 2, /obj/item/stack/gun_powder = 5)
	output = list(/obj/item/ammo_magazine/tank/ltb_cannon = 1)

/datum/assembly_craft/vehicles/ltb_cannon_apfds
	name = "LTB tank APFDS shell"
	input = list(/obj/item/stack/sheet/jeweler_steel = 2, /obj/item/stack/gun_powder = 2)
	output = list(/obj/item/ammo_magazine/tank/ltb_cannon/apfds = 1)

/datum/assembly_craft/vehicles/ltb_cannon_TOW
	name = "TOW Launcher Magazine"
	input = list(/obj/item/stack/sheet/jeweler_steel = 1, /obj/item/stack/gun_powder = 2)
	output = list(/obj/item/ammo_magazine/tank/microrocket_rack = 1)

/datum/assembly_craft/vehicles/gl_explosive_tank_ammo
	name = "Tank grenade launcher magazine"
	input = list(/obj/item/stack/sheet/jeweler_steel = 1, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/ammo_magazine/tank/tank_glauncher = 1)

/datum/assembly_craft/vehicles/autocannon
	name = "Bushwhacker Autocannon APDS Box (30mm)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 1, /obj/item/stack/gun_powder = 2)
	output = list(/obj/item/ammo_magazine/tank/autocannon = 1)

/datum/assembly_craft/vehicles/autocannon_high_explosive
	name = "Bushwhacker Autocannon High Explosive Box (30mm)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 1, /obj/item/stack/gun_powder = 2)
	output = list(/obj/item/ammo_magazine/tank/autocannon/high_explosive = 1)
