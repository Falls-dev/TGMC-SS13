// Hivemind RTS mouse input and drag-selection rendering.

/atom/movable/screen/hivemind_rts_drag_box
	name = "RTS selection box"
	icon = 'icons/effects/alphacolors.dmi'
	icon_state = "white"
	plane = ABOVE_HUD_PLANE
	layer = 120
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = APPEARANCE_UI

/mob/living/carbon/xenomorph/hivemind/proc/on_rts_mousedown(mob/source, atom/object, turf/location, control, params)
	SIGNAL_HANDLER
	if(!client || !rts_mode_active)
		return
	var/list/modifiers = params2list(params)
	if(modifiers[BUTTON] != LEFT_CLICK || modifiers["right"] || modifiers["middle"])
		return
	// HUD elements must keep their own clicks; the map click-catcher is selectable.
	if(istype(object, /atom/movable/screen) && !istype(object, /atom/movable/screen/click_catcher))
		return
	if(!modifiers["screen-loc"])
		return
	var/list/start_coords = params2screenpixel(modifiers["screen-loc"])
	if(!start_coords || !length(start_coords))
		return
	rts_drag_start_screen_x = start_coords[1]
	rts_drag_start_screen_y = start_coords[2]
	var/atom/start_target = get_turf_on_clickcatcher(object, src, params)
	if(!start_target)
		start_target = location
	rts_drag_start_turf = get_turf(start_target)
	if(!rts_drag_start_turf && modifiers["screen-loc"])
		var/atom/viewer = client.eye ? client.eye : src
		rts_drag_start_turf = params2turf(modifiers["screen-loc"], get_turf(viewer), client)
	rts_drag_active = FALSE
	rts_drag_additive = !!modifiers["shift"]
	// Show a small visible preview immediately; plain clicks remove it on MouseUp.
	update_rts_drag_box(rts_drag_start_screen_x, rts_drag_start_screen_y, rts_drag_start_screen_x + 2, rts_drag_start_screen_y + 2)

/// Mark a drag only after the cursor has moved far enough to distinguish it from a click.
/mob/living/carbon/xenomorph/hivemind/proc/on_rts_mousedrag(mob/source, atom/src_object, atom/over_object, turf/src_location, turf/over_location, src_control, over_control, params)
	SIGNAL_HANDLER
	if(!client || !rts_mode_active || !rts_drag_start_turf)
		return
	var/list/modifiers = params2list(params)
	if(!modifiers["screen-loc"])
		return
	var/list/current_coords = params2screenpixel(modifiers["screen-loc"])
	if(!current_coords || !length(current_coords))
		return
	if(!rts_drag_active && abs(current_coords[1] - rts_drag_start_screen_x) < 6 && abs(current_coords[2] - rts_drag_start_screen_y) < 6)
		return
	rts_drag_active = TRUE
	update_rts_drag_box(rts_drag_start_screen_x, rts_drag_start_screen_y, current_coords[1], current_coords[2])

/// Box select only; plain clicks are handled in ClickOn.
/mob/living/carbon/xenomorph/hivemind/proc/on_rts_mouseup(mob/source, atom/object, turf/location, control, params)
	SIGNAL_HANDLER
	if(!rts_mode_active || !rts_drag_active || !rts_drag_start_turf)
		clear_rts_drag_state()
		return
	var/list/modifiers = params2list(params)
	var/atom/end_target = get_turf_on_clickcatcher(object, src, params)
	if(!end_target)
		end_target = location
	var/turf/end_turf = get_turf(end_target)
	if(!end_turf && modifiers["screen-loc"] && client)
		var/atom/viewer = client.eye ? client.eye : src
		end_turf = params2turf(modifiers["screen-loc"], get_turf(viewer), client)
	var/turf/start_turf = rts_drag_start_turf
	var/additive = rts_drag_additive || !!modifiers["shift"]
	clear_rts_drag_state()
	if(client)
		client.click_intercepted = world.time
	if(!start_turf || !end_turf || end_turf.z != start_turf.z)
		return COMSIG_MOB_CLICK_CANCELED
	if(!additive)
		clear_minion_selection()
	for(var/turf/T in block(locate(min(start_turf.x, end_turf.x), min(start_turf.y, end_turf.y), start_turf.z), locate(max(start_turf.x, end_turf.x), max(start_turf.y, end_turf.y), start_turf.z)))
		for(var/mob/living/carbon/xenomorph/minion in T)
			if(can_control_minion(minion))
				select_minion(minion, FALSE)
	return COMSIG_MOB_CLICK_CANCELED

/mob/living/carbon/xenomorph/hivemind/proc/rts_pixel_to_screen_loc(pixel_x, pixel_y)
	var/x_tile = FLOOR((pixel_x - 1) / 32, 1) + 1
	var/y_tile = FLOOR((pixel_y - 1) / 32, 1) + 1
	var/x_offset = ((pixel_x - 1) % 32) + 1
	var/y_offset = ((pixel_y - 1) % 32) + 1
	return "[x_tile]:[x_offset],[y_tile]:[y_offset]"

/mob/living/carbon/xenomorph/hivemind/proc/update_rts_drag_box(start_x, start_y, end_x, end_y)
	if(!client)
		return
	var/min_x = min(start_x, end_x)
	var/max_x = max(start_x, end_x)
	var/min_y = min(start_y, end_y)
	var/max_y = max(start_y, end_y)
	var/box_width = max(1, max_x - min_x + 1)
	var/box_height = max(1, max_y - min_y + 1)
	var/base_screen_loc = rts_pixel_to_screen_loc(min_x, min_y)

	if(!rts_drag_fill)
		rts_drag_fill = new /atom/movable/screen/hivemind_rts_drag_box(null)
		client.screen += rts_drag_fill
	if(!rts_drag_border_top)
		rts_drag_border_top = new /atom/movable/screen/hivemind_rts_drag_box(null)
		client.screen += rts_drag_border_top
	if(!rts_drag_border_bottom)
		rts_drag_border_bottom = new /atom/movable/screen/hivemind_rts_drag_box(null)
		client.screen += rts_drag_border_bottom
	if(!rts_drag_border_left)
		rts_drag_border_left = new /atom/movable/screen/hivemind_rts_drag_box(null)
		client.screen += rts_drag_border_left
	if(!rts_drag_border_right)
		rts_drag_border_right = new /atom/movable/screen/hivemind_rts_drag_box(null)
		client.screen += rts_drag_border_right

	// Scale the bitmap itself to the target pixel size. Matrix scaling a 32x32 DMI state
	// by a screen-pixel width expands it by another factor of 32 and covers the viewport.
	rts_drag_fill.icon = hivemind_rts_solid_icon(box_width, box_height)
	rts_drag_fill.icon_state = "white"
	rts_drag_fill.color = "#18FF68"
	rts_drag_fill.alpha = 56
	rts_drag_fill.screen_loc = base_screen_loc
	rts_drag_fill.pixel_x = 0
	rts_drag_fill.pixel_y = 0
	rts_drag_fill.transform = null

	rts_drag_border_top.icon = hivemind_rts_solid_icon(box_width, 2)
	rts_drag_border_top.icon_state = "white"
	rts_drag_border_top.color = "#35FF80"
	rts_drag_border_top.alpha = 255
	rts_drag_border_top.screen_loc = base_screen_loc
	rts_drag_border_top.pixel_x = 0
	rts_drag_border_top.pixel_y = box_height - 2
	rts_drag_border_top.transform = null

	rts_drag_border_bottom.icon = hivemind_rts_solid_icon(box_width, 2)
	rts_drag_border_bottom.icon_state = "white"
	rts_drag_border_bottom.color = "#35FF80"
	rts_drag_border_bottom.alpha = 255
	rts_drag_border_bottom.screen_loc = base_screen_loc
	rts_drag_border_bottom.pixel_x = 0
	rts_drag_border_bottom.pixel_y = 0
	rts_drag_border_bottom.transform = null

	rts_drag_border_left.icon = hivemind_rts_solid_icon(2, box_height)
	rts_drag_border_left.icon_state = "white"
	rts_drag_border_left.color = "#35FF80"
	rts_drag_border_left.alpha = 255
	rts_drag_border_left.screen_loc = base_screen_loc
	rts_drag_border_left.pixel_x = 0
	rts_drag_border_left.pixel_y = 0
	rts_drag_border_left.transform = null

	rts_drag_border_right.icon = hivemind_rts_solid_icon(2, box_height)
	rts_drag_border_right.icon_state = "white"
	rts_drag_border_right.color = "#35FF80"
	rts_drag_border_right.alpha = 255
	rts_drag_border_right.screen_loc = base_screen_loc
	rts_drag_border_right.pixel_x = box_width - 2
	rts_drag_border_right.pixel_y = 0
	rts_drag_border_right.transform = null

/mob/living/carbon/xenomorph/hivemind/proc/clear_rts_drag_state()
	if(client)
		for(var/atom/movable/screen/hivemind_rts_drag_box/box_part in list(rts_drag_fill, rts_drag_border_top, rts_drag_border_bottom, rts_drag_border_left, rts_drag_border_right))
			if(box_part)
				client.screen -= box_part
	QDEL_NULL(rts_drag_fill)
	QDEL_NULL(rts_drag_border_top)
	QDEL_NULL(rts_drag_border_bottom)
	QDEL_NULL(rts_drag_border_left)
	QDEL_NULL(rts_drag_border_right)
	rts_drag_start_turf = null
	rts_drag_start_screen_x = 0
	rts_drag_start_screen_y = 0
	rts_drag_active = FALSE
	rts_drag_additive = FALSE
