/datum/game_mode/infestation/crash
	name = "Crash"
	config_tag = "Crash"
	esc_menu_name = "Canterbury" // Потому что спавн происходит прямо на нём а не на Талосе
	required_players = 2
	round_type_flags = MODE_INFESTATION|MODE_XENO_SPAWN_PROTECT|MODE_DEAD_GRAB_FORBIDDEN|MODE_DISALLOW_RAILGUN|MODE_PSY_POINTS|MODE_PSY_POINTS_ADVANCED|MODE_SILOS_SPAWN_MINIONS|MODE_ALLOW_XENO_QUICKBUILD|MODE_HAS_MINERS|MODE_ALLOW_MARINE_QUICKBUILD
	xeno_abilities_flags = ABILITY_CRASH
	valid_job_types = list(
		/datum/job/terragov/squad/standard = -1,
		/datum/job/terragov/squad/robot = -1,
		/datum/job/terragov/squad/engineer = 1,
		/datum/job/terragov/squad/corpsman = 1,
		/datum/job/terragov/squad/smartgunner = 1,
		/datum/job/terragov/squad/specialist = 1,
		/datum/job/terragov/squad/leader = 1,
		/datum/job/terragov/medical/professor = 1,
		/datum/job/terragov/medical/medicalofficer = 1,
		/datum/job/terragov/silicon/synthetic = 1,
		/datum/job/terragov/command/fieldcommander = 1,
		/datum/job/xenomorph = FREE_XENO_AT_START
	)
	job_points_needed_by_job_type = list(
		/datum/job/terragov/squad/smartgunner = 20,
		/datum/job/terragov/squad/specialist = 20,
		/datum/job/terragov/squad/corpsman = 5,
		/datum/job/terragov/squad/engineer = 5,
		/datum/job/xenomorph = CRASH_LARVA_POINTS_NEEDED,
	)
	xenorespawn_time = 1 MINUTES

	blacklist_ground_maps = list(MAP_BIG_RED, MAP_DELTA_STATION, MAP_PRISON_STATION, MAP_LV_624, MAP_WHISKEY_OUTPOST, MAP_OSCAR_OUTPOST, MAP_LAST_STAND)

	restricted_castes = list(/datum/xeno_caste/hivemind)

	bioscan_interval = 0
	// Round end conditions
	var/shuttle_landed = FALSE
	var/marines_evac = CRASH_EVAC_NONE

	// Shuttle details
	var/shuttle_id = SHUTTLE_CANTERBURY
	var/obj/docking_port/mobile/crashmode/shuttle

	///How long between two larva check
	var/larva_check_interval = 1 MINUTES
	///Last time larva balance was checked
	var/last_larva_check
	///Here, we are keeping a record of which squads everyone was originally in, for the purpose of future reallocation.
	var/list/orphan_marines_cache = list()

/datum/game_mode/infestation/crash/pre_setup()
	. = ..()

	// Spawn the ship
	if(TGS_CLIENT_COUNT >= 25)
		shuttle_id = SHUTTLE_BIGBURY
		esc_menu_name = "Bigbury" // Заменяем Кантебери
	if(!SSmapping.shuttle_templates[shuttle_id])
		message_admins("Gamemode: couldn't find a valid shuttle template for [shuttle_id]")
		CRASH("Shuttle [shuttle_id] wasn't found and can't be loaded")

	var/datum/map_template/shuttle/ST = SSmapping.shuttle_templates[shuttle_id]
	shuttle = SSshuttle.load_template_to_transit(ST)

	// Redefine the relevant spawnpoints after spawning the ship.
	for(var/job_type in shuttle.spawns_by_job)
		GLOB.spawns_by_job[job_type] = shuttle.spawns_by_job[job_type]

	GLOB.start_squad_landmarks_list = null
	GLOB.latejoin_squad_landmarks_list = null

	GLOB.latejoin = shuttle.latejoins
	GLOB.latejoin_cryo = shuttle.latejoins
	GLOB.latejoin_gateway = shuttle.latejoins
	// Launch shuttle
	var/list/valid_docks = list()
	for(var/obj/docking_port/stationary/crashmode/potential_crash_site in SSshuttle.stationary_docking_ports)
		if(!shuttle.check_dock(potential_crash_site, silent = TRUE))
			continue
		valid_docks += potential_crash_site

	if(!length(valid_docks))
		CRASH("No valid crash sides found!")
	var/obj/docking_port/stationary/crashmode/actual_crash_site = pick(valid_docks)

	shuttle.crashing = TRUE
	SSshuttle.moveShuttleToDock(shuttle.shuttle_id, actual_crash_site, TRUE) // FALSE = instant arrival
	addtimer(CALLBACK(src, PROC_REF(crash_shuttle), actual_crash_site), 10 MINUTES)

	GLOB.start_squad_landmarks_list = null

	GLOB.all_supply_groups -= "Factory" // In ideal world, we just balance factories out

	for(var/obj/machinery/telecomms/relay/preset/telecomms/relay AS in GLOB.ground_telecomms_relay)
		qdel(relay) // so there's no double intercomms, hacky, but i don't know a better way.

/datum/game_mode/infestation/crash/post_setup()
	. = ..()

	for(var/i in GLOB.nuke_spawn_locs)
		new /obj/machinery/nuclearbomb(i)

	for(var/obj/machinery/computer/shuttle/shuttle_control/computer_to_disable AS in GLOB.shuttle_controls_list)
		if(istype(computer_to_disable, /obj/machinery/computer/shuttle/shuttle_control/canterbury))
			continue
		computer_to_disable.machine_stat |= BROKEN
		computer_to_disable.update_icon()

	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_OPEN_TIMED_SHUTTERS_CRASH)
	RegisterSignal(SSdcs, COMSIG_GLOB_NUKE_EXPLODED, PROC_REF(on_nuclear_explosion))
	RegisterSignal(SSdcs, COMSIG_GLOB_NUKE_DIFFUSED, PROC_REF(on_nuclear_diffuse))
	RegisterSignal(SSdcs, COMSIG_GLOB_NUKE_START, PROC_REF(on_nuke_started))

	if(!(round_type_flags & MODE_INFESTATION))
		return

	for(var/i in GLOB.xeno_resin_silo_turfs)
		new /obj/structure/xeno/silo/crash(i)

	for(var/obj/effect/landmark/corpsespawner/corpse AS in GLOB.corpse_landmarks_list)
		corpse.create_mob()

	for(var/i in GLOB.alive_xeno_list_hive[XENO_HIVE_NORMAL])
		if(isxenolarva(i)) // Larva
			var/mob/living/carbon/xenomorph/larva/X = i
			X.evolution_stored = X.xeno_caste.evolution_threshold //Immediate roundstart evo for larva.

/datum/game_mode/infestation/crash/announce()
	to_chat(world, span_round_header("The current map is - [SSmapping.configs[GROUND_MAP].map_name]!"))
	priority_announce("Высадка запланирована через 10 минут. Приготовьтесь к посадке. Предварительное сканирование показывает наличие агрессивных форм биологической жизни. Ваша следующая миссия - заполучить коды доступа и активировать ядерную боеголовку.", title = "Доброе утро, товарищи!", type = ANNOUNCEMENT_PRIORITY, sound = 'sound/AI/crash_start.ogg', color_override = "red")

/datum/game_mode/infestation/crash/process()
	. = ..()

	if(world.time > last_larva_check + larva_check_interval)
		last_larva_check = world.time // It should stand first, so the check updates not after the balance_scales() gets completed
		balance_scales()

/datum/game_mode/infestation/crash/proc/crash_shuttle(obj/docking_port/stationary/target)
	shuttle_landed = TRUE
	shuttle.crashing = FALSE
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_CANTERBURRY_LANDING)
	generate_nuke_disk_spawners()
	consolidate_squads()

/datum/game_mode/infestation/crash/check_finished(force_end)
	if(round_finished)
		return TRUE

	if(!shuttle_landed && !force_end)
		return FALSE

	var/list/living_player_list = count_humans_and_xenos(count_flags = COUNT_IGNORE_HUMAN_SSD)
	var/num_humans = living_player_list[1]

	if(num_humans && planet_nuked == INFESTATION_NUKE_NONE && marines_evac == CRASH_EVAC_NONE && !force_end)
		return FALSE

	switch(planet_nuked)

		if(INFESTATION_NUKE_NONE)
			if(!num_humans)
				message_admins("Round finished: [MODE_INFESTATION_X_MAJOR]") //xenos wiped out ALL the marines
				round_finished = MODE_INFESTATION_X_MAJOR
				return TRUE
			if(marines_evac == CRASH_EVAC_COMPLETED || (!length(GLOB.active_nuke_list) && marines_evac != CRASH_EVAC_NONE))
				message_admins("Round finished: [MODE_INFESTATION_X_MINOR]") //marines evaced without a nuke
				round_finished = MODE_INFESTATION_X_MINOR
				return TRUE

		if(INFESTATION_NUKE_COMPLETED)
			if(marines_evac == CRASH_EVAC_NONE)
				message_admins("Round finished: [MODE_INFESTATION_M_MINOR]") //marines nuked the planet but didn't evac
				round_finished = MODE_INFESTATION_M_MINOR
				return TRUE
			message_admins("Round finished: [MODE_INFESTATION_M_MAJOR]") //marines nuked the planet and managed to evac
			round_finished = MODE_INFESTATION_M_MAJOR
			return TRUE

		if(INFESTATION_NUKE_COMPLETED_SHIPSIDE, INFESTATION_NUKE_COMPLETED_OTHER)
			message_admins("Round finished: [MODE_INFESTATION_X_MAJOR]") //marines nuked themselves somehow
			round_finished = MODE_INFESTATION_X_MAJOR
			return TRUE
	return FALSE

/datum/game_mode/infestation/crash/on_nuclear_diffuse(obj/machinery/nuclearbomb/bomb, mob/living/carbon/xenomorph/X)
	var/list/living_player_list = count_humans_and_xenos(count_flags = COUNT_IGNORE_HUMAN_SSD)
	var/num_humans = living_player_list[1]
	if(!num_humans) // no humans left on planet to try and restart it.
		addtimer(VARSET_CALLBACK(src, marines_evac, CRASH_EVAC_COMPLETED), 10 SECONDS)

/datum/game_mode/infestation/crash/can_summon_dropship(mob/user)
	to_chat(src, span_warning("This power doesn't work in this gamemode."))
	return FALSE

/datum/game_mode/infestation/crash/proc/consolidate_squads()
	var/list/roles_to_check = list(
		SQUAD_MARINE,
		SQUAD_CORPSMAN,
		SQUAD_ENGINEER,
		SQUAD_SMARTGUNNER,
		SQUAD_SPECIALIST,
		SQUAD_LEADER,
		FIELD_COMMANDER
	)

	var/list/squads_with_sl = list()
	var/list/squads_without_sl = list()

	var/mob/living/carbon/human/best_real_sl
	var/highest_sl_exp = -1

	var/mob/living/carbon/human/best_orphan
	var/highest_orphan_exp = -1
	var/datum/squad/orphan_target_squad

	for(var/datum/squad/S in SSjob.active_squads[FACTION_TERRAGOV])
		if(S.squad_leader && S.squad_leader.stat != DEAD && S.squad_leader.client)
			squads_with_sl += S

			var/total_exp = 0
			for(var/role in roles_to_check)
				total_exp += S.squad_leader.client.get_exp(role)

			if(total_exp > highest_sl_exp)
				highest_sl_exp = total_exp
				best_real_sl = S.squad_leader
		else
			squads_without_sl += S

			for(var/mob/living/carbon/human/M in S.marines_list)
				if(M.stat == DEAD || !M.client)
					continue

				var/total_exp = 0
				for(var/role in roles_to_check)
					total_exp += M.client.get_exp(role)

				if(total_exp > highest_orphan_exp)
					highest_orphan_exp = total_exp
					best_orphan = M
					orphan_target_squad = S

	var/datum/squad/target_squad

	if(length(squads_with_sl))
		target_squad = best_real_sl.assigned_squad
	else
		if(best_orphan && orphan_target_squad)
			target_squad = orphan_target_squad
			target_squad.promote_leader(best_orphan)
			target_squad.message_squad("Автоматическая система назначила бойца [best_orphan.real_name] исполняющим обязанности командира отряда.")

	if(target_squad)
		var/list/marines_to_move = list()

		for(var/datum/squad/S in squads_without_sl)
			if(S == target_squad)
				continue

			for(var/mob/living/carbon/human/M in S.marines_list)
				marines_to_move += M

		if(length(marines_to_move))
			for(var/mob/living/carbon/human/M in marines_to_move)
				var/datum/squad/old_squad = M.assigned_squad
				if(old_squad)
					orphan_marines_cache[M.ckey] = old_squad
					old_squad.remove_from_squad(M)
				target_squad.insert_into_squad(M, give_radio = TRUE, radio_from = old_squad)
			target_squad.message_squad("В связи с отсутствием командования в других подразделениях, разрозненные бойцы были прикомандированы под руководство отряда [target_squad.name].")

/datum/game_mode/infestation/crash/LateSpawn(mob/new_player/player)
	var/client/C = player.client
	. = ..()
	if(C && istype(C.mob, /mob/living/carbon/human))
		handle_latejoin_squad(C.mob)

/datum/game_mode/infestation/crash/proc/handle_latejoin_squad(mob/living/carbon/human/H)
	if(!shuttle_landed)
		return

	var/datum/squad/S = H.assigned_squad
	if(!S)
		return

	var/is_sl = FALSE
	if(istype(H.job, /datum/job/terragov/squad/leader))
		is_sl = TRUE

	if(is_sl)
		for(var/mar_ckey in orphan_marines_cache)
			var/datum/squad/original_squad = orphan_marines_cache[mar_ckey]

			if(original_squad == S)
				for(var/mob/living/carbon/human/marine in GLOB.human_mob_list)
					if(marine.ckey == mar_ckey && marine.stat != DEAD && marine.assigned_squad != S)
						marine.assigned_squad.remove_from_squad(marine)
						S.insert_into_squad(marine, give_radio = TRUE, radio_from = S)
						to_chat(marine, span_notice("Ваш командир прибыл! Вы переведены обратно в отряд [S.name]."))
						break
				orphan_marines_cache -= mar_ckey

	else
		if(!S.squad_leader || S.squad_leader.stat == DEAD || !S.squad_leader.client)
			var/datum/squad/target_squad
			var/highest_sl_exp = -1
			var/list/roles_to_check = list(SQUAD_MARINE, SQUAD_CORPSMAN, SQUAD_ENGINEER, SQUAD_SMARTGUNNER, SQUAD_SPECIALIST, SQUAD_LEADER, FIELD_COMMANDER)

			for(var/datum/squad/other_squad in SSjob.active_squads[FACTION_TERRAGOV])
				if(other_squad.squad_leader && other_squad.squad_leader.stat != DEAD && other_squad.squad_leader.client)
					var/total_exp = 0
					for(var/role in roles_to_check)
						total_exp += other_squad.squad_leader.client.get_exp(role)

					if(total_exp > highest_sl_exp)
						highest_sl_exp = total_exp
						target_squad = other_squad

			if(target_squad && target_squad != S)
				orphan_marines_cache[H.ckey] = S
				S.remove_from_squad(H)
				target_squad.insert_into_squad(H, give_radio = TRUE, radio_from = S)
				to_chat(H, span_warning("В вашем изначальном отряде нет командования. Вы прикомандированы к отряду [target_squad.name]."))

/// Adds more xeno job slots if needed.
/datum/game_mode/infestation/crash/proc/balance_scales()
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
/datum/game_mode/infestation/crash/proc/get_jobpoint_difference()
	var/datum/hive_status/normal/xeno_hive = GLOB.hive_datums[XENO_HIVE_NORMAL]
	var/datum/job/xeno_job = SSjob.GetJobType(/datum/job/xenomorph)
	return get_total_joblarvaworth(count_flags = COUNT_IGNORE_HUMAN_SSD) - (xeno_hive.total_xenos_for_evolving() * xeno_job.job_points_needed)

/datum/game_mode/infestation/crash/get_adjusted_jobworth_list(list/jobworth_list)
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
