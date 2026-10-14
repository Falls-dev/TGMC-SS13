/obj/structure/tent
	name = "TGMC tent"
	desc = "A portable field shelter. Can be torn down with an unfolded entrenching tool."
	icon = 'icons/obj/structures/tents_deployed_classic.dmi'
	layer = BELOW_OBJ_LAYER
	max_integrity = 200
	resistance_flags = XENO_DAMAGEABLE
	obj_flags = CAN_BE_HIT | BLOCKS_CONSTRUCTION | BLOCKS_CONSTRUCTION_DIR
	coverage = 0
	dir = SOUTH
	// Render the entire large sprite when its origin tile is outside the view.
	appearance_flags = PIXEL_SCALE | LONG_GLIDE
	hit_sound = 'sound/effects/rustle1.ogg'
	destroy_sound = 'sound/effects/rustle1.ogg'
	/// Footprint measured from the southwest corner.
	var/x_dim = 2
	var/y_dim = 4
	var/cold_protection_factor = 0.7
	var/roof_state
	var/obj/effect/tent_roof/roof
	/// Clients currently viewing the interior instead of the roof.
	var/list/client/interior_viewers = list()
	var/image/hidden_roof

/obj/structure/tent/Initialize(mapload)
	. = ..()
	bound_width = x_dim * world.icon_size
	bound_height = y_dim * world.icon_size
	switch(SSmapping.configs[GROUND_MAP]?.armor_style)
		if(MAP_ARMOR_STYLE_JUNGLE)
			icon = 'icons/obj/structures/tents_deployed_jungle.dmi'
		if(MAP_ARMOR_STYLE_DESERT)
			icon = 'icons/obj/structures/tents_deployed_desert.dmi'
		if(MAP_ARMOR_STYLE_ICE)
			icon = 'icons/obj/structures/tents_deployed_snow.dmi'
		if(MAP_ARMOR_STYLE_PRISON)
			icon = 'icons/obj/structures/tents_deployed_urban.dmi'
	if(roof_state)
		roof = new(loc)
		roof.icon = icon
		roof.icon_state = roof_state
		hidden_roof = image(icon, roof, roof_state)
		hidden_roof.override = TRUE
		hidden_roof.alpha = 0
	START_PROCESSING(SSobj, src)

/obj/structure/tent/process()
	var/list/client/current_viewers = list()
	for(var/client/viewer as anything in GLOB.clients)
		if(get_turf(viewer.eye) in locs)
			current_viewers += viewer
	for(var/client/viewer as anything in interior_viewers - current_viewers)
		viewer.images -= hidden_roof
	for(var/client/viewer as anything in current_viewers - interior_viewers)
		viewer.images += hidden_roof
	interior_viewers = current_viewers

/obj/structure/tent/Destroy()
	STOP_PROCESSING(SSobj, src)
	for(var/client/viewer as anything in interior_viewers)
		viewer.images -= hidden_roof
	interior_viewers.Cut()
	hidden_roof = null
	QDEL_NULL(roof)
	return ..()

/obj/structure/tent/attackby(obj/item/item, mob/living/user, params)
	if(!istype(item, /obj/item/tool/shovel))
		return ..()
	var/obj/item/tool/shovel/shovel = item
	if(shovel.folded || user.do_actions)
		return TRUE
	visible_message(span_warning("[user] starts tearing down [src]!"))
	if(!do_after(user, 15 SECONDS, NONE, src, BUSY_ICON_HOSTILE))
		return TRUE
	visible_message(span_warning("[user] tears down [src]!"))
	playsound(src, 'sound/effects/rustle1.ogg', 25, TRUE)
	qdel(src)
	return TRUE

/obj/structure/tent/cmd
	name = "TGMC command tent"
	icon_state = "cmd_interior"
	roof_state = "cmd_top"

/obj/structure/tent/med
	name = "TGMC medical tent"
	icon_state = "med_interior"
	roof_state = "med_top"
	var/surgery_speed_mult = 0.9

/obj/structure/tent/big
	name = "large TGMC tent"
	icon_state = "big_interior"
	roof_state = "big_top"
	x_dim = 3

/obj/structure/tent/reqs
	name = "TGMC requisitions tent"
	icon_state = "reqs_interior"
	roof_state = "reqs_top"
	x_dim = 4

/obj/structure/tent/mess
	name = "TGMC mess tent"
	icon_state = "reqs_interior"
	roof_state = "mess_top"
	x_dim = 4

/// Separate roof permits a per-client override without hiding the interior.
/obj/effect/tent_roof
	anchored = TRUE
	layer = ABOVE_TREE_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = PIXEL_SCALE | LONG_GLIDE

/obj/structure/tent/projectile_hit(atom/movable/projectile/proj, cardinal_move, uncrossing)
	return FALSE
