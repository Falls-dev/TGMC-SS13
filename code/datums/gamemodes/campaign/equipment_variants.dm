// Equipment variants required by Campaign.

/obj/item/clothing/suit/modular/robot/tyr_two
	starting_attachments = list(
		/obj/item/armor_module/module/tyr_extra_armor,
		/obj/item/armor_module/storage/engineering,
	)


//helmet

/obj/item/clothing/suit/modular/robot/shield_overclocked
	starting_attachments = list(
		/obj/item/armor_module/module/eshield/overclocked,
		/obj/item/armor_module/storage/engineering,
	)

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
	RegisterSignal(src, COMSIG_MOVABLE_PATROL_DEPLOYED, PROC_REF(animate_hover))

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

/obj/item/weapon/sword/officersword
	name = "officers sword"
	desc = "This appears to be a rather old blade that has been well taken care of, it is probably a family heirloom. Oddly despite its probable non-combat purpose it is sharpened and not blunt."
	icon_state = "officer_sword"
	worn_icon_state = "officer_sword"
	force = 75
	attack_speed = 11
	penetration = 15
	w_class = WEIGHT_CLASS_BULKY

/obj/item/weapon/sword/officersword/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/strappable)

/obj/item/clothing/suit/modular/xenonauten/light/shield_overclocked
	starting_attachments = list(
		/obj/item/armor_module/module/eshield/overclocked,
		/obj/item/armor_module/storage/medical,
	)

/obj/item/clothing/suit/modular/xenonauten/light/shield_overclocked/medic
	starting_attachments = list(
		/obj/item/armor_module/module/eshield/overclocked,
		/obj/item/armor_module/storage/general,
	)

/obj/item/clothing/suit/modular/xenonauten/light/shield_overclocked/engineer
	starting_attachments = list(
		/obj/item/armor_module/module/eshield/overclocked,
		/obj/item/armor_module/storage/engineering,
	)

/obj/item/clothing/head/modular/m10x/medium
	name = "\improper Knight Class Helmet"
	soft_armor = MARINE_ARMOR_HEAVY

/obj/item/clothing/suit/modular/xenonauten/shield_overclocked
	starting_attachments = list(
		/obj/item/armor_module/module/eshield/overclocked,
		/obj/item/armor_module/storage/medical,
	)

/obj/item/clothing/suit/modular/xenonauten/shield_overclocked/medic
	starting_attachments = list(
		/obj/item/armor_module/module/eshield/overclocked,
		/obj/item/armor_module/storage/general,
	)

/obj/item/clothing/suit/modular/xenonauten/shield_overclocked/engineer
	starting_attachments = list(
		/obj/item/armor_module/module/eshield/overclocked,
		/obj/item/armor_module/storage/engineering,
	)

/obj/item/clothing/suit/modular/xenonauten/heavy/shield_overclocked
	starting_attachments = list(
		/obj/item/armor_module/module/eshield/overclocked,
		/obj/item/armor_module/storage/medical,
	)

/obj/item/clothing/head/modular/m10x/leader/fcdr
	name = "\improper King Class Helmet"

/obj/item/clothing/head/modular/m10x/pyro
	name = "\improper Jester Class Helmet"
	desc = "A bulky helmet with an integrated gas mask and a 'Surt' armor module for fireproofing, fielded to TDF flamethrower operators."
	soft_armor = list(MELEE = 45, BULLET = 65, LASER = 60, ENERGY = 60, BOMB = 50, BIO = 50, FIRE = 100, ACID = 50)

/obj/item/clothing/head/modular/m10x/sg
	name = "\improper Spade Class Helmet"
	desc = "A helmet loaded with sensors and targeting computers to assist the smartgun at shooting things."

/obj/item/clothing/head/modular/m10x/sg/tyr
	soft_armor = list(MELEE = 60, BULLET = 80, LASER = 80, ENERGY = 75, BOMB = 60, BIO = 60, FIRE = 55, ACID = 75)

/obj/item/clothing/head/modular/m10x/heavy/tyr
	soft_armor = list(MELEE = 60, BULLET = 80, LASER = 80, ENERGY = 75, BOMB = 60, BIO = 60, FIRE = 55, ACID = 75)

/obj/item/clothing/suit/modular/xenonauten/heavy/tyr_two/corpsman
	starting_attachments = list(
		/obj/item/armor_module/module/tyr_extra_armor,
		/obj/item/armor_module/storage/general,
	)

/obj/item/clothing/suit/modular/xenonauten/heavy/tyr_two/engineer
	starting_attachments = list(
		/obj/item/armor_module/module/tyr_extra_armor,
		/obj/item/armor_module/storage/engineering,
	)

/obj/item/clothing/head/modular/m10x/medic
	name = "\improper Heart Class Helmet"
	desc = "A distinct helmet paired with the 'Mimir' armor module for additional protection against biological attacks, helps indicate your a medic and also helps indicate you as a priority target."
	soft_armor = list(MELEE = 45, BULLET = 65, LASER = 60, ENERGY = 60, BOMB = 50, BIO = 75, FIRE = 50, ACID = 70)

/obj/item/clothing/head/modular/m10x/engi/welding
	starting_attachments = list(/obj/item/armor_module/storage/helmet, /obj/item/armor_module/module/welding)

/obj/item/clothing/suit/modular/xenonauten/heavy/leader/shield_overclocked
	starting_attachments = list(
		/obj/item/armor_module/module/eshield/overclocked,
		/obj/item/armor_module/storage/medical,
	)

/obj/item/clothing/suit/modular/xenonauten/heavy/leader/shield
	starting_attachments = list(
		/obj/item/armor_module/module/eshield,
		/obj/item/armor_module/storage/medical,
	)

/obj/item/explosive/grenade/smokebomb/cloak/som
	name = "\improper S30-C smoke grenade"
	desc = "A sophisticated version of the S30-S with a slighty improved smoke screen payload. It's set to detonate in 2 seconds."
	icon_state = "grenade_cloak_som"
	worn_icon_state = "grenade_cloak_som"

/datum/skills/ce
	name = CHIEF_SHIP_ENGINEER
	engineer = SKILL_ENGINEER_MASTER
	construction = SKILL_CONSTRUCTION_MASTER
	leadership = SKILL_LEAD_TRAINED
	police = SKILL_POLICE_MP
	powerloader = SKILL_POWERLOADER_MASTER

/datum/ammo/tx54/smoke/acid
	name = "20mm acid grenade"
	hud_state = "grenade_acid"
	bonus_projectiles_type = /datum/ammo/bullet/tx54_spread/smoke/acid
	handful_greyscale_colors = COLOR_AMMO_ACID
	projectile_greyscale_colors = COLOR_AMMO_ACID

/datum/ammo/bullet/spottingrifle/incendiary
	name = "smart incendiary spotting  bullet"
	hud_state = "spotrifle_incend"
	ammo_behavior_flags = AMMO_BALLISTIC|AMMO_INCENDIARY
	damage_type = BURN
	damage = 10
	sundering = 0.5

/datum/ammo/bullet/spottingrifle/tungsten
	name = "smart tungsten spotting bullet"
	hud_state = "spotrifle_tungsten"
	damage = 10
	sundering = 0.5

/datum/ammo/bullet/spottingrifle/tungsten/on_hit_mob(mob/target_mob, atom/movable/projectile/proj)
	staggerstun(target_mob, proj, knockback = 3, max_range = 12)

/datum/ammo/bullet/spottingrifle/highimpact
	name = "smart high-impact spotting bullet"
	hud_state = "spotrifle_impact"
	damage = 10
	sundering = 0.5

/datum/ammo/bullet/spottingrifle/highimpact/on_hit_mob(mob/target_mob, atom/movable/projectile/proj)
	staggerstun(target_mob, proj, stagger = 1 SECONDS, slowdown = 1, max_range = 12)

/datum/ammo/bullet/shotgun/tx15_flechette
	name = "shotgun flechette shell"
	handful_icon_state = "shotgun_flechette"
	icon_state = "flechette"
	hud_state = "shotgun_flechette"
	ammo_behavior_flags = AMMO_BALLISTIC
	bonus_projectiles_type = /datum/ammo/bullet/shotgun/tx15_flechette/spread
	bonus_projectiles_amount = 4
	bonus_projectiles_scatter = 2
	max_range = 15
	damage = 17
	damage_falloff = 0.25
	penetration = 20
	sundering = 1.5

/datum/ammo/bullet/shotgun/tx15_flechette/spread
	name = "additional flechette"

/datum/ammo/tx54/tank_canister/incendiary
	name = "incendiary canister"
	icon_state = "canister_shot"
	hud_state = "grenade_fire"
	projectile_greyscale_colors = "#5f2702"
	bonus_projectiles_type = /datum/ammo/bullet/tx54_spread/tank_canister/incendiary
	bonus_projectiles_scatter = 4
	bonus_projectile_quantity = 12

/datum/ammo/bullet/minigun/ltaap/hv
	damage = 35
	penetration = 30
	ammo_behavior_flags = AMMO_BALLISTIC
	hud_state = "hivelo_impact"
	hud_state_empty = "hivelo_empty"

/obj/item/vehicle_module/mounted_gun/autocannon
	name = "dual V-44 light gatling guns"
	desc = "A pair of triple barreled 'light' gatling guns designed to be mounted in light vehicles such as the SOM hover bikes. A smaller calibre round is used for optimal internal magazine capacity, but makes up for this with a ferocious rate of fire."
	icon = 'icons/obj/vehicles/big_bike.dmi'
	icon_state = "bike_autocannon"
	should_use_obj_appeareance = FALSE
	mounted_gun = /obj/item/weapon/gun/bike_autocannon

/obj/item/vehicle_module/mounted_gun/volkite
	name = "mounted Demi-Culverin"
	desc = "A paired set of volkite weapons mounted into light vehicles such as SOM hover bikes. While they lack the raw power of some other volkite weapons, they make up for this through sheer volume of fire and integrate recharging power source."
	icon = 'icons/obj/vehicles/hover_bike.dmi'
	icon_state = "bike_volkite"
	should_use_obj_appeareance = FALSE
	mounted_gun = /obj/item/weapon/gun/energy/lasgun/lasrifle/volkite/demi_culverin

///bike volkite

/obj/item/vehicle_module/mounted_gun/minigun
	name = "dual V-44 light gatling guns"
	desc = "A pair of triple barreled 'light' gatling guns designed to be mounted in light vehicles such as SOM hover bikes. A smaller calibre round is used for optimal internal magazine capacity, but makes up for this with a ferocious rate of fire."
	icon = 'icons/obj/vehicles/hover_bike.dmi'
	icon_state = "bike_minigun"
	should_use_obj_appeareance = FALSE
	mounted_gun = /obj/item/weapon/gun/bike_minigun

/obj/item/attachable/stock/tx15
	name = "\improper SH-15 stock"
	desc = "The standard stock for the SH-15. Cannot be removed."
	icon_state = "tx15"
	pixel_shift_x = 32
	pixel_shift_y = 13

/obj/item/attachable/stock/t18stock
	name = "\improper AR-18 stock"
	desc = "A specialized stock for the AR-18."
	icon_state = "t18"
	pixel_shift_x = 32
	pixel_shift_y = 13

/obj/item/attachable/stock/t12stock
	name = "\improper AR-12 stock"
	desc = "A specialized stock for the AR-12."
	icon_state = "t12"
	pixel_shift_x = 32
	pixel_shift_y = 13

/obj/item/attachable/stock/t64stock
	name = "\improper BR-64 stock"
	desc = "A specialized stock for the BR-64."
	icon_state = "t64"

//You can remove the stock on the Magnum. So it has stats and is removeable.

/obj/item/attachable/bayonet/som
	name = "\improper S20 SOM bayonet"
	desc = "A large knife that is the standard issue combat knife of the SOM. Can be attached to a variety of weapons at will or used as a standard knife."
	icon_state = "bayonetknife_som"
	worn_icon_state = "bayonetknife"
	force = 30

/obj/item/attachable/foldable/t19stock
	name = "\improper MP-19 machinepistol stock"
	desc = "A submachinegun stock distributed in small numbers to TGMC forces. Compatible with the MP-19, this stock reduces recoil and improves accuracy, but at a reduction to handling and agility. Seemingly a bit more effective in a brawl."
	attach_features_flags = ATTACH_ACTIVATION
	wield_delay_mod = 0.1 SECONDS
	melee_mod = 5
	size_mod = 1
	icon_state = "t19"
	accuracy_mod = 0.3
	recoil_mod = -2
	scatter_mod = -8
	accuracy_unwielded_mod = -0.1
	scatter_unwielded_mod = 4

/obj/item/attachable/bayonet/converted
	name = "bayonet"
	desc = "A sharp blade for mounting on a weapon. It can be used to stab manually on anything but harm intent. Slightly reduces the accuracy of the gun when mounted."
	icon_state = "bayonet"
	force = 20
	throwforce = 10
	pixel_shift_x = 14
	pixel_shift_y = 18

/obj/item/attachable/bayonet/converted/screwdriver_act(mob/living/user, obj/item/I)
	to_chat(user, span_notice("You modify the bayonet back into a combat knife."))
	if(loc == user)
		user.dropItemToGround(src)
	var/obj/item/weapon/combat_knife/knife = new(loc)
	user.put_in_hands(knife) //This proc tries right, left, then drops it all-in-one.
	if(knife.loc != user) //It ended up on the floor, put it whereever the old flashlight is.
		knife.forceMove(loc)
	qdel(src)

/obj/item/attachable/stock/t27
	name = "MG-27 Body"
	desc = "A stock for a MG-27 MMG."
	icon_state = "t27"
	pixel_shift_x = 15
	pixel_shift_y = 0

/obj/item/attachable/scope/unremovable/mmg
	name = "MG-27 rail scope"
	icon_state = "mini"
	desc = "A small rail mounted zoom sight scope. Allows zoom by activating the attachment."
	wield_delay_mod = 0.2 SECONDS
	aim_speed_mod = 0.2
	scoped_accuracy_mod = SCOPE_RAIL_MINI
	zoom_slowdown = 0.3
	zoom_tile_offset = 5
	zoom_viewsize = 0

/datum/action/minimap/som
	minimap_flags = MINIMAP_FLAG_MARINE_SOM
	marker_flags = MINIMAP_FLAG_MARINE_SOM

/datum/ammo/bullet/tx54_spread/smoke/acid
	trail_spread_system = /datum/effect_system/smoke_spread/xeno/acid

/datum/ammo/bullet/tx54_spread/tank_canister/incendiary
	name = "incendiary canister shot"
	ammo_behavior_flags = parent_type::ammo_behavior_flags|AMMO_INCENDIARY|AMMO_LEAVE_TURF
	bullet_color = COLOR_LIGHT_ORANGE
	damage = 25

/datum/ammo/bullet/tx54_spread/tank_canister/incendiary/on_leave_turf(turf/target_turf, atom/movable/projectile/proj)
	if(prob(35))
		drop_flame(target_turf)

/datum/ammo/bullet/smarttargetrifle
	name = "smart marksman bullet"
	icon_state = "bullet_red"
	bullet_color = COLOR_SOFT_RED //Red bullets to indicate friendly fire restriction
	hud_state = "smartgun"
	hud_state_empty = "smartgun_empty"
	ammo_behavior_flags = AMMO_BALLISTIC
	damage = 40
	max_range = 40
	penetration = 30
	sundering = 5
	shell_speed = 4
	damage_falloff = 0.5
	accurate_range = 25
	accurate_range_min = 3

/datum/ammo/bullet/revolver/tp44
	name = "standard revolver bullet"
	damage = 40
	penetration = 15
	sundering = 1

/datum/ammo/bullet/revolver/tp44/on_hit_mob(mob/target_mob, atom/movable/projectile/proj)
	staggerstun(target_mob, proj, knockback = 1)

/obj/item/weapon/gun/bike_autocannon
	name = "dual AC-32 light autocannons"
	desc = "A pair of 20mm autocannons, designed to be mounted on light vehicles such as the heavy motorbike. It packs a heavy punch, providing formidable firepower and a large internal magazine."
	icon = 'icons/obj/vehicles/vehicle_weapons.dmi'
	icon_state = "bike_autocannon"
	worn_icon_state = null
	max_shells = 150
	caliber = CALIBER_20
	load_method = MAGAZINE
	fire_sound = 'sound/weapons/guns/fire/hmg2.ogg'
	reload_sound = 'sound/weapons/guns/interact/minigun_cocked.ogg'
	default_ammo_type = /obj/item/ammo_magazine/bike_autocannon
	allowed_ammo_types = list(/obj/item/ammo_magazine/bike_autocannon)
	w_class = WEIGHT_CLASS_HUGE
	gun_skill_category = SKILL_HEAVY_WEAPONS
	item_flags = NONE
	equip_slot_flags = NONE
	gun_features_flags = GUN_AMMO_COUNTER|GUN_SMOKE_PARTICLES
	reciever_flags = AMMO_RECIEVER_CYCLE_ONLY_BEFORE_FIRE|AMMO_RECIEVER_MAGAZINES
	gun_firemode_list = list(GUN_FIREMODE_AUTOMATIC)

	fire_delay = 0.2 SECONDS

	recoil_unwielded = -2
	scatter_unwielded = 4
	damage_falloff_mult = 0.4
	movement_acc_penalty_mult = 2

/obj/item/weapon/gun/energy/lasgun/lasrifle/volkite/demi_culverin
	name = "\improper VX-42b Demi-Culverin"
	desc = "A paired set of volkite weapons mounted into light vehicles such as SOM hover bikes. While they lack the raw power of some other volkite weapons, they make up for this through sheer volume of fire and integrate recharging power source."
	icon = 'icons/obj/vehicles/vehicle_weapons.dmi'
	icon_state = "bike_volkite"
	worn_icon_state = null
	allowed_ammo_types = list(/obj/item/cell/lasgun/volkite/turret/hover_bike)
	default_ammo_type = /obj/item/cell/lasgun/volkite/turret/hover_bike
	attachable_allowed = null
	item_flags = NONE
	gun_features_flags = GUN_AMMO_COUNTER|GUN_ENERGY|GUN_AMMO_COUNT_BY_SHOTS_REMAINING
	reciever_flags = AMMO_RECIEVER_MAGAZINES|AMMO_RECIEVER_DO_NOT_EJECT_HANDFULS|AMMO_RECIEVER_CYCLE_ONLY_BEFORE_FIRE|AMMO_RECIEVER_CLOSED|AMMO_RECIEVER_AUTO_EJECT_LOCKED
	ammo_level_icon = null
	gun_skill_category = SKILL_HEAVY_WEAPONS
	ammo_datum_type = /datum/ammo/energy/volkite/demi_culverin
	rounds_per_shot = 20
	fire_delay = 0.1 SECONDS
	accuracy_mult_unwielded = 1
	scatter_unwielded = 8
	recoil_unwielded = -2
	damage_falloff_mult = 0.4
	movement_acc_penalty_mult = 3

/obj/item/weapon/gun/bike_minigun
	name = "dual V-44 light gatling guns"
	desc = "A pair of triple barreled 'light' gatling guns designed to be mounted in light vehicles such as SOM hover bikes. A smaller calibre round is used for optimal internal magazine capacity, but makes up for this with a ferocious rate of fire."
	icon = 'icons/obj/vehicles/vehicle_weapons.dmi'
	icon_state = "bike_minigun"
	worn_icon_state = null
	fire_animation = "minigun_fire"
	max_shells = 500 //codex
	caliber = CALIBER_762X51 //codex
	load_method = MAGAZINE //codex
	fire_sound = 'sound/weapons/guns/fire/minigun.ogg'
	unload_sound = 'sound/weapons/guns/interact/minigun_unload.ogg'
	reload_sound = 'sound/weapons/guns/interact/minigun_reload.ogg'
	cocked_sound = 'sound/weapons/guns/interact/minigun_cocked.ogg'
	default_ammo_type = /obj/item/ammo_magazine/bike_minigun
	allowed_ammo_types = list(/obj/item/ammo_magazine/bike_minigun)
	w_class = WEIGHT_CLASS_HUGE
	gun_skill_category = SKILL_HEAVY_WEAPONS
	item_flags = NONE
	equip_slot_flags = NONE
	gun_features_flags = GUN_AMMO_COUNTER|GUN_SMOKE_PARTICLES
	reciever_flags = AMMO_RECIEVER_CYCLE_ONLY_BEFORE_FIRE|AMMO_RECIEVER_MAGAZINES
	gun_firemode_list = list(GUN_FIREMODE_AUTOMATIC)

	fire_delay = 0.1 SECONDS
	windup_delay = 0.3 SECONDS
	windup_sound = 'sound/weapons/guns/fire/tank_minigun_start.ogg'

	recoil_unwielded = -2
	scatter_unwielded = 10
	damage_falloff_mult = 0.4
	movement_acc_penalty_mult = 2

//

/datum/ammo/energy/volkite/demi_culverin
	max_range = 18
	accurate_range = 7
	damage = 15

/datum/ammo/bullet/spottingrifle/heavyrubber
	name = "smart heavy-rubber spotting bullet"
	hud_state = "spotrifle_rubber"
	damage = 10
	sundering = 0.5

/datum/ammo/bullet/spottingrifle/heavyrubber/on_hit_mob(mob/target_mob, atom/movable/projectile/proj)
	staggerstun(target_mob, proj, paralyze = 1 SECONDS, slowdown = 1, max_range = 12)

/datum/ammo/bullet/spottingrifle/plasmaloss
	name = "smart tanglefoot spotting bullet"
	hud_state = "spotrifle_plasmaloss"
	damage = 10
	sundering = 0.5

/datum/ammo/bullet/spottingrifle/plasmaloss/on_hit_mob(mob/target_mob, atom/movable/projectile/proj)
	if(isxeno(target_mob))
		var/mob/living/carbon/xenomorph/target_xeno = target_mob
		target_xeno.use_plasma(20 + 0.2 * target_xeno.xeno_caste.plasma_max * target_xeno.xeno_caste.plasma_regen_limit) // This is draining 20%+20 flat per hit.

/datum/ammo/bullet/spottingrifle/flak
	name = "smart flak spotting bullet"
	hud_state = "spotrifle_flak"
	damage = 60
	sundering = 0.5

/datum/ammo/bullet/spottingrifle/flak/on_hit_mob(mob/target_mob, atom/movable/projectile/proj)
	airburst(target_mob, proj, 30)

/datum/ammo/bullet/bike_autocannon
	name = "autocannon high-velocity bullet"
	hud_state = "minigun"
	hud_state_empty = "smartgun_empty"
	ammo_behavior_flags = AMMO_BALLISTIC
	damage = 30
	penetration = 25
	sundering = 1
	max_range = 15

/datum/ammo/bullet/minigun_light
	name = "minigun bullet"
	hud_state = "minigun"
	hud_state_empty = "smartgun_empty"
	accurate_range = 6
	damage = 16
	penetration = 15
	shrapnel_chance = 15
	sundering = 1.5

/datum/ammo/bullet/rifle/standard_br
	name = "light marksman bullet"
	hud_state = "hivelo"
	hud_state_empty = "hivelo_empty"
	ammo_behavior_flags = AMMO_BALLISTIC
	penetration = 15
	damage = 32.5
	sundering = 1.25

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

/obj/structure/barricade/folding/capsule
	name = "capsule-deployed folding plasteel barricade"
	desc = parent_type::desc + " Deconstruction will yield less materials due to being deployed via capsule."
	stack_amount = 4

/obj/structure/barricade/solid/capsule
	name = "capsule-deployed metal barricade"
	desc = parent_type::desc + " Deconstruction will yield less materials due to being deployed via capsule."
	stack_amount = 3

/obj/structure/barricade/wooden
	parent_type = /obj/structure/barricade/wood

/obj/structure/sign/double/barsign
	icon = 'icons/obj/structures/barsigns.dmi'
	icon_state = "off"

/obj/structure/sign/double/barsign/carp
	name = "The Drunk Carp"
	desc = "The Drunk Carp, Bar and Grill"
	icon_state = "thedrunkcarp"

/obj/structure/sign/double/barsign/Initialize(mapload)
	. = ..()
	icon = 'icons/obj/structures/barsigns.dmi'

/obj/effect/urban/decal/dirt_2
	icon = 'icons/turf/desertdam_map.dmi'
	icon_state = "dirt_2"

/obj/effect/urban/decal/road/lines3
	icon = 'icons/turf/desertdam_map.dmi'
	icon_state = "Z_S3"

/obj/structure/table/urban/shiny_black
	name = "shiny black metal table"
	desc = "A shiny black metallic surface resting on four legs, looks like it belongs in a boardroom. Useful to put stuff on. Can be flipped in emergencies to act as cover."
	icon = 'icons/obj/smooth_objects/urban_table_black.dmi'
	icon_state = "urban_table_black-0"
	base_icon_state = "urban_table_black"
	parts = /obj/item/frame/table

/obj/structure/table/urban/shiny_brown
	name = "shiny brown metal table"
	desc = "A shiny brown metallic surface resting on four legs, looks like it belongs in a boardroom. Useful to put stuff on. Can be flipped in emergencies to act as cover."
	icon = 'icons/obj/smooth_objects/urban_table_brown.dmi'
	icon_state = "urban_table_brown-0"
	base_icon_state = "urban_table_brown"
	parts = /obj/item/frame/table

/obj/effect/urban/decal/road/lines1
	icon = 'icons/turf/desertdam_map.dmi'
	icon_state = "Z_W1"

/obj/structure/prop/urban/misc/blood
	name = "blood"
	icon = 'icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "wallblood_floorblood"

/obj/structure/prop/urban/misc/blood/blood1
	icon = 'icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "wallblood_floorblood"

/obj/structure/prop/urban/misc/blood/blood2
	icon = 'icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "wall_blood_1"

/obj/structure/prop/urban/misc/blood/blood3
	icon = 'icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "wall_blood_2"

// Fire

/obj/effect/urban/decal/trash //curse you zenith for never defining any of your 16 trash additions
	name = "garbage"
	desc = "Some trash plastered to the ground."
	icon = 'icons/turf/desertdam_map.dmi'
	icon_state = "trash_1"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/urban/decal/trash/two
	icon_state = "trash_2"

/obj/effect/urban/decal/trash/three
	icon_state = "trash_3"

/obj/effect/urban/decal/trash/four
	icon_state = "trash_4"

/obj/effect/urban/decal/trash/five
	icon_state = "trash_5"

/obj/effect/urban/decal/trash/six
	icon_state = "trash_6"

/obj/effect/urban/decal/trash/seven
	icon_state = "trash_7"

/obj/effect/urban/decal/trash/eight
	icon_state = "trash_8"

/obj/effect/urban/decal/trash/nine
	icon_state = "trash_9"

/obj/effect/urban/decal/trash/ten
	icon_state = "trash_10"

/obj/effect/urban/decal/trash/eleven
	icon_state = "trash_11"

/obj/effect/urban/decal/trash/twelve
	icon_state = "trash_12"

/obj/effect/urban/decal/trash/thirteen
	icon_state = "trash_13"

/obj/effect/urban/decal/trash/fourteen
	icon_state = "trash_14"

/obj/effect/urban/decal/trash/fifteen
	icon_state = "trash_15"

/obj/effect/urban/decal/trash/sixteen
	icon_state = "trash_16"

/obj/effect/urban/decal/trash/seventeen
	icon_state = "trash_17"

/// Engineer_ship

/obj/effect/urban/decal/road/road_stop/one
	name = "road"
	icon_state = "thin_road_stop_decal1"

/obj/structure/bed/urban/bunkbed3
	name = "bunk bed"
	desc = "A comfy looking bunk-bed."
	icon_state = "zbunkbed3"

/obj/effect/urban/decal/dirt
	icon = 'icons/turf/desertdam_map.dmi'
	icon_state = "dirt"

/obj/effect/urban/decal/road/lines2
	icon = 'icons/turf/desertdam_map.dmi'
	icon_state = "Z_N2"

/obj/effect/urban/decal/road/road_stop
	name = "road"
	icon_state = "thin_road_stop_decal"

/obj/effect/urban/decal/road/road_stop/two
	name = "road"
	icon_state = "thin_road_stop_decal2"

/obj/effect/urban/decal/road/road_stop/three
	name = "road"
	icon_state = "thin_road_stop_decal3"

/obj/effect/urban/decal/road/road_stop/five
	name = "road"
	icon_state = "thin_stop_decal5"

/////

/obj/effect/urban/decal/road/road_stop/regular/five
	name = "road"
	icon_state = "thin_stop_decal5"

// Double Roadlines

/obj/effect/urban/decal/bloodtrail
	icon = 'icons/turf/desertdam_map.dmi'
	icon_state = "bloodtrail"

/obj/structure/prop/urban/supermart/rack/longrack6
	name = "shelf"
	desc = "A long shelf filled with various foodstuffs"
	icon_state = "longrack6"

/obj/structure/prop/urban/misc/buildinggreeblies/greeble12/dense
	density = TRUE

/obj/effect/urban/decal/road/lines4
	icon = 'icons/turf/desertdam_map.dmi'
	icon_state = "Z_E4"

/obj/effect/urban/decal/tiretrack
	icon = 'icons/turf/desertdam_map.dmi'
	icon_state = "tiremarks"

/obj/structure/prop/urban/misc/buildinggreebliessmall
	name = "wall vent"
	desc = "A small piece of odd looking machinery..."
	icon_state = "smallwallvent1"
	density = FALSE

/obj/structure/prop/urban/misc/buildinggreebliessmall/computer
	name = "machinery"
	icon_state = "zcomputermachine"
	density = TRUE

/obj/structure/prop/urban/misc/buildinggreeblies/greeble11/dense
	density = TRUE

/obj/structure/prop/urban/misc/buildinggreeblies/greeble10/dense
	density = TRUE

/obj/structure/prop/urban/airport/refuelinghose
	name = "refueling hose"
	desc = "A long refueling hose that connects to various types of dropships."
	icon = 'icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "fuelline1"
	bound_height = 64
	bound_width = 96
	layer = ABOVE_WEEDS_LAYER
	plane = FLOOR_PLANE

/obj/structure/prop/urban/supermart/rack/longrack2
	name = "shelf"
	desc = "A long shelf filled with various foodstuffs"
	icon_state = "longrack2"

/obj/structure/prop/urban/airport/refuelinghose2
	name = "refueling hose"
	desc = "A long refueling hose that connects to various types of dropships."
	icon = 'icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "fuelline2"
	bound_height = 64
	bound_width = 96
	layer = ABOVE_WEEDS_LAYER
	plane = FLOOR_PLANE

// Pilot body

/obj/effect/urban/decal/road/corner
	icon = 'icons/turf/desertdam_map.dmi'
	icon_state = "Z_corner"

/obj/effect/urban/decal/road/lines5
	icon = 'icons/turf/desertdam_map.dmi'
	icon_state = "Z_M1"

/obj/structure/prop/urban/supermart/freezer/supermartfreezer2
	icon_state = "freezerlower"

/obj/structure/prop/urban/supermart/freezer
	name = "commercial freezer"
	desc = "A commercial grade freezer."
	icon_state = "freezerupper"
	density = TRUE

/obj/structure/prop/urban/supermart/freezer/supermartfreezer1
	icon_state = "freezerupper"

/obj/structure/prop/urban/supermart/freezer/supermartfreezer3
	icon_state = "freezermid"

/obj/structure/prop/urban/supermart/freezer/supermartfreezer4
	icon_state = "freezerupper1"

/obj/structure/prop/urban/supermart/freezer/supermartfreezer5
	icon_state = "freezerlower1"

/obj/structure/prop/urban/supermart/freezer/supermartfreezer6
	icon_state = "freezermid1"

/obj/structure/prop/urban/signs/high_voltage/small
	name = "warning sign"
	desc = "DANGER - HIGH VOLTAGE - DEATH!."
	icon = 'icons/obj/structures/prop/urban/urbanrandomprops.dmi'
	icon_state = "shockyTiny"

// billboards, Signs and Posters

/// Alien Isolation - posters used as reference (direct downscale of the image for some) If anyone wants to name the billboards individually ///

/obj/structure/prop/urban/supermart/rack/longrack5
	name = "shelf"
	desc = "A long shelf filled with various foodstuffs"
	icon_state = "longrack5"

/obj/structure/prop/urban/signs/high_voltage
	name = "warning sign"
	desc = "DANGER - HIGH VOLTAGE - DEATH!."
	icon = 'icons/obj/structures/prop/urban/urbanrandomprops.dmi'
	icon_state = "shockyBig"

/obj/structure/prop/urban/supermart/rack/longrack1
	name = "shelf"
	desc = "A long shelf filled with various foodstuffs"
	icon_state = "longrack1"

/obj/item/organ/brain/xeno
	name = "thinkpan"
	desc = "It looks kind of like an enormous wad of purple bubblegum."
	icon = 'icons/mob/alien.dmi'
	icon_state = "chitin"

/obj/item/vehicle_module/mounted_gun
	icon = 'icons/obj/vehicles.dmi'
	icon_state = ""
	slot = ATTACHMENT_SLOT_WEAPON
	w_class = WEIGHT_CLASS_BULKY
	attach_features_flags = ATTACH_ACTIVATION|ATTACH_REMOVABLE|ATTACH_NO_HANDS
	///The gun mounted on a vehicle. Initial value is the type to use
	var/obj/item/weapon/gun/mounted_gun
	///Firing angle for the mounted weapon
	var/firing_angle = 120

/obj/item/vehicle_module/mounted_gun/Initialize(mapload)
	if(!mounted_gun)
		return INITIALIZE_HINT_QDEL
	. = ..()
	mounted_gun = new mounted_gun(src)
	mounted_gun.gun_fire_angle = firing_angle
	action_icon = mounted_gun.icon
	action_icon_state = mounted_gun.icon_state

/obj/item/vehicle_module/mounted_gun/Destroy()
	QDEL_NULL(mounted_gun)
	return ..()

/obj/item/vehicle_module/mounted_gun/on_unbuckle(datum/source, mob/living/unbuckled_mob, force = FALSE)
	if(mounted_gun.loc == unbuckled_mob)
		unbuckled_mob.dropItemToGround(mounted_gun, TRUE)
	return ..()

/obj/item/vehicle_module/mounted_gun/activate(mob/living/user)
	if(mounted_gun.loc == user)
		on_weapon_equipped(null, user)
		return FALSE
	if(!user.put_in_active_hand(mounted_gun) && !user.put_in_inactive_hand(mounted_gun))
		to_chat(user, span_warning("Could not equip weapon! Click [parent] with a free hand to equip."))
		return FALSE
	RegisterSignal(mounted_gun, COMSIG_MOVABLE_MOVED, PROC_REF(on_weapon_moved))
	RegisterSignal(mounted_gun, COMSIG_ITEM_EQUIPPED, PROC_REF(on_weapon_equipped))
	return TRUE

///Handles the weapon being moved
/obj/item/vehicle_module/mounted_gun/proc/on_weapon_moved(obj/item/source)
	SIGNAL_HANDLER
	if(ismob(mounted_gun.loc)) //we have to handle it after its fully equipped or it becomes cursed
		return
	reequip_weapon()

///Handles the weapon being put into an equip slot
/obj/item/vehicle_module/mounted_gun/proc/on_weapon_equipped(obj/item/source, mob/user)
	SIGNAL_HANDLER
	user.dropItemToGround(mounted_gun, TRUE)
	reequip_weapon()

///Safely puts the weapon back into storage
/obj/item/vehicle_module/mounted_gun/proc/reequip_weapon()
	UnregisterSignal(mounted_gun, list(COMSIG_MOVABLE_MOVED, COMSIG_ITEM_EQUIPPED))
	mounted_gun.forceMove(src)

// Upstream named equipment roots mapped to functional local types.
/obj/item/weapon/gun/standard_mmg
	parent_type = /obj/item/weapon/gun/mg27

/obj/item/weapon/gun/pistol/standard_pistol
	parent_type = /obj/item/weapon/gun/pistol/p14

/obj/item/weapon/gun/pistol/standard_heavypistol
	parent_type = /obj/item/weapon/gun/pistol/p23

/obj/item/weapon/gun/rifle/standard_gpmg
	parent_type = /obj/item/weapon/gun/rifle/mg60

/obj/item/weapon/gun/rifle/standard_smarttargetrifle
	parent_type = /obj/item/weapon/gun/rifle/sg62

/obj/item/weapon/gun/rifle/standard_autoshotgun
	parent_type = /obj/item/weapon/gun/rifle/sh15

/obj/item/weapon/gun/rifle/standard_skirmishrifle
	parent_type = /obj/item/weapon/gun/rifle/ar21

/obj/item/weapon/gun/rifle/standard_carbine
	parent_type = /obj/item/weapon/gun/rifle/ar18

/obj/item/weapon/gun/rifle/standard_assaultrifle
	parent_type = /obj/item/weapon/gun/rifle/ar12

/obj/item/weapon/gun/rifle/standard_br
	parent_type = /obj/item/weapon/gun/rifle/br64

/obj/item/weapon/gun/rifle/standard_lmg
	parent_type = /obj/item/weapon/gun/rifle/mg42

/obj/item/weapon/gun/rifle/tx55/freelancer_custom
	parent_type = /obj/item/weapon/gun/rifle/tx55/freelancer

/obj/item/weapon/gun/smg/standard_machinepistol
	parent_type = /obj/item/weapon/gun/smg/mp19

/obj/item/weapon/gun/sentry/big_sentry
	parent_type = /obj/item/weapon/gun/sentry/basic

/obj/item/ammo_magazine/standard_mmg
	parent_type = /obj/item/ammo_magazine/mg27

/obj/item/ammo_magazine/standard_gpmg
	parent_type = /obj/item/ammo_magazine/mg60

/obj/item/ammo_magazine/rifle/standard_smarttargetrifle
	parent_type = /obj/item/ammo_magazine/rifle/sg62

/obj/item/ammo_magazine/rifle/standard_spottingrifle
	parent_type = /obj/item/ammo_magazine/rifle/sg153

/obj/item/ammo_magazine/rifle/standard_carbine
	parent_type = /obj/item/ammo_magazine/rifle/ar18

/obj/item/ammo_magazine/rifle/standard_assaultrifle
	parent_type = /obj/item/ammo_magazine/rifle/ar12

/obj/item/ammo_magazine/rifle/standard_br
	parent_type = /obj/item/ammo_magazine/rifle/br64

/obj/item/ammo_magazine/rifle/standard_skirmishrifle
	parent_type = /obj/item/ammo_magazine/rifle/ar21

/obj/item/ammo_magazine/standard_lmg
	parent_type = /obj/item/ammo_magazine/mg42

/obj/item/storage/holster/belt/m44
	parent_type = /obj/item/storage/holster/belt/revolver/m44

/obj/item/weapon/gun/sentry/big_sentry/premade
	parent_type = /obj/item/weapon/gun/sentry/basic/premade

/obj/item/weapon/gun/standard_mmg/Initialize(mapload, spawn_empty)
	. = ..()
	allowed_ammo_types = allowed_ammo_types.Copy()
	allowed_ammo_types |= list(/obj/item/ammo_magazine/standard_mmg)

/obj/item/weapon/gun/rifle/standard_gpmg/Initialize(mapload, spawn_empty)
	. = ..()
	allowed_ammo_types = allowed_ammo_types.Copy()
	allowed_ammo_types |= list(/obj/item/ammo_magazine/standard_gpmg, /obj/item/ammo_magazine/standard_gpmg/big)

/obj/item/weapon/gun/rifle/standard_smarttargetrifle/Initialize(mapload, spawn_empty)
	. = ..()
	allowed_ammo_types = allowed_ammo_types.Copy()
	allowed_ammo_types |= list(/obj/item/ammo_magazine/rifle/standard_smarttargetrifle)

/obj/item/weapon/gun/rifle/standard_autoshotgun/Initialize(mapload, spawn_empty)
	. = ..()
	allowed_ammo_types = allowed_ammo_types.Copy()
	allowed_ammo_types |= list(/obj/item/ammo_magazine/rifle/tx15_flechette)

/obj/item/weapon/gun/rifle/standard_skirmishrifle/Initialize(mapload, spawn_empty)
	. = ..()
	allowed_ammo_types = allowed_ammo_types.Copy()
	allowed_ammo_types |= list(/obj/item/ammo_magazine/rifle/standard_skirmishrifle)

/obj/item/weapon/gun/rifle/standard_carbine/Initialize(mapload, spawn_empty)
	. = ..()
	allowed_ammo_types = allowed_ammo_types.Copy()
	allowed_ammo_types |= list(/obj/item/ammo_magazine/rifle/standard_carbine, /obj/item/ammo_magazine/rifle/standard_carbine/ap)

/obj/item/weapon/gun/rifle/standard_assaultrifle/Initialize(mapload, spawn_empty)
	. = ..()
	allowed_ammo_types = allowed_ammo_types.Copy()
	allowed_ammo_types |= list(/obj/item/ammo_magazine/rifle/standard_assaultrifle, /obj/item/ammo_magazine/rifle/standard_assaultrifle/ap)

/obj/item/weapon/gun/rifle/standard_br/Initialize(mapload, spawn_empty)
	. = ..()
	allowed_ammo_types = allowed_ammo_types.Copy()
	allowed_ammo_types |= list(/obj/item/ammo_magazine/rifle/standard_br)

/obj/item/weapon/gun/rifle/standard_lmg/Initialize(mapload, spawn_empty)
	. = ..()
	allowed_ammo_types = allowed_ammo_types.Copy()
	allowed_ammo_types |= list(/obj/item/ammo_magazine/standard_lmg)

/obj/item/weapon/gun/rifle/tx55/freelancer_custom/Initialize(mapload, spawn_empty)
	. = ..()
	allowed_ammo_types = allowed_ammo_types.Copy()
	allowed_ammo_types |= list(/obj/item/ammo_magazine/rifle/standard_assaultrifle, /obj/item/ammo_magazine/rifle/standard_assaultrifle/ap)

/obj/item/weapon/gun/sentry/big_sentry/Initialize(mapload, spawn_empty)
	. = ..()
	allowed_ammo_types = allowed_ammo_types.Copy()
	allowed_ammo_types |= list(/obj/item/ammo_magazine/sentry)

