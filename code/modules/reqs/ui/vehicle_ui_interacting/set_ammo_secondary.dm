/datum/supply_ui/vehicles/proc/set_ammo_secondary(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(!current_secondary)
		return
	var/obj/item/armored_weapon/weapon_type = current_primary
	var/newtype = text2path(params["type"])
	if(!(newtype in secondary_ammo))
		return
	var/non_adjusted_total = 0
	for(var/ammo in secondary_ammo)
		if(ammo == newtype)
			continue
		non_adjusted_total += secondary_ammo[ammo]
	var/newvalue = clamp(params["new_value"], 0, initial(weapon_type.max_ammo) - non_adjusted_total)
	secondary_ammo[newtype] = newvalue
	return TRUE
