/datum/dig_site
    var/site_name = ""
    var/turf/location
    var/tier = 0
    var/target_depth = 0
    var/current_depth = 0

/datum/dig_site/New(turf/T, name_override)
    location = T
    site_name = name_override ? name_override : "Unknown-[rand(10000, 99999)]"

    tier = pick(
        40; 0,
        25; 1,
        20; 2,
        10; 3,
        5;  4
    )

    target_depth = rand(10 + (tier * 5), 100 + (tier * 50))

SUBSYSTEM_DEF(xeno_archaeology)
    name = "Xeno Archaeology"
    wait = 5 MINUTES
    flags = SS_BACKGROUND
    can_fire = FALSE
    init_order = INIT_ORDER_SPAWNING_POOL
    var/list/active_sites = list()
    var/max_active_sites = 5

/datum/controller/subsystem/xeno_archaeology/Initialize()
    SSxeno_archaeology = src
    addtimer(CALLBACK(src, .proc/populate_world), 10 SECONDS)
    return SS_INIT_SUCCESS

/datum/controller/subsystem/xeno_archaeology/proc/populate_world()
    var/created = 0
    for(var/i in 1 to max_active_sites)
        if(generate_dig_site())
            created++
    world.log << "\[Xeno Archaeology\] Spawned [created] / [max_active_sites] dig sites on Planet."

/datum/controller/subsystem/xeno_archaeology/proc/generate_dig_site()
    if(!world.maxx || !world.maxy)
        return FALSE

    var/attempts = 0
    while(attempts < 300)
        attempts++
        var/turf/T = locate(rand(1, world.maxx), rand(1, world.maxy), 2)

        if(!T || !istype(T, /turf/open) || T.density)
            continue

        var/area/A = get_area(T)
        if(!A)
            continue

        var/area_path = "[A.type]"
        if(findtext(area_path, "shuttle") || findtext(area_path, "space"))
            continue

        var/turf_path = "[T.type]"
        if(!findtext(turf_path, "dirt") && !findtext(turf_path, "grass") && !findtext(turf_path, "sand") && !findtext(turf_path, "snow") && !findtext(turf_path, "ice") && !findtext(turf_path, "floor") && !findtext(turf_path, "cave"))
            continue

        var/too_close = FALSE
        for(var/datum/dig_site/existing_site in active_sites)
            if(get_dist(T, existing_site.location) < 50)
                too_close = TRUE
                break
        if(too_close)
            continue

        if(get_site_at(T))
            continue

        var/new_name = generate_icao_name()
        var/datum/dig_site/D = new(T, new_name)
        active_sites += D
        return TRUE

    return FALSE

/datum/controller/subsystem/xeno_archaeology/proc/get_site_at(turf/T)
    for(var/datum/dig_site/D in active_sites)
        if(D.location == T)
            return D
    return null

/datum/controller/subsystem/xeno_archaeology/proc/clear_site(datum/dig_site/S)
    active_sites -= S
    qdel(S)
    generate_dig_site()

/datum/controller/subsystem/xeno_archaeology/proc/generate_icao_name()
    var/list/icao = list(
        "Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf",
        "Hotel", "India", "Juliet", "Kilo", "Lima", "Mike", "November",
        "Oscar", "Papa", "Quebec", "Romeo", "Sierra", "Tango", "Uniform",
        "Victor", "Whiskey", "Xray", "Yankee", "Zulu"
    )

    var/num = rand(1, 99999)
    var/num_string = "[num]"
    while(length(num_string) < 5)
        num_string = "0[num_string]"

    return "[pick(icao)]-[num_string]"
