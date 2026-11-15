/datum/action/ability/activable/xeno/secrete_resin/ui_state(mob/user)
	return GLOB.conscious_state

/datum/action/ability/activable/xeno/secrete_resin/ui_assets(mob/user)
	. = ..()
	. += get_asset_datum(/datum/asset/spritesheet/xenobuild)

/datum/action/ability/activable/xeno/secrete_resin/ui_interact(mob/user, datum/tgui/ui)
	ui_mode_active = TRUE
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "XenoBuildMenu", "Hive Construction")
		ui.open()

/datum/action/ability/activable/xeno/secrete_resin/ui_static_data(mob/user)
	. = ..()
	var/list/entries = list()
	var/list/catalog = get_xeno_build_catalog()
	for(var/key in catalog)
		var/datum/xeno_build_entry/entry = catalog[key]
		if(entry.unavailable_reason(xeno_owner))
			continue
		entries += list(entry.get_ui_data())
	var/list/patterns = list()
	for(var/id in get_xeno_build_patterns())
		var/datum/buildingpattern/pattern = GLOB.xeno_build_patterns[id]
		patterns += list(pattern.get_ui_data())
	.["entries"] = entries
	.["patterns"] = patterns
	.["categories"] = list("Walls", "Doors", "Misc", "Wells", "Psychic")

/datum/action/ability/activable/xeno/secrete_resin/ui_data(mob/user)
	. = ..()
	var/list/states = list()
	var/list/catalog = get_xeno_build_catalog()
	for(var/key in catalog)
		var/datum/xeno_build_entry/entry = catalog[key]
		if(entry.unavailable_reason(xeno_owner))
			continue
		states[key] = entry.get_state_data(xeno_owner)
	.["states"] = states
	.["ghost_mode"] = ghost_mode
	.["demolish_mode"] = demolish_mode
	.["auto_rebuild"] = auto_rebuild_mode
	.["pattern"] = selected_pattern.id
	.["selected"] = "[xeno_owner.selected_resin]"
	.["favorites"] = favorites
	.["can_pattern"] = xeno_owner.can_pattern_build()
	.["quickbuild"] = xeno_quickbuild_active()
	.["quickbuild_points"] = xeno_quickbuild_active() ? SSresinshaping.get_building_points(xeno_owner) : 0
	.["plasma"] = xeno_owner.plasma_stored
	.["psy_points"] = SSpoints.xeno_points_by_hive[xeno_owner.hivenumber]
	.["range"] = xeno_owner.get_build_range()
	.["can_undo"] = length(undo_stack) > 0
	.["can_redo"] = length(redo_stack) > 0

/datum/action/ability/activable/xeno/secrete_resin/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("undo")
			step_back()
			return TRUE
		if("redo")
			step_forward()
			return TRUE
		if("toggle_ghost")
			ui_mode_active = TRUE
			ghost_mode = istype(xeno_owner, /mob/living/carbon/xenomorph/hivemind) ? TRUE : !ghost_mode
			ensure_selected()
			return TRUE
		if("toggle_auto_rebuild")
			ui_mode_active = TRUE
			auto_rebuild_mode = !auto_rebuild_mode
			ensure_selected()
			return TRUE
		if("toggle_demolish")
			ui_mode_active = TRUE
			demolish_mode = !demolish_mode
			ensure_selected()
			cleanup_holograms()
			return TRUE
		if("select_pattern")
			ui_mode_active = TRUE
			var/datum/buildingpattern/pattern = get_xeno_build_patterns()[params["id"]]
			if(!pattern)
				return
			selected_pattern = pattern
			xeno_owner.balloon_alert(xeno_owner, pattern.overheadmsg)
			ensure_selected()
			cleanup_holograms()
			return TRUE
		if("select_entry")
			ui_mode_active = TRUE
			var/datum/xeno_build_entry/entry = get_xeno_build_catalog()[params["key"]]
			if(!entry || entry.unavailable_reason(xeno_owner))
				return
			select_entry(entry)
			demolish_mode = FALSE
			ensure_selected()
			cleanup_holograms()
			return TRUE
		if("toggle_favorite")
			var/key = params["key"]
			if(!get_xeno_build_catalog()[key])
				return
			if(key in favorites)
				favorites -= key
			else
				favorites += key
			return TRUE


/datum/action/ability/activable/xeno/secrete_resin/ui_close(mob/user)
	if(user == xeno_owner)
		ui_mode_active = FALSE
		if(xeno_owner.selected_ability == src)
			deselect()
	return ..()
