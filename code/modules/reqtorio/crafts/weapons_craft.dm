/*******************************************************************************
WEAPONS
*******************************************************************************/

/datum/assembly_craft/weapons
	group = "Weapons"
	craft_time = 5 SECONDS

/datum/assembly_craft/weapons/smartgun_minigun_box
	name = "SG-85 ammo bin"
	input = list(/obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/ammo_magazine/packet/smart_minigun = 1)

/datum/assembly_craft/weapons/sg29
	name = "SG-29 ammo drum"
	input = list(/obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/ammo_magazine/sg29 = 1)

/datum/assembly_craft/weapons/sg62
	name = "SG-62 ammo magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/ammo_magazine/rifle/sg62 = 1)

/datum/assembly_craft/weapons/sg153
	name = "SG-153 spotting rifle ammo"
	input = list(/obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/ammo_magazine/rifle/sg153 = 1)

/datum/assembly_craft/weapons/sg153/highimpact
	name = "SG-153 high impact spotting rifle ammo"
	output = list(/obj/item/ammo_magazine/rifle/sg153/highimpact = 1)

/datum/assembly_craft/weapons/sg153/heavyrubber
	name = "SG-153 heavy rubber spotting rifle ammo"
	output = list(/obj/item/ammo_magazine/rifle/sg153/heavyrubber = 1)

/datum/assembly_craft/weapons/sg153/plasmaloss
	name = "SG-153 tanglefoot spotting rifle ammo"
	output = list(/obj/item/ammo_magazine/rifle/sg153/plasmaloss = 1)

/datum/assembly_craft/weapons/sg153/tungsten
	name = "SG-153 tungsten spotting rifle ammo"
	output = list(/obj/item/ammo_magazine/rifle/sg153/tungsten = 1)

/datum/assembly_craft/weapons/sg153/incendiary
	name = "SG-153 incendiary spotting rifle ammo"
	output = list(/obj/item/ammo_magazine/rifle/sg153/incendiary = 1)

/datum/assembly_craft/weapons/sg153/flak
	name = "SG-153 flak spotting rifle ammo"
	output = list(/obj/item/ammo_magazine/rifle/sg153/flak = 1)

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

/datum/assembly_craft/weapons/fk88_he
	name = "FK-88 HE shell (155mm Shell)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 3, /obj/item/stack/gun_powder = 10)
	output = list(/obj/item/ammo_magazine/fk88/he = 1)

/datum/assembly_craft/weapons/fk88_he/unguided
	name = "FK-88 unguided HE shell (155mm Shell)"
	output = list(/obj/item/ammo_magazine/fk88/he/unguided = 1)

/datum/assembly_craft/weapons/fk88_sabot
	name = "FK-88 APFDS shell (155mm Shell)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 3, /obj/item/stack/gun_powder = 5)
	output = list(/obj/item/ammo_magazine/fk88/sabot = 1)

/datum/assembly_craft/weapons/agls37_he
	name = "AGLS-37 HE magazine (40mm Caseless)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 3, /obj/item/stack/gun_powder = 5)
	output = list(/obj/item/ammo_magazine/agls37 = 1)

/datum/assembly_craft/weapons/agls37_fragmentation
	name = "AGLS-37 Frag magazine (40mm Caseless)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 2, /obj/item/stack/gun_powder = 4)
	output = list(/obj/item/ammo_magazine/agls37/fragmentation = 1)

/datum/assembly_craft/weapons/agls37_incendiary
	name = "AGLS-37 WP magazine (40mm Caseless)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 2, /obj/item/stack/gun_powder = 4)
	output = list(/obj/item/ammo_magazine/agls37/incendiary = 1)

/datum/assembly_craft/weapons/agls37_flare
	name = "AGLS-37 Flare magazine (40mm Caseless)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 2, /obj/item/stack/gun_powder = 2)
	output = list(/obj/item/ammo_magazine/agls37/flare = 1)

/datum/assembly_craft/weapons/agls37_cloak
	name = "AGLS-37 Cloak magazine (40mm Caseless)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 2, /obj/item/stack/gun_powder = 3)
	output = list(/obj/item/ammo_magazine/agls37/cloak = 1)

/datum/assembly_craft/weapons/agls37_tanglefoot
	name = "AGLS-37 Tanglefoot magazine (40mm Caseless)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 5, /obj/item/stack/gun_powder = 4)
	output = list(/obj/item/ammo_magazine/agls37/tanglefoot = 1)

/datum/assembly_craft/weapons/at36_shell
	name = "AT-36 AP-HE Shell (37mm)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 1, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/ammo_magazine/at36 = 1)

/datum/assembly_craft/weapons/at36_shell/apcr
	name = "AT-36 APCR Shell (37mm)"
	output = list(/obj/item/ammo_magazine/at36/apcr = 1)

/datum/assembly_craft/weapons/at36_shell/he
	name = "AT-36 HE Shell (37mm)"
	output = list(/obj/item/ammo_magazine/at36/he = 1)

/datum/assembly_craft/weapons/at36_shell/beehive
	name = "AT-36 Beehive Shell (37mm)"
	output = list(/obj/item/ammo_magazine/at36/beehive = 1)

/datum/assembly_craft/weapons/at36_shell/incendiary
	name = "AT-36 Napalm Shell (37mm)"
	output = list(/obj/item/ammo_magazine/at36/incend = 1)

/datum/assembly_craft/weapons/atr22_shell
	name = "ATR-22 high-velocity magazine(20mm)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 2, /obj/item/stack/gun_powder = 2)
	output = list(/obj/item/ammo_magazine/atr22 = 1)

/datum/assembly_craft/weapons/atr22_shell/flak
	name = "ATR-22 smart-detonating magazine(20mm)"
	output = list(/obj/item/ammo_magazine/atr22/flak = 1)
