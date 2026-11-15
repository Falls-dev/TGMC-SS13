// Hivemind RTS mouse input and drag-selection rendering.

/atom/movable/screen/hivemind_rts_drag_box
	name = "RTS selection box"
	icon = 'icons/effects/alphacolors.dmi'
	icon_state = "white"
	plane = ABOVE_HUD_PLANE
	layer = 120
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = APPEARANCE_UI_TRANSFORM //APPEARANCE_UI contains RESET_TRANSFORM and kills the frame scale

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
	var/atom/viewer = client.eye ? client.eye : src
	rts_drag_start_turf = params2turf(modifiers["screen-loc"], get_turf(viewer), client)
	if(!rts_drag_start_turf)
		var/atom/start_target = get_turf_on_clickcatcher(object, src, params)
		if(!start_target)
			start_target = location
		rts_drag_start_turf = get_turf(start_target)
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
	var/turf/end_turf
	if(modifiers["screen-loc"] && client)
		var/atom/viewer = client.eye ? client.eye : src
		end_turf = params2turf(modifiers["screen-loc"], get_turf(viewer), client)
	if(!end_turf)
		var/atom/end_target = get_turf_on_clickcatcher(object, src, params)
		if(!end_target)
			end_target = location
		end_turf = get_turf(end_target)
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

/// Frame: one solid 32x32 sprite per part, size and position set via transform/pixel_x/pixel_y. Icons are not created on the fly
/mob/living/carbon/xenomorph/hivemind/proc/place_rts_box_part(atom/movable/screen/hivemind_rts_drag_box/part, left, bottom, width, height, part_color, part_alpha)
	// LEFT/BOTTOM tracks the actual map-control edge (including client view scaling).
	// The offset places the transformed 32x32 sprite's center on the rectangle part's center.
	part.screen_loc = "LEFT,BOTTOM"
	part.pixel_x = left + width / 2 - 16
	part.pixel_y = bottom + height / 2 - 16
	part.transform = matrix(width / 32, 0, 0, 0, height / 32, 0)
	part.color = part_color
	part.alpha = part_alpha

/mob/living/carbon/xenomorph/hivemind/proc/update_rts_drag_box(start_x, start_y, end_x, end_y)
	if(!client)
		return
	var/min_x = min(start_x, end_x)
	var/min_y = min(start_y, end_y)
	var/box_width = max(1, abs(end_x - start_x) + 1)
	var/box_height = max(1, abs(end_y - start_y) + 1)
	var/rect = "[min_x],[min_y],[box_width],[box_height]"
	if(rect == rts_drag_last_rect && rts_drag_fill)
		return
	rts_drag_last_rect = rect
	var/list/parts = list("rts_drag_fill", "rts_drag_border_top", "rts_drag_border_bottom", "rts_drag_border_left", "rts_drag_border_right")
	for(var/part_name in parts)
		if(!vars[part_name])
			var/atom/movable/screen/hivemind_rts_drag_box/new_part = new(null)
			vars[part_name] = new_part
			client.screen += new_part
	var/left = min_x
	var/bottom = min_y
	place_rts_box_part(rts_drag_fill, left, bottom, box_width, box_height, "#18FF68", 56)
	place_rts_box_part(rts_drag_border_top, left, bottom + box_height - 2, box_width, 2, "#35FF80", 255)
	place_rts_box_part(rts_drag_border_bottom, left, bottom, box_width, 2, "#35FF80", 255)
	place_rts_box_part(rts_drag_border_left, left, bottom, 2, box_height, "#35FF80", 255)
	place_rts_box_part(rts_drag_border_right, left + box_width - 2, bottom, 2, box_height, "#35FF80", 255)

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
	rts_drag_last_rect = null
