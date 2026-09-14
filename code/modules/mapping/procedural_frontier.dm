/*
	* Procedural Frontier
	*
	* A single all-cave map generated from a landmark. The generator is arranged
	* as independent stages so terrain, landmarks, or landing-zone rules can be
	* replaced without rewriting the complete generation pass.
	*/

/area/procedural_frontier
	name = "Frontier Caves"
	icon_state = "red"
	ceiling = CEILING_DEEP_UNDERGROUND
	outside = FALSE
	always_unpowered = TRUE
	minimap_color = MINIMAP_AREA_CAVES

/area/procedural_frontier/landing
	name = "Landing Zone"
	icon_state = "green"
	outside = FALSE
	always_unpowered = FALSE
	minimap_color = MINIMAP_AREA_LZ

/area/procedural_frontier/landing/lz1
	name = "Landing Zone One"
	icon_state = "away1"
	outside = FALSE
	ceiling = CEILING_NONE
	always_unpowered = FALSE
	area_flags = NONE

// Directional cave sectors are represented by one runtime area type. Instances
// are split by direction, depth band, and ceiling value during generation.
/area/procedural_frontier/sector
	name = "Frontier Caves"
	icon_state = "red"
	outside = FALSE
	always_unpowered = TRUE
	minimap_color = MINIMAP_AREA_CAVES

/area/procedural_frontier/generator_room
	name = "Geothermal Generator Room"
	icon_state = "away1"
	ceiling = CEILING_UNDERGROUND_METAL
	outside = FALSE
	always_unpowered = FALSE
	minimap_color = rgb(120, 120, 120)

// All coordinates derived for one map-generation run.
/datum/procedural_frontier_layout
	var/z_level
	var/map_min_x
	var/map_max_x
	var/map_min_y
	var/map_max_y
	var/map_center_x
	var/map_center_y
	var/landing_min_x
	var/landing_max_x
	var/landing_min_y
	var/landing_max_y
	var/landing_center_x
	var/landing_center_y
	var/pad_min_x
	var/pad_max_x
	var/pad_min_y
	var/pad_max_y
	var/max_landing_distance
	var/landing_edge_factor
	var/landing_exit_direction
	var/generator_room_min_x
	var/generator_room_max_x
	var/generator_room_min_y
	var/generator_room_max_y

/datum/procedural_frontier_layout/proc/is_border(x, y)
	return x == map_min_x || x == map_max_x || y == map_min_y || y == map_max_y

/datum/procedural_frontier_layout/proc/is_landing(x, y)
	return x >= landing_min_x && x <= landing_max_x && y >= landing_min_y && y <= landing_max_y

/datum/procedural_frontier_layout/proc/is_landing_border(x, y)
	return is_landing(x, y) && (x == landing_min_x || x == landing_max_x || y == landing_min_y || y == landing_max_y)

/datum/procedural_frontier_layout/proc/is_generator_room(x, y)
	return generator_room_min_x && x >= generator_room_min_x && x <= generator_room_max_x && y >= generator_room_min_y && y <= generator_room_max_y

/datum/procedural_frontier_layout/proc/is_pad(x, y)
	return x >= pad_min_x && x <= pad_max_x && y >= pad_min_y && y <= pad_max_y

/datum/procedural_frontier_layout/proc/get_landing_center()
	return locate(landing_center_x, landing_center_y, z_level)

// Deterministic value noise helpers. Keep these global for use by future map
// features (for example ore veins or a distinct cave-biome pass).
/proc/procedural_frontier_hash(x, y, seed)
	var/value = sin((x * 12.9898) + (y * 78.233) + (seed * 0.001)) * 43758.5453
	return value - floor(value)

/proc/procedural_frontier_fade(value)
	return value * value * value * (value * (value * 6 - 15) + 10)

/proc/procedural_frontier_value_noise(x, y, seed, grid_scale)
	var/grid_x = floor(x / grid_scale)
	var/grid_y = floor(y / grid_scale)
	var/fraction_x = (x / grid_scale) - grid_x
	var/fraction_y = (y / grid_scale) - grid_y
	var/smooth_x = procedural_frontier_fade(fraction_x)
	var/smooth_y = procedural_frontier_fade(fraction_y)
	var/noise_bottom_left = procedural_frontier_hash(grid_x, grid_y, seed)
	var/noise_bottom_right = procedural_frontier_hash(grid_x + 1, grid_y, seed)
	var/noise_top_left = procedural_frontier_hash(grid_x, grid_y + 1, seed)
	var/noise_top_right = procedural_frontier_hash(grid_x + 1, grid_y + 1, seed)
	var/low_edge = noise_bottom_left + (noise_bottom_right - noise_bottom_left) * smooth_x
	var/high_edge = noise_top_left + (noise_top_right - noise_top_left) * smooth_x
	return low_edge + (high_edge - low_edge) * smooth_y

/proc/procedural_frontier_noise(x, y, seed, coarse_scale = 16, fine_scale = 5, coarse_weight = 0.70)
	var/coarse_noise = procedural_frontier_value_noise(x, y, seed, coarse_scale)
	var/fine_noise = procedural_frontier_value_noise(x, y, seed + 31, fine_scale)
	return coarse_noise * coarse_weight + fine_noise * (1 - coarse_weight)

/proc/procedural_frontier_ridge_noise(x, y, seed, coarse_scale = 16, fine_scale = 5, coarse_weight = 0.70)
	var/value = procedural_frontier_noise(x, y, seed, coarse_scale, fine_scale, coarse_weight)
	return 1 - abs((value * 2) - 1)

// Normalized exponential ease-out: 0 at the landing, 1 at the farthest edge.
/proc/procedural_frontier_landing_threshold(distance, max_distance, exponential_rate)
	if(max_distance <= 0)
		return 1
	var/normalized_distance = clamp(distance / max_distance, 0, 1)
	var/rate = max(0.01, exponential_rate)
	var/normalizer = 1 - (2 ** (-rate))
	if(!normalizer)
		return normalized_distance
	return clamp((1 - (2 ** (-rate * normalized_distance))) / normalizer, 0, 1)

/obj/effect/landmark/procedural_frontier_generator
	name = "Procedural Frontier generator"
	icon_state = "x2"

	// Map dimensions must match the authored .dmm shell.
	var/map_width = 199
	var/map_height = 199

	// Landing zone geometry and placement.
	var/landing_width = 30
	var/landing_height = 40
	var/landing_edge_margin = 8
	var/landing_edge_bias = 4
	var/landing_exit_length = 18
	var/pad_width = 11
	var/pad_height = 21

	// Cave-density profile. The LZ surface is always open; farther away, the
	// ridge cutoff rises according to the exponential gradient.
	var/landing_surface_radius = 24
	var/landing_edge_opening = 4.0
	var/ceiling_distance_rate = 0.35
	// The gradient is evaluated over an extended range and clamped to the
	// actual CEILING constants afterwards. A negative lower bound deliberately
	// makes the central CEILING_NONE band wider than the other levels.
	var/ceiling_gradient_min = -1
	var/ceiling_gradient_max = CEILING_DEEP_UNDERGROUND_METAL
	var/remote_cave_cutoff = 0.82
	var/cave_ridge_threshold = 0.0
	var/central_landing_complexity = 0.18
	// A hard ridge check selects solid material eligible for deep walls. The
	// separate wall-distance test below ensures these are not cave boundaries.
	var/hard_ridge_cutoff = 0.35
	var/deep_wall_separation = 2
	// Terrain type paths are configurable so a new Frontier biome can replace
	// materials without changing the generation routines below.
	var/open_turf_type = /turf/open
	var/cave_wall_type = /turf/closed/mineral/smooth/bigred
	var/deep_cave_wall_type = /turf/closed/mineral/smooth/bigred/indestructible
	var/reinforced_wall_type = /turf/closed/wall/r_wall
	var/gold_wall_type = /turf/closed/wall/mineral/gold
	var/plating_floor_type = /turf/open/floor/plating
	var/asteroid_floor_type = /turf/open/floor/asteroidfloor
	var/cave_floor_type = /turf/open/floor/plating/ground/mars/random/cave
	var/wood_floor_type = /turf/open/floor/wood
	var/mainship_gray_floor_type = /turf/open/floor/mainship/metal/gray
	var/toilet_floor_type = /turf/open/floor/prison/darkyellow/full

	// Noise settings. Expose both layers to make biome-specific generators easy.
	var/noise_coarse_scale = 16
	var/noise_fine_scale = 5
	var/noise_coarse_weight = 0.70

	// Landmark placement settings.
	var/weed_node_spacing = 5
	var/tunnel_edge_offset = 10
	var/tunnel_minimum_spacing = 24
	var/miner_phoron_count = 8
	var/miner_phoron_radius = 48
	var/miner_platinum_count = 16
	var/miner_minimum_spacing = 10
	var/supply_room_width = 6
	var/supply_room_height = 6
	var/medical_room_width = 6
	var/medical_room_height = 6
	var/engineering_room_width = 6
	var/engineering_room_height = 6
	var/weapon_room_width = 6
	var/weapon_room_height = 6
	var/toilet_room_width = 6
	var/toilet_room_height = 6
	var/toilet_room_chance = 1
	var/lz_barrel_count = 4
	var/lz_supplycrate_count = 3
	var/xenomorph_spawn_count = 3
	var/excavation_site_count = 20
	// The ground telecomms relay is intentionally sealed inside this square of
	// indestructible deep rock; it is not intended to be physically reachable.
	var/telecomms_relay_wall_radius = 1
	// Selected biome preset is applied once per generation using the round seed.
	var/selected_biome_name = ""
	var/selected_weather_trait
	// Central geothermal room. It is carved after cave reachability is known,
	// then linked back to the live cave network through two opposite entrances.
	var/generator_room_width = 12
	var/generator_room_height = 9

/obj/effect/landmark/procedural_frontier_generator/Initialize(mapload)
	. = ..()
	if(!mapload)
		return
	generate()
	return INITIALIZE_HINT_QDEL

/obj/effect/landmark/procedural_frontier_generator/proc/generate()
	var/seed = Master.random_seed
	var/datum/procedural_frontier_layout/layout = create_layout(seed)
	if(!layout)
		return
	select_biome_preset(seed)
	var/area/cave_area = new /area/procedural_frontier
	var/area/landing_area = new /area/procedural_frontier/landing/lz1
	var/area/generator_area = new /area/procedural_frontier/generator_room
	var/area/relay_area = new /area/storage/testroom

	generate_terrain(layout, cave_area, landing_area, seed)
	carve_landing_exit(layout, cave_area, landing_area)
	place_landing_docking_port(layout)
	place_supply_room(layout, landing_area, seed)
	place_medical_room(layout, landing_area, seed)
	place_engineering_room(layout, landing_area, seed)
	place_weapon_room(layout, landing_area, seed)
	if(prob(toilet_room_chance))
		place_toilet_room(layout, landing_area, seed)
	place_landing_equipment(layout, landing_area)
	place_landing_random_props(layout)
	place_deep_walls(layout, cave_area, seed)
	var/list/open_cave_tiles = retain_reachable_cave_tiles(layout, cave_area, landing_area)
	place_generator_room(layout, generator_area, cave_area, open_cave_tiles, seed)
	assign_cave_areas(layout)
	// Place after cave sectors are assigned so their area pass cannot overwrite
	// the sealed relay chamber.
	place_ground_telecomms_relay(layout, relay_area, seed)
	place_weed_nodes(open_cave_tiles)
	place_xeno_tunnels(open_cave_tiles, layout)
	var/list/placed_miner_tiles = list()
	place_platinum_miners(open_cave_tiles, layout, placed_miner_tiles)
	place_phoron_miners(open_cave_tiles, layout, placed_miner_tiles)
	place_xenomorph_spawns(open_cave_tiles)
	place_excavation_sites(open_cave_tiles, layout)

	smooth_zlevel(layout.z_level)
	log_game("Procedural Frontier caves generated: [map_width]x[map_height], landing at ([layout.landing_center_x],[layout.landing_center_y]), seed [seed]")

/obj/effect/landmark/procedural_frontier_generator/proc/select_biome_preset(seed)
	var/list/presets = list(
		list("name" = "Jungle", "weather" = ZTRAIT_ACIDRAIN, "wall" = /turf/closed/mineral/smooth, "deep_wall" = /turf/closed/mineral/smooth/indestructible, "floor" = /turf/open/floor/plating/ground/dirt),
		list("name" = "Desert", "weather" = ZTRAIT_SANDSTORM, "wall" = /turf/closed/mineral/smooth/bigred, "deep_wall" = /turf/closed/mineral/smooth/bigred/indestructible, "floor" = /turf/open/floor/plating/ground/mars/random/cave),
		list("name" = "Taiga", "weather" = ZTRAIT_SNOWSTORM, "wall" = /turf/closed/mineral/smooth/bluefrostwall, "deep_wall" = /turf/closed/mineral/smooth/darkfrostwall/indestructible, "floor" = /turf/open/floor/plating/ground/snow/layer2)
	)
	// Use equal-width buckets. `round(hash * (count - 1))` would make the
	// middle preset twice as likely as the first and last ones.
	var/preset_index = 1 + floor(procedural_frontier_hash(3601, 41, seed) * length(presets))
	var/list/preset = presets[preset_index]
	selected_biome_name = preset["name"]
	selected_weather_trait = preset["weather"]
	cave_wall_type = preset["wall"]
	deep_cave_wall_type = preset["deep_wall"]
	cave_floor_type = preset["floor"]
	configure_biome_weather(selected_weather_trait)
	log_game("Procedural Frontier biome preset: [selected_biome_name]")

/obj/effect/landmark/procedural_frontier_generator/proc/configure_biome_weather(weather_trait)
	var/datum/space_level/current_level = SSmapping.get_level(z)
	if(!current_level)
		return
	var/list/weather_traits = list(ZTRAIT_ACIDRAIN, ZTRAIT_SANDSTORM, ZTRAIT_SNOWSTORM)
	for(var/trait in weather_traits)
		if(current_level.traits[trait])
			current_level.traits -= trait
		var/list/trait_levels = SSmapping.z_trait_levels[trait]
		if(islist(trait_levels))
			trait_levels -= z
	current_level.traits[weather_trait] = TRUE
	var/list/selected_trait_levels = SSmapping.z_trait_levels[weather_trait]
	if(!islist(selected_trait_levels))
		selected_trait_levels = list()
		SSmapping.z_trait_levels[weather_trait] = selected_trait_levels
	if(!(z in selected_trait_levels))
		selected_trait_levels += z
	if(SSweather?.initialized)
		var/list/eligible = SSweather.eligible_zlevels["[z]"]
		if(!eligible)
			eligible = list()
		for(var/weather_type_path in subtypesof(/datum/weather))
			var/datum/weather/weather_type = weather_type_path
			var/target_trait = initial(weather_type.target_trait)
			if(target_trait == weather_trait)
				eligible[weather_type_path] = initial(weather_type.probability)
			else
				eligible -= weather_type_path
		SSweather.eligible_zlevels["[z]"] = eligible

/obj/effect/landmark/procedural_frontier_generator/proc/create_layout(seed)
	var/datum/procedural_frontier_layout/layout = new
	layout.z_level = z
	// The landmark is the authored map center. This makes the runtime map
	// independent of the z-level's world origin.
	layout.map_center_x = x
	layout.map_center_y = y
	layout.map_min_x = layout.map_center_x - round((map_width - 1) / 2)
	layout.map_min_y = layout.map_center_y - round((map_height - 1) / 2)
	layout.map_max_x = layout.map_min_x + map_width - 1
	layout.map_max_y = layout.map_min_y + map_height - 1

	var/available_x = max(1, map_width - landing_width - landing_edge_margin * 2)
	var/available_y = max(1, map_height - landing_height - landing_edge_margin * 2)
	layout.landing_min_x = layout.map_min_x + landing_edge_margin + get_edge_biased_offset(available_x, procedural_frontier_hash(701, 17, seed))
	layout.landing_min_y = layout.map_min_y + landing_edge_margin + get_edge_biased_offset(available_y, procedural_frontier_hash(719, 23, seed))
	layout.landing_max_x = layout.landing_min_x + landing_width - 1
	layout.landing_max_y = layout.landing_min_y + landing_height - 1
	layout.landing_center_x = round((layout.landing_min_x + layout.landing_max_x) / 2)
	layout.landing_center_y = round((layout.landing_min_y + layout.landing_max_y) / 2)
	layout.pad_min_x = layout.landing_center_x - round((pad_width - 1) / 2)
	layout.pad_max_x = layout.pad_min_x + pad_width - 1
	layout.pad_min_y = layout.landing_center_y - round((pad_height - 1) / 2)
	layout.pad_max_y = layout.pad_min_y + pad_height - 1
	layout.max_landing_distance = get_farthest_edge_distance(layout)
	layout.landing_edge_factor = get_landing_edge_factor(layout)
	layout.landing_exit_direction = get_landing_exit_direction(layout)
	return layout

/obj/effect/landmark/procedural_frontier_generator/proc/get_landing_exit_direction(datum/procedural_frontier_layout/layout)
	var/offset_x = layout.landing_center_x - layout.map_center_x
	var/offset_y = layout.landing_center_y - layout.map_center_y
	if(abs(offset_x) >= abs(offset_y))
		return offset_x >= 0 ? WEST : EAST
	return offset_y >= 0 ? SOUTH : NORTH

/obj/effect/landmark/procedural_frontier_generator/proc/get_edge_biased_offset(range, random_value)
	if(range <= 0)
		return 0
	var/edge_distance = (random_value < 0.5) ? (random_value * 2) : ((1 - random_value) * 2)
	var/half_range = range / 2
	return round(random_value < 0.5 ? (edge_distance ** landing_edge_bias) * half_range : range - (edge_distance ** landing_edge_bias) * half_range)

/obj/effect/landmark/procedural_frontier_generator/proc/get_farthest_edge_distance(datum/procedural_frontier_layout/layout)
	var/turf/landing_center = layout.get_landing_center()
	if(!landing_center)
		return 1
	var/farthest_distance = 1
	for(var/list/corner in list(
		list(layout.map_min_x, layout.map_min_y),
		list(layout.map_max_x, layout.map_min_y),
		list(layout.map_min_x, layout.map_max_y),
		list(layout.map_max_x, layout.map_max_y),
	))
		var/turf/corner_turf = locate(corner[1], corner[2], layout.z_level)
		if(corner_turf)
			farthest_distance = max(farthest_distance, get_dist(landing_center, corner_turf))
	return farthest_distance

/obj/effect/landmark/procedural_frontier_generator/proc/get_landing_edge_factor(datum/procedural_frontier_layout/layout)
	var/relative_x = abs(layout.landing_center_x - layout.map_center_x) / max(1, map_width / 2)
	var/relative_y = abs(layout.landing_center_y - layout.map_center_y) / max(1, map_height / 2)
	return clamp(max(relative_x, relative_y), 0, 1)

/obj/effect/landmark/procedural_frontier_generator/proc/get_ceiling_level(distance_from_landing, datum/procedural_frontier_layout/layout)
	// Map the exponential distance profile onto an extended -1..7 range, then
	// clamp it to the valid CEILING constants (0..7).
	var/normalized_distance = procedural_frontier_landing_threshold(distance_from_landing, layout.max_landing_distance, ceiling_distance_rate)
	var/gradient_span = max(1, ceiling_gradient_max - ceiling_gradient_min)
	var/raw_ceiling = round(ceiling_gradient_min + normalized_distance * gradient_span)
	return clamp(raw_ceiling, CEILING_NONE, CEILING_DEEP_UNDERGROUND_METAL)

/obj/effect/landmark/procedural_frontier_generator/proc/get_cave_area_color(ceiling_level)
	// Keep shallow/outside areas light and progressively darken underground
	// sectors. A neutral grayscale keeps the direction/depth names readable.
	var/shade = clamp(220 - (ceiling_level * 24), 52, 220)
	return rgb(shade, shade, shade)

/obj/effect/landmark/procedural_frontier_generator/proc/is_cave_area_outside(ceiling_level)
	return ceiling_level <= CEILING_OBSTRUCTED

/obj/effect/landmark/procedural_frontier_generator/proc/get_cave_depth_sector(distance_from_landing, datum/procedural_frontier_layout/layout)
	// Use the same exponential curve as ceiling assignment. This aligns Near,
	// Middle, and Far area bands with increasingly stronger ceiling types.
	var/normalized_distance = procedural_frontier_landing_threshold(distance_from_landing, layout.max_landing_distance, ceiling_distance_rate)
	return clamp(floor(normalized_distance * 3), 0, 2)

/obj/effect/landmark/procedural_frontier_generator/proc/get_cave_depth_sector_name(depth_sector)
	switch(depth_sector)
		if(0)
			return "Near"
		if(1)
			return "Middle"
	return "Far"

/obj/effect/landmark/procedural_frontier_generator/proc/get_cave_sector(dx, dy)
	if(!dx && !dy)
		return "center"
	var/absolute_x = abs(dx)
	var/absolute_y = abs(dy)
	// Keep cardinal sectors broad while reserving diagonal sectors for tiles
	// where both axes contribute materially to the direction.
	if(absolute_x > absolute_y * 2)
		return dx > 0 ? "east" : "west"
	if(absolute_y > absolute_x * 2)
		return dy > 0 ? "north" : "south"
	if(dx > 0)
		return dy > 0 ? "northeast" : "southeast"
	return dy > 0 ? "northwest" : "southwest"

/obj/effect/landmark/procedural_frontier_generator/proc/assign_cave_areas(datum/procedural_frontier_layout/layout)
	var/turf/landing_center = layout.get_landing_center()
	if(!landing_center)
		return
	var/list/area_cache = list()
	for(var/tile_x in layout.map_min_x to layout.map_max_x)
		for(var/tile_y in layout.map_min_y to layout.map_max_y)
			// Keep the LZ and its external containment ring in their dedicated
			// area so NEAR_FOB and shutter handling remain intact.
			if(tile_x >= layout.landing_min_x - 1 && tile_x <= layout.landing_max_x + 1 && tile_y >= layout.landing_min_y - 1 && tile_y <= layout.landing_max_y + 1)
				continue
			if(layout.is_generator_room(tile_x, tile_y))
				continue
			var/turf/current_turf = locate(tile_x, tile_y, layout.z_level)
			if(!current_turf)
				continue
			var/sector = get_cave_sector(tile_x - landing_center.x, tile_y - landing_center.y)
			var/distance_from_landing = get_dist_euclidean(current_turf, landing_center)
			var/depth_sector = get_cave_depth_sector(distance_from_landing, layout)
			var/depth_name = get_cave_depth_sector_name(depth_sector)
			var/ceiling_level = get_ceiling_level(distance_from_landing, layout)
			var/cache_key = "[sector]:[depth_sector]:[ceiling_level]"
			var/area/target_area = area_cache[cache_key]
			if(!target_area)
				target_area = new /area/procedural_frontier/sector
				target_area.ceiling = ceiling_level
				target_area.outside = is_cave_area_outside(ceiling_level)
				target_area.minimap_color = get_cave_area_color(ceiling_level)
				target_area.name = "Frontier Caves - [capitalize(sector)] - [depth_name] (ceiling [ceiling_level])"
				area_cache[cache_key] = target_area
			current_turf.change_area(current_turf.loc, target_area)

/obj/effect/landmark/procedural_frontier_generator/proc/generate_terrain(datum/procedural_frontier_layout/layout, area/cave_area, area/landing_area, seed)
	var/turf/landing_center = layout.get_landing_center()
	var/central_complexity_multiplier = 1 + central_landing_complexity * (1 - layout.landing_edge_factor)
	for(var/tile_x in layout.map_min_x to layout.map_max_x)
		for(var/tile_y in layout.map_min_y to layout.map_max_y)
			var/turf/current_turf = locate(tile_x, tile_y, layout.z_level)
			if(!current_turf)
				continue
			if(layout.is_landing(tile_x, tile_y))
				if(layout.is_landing_border(tile_x, tile_y))
					set_turf_and_area(current_turf, reinforced_wall_type, landing_area)
				else if(layout.is_pad(tile_x, tile_y))
					set_turf_and_area(current_turf, plating_floor_type, landing_area)
				else
					set_turf_and_area(current_turf, asteroid_floor_type, landing_area)
				continue
			if(layout.is_border(tile_x, tile_y))
				set_turf_and_area(current_turf, deep_cave_wall_type, cave_area)
				continue
			var/distance_from_landing = landing_center ? get_dist(current_turf, landing_center) : 0
			if(distance_from_landing <= landing_surface_radius)
				set_turf_and_area(current_turf, asteroid_floor_type, cave_area)
				continue
			var/ridge_cutoff = get_ridge_cutoff(distance_from_landing, layout, central_complexity_multiplier)
			var/ridge_value = procedural_frontier_ridge_noise(tile_x, tile_y, seed, noise_coarse_scale, noise_fine_scale, noise_coarse_weight)
			if(ridge_value >= ridge_cutoff)
				set_turf_and_area(current_turf, cave_floor_type, cave_area)
			else
				set_turf_and_area(current_turf, cave_wall_type, cave_area)

/obj/effect/landmark/procedural_frontier_generator/proc/get_ridge_cutoff(distance_from_landing, datum/procedural_frontier_layout/layout, central_complexity_multiplier)
	var/distance_threshold = procedural_frontier_landing_threshold(distance_from_landing, layout.max_landing_distance, landing_edge_opening)
	return clamp(distance_threshold * remote_cave_cutoff * central_complexity_multiplier + cave_ridge_threshold, 0, 1)

/obj/effect/landmark/procedural_frontier_generator/proc/set_turf_and_area(turf/target_turf, turf_type, area/target_area)
	var/turf/new_turf = target_turf.ChangeTurf(turf_type, null, CHANGETURF_SKIP)
	new_turf.change_area(new_turf.loc, target_area)
	return new_turf

/obj/effect/landmark/procedural_frontier_generator/proc/carve_landing_exit(datum/procedural_frontier_layout/layout, area/cave_area, area/landing_area)
	var/list/exit_centers = (layout.landing_exit_direction == NORTH || layout.landing_exit_direction == SOUTH) ? list(layout.landing_min_x + 6, layout.landing_max_x - 6) : list(layout.landing_min_y + 6, layout.landing_max_y - 6)
	for(var/exit_center in exit_centers)
		for(var/offset in -1 to 1)
			for(var/distance in 0 to landing_exit_length - 1)
				var/exit_x = exit_center
				var/exit_y = exit_center
				if(layout.landing_exit_direction == NORTH)
					exit_x += offset
					exit_y = layout.landing_max_y + 1 + distance
				else if(layout.landing_exit_direction == SOUTH)
					exit_x += offset
					exit_y = layout.landing_min_y - 1 - distance
				else if(layout.landing_exit_direction == EAST)
					exit_x = layout.landing_max_x + 1 + distance
					exit_y += offset
				else
					exit_x = layout.landing_min_x - 1 - distance
					exit_y += offset
				if(exit_x <= layout.map_min_x || exit_x >= layout.map_max_x || exit_y <= layout.map_min_y || exit_y >= layout.map_max_y)
					continue
				var/turf/exit_turf = locate(exit_x, exit_y, layout.z_level)
				if(exit_turf)
					set_turf_and_area(exit_turf, asteroid_floor_type, cave_area)
			var/turf/wall_gap
			if(layout.landing_exit_direction == NORTH)
				wall_gap = locate(exit_center + offset, layout.landing_max_y, layout.z_level)
			else if(layout.landing_exit_direction == SOUTH)
				wall_gap = locate(exit_center + offset, layout.landing_min_y, layout.z_level)
			else if(layout.landing_exit_direction == EAST)
				wall_gap = locate(layout.landing_max_x, exit_center + offset, layout.z_level)
			else
				wall_gap = locate(layout.landing_min_x, exit_center + offset, layout.z_level)
			if(wall_gap)
				set_turf_and_area(wall_gap, plating_floor_type, landing_area)

/obj/effect/landmark/procedural_frontier_generator/proc/place_landing_docking_port(datum/procedural_frontier_layout/layout)
	var/turf/landing_center = layout.get_landing_center()
	if(landing_center)
		var/obj/docking_port/stationary/marine_dropship/lz1/docking_port = new(landing_center)
		docking_port.area_type = /area/procedural_frontier/landing/lz1
	// Mount the button immediately inside the wall containing the exits.
	var/turf/button_turf
	if(layout.landing_exit_direction == NORTH)
		button_turf = locate(layout.landing_center_x, layout.landing_max_y - 1, layout.z_level)
	else if(layout.landing_exit_direction == SOUTH)
		button_turf = locate(layout.landing_center_x, layout.landing_min_y + 1, layout.z_level)
	else if(layout.landing_exit_direction == EAST)
		button_turf = locate(layout.landing_max_x - 1, layout.landing_center_y, layout.z_level)
	else
		button_turf = locate(layout.landing_min_x + 1, layout.landing_center_y, layout.z_level)
	if(button_turf)
		new /obj/machinery/button/door/open_only/landing_zone(button_turf)

/obj/effect/landmark/procedural_frontier_generator/proc/place_landing_equipment(datum/procedural_frontier_layout/layout, area/landing_area)
	// Mark the pad with a stencil. Every tile covered by the dropship remains
	// clean plating; do not replace it with warning overlays.
	for(var/tile_x in layout.pad_min_x to layout.pad_max_x)
		for(var/tile_y in layout.pad_min_y to layout.pad_max_y)
			var/turf/pad_turf = locate(tile_x, tile_y, layout.z_level)
			if(pad_turf)
				set_turf_and_area(pad_turf, plating_floor_type, landing_area)
	var/turf/stencil_turf = locate(layout.landing_center_x, layout.landing_center_y, layout.z_level)
	if(stencil_turf)
		new /obj/structure/prop/mainship/hangar_stencil(stencil_turf)
	// Timed containment poddoors form a complete, gapless outer ring. The
	// reinforced wall is the inner ring; poddoors are one tile behind it.
	var/containment_min_x = layout.landing_min_x - 1
	var/containment_max_x = layout.landing_max_x + 1
	var/containment_min_y = layout.landing_min_y - 1
	var/containment_max_y = layout.landing_max_y + 1
	for(var/tile_x in containment_min_x to containment_max_x)
		for(var/tile_y in containment_min_y to containment_max_y)
			var/is_containment_ring = tile_x == containment_min_x || tile_x == containment_max_x || tile_y == containment_min_y || tile_y == containment_max_y
			if(!is_containment_ring)
				continue
			var/turf/containment_turf = locate(tile_x, tile_y, layout.z_level)
			if(containment_turf)
				containment_turf = set_turf_and_area(containment_turf, asteroid_floor_type, landing_area)
				var/obj/machinery/door/poddoor/timed_late/containment/landing_zone/containment_door = new(containment_turf)
				// Poddoors follow the orientation of their ring side. In particular,
				// the north and south rows are intentionally different directions.
				if(tile_y == containment_min_y)
					containment_door.dir = SOUTH
				else if(tile_y == containment_max_y)
					containment_door.dir = NORTH
				else if(tile_x == containment_min_x)
					containment_door.dir = WEST
				else
					containment_door.dir = EAST
	// Barricades sit immediately inside each exit. Their sprite direction is
	// perpendicular to the old mapping: north/south walls use NORTH, while
	// east/west walls use EAST.
	var/list/exit_centers = (layout.landing_exit_direction == NORTH || layout.landing_exit_direction == SOUTH) ? list(layout.landing_min_x + 6, layout.landing_max_x - 6) : list(layout.landing_min_y + 6, layout.landing_max_y - 6)
	for(var/exit_center in exit_centers)
		for(var/offset in -1 to 1)
			var/turf/barricade_turf
			if(layout.landing_exit_direction == NORTH)
				barricade_turf = locate(exit_center + offset, layout.landing_max_y - 1, layout.z_level)
			else if(layout.landing_exit_direction == SOUTH)
				barricade_turf = locate(exit_center + offset, layout.landing_min_y + 1, layout.z_level)
			else if(layout.landing_exit_direction == EAST)
				barricade_turf = locate(layout.landing_max_x - 1, exit_center + offset, layout.z_level)
			else
				barricade_turf = locate(layout.landing_min_x + 1, exit_center + offset, layout.z_level)
			if(barricade_turf)
				var/obj/structure/barricade/folding/barricade = new(barricade_turf)
				barricade.dir = get_landing_exit_object_dir(layout.landing_exit_direction)

/obj/effect/landmark/procedural_frontier_generator/proc/place_supply_room(datum/procedural_frontier_layout/layout, area/landing_area, seed)
	var/list/room_origin = get_lz_room_origin(layout, 1, supply_room_width, supply_room_height)
	var/room_min_x = room_origin[1]
	var/room_min_y = room_origin[2]
	var/room_max_x = room_min_x + supply_room_width - 1
	var/room_max_y = room_min_y + supply_room_height - 1
	for(var/tile_x in room_min_x to room_max_x)
		for(var/tile_y in room_min_y to room_max_y)
			var/turf/room_turf = locate(tile_x, tile_y, layout.z_level)
			if(!room_turf)
				continue
			var/is_room_border = tile_x == room_min_x || tile_x == room_max_x || tile_y == room_min_y || tile_y == room_max_y
			set_turf_and_area(room_turf, is_room_border ? reinforced_wall_type : wood_floor_type, landing_area)
	var/turf/console_turf = locate(room_min_x + 1, room_min_y + 1, layout.z_level)
	if(console_turf)
		new /obj/machinery/computer/supplycomp/crash(console_turf)
	for(var/crate_type in list(/obj/structure/largecrate/guns/russian, /obj/structure/largecrate/guns/merc))
		var/turf/crate_turf = locate(room_min_x + 2 + (crate_type == /obj/structure/largecrate/guns/merc), room_min_y + 3, layout.z_level)
		if(crate_turf)
			new crate_type(crate_turf)
	for(var/i in 1 to 2)
		var/turf/barrel_turf = locate(room_min_x + 2 + i, room_min_y + 2, layout.z_level)
		if(barrel_turf)
			new /obj/effect/spawner/random/misc/structure/barrel(barrel_turf)
	var/turf/airlock_turf = get_lz_room_airlock_turf(layout, room_min_x, room_min_y, room_max_x, room_max_y)
	place_lz_room_airlock(airlock_turf, wood_floor_type, landing_area)
	place_room_lights(layout, room_min_x, room_min_y, room_max_x, room_max_y)

/obj/effect/landmark/procedural_frontier_generator/proc/place_medical_room(datum/procedural_frontier_layout/layout, area/landing_area, seed)
	var/list/room_origin = get_lz_room_origin(layout, 2, medical_room_width, medical_room_height)
	var/room_min_x = room_origin[1]
	var/room_min_y = room_origin[2]
	var/room_max_x = room_min_x + medical_room_width - 1
	var/room_max_y = room_min_y + medical_room_height - 1
	build_lz_room(layout, landing_area, room_min_x, room_min_y, room_max_x, room_max_y, mainship_gray_floor_type)
	var/turf/table_turf = locate(round((room_min_x + room_max_x) / 2), round((room_min_y + room_max_y) / 2), layout.z_level)
	if(table_turf)
		new /obj/machinery/optable(table_turf)
	var/turf/iv_turf = locate(room_min_x + 2, room_min_y + 2, layout.z_level)
	if(iv_turf)
		new /obj/machinery/iv_drip(iv_turf)
	var/turf/printer_turf = locate(room_max_x - 1, room_min_y + 2, layout.z_level)
	if(printer_turf)
		new /obj/machinery/bioprinter/stocked(printer_turf)
	var/turf/closet_turf = locate(room_min_x + 1, room_max_y - 1, layout.z_level)
	if(closet_turf)
		new /obj/structure/closet/secure_closet/medical2(closet_turf)
	var/turf/marine_med_turf = locate(room_max_x - 1, room_min_y + 1, layout.z_level)
	if(marine_med_turf)
		new /obj/machinery/vending/MarineMed(marine_med_turf)
	var/turf/medical_vend_turf = locate(room_max_x - 1, room_max_y - 1, layout.z_level)
	if(medical_vend_turf)
		new /obj/machinery/vending/medical(medical_vend_turf)
	for(var/table_x in list(room_min_x + 2, room_max_x - 2))
		var/turf/side_table_turf = locate(table_x, room_max_y - 2, layout.z_level)
		if(side_table_turf)
			new /obj/structure/table(side_table_turf)
			new /obj/item/tank/anesthetic(side_table_turf)
			new /obj/item/clothing/mask/breath/medical(side_table_turf)
			new /obj/item/storage/surgical_tray/alt(side_table_turf)
	place_lz_room_airlock(get_lz_room_airlock_turf(layout, room_min_x, room_min_y, room_max_x, room_max_y), mainship_gray_floor_type, landing_area)
	place_room_lights(layout, room_min_x, room_min_y, room_max_x, room_max_y)

/obj/effect/landmark/procedural_frontier_generator/proc/place_engineering_room(datum/procedural_frontier_layout/layout, area/landing_area, seed)
	var/list/room_origin = get_lz_room_origin(layout, 3, engineering_room_width, engineering_room_height)
	var/room_min_x = room_origin[1]
	var/room_min_y = room_origin[2]
	var/room_max_x = room_min_x + engineering_room_width - 1
	var/room_max_y = room_min_y + engineering_room_height - 1
	build_lz_room(layout, landing_area, room_min_x, room_min_y, room_max_x, room_max_y, asteroid_floor_type)
	for(var/tile_x in room_min_x + 1 to room_max_x - 1)
		for(var/tile_y in room_min_y + 1 to room_max_y - 1)
			var/turf/decal_turf = locate(tile_x, tile_y, layout.z_level)
			if(decal_turf)
				new /obj/effect/turf_decal/tile/transparent/yellow/diagonal_centre(decal_turf)
	var/turf/apc_turf = locate(room_min_x + 1, room_max_y - 1, layout.z_level)
	if(apc_turf)
		new /obj/machinery/power/apc(apc_turf)
	var/turf/engivend_turf = locate(room_min_x + 2, room_min_y + 2, layout.z_level)
	if(engivend_turf)
		new /obj/machinery/vending/engivend(engivend_turf)
	var/turf/toolvend_turf = locate(room_max_x - 1, room_min_y + 2, layout.z_level)
	if(toolvend_turf)
		new /obj/machinery/vending/tool(toolvend_turf)
	var/turf/rack_turf = locate(room_min_x + 1, room_max_y - 1, layout.z_level)
	if(rack_turf)
		new /obj/structure/rack(rack_turf)
		new /obj/item/tool/pickaxe/plasmacutter(rack_turf)
	place_lz_room_airlock(get_lz_room_airlock_turf(layout, room_min_x, room_min_y, room_max_x, room_max_y), asteroid_floor_type, landing_area)
	place_room_lights(layout, room_min_x, room_min_y, room_max_x, room_max_y)

/obj/effect/landmark/procedural_frontier_generator/proc/place_weapon_room(datum/procedural_frontier_layout/layout, area/landing_area, seed)
	var/list/room_origin = get_lz_room_origin(layout, 4, weapon_room_width, weapon_room_height)
	var/room_min_x = room_origin[1]
	var/room_min_y = room_origin[2]
	var/room_max_x = room_min_x + weapon_room_width - 1
	var/room_max_y = room_min_y + weapon_room_height - 1
	build_lz_room(layout, landing_area, room_min_x, room_min_y, room_max_x, room_max_y, mainship_gray_floor_type)
	// Keep all three vendors flush against the same inner wall in one line.
	var/list/vendor_types = list(
		/obj/machinery/vending/weapon,
		/obj/machinery/vending/armor_supply,
		/obj/machinery/vending/uniform_supply,
	)
	var/vendor_index = 0
	for(var/vendor_type in vendor_types)
		var/turf/vendor_turf = locate(room_min_x + 1 + vendor_index++, room_min_y + 1, layout.z_level)
		if(vendor_turf)
			new vendor_type(vendor_turf)
	place_lz_room_airlock(get_lz_room_airlock_turf(layout, room_min_x, room_min_y, room_max_x, room_max_y), mainship_gray_floor_type, landing_area)
	place_room_lights(layout, room_min_x, room_min_y, room_max_x, room_max_y)

/obj/effect/landmark/procedural_frontier_generator/proc/place_toilet_room(datum/procedural_frontier_layout/layout, area/landing_area, seed)
	var/list/room_origin = get_lz_room_origin(layout, 5, toilet_room_width, toilet_room_height)
	var/room_min_x = room_origin[1]
	var/room_min_y = room_origin[2]
	var/room_max_x = room_min_x + toilet_room_width - 1
	var/room_max_y = room_min_y + toilet_room_height - 1
	build_lz_room(layout, landing_area, room_min_x, room_min_y, room_max_x, room_max_y, toilet_floor_type, gold_wall_type)
	var/turf/toilet_turf = locate(round((room_min_x + room_max_x) / 2), round((room_min_y + room_max_y) / 2), layout.z_level)
	if(toilet_turf)
		new /obj/structure/toilet/alternate(toilet_turf)
	place_lz_room_airlock(get_lz_room_airlock_turf(layout, room_min_x, room_min_y, room_max_x, room_max_y), toilet_floor_type, landing_area)
	place_room_lights(layout, room_min_x, room_min_y, room_max_x, room_max_y)

/obj/effect/landmark/procedural_frontier_generator/proc/get_room_edge_offset(min_value, max_value, seed, salt)
	if(max_value <= min_value)
		return min_value
	return min_value + round(procedural_frontier_hash(salt, salt + 7, seed) * (max_value - min_value))

/obj/effect/landmark/procedural_frontier_generator/proc/get_lz_room_origin(datum/procedural_frontier_layout/layout, slot, room_width, room_height)
	slot = 1 + ((slot - 1) % 4)
	var/list/origin = list(layout.landing_min_x + 2, layout.landing_min_y + 2)
	var/room_gap = 1
	if(layout.landing_exit_direction == NORTH)
		origin[1] = layout.landing_min_x + 1 + ((slot - 1) * (room_width + room_gap))
		origin[2] = layout.landing_min_y
	else if(layout.landing_exit_direction == SOUTH)
		origin[1] = layout.landing_min_x + 1 + ((slot - 1) * (room_width + room_gap))
		origin[2] = layout.landing_max_y - room_height + 1
	else if(layout.landing_exit_direction == EAST)
		origin[1] = layout.landing_min_x
		origin[2] = layout.landing_min_y + 1 + ((slot - 1) * (room_height + room_gap))
	else
		origin[1] = layout.landing_max_x - room_width + 1
		origin[2] = layout.landing_min_y + 1 + ((slot - 1) * (room_height + room_gap))
	return origin

/obj/effect/landmark/procedural_frontier_generator/proc/get_lz_room_airlock_turf(datum/procedural_frontier_layout/layout, room_min_x, room_min_y, room_max_x, room_max_y)
	var/door_x = round((room_min_x + room_max_x) / 2)
	var/door_y = round((room_min_y + room_max_y) / 2)
	if(layout.landing_exit_direction == NORTH)
		door_y = room_max_y
	else if(layout.landing_exit_direction == SOUTH)
		door_y = room_min_y
	else if(layout.landing_exit_direction == EAST)
		door_x = room_max_x
	else
		door_x = room_min_x
	return locate(door_x, door_y, layout.z_level)

//гений мысли, отец русского кодинга
/obj/effect/landmark/procedural_frontier_generator/proc/get_landing_exit_object_dir(exit_direction)
	// Folding barricades expose all four cardinal orientations. Keep the
	// object's facing aligned with the side used by the exit itself.
	switch(exit_direction)
		if(NORTH)
			return NORTH
		if(SOUTH)
			return SOUTH
		if(EAST)
			return EAST
		if(WEST)
			return WEST
	return SOUTH

/obj/effect/landmark/procedural_frontier_generator/proc/build_lz_room(datum/procedural_frontier_layout/layout, area/landing_area, room_min_x, room_min_y, room_max_x, room_max_y, floor_type, wall_type)
	if(!wall_type)
		wall_type = reinforced_wall_type
	for(var/tile_x in room_min_x to room_max_x)
		for(var/tile_y in room_min_y to room_max_y)
			var/turf/room_turf = locate(tile_x, tile_y, layout.z_level)
			if(!room_turf)
				continue
			var/is_room_border = tile_x == room_min_x || tile_x == room_max_x || tile_y == room_min_y || tile_y == room_max_y
			set_turf_and_area(room_turf, is_room_border ? wall_type : floor_type, landing_area)

/obj/effect/landmark/procedural_frontier_generator/proc/place_room_lights(datum/procedural_frontier_layout/layout, room_min_x, room_min_y, room_max_x, room_max_y)
	var/list/light_positions = list(
		list(room_min_x + 1, room_min_y + 1),
		list(room_max_x - 1, room_min_y + 1),
	)
	for(var/list/light_position in light_positions)
		var/turf/light_turf = locate(light_position[1], light_position[2], layout.z_level)
		if(light_turf && istype(light_turf, open_turf_type) && !length(light_turf.contents))
			new /obj/machinery/light(light_turf)

/obj/effect/landmark/procedural_frontier_generator/proc/place_lz_room_airlock(turf/airlock_turf, floor_type, area/landing_area)
	if(!airlock_turf)
		return
	airlock_turf = set_turf_and_area(airlock_turf, floor_type, landing_area)
	new /obj/machinery/door/airlock/mainship/engineering/free_access(airlock_turf)

/obj/effect/landmark/procedural_frontier_generator/proc/place_landing_random_props(datum/procedural_frontier_layout/layout)
	var/list/candidates = list()
	for(var/tile_x in layout.landing_min_x + 2 to layout.landing_max_x - 2)
		for(var/tile_y in layout.landing_min_y + 2 to layout.landing_max_y - 2)
			if(layout.is_pad(tile_x, tile_y))
				continue
			var/turf/candidate = locate(tile_x, tile_y, layout.z_level)
			if(candidate && istype(candidate, open_turf_type) && !length(candidate.contents))
				candidates += candidate
	for(var/i in 1 to lz_barrel_count)
		var/turf/barrel_turf = pick_n_take(candidates)
		if(barrel_turf)
			new /obj/effect/spawner/random/misc/structure/barrel(barrel_turf)
	for(var/i in 1 to lz_supplycrate_count)
		var/turf/crate_turf = pick_n_take(candidates)
		if(crate_turf)
			new /obj/effect/spawner/random/misc/structure/supplycrate(crate_turf)

/obj/effect/landmark/procedural_frontier_generator/proc/place_deep_walls(datum/procedural_frontier_layout/layout, area/cave_area, seed)
	// Deep walls are based on separation from open cave tiles, never on LZ
	// distance. This keeps r_walls in the interior of thick rock masses.
	for(var/tile_x in layout.map_min_x + 1 to layout.map_max_x - 1)
		for(var/tile_y in layout.map_min_y + 1 to layout.map_max_y - 1)
			var/turf/rock_turf = locate(tile_x, tile_y, layout.z_level)
			if(!rock_turf || !istype(rock_turf, cave_wall_type))
				continue
			var/ridge_value = procedural_frontier_ridge_noise(tile_x, tile_y, seed, noise_coarse_scale, noise_fine_scale, noise_coarse_weight)
			if(ridge_value > hard_ridge_cutoff || !is_deep_inside_rock(rock_turf, layout))
				continue
			set_turf_and_area(rock_turf, deep_cave_wall_type, cave_area)

/obj/effect/landmark/procedural_frontier_generator/proc/place_ground_telecomms_relay(datum/procedural_frontier_layout/layout, area/relay_area, seed)
	var/list/candidates = list()
	for(var/tile_x in layout.map_min_x + telecomms_relay_wall_radius + 1 to layout.map_max_x - telecomms_relay_wall_radius - 1)
		for(var/tile_y in layout.map_min_y + telecomms_relay_wall_radius + 1 to layout.map_max_y - telecomms_relay_wall_radius - 1)
			if(!is_sealed_relay_location(tile_x, tile_y, layout))
				continue
			candidates += list(locate(tile_x, tile_y, layout.z_level))
	if(!length(candidates))
		log_game("Procedural Frontier: no sealed rock pocket available for ground telecomms relay")
		return
	var/relay_index = 1 + round(procedural_frontier_hash(3701, 43, seed) * (length(candidates) - 1))
	var/turf/relay_turf = candidates[relay_index]
	for(var/tile_x in relay_turf.x - telecomms_relay_wall_radius to relay_turf.x + telecomms_relay_wall_radius)
		for(var/tile_y in relay_turf.y - telecomms_relay_wall_radius to relay_turf.y + telecomms_relay_wall_radius)
			var/turf/wall_turf = locate(tile_x, tile_y, layout.z_level)
			if(wall_turf)
				set_turf_and_area(wall_turf, deep_cave_wall_type, relay_area)
	// Ground relays are normally embedded in indestructible rock on static
	// maps. Keep this one fully sealed too: no floor, airlock, or cave opening.
	relay_turf = locate(relay_turf.x, relay_turf.y, layout.z_level)
	new /obj/machinery/telecomms/relay/preset/telecomms/ground(relay_turf)

/obj/effect/landmark/procedural_frontier_generator/proc/is_sealed_relay_location(tile_x, tile_y, datum/procedural_frontier_layout/layout)
	if(layout.is_landing(tile_x, tile_y) || layout.is_generator_room(tile_x, tile_y))
		return FALSE
	for(var/check_x in tile_x - telecomms_relay_wall_radius to tile_x + telecomms_relay_wall_radius)
		for(var/check_y in tile_y - telecomms_relay_wall_radius to tile_y + telecomms_relay_wall_radius)
			var/turf/check_turf = locate(check_x, check_y, layout.z_level)
			if(!check_turf || !istype(check_turf, cave_wall_type))
				return FALSE
	return TRUE

/obj/effect/landmark/procedural_frontier_generator/proc/is_deep_inside_rock(turf/rock_turf, datum/procedural_frontier_layout/layout)
	for(var/offset_x in -deep_wall_separation to deep_wall_separation)
		for(var/offset_y in -deep_wall_separation to deep_wall_separation)
			if(!offset_x && !offset_y)
				continue
			var/turf/neighbor = locate(rock_turf.x + offset_x, rock_turf.y + offset_y, layout.z_level)
			if(!neighbor || istype(neighbor, open_turf_type))
				return FALSE
	return TRUE

/obj/effect/landmark/procedural_frontier_generator/proc/retain_reachable_cave_tiles(datum/procedural_frontier_layout/layout, area/cave_area, area/landing_area)
	// Flood-fill starts inside the LZ. Any open cave tile which cannot be reached
	// cardinally from it is sealed back into rock before landmarks are placed.
	var/turf/landing_center = layout.get_landing_center()
	if(!landing_center)
		return list()
	var/list/reachable_tiles = list()
	var/list/visited = list()
	var/list/queue = list(landing_center)
	var/queue_index = 1
	while(queue_index <= length(queue))
		var/turf/current_turf = queue[queue_index++]
		var/current_key = "[current_turf.x],[current_turf.y]"
		if(visited[current_key])
			continue
		visited[current_key] = TRUE
		if(!istype(current_turf, open_turf_type))
			continue
		for(var/direction in GLOB.cardinals)
			var/turf/neighbor = get_step(current_turf, direction)
			if(!neighbor)
				continue
			if(neighbor.x <= layout.map_min_x || neighbor.x >= layout.map_max_x || neighbor.y <= layout.map_min_y || neighbor.y >= layout.map_max_y)
				continue
			var/neighbor_key = "[neighbor.x],[neighbor.y]"
			if(!visited[neighbor_key] && istype(neighbor, open_turf_type))
				queue += neighbor

	for(var/tile_x in layout.map_min_x + 1 to layout.map_max_x - 1)
		for(var/tile_y in layout.map_min_y + 1 to layout.map_max_y - 1)
			var/turf/cave_turf = locate(tile_x, tile_y, layout.z_level)
			if(!cave_turf || layout.is_landing(tile_x, tile_y))
				continue
			var/cave_key = "[tile_x],[tile_y]"
			if(istype(cave_turf, open_turf_type) && visited[cave_key])
				reachable_tiles += cave_turf
			else if(istype(cave_turf, open_turf_type))
				set_turf_and_area(cave_turf, cave_wall_type, cave_area)
	return reachable_tiles

/obj/effect/landmark/procedural_frontier_generator/proc/place_generator_room(datum/procedural_frontier_layout/layout, area/generator_area, area/cave_area, list/open_cave_tiles, seed)
	var/half_width = round(generator_room_width / 2)
	var/half_height = round(generator_room_height / 2)
	var/room_center_x = layout.map_center_x
	var/room_center_y = layout.map_center_y
	// Keep the room approximately central, but move it to the nearest valid
	// point when the random landing zone occupies the exact map centre.
	var/found_room_position = FALSE
	for(var/ring in 0 to 24)
		var/list/candidates = list(list(0, 0), list(ring, 0), list(-ring, 0), list(0, ring), list(0, -ring))
		for(var/list/offset in candidates)
			var/test_min_x = room_center_x + offset[1] - half_width
			var/test_min_y = room_center_y + offset[2] - half_height
			var/test_max_x = test_min_x + generator_room_width - 1
			var/test_max_y = test_min_y + generator_room_height - 1
			if(test_min_x <= layout.map_min_x + 1 || test_max_x >= layout.map_max_x - 1 || test_min_y <= layout.map_min_y + 1 || test_max_y >= layout.map_max_y - 1)
				continue
			if(test_max_x < layout.landing_min_x - 2 || test_min_x > layout.landing_max_x + 2 || test_max_y < layout.landing_min_y - 2 || test_min_y > layout.landing_max_y + 2)
				room_center_x += offset[1]
				room_center_y += offset[2]
				found_room_position = TRUE
				break
		if(found_room_position)
			break
	var/min_x = room_center_x - half_width
	var/min_y = room_center_y - half_height
	var/max_x = min_x + generator_room_width - 1
	var/max_y = min_y + generator_room_height - 1
	layout.generator_room_min_x = min_x
	layout.generator_room_max_x = max_x
	layout.generator_room_min_y = min_y
	layout.generator_room_max_y = max_y
	for(var/tile_x in min_x to max_x)
		for(var/tile_y in min_y to max_y)
			var/turf/room_turf = locate(tile_x, tile_y, layout.z_level)
			if(!room_turf)
				continue
			var/is_border = tile_x == min_x || tile_x == max_x || tile_y == min_y || tile_y == max_y
			set_turf_and_area(room_turf, is_border ? reinforced_wall_type : asteroid_floor_type, generator_area)
	// APC is mounted against the east wall. The generators are three adjacent
	// machines on one line, leaving clear space around the feature.
	var/turf/apc_turf = locate(max_x, room_center_y, layout.z_level)
	if(apc_turf)
		new /obj/machinery/power/apc(apc_turf)
	for(var/generator_index in 1 to 3)
		var/turf/generator_turf = locate(room_center_x - 1 + generator_index, room_center_y, layout.z_level)
		if(generator_turf)
			new /obj/machinery/power/geothermal(generator_turf)
	// Opposite-side doors make the room a pass-through rather than a sealed
	// island. Each route targets the nearest reachable cave tile on that side.
	place_generator_room_exit(layout, generator_area, cave_area, open_cave_tiles, room_center_x, max_y, NORTH, seed)
	place_generator_room_exit(layout, generator_area, cave_area, open_cave_tiles, room_center_x, min_y, SOUTH, seed + 1)

/obj/effect/landmark/procedural_frontier_generator/proc/place_generator_room_exit(datum/procedural_frontier_layout/layout, area/generator_area, area/cave_area, list/open_cave_tiles, entry_x, entry_y, direction, seed)
	var/turf/target
	var/best_distance = INFINITY
	for(var/turf/candidate in open_cave_tiles)
		if(direction == NORTH && candidate.y <= entry_y)
			continue
		if(direction == SOUTH && candidate.y >= entry_y)
			continue
		if(abs(candidate.x - entry_x) > 32)
			continue
		var/distance = abs(candidate.x - entry_x) + abs(candidate.y - entry_y)
		if(distance < best_distance)
			best_distance = distance
			target = candidate
	if(!target)
		return
	var/door_turf = locate(entry_x, entry_y, layout.z_level)
	if(door_turf)
		set_turf_and_area(door_turf, asteroid_floor_type, generator_area)
		new /obj/machinery/door/airlock/mainship/engineering/free_access(door_turf)
	var/path_x = entry_x
	var/path_y = entry_y
	while(path_x != target.x)
		path_x += path_x < target.x ? 1 : -1
		var/turf/path_turf = locate(path_x, path_y, layout.z_level)
		if(path_turf)
			set_turf_and_area(path_turf, asteroid_floor_type, cave_area)
	while(path_y != target.y)
		path_y += path_y < target.y ? 1 : -1
		var/turf/path_turf = locate(path_x, path_y, layout.z_level)
		if(path_turf)
			set_turf_and_area(path_turf, asteroid_floor_type, cave_area)

/obj/effect/landmark/procedural_frontier_generator/proc/place_weed_nodes(list/open_cave_tiles)
	for(var/turf/cave_turf in open_cave_tiles)
		if(cave_turf.x % weed_node_spacing == 0 && cave_turf.y % weed_node_spacing == 0)
			new /obj/effect/landmark/weed_node(cave_turf)

/obj/effect/landmark/procedural_frontier_generator/proc/place_xeno_tunnels(list/open_cave_tiles, datum/procedural_frontier_layout/layout)
	var/list/tunnel_tiles = list()
	var/list/tunnel_targets = list(
		list(layout.map_min_x + tunnel_edge_offset, layout.map_min_y + tunnel_edge_offset),
		list(layout.map_max_x - tunnel_edge_offset, layout.map_min_y + tunnel_edge_offset),
		list(layout.map_min_x + tunnel_edge_offset, layout.map_max_y - tunnel_edge_offset),
		list(layout.map_max_x - tunnel_edge_offset, layout.map_max_y - tunnel_edge_offset),
	)
	for(var/list/target in tunnel_targets)
		var/turf/best_tunnel_turf = get_best_tunnel_tile(open_cave_tiles, tunnel_tiles, target)
		if(best_tunnel_turf)
			new /obj/effect/landmark/xeno_tunnel_spawn(best_tunnel_turf)
			tunnel_tiles += best_tunnel_turf

/obj/effect/landmark/procedural_frontier_generator/proc/get_best_tunnel_tile(list/open_cave_tiles, list/placed_tunnels, list/target)
	var/turf/best_tunnel_turf
	var/best_score = INFINITY
	for(var/turf/cave_turf in open_cave_tiles)
		if(!is_tunnel_tile_far_enough(cave_turf, placed_tunnels))
			continue
		var/score = abs(cave_turf.x - target[1]) + abs(cave_turf.y - target[2])
		if(score < best_score)
			best_score = score
			best_tunnel_turf = cave_turf
	return best_tunnel_turf

/obj/effect/landmark/procedural_frontier_generator/proc/is_tunnel_tile_far_enough(turf/candidate, list/placed_tunnels)
	for(var/turf/other_tunnel in placed_tunnels)
		if(get_dist(candidate, other_tunnel) < tunnel_minimum_spacing)
			return FALSE
	return TRUE

/obj/effect/landmark/procedural_frontier_generator/proc/place_platinum_miners(list/open_cave_tiles, datum/procedural_frontier_layout/layout, list/placed_miner_tiles)
	var/list/candidates = list()
	var/turf/landing_center = layout.get_landing_center()
	for(var/turf/candidate in open_cave_tiles)
		if(landing_center && get_dist(candidate, landing_center) > landing_surface_radius)
			candidates += candidate
	if(!length(candidates))
		candidates = open_cave_tiles.Copy()
	select_spaced_miner_tiles(candidates, /obj/effect/landmark/miner_platinum, miner_platinum_count, placed_miner_tiles)

/obj/effect/landmark/procedural_frontier_generator/proc/place_phoron_miners(list/open_cave_tiles, datum/procedural_frontier_layout/layout, list/placed_miner_tiles)
	var/list/candidates = list()
	var/turf/landing_center = layout.get_landing_center()
	for(var/turf/candidate in open_cave_tiles)
		if(landing_center && get_dist(candidate, landing_center) <= miner_phoron_radius)
			candidates += candidate
	select_spaced_miner_tiles(candidates, /obj/effect/landmark/miner_phoron, miner_phoron_count, placed_miner_tiles)

/obj/effect/landmark/procedural_frontier_generator/proc/select_spaced_miner_tiles(list/candidates, landmark_type, miner_count, list/placed_miner_tiles)
	var/list/remaining = candidates.Copy()
	for(var/i in 1 to min(miner_count, length(remaining)))
		var/turf/best_turf
		var/best_score = -1
		for(var/turf/candidate in remaining)
			var/nearest_distance = INFINITY
			for(var/turf/placed_turf in placed_miner_tiles)
				nearest_distance = min(nearest_distance, get_dist(candidate, placed_turf))
			if(!length(placed_miner_tiles))
				nearest_distance = 0
			if(nearest_distance < miner_minimum_spacing && length(placed_miner_tiles))
				continue
			if(nearest_distance > best_score)
				best_score = nearest_distance
				best_turf = candidate
		if(!best_turf)
			break
		new landmark_type(best_turf)
		placed_miner_tiles += best_turf
		remaining -= best_turf

/obj/effect/landmark/procedural_frontier_generator/proc/place_xenomorph_spawns(list/open_cave_tiles)
	if(!length(open_cave_tiles))
		return
	var/list/safe_cave_tiles = list()
	for(var/turf/cave_turf in open_cave_tiles)
		var/area/cave_area = get_area(cave_turf)
		if(cave_area && cave_area.ceiling >= CEILING_UNDERGROUND)
			safe_cave_tiles += cave_turf
	if(!length(safe_cave_tiles))
		return
	// Spread deterministic job spawns only through deep enough sectors. This
	// prevents xenomorphs from appearing under open-sky storm exposure.
	for(var/spawn_index in 1 to min(xenomorph_spawn_count, length(safe_cave_tiles)))
		var/list_index = round(1 + (length(safe_cave_tiles) - 1) * (spawn_index - 1) / max(1, xenomorph_spawn_count - 1))
		new /obj/effect/landmark/start/job/xenomorph(safe_cave_tiles[list_index])

/obj/effect/landmark/procedural_frontier_generator/proc/place_excavation_sites(list/open_cave_tiles, datum/procedural_frontier_layout/layout)
	var/list/site_candidates = list()
	for(var/turf/candidate in open_cave_tiles)
		if(get_dist(candidate, layout.get_landing_center()) > landing_surface_radius)
			site_candidates += candidate
	for(var/i in 1 to min(excavation_site_count, length(site_candidates)))
		var/turf/site_turf = pick_n_take(site_candidates)
		if(site_turf)
			new /obj/effect/landmark/excavation_site_spawner(site_turf)
