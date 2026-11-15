GLOBAL_LIST_EMPTY(armored_gunammo)
GLOBAL_LIST_EMPTY(armored_modtypes)
GLOBAL_LIST_INIT(armored_guntypes, armored_init_guntypes())
GLOBAL_LIST_EMPTY(purchased_tanks)

///im a lazy bum who cant use initial on lists, so we just load everything into a list
/proc/armored_init_guntypes()
	. = list()
	for(var/obj/vehicle/sealed/armored/vehtype AS in typesof(/obj/vehicle/sealed/armored))
		vehtype = new vehtype
		GLOB.armored_modtypes[vehtype.type] = list()
		for(var/obj/item/tank_module/module AS in vehtype.permitted_mods)
			if(module::tank_mod_flags & TANK_MOD_NOT_FABRICABLE)
				continue
			GLOB.armored_modtypes[vehtype.type] += module

		.[vehtype.type] = list()
		for(var/obj/item/armored_weapon/weapon AS in vehtype.permitted_weapons)
			if(weapon::armored_weapon_flags & MODULE_NOT_FABRICABLE)
				continue
			.[vehtype.type] += weapon
		vehtype.Destroy()
	for(var/obj/item/armored_weapon/gun AS in typesof(/obj/item/armored_weapon))
		gun = new gun
		GLOB.armored_gunammo[gun.type] = list()
		for(var/obj/item/ammo_magazine/magazine AS in gun.accepted_ammo)
			if(magazine::magazine_flags & MAGAZINE_NOT_FABRICABLE)
				continue
			GLOB.armored_gunammo[gun.type] += magazine
		gun.Destroy()

/datum/supply_ui/vehicles
	tgui_name = "VehicleSupply"
	shuttle_id = SHUTTLE_VEHICLE_SUPPLY
	home_id = "vehicle_home"
	/// current selected vehicles typepath
	var/current_veh_type
	/// current selected primary weapons typepath
	var/current_primary
	/// current selected secondaryies typepath
	var/current_secondary
	/// current driver mod typepath
	var/current_driver_mod
	/// current gunner mod typepath
	var/current_gunner_mod
	/// current primary ammo list, type = count
	var/list/primary_ammo = list()
	/// current secondary ammo list, type = count
	var/list/secondary_ammo = list()

/datum/supply_ui/vehicles/ui_static_data(mob/user)
	var/list/data = list()
	for(var/obj/vehicle/sealed/armored/vehtype AS in typesof(/obj/vehicle/sealed/armored))
		var/flags = vehtype::armored_flags

		if(flags & ARMORED_PURCHASABLE_TRANSPORT)
			if(user.skills.getRating(SKILL_LARGE_VEHICLE) < SKILL_LARGE_VEHICLE_EXPERIENCED)
				continue
		else if(flags & ARMORED_PURCHASABLE_ASSAULT)
			if(user.skills.getRating(SKILL_LARGE_VEHICLE) < SKILL_LARGE_VEHICLE_VETERAN)
				continue
		else
			continue

		data["vehicles"] += list(list("name" = initial(vehtype.name), "desc" = initial(vehtype.desc), "type" = "[vehtype]", "isselected" = (vehtype == current_veh_type)))
		if(vehtype != current_veh_type)
			continue
		for(var/obj/item/armored_weapon/gun AS in GLOB.armored_guntypes[vehtype])
			var/primary_selected = (current_primary == gun)
			var/secondary_selected = (current_secondary == gun)
			if(initial(gun.armored_weapon_flags) & MODULE_PRIMARY)
				data["primaryWeapons"] += list(list(
					"name" = initial(gun.name),
					"desc" = initial(gun.desc),
					"type" = gun,
					"isselected" = primary_selected,
				))

				if(primary_selected)
					for(var/obj/item/ammo_magazine/mag AS in primary_ammo)
						data["primaryammotypes"] += list(list(
							"name" = initial(mag.name),
							"type" = mag,
							"current" = primary_ammo[mag],
							"max" = initial(gun.max_ammo),
						))

			if(initial(gun.armored_weapon_flags) & MODULE_SECONDARY)
				data["secondaryWeapons"] += list(list(
					"name" = initial(gun.name),
					"desc" = initial(gun.desc),
					"type" = gun,
					"isselected" = secondary_selected,
				))
				if(secondary_selected)
					for(var/obj/item/ammo_magazine/mag AS in secondary_ammo)
						data["secondarymmotypes"] += list(list(
							"name" = initial(mag.name),
							"type" = mag,
							"current" = secondary_ammo[mag],
							"max" = initial(gun.max_ammo),
						))

		for(var/obj/item/tank_module/mod AS in GLOB.armored_modtypes[vehtype])
			if(initial(mod.is_driver_module))
				data["driverModules"] += list(list(
					"name" = initial(mod.name),
					"desc" = initial(mod.desc),
					"type" = mod,
					"isselected" = (current_driver_mod == mod),
				))
			else
				data["gunnerModules"] += list(list(
					"name" = initial(mod.name),
					"desc" = initial(mod.desc),
					"type" = mod,
					"isselected" = (current_gunner_mod == mod),
				))
	return data

/datum/supply_ui/vehicles/ui_data(mob/living/user)
	var/list/data = list()
	if(supply_shuttle)
		if(supply_shuttle?.mode == SHUTTLE_CALL)
			if(is_mainship_level(supply_shuttle.destination.z))
				data["elevator"] = "Raising"
				data["elevator_dir"] = "up"
			else
				data["elevator"] = "Lowering"
				data["elevator_dir"] = "down"
		else if(supply_shuttle?.mode == SHUTTLE_IDLE)
			if(is_mainship_level(supply_shuttle.z))
				data["elevator"] = "Raised"
				data["elevator_dir"] = "down"
			else if(current_veh_type)
				data["elevator"] = "Purchase"
				data["elevator_dir"] = "store"
			else
				data["elevator"] = "Lowered"
				data["elevator_dir"] = "up"
		else
			if(is_mainship_level(supply_shuttle.z))
				data["elevator"] = "Lowering"
				data["elevator_dir"] = "down"
			else
				data["elevator"] = "Raising"
				data["elevator_dir"] = "up"
	else
		data["elevator"] = "MISSING!"
	return data

/datum/supply_ui/vehicles/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("setvehicle")
			. = set_vehicle(action, params, ui, state)

		if("setprimary")
			. = set_primary(action, params, ui, state)


		if("setsecondary")
			. = set_secondary(action, params, ui, state)

		if("set_ammo_primary")
			. = set_ammo_primary(action, params, ui, state)


		if("set_ammo_secondary")
			. = set_ammo_secondary(action, params, ui, state)

		if("set_driver_mod")
			. = set_driver_mod(action, params, ui, state)


		if("set_gunner_mod")
			. = set_gunner_mod(action, params, ui, state)


	if(.)
		update_static_data(usr)

