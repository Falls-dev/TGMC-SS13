/datum/supply_ui/vehicles/proc/set_secondary(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(!current_veh_type)
		return
	var/obj/item/armored_weapon/newtype = text2path(params["type"])
	if(!(newtype in GLOB.armored_guntypes[current_veh_type]))
		return
	if(initial(newtype.armored_weapon_flags) & MODULE_NOT_FABRICABLE)
		return
	current_secondary = newtype
	var/list/assoc_cast = GLOB.armored_gunammo[newtype]
	secondary_ammo = assoc_cast.Copy()
	for(var/ammo in secondary_ammo)
		secondary_ammo[ammo] = trunc(initial(newtype.max_ammo) / length(secondary_ammo))
	return TRUE
