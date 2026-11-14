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

/obj/item/weapon/gun/rifle/tx55/freelancer_custom/combat_patrol
	starting_attachment_types = list(
		/obj/item/weapon/gun/rifle/tx54/mini,
		/obj/item/attachable/motiondetector,
		/obj/item/attachable/extended_barrel,
		/obj/item/attachable/verticalgrip,
	)

//-------------------------------------------------------
//A true classic, the Garand. Ping.

/obj/item/weapon/gun/rifle/standard_gpmg/machinegunner
	starting_attachment_types = list(/obj/item/attachable/stock/t60stock, /obj/item/attachable/foldable/bipod, /obj/item/attachable/magnetic_harness, /obj/item/attachable/extended_barrel)

/obj/item/weapon/gun/rifle/standard_smarttargetrifle/motion
	starting_attachment_types = list(/obj/item/weapon/gun/rifle/sg153, /obj/item/attachable/stock/strstock, /obj/item/attachable/motiondetector)

/obj/item/weapon/gun/rifle/standard_autoshotgun/engineer
	starting_attachment_types = list(/obj/item/attachable/stock/sh15, /obj/item/attachable/magnetic_harness, /obj/item/weapon/gun/grenade_launcher/underslung)

/obj/item/weapon/gun/rifle/standard_skirmishrifle/standard
	starting_attachment_types = list(
		/obj/item/attachable/reddot,
		/obj/item/attachable/extended_barrel,
		/obj/item/weapon/gun/grenade_launcher/underslung,
	)

//-------------------------------------------------------
//AF-51B MACHINEcarbine

/obj/item/weapon/gun/rifle/standard_carbine/standard
	starting_attachment_types = list(/obj/item/attachable/stock/ar18stock, /obj/item/weapon/gun/grenade_launcher/underslung, /obj/item/attachable/reddot, /obj/item/attachable/extended_barrel)

/obj/item/weapon/gun/rifle/standard_assaultrifle/medic
	starting_attachment_types = list(/obj/item/attachable/stock/ar12stock, /obj/item/attachable/magnetic_harness, /obj/item/attachable/extended_barrel, /obj/item/weapon/gun/grenade_launcher/underslung)

//-------------------------------------------------------
//DMR-37 DMR

/obj/item/weapon/gun/rifle/standard_carbine/engineer
	starting_attachment_types = list(/obj/item/attachable/stock/ar18stock, /obj/item/attachable/magnetic_harness, /obj/item/attachable/verticalgrip, /obj/item/attachable/extended_barrel)

/obj/item/weapon/gun/rifle/standard_assaultrifle/engineer
	starting_attachment_types = list(/obj/item/attachable/stock/ar12stock, /obj/item/attachable/magnetic_harness, /obj/item/attachable/extended_barrel, /obj/item/weapon/gun/flamer/mini_flamer)

/obj/item/weapon/gun/rifle/m41a/field_commander
	starting_attachment_types = list(
		/obj/item/attachable/stock/m41a,
		/obj/item/weapon/gun/grenade_launcher/underslung/invisible,
		/obj/item/attachable/reddot,
		/obj/item/attachable/extended_barrel,
	)

/obj/item/weapon/gun/rifle/standard_assaultrifle/rifleman
	starting_attachment_types = list(/obj/item/attachable/stock/ar12stock, /obj/item/attachable/reddot, /obj/item/attachable/extended_barrel, /obj/item/weapon/gun/grenade_launcher/underslung)

/obj/item/weapon/gun/rifle/standard_carbine/plasma_pistol
	starting_attachment_types = list(/obj/item/attachable/stock/ar18stock, /obj/item/weapon/gun/pistol/plasma_pistol, /obj/item/attachable/motiondetector, /obj/item/attachable/compensator)

/obj/item/weapon/gun/rifle/standard_br/standard
	starting_attachment_types = list(/obj/item/attachable/stock/br64stock, /obj/item/weapon/gun/grenade_launcher/underslung/br64, /obj/item/attachable/reddot, /obj/item/attachable/extended_barrel)

//-------------------------------------------------------
//PR-412 Pulse Rifle

/obj/item/weapon/gun/rifle/standard_autoshotgun/standard
	starting_attachment_types = list(/obj/item/attachable/stock/sh15, /obj/item/attachable/magnetic_harness, /obj/item/attachable/bayonet, /obj/item/weapon/gun/grenade_launcher/underslung)

/obj/item/weapon/gun/rifle/standard_carbine/scout
	starting_attachment_types = list(/obj/item/attachable/stock/ar18stock, /obj/item/weapon/gun/grenade_launcher/underslung, /obj/item/attachable/motiondetector, /obj/item/attachable/extended_barrel)

/obj/item/weapon/gun/rifle/standard_carbine/suppressed
	starting_attachment_types = list(/obj/item/attachable/stock/ar18stock, /obj/item/weapon/gun/grenade_launcher/underslung, /obj/item/attachable/reddot, /obj/item/attachable/suppressor)

/obj/item/weapon/gun/rifle/tx54/motion_sensor
	starting_attachment_types = list(/obj/item/attachable/motiondetector)
	default_ammo_type = /obj/item/ammo_magazine/rifle/tx54

//-------------------------------------------------------
// AR-55 built in grenade launcher

/obj/item/weapon/gun/rifle/standard_autoshotgun/plasma_pistol
	starting_attachment_types = list(/obj/item/attachable/stock/sh15, /obj/item/attachable/motiondetector, /obj/item/attachable/extended_barrel, /obj/item/weapon/gun/pistol/plasma_pistol)

//-------------------------------------------------------
//SG-29 Smart Machine Gun (It's more of a rifle than the SG.)

/obj/item/weapon/gun/rifle/som/suppressed
	starting_attachment_types = list(
		/obj/item/weapon/gun/shotgun/micro_grenade,
		/obj/item/attachable/verticalgrip,
		/obj/item/attachable/suppressor,
		/obj/item/attachable/magnetic_harness,
	)

/obj/item/weapon/gun/rifle/standard_spottingrifle
	name = "SG-153 spotting rifle"
	desc = "An underslung spotting rifle, generally found ontop of another gun."
	icon_state = "sg153"
	icon = 'icons/obj/items/guns/marksman64.dmi'
	fire_sound =  'sound/weapons/guns/fire/spottingrifle.ogg'
	caliber = CALIBER_12X7
	slot = ATTACHMENT_SLOT_UNDER
	gun_skill_category = SKILL_SMARTGUN
	max_shells = 5
	default_ammo_type =/obj/item/ammo_magazine/rifle/standard_spottingrifle
	allowed_ammo_types = list(
		/obj/item/ammo_magazine/rifle/standard_spottingrifle,
		/obj/item/ammo_magazine/rifle/standard_spottingrifle/highimpact,
		/obj/item/ammo_magazine/rifle/standard_spottingrifle/heavyrubber,
		/obj/item/ammo_magazine/rifle/standard_spottingrifle/plasmaloss,
		/obj/item/ammo_magazine/rifle/standard_spottingrifle/tungsten,
		/obj/item/ammo_magazine/rifle/standard_spottingrifle/incendiary,
		/obj/item/ammo_magazine/rifle/standard_spottingrifle/flak,
	)
	force = 5
	attachable_allowed = list()
	actions_types = list()
	gun_firemode_list = list(GUN_FIREMODE_SEMIAUTO)
	gun_features_flags = GUN_IS_ATTACHMENT|GUN_WIELDED_FIRING_ONLY|GUN_ATTACHMENT_FIRE_ONLY|GUN_AMMO_COUNTER|GUN_IFF|GUN_SMOKE_PARTICLES
	attach_features_flags = NONE
	fire_delay = 1 SECONDS
	accuracy_mult = 1.25
	pixel_shift_x = 18
	pixel_shift_y = 16

//-------------------------------------------------------
//SG-25 Smart Rifle (Added back spefically for NT PMC ert, do not expect it to return in marine roster)

/obj/item/weapon/gun/rifle/standard_lmg/autorifleman
	starting_attachment_types = list(/obj/item/attachable/verticalgrip, /obj/item/attachable/reddot)

/obj/item/weapon/gun/rifle/standard_lmg/beginner
	starting_attachment_types = list(/obj/item/attachable/extended_barrel, /obj/item/attachable/reddot, /obj/item/attachable/verticalgrip)

//-------------------------------------------------------
//MG-60 General Purpose Machine Gun

/obj/item/ammo_magazine/standard_gpmg/big
	name = "\improper MG-60 GPMG quadruple box magazine (10x26mm)"
	desc = "A series of 4 belt boxes linked together for the MG-60 general purpose machinegun, incredibly impractical to use undeployed."
	icon = 'icons/obj/items/ammo/campaign_magazines.dmi'
	icon_state = "t60b"
	w_class = WEIGHT_CLASS_BULKY
	reload_delay = 8 SECONDS
	max_rounds = 800
	scatter_mod = 15
	wield_delay_mod = 6 SECONDS

//-------------------------------------------------------
//PR-412L1 HEAVY PULSE RIFLE

/obj/item/ammo_magazine/rifle/standard_spottingrifle/incendiary
	name = "\improper SG-153 incendiary magazine (12.7mm Smart Magnum)"
	desc = "A magazine filled with 12.7mm incendiary smart rounds, these rounds will set alight anything they hit."
	icon_state = "sg153_ic"
	icon_state_mini = "mag_rifle_orange"
	default_ammo = /datum/ammo/bullet/spottingrifle/incendiary

/obj/item/ammo_magazine/rifle/standard_spottingrifle/tungsten
	name = "\improper SG-153 tungsten magazine (12.7mm Smart Magnum)"
	desc = "A magazine filled with 12.7mm tungsten smart rounds, these rounds will massively knock back any target it hits."
	icon_state = "sg153_tg"
	icon_state_mini = "mag_rifle_green"
	default_ammo = /datum/ammo/bullet/spottingrifle/tungsten

/obj/item/ammo_magazine/rifle/standard_spottingrifle/highimpact
	name = "\improper SG-153 high impact magazine (12.7mm Smart Magnum)"
	desc = "A magazine filled with 12.7mm high impact smart rounds, these will likely stagger and slow anything they hit."
	icon_state = "sg153_hi"
	icon_state_mini = "mag_rifle_blue"
	default_ammo = /datum/ammo/bullet/spottingrifle/highimpact

/obj/item/ammo_magazine/rifle/tx15_flechette
	name = "\improper SH-15 flechette magazine (16 gauge)"
	desc = "A magazine of 16 gauge flechette rounds, for the SH-15."
	caliber = CALIBER_16G
	icon_state = "tx15_flechette"
	icon_state_mini = "mag_tx15_flechette"
	default_ammo = /datum/ammo/bullet/shotgun/tx15_flechette
	max_rounds = 12
	bonus_overlay = "tx15_flech"

/obj/item/ammo_magazine/rifle/standard_carbine/ap
	name = "\improper AR-18 AP magazine (10x24mm)"
	desc = "A 10mm assault carbine magazine, loaded with light armor piercing rounds."
	icon = 'icons/obj/items/ammo/campaign_magazines.dmi'
	icon_state = "t18_ap"
	icon_state_mini = "mag_rifle_big_green"
	default_ammo = /datum/ammo/bullet/rifle/hv
	bonus_overlay = "t18_ap"

//-------------------------------------------------------
//T12 Assault Rifle

/obj/item/ammo_magazine/rifle/standard_assaultrifle/ap
	name = "\improper AR-12 AP magazine (10x24mm)"
	desc = "A 10mm assault rifle magazine, loaded with light armor piercing rounds."
	icon = 'icons/obj/items/ammo/campaign_magazines.dmi'
	icon_state = "t12_ap"
	icon_state_mini = "mag_rifle_big_green"
	default_ammo = /datum/ammo/bullet/rifle/hv
	bonus_overlay = "t12_ap"

//-------------------------------------------------------
//T37 DMR

/obj/item/ammo_magazine/rifle/tx54/smoke/acid
	name = "\improper 20mm acid smoke grenade magazine"
	desc = "A 20mm magazine loaded with acid grenades. For use with the GL-54 or AR-55."
	default_ammo = /datum/ammo/tx54/smoke/acid
	icon_state = "tx54_airburst"
	icon_state_mini = "mag_sniper_green"
	greyscale_colors = COLOR_AMMO_ACID

/obj/item/ammo_magazine/rifle/standard_spottingrifle/heavyrubber
	name = "\improper SG-153 heavy rubber magazine (12.7mm Smart Magnum)"
	desc = "A magazine filled with 12.7mm heavy rubber smart rounds, these will likely stun and displace anything they hit."
	icon_state = "sg153_hr"
	icon_state_mini = "mag_rifle_red"
	default_ammo = /datum/ammo/bullet/spottingrifle/heavyrubber

/obj/item/ammo_magazine/rifle/standard_spottingrifle/plasmaloss
	name = "\improper SG-153 tanglefoot magazine (12.7mm Smart Magnum)"
	desc = "A magazine filled with 12.7mm smart rounds tipped with 'Tanglefoot' poison, these rounds will drain the energy out of targets they hit."
	icon_state = "sg153_pl"
	icon_state_mini = "mag_rifle_purple"
	default_ammo = /datum/ammo/bullet/spottingrifle/plasmaloss

/obj/item/ammo_magazine/rifle/standard_spottingrifle/flak
	name = "\improper SG-153 flak magazine (12.7mm Smart Magnum)"
	desc = "A magazine filled with 12.7mm flak smart rounds, these rounds will airburst on contact with an organic target, causing damage in a small area near the target."
	icon_state = "sg153_fl"
	icon_state_mini = "mag_rifle_cyan"
	default_ammo = /datum/ammo/bullet/spottingrifle/flak

//-------------------------------------------------------
//SMARTRIFLE AMMUNITION
