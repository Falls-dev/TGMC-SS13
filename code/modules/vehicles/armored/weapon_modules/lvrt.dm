// Recon tank
/obj/item/armored_weapon/lvrt_sarden
	name = "\improper EM-2600 'SARDEN' Autocannon"
	desc = "A 30mm Autocannon for the LVRT 'Fallow'. A surprisingly powerful autocannon. Sadly, beltfeeding system was lost in the slew of budget cuts related to the system. It is loaded with 4 round clips."
	icon_state = "lvrt_autocannon"
	fire_sound = SFX_AC_FIRE
	interior_fire_sound = null
	ammo = /obj/item/ammo_magazine/tank/sarden_clip
	accepted_ammo = list(/obj/item/ammo_magazine/tank/sarden_clip, /obj/item/ammo_magazine/tank/sarden_clip/high_explosive)
	fire_mode = GUN_FIREMODE_AUTOMATIC
	variance = 2
	projectile_delay = 0.65 SECONDS
	rearm_time = 0.5 SECONDS
	hud_state_empty = "rifle_empty"

/obj/item/armored_weapon/lvrt_cannon
	name = "\improper EM-2500 Low Velocity Cannon"
	desc = "A 76mm low velocity cannon for the LVRT 'Fallow'. It has slow travel speed and solid explosive performance. It is loaded with 76mm shells."
	icon_state = "lvrt_cannon"
	fire_sound = SFX_AC_FIRE
	interior_fire_sound = null
	ammo = /obj/item/ammo_magazine/tank/lowvel_cannon_recon
	accepted_ammo = list(/obj/item/ammo_magazine/tank/lowvel_cannon_recon, /obj/item/ammo_magazine/tank/lowvel_cannon_recon/high_explosive, /obj/item/ammo_magazine/tank/lowvel_high_explosive_fragmenting_antipersonnel)
	variance = 0
	projectile_delay = 1.5 SECONDS
	rearm_time = 1.5 SECONDS
	hud_state_empty = "rifle_empty"

/obj/item/armored_weapon/lvrt_flamer
	name = "\improper EM-2400 Low Impulse Flamer"
	desc = "A 40mm low impulse flamer for the LVRT 'Fallow'. With it's special design, fires globes of fire to small area. Was made to counter soft organic structers. Utilizing special high-combustion fuel mix."
	icon_state = "lvrt_flamer"
	fire_sound = SFX_AC_FIRE
	interior_fire_sound = null
	ammo = /obj/item/ammo_magazine/tank/lowvel_canister
	accepted_ammo = list(/obj/item/ammo_magazine/tank/lowvel_canister)
	variance = 2
	projectile_delay = 1 SECONDS
	rearm_time = 1.5 SECONDS
	hud_state_empty = "flame_empty"
