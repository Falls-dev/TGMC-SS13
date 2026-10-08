/datum/game_mode/infestation/nuclear_war
	name = "Nuclear War"
	config_tag = "Nuclear War"
	human_dnr_ticks = TIME_BEFORE_DNR * 3 // 15 minutes at 2 seconds per human life tick.
	xenorespawn_time = 30 SECONDS
	silo_scaling = 0 //just in case
	max_silo_ammount = 0
	/// How often the marine/xeno population balance is checked.
	var/larva_check_interval = 30 SECONDS
	var/last_larva_check = 0
	round_type_flags = MODE_INFESTATION|MODE_XENO_SPAWN_PROTECT|MODE_LATE_OPENING_SHUTTER_TIMER|MODE_PSY_POINTS|MODE_PSY_POINTS_ADVANCED|MODE_DEAD_GRAB_FORBIDDEN|MODE_HIJACK_POSSIBLE|MODE_SILO_RESPAWN|MODE_SILO_NO_LARVA|MODE_ALLOW_XENO_QUICKBUILD|MODE_HAS_EXCAVATION|MODE_HAS_MINERS
	xeno_abilities_flags = ABILITY_DISTRESS
	valid_job_types = list(
		/datum/job/terragov/command/captain = 1,
		/datum/job/terragov/command/fieldcommander = 1,
		/datum/job/terragov/command/staffofficer = 4,
		/datum/job/terragov/command/pilot = 1,
		/datum/job/terragov/command/transportofficer = 1,
		/datum/job/terragov/requisitions/tech = 2,
		/datum/job/terragov/requisitions/officer = 1,
		/datum/job/terragov/medical/professor = 1,
		/datum/job/terragov/medical/medicalofficer = 4,
		/datum/job/terragov/medical/researcher = 2,
		/datum/job/terragov/civilian/liaison = 1,
		/datum/job/terragov/civilian/clown = -1,
		/datum/job/terragov/silicon/synthetic = 1,
		/datum/job/terragov/command/mech_pilot = 0,
		/datum/job/terragov/command/assault_crewman = 2,
		/datum/job/terragov/command/transport_crewman = 1,
		/datum/job/terragov/silicon/ai = 1,
		/datum/job/terragov/squad/engineer = 1,
		/datum/job/terragov/squad/corpsman = 1,
		/datum/job/terragov/squad/smartgunner = 1,
		/datum/job/terragov/squad/leader = 1,
		/datum/job/terragov/squad/standard = -1,
		/datum/job/terragov/squad/robot = -1,
		/datum/job/xenomorph = FREE_XENO_AT_START,
		/datum/job/xenomorph/queen = 1,
		/datum/job/survivor/rambo = 1,
	)
	job_points_needed_by_job_type = list(
		/datum/job/terragov/squad/smartgunner = 20,
		/datum/job/terragov/squad/corpsman = 5,
		/datum/job/terragov/squad/engineer = 5,
		/datum/job/xenomorph = NUCLEAR_WAR_LARVA_POINTS_NEEDED,
	)

/datum/game_mode/infestation/nuclear_war/pre_setup()
	// Spawn silos at their map landmarks; clear the fog boundary before parent setup.
	for(var/turf/spawn_turf AS in GLOB.xeno_resin_silo_turfs)
		new /obj/structure/xeno/silo/nuclear_war(spawn_turf)
	GLOB.xeno_spawn_protection_locations.Cut()
	return ..()

/datum/game_mode/infestation/nuclear_war/post_setup()
	. = ..()

	SSpoints.add_psy_points(XENO_HIVE_NORMAL, 600)

	for(var/obj/effect/landmark/corpsespawner/corpse AS in GLOB.corpse_landmarks_list)
		corpse.create_mob()

	for(var/mob/living/carbon/xenomorph/larva/xeno in GLOB.alive_xeno_list)
		xeno.evolution_stored = xeno.xeno_caste.evolution_threshold //Immediate roundstart evo for larva.

	for(var/i in GLOB.nuke_spawn_locs)
		new /obj/machinery/nuclearbomb(i)
	generate_nuke_disk_spawners()

	RegisterSignal(SSdcs, COMSIG_GLOB_NUKE_EXPLODED, PROC_REF(on_nuclear_explosion))
	RegisterSignal(SSdcs, COMSIG_GLOB_NUKE_DIFFUSED, PROC_REF(on_nuclear_diffuse))
	RegisterSignal(SSdcs, COMSIG_GLOB_NUKE_START, PROC_REF(on_nuke_started))

/datum/game_mode/infestation/nuclear_war/process()
	. = ..()
	if(round_finished)
		return
	if(world.time > last_larva_check + larva_check_interval)
		last_larva_check = world.time
		balance_scales()

/// Adds more xeno job slots if needed.
/datum/game_mode/infestation/nuclear_war/proc/balance_scales()
	var/datum/hive_status/normal/xeno_hive = GLOB.hive_datums[XENO_HIVE_NORMAL]
	var/datum/job/xeno_job = SSjob.GetJobType(/datum/job/xenomorph)
	// Spawn more xenos to help maintain the ratio.
	var/xenomorphs_below_ratio = trunc(get_jobpoint_difference() / xeno_job.job_points_needed)
	if(xenomorphs_below_ratio >= 1)
		xeno_job.add_job_positions(xenomorphs_below_ratio)
		xeno_hive.update_tier_limits()
		return
	if(xeno_hive.total_xenos_for_evolving() <= 0)
		xeno_job.add_job_positions(2)
		xeno_hive.update_tier_limits()

/// Gets the difference of job points between humans and xenos. Negative means too many xenos. Positive means too many humans.
/datum/game_mode/infestation/nuclear_war/proc/get_jobpoint_difference()
	var/datum/hive_status/normal/xeno_hive = GLOB.hive_datums[XENO_HIVE_NORMAL]
	var/datum/job/xeno_job = SSjob.GetJobType(/datum/job/xenomorph)
	return get_total_joblarvaworth(count_flags = COUNT_IGNORE_HUMAN_SSD) - (xeno_hive.total_xenos_for_evolving() * xeno_job.job_points_needed)

/datum/game_mode/infestation/nuclear_war/get_adjusted_jobworth_list(list/jobworth_list)
	var/list/adjusted_jobworth_list = deep_copy_list(jobworth_list)
	var/jobpoint_difference = get_jobpoint_difference()
	for(var/index in jobworth_list)
		var/datum/job/scaled_job = SSjob.GetJobType(index)
		if(!(index in SSticker.mode.valid_job_types))
			continue
		if(!isxenosjob(scaled_job))
			continue
		var/amount = jobworth_list[index]
		adjusted_jobworth_list[index] = clamp(jobpoint_difference + amount, 0, amount)
	return adjusted_jobworth_list

/datum/game_mode/infestation/nuclear_war/check_finished()
	if(round_finished)
		return TRUE

	if(world.time < (SSticker.round_start_time + 5 SECONDS))
		return FALSE

	var/list/living_player_list = count_humans_and_xenos(count_flags = COUNT_IGNORE_ALIVE_SSD|COUNT_IGNORE_XENO_SPECIAL_AREA)
	var/num_humans = living_player_list[1]
	var/num_xenos = living_player_list[2]
	var/num_humans_ship = living_player_list[3]

	if(SSevacuation.dest_status == NUKE_EXPLOSION_FINISHED)
		message_admins("Round finished: [MODE_GENERIC_DRAW_NUKE]") //ship blows, no one wins
		round_finished = MODE_GENERIC_DRAW_NUKE
		return TRUE

	if(round_stage == INFESTATION_DROPSHIP_CAPTURED_XENOS)
		message_admins("Round finished: [MODE_INFESTATION_X_MINOR]")
		round_finished = MODE_INFESTATION_X_MINOR
		return TRUE

	switch(planet_nuked)
		if(INFESTATION_NUKE_COMPLETED)
			message_admins("Round finished: [MODE_INFESTATION_M_MINOR]") //marines managed to nuke the colony
			round_finished = MODE_INFESTATION_M_MINOR
			return TRUE
		if(INFESTATION_NUKE_COMPLETED_SHIPSIDE)
			message_admins("Round finished: [MODE_INFESTATION_X_MAJOR]") //marines managed to nuke their own ship
			round_finished = MODE_INFESTATION_X_MAJOR
			return TRUE
		if(INFESTATION_NUKE_COMPLETED_OTHER)
			message_admins("Round finished: [MODE_INFESTATION_X_MINOR]") //marines managed to nuke transit or something
			round_finished = MODE_INFESTATION_X_MINOR
			return TRUE

	if(!num_humans)
		if(!num_xenos)
			message_admins("Round finished: [MODE_INFESTATION_DRAW_DEATH]") //everyone died at the same time, no one wins
			round_finished = MODE_INFESTATION_DRAW_DEATH
			return TRUE
		message_admins("Round finished: [MODE_INFESTATION_X_MAJOR]") //xenos wiped out ALL the marines without hijacking, xeno major victory
		round_finished = MODE_INFESTATION_X_MAJOR
		return TRUE
	if(!num_xenos)
		if(round_stage == INFESTATION_MARINE_CRASHING)
			message_admins("Round finished: [MODE_INFESTATION_M_MINOR]") //marines lost the ground operation but managed to wipe out Xenos on the ship at a greater cost, minor victory
			round_finished = MODE_INFESTATION_M_MINOR
			return TRUE
		message_admins("Round finished: [MODE_INFESTATION_M_MAJOR]") //marines win big
		round_finished = MODE_INFESTATION_M_MAJOR
		return TRUE
	if(round_stage == INFESTATION_MARINE_CRASHING && !num_humans_ship)
		if(SSevacuation.human_escaped > SSevacuation.initial_human_on_ship * 0.5)
			message_admins("Round finished: [MODE_INFESTATION_X_MINOR]") //xenos have control of the ship, but most marines managed to flee
			round_finished = MODE_INFESTATION_X_MINOR
			return
		message_admins("Round finished: [MODE_INFESTATION_X_MAJOR]") //xenos wiped our marines, xeno major victory
		round_finished = MODE_INFESTATION_X_MAJOR
		return TRUE
	return FALSE
