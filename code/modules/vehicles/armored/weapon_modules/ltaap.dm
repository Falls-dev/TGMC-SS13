/obj/item/armored_weapon/ltaap
	name = "\improper LTA-AP chaingun"
	desc = "A hefty, large caliber chaingun"
	icon_state = "ltaap_chaingun"
	fire_sound = 'sound/weapons/guns/fire/tank_minigun_loop.ogg'
	interior_fire_sound = null
	windup_delay = 5
	windup_sound = 'sound/weapons/guns/fire/tank_minigun_start.ogg'
	ammo = /obj/item/ammo_magazine/tank/ltaap_chaingun
	accepted_ammo = list(/obj/item/ammo_magazine/tank/ltaap_chaingun)
	fire_mode = GUN_FIREMODE_AUTOMATIC
	variance = 5
	projectile_delay = 0.1 SECONDS
	rearm_time = 3 SECONDS
	hud_state_empty = "rifle_empty"
