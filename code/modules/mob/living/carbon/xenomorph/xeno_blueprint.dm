#define XENO_BLUEPRINT_HUD "xeno_blueprint_hud"

/// Whether free building is active before shutters open
/// Build range while quick-building: whole patterns fit around the cursor
#define QUICKBUILD_BUILD_RANGE 4

/proc/xeno_quickbuild_active()
	return SSmonitor.gamestate == SHUTTERS_CLOSED && CHECK_BITFIELD(SSticker.mode?.round_type_flags, MODE_ALLOW_XENO_QUICKBUILD) && SSresinshaping.active

/// Lazy catalog, key => entry. Lazy because the game mode is only needed for psychic builds
/proc/get_xeno_build_catalog()
	if(length(GLOB.xeno_build_catalog))
		return GLOB.xeno_build_catalog
	for(var/type in subtypesof(/datum/xeno_build_entry))
		var/datum/xeno_build_entry/entry = new type
		if(entry.path)
			GLOB.xeno_build_catalog[entry.key] = entry
	for(var/type in subtypesof(/datum/hive_upgrade/building))
		var/datum/hive_upgrade/building/upgrade = new type
		if(upgrade.name == "Error upgrade" || !upgrade.building_type)
			qdel(upgrade)
			continue
		var/datum/xeno_build_entry/psychic/entry = new(upgrade)
		GLOB.xeno_build_catalog[entry.key] = entry
		qdel(upgrade)
	return GLOB.xeno_build_catalog

/datum/xeno_build_entry
	var/key
	var/name
	var/desc
	var/category
	var/atom/path
	var/kind = BUILD_KIND_RESIN
	/// For wells: the ability whose cooldown/plasma is spent
	var/ability_type
	var/wait_mult = 1
	var/cost_div = 1
	/// Needs an adjacent wall/door
	var/needs_support = FALSE
	var/spacing_type
	var/spacing_range = 0
	/// For the UI icon: file and state. For psychic - state from the blessing menu
	var/icon_file = 'icons/Xeno/actions/construction.dmi'
	var/icon_state

/datum/xeno_build_entry/New()
	. = ..()
	if(!path)
		return
	key = "[path]"
	name ||= initial(path.name)
	icon_state ||= name

/// Reason this is unavailable for this xeno, or null
/datum/xeno_build_entry/proc/unavailable_reason(mob/living/carbon/xenomorph/X)
	switch(kind)
		if(BUILD_KIND_RESIN)
			var/datum/action/ability/activable/xeno/secrete_resin/resin = locate() in X.actions
			if(resin)
				return (path in resin.buildable_structures) ? null : "Not in our repertoire"
			return (path == /turf/closed/wall/resin/regenerating) ? null : "Requires a builder caste"
		if(BUILD_KIND_WELL)
			return (locate(ability_type) in X.actions) ? null : "Requires a builder caste"
	return null

/// Tile check: NO_ERROR or ERROR_*
/datum/xeno_build_entry/proc/check_turf(turf/T)
	if(!T)
		return ERROR_JUST_NO
	if(kind == BUILD_KIND_RESIN)
		. = is_valid_for_resin_structure(T, needs_support, path)
	else
		. = check_structure_turf(T)
	if(. != NO_ERROR)
		return
	if(spacing_type)
		for(var/atom/near in range(spacing_range, T))
			if(istype(near, spacing_type))
				return ERROR_JUST_NO

/// Wells and psychic builds: same as in old abilities
/datum/xeno_build_entry/proc/check_structure_turf(turf/T)
	if(!T.is_weedable() || T.density)
		return ERROR_CANT_WEED
	if(!(locate(/obj/alien/weeds) in T))
		return ERROR_NO_WEED
	if(!T.check_disallow_alien_fortification(null, TRUE))
		return ERROR_NOT_ALLOWED
	if(!T.check_alien_construction(null, TRUE, path))
		return ERROR_CONSTRUCT
	return NO_ERROR

/// Prefix in the xenobuild spritesheet: c_ = construction.dmi, h_ = hivelord.dmi, p_ = buyable_icons.dmi
/datum/xeno_build_entry/proc/get_icon_class()
	var/prefix = (icon_file == 'icons/Xeno/actions/hivelord.dmi') ? "h_" : "c_"
	return "xenobuild32x32 [prefix][replacetext(icon_state, " ", "_")]"

/// Icon file of the ability button; icon_state is shared with the UI/radial
/datum/xeno_build_entry/proc/get_action_icon()
	return icon_file

/// Icon for radial menus
/datum/xeno_build_entry/proc/get_radial_image()
	return image(icon_file, icon_state = icon_state)

/// Static data for the UI
/datum/xeno_build_entry/proc/get_ui_data()
	return list("key" = key, "name" = name, "desc" = desc, "category" = category, "kind" = kind, "icon" = get_icon_class())

/// Dynamic data for the UI: cost, resource, cooldown, whether the resource suffices
/datum/xeno_build_entry/proc/get_state_data(mob/living/carbon/xenomorph/X)
	var/cost = 0
	var/cooldown = 0
	var/datum/action/ability/ability
	if(kind == BUILD_KIND_WELL)
		ability = locate(ability_type) in X.actions
		cost = ability?.ability_cost
		cooldown = ability?.cooldown_timer ? round(ability.cooldown_remaining()) : 0
	else
		ability = locate(/datum/action/ability/activable/xeno/secrete_resin) in X.actions
		cost = ability ? ability.ability_cost / cost_div : NONBUILDER_WALL_COST
		if(SSmonitor.gamestate == SHUTTERS_CLOSED)
			cost *= 0.5
	var/free = X.uses_quickbuild(src)
	return list("cost" = free ? 0 : round(cost), "unit" = "plasma", "cooldown" = cooldown, "ok" = free || (X.plasma_stored >= cost && !cooldown))

// --- Walls
/datum/xeno_build_entry/wall
	category = "Walls"
	path = /turf/closed/wall/resin/regenerating
	icon_state = RESIN_WALL

/datum/xeno_build_entry/wall/bulletproof
	path = /turf/closed/wall/resin/regenerating/bulletproof
	icon_state = RESIN_WALL_BULLET

/datum/xeno_build_entry/wall/fireproof
	path = /turf/closed/wall/resin/regenerating/fireproof
	icon_state = RESIN_WALL_FIRE

/datum/xeno_build_entry/wall/hardy
	path = /turf/closed/wall/resin/regenerating/hardy
	icon_state = RESIN_WALL_HARDY

/datum/xeno_build_entry/wall/thick
	path = /turf/closed/wall/resin/regenerating/thick
	icon_state = RESIN_WALL

// --- Doors
/datum/xeno_build_entry/door
	category = "Doors"
	path = /obj/structure/mineral_door/resin
	icon_state = RESIN_DOOR
	needs_support = TRUE
	spacing_type = /obj/structure/mineral_door/resin
	spacing_range = 2

/datum/xeno_build_entry/door/thick
	path = /obj/structure/mineral_door/resin/thick
	needs_support = FALSE

// --- Misc
/datum/xeno_build_entry/sticky
	category = "Misc"
	path = /obj/alien/resin/sticky
	icon_state = STICKY_RESIN
	wait_mult = 0.5
	cost_div = 3

/datum/xeno_build_entry/nest
	category = "Misc"
	path = /obj/structure/bed/nest
	icon_state = ALIEN_NEST
	spacing_type = /obj/structure/bed/nest
	spacing_range = 2

// --- Hivemind: instant growths
/datum/xeno_build_entry/growth
	category = "Misc"
	path = /obj/alien/resin/resin_growth
	icon_state = GROWTH_WALL
	wait_mult = 0

/datum/xeno_build_entry/growth/door
	category = "Doors"
	path = /obj/alien/resin/resin_growth/door
	icon_state = GROWTH_DOOR

// --- Wells
/datum/xeno_build_entry/acidwell
	category = "Wells"
	kind = BUILD_KIND_WELL
	path = /obj/structure/xeno/acidwell
	ability_type = /datum/action/ability/xeno_action/place_acidwell
	icon_state = "place_trap"
	spacing_type = /obj/structure/xeno/acidwell
	spacing_range = 1

/datum/xeno_build_entry/jelly_pod
	category = "Wells"
	kind = BUILD_KIND_WELL
	path = /obj/structure/xeno/resin_jelly_pod
	ability_type = /datum/action/ability/xeno_action/place_jelly_pod
	icon_file = 'icons/Xeno/actions/hivelord.dmi'
	icon_state = "resin_jelly_pod"

// --- Psychic builds: taken from /datum/hive_upgrade/building. Built while standing on the ghost tile (can_buy/on_buy logic is tied to the builder's tile)
/datum/xeno_build_entry/psychic
	category = "Psychic"
	kind = BUILD_KIND_PSYCHIC
	var/upgrade_name

/datum/xeno_build_entry/psychic/New(datum/hive_upgrade/building/upgrade)
	if(!upgrade)
		return // the type itself is not in the catalog: path is empty
	path = upgrade.building_type
	name = upgrade.name
	desc = upgrade.desc
	icon_state = upgrade.icon
	upgrade_name = upgrade.name
	. = ..()

/datum/xeno_build_entry/psychic/unavailable_reason(mob/living/carbon/xenomorph/X)
	return get_upgrade(X) ? null : "Unavailable in this gamemode"

/datum/xeno_build_entry/psychic/proc/get_upgrade(mob/living/carbon/xenomorph/X)
	return X.hive?.purchases?.upgrades_by_name[upgrade_name]

/datum/xeno_build_entry/psychic/get_action_icon()
	return 'icons/UI_Icons/buyable_icons.dmi'

/datum/xeno_build_entry/psychic/get_radial_image()
	return image('icons/UI_Icons/buyable_icons.dmi', icon_state = icon_state)

/datum/xeno_build_entry/psychic/get_icon_class()
	return "xenobuild32x32 p_[replacetext(icon_state, " ", "_")]"

/datum/xeno_build_entry/psychic/get_state_data(mob/living/carbon/xenomorph/X)
	var/datum/hive_upgrade/building/upgrade = get_upgrade(X)
	var/cost = upgrade ? upgrade.psypoint_cost : 0
	if(istype(upgrade, /datum/hive_upgrade/building/silo))
		var/datum/hive_upgrade/building/silo/silo = upgrade
		cost = silo.get_current_cost()
	return list("cost" = cost, "unit" = "psy", "cooldown" = 0, "ok" = SSpoints.xeno_points_by_hive[X.hivenumber] >= cost)

// ---------------------------------------------------------------------------
// HUD: each hive has its own HUD with ghost images. Visible to hive xenos and observers
// ---------------------------------------------------------------------------
GLOBAL_LIST_EMPTY(xeno_blueprint_huds)

/datum/atom_hud/xeno_blueprint
	hud_icons = list(XENO_BLUEPRINT_HUD)

/proc/get_xeno_blueprint_hud(hivenumber)
	RETURN_TYPE(/datum/atom_hud/xeno_blueprint)
	var/key = "[hivenumber]"
	var/datum/atom_hud/xeno_blueprint/hud = GLOB.xeno_blueprint_huds[key]
	if(!hud)
		hud = new
		GLOB.xeno_blueprint_huds[key] = hud
	return hud

/// Subscribes the xeno to its hive's HUD and unsubscribes from the others. Call after a hive change
/mob/living/carbon/xenomorph/proc/update_blueprint_hud()
	var/own_key = "[hivenumber]"
	for(var/key in GLOB.xeno_blueprint_huds)
		if(key == own_key)
			continue
		var/datum/atom_hud/hud = GLOB.xeno_blueprint_huds[key]
		hud.remove_hud_from(src)
	get_xeno_blueprint_hud(hivenumber).add_hud_to(src)

/mob/living/carbon/xenomorph/proc/clear_blueprint_hud()
	for(var/key in GLOB.xeno_blueprint_huds)
		var/datum/atom_hud/hud = GLOB.xeno_blueprint_huds[key]
		hud.remove_hud_from(src)

// ---------------------------------------------------------------------------
// Ghost
// ---------------------------------------------------------------------------
/obj/effect/xeno_blueprint
	name = "blueprint"
	anchored = TRUE
	alpha = 0 // the object itself renders nothing; the image goes through the hive HUD
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/datum/xeno_build_entry/entry
	var/hivenumber
	var/is_demolish = FALSE
	/// A build from this blueprint gets the auto-rebuild marker
	var/auto_rebuild = FALSE
	/// Blueprint turned into a build: the marker moves to it and is not removed
	var/consumed = FALSE

/obj/effect/xeno_blueprint/Initialize(mapload, datum/xeno_build_entry/_entry, _hivenumber, _demolish = FALSE, _auto_rebuild = FALSE)
	. = ..()
	entry = _entry
	hivenumber = _hivenumber
	is_demolish = _demolish
	auto_rebuild = _auto_rebuild && !_demolish
	LAZYADD(GLOB.xeno_blueprints[hivenumber], src)
	var/image/ghost = build_ghost_image()
	if(!ghost)
		return INITIALIZE_HINT_QDEL
	LAZYINITLIST(hud_list)
	hud_list[XENO_BLUEPRINT_HUD] = ghost
	var/datum/atom_hud/hud = get_xeno_blueprint_hud(hivenumber)
	hud.add_to_hud(src)
	for(var/mob/dead/observer/watcher AS in GLOB.observer_list)
		hud.add_hud_to(watcher)

/// The icon is taken from the type's regular vars rather than appearance: initial(appearance) is empty or unstable for walls and doors.
/obj/effect/xeno_blueprint/proc/build_ghost_image()
	var/ghost_icon
	var/ghost_state
	var/ghost_dir = SOUTH
	if(is_demolish)
		var/atom/target = get_demolish_target(loc)
		if(!target)
			return null
		ghost_icon = target.icon
		ghost_state = target.icon_state
		ghost_dir = target.dir
	else
		var/atom/shown = entry?.path
		if(!shown)
			return null
		ghost_icon = initial(shown.icon)
		ghost_state = initial(shown.icon_state)
		ghost_dir = initial(shown.dir)
		if(!ghost_icon || !ghost_state)
			ghost_icon = entry.icon_file
			ghost_state = entry.icon_state
	var/image/ghost = image(ghost_icon, loc, ghost_state, ABOVE_OBJ_LAYER, ghost_dir)
	ghost.alpha = auto_rebuild ? 200 : 150
	ghost.color = is_demolish ? BP_TINT_DEMOLISH : BP_TINT_GHOST
	ghost.plane = ABOVE_LIGHTING_PLANE // Visible even in darkness.
	ghost.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	return ghost

/obj/effect/xeno_blueprint/Destroy()
	if(auto_rebuild && !consumed)
		clear_auto_rebuild_at(get_turf(src)) // The blueprint was removed manually; there is nothing left to rebuild.
	if(hud_list?[XENO_BLUEPRINT_HUD])
		get_xeno_blueprint_hud(hivenumber).remove_from_hud(src)
		hud_list -= XENO_BLUEPRINT_HUD
	LAZYREMOVE(GLOB.xeno_blueprints[hivenumber], src)
	entry = null
	return ..()

/// Determines which structure the demolition blueprint targets on this tile (wall > door > nest > sticky resin).
/proc/get_demolish_target(turf/T)
	if(!T)
		return null
	if(istype(T, /turf/closed/wall/resin))
		return T
	var/atom/found = locate(/obj/structure/mineral_door/resin) in T
	found ||= locate(/obj/structure/bed/nest) in T
	found ||= locate(/obj/alien/resin/sticky) in T
	return found

/// Demolishes the target. Returns TRUE on success. TODO(verify): resin demolition method; currently uses ScrapeAway/deconstruct.
/proc/demolish_resin_target(atom/target, mob/living/carbon/xenomorph/X)
	if(!target || QDELETED(target))
		return FALSE
	clear_auto_rebuild_at(get_turf(target))
	if(SSresinshaping.should_refund(target, X))
		SSresinshaping.decrement_build_counter(X)
	if(isturf(target))
		var/turf/T = target
		T.ScrapeAway()
		return TRUE
	var/obj/O = target
	O.deconstruct(FALSE)
	return TRUE

/// Capture the state of a tile touched by the construction UI.
/// Paths/coordinates are stored rather than turf references because ChangeTurf replaces turf instances.
/mob/living/carbon/xenomorph/proc/capture_construction_state(turf/T)
	if(!T)
		return null
	var/obj/effect/xeno_blueprint/bp = locate() in T
	var/list/blueprint_state
	if(bp)
		blueprint_state = list("entry" = bp.entry, "is_demolish" = bp.is_demolish, "hivenumber" = bp.hivenumber, "auto" = bp.auto_rebuild)
	var/obj/resin_object
	resin_object = locate(/obj/alien/resin) in T
	resin_object ||= locate(/obj/structure/mineral_door/resin) in T
	resin_object ||= locate(/obj/structure/bed/nest) in T
	resin_object ||= locate(/obj/structure/xeno/acidwell) in T
	resin_object ||= locate(/obj/structure/xeno/resin_jelly_pod) in T
	var/list/saved_baseturfs = islist(T.baseturfs) ? T.baseturfs.Copy() : list(T.baseturfs)
	return list(
		"x" = T.x,
		"y" = T.y,
		"z" = T.z,
		"turf_type" = T.type,
		"baseturfs" = saved_baseturfs,
		"structure_type" = resin_object?.type,
		"structure_dir" = resin_object?.dir,
		"blueprint" = blueprint_state,
	)

/mob/living/carbon/xenomorph/proc/construction_states_equal(list/first, list/second)
	if(!first && !second)
		return TRUE
	if(!first || !second)
		return FALSE
	if(first["turf_type"] != second["turf_type"] || first["structure_type"] != second["structure_type"] || first["structure_dir"] != second["structure_dir"])
		return FALSE
	var/first_bases = first["baseturfs"]
	var/second_bases = second["baseturfs"]
	if(islist(first_bases) != islist(second_bases))
		return FALSE
	if(islist(first_bases))
		if(length(first_bases) != length(second_bases))
			return FALSE
		for(var/i in 1 to length(first_bases))
			if(first_bases[i] != second_bases[i])
				return FALSE
	else if(first_bases != second_bases)
		return FALSE
	var/list/first_blueprint = first["blueprint"]
	var/list/second_blueprint = second["blueprint"]
	if(!first_blueprint && !second_blueprint)
		return TRUE
	if(!first_blueprint || !second_blueprint)
		return FALSE
	return first_blueprint["entry"] == second_blueprint["entry"] && first_blueprint["is_demolish"] == second_blueprint["is_demolish"] && first_blueprint["hivenumber"] == second_blueprint["hivenumber"] && first_blueprint["auto"] == second_blueprint["auto"]

/// Restore a saved tile state, including resin structure and blueprint.
/mob/living/carbon/xenomorph/proc/restore_construction_state(list/state)
	if(!state)
		return FALSE
	var/turf/T = locate(state["x"], state["y"], state["z"])
	if(!T)
		return FALSE
	var/obj/effect/xeno_blueprint/current_blueprint = locate() in T
	if(current_blueprint)
		qdel(current_blueprint)
	var/obj/structure/mineral_door/resin/current_door = locate() in T
	if(current_door)
		qdel(current_door)
	var/obj/structure/bed/nest/current_nest = locate() in T
	if(current_nest)
		qdel(current_nest)
	var/obj/alien/resin/current_resin = locate() in T
	if(current_resin)
		qdel(current_resin)
	var/obj/structure/xeno/acidwell/current_well = locate() in T
	if(current_well)
		qdel(current_well)
	var/obj/structure/xeno/resin_jelly_pod/current_jelly_pod = locate() in T
	if(current_jelly_pod)
		qdel(current_jelly_pod)
	var/turf/saved_turf_type = state["turf_type"]
	var/list/stated_baseturfs = state["baseturfs"]
	var/list/saved_baseturfs = islist(stated_baseturfs) ? stated_baseturfs.Copy() : list(stated_baseturfs)
	var/list/current_baseturfs = islist(T.baseturfs) ? T.baseturfs : list(T.baseturfs)
	var/baseturfs_changed = length(current_baseturfs) != length(saved_baseturfs)
	if(!baseturfs_changed)
		for(var/i in 1 to length(saved_baseturfs))
			if(current_baseturfs[i] != saved_baseturfs[i])
				baseturfs_changed = TRUE
				break
	if(T.type != saved_turf_type || baseturfs_changed)
		T = T.ChangeTurf(saved_turf_type, saved_baseturfs)
	T = locate(state["x"], state["y"], state["z"])
	if(!T)
		return FALSE
	var/obj/saved_structure_type = state["structure_type"]
	if(saved_structure_type == /obj/structure/xeno/acidwell)
		var/obj/structure/xeno/acidwell/restored_well = new saved_structure_type(T, src)
		restored_well?.setDir(state["structure_dir"])
	else if(saved_structure_type == /obj/structure/xeno/resin_jelly_pod)
		var/obj/structure/xeno/resin_jelly_pod/restored_jelly_pod = new saved_structure_type(T, hivenumber)
		restored_jelly_pod?.setDir(state["structure_dir"])
	else if(saved_structure_type)
		var/obj/restored_structure = new saved_structure_type(T)
		if(restored_structure)
			restored_structure.setDir(state["structure_dir"])
	var/list/blueprint_state = state["blueprint"]
	if(blueprint_state)
		var/datum/xeno_build_entry/entry = blueprint_state["entry"]
		var/is_demolish = blueprint_state["is_demolish"]
		if(is_demolish && !get_demolish_target(T))
			return TRUE
		if(!is_demolish && !entry)
			return FALSE
		var/restored_hivenumber = blueprint_state["hivenumber"]
		if(isnull(restored_hivenumber))
			restored_hivenumber = hivenumber
		new /obj/effect/xeno_blueprint(T, entry, restored_hivenumber, is_demolish, blueprint_state["auto"])
	return TRUE

/// One reversible UI construction operation.
/datum/xeno_building_action
	var/list/changes = list()

/datum/xeno_building_action/New(list/_changes)
	. = ..()
	changes = _changes

/datum/xeno_building_action/proc/undo(mob/living/carbon/xenomorph/X)
	if(!X)
		return FALSE
	// Avoid overwriting another builder's later work on any tile in this operation.
	for(var/list/change AS in changes)
		var/turf/T = locate(change["x"], change["y"], change["z"])
		if(!T || !X.construction_states_equal(X.capture_construction_state(T), change["after"]))
			return FALSE
	for(var/i in length(changes) to 1 step -1)
		X.restore_construction_state(changes[i]["before"])
	return TRUE

/datum/xeno_building_action/proc/redo(mob/living/carbon/xenomorph/X)
	if(!X)
		return FALSE
	for(var/list/change AS in changes)
		var/turf/T = locate(change["x"], change["y"], change["z"])
		if(!T || !X.construction_states_equal(X.capture_construction_state(T), change["before"]))
			return FALSE
	for(var/list/change AS in changes)
		X.restore_construction_state(change["after"])
	return TRUE

// ---------------------------------------------------------------------------
// Xenomorph logic
// ---------------------------------------------------------------------------
/// Building range: 1 around the xenomorph, 2 for Hivelords, 4 for the Hivemind.
/mob/living/carbon/xenomorph/proc/get_build_range()
	return max(1, xeno_caste.resin_max_range)

/// Quick-build points belong to player ckeys, so only clients (not AI) build instantly.
/mob/living/carbon/xenomorph/proc/uses_quickbuild(datum/xeno_build_entry/entry)
	return client && xeno_quickbuild_active() && (!entry || entry.kind == BUILD_KIND_RESIN)

/// Quick-building and the Hivemind's eye can place whole patterns.
/mob/living/carbon/xenomorph/proc/can_pattern_build()
	return uses_quickbuild() || (istype(src, /mob/living/carbon/xenomorph/hivemind) && (status_flags & INCORPOREAL))

/// The current and adjacent tiles are always reachable (without a visibility check, which would break construction next to walls and wall demolition).
/mob/living/carbon/xenomorph/proc/in_build_reach(turf/T)
	var/turf/own = get_turf(src)
	if(!own || !T || own.z != T.z)
		return FALSE
	var/dist = get_dist(own, T)
	var/range = get_build_range()
	if(uses_quickbuild())
		return dist <= max(range, QUICKBUILD_BUILD_RANGE)
	if(dist > range)
		return FALSE
	if(dist <= 1)
		return TRUE
	return line_of_sight(own, T, range, TRUE)

/mob/living/carbon/xenomorph/proc/get_blueprint_state(turf/T, datum/xeno_build_entry/entry)
	if(entry.check_turf(T) != NO_ERROR)
		return BP_STATE_BLOCKED
	if(!in_build_reach(T))
		return BP_STATE_GHOST
	return BP_STATE_FREE

/// Places a construction blueprint. An identical blueprint is ignored; a different one replaces it.
/mob/living/carbon/xenomorph/proc/place_blueprint(turf/T, datum/xeno_build_entry/entry, auto_rebuild = FALSE)
	var/reason = entry.unavailable_reason(src)
	if(reason)
		balloon_alert(src, reason)
		return FALSE
	if(length(GLOB.xeno_blueprints[hivenumber]) >= BP_MAX_PER_HIVE)
		balloon_alert(src, "too many blueprints")
		return FALSE
	var/obj/effect/xeno_blueprint/old = locate() in T
	if(old)
		if(!old.is_demolish && old.entry == entry && old.auto_rebuild == auto_rebuild)
			return FALSE
		qdel(old)
	if(get_blueprint_state(T, entry) == BP_STATE_BLOCKED)
		return FALSE
	new /obj/effect/xeno_blueprint(T, entry, hivenumber, FALSE, auto_rebuild)
	return TRUE

/// Places a demolition blueprint. If a blueprint already exists on the tile, it is cancelled.
/mob/living/carbon/xenomorph/proc/place_demolish_blueprint(turf/T)
	var/obj/effect/xeno_blueprint/old = locate() in T
	if(old)
		qdel(old)
		return TRUE
	if(!get_demolish_target(T))
		return FALSE
	new /obj/effect/xeno_blueprint(T, null, hivenumber, TRUE)
	return TRUE

/// Builds or demolishes the structure marked by a blueprint. Runs asynchronously and uses do_after.
/mob/living/carbon/xenomorph/hivemind/try_build_blueprint(obj/effect/xeno_blueprint/bp)
	if(status_flags & INCORPOREAL)
		balloon_alert(src, "blueprints only")
		return FALSE
	return ..()

/mob/living/carbon/xenomorph/proc/try_build_blueprint(obj/effect/xeno_blueprint/bp)
	var/turf/T = get_turf(bp)
	if(QDELETED(bp) || !T || do_actions)
		return FALSE
	if(!in_build_reach(T))
		balloon_alert(src, "too far")
		return FALSE
	if(bp.is_demolish)
		return build_demolish(bp, T)
	var/datum/xeno_build_entry/entry = bp.entry
	var/reason = entry.unavailable_reason(src)
	if(reason)
		balloon_alert(src, reason)
		return FALSE
	if(entry.check_turf(T) != NO_ERROR)
		balloon_alert(src, "blocked")
		return FALSE
	if(entry.kind == BUILD_KIND_PSYCHIC)
		return build_psychic(bp, entry, T)
	return build_standard(bp, entry, T)

/mob/living/carbon/xenomorph/proc/build_demolish(obj/effect/xeno_blueprint/bp, turf/T)
	var/atom/target = get_demolish_target(T)
	if(!target)
		qdel(bp)
		return FALSE
	if(!xeno_quickbuild_active() && !do_after(src, 1 SECONDS, NONE, T, BUSY_ICON_BUILD))
		return FALSE
	if(QDELETED(bp) || target != get_demolish_target(T))
		return FALSE
	qdel(bp)
	return demolish_resin_target(target, src)

/mob/living/carbon/xenomorph/proc/get_blueprint_wait(datum/xeno_build_entry/entry)
	var/datum/action/ability/activable/xeno/secrete_resin/resin = locate() in actions
	var/base = resin ? resin.base_wait : BP_BASE_WAIT
	var/scaling = resin ? resin.scaling_wait : BP_SCALING_WAIT
	. = (base + scaling - max(0, (scaling * health / maxHealth))) * entry.wait_mult
	if(!resin)
		. *= NONBUILDER_WALL_WAIT_MULT

/mob/living/carbon/xenomorph/proc/build_standard(obj/effect/xeno_blueprint/bp, datum/xeno_build_entry/entry, turf/T)
	var/datum/action/ability/ability
	var/cost = 0
	var/quick = uses_quickbuild(entry)
	if(entry.kind == BUILD_KIND_WELL)
		ability = locate(entry.ability_type) in actions
		cost = ability.ability_cost
		if(!ability.action_COOLDOWN_FINISHED())
			balloon_alert(src, "wait [ability.cooldown_remaining()] sec")
			return FALSE
	else
		ability = locate(/datum/action/ability/activable/xeno/secrete_resin) in actions
		cost = ability ? ability.ability_cost / entry.cost_div : NONBUILDER_WALL_COST
		if(SSmonitor.gamestate == SHUTTERS_CLOSED)
			cost *= 0.5
	if(quick)
		if(!SSresinshaping.get_building_points(src))
			balloon_alert(src, "no quick-build points left")
			return FALSE
		for(var/mob/living/carbon/human/H AS in cheap_get_humans_near(T, 10))
			if(H.client && H.stat != DEAD)
				balloon_alert(src, "somebody humanlike is alive nearby!")
				return FALSE
	else
		if(plasma_stored < cost)
			balloon_alert(src, "need [cost] plasma")
			return FALSE
		face_atom(T)
		var/wait = entry.kind == BUILD_KIND_WELL ? 0.5 SECONDS : get_blueprint_wait(entry)
		if(wait > 0 && !do_after(src, wait, NONE, T, BUSY_ICON_BUILD))
			return FALSE
		if(QDELETED(bp) || entry.check_turf(T) != NO_ERROR || plasma_stored < cost)
			return FALSE
	var/rebuild = bp.auto_rebuild
	var/atom/built = spawn_blueprint_structure(entry, T)
	if(!built)
		return FALSE
	bp.consumed = TRUE
	qdel(bp)
	if(rebuild)
		register_auto_rebuild(ispath(entry.path, /turf) ? locate(T.x, T.y, T.z) : built, entry, hivenumber)
	if(quick)
		SSresinshaping.increment_build_counter(src)
		return TRUE
	playsound(T, SFX_ALIEN_RESIN_BUILD, 25)
	if(ability)
		ability.succeed_activate(cost)
		if(entry.kind == BUILD_KIND_WELL)
			ability.add_cooldown()
		else
			ability.add_cooldown(SSmonitor.gamestate == SHUTTERS_CLOSED ? ability.get_cooldown() * 0.5 : ability.get_cooldown())
			var/datum/action/ability/activable/xeno/secrete_resin/resin = ability
			if(resin.heal_percentage)
				var/health_healed = maxHealth * resin.heal_percentage
				HEAL_XENO_DAMAGE(src, health_healed, FALSE)
	else
		use_plasma(cost)
	record_structures_built()
	return TRUE

/mob/living/carbon/xenomorph/proc/spawn_blueprint_structure(datum/xeno_build_entry/entry, turf/T)
	if(ispath(entry.path, /turf))
		var/list/baseturfs = islist(T.baseturfs) ? T.baseturfs : list(T.baseturfs)
		baseturfs |= T.type
		T.ChangeTurf(entry.path, baseturfs)
		return T
	if(entry.path == /obj/structure/xeno/acidwell)
		GLOB.round_statistics.xeno_acid_wells++
		SSblackbox.record_feedback(FEEDBACK_TALLY, "round_statistics", 1, "xeno_acid_wells")
		record_traps_created()
		return new /obj/structure/xeno/acidwell(T, src)
	if(entry.kind == BUILD_KIND_WELL)
		return new entry.path(T, get_xeno_hivenumber())
	return new entry.path(T)

/// Psychic construction: the xenomorph must stand on the blueprint tile; the standard on_buy flow then handles do_after, cost, and messages.
/mob/living/carbon/xenomorph/proc/build_psychic(obj/effect/xeno_blueprint/bp, datum/xeno_build_entry/psychic/entry, turf/T)
	if(get_turf(src) != T)
		balloon_alert(src, "stand on the blueprint")
		return FALSE
	var/datum/hive_upgrade/building/upgrade = entry.get_upgrade(src)
	if(!upgrade?.can_buy(src, FALSE))
		return FALSE
	if(!upgrade.on_buy(src))
		return FALSE
	qdel(bp)
	return TRUE



// ---------------------------------------------------------------------------
// Blueprint clicks
// ---------------------------------------------------------------------------
/// Registered during xenomorph Initialize. Left-clicks with the harm intent pass through.
/mob/living/carbon/xenomorph/proc/blueprint_click(atom/A, params)
	SIGNAL_HANDLER
	var/turf/T = get_turf(A)
	if(!T)
		return
	var/obj/effect/xeno_blueprint/bp = locate() in T
	if(!bp || bp.hivenumber != hivenumber)
		return
	var/list/modifiers = params2list(params)
	if(modifiers[SHIFT_CLICK] || modifiers[CTRL_CLICK] || modifiers[ALT_CLICK] || modifiers[MIDDLE_CLICK])
		return
	if(istype(selected_ability, /datum/action/ability/activable/xeno/secrete_resin)) // The selected ability handles left and right clicks itself.
		return
	if(modifiers[BUTTON] == RIGHT_CLICK)
		qdel(bp)
		return COMSIG_MOB_CLICK_CANCELED
	if(istype(src, /mob/living/carbon/xenomorph/hivemind) && (status_flags & INCORPOREAL))
		return COMSIG_MOB_CLICK_CANCELED // The Hivemind's eye can place/cancel blueprints, never execute them.
	if(a_intent == INTENT_HARM)
		return
	INVOKE_ASYNC(src, PROC_REF(try_build_blueprint), bp)
	return COMSIG_MOB_CLICK_CANCELED


// ---------------------------------------------------------------------------
// Auto-rebuild: when a marked structure is destroyed, a new blueprint is placed at its location (even without weeds).
// ---------------------------------------------------------------------------
GLOBAL_LIST_EMPTY(xeno_rebuild_markers)

/proc/rebuild_marker_key(turf/T)
	return "[T.x],[T.y],[T.z]"

/proc/register_auto_rebuild(atom/built, datum/xeno_build_entry/entry, hivenumber)
	var/turf/T = get_turf(built)
	if(!T || !entry)
		return
	var/key = rebuild_marker_key(T)
	var/datum/xeno_rebuild_marker/old = GLOB.xeno_rebuild_markers[key]
	if(old)
		qdel(old)
	GLOB.xeno_rebuild_markers[key] = new /datum/xeno_rebuild_marker(built, entry, hivenumber)

/proc/clear_auto_rebuild_at(turf/T)
	if(!T)
		return
	var/datum/xeno_rebuild_marker/marker = GLOB.xeno_rebuild_markers[rebuild_marker_key(T)]
	if(marker)
		qdel(marker)

/datum/xeno_rebuild_marker
	var/datum/xeno_build_entry/entry
	var/hivenumber
	var/mx
	var/my
	var/mz
	var/atom/tracked

/datum/xeno_rebuild_marker/New(atom/built, datum/xeno_build_entry/_entry, _hivenumber)
	. = ..()
	entry = _entry
	hivenumber = _hivenumber
	var/turf/T = get_turf(built)
	mx = T.x
	my = T.y
	mz = T.z
	track(built)

/datum/xeno_rebuild_marker/Destroy()
	untrack()
	if(GLOB.xeno_rebuild_markers["[mx],[my],[mz]"] == src)
		GLOB.xeno_rebuild_markers -= "[mx],[my],[mz]"
	entry = null
	return ..()

/datum/xeno_rebuild_marker/proc/track(atom/A)
	untrack()
	tracked = A
	if(isturf(A))
		RegisterSignal(A, COMSIG_TURF_CHANGE, PROC_REF(on_turf_changed))
	else
		RegisterSignal(A, COMSIG_QDELETING, PROC_REF(on_lost))

/datum/xeno_rebuild_marker/proc/untrack()
	if(tracked)
		UnregisterSignal(tracked, list(COMSIG_TURF_CHANGE, COMSIG_QDELETING))
	tracked = null

/datum/xeno_rebuild_marker/proc/on_turf_changed(datum/source, path, list/new_baseturfs, flags)
	SIGNAL_HANDLER
	if(ispath(path, entry.path))
		return
	untrack()
	addtimer(CALLBACK(src, PROC_REF(try_replace)), 1)

/datum/xeno_rebuild_marker/proc/on_lost(datum/source)
	SIGNAL_HANDLER
	untrack()
	addtimer(CALLBACK(src, PROC_REF(try_replace)), 1)

/datum/xeno_rebuild_marker/proc/try_replace()
	if(QDELETED(src))
		return
	var/turf/T = locate(mx, my, mz)
	if(!T || !entry)
		qdel(src)
		return
	var/atom/present = ispath(entry.path, /turf) ? (istype(T, entry.path) ? T : null) : (locate(entry.path) in T)
	if(present)
		track(present)
		return
	if(locate(/obj/effect/xeno_blueprint) in T)
		return
	if(ispath(entry.path, /turf/closed) && T.density) // Something else is already occupying this location.
		qdel(src)
		return
	if(length(GLOB.xeno_blueprints[hivenumber]) >= BP_MAX_PER_HIVE)
		return
	new /obj/effect/xeno_blueprint(T, entry, hivenumber, FALSE, TRUE)
