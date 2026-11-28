/datum/unit_test/barsign_icons/Run()
	var/obj/machinery/barsign/barsign_type = /obj/machinery/barsign
	var/sign_icon = initial(barsign_type.icon)
	for(var/datum/barsign/sign_type as anything in subtypesof(/datum/barsign))
		var/icon_state = initial(sign_type.icon_state)
		if(!icon_state || !icon_exists(sign_icon, icon_state))
			TEST_FAIL("[sign_type] is missing its base icon state '[icon_state]'.")
			continue
		if(initial(sign_type.light_mask) && !icon_exists(sign_icon, "[icon_state]-light-mask"))
			TEST_FAIL("[sign_type] is missing its light mask '[icon_state]-light-mask'.")
