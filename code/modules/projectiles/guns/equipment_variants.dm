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
