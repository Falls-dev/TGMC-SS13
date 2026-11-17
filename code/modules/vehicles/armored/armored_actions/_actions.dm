/obj/vehicle/sealed/armored/generate_action_type()
	. = ..()
	if(istype(., /datum/action/vehicle/sealed/armored))
		var/datum/action/vehicle/sealed/armored/armor = .
		armor.chassis = src

///yes this is a blatant mech copypaste
/datum/action/vehicle/sealed/armored
	action_icon = 'icons/mob/actions/actions_mecha.dmi'
	///mech owner of this action
	var/obj/vehicle/sealed/armored/chassis

/datum/action/vehicle/sealed/armored/Destroy()
	chassis = null
	return ..()
