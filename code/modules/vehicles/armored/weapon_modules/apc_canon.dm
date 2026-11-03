/obj/item/armored_weapon/apc_cannon
	name = "\improper MKV-7 utility payload launcher"
	desc = "A double barrelled cannon which can rapidly deploy utility packages to the battlefield."
	icon_state = "APC uninstalled dualcannon"
	fire_sound = 'sound/weapons/guns/fire/tank_smokelauncher.ogg'
	interior_fire_sound = null
	ammo = /obj/item/ammo_magazine/tank/tank_slauncher
	accepted_ammo = list(
		/obj/item/ammo_magazine/tank/tank_slauncher,
		/obj/item/ammo_magazine/tank/tank_glauncher,
	)
	projectile_delay = 0.7 SECONDS
	hud_state_empty = "grenade_empty"
