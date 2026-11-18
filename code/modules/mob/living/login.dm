/mob/living/Login()
	. = ..()
	//Mind updates
	mind_initialize()	//updates the mind (or creates and initializes one if one doesn't exist)
	mind.active = TRUE		//indicates that the mind is currently synced with a client

	INVOKE_ASYNC(SSdiscord, TYPE_PROC_REF(/datum/controller/subsystem/discord, get_boosty_tier), ckey)

	var/turf/mob_turf = get_turf(src)
	if(isturf(mob_turf))
		update_z(mob_turf.z)

	if(HAS_TRAIT(src, TRAIT_MOVE_VENTCRAWLING) && istype(loc, /obj/machinery/atmospherics))
		client.images -= pipes_shown
		pipes_shown.Cut()
		reset_perspective(loc)
	LAZYREMOVE(GLOB.ssd_living_mobs, src)
	set_afk_status(MOB_CONNECTED)
