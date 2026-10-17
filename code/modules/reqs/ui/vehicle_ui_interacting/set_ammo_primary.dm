/datum/supply_ui/vehicles/proc/set_ammo_primary(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(!current_primary)
		return
	var/obj/item/armored_weapon/weapon_type = current_primary
	var/newtype = text2path(params["type"])
	if(!(newtype in primary_ammo))
		return
	var/non_adjusted_total = 0
	for(var/ammo in primary_ammo)
		if(ammo == newtype)
			continue
		non_adjusted_total += primary_ammo[ammo]
	var/newvalue = clamp(params["new_value"], 0, initial(weapon_type.max_ammo) - non_adjusted_total)
	primary_ammo[newtype] = newvalue
	return TRUE
