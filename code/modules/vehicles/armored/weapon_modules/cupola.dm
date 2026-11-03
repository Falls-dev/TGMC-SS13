/obj/item/armored_weapon/secondary_weapon
	name = "secondary cupola minigun"
	desc = "A robotically controlled minigun that spews lead."
	icon_state = "cupola"
	fire_sound = 'sound/weapons/guns/fire/tank_minigun_loop.ogg'
	interior_fire_sound = null
	windup_delay = 5
	windup_sound = 'sound/weapons/guns/fire/tank_minigun_start.ogg'
	armored_weapon_flags = MODULE_SECONDARY
	ammo = /obj/item/ammo_magazine/tank/secondary_cupola
	accepted_ammo = list(/obj/item/ammo_magazine/tank/secondary_cupola)
	fire_mode = GUN_FIREMODE_AUTOMATIC
	projectile_delay = 2
	variance = 5
	rearm_time = 1 SECONDS
	hud_state_empty = "rifle_empty"
