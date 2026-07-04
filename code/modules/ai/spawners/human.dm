///Spawns a number of human mobs at a given location, based of a list of jobs
/proc/spawn_npc_squad(turf/location, list/role_list)
	if(!isturf(location))
		location = get_turf(location)
	if(!location)
		return
	var/list/mob_list = list()
	var/squad_to_insert_into
	var/datum/job/job_checked = SSjob.GetJobType(role_list[1])
	if(job_checked && ismarinejob(job_checked) && length(SSjob.active_squads[job_checked.faction]))
		squad_to_insert_into = pick(SSjob.active_squads[job_checked.faction])

	for(var/i = 1 to length(role_list))
		var/datum/job/new_job = SSjob.GetJobType(role_list[i])
		if(!new_job)
			stack_trace("spawn_npc_squad called with invalid job type [role_list[i]]")
			continue
		var/mob/living/carbon/human/new_human = new()
		mob_list += new_human
		new_human.apply_assigned_role_to_spawn(new_job, new_human.client, squad_to_insert_into, TRUE)
		new_human.faction = new_job.faction
		new_human.hud_set_job(new_human.faction)
		stoplag()

	for(var/mob/living/carbon/human/dude AS in mob_list)
		dude.forceMove(location)
		dude.AddComponent(/datum/component/ai_controller, /datum/ai_behavior/human)
		if(istype(dude.wear_ear, /obj/item/radio/headset/mainship)) //due to the lagginess of spawning in mobs, this won't proc at the right time normally
			var/obj/item/radio/headset/mainship/worn_headset = dude.wear_ear
			worn_headset.update_minimap_icon()

	return mob_list

/obj/effect/ai_node/spawner/human
	name = "AI human spawner node"
	use_post_spawn = TRUE //Gotta equip those AI you know

/obj/effect/ai_node/spawner/human/deathsquad
	spawn_types = /mob/living/carbon/human/node_pathing
	spawn_amount = 4
	spawn_delay = 10 SECONDS
	max_amount = 10

/obj/effect/ai_node/spawner/human/deathsquad/post_spawn(list/squad)
	var/mob/living/carbon/human/SL = pick_n_take(squad)
	var/datum/job/job = SSjob.GetJobType(/datum/job/deathsquad/leader)
	SL.apply_assigned_role_to_spawn(job)
	job = SSjob.GetJobType(/datum/job/deathsquad/standard)
	for(var/mob/living/carbon/human/squaddie AS in squad)
		squaddie.apply_assigned_role_to_spawn(job)
