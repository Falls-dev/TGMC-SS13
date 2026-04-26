GLOBAL_LIST_INIT(xeno_skins_by_caste, init_xeno_skin_registry())

/proc/init_xeno_skin_registry()
	var/list/registry = list()

	registry[/datum/xeno_caste/boiler] = list(/datum/xenomorph_skin/boiler/base, /datum/xenomorph_skin/boiler/rouny)
	registry[/datum/xeno_caste/bull] = list(/datum/xenomorph_skin/bull/base, /datum/xenomorph_skin/bull/rouny)
	registry[/datum/xeno_caste/crusher] = list(/datum/xenomorph_skin/crusher/base, /datum/xenomorph_skin/crusher/rouny)
	registry[/datum/xeno_caste/defender] = list(/datum/xenomorph_skin/defender/base, /datum/xenomorph_skin/defender/rouny)
	registry[/datum/xeno_caste/defiler] = list(/datum/xenomorph_skin/defiler/base, /datum/xenomorph_skin/defiler/rouny)
	registry[/datum/xeno_caste/drone] = list(/datum/xenomorph_skin/drone/base, /datum/xenomorph_skin/drone/rouny, /datum/xenomorph_skin/drone/king, /datum/xenomorph_skin/drone/cyborg, /datum/xenomorph_skin/drone/hornet)
	registry[/datum/xeno_caste/gorger] = list(/datum/xenomorph_skin/gorger/base, /datum/xenomorph_skin/gorger/rouny)
	registry[/datum/xeno_caste/hivelord] = list(/datum/xenomorph_skin/hivelord/base, /datum/xenomorph_skin/hivelord/rouny)
	registry[/datum/xeno_caste/king] = list(/datum/xenomorph_skin/king/base, /datum/xenomorph_skin/king/red)
	registry[/datum/xeno_caste/praetorian] = list(/datum/xenomorph_skin/praetorian/base, /datum/xenomorph_skin/praetorian/rouny, /datum/xenomorph_skin/praetorian/tacticool)
	registry[/datum/xeno_caste/queen] = list(/datum/xenomorph_skin/queen/base, /datum/xenomorph_skin/queen/rouny)
	registry[/datum/xeno_caste/ravager] = list(/datum/xenomorph_skin/ravager/base, /datum/xenomorph_skin/ravager/rouny, /datum/xenomorph_skin/ravager/bonehead)
	registry[/datum/xeno_caste/runner] = list(/datum/xenomorph_skin/runner/base, /datum/xenomorph_skin/runner/rouny, /datum/xenomorph_skin/runner/gold, /datum/xenomorph_skin/runner/gold_rouny, /datum/xenomorph_skin/runner/tacticool)
	registry[/datum/xeno_caste/scorpion] = list(/datum/xenomorph_skin/scorpion/base, /datum/xenomorph_skin/scorpion/crab)
	registry[/datum/xeno_caste/shrike] = list(/datum/xenomorph_skin/shrike/base, /datum/xenomorph_skin/shrike/rouny, /datum/xenomorph_skin/shrike/joker, /datum/xenomorph_skin/shrike/clown)
	registry[/datum/xeno_caste/warlock] = list(/datum/xenomorph_skin/warlock/base, /datum/xenomorph_skin/warlock/rouny, /datum/xenomorph_skin/warlock/arabian)
	registry[/datum/xeno_caste/warrior] = list(/datum/xenomorph_skin/warrior/base, /datum/xenomorph_skin/warrior/rouny)

	return registry

/mob/living/carbon/xenomorph
	var/effects_icon

/mob/living/carbon/xenomorph/verb/change_appearance()
	set name = "Change appearance"
	set desc = "Changes your appearance."
	set category = "Alien"

	change_skin()

/mob/living/carbon/xenomorph/proc/get_registered_skin_typepaths()
	RETURN_TYPE(/list)
	var/list/registered = GLOB.xeno_skins_by_caste?[caste_base_type]
	return islist(registered) ? registered.Copy() : list()

/mob/living/carbon/xenomorph/proc/get_available_skins()
	RETURN_TYPE(/list)
	var/list/typepaths = get_registered_skin_typepaths()
	var/list/available = list()
	var/admin_access = check_other_rights(client, R_ADMIN, FALSE)
	for(var/datum/xenomorph_skin/skin_path as anything in typepaths)
		var/datum/xenomorph_skin/skin = new skin_path
		if(skin.admin_only && !admin_access)
			continue
		available[skin.name] = skin
	return available

/mob/living/carbon/xenomorph/proc/change_skin()
	var/list/available_skins = get_available_skins()
	if(length(available_skins) < 2)
		balloon_alert(src, "нет доступных скинов")
		return

	var/answer = tgui_input_list(src, "Выберите внешний вид", "Скины ксеноморфа", available_skins)
	var/datum/xenomorph_skin/selection = available_skins[answer]
	if(!selection)
		return

	icon = selection.icon
	effects_icon = selection.get_effects_icon()
	if(fire_overlay)
		fire_overlay.icon = effects_icon
		fire_overlay.update_appearance(UPDATE_ICON)
	regenerate_icons()
