/*******************************************************************************
WEAPONS
*******************************************************************************/

/datum/assembly_craft/weapons
	group = "Weapons"
	craft_time = 5 SECONDS

/datum/assembly_craft/weapons/sr81_magazine
	name = "SR-81 IFF Auto Sniper magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 2)
	output = list(/obj/item/ammo_magazine/rifle/sr81 = 1)

/datum/assembly_craft/weapons/sr127_flak_magazine
	name = "SR-127 Flak Magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/ammo_magazine/rifle/sr127/flak = 1)

/datum/assembly_craft/weapons/scout_rifle_magazine
	name = "BR-8 scout rifle magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/ammo_magazine/rifle/tx8 = 1)

/datum/assembly_craft/weapons/scout_rifle_incendiary_magazine
	name = "BR-8 scout rifle incendiary magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 2)
	output = list(/obj/item/ammo_magazine/rifle/tx8/incendiary = 1)

/datum/assembly_craft/weapons/scout_rifle_impact_magazine
	name = "BR-8 scout rifle impact magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 2)
	output = list(/obj/item/ammo_magazine/rifle/tx8/impact = 1)

/datum/assembly_craft/weapons/mateba_speedloader
	name = "Mateba autorevolver speedloader"
	input = list(/obj/item/stack/sheet/mineral/osmium = 2, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/ammo_magazine/revolver/mateba = 1)

/datum/assembly_craft/weapons/railgun_magazine
	name = "Railgun canister (Armor Piercing Discarding Sabot)"
	input = list(/obj/item/stack/sheet/mineral/osmium = 10, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/ammo_magazine/railgun = 1)

/datum/assembly_craft/weapons/railgun_hvap_magazine
	name = "Railgun canister (High Velocity Armor Piericing)"
	input = list(/obj/item/stack/sheet/mineral/osmium = 20, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/ammo_magazine/railgun/hvap = 1)

/datum/assembly_craft/weapons/railgun_smart_magazine
	name = "Railgun canister (Smart Armor Piericing)"
	input = list(/obj/item/stack/sheet/mineral/osmium = 15, /obj/item/stack/gun_powder = 2)
	output = list(/obj/item/ammo_magazine/railgun/smart = 1)

/datum/assembly_craft/weapons/minigun_powerpack
	name = "MG-100 Vindicator powerpack"
	input = list(/obj/item/stack/sheet/mineral/osmium = 25, /obj/item/stack/gun_powder = 10)
	output = list(/obj/item/ammo_magazine/minigun_powerpack = 1)

/datum/assembly_craft/weapons/amr_magazine
	name = "T-26 AMR magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/ammo_magazine/sniper = 1)

/datum/assembly_craft/weapons/amr_magazine_incend
	name = "T-26 AMR incendiary magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 2)
	output = list(/obj/item/ammo_magazine/sniper/incendiary = 1)

/datum/assembly_craft/weapons/amr_magazine_flak
	name = "T-26 AMR flak magazine assembly refill"
	input = list(/obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 2)
	output = list(/obj/item/ammo_magazine/sniper/flak = 1)

/datum/assembly_craft/weapons/howitzer_shell_he
	name = "Howitzer HE shell"
	input = list(/obj/item/stack/sheet/metal = 5, /obj/item/stack/gun_powder = 2)
	output = list(/obj/item/mortal_shell/howitzer/he = 1)

/datum/assembly_craft/weapons/howitzer_shell_incen_refill
	name = "Howitzer Incendiary shell"
	input = list(/obj/item/stack/sheet/metal = 5, /obj/item/stack/gun_powder = 2)
	output = list(/obj/item/mortal_shell/howitzer/incendiary = 1)

/datum/assembly_craft/weapons/howitzer_shell_wp_refill
	name = "Howitzer white phosporous 'spotting' shell"
	input = list(/obj/item/stack/sheet/metal = 5, /obj/item/stack/gun_powder = 3)
	output = list(/obj/item/mortal_shell/howitzer/white_phos = 1)

/datum/assembly_craft/weapons/howitzer_shell_tfoot_refill
	name = "Howitzer 'Tanglefoot' shell"
	input = list(/obj/item/stack/sheet/metal = 5, /obj/item/stack/gun_powder = 3)
	output = list(/obj/item/mortal_shell/howitzer/plasmaloss = 1)

/datum/assembly_craft/weapons/mortar_shell
	name = "Mortar High Explosive shell"
	input = list(/obj/item/stack/sheet/metal = 1, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/mortal_shell/he = 1)

/datum/assembly_craft/weapons/mortar_shell/incen
	name = "Mortar Incendiary shell"
	output = list(/obj/item/mortal_shell/incendiary = 1)

/datum/assembly_craft/weapons/mortar_shell/tfoot
	name = "Mortar Tanglefoot Gas shell"
	output = list(/obj/item/mortal_shell/plasmaloss = 1)

/datum/assembly_craft/weapons/mortar_shell/flare
	name = "Mortar Flare shell"
	output = list(/obj/item/mortal_shell/flare = 1)

/datum/assembly_craft/weapons/mortar_shell/smoke
	name = "Mortar Smoke shell"
	output = list(/obj/item/mortal_shell/smoke = 1)

/datum/assembly_craft/weapons/mlrs_rocket
	name = "MLRS High Explosive rocket"
	input = list(/obj/item/stack/sheet/metal = 8, /obj/item/stack/gun_powder = 8)
	output = list(/obj/item/storage/box/mlrs_rockets = 1)

/datum/assembly_craft/weapons/mlrs_rocket/gas
	name = "MLRS Gas rockets"
	input = list(/obj/item/stack/sheet/metal = 8, /obj/item/stack/gun_powder = 16)
	output = list(/obj/item/storage/box/mlrs_rockets_gas = 1)

/datum/assembly_craft/weapons/mlrs_rocket/tangle
	name = "MLRS Tanglefoot rockets"
	output = list(/obj/item/storage/box/mlrs_rockets_tangle = 1)
