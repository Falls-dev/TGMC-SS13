/datum/supply_ui/vehicles/proc/set_driver_mod(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(!current_veh_type)
		return
	var/newtype = text2path(params["type"])
	if(!ispath(newtype, /obj/item/tank_module))
		return
	if(!(newtype in GLOB.armored_modtypes[current_veh_type]))
		return
	current_driver_mod = newtype
	return TRUE
