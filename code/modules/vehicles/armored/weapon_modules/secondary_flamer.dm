/obj/item/armored_weapon/secondary_flamer
	name = "\improper OMR Mk.3 secondary flamer"
	desc = "A large, vehicle mounted flamer. This one is capable of spraying it's payload due to a less solid mix."
	icon_state = "sflamer"
	fire_sound = SFX_GUN_FLAMETHROWER
	interior_fire_sound = null
	ammo = /obj/item/ammo_magazine/tank/secondary_flamer_tank
	armored_weapon_flags = MODULE_SECONDARY
	fire_mode = GUN_FIREMODE_AUTOMATIC
	variance = 5
	rearm_time = 1 SECONDS
	accepted_ammo = list(
		/obj/item/ammo_magazine/tank/secondary_flamer_tank,
	)
	projectile_delay = 1 // spray visuals
	hud_state_empty = "flame_empty"
