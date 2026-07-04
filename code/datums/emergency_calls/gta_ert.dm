/datum/emergency_call/gta/ballas
	name = "Ballas Street Gang"
	base_probability = 6
	alignement_factor = 1

/datum/emergency_call/gta/ballas/print_backstory(mob/living/carbon/human/H)
	to_chat(H, "<B>You rep the Ballas — purple runs deep in your veins and your bandana.</B>")
	to_chat(H, "<B>Word on the street is something went down near [SSmapping.configs[SHIP_MAP].map_name]. Time to show up, take what's yours, and remind everyone who runs these blocks.</B>")
	to_chat(H, "<B>Stick with your set. Don't let Grove or the corps get in your way.</B>")

/datum/emergency_call/gta/ballas/create_member(datum/mind/M)
	. = ..()
	if(!.)
		return
	var/mob/original = M.current
	var/mob/living/carbon/human/H = .
	M.transfer_to(H, TRUE)
	H.fully_replace_character_name(M.name, H.real_name)
	if(original)
		qdel(original)
	print_backstory(H)
	if(!leader)
		leader = H
		var/datum/job/J = SSjob.GetJobType(/datum/job/gta/ert/ballas/leader)
		H.apply_assigned_role_to_spawn(J)
		to_chat(H, "<p style='font-size:1.5em'>[span_danger("You are the OG of this Ballas crew. Keep the homies in line.")]</p>")
		return
	if(medics < max_medics)
		var/datum/job/J = SSjob.GetJobType(/datum/job/gta/ert/ballas/medic)
		H.apply_assigned_role_to_spawn(J)
		to_chat(H, "<p style='font-size:1.5em'>[span_danger("You patch up the Ballas when the shooting starts.")]</p>")
		medics++
		return
	var/datum/job/J = SSjob.GetJobType(/datum/job/gta/ert/ballas/standard)
	H.apply_assigned_role_to_spawn(J)
	to_chat(H, span_danger("You are a Ballas gang member rolling on the distress signal."))

/datum/emergency_call/gta/grove
	name = "Grove Street Families"
	base_probability = 6
	alignement_factor = 1

/datum/emergency_call/gta/grove/print_backstory(mob/living/carbon/human/H)
	to_chat(H, "<B>You are Grove Street — green rag, loyal crew, and a long feud with the Ballas.</B>")
	to_chat(H, "<B>Chaos near [SSmapping.configs[SHIP_MAP].map_name] means opportunity. Roll up with your homies and set things straight.</B>")
	to_chat(H, "<B>Grove Street, home. At least it was before all this.</B>")

/datum/emergency_call/gta/grove/create_member(datum/mind/M)
	. = ..()
	if(!.)
		return
	var/mob/original = M.current
	var/mob/living/carbon/human/H = .
	M.transfer_to(H, TRUE)
	H.fully_replace_character_name(M.name, H.real_name)
	if(original)
		qdel(original)
	print_backstory(H)
	if(!leader)
		leader = H
		var/datum/job/J = SSjob.GetJobType(/datum/job/gta/ert/grove/leader)
		H.apply_assigned_role_to_spawn(J)
		to_chat(H, "<p style='font-size:1.5em'>[span_danger("You are the OG of this Grove Street crew. Hold the block down.")]</p>")
		return
	if(medics < max_medics)
		var/datum/job/J = SSjob.GetJobType(/datum/job/gta/ert/grove/medic)
		H.apply_assigned_role_to_spawn(J)
		to_chat(H, "<p style='font-size:1.5em'>[span_danger("You keep the Grove alive when bullets fly.")]</p>")
		medics++
		return
	var/datum/job/J = SSjob.GetJobType(/datum/job/gta/ert/grove/standard)
	H.apply_assigned_role_to_spawn(J)
	to_chat(H, span_danger("You are a Grove Street gang member rolling on the distress signal."))
