/obj/vehicle/ridden/big_bike
	name = "big bike"
	desc = "A TGMC heavy motorbike. Used to swiftly carry up to 2 soldiers over the roughest of terrain, at high speed and with respectable survivibility. Is typically armed with a pair of forwarded mounted weapons. Favoured for rapid assaults."
	icon = 'icons/obj/vehicles/big_bike.dmi'
	icon_state = "big_bike"
	max_integrity = 425
	soft_armor = list(MELEE = 45, BULLET = 50, LASER = 50, ENERGY = 60, BOMB = 60, FIRE = 80, ACID = 40)
	resistance_flags = XENO_DAMAGEABLE
	atom_flags = PREVENT_CONTENTS_EXPLOSION
	key_type = null
	coverage = 60
	layer = MOB_BELOW_PIGGYBACK_LAYER
	allow_pass_flags = PASSABLE
	pass_flags = PASS_LOW_STRUCTURE
	buckle_flags = CAN_BUCKLE|BUCKLE_NEEDS_HAND
	max_buckled_mobs = 2
	max_occupants = 2
	pixel_w = -17
	pixel_z = -12
	attachments_by_slot = list(ATTACHMENT_SLOT_STORAGE, ATTACHMENT_SLOT_WEAPON)
	attachments_allowed = list(/obj/item/vehicle_module/storage/motorbike, /obj/item/vehicle_module/mounted_gun/autocannon)
	starting_attachments = list(/obj/item/vehicle_module/storage/motorbike, /obj/item/vehicle_module/mounted_gun/autocannon)
	COOLDOWN_DECLARE(rev_cooldown)
	/// The looping sound that plays when the bike is operating
	var/datum/looping_sound/bike_idle/engine_sound

/obj/vehicle/ridden/big_bike/Initialize(mapload)
	. = ..()
	engine_sound = new()
	AddElement(/datum/element/ridable, /datum/component/riding/vehicle/big_bike)
	update_icon()

/obj/vehicle/ridden/big_bike/Destroy()
	if(isdatum(engine_sound))
		QDEL_NULL(engine_sound)
	return ..()

/obj/vehicle/ridden/big_bike/examine(mob/user)
	. = ..()
	if(!ishuman(user))
		return
	. += "To access internal storage click with an empty hand or drag the bike onto self."

/obj/vehicle/ridden/big_bike/update_overlays()
	. = ..()
	. += mutable_appearance(icon, "big_bike_toplayer", TANK_DECORATION_LAYER)
	. += mutable_appearance(icon, "big_bike_midlayer", MOB_ABOVE_PIGGYBACK_LAYER)

/obj/vehicle/ridden/big_bike/post_unbuckle_mob(mob/living/M)
	remove_occupant(M)
	M.remove_pass_flags(pass_flags, BIGBIKE_TRAIT)
	if(!length(occupants))
		engine_sound.stop(src)
	return ..()

/obj/vehicle/ridden/big_bike/post_buckle_mob(mob/living/M)
	add_occupant(M)
	M.add_pass_flags(pass_flags, BIGBIKE_TRAIT)
	if(is_driver(M))
		engine_sound.start(src)
	return ..()

/obj/vehicle/ridden/big_bike/auto_assign_occupant_flags(mob/M)
	. = ..()
	if(!is_driver(M))
		return
	add_control_flags(M, VEHICLE_CONTROL_EQUIPMENT)

/obj/vehicle/ridden/big_bike/welder_act(mob/living/user, obj/item/I)
	return welder_repair_act(user, I, 15, 3 SECONDS, fuel_req = 1)

/obj/vehicle/ridden/big_bike/obj_destruction(damage_amount, damage_type, damage_flag, mob/living/blame_mob)
	cell_explosion(get_turf(src), 100, 25)
	return ..()

/obj/vehicle/ridden/big_bike/AltClick(mob/user)
	if(!is_driver(user))
		return FALSE
	if(!COOLDOWN_FINISHED(src, rev_cooldown))
		return FALSE
	COOLDOWN_START(src, rev_cooldown, 3 SECONDS)
	to_chat(user, span_notice("You rev the [src]'s engine."))
	playsound(src, pick('sound/vehicles/bikerev-1.ogg', 'sound/vehicles/bikerev-2.ogg', 'sound/vehicles/bikerev-3.ogg', 'sound/vehicles/bikerev-4.ogg'), 50, TRUE, falloff = 3)
	return TRUE

/obj/vehicle/ridden/hover_bike
	name = "hover bike"
	desc = "A SOM light hovercraft. Used to swiftly carry up to 2 soldiers over the roughest of terrain, or light defences. Is typically armed with a pair of forwarded mounted weapons. Favoured for rapid assaults."
	icon = 'icons/obj/vehicles/hover_bike.dmi'
	icon_state = "hover_bike"
	max_integrity = 325
	soft_armor = list(MELEE = 45, BULLET = 50, LASER = 50, ENERGY = 60, BOMB = 60, FIRE = 80, ACID = 40)
	resistance_flags = XENO_DAMAGEABLE
	atom_flags = PREVENT_CONTENTS_EXPLOSION
	key_type = null
	coverage = 60
	layer = MOB_BELOW_PIGGYBACK_LAYER
	allow_pass_flags = PASSABLE
	pass_flags = PASS_LOW_STRUCTURE|PASS_DEFENSIVE_STRUCTURE|PASS_FIRE
	buckle_flags = CAN_BUCKLE|BUCKLE_NEEDS_HAND
	max_buckled_mobs = 2
	max_occupants = 2
	pixel_w = -22
	pixel_z = -22
	attachments_by_slot = list(ATTACHMENT_SLOT_STORAGE, ATTACHMENT_SLOT_WEAPON)
	attachments_allowed = list(/obj/item/vehicle_module/storage/motorbike, /obj/item/vehicle_module/mounted_gun/volkite, /obj/item/vehicle_module/mounted_gun/minigun)
	starting_attachments = list(/obj/item/vehicle_module/storage/motorbike, /obj/item/vehicle_module/mounted_gun/volkite)
	/// The looping sound that plays when the bike is operating
	var/datum/looping_sound/som_tank_drive/hover_bike/engine_sound

/obj/vehicle/ridden/hover_bike/Initialize(mapload)
	. = ..()
	engine_sound = new()
	AddElement(/datum/element/ridable, /datum/component/riding/vehicle/hover_bike)
	add_filter("shadow", 2, drop_shadow_filter(0, -8, 1))
	update_icon()
	animate_hover()

/obj/vehicle/ridden/hover_bike/Destroy()
	QDEL_NULL(engine_sound)
	return ..()

/obj/vehicle/ridden/hover_bike/examine(mob/user)
	. = ..()
	if(!ishuman(user))
		return
	. += "To access internal storage click with an empty hand or drag the bike onto self."

/obj/vehicle/ridden/hover_bike/update_overlays()
	. = ..()
	. += mutable_appearance(icon, "hover_bike_toplayer", TANK_DECORATION_LAYER)
	. += mutable_appearance(icon, "hover_bike_midlayer", MOB_ABOVE_PIGGYBACK_LAYER)

/obj/vehicle/ridden/hover_bike/post_unbuckle_mob(mob/living/M)
	remove_occupant(M)
	M.remove_pass_flags(pass_flags, HOVERBIKE_TRAIT)
	if(!length(occupants))
		engine_sound.stop(src)
	. = ..()
	animate_hover()
	animate(M)

/obj/vehicle/ridden/hover_bike/post_buckle_mob(mob/living/M)
	add_occupant(M)
	M.add_pass_flags(pass_flags, HOVERBIKE_TRAIT)
	if(is_driver(M))
		engine_sound.start(src)
	. = ..()
	animate_hover()

/obj/vehicle/ridden/hover_bike/auto_assign_occupant_flags(mob/M)
	. = ..()
	if(!is_driver(M))
		return
	add_control_flags(M, VEHICLE_CONTROL_EQUIPMENT)

/obj/vehicle/ridden/hover_bike/welder_act(mob/living/user, obj/item/I)
	return welder_repair_act(user, I, 15, 3 SECONDS, fuel_req = 1)

/obj/vehicle/ridden/hover_bike/obj_destruction(damage_amount, damage_type, damage_flag, mob/living/blame_mob)
	cell_explosion(get_turf(src), 100, 25)
	return ..()

/obj/vehicle/ridden/hover_bike/lava_act()
	return //we flying baby

///Animates the bob for the bike and its occupants

/obj/vehicle/ridden/hover_bike/proc/animate_hover()
	var/list/hover_list = list(src)
	if(length(occupants))
		hover_list += occupants
	for(var/atom/atom AS in hover_list)
		animate(atom, time = 1.2 SECONDS, loop = -1, easing = SINE_EASING, flags = ANIMATION_RELATIVE|ANIMATION_END_NOW, pixel_z = 3)
		animate(time = 1.2 SECONDS, loop = -1, easing = SINE_EASING, flags = ANIMATION_RELATIVE, pixel_z = -3)

/datum/looping_sound/bike_idle
	mid_sounds = list(
		'sound/vehicles/bikeidle-1.ogg'=1,
		'sound/vehicles/bikeidle-2.ogg'=1,
		'sound/vehicles/bikeidle-3.ogg'=1,
		'sound/vehicles/bikeidle-4.ogg'=1,
		'sound/vehicles/bikeidle-5.ogg'=1,
		'sound/vehicles/bikeidle-6.ogg'=1,
	)
	mid_length = 1 SECONDS
	start_sound = 'sound/vehicles/bikestart.ogg'
	start_length = 1 SECONDS
	volume = 25

/datum/looping_sound/som_tank_drive/hover_bike
	mid_length = 10 //The freq change makes ugly gaps otherwise, but this still isn't perfect
	vary = TRUE
	volume = 30
