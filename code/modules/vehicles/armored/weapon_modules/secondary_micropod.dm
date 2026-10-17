/obj/item/armored_weapon/microrocket_pod
	name = "microrocket pod"
	desc = "A TGMC secondary vehicle-mounted multiple launch rocket system with a total of 6 homing microrockets. Capable of unleashing its entire payload in rapid succession."
	icon_state = "secondary_rocket_multiple"
	fire_sound = 'sound/weapons/guns/fire/launcher.ogg'
	interior_fire_sound = null
	armored_weapon_flags = MODULE_SECONDARY
	ammo = /obj/item/ammo_magazine/tank/microrocket_rack
	accepted_ammo = list(/obj/item/ammo_magazine/tank/microrocket_rack)
	fire_mode = GUN_FIREMODE_BURSTFIRE
	projectile_delay = 2 SECONDS
	variance = 40
	burst_amount = 3
	projectile_burst_delay = 0.1 SECONDS
	rearm_time = 5 SECONDS
	hud_state_empty = "rocket_empty"
