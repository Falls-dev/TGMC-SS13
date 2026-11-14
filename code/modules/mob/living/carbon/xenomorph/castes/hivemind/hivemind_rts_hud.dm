// Hivemind RTS HUD and screen widgets.

/// Creates a solid white icon with exact pixel dimensions. Do not scale 32x32 UI icons with a pixel-sized matrix.
/proc/hivemind_rts_solid_icon(icon_width, icon_height)
	var/icon/solid_icon = icon('icons/effects/alphacolors.dmi', "white")
	solid_icon.Scale(max(1, round(icon_width)), max(1, round(icon_height)))
	return solid_icon

/// Builds a correctly sized flat-color overlay for RTS HUD cards.
/proc/hivemind_rts_panel_overlay(icon_width, icon_height, overlay_color, overlay_layer, overlay_alpha = 255, offset_x = 0, offset_y = 0)
	var/mutable_appearance/panel = mutable_appearance(icon = hivemind_rts_solid_icon(icon_width, icon_height), icon_state = "white", layer = overlay_layer)
	panel.color = overlay_color
	panel.alpha = overlay_alpha
	panel.pixel_x = offset_x
	panel.pixel_y = offset_y
	panel.appearance_flags = APPEARANCE_UI|RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM
	return panel

/mob/living/carbon/xenomorph/hivemind/proc/update_rts_hud()
	if(!client)
		return
	// Minions are highlighted in-world; only show the five control groups and order controls.
	update_rts_group_hud()

/mob/living/carbon/xenomorph/hivemind/proc/update_rts_group_hud()
	if(!client)
		return
	var/needs_rebuild = length(rts_group_buttons) != HIVEMIND_RTS_GROUP_COUNT + 4
	for(var/atom/movable/screen/screen_object in rts_group_buttons)
		if(QDELETED(screen_object))
			needs_rebuild = TRUE
			break
	if(needs_rebuild)
		for(var/atom/movable/screen/old_button in rts_group_buttons)
			client.screen -= old_button
		QDEL_LIST(rts_group_buttons)
		rts_group_buttons = list()
		for(var/group_idx in 1 to HIVEMIND_RTS_GROUP_COUNT)
			rts_group_buttons += new /atom/movable/screen/hivemind_rts_group_button(null, null, group_idx, src, "CENTER,SOUTH:[HIVEMIND_RTS_GROUP_HUD_Y]")
		var/order_idx = HIVEMIND_RTS_GROUP_COUNT
		for(var/order in list(RTS_ORDER_SELECT_ALL, RTS_ORDER_STOP, RTS_ORDER_CLEAR))
			order_idx++
			rts_group_buttons += new /atom/movable/screen/hivemind_rts_order_button(null, null, order, order_idx, src, "CENTER,SOUTH:[HIVEMIND_RTS_GROUP_HUD_Y]")
		rts_group_buttons += new /atom/movable/screen/hivemind_rts_group_summary(null, null, src, "CENTER,SOUTH:[HIVEMIND_RTS_GROUP_SUMMARY_HUD_Y]")
	for(var/atom/movable/screen/screen_object in rts_group_buttons)
		if(istype(screen_object, /atom/movable/screen/hivemind_rts_group_summary))
			var/atom/movable/screen/hivemind_rts_group_summary/group_summary = screen_object
			group_summary.update_summary()
			if(active_control_group)
				if(!(group_summary in client.screen))
					client.screen += group_summary
			else
				client.screen -= group_summary
			continue
		if(!(screen_object in client.screen))
			client.screen += screen_object
		if(istype(screen_object, /atom/movable/screen/hivemind_rts_group_button))
			var/atom/movable/screen/hivemind_rts_group_button/group_button = screen_object
			group_button.update_button()

/// The normal HUD rebuild replaces client.screen, so restore the RTS controls afterwards.
/mob/living/carbon/xenomorph/hivemind/proc/on_rts_hud_refreshed(datum/source, datum/hud/refreshed_hud)
	SIGNAL_HANDLER
	update_rts_hud()

/mob/living/carbon/xenomorph/hivemind/proc/clear_rts_hud()
	if(client)
		for(var/atom/movable/screen/screen_object in rts_group_buttons)
			client.screen -= screen_object
	QDEL_LIST(rts_group_buttons)
	rts_group_buttons = list()

/atom/movable/screen/hivemind_rts_group_button
	name = "Control Group"
	icon = 'icons/effects/effects.dmi'
	icon_state = "white"
	plane = ABOVE_HUD_PLANE
	layer = 80
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	appearance_flags = APPEARANCE_UI
	var/group_idx = 1
	var/mob/living/carbon/xenomorph/hivemind/hivemind_owner

/atom/movable/screen/hivemind_rts_group_button/Initialize(mapload, datum/hud/hud_owner, group_number, mob/living/carbon/xenomorph/hivemind/H, position)
	. = ..(mapload, hud_owner)
	group_idx = group_number
	hivemind_owner = H
	var/x_offset = group_idx - HIVEMIND_RTS_GROUP_CENTER_INDEX
	var/x_position = x_offset ? "CENTER[x_offset > 0 ? "+" : ""][x_offset]" : "CENTER"
	screen_loc = "[x_position],SOUTH:[HIVEMIND_RTS_GROUP_HUD_Y]"
	pixel_x = 0
	update_button()

/atom/movable/screen/hivemind_rts_group_button/Destroy()
	hivemind_owner = null
	return ..()

/// Every slot remains visible. The selected slot has a bright border; each slot shows a caste portrait and its saved unit count.
/atom/movable/screen/hivemind_rts_group_button/proc/update_button()
	if(!hivemind_owner)
		return
	var/list/group = hivemind_owner.control_groups[group_idx]
	var/count = 0
	var/mob/living/carbon/xenomorph/representative
	for(var/mob/living/carbon/xenomorph/minion in group.Copy())
		if(!hivemind_owner.can_control_minion(minion))
			group -= minion
			continue
		count++
		if(!representative)
			representative = minion
	var/is_active = hivemind_owner.active_control_group == group_idx
	cut_overlays()
	maptext = null
	color = null
	alpha = 255

	// The DMI source is 32x32. Resize the bitmap, not the object transform, to keep the card local.
	add_overlay(hivemind_rts_panel_overlay(HIVEMIND_RTS_GROUP_CARD_WIDTH, HIVEMIND_RTS_GROUP_CARD_HEIGHT, is_active ? "#43FF86" : "#718078", 82))
	add_overlay(hivemind_rts_panel_overlay(HIVEMIND_RTS_GROUP_CARD_WIDTH - 4, HIVEMIND_RTS_GROUP_CARD_HEIGHT - 4, "#111A15", 83, 250, 2, 2))

	if(representative)
		var/mutable_appearance/portrait = new /mutable_appearance(representative)
		portrait.layer = 84
		portrait.plane = ABOVE_HUD_PLANE
		portrait.appearance_flags = APPEARANCE_UI|RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM
		var/matrix/portrait_transform = matrix()
		portrait_transform.Scale(0.68, 0.68)
		portrait_transform.Translate(5, 7)
		portrait.transform = portrait_transform
		add_overlay(portrait)

	add_overlay(hivemind_rts_panel_overlay(HIVEMIND_RTS_GROUP_CARD_WIDTH - 4, 9, "#07100B", 85, 235, 2, 2))

	var/mutable_appearance/index_label = mutable_appearance(icon = null, icon_state = null, layer = 86)
	index_label.appearance_flags = APPEARANCE_UI|RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM
	index_label.maptext = "<span style='font-size:8pt;font-weight:bold;color:#FFFFFF;-dm-text-outline:1px black;'>[group_idx]</span>"
	index_label.maptext_x = 2
	index_label.maptext_y = 21
	index_label.maptext_width = 10
	index_label.maptext_height = 10
	add_overlay(index_label)

	var/mutable_appearance/count_label = mutable_appearance(icon = null, icon_state = null, layer = 90)
	count_label.appearance_flags = APPEARANCE_UI|RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM
	count_label.maptext = "<div style='text-align:center;font-size:8pt;font-weight:bold;color:#FFFFFF;-dm-text-outline:1px black;'>[count]</div>"
	count_label.maptext_x = 0
	count_label.maptext_y = 1
	count_label.maptext_width = HIVEMIND_RTS_GROUP_CARD_WIDTH
	count_label.maptext_height = 10
	add_overlay(count_label)
	name = "Отряд [group_idx]: [count] миньонов ([is_active ? "активный" : "не выбран"]); ЛКМ - выбрать, ПКМ - выбрать и перейти, Ctrl - сохранить, Shift - добавить"

/atom/movable/screen/hivemind_rts_group_button/Click(location, control, params)
	if(!hivemind_owner)
		return
	var/list/modifiers = params2list(params)
	if(modifiers["right"])
		hivemind_owner.select_control_group(group_idx, TRUE)
	else if(modifiers["ctrl"])
		hivemind_owner.assign_control_group(group_idx)
	else if(modifiers["shift"])
		hivemind_owner.add_to_control_group(group_idx)
	else
		hivemind_owner.select_control_group(group_idx)

/// Small composition card placed directly beneath the currently active control group.
/atom/movable/screen/hivemind_rts_group_summary
	name = "Active group composition"
	icon = null
	icon_state = ""
	plane = ABOVE_HUD_PLANE
	layer = 90
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = APPEARANCE_UI
	var/mob/living/carbon/xenomorph/hivemind/hivemind_owner

/atom/movable/screen/hivemind_rts_group_summary/Initialize(mapload, datum/hud/hud_owner, mob/living/carbon/xenomorph/hivemind/H, position)
	. = ..(mapload, hud_owner)
	hivemind_owner = H
	update_summary()

/atom/movable/screen/hivemind_rts_group_summary/Destroy()
	hivemind_owner = null
	return ..()

/atom/movable/screen/hivemind_rts_group_summary/proc/update_summary()
	if(!hivemind_owner || !hivemind_owner.active_control_group)
		return
	var/group_idx = hivemind_owner.active_control_group
	var/x_offset = group_idx - HIVEMIND_RTS_GROUP_CENTER_INDEX
	var/x_position = x_offset ? "CENTER[x_offset > 0 ? "+" : ""][x_offset]" : "CENTER"
	screen_loc = "[x_position],SOUTH:[HIVEMIND_RTS_GROUP_SUMMARY_HUD_Y]"
	var/list/group = hivemind_owner.control_groups[group_idx]
	var/count = 0
	var/mob/living/carbon/xenomorph/representative
	for(var/mob/living/carbon/xenomorph/minion in group.Copy())
		if(!hivemind_owner.can_control_minion(minion))
			group -= minion
			continue
		count++
		if(!representative)
			representative = minion
	cut_overlays()
	add_overlay(hivemind_rts_panel_overlay(HIVEMIND_RTS_GROUP_CARD_WIDTH, HIVEMIND_RTS_GROUP_CARD_HEIGHT - 10, "#39FF83", 91))
	add_overlay(hivemind_rts_panel_overlay(HIVEMIND_RTS_GROUP_CARD_WIDTH - 4, HIVEMIND_RTS_GROUP_CARD_HEIGHT - 14, "#111A15", 92, 250, 2, 2))
	if(representative)
		var/mutable_appearance/portrait = new /mutable_appearance(representative)
		portrait.layer = 93
		portrait.plane = ABOVE_HUD_PLANE
		portrait.appearance_flags = APPEARANCE_UI|RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM
		var/matrix/portrait_transform = matrix()
		portrait_transform.Scale(0.48, 0.48)
		portrait_transform.Translate(2, 3)
		portrait.transform = portrait_transform
		add_overlay(portrait)
	var/mutable_appearance/group_label = mutable_appearance(icon = null, icon_state = null, layer = 94)
	group_label.appearance_flags = APPEARANCE_UI|RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM
	group_label.maptext = "<div style='font-size:7pt;font-weight:bold;color:#FFFFFF;-dm-text-outline:1px black;'>G[group_idx]</div>"
	group_label.maptext_x = 17
	group_label.maptext_y = 11
	group_label.maptext_width = 15
	group_label.maptext_height = 9
	add_overlay(group_label)
	var/mutable_appearance/count_label = mutable_appearance(icon = null, icon_state = null, layer = 96)
	count_label.appearance_flags = APPEARANCE_UI|RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM
	count_label.maptext = "<div style='font-size:10pt;font-weight:bold;color:#FFFFFF;-dm-text-outline:1px black;'>[count]</div>"
	count_label.maptext_x = 18
	count_label.maptext_y = 1
	count_label.maptext_width = 13
	count_label.maptext_height = 13
	add_overlay(count_label)
	name = "Состав отряда [group_idx]: [count] миньонов"

/// Order buttons next to the group row: select all in view, stop, clear selection.
/atom/movable/screen/hivemind_rts_order_button
	name = "Order"
	icon = 'icons/Xeno/actions/general.dmi'
	icon_state = "rally_minions"
	plane = ABOVE_HUD_PLANE
	layer = 80
	mouse_opacity = MOUSE_OPACITY_ICON
	appearance_flags = APPEARANCE_UI
	var/order
	var/mob/living/carbon/xenomorph/hivemind/hivemind_owner

/atom/movable/screen/hivemind_rts_order_button/Initialize(mapload, datum/hud/hud_owner, order_type, slot, mob/living/carbon/xenomorph/hivemind/H, position)
	. = ..(mapload, hud_owner)
	order = order_type
	hivemind_owner = H
	var/x_offset = slot - HIVEMIND_RTS_GROUP_CENTER_INDEX
	var/x_position = x_offset ? "CENTER[x_offset > 0 ? "+" : ""][x_offset]" : "CENTER"
	screen_loc = "[x_position],SOUTH:[HIVEMIND_RTS_GROUP_HUD_Y]"
	pixel_x = 0
	switch(order)
		if(RTS_ORDER_SELECT_ALL)
			name = "Выбрать всех миньонов в поле зрения"
			icon_state = "rally_minions"
		if(RTS_ORDER_STOP)
			name = "Стоп (выбранные, иначе все в поле зрения)"
			icon_state = "minion_passive"
		if(RTS_ORDER_CLEAR)
			name = "Снять выделение"
			icon_state = "minion_agressive"

/atom/movable/screen/hivemind_rts_order_button/Destroy()
	hivemind_owner = null
	return ..()

/atom/movable/screen/hivemind_rts_order_button/Click(location, control, params)
	if(!hivemind_owner)
		return
	switch(order)
		if(RTS_ORDER_SELECT_ALL)
			hivemind_owner.select_all_in_view()
		if(RTS_ORDER_STOP)
			hivemind_owner.stop_selected_or_visible()
		if(RTS_ORDER_CLEAR)
			hivemind_owner.clear_minion_selection()
