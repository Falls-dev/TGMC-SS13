// Ported from cmss13-pve for Calliope Highway and LV522 Chance's Claim.
// Trimmed to map-used auto turfs and adapted to TGMC turf vars (slayer).

/turf/open/auto_turf
	name = "auto-sand"
	icon = 'icons/turf/floors/auto_sand.dmi'
	icon_state = "sand_1"
	var/icon_prefix = "sand"
	var/layer_name = list("layer 1", "layer 2", "layer 3", "layer 4", "layer 5")
	var/variant = 0
	var/variant_prefix_name = ""

/turf/open/auto_turf/is_weedable()
	return TRUE

/turf/open/auto_turf/get_dirt_type()
	return DIRT_TYPE_GROUND

/turf/open/auto_turf/can_dig_xeno_tunnel()
	return TRUE

/turf/open/auto_turf/update_icon()
	if(variant && (slayer == initial(slayer)))
		icon_state = "[icon_prefix]_[slayer]_[variant]"
	else
		icon_state = "[icon_prefix]_[slayer]"
	setDir(pick(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST))

	var/name_to_set
	switch(slayer)
		if(0)
			name_to_set = layer_name[1]
		if(1)
			name_to_set = layer_name[2]
		if(2)
			name_to_set = layer_name[3]
		if(3)
			name_to_set = layer_name[4]
		if(4)
			name_to_set = layer_name[5]

	if(slayer == initial(slayer))
		name = "[variant_prefix_name] [name_to_set]"
	else
		name = name_to_set

/turf/open/auto_turf/proc/changing_layer(new_layer)
	if(isnull(new_layer) || new_layer == slayer)
		return
	slayer = max(0, new_layer)
	for(var/direction in GLOB.alldirs)
		var/turf/open/T = get_step(src, direction)
		if(istype(T))
			T.update_icon()
	update_icon()

/turf/open/auto_turf/sand_white
	layer_name = list("aged igneous", "wind swept dunes", "warn a coder", "warn a coder", "warn a coder")
	icon_state = "varadero_1"
	icon_prefix = "varadero"

/turf/open/auto_turf/sand_white/get_dirt_type()
	return DIRT_TYPE_SAND

/turf/open/auto_turf/sand_white/layer0
	icon_state = "varadero_0"
	slayer = 0

/turf/open/auto_turf/sand_white/layer1
	icon_state = "varadero_1"
	slayer = 1

/turf/open/auto_turf/strata_grass
	name = "matted grass"
	icon = 'icons/turf/floors/auto_strata_grass.dmi'
	icon_state = "grass_0"
	icon_prefix = "grass"
	layer_name = list("ground", "lush thick grass")
	desc = "grass, dirt, mud, and other assorted high moisture cave flooring."
	baseturfs = /turf/open/auto_turf/strata_grass/layer0

/turf/open/auto_turf/strata_grass/layer0
	icon_state = "grass_0"
	slayer = 0
	variant_prefix_name = "matted grass"

/turf/open/auto_turf/strata_grass/layer0_mud
	icon_state = "grass_0_mud"
	slayer = 0
	variant = "mud"
	variant_prefix_name = "muddy"

/turf/open/auto_turf/strata_grass/layer0_mud_alt
	icon_state = "grass_0_mud_alt"
	slayer = 0
	variant = "mud_alt"
	variant_prefix_name = "muddy"

/turf/open/auto_turf/strata_grass/layer1
	icon_state = "grass_1"
	slayer = 1

/turf/open/auto_turf/shale
	layer_name = list("wind blown dirt", "volcanic plate rock", "volcanic plate and rock", "this layer does not exist")
	icon = 'icons/turf/floors/auto_shale.dmi'
	icon_prefix = "shale"

/turf/open/auto_turf/shale/get_dirt_type()
	return DIRT_TYPE_SHALE

/turf/open/auto_turf/shale/layer0
	icon_state = "shale_0"
	slayer = 0
	color = "#6699CC"

/turf/open/auto_turf/shale/layer0_puddle
	icon_state = "shale_0_puddle"
	slayer = 0

/turf/open/auto_turf/shale/layer0_plate
	icon_state = "shale_1_alt"
	slayer = 0

/turf/open/auto_turf/shale/layer1
	icon_state = "shale_1"
	slayer = 1

/turf/open/auto_turf/shale/layer2
	icon_state = "shale_2"
	slayer = 2
