/obj/item/armored_weapon/bfg
	name = "\improper BFG 9500"
	desc = "A crackling energy weapon, a slightly scaled up model of the classic BFG 9000. Point at people who killed your rabbit."
	icon_state = "bfg"
	fire_sound = 'sound/weapons/guns/fire/tank_bfg.ogg'
	interior_fire_sound = 'sound/vehicles/weapons/particle_fire_interior.ogg'
	armored_weapon_flags = MODULE_PRIMARY|MODULE_NOT_FABRICABLE
	ammo = /obj/item/ammo_magazine/tank/bfg
	accepted_ammo = list(/obj/item/ammo_magazine/tank/bfg)
	fire_mode = GUN_FIREMODE_SEMIAUTO
	projectile_delay = 8 SECONDS
	variance = 0
	hud_state_empty = "electrothermal_empty"
