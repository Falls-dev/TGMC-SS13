// ============================================================
// Transform tab.
//
// The category -> {name, path, color} table below mirrors the exact set of
// transform options TGMC's `topic.dm` `href_list["transform"]` switch supports
// today (not RU's transform list, which includes several TGMC-nonexistent
// castes/species).
// ============================================================

GLOBAL_LIST_INIT(pp_transformables, list(
	"Special" = list(
		list(name = "Observer", key = "observer", color = "grey"),
		list(name = "AI", key = "ai", color = "grey"),
		list(name = "Sectoid", key = "sectoid", color = "grey"),
		list(name = "Skeleton", key = "SKELETON", color = "grey"),
		list(name = "Yautja", key = "yautja", color = "grey"),
	),

	"Humanoid" = list(
		list(name = "Human", key = "human", color = "green"),
		list(name = "Synthetic", key = "synthetic", color = "green"),
		list(name = "Engineer Synth", key = "engineer_synth", color = "green"),
		list(name = "Medical Synth", key = "medical_synth", color = "green"),
		list(name = "Vatborn", key = "vatborn", color = "green"),
		list(name = "Vatgrown", key = "vatgrown", color = "green"),
		list(name = "Combat Robot", key = "combat_robot", color = "green"),
		list(name = "Monkey", key = "monkey", color = "green"),
		list(name = "Moth", key = "moth", color = "green"),
		list(name = "Zombie", key = "zombie", color = "green"),
		list(name = "Hellhound", key = "hellhound", color = "green"),
	),

	"Alien Tier 0" = list(
		list(name = "Larva", key = "larva", color = "purple"),
		list(name = "Predalien Larva", key = "predalien_larva", color = "purple"),
		list(name = "Facehugger", key = "facehugger", color = "purple"),
	),

	"Alien Tier 1" = list(
		list(name = "Runner", key = "runner", color = "purple"),
		list(name = "Drone", key = "drone", color = "purple"),
		list(name = "Sentinel", key = "sentinel", color = "purple"),
		list(name = "Defender", key = "defender", color = "purple"),
	),

	"Alien Tier 2" = list(
		list(name = "Hunter", key = "hunter", color = "purple"),
		list(name = "Panther", key = "panther", color = "purple"),
		list(name = "Bull", key = "bull", color = "purple"),
		list(name = "Warrior", key = "warrior", color = "purple"),
		list(name = "Spitter", key = "spitter", color = "purple"),
		list(name = "Hivelord", key = "hivelord", color = "purple"),
		list(name = "Carrier", key = "carrier", color = "purple"),
	),

	"Alien Tier 3" = list(
		list(name = "Ravager", key = "ravager", color = "purple"),
		list(name = "Praetorian", key = "praetorian", color = "purple"),
		list(name = "Boiler", key = "boiler", color = "purple"),
		list(name = "Defiler", key = "defiler", color = "purple"),
		list(name = "Crusher", key = "crusher", color = "purple"),
		list(name = "Gorger", key = "gorger", color = "purple"),
		list(name = "Warlock", key = "warlock", color = "purple"),
		list(name = "Widow", key = "widow", color = "purple"),
		list(name = "Behemoth", key = "behemoth", color = "purple"),
		list(name = "Chimera", key = "chimera", color = "purple"),
		list(name = "Dragon", key = "dragon", color = "purple"),
		list(name = "Pyrogen", key = "pyrogen", color = "purple"),
	),

	"Alien Tier 4" = list(
		list(name = "Queen", key = "queen", color = "purple"),
		list(name = "Shrike", key = "shrike", color = "purple"),
		list(name = "Hivemind", key = "hivemind", color = "purple"),
		list(name = "King", key = "king", color = "purple"),
		list(name = "Predalien", key = "predalien", color = "purple"),
	),
))

/datum/player_action/transform
	action_tag = "mob_transform"
	name = "Transform"
	permissions_required = R_ADMIN

/datum/player_action/transform/act(client/user, mob/target, list/params)
	var/transform_key = params["key"]
	if(!transform_key)
		return

	var/mob/old_mob = user.mob

	var/delmob
	switch(tgui_alert(user, "Delete old mob?", "Message", list("Yes", "No")))
		if("Yes")
			delmob = TRUE
		if("No")
			delmob = FALSE
		else
			return

	var/turf/location
	switch(tgui_alert(user, "Teleport to your location?", "Message", list("Yes", "No")))
		if("Yes")
			location = get_turf(old_mob)
		if("No")
			location = null
		else
			return

	if(QDELETED(target))
		return

	var/mob/new_mob

	switch(transform_key)
		if("observer")
			new_mob = target.ghostize()
			if(isobserver(target) && new_mob.icon == initial(new_mob.icon))
				new_mob.alpha = 255
			if(delmob)
				qdel(target)
			if(location)
				new_mob.forceMove(location)
		if("larva")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/larva, location, null, delmob)
		if("defender")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/defender, location, null, delmob)
		if("warrior")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/warrior, location, null, delmob)
		if("runner")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/runner, location, null, delmob)
		if("drone")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/drone, location, null, delmob)
		if("sentinel")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/sentinel, location, null, delmob)
		if("bull")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/bull, location, null, delmob)
		if("hunter")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/hunter, location, null, delmob)
		if("carrier")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/carrier, location, null, delmob)
		if("hivelord")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/hivelord, location, null, delmob)
		if("praetorian")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/praetorian, location, null, delmob)
		if("ravager")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/ravager, location, null, delmob)
		if("spitter")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/spitter, location, null, delmob)
		if("boiler")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/boiler, location, null, delmob)
		if("crusher")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/crusher, location, null, delmob)
		if("defiler")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/defiler, location, null, delmob)
		if("gorger")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/gorger, location, null, delmob)
		if("warlock")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/warlock, location, null, delmob)
		if("widow")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/widow, location, null, delmob)
		if("shrike")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/shrike, location, null, delmob)
		if("hivemind")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/hivemind, location, null, delmob)
		if("queen")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/queen, location, null, delmob)
		if("king")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/king, location, null, delmob)
		if("dragon")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/dragon, location, null, delmob)
		if("pyrogen")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/pyrogen, location, null, delmob)
		if("behemoth")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/behemoth, location, null, delmob)
		if("human")
			new_mob = target.change_mob_type(/mob/living/carbon/human, location, null, delmob)
		if("synthetic")
			new_mob = target.change_mob_type(/mob/living/carbon/human/species/synthetic, location, null, delmob)
		if("early_synth", "engineer_synth")
			// #118 renamed early -> engineer; keep both path strings so this compiles in test-merge and standalone.
			var/engineer_path = text2path("/mob/living/carbon/human/species/synthetic/engineer") || text2path("/mob/living/carbon/human/species/synthetic/early") || /mob/living/carbon/human/species/synthetic
			new_mob = target.change_mob_type(engineer_path, location, null, delmob)
		if("medical_synth")
			var/medical_path = text2path("/mob/living/carbon/human/species/synthetic/medical") || /mob/living/carbon/human/species/synthetic
			new_mob = target.change_mob_type(medical_path, location, null, delmob)
		if("sectoid")
			new_mob = target.change_mob_type(/mob/living/carbon/human/species/sectoid, location, null, delmob)
		if("vatborn")
			new_mob = target.change_mob_type(/mob/living/carbon/human/species/vatborn, location, null, delmob)
		if("vatgrown")
			new_mob = target.change_mob_type(/mob/living/carbon/human/species/vatgrown, location, null, delmob)
		if("combat_robot")
			new_mob = target.change_mob_type(/mob/living/carbon/human/species/robot, location, null, delmob)
		if("SKELETON")
			new_mob = target.change_mob_type(/mob/living/carbon/human/species/skeleton, location, null, delmob)
		if("monkey")
			new_mob = target.change_mob_type(/mob/living/carbon/human/species/monkey, location, null, delmob, "Monkey")
		if("moth")
			new_mob = target.change_mob_type(/mob/living/carbon/human/species/moth, location, null, delmob, "Moth")
		if("zombie")
			new_mob = target.change_mob_type(/mob/living/carbon/human/species/zombie, location, null, delmob, "Zombie")
		if("ai")
			new_mob = target.change_mob_type(/mob/living/silicon/ai, location, null, delmob)
		if("facehugger")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/facehugger, location, null, delmob)
		if("panther")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/panther, location, null, delmob)
		if("chimera")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/chimera, location, null, delmob)
		if("hellhound")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/hellhound, location, null, delmob)
		if("predalien_larva")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/larva/predalien, location, null, delmob)
		if("predalien")
			new_mob = target.change_mob_type(/mob/living/carbon/xenomorph/predalien, location, null, delmob)
		if("yautja")
			new_mob = target.change_mob_type(/mob/living/carbon/human/species/yautja, location, null, delmob)
		else
			return

	SSadmin_verbs.dynamic_invoke_verb(user, /datum/admin_verb/show_player_panel, new_mob || target)

	log_admin("[key_name(old_mob)] has transformed [key_name(new_mob ? new_mob : target)] into [transform_key].[delmob ? " Old mob deleted." : ""][location ? " Teleported to [AREACOORD(location)]" : ""]")
	message_admins("[delmob ? key_name_admin(old_mob) : ADMIN_TPMONTY(old_mob)] has transformed [new_mob ? ADMIN_TPMONTY(new_mob) : ADMIN_TPMONTY(target)] into [transform_key].[delmob ? " Old mob deleted." : ""][location ? " Teleported to new location." : ""]")
	return TRUE
