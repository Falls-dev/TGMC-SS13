/datum/hud/new_player/New(mob/owner)
	. = ..()

	if(!owner?.client)
		return

	var/list/buttons = subtypesof(/atom/movable/screen/text/lobby)
	buttons -= /atom/movable/screen/text/lobby/clickable //skip the parent type for clickables

	var/ycoord = 11
	for(var/atom/movable/screen/text/lobby/lobbyscreen as anything in buttons)
		lobbyscreen = new lobbyscreen(owner, src)
		static_inventory += lobbyscreen
		if(istype(lobbyscreen, /atom/movable/screen/text/lobby/infestation_progress))
			// This widget has its own fixed position and must not be placed with the lobby buttons.
			lobbyscreen.screen_loc = "CENTER,TOP"
			continue
		lobbyscreen.set_position(2, ycoord--)
