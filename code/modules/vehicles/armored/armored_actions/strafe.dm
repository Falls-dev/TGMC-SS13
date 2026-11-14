/datum/action/vehicle/sealed/armored/strafe
	name = "Toggle Strafing. Disabled when Alt is held."
	action_icon_state = "strafe"
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_MECHABILITY_TOGGLE_STRAFE,
	)

/datum/action/vehicle/sealed/armored/strafe/action_activate(trigger_flags)
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	chassis.toggle_strafe()

///Toggles strafemode on or off
/obj/vehicle/sealed/armored/proc/toggle_strafe()
	strafe = !strafe

	for(var/occupant in occupants)
		balloon_alert(occupant, "Strafing mode [strafe?"on":"off"].")
		var/datum/action/action = LAZYACCESSASSOC(occupant_actions, occupant, /datum/action/vehicle/sealed/armored/strafe)
		action?.update_button_icon()
