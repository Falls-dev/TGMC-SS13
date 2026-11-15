/datum/action/vehicle/sealed/armored/toggle_lights
	name = "Toggle Lights"
	action_icon_state = "mech_lights_off"

/datum/action/vehicle/sealed/armored/toggle_lights/action_activate(trigger_flags)
	if(!owner || !chassis || !(owner in chassis.occupants))
		return

	if(!(chassis.armored_flags & ARMORED_HAS_HEADLIGHTS))
		chassis.balloon_alert(owner, "the vehicle's lights are broken!")
		return
	chassis.armored_flags ^= ARMORED_LIGHTS_ON
	if(chassis.armored_flags & ARMORED_LIGHTS_ON)
		action_icon_state = "mech_lights_on"
	else
		action_icon_state = "mech_lights_off"
	chassis.set_light_on(chassis.armored_flags & ARMORED_LIGHTS_ON)
	chassis.balloon_alert(owner, "toggled lights [chassis.armored_flags & ARMORED_LIGHTS_ON ? "on":"off"]")
	playsound(chassis,'sound/mecha/brass_skewer.ogg', 40, TRUE)
	chassis.log_message("Toggled lights [(chassis.armored_flags & ARMORED_LIGHTS_ON)?"on":"off"].", LOG_MECHA)
	update_button_icon()
