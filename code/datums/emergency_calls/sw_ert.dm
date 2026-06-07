/datum/emergency_call/sw/rebels
	name = "Rebel Alliance Squad"
	base_probability = 8
	alignement_factor = -1

/datum/emergency_call/sw/rebels/print_backstory(mob/living/carbon/human/H)
	to_chat(H, "<B>You are a soldier of the Rebel Alliance, fighting the tyranny of distant empires wherever they appear.</B>")
	to_chat(H, "<B>A distress signal from [SSmapping.configs[SHIP_MAP].map_name] has reached your cell. The Alliance sends you to investigate — and to help, if the cause is just.</B>")

/datum/emergency_call/sw/rebels/create_member(datum/mind/M)
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
		var/datum/job/J = SSjob.GetJobType(/datum/job/sw/ert/rebel/officer)
		H.apply_assigned_role_to_spawn(J)
		to_chat(H, "<p style='font-size:1.5em'>[span_notice("You lead this Rebel fireteam. For the Alliance!")]</p>")
		return
	if(medics < max_medics)
		var/datum/job/J = SSjob.GetJobType(/datum/job/sw/ert/rebel/medic)
		H.apply_assigned_role_to_spawn(J)
		to_chat(H, "<p style='font-size:1.5em'>[span_notice("You are the Rebel medic attached to this squad.")]</p>")
		medics++
		return
	var/datum/job/J = SSjob.GetJobType(/datum/job/sw/ert/rebel)
	H.apply_assigned_role_to_spawn(J)
	to_chat(H, span_notice("You are a Rebel trooper responding to the distress signal."))

/datum/emergency_call/sw/republic_clones
	name = "Grand Army of the Republic Squad"
	base_probability = 8
	alignement_factor = -1

/datum/emergency_call/sw/republic_clones/print_backstory(mob/living/carbon/human/H)
	to_chat(H, "<B>You are a clone trooper of the Grand Army of the Republic, bred for war and loyal to the Senate.</B>")
	to_chat(H, "<B>Your unit has been dispatched to answer a distress call from [SSmapping.configs[SHIP_MAP].map_name]. Execute your orders and protect the innocent.</B>")

/datum/emergency_call/sw/republic_clones/create_member(datum/mind/M)
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
		var/datum/job/J = SSjob.GetJobType(/datum/job/sw/ert/republic/sergeant)
		H.apply_assigned_role_to_spawn(J)
		to_chat(H, "<p style='font-size:1.5em'>[span_notice("You are the sergeant of this clone fireteam. Good soldiers follow orders.")]</p>")
		return
	if(medics < max_medics)
		var/datum/job/J = SSjob.GetJobType(/datum/job/sw/ert/republic/medic)
		H.apply_assigned_role_to_spawn(J)
		to_chat(H, "<p style='font-size:1.5em'>[span_notice("You are the clone medic of this fireteam.")]</p>")
		medics++
		return
	var/datum/job/J = SSjob.GetJobType(/datum/job/sw/ert/republic)
	H.apply_assigned_role_to_spawn(J)
	to_chat(H, span_notice("You are a Republic clone trooper responding to the distress call."))

/datum/emergency_call/sw/republic_elite
	name = "Republic Elite Clone Detachment"
	base_probability = 5
	alignement_factor = -1
	var/max_commandos = 2

/datum/emergency_call/sw/republic_elite/do_activate(announce = TRUE)
	max_commandos = max(1, round(mob_max * 0.2))
	return ..()

/datum/emergency_call/sw/republic_elite/print_backstory(mob/living/carbon/human/H)
	to_chat(H, "<B>You are an elite clone of the Grand Army of the Republic — among the best the Kaminoans ever produced.</B>")
	to_chat(H, "<B>Special orders have sent your detachment to [SSmapping.configs[SHIP_MAP].map_name]. Failure is not an option.</B>")

/datum/emergency_call/sw/republic_elite/create_member(datum/mind/M)
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
		var/datum/job/J = SSjob.GetJobType(/datum/job/sw/ert/republic/elite)
		H.apply_assigned_role_to_spawn(J)
		to_chat(H, "<p style='font-size:1.5em'>[span_notice("You command this elite clone detachment.")]</p>")
		return
	if(max_commandos > 0)
		var/datum/job/J = SSjob.GetJobType(/datum/job/sw/ert/republic/elite/commando)
		H.apply_assigned_role_to_spawn(J)
		to_chat(H, "<p style='font-size:1.5em'>[span_notice("You are a Republic clone commando — the tip of the spear.")]</p>")
		max_commandos--
		return
	var/datum/job/J = SSjob.GetJobType(/datum/job/sw/ert/republic/elite)
	H.apply_assigned_role_to_spawn(J)
	to_chat(H, span_notice("You are an elite Republic clone responding to the distress call."))

/datum/emergency_call/sw/imperials
	name = "Imperial Stormtrooper Squad"
	base_probability = 8
	alignement_factor = 1

/datum/emergency_call/sw/imperials/print_backstory(mob/living/carbon/human/H)
	to_chat(H, "<B>You serve the Galactic Empire. Order will be maintained — by force, if necessary.</B>")
	to_chat(H, "<B>Intelligence reports a distress signal from [SSmapping.configs[SHIP_MAP].map_name]. Your squad is to secure the area and eliminate any threats to Imperial interests.</B>")

/datum/emergency_call/sw/imperials/create_member(datum/mind/M)
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
		var/datum/job/J = SSjob.GetJobType(/datum/job/sw/ert/imperial/officer)
		H.apply_assigned_role_to_spawn(J)
		to_chat(H, "<p style='font-size:1.5em'>[span_danger("You lead this Imperial squad. Long live the Empire!")]</p>")
		return
	if(medics < max_medics)
		var/datum/job/J = SSjob.GetJobType(/datum/job/sw/ert/imperial/medic)
		H.apply_assigned_role_to_spawn(J)
		to_chat(H, "<p style='font-size:1.5em'>[span_danger("You are the Imperial field surgeon attached to this squad.")]</p>")
		medics++
		return
	var/datum/job/J = SSjob.GetJobType(/datum/job/sw/ert/imperial)
	H.apply_assigned_role_to_spawn(J)
	to_chat(H, span_danger("You are an Imperial stormtrooper responding to the distress signal."))

/datum/emergency_call/sw/imperial_guard
	name = "Imperial Guard Detachment"
	base_probability = 3
	alignement_factor = 1

/datum/emergency_call/sw/imperial_guard/print_backstory(mob/living/carbon/human/H)
	to_chat(H, "<B>You are among the Emperor's most trusted protectors — Royal Guard or Senate Guard, hand-picked and deadly.</B>")
	to_chat(H, "<B>A matter of utmost importance draws you to [SSmapping.configs[SHIP_MAP].map_name]. None may stand in your way.</B>")

/datum/emergency_call/sw/imperial_guard/create_member(datum/mind/M)
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
		var/datum/job/J = SSjob.GetJobType(/datum/job/sw/ert/imperial/guard)
		H.apply_assigned_role_to_spawn(J)
		to_chat(H, "<p style='font-size:1.5em'>[span_danger("You lead the Imperial Guard detachment.")]</p>")
		return
	if(prob(50))
		var/datum/job/J = SSjob.GetJobType(/datum/job/sw/ert/imperial/guard/senate)
		H.apply_assigned_role_to_spawn(J)
		to_chat(H, "<p style='font-size:1.5em'>[span_danger("You serve as a Senate Guard in this detachment.")]</p>")
		return
	var/datum/job/J = SSjob.GetJobType(/datum/job/sw/ert/imperial/guard)
	H.apply_assigned_role_to_spawn(J)
	to_chat(H, span_danger("You are a Royal Guardsman responding to the distress signal."))
