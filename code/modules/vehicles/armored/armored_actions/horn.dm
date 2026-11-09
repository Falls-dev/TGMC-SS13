/datum/action/vehicle/sealed/armored/horn
	name = "Honk Horn"
	action_icon = 'icons/mob/actions/actions_vehicle.dmi'
	action_icon_state = "car_horn"
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_KB_VEHICLEHONK,
	)

/datum/action/vehicle/sealed/armored/horn/action_activate(trigger_flags)
	if(!owner?.client || !chassis || !(owner in chassis.occupants))
		return
	if(TIMER_COOLDOWN_RUNNING(chassis, COOLDOWN_ARMORED_HORN))
		return

	chassis.visible_message("[chassis] honks its horn!")
	playsound(chassis.loc, 'sound/vehicles/horns/armored_horn.ogg', 70)
	TIMER_COOLDOWN_START(chassis, COOLDOWN_ARMORED_HORN, 15 SECONDS) //To keep people's eardrums intact
