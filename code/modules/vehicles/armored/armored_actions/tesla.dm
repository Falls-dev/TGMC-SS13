/datum/action/vehicle/sealed/armored/tesla
	name = "Tesla"
	action_icon_state = "pulsearmor"
	keybinding_signals = list(KEYBINDING_NORMAL = COMSIG_VEHICLEABILITY_TESLA)
	COOLDOWN_DECLARE(tesla_cooldown)

/datum/action/vehicle/sealed/armored/tesla/remove_action(mob/M)
	clear_effects()
	return ..()

/datum/action/vehicle/sealed/armored/tesla/action_activate(trigger_flags)
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	if(!COOLDOWN_FINISHED(src, tesla_cooldown))
		chassis.balloon_alert(owner, "wait [DisplayTimeText(COOLDOWN_TIMELEFT(src, tesla_cooldown))]!")
		return

	chassis.visible_message("[chassis] becomes electrified!")
	playsound(chassis.loc, 'sound/magic/lightningshock.ogg', 100, TRUE)
	COOLDOWN_START(src, tesla_cooldown, 30 SECONDS)
	chassis.add_filter("vehicle_tesla", 1, outline_filter(1, COLOR_PULSE_BLUE))
	addtimer(CALLBACK(src, PROC_REF(clear_effects)), 1 SECONDS)

	for(var/mob/living/mob_desant in chassis?.hitbox?.tank_desants)
		mob_desant.Stun(0.2 SECONDS)
		var/away_dir = REVERSE_DIR(get_dir(mob_desant, chassis) || pick(GLOB.alldirs))
		var/turf/target = get_ranged_target_turf(mob_desant, away_dir, 3)
		mob_desant.throw_at(target, 3, 3, chassis)

/datum/action/vehicle/sealed/armored/tesla/proc/clear_effects()
	chassis?.remove_filter("vehicle_tesla")
