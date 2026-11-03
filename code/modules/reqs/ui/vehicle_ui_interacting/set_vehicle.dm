/datum/supply_ui/vehicles/proc/set_vehicle(action, list/params, datum/tgui/ui, datum/ui_state/state)
	var/newtype = text2path(params["type"])
	if(!ispath(newtype, /obj/vehicle/sealed/armored))
		return
	var/obj/vehicle/sealed/armored/tank_type = newtype
	var/is_assault = initial(tank_type.armored_flags) & ARMORED_PURCHASABLE_ASSAULT
	if(GLOB.purchased_tanks[usr.faction]?["[is_assault]"])
		to_chat(usr, span_danger("A vehicle of this type has already been purchased!"))
		return
	current_veh_type = newtype
	current_primary = null
	current_secondary = null
	current_driver_mod = null
	current_gunner_mod = null
	primary_ammo = list()
	secondary_ammo = list()
	return TRUE
