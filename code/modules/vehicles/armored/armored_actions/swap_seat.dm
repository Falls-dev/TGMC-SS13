/datum/action/vehicle/sealed/armored/swap_seat
	name = "Switch Seats"
	action_icon_state = "mech_seat_swap"

#define ARMOR_DRIVER "Driver"
#define ARMOR_GUNNER "Gunner"
#define ARMOR_PASSENGER "Passenger"

/datum/action/vehicle/sealed/armored/swap_seat/action_activate(trigger_flags)
	if(!transfer_checks())
		return
	var/list/choices = list()
	if(!chassis.is_driver(owner))
		choices += ARMOR_DRIVER
	if(!chassis.is_equipment_controller(owner))
		choices += ARMOR_GUNNER
	choices += ARMOR_PASSENGER
	var/choice = tgui_input_list(owner, "Select a seat", chassis.name, choices)
	if(!choice)
		return
	if(!transfer_checks(choice))
		return
	chassis.balloon_alert(owner, "moving to other seat...")
	if(!do_after(owner, chassis.enter_delay, target = chassis, extra_checks=CALLBACK(src, PROC_REF(transfer_checks), choice)))
		chassis.balloon_alert(owner, "interrupted!")
		return
	chassis.remove_control_flags(owner, VEHICLE_CONTROL_MELEE|VEHICLE_CONTROL_EQUIPMENT|VEHICLE_CONTROL_DRIVE|VEHICLE_CONTROL_SETTINGS)
	switch(choice)
		if(ARMOR_GUNNER)
			chassis.balloon_alert(owner, "controlling gunner seat")
			chassis.add_control_flags(owner, VEHICLE_CONTROL_MELEE|VEHICLE_CONTROL_EQUIPMENT)
		if(ARMOR_DRIVER)
			chassis.balloon_alert(owner, "controlling pilot seat")
			chassis.add_control_flags(owner, VEHICLE_CONTROL_DRIVE|VEHICLE_CONTROL_SETTINGS)
		if(ARMOR_PASSENGER)
			chassis.balloon_alert(owner, "entered passenger seat")

///checks if owner can still transfer
/datum/action/vehicle/sealed/armored/swap_seat/proc/transfer_checks(choice)
	if(!owner || !chassis || !(owner in chassis.occupants))
		return FALSE
	if(length(chassis.occupants) >= chassis.max_occupants)
		chassis.balloon_alert(owner, "other seats occupied!")
		return FALSE
	switch(choice)
		if(ARMOR_GUNNER)
			if(length(chassis.return_controllers_with_flag(VEHICLE_CONTROL_EQUIPMENT)) >= 1)
				chassis.balloon_alert(owner, "gunner occupied!")
				return FALSE
		if(ARMOR_DRIVER)
			if(chassis.driver_amount() >= chassis.max_drivers)
				chassis.balloon_alert(owner, "driver occupied!")
				return FALSE
	return TRUE

#undef ARMOR_DRIVER
#undef ARMOR_GUNNER
#undef ARMOR_PASSENGER
