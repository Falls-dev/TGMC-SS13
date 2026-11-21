#define COLONY_IMPACT_MAP "Colony 1" // взято с ерп тгмс
#define COLONY_IMPACT_SURVIVOR_WINDOW (6 MINUTES) // 6 минут на заход в игру а дальше прилёт
#define COLONY_IMPACT_REINFORCEMENTS (10 MINUTES) // через 4 минуты после прилёта госты и челы в лобби могут зайти за шмаров
#define COLONY_IMPACT_UNLOAD_TIME (3 MINUTES) // время на высадку после приземления
#define COLONY_IMPACT_LIMIT (60 MINUTES) // на весь раунд 60 минут, потом автоконец
#define COLONY_IMPACT_DRAW "DRAW: Operation timed out"

/datum/game_mode/infestation/colony_impact
	name = "Colony Impact"
	config_tag = "Colony Impact"
	votable = FALSE
	required_players = 2
	squads_max_number = 1
	allow_persistence_save = FALSE
	esc_menu_name = "Colony Impact"
	whitelist_ground_maps = list(COLONY_IMPACT_MAP)
	round_type_flags = MODE_INFESTATION|MODE_DEAD_GRAB_FORBIDDEN|MODE_DISALLOW_RAILGUN|MODE_PSY_POINTS|MODE_PSY_POINTS_ADVANCED|MODE_ALLOW_XENO_QUICKBUILD|MODE_ALLOW_MARINE_QUICKBUILD
	xeno_abilities_flags = ABILITY_CRASH
	bioscan_interval = 0
	populate_infestation_on_start = FALSE
	xenorespawn_time = 2 MINUTES
	round_end_states = list(MODE_INFESTATION_X_MAJOR, MODE_INFESTATION_M_MAJOR, MODE_INFESTATION_DRAW_DEATH, COLONY_IMPACT_DRAW)
	valid_job_types = list( // жаль игроков на сервере не 100, так бы сюрвораш можно было б устроить
		/datum/job/xenomorph = 2,
		/datum/job/survivor/civilian = 30,
		/datum/job/survivor/doctor = 4,
		/datum/job/survivor/security = 4,
		/datum/job/survivor/atmos = 4,
		/datum/job/survivor/miner = 4,
		/datum/job/survivor/scientist = 3,
		/datum/job/survivor/marshal = 1,
		/datum/job/survivor/liaison = 1,
	)

	var/list/reinforcement_jobs = list( // ~10 маров на помощь сюрвам
		/datum/job/terragov/squad/standard = 4,
		/datum/job/terragov/squad/corpsman = 2,
		/datum/job/terragov/squad/engineer = 2,
		/datum/job/terragov/squad/smartgunner = 1,
		/datum/job/terragov/squad/leader = 1,
	)
	var/list/survivor_spawns = list()
	var/list/obj/machinery/door/poddoor/shutters/colony_impact/landing/landing_shutters = list()
	var/list/pending_observers = list()
	var/obj/docking_port/mobile/colony_impact/meteor
	var/obj/docking_port/mobile/colony_impact/reinforcement/dropship
	var/obj/docking_port/stationary/colony_impact/impact_site
	var/obj/docking_port/stationary/colony_impact/landing_zone
	var/turf/disembark_turf
	var/impact_started = FALSE
	var/impact_complete = FALSE
	var/reinforcements_open = FALSE
	var/reinforcements_landed = FALSE
	var/reinforcements_departed = FALSE
	var/next_larva_check = 0

/datum/game_mode/infestation/colony_impact/can_start(bypass_checks)
	if(SSmapping.configs[GROUND_MAP].map_name != COLONY_IMPACT_MAP)
		to_chat(world, span_warning("Для запуска этого режима загрузи карту [COLONY_IMPACT_MAP]."))
		return FALSE
	return ..()

/datum/game_mode/infestation/colony_impact/scale_squad_jobs()
	// The default implementation would open a squad leader position during roundstart assignment.
	return

/datum/game_mode/infestation/colony_impact/pre_setup()
	var/list/ground_levels = SSmapping.levels_by_trait(ZTRAIT_GROUND)
	if(!length(ground_levels))
		return FALSE
	var/ground_z = ground_levels[1]
	for(var/turf/survivor_spawn as anything in GLOB.spawns_by_job[/datum/job/survivor/rambo])
		if(survivor_spawn.z == ground_z)
			survivor_spawns += survivor_spawn
	if(!length(survivor_spawns))
		message_admins("ИВЕНТ: не найдено ни одного спавна для сюрвов на земле. Мапер пидорас.")
		return FALSE

	var/list/impact_sites = list()
	for(var/obj/docking_port/stationary/colony_impact/dock in SSshuttle.stationary_docking_ports)
		if(dock.z != ground_z)
			continue
		if(istype(dock, /obj/docking_port/stationary/colony_impact/reinforcements))
			landing_zone = dock
		else
			impact_sites += dock
	if(!landing_zone || !length(impact_sites))
		message_admins("ИВЕНТ: отсутствуют точки для краша.")
		return FALSE
	impact_site = pick(impact_sites)

	var/area/landing_area = get_area(landing_zone)
	var/obj/effect/landmark/colony_impact_disembark/disembark_marker = locate(/obj/effect/landmark/colony_impact_disembark) in landing_area
	disembark_turf = get_turf(disembark_marker)
	for(var/obj/machinery/door/poddoor/shutters/colony_impact/landing/shutter in landing_area)
		landing_shutters += shutter
	if(!disembark_turf || !length(landing_shutters))
		message_admins("ИВЕНТ: отсутствует точка высадки или створки для открытия. КОРОЧЕ ЧЁТО СЛОМАЛОСЬ А ЧЁ Я НЕ ЕБУ.")
		return FALSE

	// As in Crash, the ships must be in transit before setup creates the first characters.
	meteor = SSshuttle.load_template_to_transit(SSmapping.shuttle_templates["colony_impact_meteor"])
	dropship = SSshuttle.load_template_to_transit(SSmapping.shuttle_templates["colony_impact_reinforcement"])
	if(!length(meteor.get_spawn_turfs()) || !length(dropship.get_spawn_turfs()))
		CRASH("Colony Impact: a shuttle loaded without usable spawn markers.")
	impact_site.copy_size(meteor)
	landing_zone.copy_size(dropship)

	return ..()

/datum/game_mode/infestation/colony_impact/announce() // Никакой вышки 5 нету, так сказать наебка для уёбка
	priority_announce("Обнаружен удалённый обьект который приближается к колонии. Включите питание на вышке 5 для запуска систем ПВО.", "Colony AI", type = ANNOUNCEMENT_PRIORITY)

/datum/game_mode/infestation/colony_impact/post_setup()
	. = ..()
	log_game("ИВЕНТ: [length(survivor_spawns)] сюрвов заспавнилось. Начинаем веселье!")
	for(var/turf/crate_turf as anything in survivor_spawns.Copy(1, min(length(survivor_spawns) + 1, 3)))
		new /obj/structure/largecrate/supply/supplies/sandbags(crate_turf)

	addtimer(CALLBACK(src, PROC_REF(warn_of_impact)), COLONY_IMPACT_SURVIVOR_WINDOW - 30 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(begin_impact)), COLONY_IMPACT_SURVIVOR_WINDOW)
	addtimer(CALLBACK(src, PROC_REF(open_reinforcements)), COLONY_IMPACT_REINFORCEMENTS)

/datum/game_mode/infestation/colony_impact/proc/warn_of_impact()
	if(round_finished)
		return
	priority_announce("Обнаружен крупный падающий объект, до столкновения около 30 секунд. Системы ПВО не отвечают. Покиньте район!", "Colony AI", type = ANNOUNCEMENT_PRIORITY, sound = 'sound/EVENT/alert_boat.ogg', color_override = "red")

/datum/game_mode/infestation/colony_impact/proc/begin_impact()
	if(round_finished || impact_started)
		return
	impact_started = TRUE
	for(var/job_type in valid_job_types)
		if(!ispath(job_type, /datum/job/survivor))
			continue
		var/datum/job/survivor_job = SSjob.GetJobType(job_type)
		survivor_job.set_job_positions(0)
	SStgui.close_uis(GLOB.latejoin_menu)
	meteor.crashing = TRUE
	if(SSshuttle.moveShuttleToDock(meteor.shuttle_id, impact_site, FALSE))
		abort_deployment("Ксенометеор не смог состыковаться (упасть) на граунд. ТПхайте ксеносов.")
		return

	impact_complete = TRUE
	new /obj/structure/xeno/silo(get_turf(meteor))
	var/datum/job/xenomorph/xeno_job = SSjob.GetJobType(/datum/job/xenomorph)
	xeno_job.free_xeno_at_start = 0
	for(var/obj/machinery/door/poddoor/shutters/colony_impact/hatch in get_area(meteor))
		INVOKE_ASYNC(hatch, TYPE_PROC_REF(/obj/machinery/door/poddoor/shutters, open))
	SSpoints.add_psy_points(XENO_HIVE_NORMAL, SILO_PRICE)
	priority_announce("Обнаружены масштабные повреждения. Запуск автоматических действий.", "Colony AI", type = ANNOUNCEMENT_PRIORITY, sound = 'sound/EVENT/alert_hoi.ogg')
	log_game("ИВЕНТ: метеор приземлился на [impact_site.x], [impact_site.y].")
	blackout_colony(impact_site.z)

/datum/game_mode/infestation/colony_impact/proc/blackout_colony(ground_z)
	playsound_z(ground_z, 'sound/effects/powerloss.ogg', 50)
	for(var/obj/machinery/power/apc/area_controller as anything in GLOB.apcs_list)
		if(area_controller.z != ground_z)
			continue
		if(area_controller.cell)
			area_controller.cell.charge = 0
		area_controller.set_broken()
		CHECK_TICK

	// Include fixtures in areas without an APC.
	for(var/obj/machinery/light/fixture in GLOB.nightfall_toggleable_lights)
		if(fixture.z != ground_z || fixture.status != LIGHT_OK)
			continue
		fixture.broken(TRUE)
		CHECK_TICK

/datum/game_mode/infestation/colony_impact/proc/open_reinforcements()
	if(round_finished)
		return
	if(!impact_complete || SSshuttle.moveShuttleToDock(dropship.shuttle_id, landing_zone, TRUE))
		abort_deployment("Шаттл маров не смог сесть. ТПхайте маров.")
		return

	reinforcements_open = TRUE
	for(var/job_type in reinforcement_jobs)
		var/datum/job/marine_job = SSjob.GetJobType(job_type)
		SSjob.active_occupations |= marine_job
		marine_job.set_job_positions(reinforcement_jobs[job_type])
	addtimer(CALLBACK(src, PROC_REF(check_reinforcement_flight)), 2 MINUTES)
	SStgui.close_uis(GLOB.latejoin_menu)
	priority_announce("Сигнал бедствия запущен. Ожидание ответа...", title = "Сигнал Бедствия", type = ANNOUNCEMENT_PRIORITY, sound = 'sound/AI/distressbeacon.ogg', color_override = "orange")
	for(var/mob/dead/observer/observer as anything in GLOB.observer_list)
		if(observer.client)
			INVOKE_ASYNC(src, PROC_REF(player_respawn), observer)
	for(var/mob/new_player/player as anything in GLOB.new_player_list)
		if(player.client)
			player.late_choices()
	log_game("ИВЕНТ: слоты для маров открыты.")

/datum/game_mode/infestation/colony_impact/player_respawn(mob/respawnee) // Код слизан с кампеина и переделан под этот режим
	if(!reinforcements_open)
		return ..()
	if(round_finished || !isobserver(respawnee) || !respawnee.client || !GLOB.enter_allowed || respawnee in pending_observers)
		return
	var/mob/dead/observer/observer = respawnee
	var/list/options = list()
	for(var/job_type in reinforcement_jobs)
		var/datum/job/marine_job = SSjob.GetJobType(job_type)
		if(observer.IsJobAvailable(marine_job, TRUE)) // ну почти слизан
			options[marine_job.title] = marine_job
	if(!length(options))
		return

	pending_observers += observer
	var/selection = tgui_input_list(observer, "Выберите роль в отряде подкрепления.", "ИВЕНТ ГОВНА", options, timeout = 2 MINUTES)
	pending_observers -= observer
	if(!selection || !reinforcements_open || !observer.client || !GLOB.enter_allowed)
		return
	var/datum/job/selected_job = options[selection]
	if(!observer.IsJobAvailable(selected_job, TRUE))
		to_chat(observer, span_warning("Этот слот уже полностью занят. Вам доступен респавн через OOC-Respawn."))
		return

	var/turf/ghost_turf = get_turf(observer)
	var/datum/weakref/original_body = observer.can_reenter_corpse
	var/mob/new_player/player = new()
	player.key = observer.key
	if(!CanLateSpawn(player, selected_job))
		if(player.client)
			if(QDELETED(observer))
				observer = new(original_body?.resolve())
				observer.can_reenter_corpse = original_body
				observer.abstract_move(ghost_turf)
			observer.key = player.key
		qdel(player)
		return
	LateSpawn(player)

/datum/game_mode/infestation/colony_impact/CanLateSpawn(mob/new_player/player, datum/job/job)
	if(!job || !player.client || round_finished)
		return FALSE
	if(istype(job, /datum/job/survivor) && (impact_started || !length(survivor_spawns)))
		return FALSE
	if(job.type in reinforcement_jobs && (!reinforcements_open || dropship.get_docked() == landing_zone || !get_job_spawn_turf(job)))
		return FALSE
	if(isxenosjob(job))
		if(XENODEATHTIME_CHECK(player))
			return FALSE
		if(impact_complete)
			if(!length(GLOB.xeno_resin_silos_by_hive[XENO_HIVE_NORMAL]))
				return FALSE
		else if(impact_started || !get_job_spawn_turf(job))
			return FALSE
	return ..()

/datum/game_mode/infestation/colony_impact/get_job_spawn_turf(datum/job/job)
	if(isxenosjob(job) && !impact_complete)
		return meteor?.get_spawn_turf()
	if(istype(job, /datum/job/survivor))
		return length(survivor_spawns) ? pick(survivor_spawns) : null
	if(job.type in reinforcement_jobs)
		return dropship?.get_spawn_turf()

/datum/game_mode/infestation/colony_impact/attempt_to_join_as_larva(client/waiter)
	if(impact_complete)
		return ..()
	var/mob/observer = waiter?.mob
	if(impact_started || round_finished || !isobserver(observer) || !GLOB.enter_allowed || !GLOB.xeno_enter_allowed || XENODEATHTIME_CHECK(observer))
		return FALSE
	var/datum/job/xeno_job = SSjob.GetJobType(/datum/job/xenomorph)
	if(!observer.IsJobAvailable(xeno_job, TRUE))
		return FALSE
	var/turf/spawn_turf = get_job_spawn_turf(xeno_job)
	if(!spawn_turf)
		return FALSE
	var/datum/hive_status/normal/hive = GLOB.hive_datums[XENO_HIVE_NORMAL]
	return !!hive.do_spawn_larva(waiter, spawn_turf)

/datum/game_mode/infestation/colony_impact/spawn_larva(mob/xeno_candidate, mob/living/carbon/xenomorph/mother)
	if(!impact_complete)
		return attempt_to_join_as_larva(xeno_candidate.client)
	return ..()

/datum/game_mode/infestation/colony_impact/proc/on_reinforcements_landed()
	if(round_finished || !reinforcements_open)
		return
	reinforcements_landed = TRUE
	reinforcements_open = FALSE
	for(var/job_type in reinforcement_jobs)
		var/datum/job/marine_job = SSjob.GetJobType(job_type)
		marine_job.set_job_positions(0)
	SStgui.close_uis(GLOB.latejoin_menu)
	priority_announce("Шаттл приземлился. До автоматического взлёта [COLONY_IMPACT_UNLOAD_TIME / (1 MINUTES)] мин.", "Colony AI", type = ANNOUNCEMENT_PRIORITY)
	addtimer(CALLBACK(src, PROC_REF(depart_reinforcements)), COLONY_IMPACT_UNLOAD_TIME)
	log_game("Colony Impact: reinforcement shuttle landed and boarding closed.")

/datum/game_mode/infestation/colony_impact/process()
	. = ..()
	if(round_finished || !impact_complete)
		return
	if(world.time < next_larva_check || !length(GLOB.xeno_resin_silos_by_hive[XENO_HIVE_NORMAL]))
		return
	next_larva_check = world.time + 1 MINUTES
	var/datum/job/xenomorph/xeno_job = SSjob.GetJobType(/datum/job/xenomorph)
	var/list/forces = count_humans_and_xenos()
	var/desired_xenos = max(2, CEILING(forces[1] / 4, 1))
	var/unfilled_xeno_slots = max(0, xeno_job.total_positions - xeno_job.current_positions)
	var/new_slots = desired_xenos - forces[2] - unfilled_xeno_slots
	if(new_slots > 0)
		xeno_job.add_job_positions(new_slots)

/datum/game_mode/infestation/colony_impact/proc/check_reinforcement_flight()
	if(!round_finished && !reinforcements_landed)
		abort_deployment("Шаттл маров не смог сесть из-за игровой (не ивентовой) ошибки.")

/datum/game_mode/infestation/colony_impact/proc/depart_reinforcements()
	if(round_finished)
		return

	// The shuttle subsystem releases the original transit dock once the shuttle lands.
	var/obj/docking_port/stationary/transit/departure_dock = dropship.assigned_transit || SSshuttle.generate_transit_dock(dropship)
	if(!departure_dock)
		abort_deployment("the reinforcement shuttle could not reserve departure transit space")
		return
	for(var/area/shuttle_area as anything in dropship.shuttle_areas)
		for(var/mob/living/passenger in shuttle_area)
			passenger.forceMove(disembark_turf)
	if(SSshuttle.moveShuttleToDock(dropship.shuttle_id, departure_dock, FALSE))
		abort_deployment("Шаттл маров не смог сесть из-за ошибки.")
		return

	reinforcements_departed = TRUE
	for(var/obj/machinery/door/poddoor/shutters/colony_impact/landing/shutter as anything in landing_shutters)
		INVOKE_ASYNC(shutter, TYPE_PROC_REF(/obj/machinery/door/poddoor/shutters, open))
	priority_announce("Эвакуационный шаттл был автоматически отозван.", "Colony AI", type = ANNOUNCEMENT_PRIORITY)
	log_game("ИВЕНТ: Шаттл маров улетел, створки ЛЗ открылись. До конца раунда на ничью осталось около 50 минут.")

/datum/game_mode/infestation/colony_impact/proc/abort_deployment(reason)
	message_admins("ИВЕНТ: [reason].")
	log_game("ИВЕНТ: [reason].")
	round_finished = COLONY_IMPACT_DRAW

/datum/game_mode/infestation/colony_impact/check_finished(force_end)
	if(round_finished)
		return TRUE
	if(reinforcements_departed)
		var/list/forces = count_humans_and_xenos()
		var/hive_survives = forces[2] || length(GLOB.xeno_resin_silos_by_hive[XENO_HIVE_NORMAL])
		if(!forces[1])
			round_finished = hive_survives ? MODE_INFESTATION_X_MAJOR : MODE_INFESTATION_DRAW_DEATH
		else if(!hive_survives)
			round_finished = MODE_INFESTATION_M_MAJOR
	if(!round_finished && (force_end || world.time >= SSticker.round_start_time + COLONY_IMPACT_LIMIT))
		round_finished = COLONY_IMPACT_DRAW
	return !!round_finished

/datum/game_mode/infestation/colony_impact/declare_completion()
	var/datum/map_config/next_ground = SSmapping.next_map_configs?[GROUND_MAP]
	if(!next_ground || next_ground.map_name == COLONY_IMPACT_MAP)
		var/datum/map_config/default_ground = config.defaultmaps[GROUND_MAP]
		if(default_ground && default_ground.map_name != COLONY_IMPACT_MAP)
			SSmapping.changemap(default_ground)
	if(GLOB.master_mode == config_tag)
		GLOB.master_mode = "Distress Signal"
		SSticker.save_mode(GLOB.master_mode)
	return ..()

/datum/job/survivor/map_check()
	. = ..()
	if(. && outfit && type != /datum/job/survivor/rambo && SSmapping.configs[GROUND_MAP].map_name == COLONY_IMPACT_MAP)
		job_flags |= JOB_FLAG_ROUNDSTARTJOINABLE|JOB_FLAG_LATEJOINABLE

/datum/job/survivor/get_access()
	. = ..()
	if(!istype(SSticker.mode, /datum/game_mode/infestation/colony_impact))
		return
	switch(type)
		if(/datum/job/survivor/security, /datum/job/survivor/marshal)
			. |= list(ACCESS_CIVILIAN_SECURITY, ACCESS_MARINE_BRIG)
		if(/datum/job/survivor/doctor)
			. |= list(ACCESS_CIVILIAN_MEDICAL, ACCESS_MARINE_MEDBAY, ACCESS_MARINE_CMO)
		if(/datum/job/survivor/liaison)
			. |= list(ACCESS_NT_CORPORATE)

/datum/map_template/shuttle/colony_impact_meteor
	shuttle_id = "colony_impact_meteor"
	name = "Colony Impact meteor"
	movement_force = list("KNOCKDOWN" = 0, "THROW" = 0)

/datum/map_template/shuttle/colony_impact_reinforcement
	shuttle_id = "colony_impact_reinforcement"
	name = "Colony Impact reinforcement shuttle"
	movement_force = list("KNOCKDOWN" = 0, "THROW" = 0)

/obj/docking_port/stationary/colony_impact
	name = "Colony 1 impact site"
	shuttle_id = "colony_impact_site"
	hidden = TRUE
	dir = SOUTH

/obj/docking_port/stationary/colony_impact/reinforcements
	name = "Colony 1 LZ-1"
	shuttle_id = "colony_impact_lz1"

/obj/docking_port/mobile/colony_impact
	name = "Infested meteor"
	shuttle_id = "colony_impact_meteor"
	area_type = /area/shuttle/colony_impact
	dir = SOUTH
	width = 9
	height = 9
	dwidth = 4
	dheight = 4
	shuttle_flags = GAMEMODE_IMMUNE

/obj/docking_port/mobile/colony_impact/proc/get_spawn_turfs()
	. = list()
	for(var/turf/open/spawn_turf in return_turfs())
		if(!istype(get_area(spawn_turf), area_type) || !isshuttleturf(spawn_turf))
			continue
		if(locate(/obj/effect/landmark/colony_impact_spawn) in spawn_turf)
			. += spawn_turf

/obj/docking_port/mobile/colony_impact/proc/get_spawn_turf()
	var/list/spawn_turfs = get_spawn_turfs()
	if(length(spawn_turfs))
		return pick(spawn_turfs)

/obj/docking_port/mobile/colony_impact/reinforcement
	name = "TGS Kestrel"
	shuttle_id = "colony_impact_reinforcement"
	area_type = /area/shuttle/colony_impact/reinforcement
	width = 7
	height = 13
	dwidth = 3
	dheight = 0
	callTime = 35 SECONDS
	ignitionTime = 5 SECONDS
	prearrivalTime = 5 SECONDS

/obj/docking_port/mobile/colony_impact/reinforcement/initiate_docking(obj/docking_port/stationary/new_dock, movement_direction, force = FALSE)
	. = ..()
	if(. != DOCKING_SUCCESS)
		return
	var/datum/game_mode/infestation/colony_impact/event_mode = SSticker.mode
	if(istype(event_mode) && event_mode.dropship == src && new_dock == event_mode.landing_zone)
		event_mode.on_reinforcements_landed()

/area/shuttle/colony_impact
	name = "Infested meteor"

/area/shuttle/colony_impact/reinforcement
	name = "TGS Kestrel"

/area/colony_impact_landing
	parent_type = /area/colony1/hangar2
	name = "Colony 1 LZ-1"
	requires_power = FALSE
	minimap_color = MINIMAP_AREA_LZ

/turf/open/shuttle/colony_impact
	name = "meteor crust"
	icon = 'icons/turf/floors.dmi'
	icon_state = "asteroid"

/turf/closed/shuttle/colony_impact
	name = "meteor rock"
	icon = 'icons/turf/walls/frostwall.dmi'
	icon_state = "frostwall-0"

/obj/effect/landmark/colony_impact_spawn

/obj/effect/landmark/colony_impact_disembark

/obj/machinery/door/poddoor/shutters/colony_impact
	name = "meteor hatch"
	use_power = FALSE
	resistance_flags = RESIST_ALL | DROPSHIP_IMMUNE

/obj/machinery/door/poddoor/shutters/colony_impact/landing
	name = "landing zone shutter"

#undef COLONY_IMPACT_MAP
#undef COLONY_IMPACT_SURVIVOR_WINDOW
#undef COLONY_IMPACT_REINFORCEMENTS
#undef COLONY_IMPACT_UNLOAD_TIME
#undef COLONY_IMPACT_LIMIT
#undef COLONY_IMPACT_DRAW
