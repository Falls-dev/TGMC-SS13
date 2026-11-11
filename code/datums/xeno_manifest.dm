GLOBAL_DATUM_INIT(xeno_manifest, /datum/xeno_manifest, new)

/datum/xeno_manifest/ui_state(mob/user)
	return GLOB.new_player_state

/datum/xeno_manifest/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "XenoManifest", "Xeno Manifest")
		ui.open()

/datum/xeno_manifest/ui_data(mob/user)
	var/list/sections = list()
	var/datum/hive_status/main_hive = GLOB.hive_datums[XENO_HIVE_NORMAL]
	if(!main_hive)
		return list("sections" = sections)

	var/list/listed_xenos = list()
	if(main_hive.living_xeno_ruler)
		listed_xenos += main_hive.living_xeno_ruler
		sections += list(make_section("Hive Ruler", listed_xenos))

	var/list/leaders = main_hive.xeno_leader_list - listed_xenos
	if(length(leaders))
		sections += list(make_section("Hive Leaders", leaders))
		listed_xenos += leaders

	for(var/index = length(GLOB.xenotiers) to 1 step -1)
		var/tier = GLOB.xenotiers[index]
		var/list/members = main_hive.xenos_by_tier[tier] - listed_xenos
		if(!length(members))
			continue
		var/title = tier == XENO_TIER_MINION ? "Minions" : "T[GLOB.tier_as_number[tier]] Xenomorphs"
		sections += list(make_section(title, members))

	return list("sections" = sections)

/datum/xeno_manifest/proc/make_section(title, list/members)
	var/list/entries = list()
	for(var/mob/living/carbon/xenomorph/member as anything in members)
		entries += list(list(
			"id" = REF(member),
			"name" = member.name,
			"caste" = member.xeno_caste.display_name,
		))
	return list("title" = title, "entries" = entries)
