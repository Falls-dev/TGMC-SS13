/obj/item/armored_weapon/tank_autocannon
	name = "\improper Bushwhacker Autocannon"
	desc = "A Bushwhacker 30mm Autocannon for vehicular use."
	icon_state = "tank_autocannon"
	interior_fire_sound = null
	fire_sound = SFX_AC_FIRE
	ammo = /obj/item/ammo_magazine/tank/autocannon
	accepted_ammo = list(/obj/item/ammo_magazine/tank/autocannon, /obj/item/ammo_magazine/tank/autocannon/high_explosive)
	fire_mode = GUN_FIREMODE_AUTOMATIC
	variance = 2
	projectile_delay = 0.35 SECONDS
	rearm_time = 10 SECONDS
	hud_state_empty = "rifle_empty"
