// Xeno construction patterns. Rows go bottom to top, X = cell, O = empty. Offsets center the pattern on the cursor.

GLOBAL_LIST_EMPTY(xeno_build_patterns)

/// Lazy init, id => pattern singleton. Order = order in UI.
/proc/get_xeno_build_patterns()
	if(length(GLOB.xeno_build_patterns))
		return GLOB.xeno_build_patterns
	for(var/type in subtypesof(/datum/buildingpattern))
		var/datum/buildingpattern/pattern = new type
		GLOB.xeno_build_patterns[pattern.id] = pattern
	return GLOB.xeno_build_patterns

/datum/buildingpattern
	var/id
	var/name
	var/list/pattern
	var/offset_x
	var/offset_y
	/// Shown overhead when selected
	var/overheadmsg

/datum/buildingpattern/New()
	. = ..()
	if(!pattern)
		return
	if(isnull(offset_x))
		offset_x = (length(pattern[1]) - 1) >> 1
	if(isnull(offset_y))
		offset_y = -((length(pattern) - 1) >> 1)

/// Size and cells for TGUI rendering
/datum/buildingpattern/proc/get_ui_data()
	return list("id" = id, "name" = name, "grid" = pattern)

/datum/buildingpattern/single
	id = "single"
	name = "Single"
	overheadmsg = "Single tile"
	pattern = list("X")

/datum/buildingpattern/square2x2
	id = "square2x2"
	name = "Cube 2x2"
	overheadmsg = "2 by 2 Square"
	pattern = list(
		"XX",
		"XX",
	)

/datum/buildingpattern/square3x3
	id = "square3x3"
	name = "Cube 3x3"
	overheadmsg = "3 by 3 Square"
	pattern = list(
		"XXX",
		"XXX",
		"XXX",
	)

/datum/buildingpattern/square5x5
	id = "square5x5"
	name = "Cube 5x5"
	overheadmsg = "5 by 5 Square"
	pattern = list(
		"XXXXX",
		"XXXXX",
		"XXXXX",
		"XXXXX",
		"XXXXX",
	)

/datum/buildingpattern/cross3x3
	id = "cross3x3"
	name = "Cross"
	overheadmsg = "3 by 3 Cross (+)"
	pattern = list(
		"OXO",
		"XXX",
		"OXO",
	)

/datum/buildingpattern/hollow_cross3x3
	id = "hollow_cross3x3"
	name = "Hollow cross"
	overheadmsg = "3 by 3 Hollow Cross (+)"
	pattern = list(
		"OXO",
		"XOX",
		"OXO",
	)

/datum/buildingpattern/star5x5
	id = "star5x5"
	name = "Star"
	overheadmsg = "5 by 5 Star"
	pattern = list(
		"XOXOX",
		"OXXXO",
		"XXXXX",
		"OXXXO",
		"XOXOX",
	)
