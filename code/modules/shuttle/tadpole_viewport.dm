/// Fixed native capture size. Logical zoom changes apparent scale, not terrain
/// capture extent. HUD positions are cached and never parsed on movement ticks.
/atom/movable/screen/background/tadpole_view_bounds
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/datum/tadpole_viewport
	var/client/chief
	var/datum/tadpole_scene_view/owner
	var/active = FALSE
	var/logical_size
	var/render_size
	var/logical_width
	var/logical_height
	var/render_width
	var/render_height
	var/padding_x = 0
	var/padding_y = 0
	var/base_zoom = 0
	var/list/hud_locations = list()
	var/list/location_cache = list()
	var/atom/movable/screen/background/tadpole_view_bounds/frame
	var/datum/plane_master_group/group
	var/original_relay_loc
	var/list/relay_locations = list()

/datum/tadpole_viewport/proc/start(datum/tadpole_scene_view/view, client/display)
	owner = view
	chief = display
	if(chief.tadpole_viewport && chief.tadpole_viewport != src)
		qdel(chief.tadpole_viewport)
	chief.tadpole_viewport = src
	logical_size = chief.view
	base_zoom = chief.view_size?.zoom || 0
	if(QDELETED(src) || QDELETED(view) || !chief || chief.tadpole_viewport != src || chief.mob != view.hud?.mymob || !view.scene?.helm.ground_tiles[get_turf(chief.eye)])
		qdel(src)
		return
	active = TRUE
	frame = new
	chief.screen += frame
	group = owner.hud.get_plane_group(PLANE_GROUP_MAIN)
	original_relay_loc = group.relay_loc
	group.relay_loc = "SCREEN_SOUTHWEST"
	sync_relays()
	chief.change_view(logical_size)

/// Preserve the requested visual zoom while keeping the native input at 25x25.
/datum/tadpole_viewport/proc/configure(view_size)
	if(logical_size == view_size && render_size)
		return render_size
	for(var/atom/movable/thing as anything in hud_locations)
		restore_location(thing)
	hud_locations.Cut()
	logical_size = view_size
	location_cache.Cut()
	var/list/size = getviewsize(view_size)
	logical_width = size[1]
	logical_height = size[2]
	var/bounds_width = max(TADPOLE_CAPTURE_SIZE, logical_width)
	var/bounds_height = max(TADPOLE_CAPTURE_SIZE, logical_height)
	if(!(bounds_width % 2))
		bounds_width++
	if(!(bounds_height % 2))
		bounds_height++
	if(frame)
		var/hx = (bounds_width - 1) / 2
		var/hy = (bounds_height - 1) / 2
		frame.screen_loc = "CENTER-[hx],CENTER-[hy] to CENTER+[hx],CENTER+[hy]"
	padding_x = (TADPOLE_CAPTURE_SIZE - logical_width) / 2
	padding_y = (TADPOLE_CAPTURE_SIZE - logical_height) / 2
	render_width = TADPOLE_CAPTURE_SIZE
	render_height = TADPOLE_CAPTURE_SIZE
	render_size = "[render_width]x[render_height]"
	return render_size

/datum/tadpole_viewport/proc/set_zoom(new_zoom)
	base_zoom = new_zoom
	INVOKE_ASYNC(src, PROC_REF(apply_zoom))

/datum/tadpole_viewport/proc/apply_zoom()
	if(!active || !chief)
		return
	var/zoom = base_zoom
	if(!zoom)
		var/list/control_size = splittext(winget(chief, "mapwindow.map", "size"), "x")
		if(QDELETED(src) || !active || !chief || length(control_size) != 2)
			return
		zoom = base_zoom || min(text2num(control_size[1]) / (logical_width * world.icon_size), text2num(control_size[2]) / (logical_height * world.icon_size))
	if(zoom > 0)
		winset(chief, "mapwindow.map", "zoom=[zoom]")

/// Convert HUD coordinates from the visible grid to its centered padded grid.
/// Plane masters/relays and fullscreen lighting keep the full render grid.
/datum/tadpole_viewport/proc/map_axis(text, axis)
	text = trim(text)
	var/colon = findtext(text, ":")
	var/pixels = colon ? copytext(text, colon) : ""
	var/coordinate = uppertext(colon ? copytext(text, 1, colon) : text)
	for(var/control_anchor in list("LEFT", "RIGHT", "TOP", "BOTTOM", "MIDDLE", "SCREEN_"))
		if(findtext(coordinate, control_anchor) == 1)
			return text
	var/size = axis == 1 ? logical_width : logical_height
	var/padding = axis == 1 ? padding_x : padding_y
	var/value
	for(var/anchor in list("WEST", "EAST", "SOUTH", "NORTH", "CENTER"))
		if(findtext(coordinate, anchor) != 1)
			continue
		var/offset_text = copytext(coordinate, length(anchor) + 1)
		var/offset = length(offset_text) ? text2num(offset_text) : 0
		if(isnull(offset))
			return null
		if(findtext(offset_text, "%"))
			offset = offset * (size - 1) / 100
		value = (anchor == "CENTER" ? (size + 1) / 2 : ((anchor == "EAST" || anchor == "NORTH") ? size : 1)) + offset
		break
	if(isnull(value))
		value = text2num(coordinate)
		if(isnull(value))
			return null
		if(findtext(coordinate, "%"))
			value = 1 + value * (size - 1) / 100
	var/position = value + padding
	var/tile = FLOOR(position, 1)
	var/pixel_offset = (position - tile) * world.icon_size + (pixels ? text2num(copytext(pixels, 2)) : 0)
	return (pixels || pixel_offset) ? "[tile]:[pixel_offset]" : "[tile]"

/datum/tadpole_viewport/proc/map_point(location)
	var/list/shorthand = list("CENTER" = "CENTER,CENTER", "NORTHWEST" = "WEST,NORTH", "NORTHEAST" = "EAST,NORTH", "SOUTHWEST" = "WEST,SOUTH", "SOUTHEAST" = "EAST,SOUTH")
	location = shorthand[uppertext(location)] || location
	var/list/parts = splittext(location, ",")
	if(length(parts) != 2)
		return null
	var/first = uppertext(trim(parts[1]))
	var/second = uppertext(trim(parts[2]))
	if(findtext(first, "NORTH") == 1 || findtext(first, "SOUTH") == 1 || findtext(first, "TOP") == 1 || findtext(first, "BOTTOM") == 1 || findtext(second, "WEST") == 1 || findtext(second, "EAST") == 1 || findtext(second, "LEFT") == 1 || findtext(second, "RIGHT") == 1)
		parts.Swap(1, 2)
	var/x = map_axis(parts[1], 1)
	var/y = map_axis(parts[2], 2)
	if(isnull(x) || isnull(y))
		return null
	return "[x],[y]"

/datum/tadpole_viewport/proc/map_location(location)
	var/cached = location_cache[location]
	if(!isnull(cached))
		return cached
	var/list/parts = splittext(location, " to ")
	var/list/result = list()
	for(var/part in parts)
		var/mapped = map_point(part)
		if(isnull(mapped))
			location_cache[location] = location
			return location
		result += mapped
	var/mapped_location = result.Join(" to ")
	location_cache[location] = mapped_location
	return mapped_location

/datum/tadpole_viewport/proc/sync_relays()
	if(QDELETED(group))
		return
	for(var/key in group.plane_masters)
		var/atom/movable/screen/plane_master/master = group.plane_masters[key]
		for(var/atom/movable/render_plane_relay/relay as anything in master.relays)
			if(!(relay in relay_locations))
				relay_locations[relay] = relay.screen_loc == "SCREEN_SOUTHWEST" ? original_relay_loc : relay.screen_loc
			if(relay.screen_loc != "SCREEN_SOUTHWEST")
				relay.screen_loc = "SCREEN_SOUTHWEST"

/datum/tadpole_viewport/proc/sync_hud()
	if(!active || !chief)
		return
	sync_relays()
	var/list/remaining = hud_locations.Copy()
	for(var/atom/movable/thing as anything in chief.screen)
		if(!thing.screen_loc || thing == frame || thing == chief.void || istype(thing, /atom/movable/screen/plane_master) || istype(thing, /atom/movable/render_plane_relay) || istype(thing, /atom/movable/screen/fullscreen))
			continue
		if(istype(thing, /atom/movable/screen))
			var/atom/movable/screen/screen_thing = thing
			if(screen_thing.assigned_map)
				continue
		var/list/state = hud_locations[thing]
		remaining -= thing
		if(state && thing.screen_loc == state[2])
			continue
		var/original = thing.screen_loc
		var/mapped = map_location(original)
		hud_locations[thing] = list(original, mapped)
		if(thing.screen_loc != mapped)
			thing.screen_loc = mapped
	for(var/atom/movable/thing as anything in remaining)
		restore_location(thing)
		hud_locations -= thing

/datum/tadpole_viewport/proc/restore_location(atom/movable/thing)
	var/list/state = hud_locations[thing]
	if(!QDELETED(thing) && state && thing.screen_loc == state[2])
		thing.screen_loc = state[1]

/datum/tadpole_viewport/Destroy()
	sync_relays()
	for(var/atom/movable/render_plane_relay/relay as anything in relay_locations)
		if(!QDELETED(relay) && relay.screen_loc == "SCREEN_SOUTHWEST")
			relay.screen_loc = relay_locations[relay]
	relay_locations.Cut()
	if(!QDELETED(group) && group.relay_loc == "SCREEN_SOUTHWEST")
		group.relay_loc = original_relay_loc
	group = null
	if(chief)
		chief.screen -= frame
	QDEL_NULL(frame)
	for(var/atom/movable/thing as anything in hud_locations)
		restore_location(thing)
	hud_locations.Cut()
	if(chief?.tadpole_viewport == src)
		chief.tadpole_viewport = null
		if(active)
			active = FALSE
			winset(chief, "mapwindow.map", "zoom=[base_zoom]")
			chief.change_view(logical_size)
	chief = null
	owner = null
	return ..()
