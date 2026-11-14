/datum/action/vehicle/sealed/armored/smoke_screen
	name = "Smokescreen"
	action_icon_state = "mech_smoke"
	keybinding_signals = list(KEYBINDING_NORMAL = COMSIG_MECHABILITY_SMOKE)
	///Uses of this ability remaining
	var/shots_remaining = 6

/datum/action/vehicle/sealed/armored/smoke_screen/New(Target)
	. = ..()
	visual_references[VREF_MUTABLE_AMMO_COUNTER] = mutable_appearance(null, null, ACTION_LAYER_MAPTEXT)

/datum/action/vehicle/sealed/armored/smoke_screen/action_activate(trigger_flags)
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	if(TIMER_COOLDOWN_RUNNING(chassis, COOLDOWN_ARMORED_SMOKE))
		return
	if(!shots_remaining)
		playsound(chassis.loc, 'sound/weapons/guns/interact/m92_cocked.ogg', 40, TRUE)
		return

	shots_remaining --
	chassis.visible_message("[chassis] pops smoke!")
	playsound(chassis.loc, 'sound/weapons/guns/fire/grenadelauncher.ogg', 80, TRUE)
	TIMER_COOLDOWN_START(chassis, COOLDOWN_ARMORED_SMOKE, 2 SECONDS)

	var/list/source_turfs = list()
	var/origin_turf  = chassis.hitbox.get_projectile_loc(src)
	source_turfs += get_step(origin_turf, turn(chassis.dir, -90))
	source_turfs += get_step(origin_turf, turn(chassis.dir, 90))

	var/datum/ammo/ammo_type = /datum/ammo/bullet/micro_rail/smoke_burst/tank
	for(var/turf/source_turf in source_turfs)
		var/turf/target_turf = get_ranged_target_turf(source_turf, get_dir(chassis, source_turf), 5)
		var/atom/movable/projectile/projectile_to_fire = new /atom/movable/projectile(source_turf)
		projectile_to_fire.generate_bullet(GLOB.ammo_list[ammo_type])
		if(chassis.hitbox?.tank_desants)
			projectile_to_fire.hit_atoms += chassis.hitbox.tank_desants
		projectile_to_fire.fire_at(target_turf, owner, chassis, projectile_to_fire.ammo.max_range, projectile_to_fire.projectile_speed)

	update_button_icon()

/datum/action/vehicle/sealed/armored/smoke_screen/update_button_icon()
	if(!button)
		return
	var/mutable_appearance/ammo_counter = visual_references[VREF_MUTABLE_AMMO_COUNTER]
	button.cut_overlay(visual_references[VREF_MUTABLE_AMMO_COUNTER])
	ammo_counter.maptext = MAPTEXT("[shots_remaining]/[initial(shots_remaining)]")
	visual_references[VREF_MUTABLE_AMMO_COUNTER] = ammo_counter
	button.add_overlay(ammo_counter)
	return ..()
