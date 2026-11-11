/obj/structure/ship_ammo/get_mechanics_info()
	. = ..()

	. += "<h3>Combat Information</h3>"

	if(travelling_time)
		var/timetohit = travelling_time * 0.1
		. += "Time to drop = [timetohit] seconds.<br>"
	if(ammo_type == CAS_30MM)
		. += "Ammo count = [ammo_count].<br>"
		. += "Ammo per firing = [ammo_used_per_firing].<br>"
		. += "The force of the bullets = [EXPLODE_LIGHT].<br>"
	if(explosion_power)
		. += "The force of the explosion = [explosion_power].<br>"
	if(explosion_falloff)
		. += "Explosion will lose [explosion_falloff] power per turf.<br>"
	if(!prediction_type)
		return
	var/prediction_type_string = "ERROR"
	switch(prediction_type)
		if(CAS_AMMO_EXPLOSIVE)
			prediction_type_string = "high-explosive rocket."
		if(CAS_AMMO_INCENDIARY)
			prediction_type_string = "incendiary rocket. Radius of fire  = [fire_range] tiles."
		if(CAS_AMMO_HARMLESS)
			prediction_type_string = "harmless rocket. It doesn't deal any damage."
	. += "Ammo type: [prediction_type_string]<br>"
