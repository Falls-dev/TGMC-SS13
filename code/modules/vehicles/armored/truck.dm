/obj/vehicle/sealed/armored/multitile/mrap
	name = "\improper MRAP - Sambar"
	desc = "An unarmed MRAP designed to transport troops across the battlefield quickly and safely."
	icon = 'icons/obj/armored/2x3/apc.dmi'
	icon_state = "apc"
	damage_icon_path = 'icons/obj/armored/2x3/apc_damage_overlay.dmi'
	hitbox = /obj/hitbox/two_three
	interior = /datum/interior/armored/mrap
	permitted_weapons = NONE
	permitted_mods = list(/obj/item/tank_module/ability/tesla)
	armored_flags = ARMORED_HAS_HEADLIGHTS|ARMORED_HAS_UNDERLAY|ARMORED_WRECKABLE|ARMORED_PURCHASABLE_TRANSPORT|ARMORED_SELF_WALL_DAMAGE
	required_entry_skill = SKILL_LARGE_VEHICLE_DEFAULT
	minimap_icon_state = "apc"
	turret_icon = null
	crushes_weeds = FALSE
	pixel_x = -24
	pixel_y = -32
	pixel_w = 0
	pixel_z = 0
	max_integrity = 900
	soft_armor = list(MELEE = 50, BULLET = 100 , LASER = 90, ENERGY = 60, BOMB = 60, BIO = 100, FIRE = 50, ACID = 50)
	hard_armor = list(MELEE = 0, BULLET = 20, LASER = 20, ENERGY = 20, BOMB = 0, BIO = 20, FIRE = 0, ACID = 0)
	max_occupants = 12
	enter_delay = 0.4 SECONDS
	ram_damage = 30
	move_delay = 0.15 SECONDS
	glide_size = 8.5
	easy_load_list = list(
		/obj/item/ammo_magazine/tank,
		/obj/structure/largecrate,
		/obj/structure/closet/crate,
	)

/obj/vehicle/sealed/armored/multitile/mrap/Initialize(mapload)
	. = ..()
	var/obj/item/tank_module/module = new /obj/item/tank_module/ability/tesla()
	module.on_equip(src)

/obj/vehicle/sealed/armored/multitile/mrap/setDir(newdir)
	. = ..()
	if(armored_flags & ARMORED_IS_WRECK)
		update_smoke_dir(null, null, newdir)

/obj/vehicle/sealed/armored/multitile/mrap/enter_locations(atom/movable/entering_thing)
	var/first_turf = get_step_away(get_step(src, REVERSE_DIR(dir)), src, 2)
	return list(
		first_turf,
		get_step(first_turf, turn(dir, -90)),
	)

/obj/vehicle/sealed/armored/multitile/mrap/wreck_vehicle()
	. = ..()
	update_smoke_dir(newdir = dir)

/obj/vehicle/sealed/armored/multitile/mrap/update_smoke_dir(datum/source, dir, newdir)
	switch(newdir)
		if(SOUTH)
			smoke_holder.particles.position = list(20, 16, 0)
		if(NORTH)
			smoke_holder.particles.position = list(-4, 73, 0)
		if(EAST)
			smoke_holder.particles.position = list(70, 35, 0)
		if(WEST)
			smoke_holder.particles.position = list(10, 35, 0)

/obj/vehicle/sealed/armored/multitile/mrap/campaign
	armored_flags = ARMORED_HAS_HEADLIGHTS|ARMORED_HAS_UNDERLAY|ARMORED_WRECKABLE
	max_integrity = 1100
	soft_armor = list(MELEE = 90, BULLET = 90 , LASER = 90, ENERGY = 90, BOMB = 85, BIO = 100, FIRE = 100, ACID = 75)
	hard_armor = list(MELEE = 5, BULLET = 5, LASER = 5, ENERGY = 5, BOMB = 20, BIO = 100, FIRE = 0, ACID = 0)
	facing_modifiers = list(VEHICLE_FRONT_ARMOUR = 0.7, VEHICLE_SIDE_ARMOUR = 1, VEHICLE_BACK_ARMOUR = 1.5)




/datum/interior/armored/logi
	template = /datum/map_template/interior/logi

/datum/map_template/interior/logi
	name = "transport truck interior template"
	filename = "logitruck"

/obj/vehicle/sealed/armored/multitile/mrap/logi
	name = "\improper TransCO 'Roadmaster' Logistics Truck"
	desc = "A lightly armored logistic transport vehicle designed to transport trade goods across the earth wherever necessary while being able to outrun and take a few shots from the usual raider interception. It comes after-market equipped with tesla coils due to the xenomorph threats."
	icon = 'icons/tgmc_erp/obj/vehicles/transport_truck.dmi'
	damage_icon_path = 'icons/tgmc_erp/obj/vehicles/transport_truck.dmi'
	icon_state = "truck_enclosed"
	hitbox = /obj/hitbox/two_three
	interior = /datum/interior/armored/logi
	permitted_weapons = NONE
	permitted_mods = list(/obj/item/tank_module/ability/tesla)
	armored_flags = ARMORED_HAS_HEADLIGHTS|ARMORED_WRECKABLE|ARMORED_SELF_WALL_DAMAGE
	required_entry_skill = SKILL_LARGE_VEHICLE_DEFAULT
	minimap_icon_state = null
	turret_icon = null
	pixel_x = -16
	pixel_y = -40
	max_integrity = 700
	soft_armor = list(MELEE = 50, BULLET = 80 , LASER = 80, ENERGY = 70, BOMB = 30, BIO = 100, FIRE = 100, ACID = 50)
	hard_armor = list(MELEE = 0, BULLET = 5, LASER = 5, ENERGY = 5, BOMB = 5, BIO = 100, FIRE = 0, ACID = 0)
	facing_modifiers = list(VEHICLE_FRONT_ARMOUR = 0.8, VEHICLE_SIDE_ARMOUR = 1, VEHICLE_BACK_ARMOUR = 1.2) //not too much diff
	ram_damage = 150
	move_delay = 0.1 SECONDS
	glide_size = 9
	easy_load_list = list(
		/obj/item/ammo_magazine/tank,
		/obj/structure/largecrate,
		/obj/structure/closet/crate,
	)

/obj/vehicle/sealed/armored/multitile/mrap/logi/treads
	name = "\improper TransCO 'Roughauler' Treaded Military Truck"
	desc = "A treaded, armored logistic transport vehicle, designed to transport troops and supplies wherever necessary, relatively quickly and hopefully in one piece thanks to it's ballistic plating. It's threads make it possible to turn on spot, be immune to flat tires, resist side-shots and traverse rough terrain, probably.  It comes after-market equipped with tesla coils due to the xenomorph threats."
	icon = 'icons/tgmc_erp/obj/vehicles/large_truck.dmi'
	damage_icon_path = 'icons/tgmc_erp/obj/vehicles/large_truck.dmi'
	icon_state = "truck_enclosed_treads"
	hitbox = /obj/hitbox/medium
	max_integrity = 800
	soft_armor = list(MELEE = 50, BULLET = 80 , LASER = 80, ENERGY = 70, BOMB = 50, BIO = 100, FIRE = 100, ACID = 55)
	hard_armor = list(MELEE = 0, BULLET = 10, LASER = 10, ENERGY = 10, BOMB = 10, BIO = 100, FIRE = 0, ACID = 0)
	facing_modifiers = list(VEHICLE_FRONT_ARMOUR = 0.8, VEHICLE_SIDE_ARMOUR = 0.8, VEHICLE_BACK_ARMOUR = 1.2) //tracks are armored yay
	move_delay = 0.2 SECONDS
	glide_size = 7

/obj/vehicle/sealed/armored/multitile/mrap/logi/treads/enter_locations(atom/movable/entering_thing)
	return list(get_step(src, REVERSE_DIR(dir)))
