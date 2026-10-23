// tgmc coax
/obj/item/armored_weapon/coaxial
	name = "EM-94 Coaxial Chain gun (10x26mm)"
	desc = "A beltfed coaxial that spews lead. Requires the Barrel shroud and power system of a vehicle to use in any way shape and form. Can use either standard MG-60 Boxes or vehicle specific boxes."
	icon_state = "lvrt_coax"
	fire_sound = 'sound/weapons/guns/fire/tgmc/kinetic/gun_mg60.ogg'
	armored_weapon_flags = MODULE_SECONDARY|MODULE_FIXED_FIRE_ARC
	ammo = /obj/item/ammo_magazine/mg60
	accepted_ammo = list(/obj/item/ammo_magazine/mg60)
	fire_mode = GUN_FIREMODE_AUTOMATIC
	projectile_delay = 0.15 SECONDS
	variance = 5
	rearm_time = 3 SECONDS
	hud_state_empty = "rifle_empty"
