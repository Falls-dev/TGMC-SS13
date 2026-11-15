/obj/item/armored_weapon/tow
	name = "\improper TOW-III launcher"
	desc = "A single-shot, homing, vehicle-mounted TOW-III launcher designed for precision strikes against armored targets. Equipped with IFF."
	icon_state = "seeker"
	fire_sound = SFX_RPG_FIRE
	interior_fire_sound = null
	armored_weapon_flags = MODULE_SECONDARY
	ammo = /obj/item/ammo_magazine/tank/tow_missile
	accepted_ammo = list(/obj/item/ammo_magazine/tank/tow_missile)
	fire_mode = GUN_FIREMODE_SEMIAUTO
	maximum_magazines = 13
	projectile_delay = 2 SECONDS
	variance = 10
	rearm_time = 1 SECONDS
	hud_state_empty = "rocket_empty"
