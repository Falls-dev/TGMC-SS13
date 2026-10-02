/datum/assembly_craft/stationary
	group = "Operations"
	craft_time = 5 SECONDS

/datum/assembly_craft/stationary/basic_sentry
	name = "TUR-B \"Bazis\" sentry turret"
	craft_time = 10 SECONDS
	input = list(/obj/item/stack/sheet/composite = 10, /obj/item/stack/sheet/mineral/osmium = 10, /obj/item/stack/sheet/mineral/platinum = 5)
	output = list(/obj/item/weapon/gun/sentry/basic = 1)

/datum/assembly_craft/stationary/sentry_magazine
	name = "TUR-B magazine (10x28mm)"
	input = list(/obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/ammo_magazine/sentry = 1)

/datum/assembly_craft/stationary/minisentry_magazine
	name = "TUR-M magazine (10x20mm)"
	input = list(/obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 2)
	output = list(/obj/item/ammo_magazine/minisentry = 1)

/datum/assembly_craft/stationary/sentry_sniper_magazine
	name = "TUR-SN magazine (9x39mm)"
	input = list(/obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 3)
	output = list(/obj/item/ammo_magazine/sentry/sniper = 1)

/datum/assembly_craft/stationary/sentry_shotgun_magazine
	name = "TUR-SH magazine (12G)"
	input = list(/obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 2)
	output = list(/obj/item/ammo_magazine/sentry/shotgun = 1)

/datum/assembly_craft/stationary/sentry_flamer_tank
	name = "TUR-F small fuel tank"
	input = list(/obj/item/stack/sheet/metal = 3, /obj/item/stack/sheet/mineral/phoron = 3)
	output = list(/obj/item/ammo_magazine/flamer_tank/large/sentry = 1)

/datum/assembly_craft/stationary/sentry_upgrade_kit
	name = "TUR-B upgrade kit"
	input = list(/obj/item/stack/sheet/plasteel = 5, /obj/item/stack/sheet/mineral/platinum = 5, /obj/item/stack/sheet/mineral/copper = 10)
	output = list(/obj/item/sentry_upgrade_kit = 1)

/datum/assembly_craft/stationary/buildasentry
	name = "Build-A-Sentry attachment system"
	input = list(/obj/item/stack/sheet/composite = 10, /obj/item/stack/sheet/mineral/osmium = 10, /obj/item/stack/sheet/mineral/silver = 5)
	output = list(/obj/item/attachable/buildasentry = 1)

/datum/assembly_craft/stationary/hsg102
	name = "HSG-102 mounted heavy smartmachinegun"
	craft_time = 30 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 25, /obj/item/stack/sheet/mineral/osmium = 50, /obj/item/stack/sheet/mineral/platinum = 10)
	output = list(/obj/item/weapon/gun/hsg102 = 1)

/datum/assembly_craft/stationary/hsg102_magazine
	name = "HSG-102 drum magazine (10x30mm Caseless)"
	input = list(/obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/ammo_magazine/hsg102 = 1)

/datum/assembly_craft/stationary/standard_minigun
	name = "MG-2005 mounted minigun"
	craft_time = 30 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 25, /obj/item/stack/sheet/mineral/osmium = 50, /obj/item/stack/sheet/mineral/platinum = 5)
	output = list(/obj/item/weapon/gun/standard_minigun = 1)

/datum/assembly_craft/stationary/heavy_minigun_magazine
	name = "MG-2005 box magazine (7.62x51mm)"
	input = list(/obj/item/stack/sheet/mineral/osmium = 10, /obj/item/stack/gun_powder = 2)
	output = list(/obj/item/ammo_magazine/heavy_minigun = 1)

/datum/assembly_craft/stationary/atr22
	name = "ATR-22 mounted flak gun"
	craft_time = 30 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 50, /obj/item/stack/sheet/mineral/osmium = 50, /obj/item/stack/sheet/mineral/platinum = 5)
	output = list(/obj/item/weapon/gun/atr22 = 1)

/datum/assembly_craft/stationary/atr22_shell
	name = "ATR-22 high-velocity magazine (20mm)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 2, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/ammo_magazine/atr22 = 1)

/datum/assembly_craft/stationary/atr22_shell/flak
	name = "ATR-22 smart-detonating magazine(20mm)"
	output = list(/obj/item/ammo_magazine/atr22/flak = 1)

/datum/assembly_craft/stationary/agls37
	name = "AGLS-37 Kauser automatic grenade launcher"
	craft_time = 10 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 25, /obj/item/stack/sheet/mineral/osmium = 25)
	output = list(/obj/item/weapon/gun/agls37 = 1)

/datum/assembly_craft/stationary/agls37_he
	name = "AGLS-37 HE magazine (40mm Caseless)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 1, /obj/item/stack/gun_powder = 5)
	output = list(/obj/item/ammo_magazine/agls37 = 1)

/datum/assembly_craft/stationary/agls37_fragmentation
	name = "AGLS-37 Frag magazine (40mm Caseless)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 1, /obj/item/stack/gun_powder = 4)
	output = list(/obj/item/ammo_magazine/agls37/fragmentation = 1)

/datum/assembly_craft/stationary/agls37_incendiary
	name = "AGLS-37 WP magazine (40mm Caseless)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 1, /obj/item/stack/gun_powder = 4)
	output = list(/obj/item/ammo_magazine/agls37/incendiary = 1)

/datum/assembly_craft/stationary/agls37_flare
	name = "AGLS-37 Flare magazine (40mm Caseless)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 1, /obj/item/stack/gun_powder = 2)
	output = list(/obj/item/ammo_magazine/agls37/flare = 1)

/datum/assembly_craft/stationary/agls37_cloak
	name = "AGLS-37 Cloak magazine (40mm Caseless)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 1, /obj/item/stack/gun_powder = 3)
	output = list(/obj/item/ammo_magazine/agls37/cloak = 1)

/datum/assembly_craft/stationary/agls37_tanglefoot
	name = "AGLS-37 Tanglefoot magazine (40mm Caseless)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 1, /obj/item/stack/gun_powder = 4)
	output = list(/obj/item/ammo_magazine/agls37/tanglefoot = 1)

/datum/assembly_craft/stationary/at36
	name = "\improper AT-36 anti tank gun"
	craft_time = 30 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 50, /obj/item/stack/sheet/mineral/osmium = 50, /obj/item/stack/sheet/mineral/platinum = 10)
	output = list(/obj/item/weapon/gun/at36 = 1)

/datum/assembly_craft/stationary/at36_shell
	name = "AT-36 AP-HE Shell (37mm)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 1, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/ammo_magazine/at36 = 1)

/datum/assembly_craft/stationary/at36_shell/apcr
	name = "AT-36 APCR Shell (37mm)"
	output = list(/obj/item/ammo_magazine/at36/apcr = 1)

/datum/assembly_craft/stationary/at36_shell/he
	name = "AT-36 HE Shell (37mm)"
	output = list(/obj/item/ammo_magazine/at36/he = 1)

/datum/assembly_craft/stationary/at36_shell/beehive
	name = "AT-36 Beehive Shell (37mm)"
	output = list(/obj/item/ammo_magazine/at36/beehive = 1)

/datum/assembly_craft/stationary/at36_shell/incendiary
	name = "AT-36 Napalm Shell (37mm)"
	output = list(/obj/item/ammo_magazine/at36/incend = 1)

/datum/assembly_craft/stationary/fk88
	name = "\improper FK-88 mounted flak gun"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 50, /obj/item/stack/sheet/mineral/osmium = 100, /obj/item/stack/sheet/mineral/platinum = 20)
	output = list(/obj/item/weapon/gun/fk88 = 1)

/datum/assembly_craft/stationary/fk88_he
	name = "FK-88 HE shell (155mm Shell)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 1, /obj/item/stack/gun_powder = 5)
	output = list(/obj/item/ammo_magazine/fk88/he = 1)

/datum/assembly_craft/stationary/fk88_he/unguided
	name = "FK-88 unguided HE shell (155mm Shell)"
	output = list(/obj/item/ammo_magazine/fk88/he/unguided = 1)

/datum/assembly_craft/stationary/fk88_sabot
	name = "FK-88 APFDS shell (155mm Shell)"
	input = list(/obj/item/stack/sheet/jeweler_steel = 1, /obj/item/stack/gun_powder = 5)
	output = list(/obj/item/ammo_magazine/fk88/sabot = 1)

/datum/assembly_craft/stationary/mg27
	name = "MG-27 medium machinegun"
	input = list(/obj/item/stack/sheet/metal = 20)
	output = list(/obj/item/weapon/gun/mg27 = 1)

/datum/assembly_craft/stationary/hmg08
	name = "HMG-08 heavy machinegun"
	craft_time = 10 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 12, /obj/item/stack/sheet/mineral/osmium = 25, /obj/item/stack/sheet/mineral/platinum = 5)
	output = list(/obj/item/weapon/gun/hmg08 = 1)

/datum/assembly_craft/stationary/hmg08_drum
	name = "HMG-08 drum magazine (10x30mm Caseless)"
	input = list(/obj/item/stack/sheet/mineral/osmium = 8, /obj/item/stack/gun_powder = 3)
	output = list(/obj/item/ammo_magazine/hmg08 = 1)

/datum/assembly_craft/stationary/hmg08_box
	name = "HMG-08 box magazine (10x30mm Caseless)"
	input = list(/obj/item/stack/sheet/mineral/osmium = 4, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/ammo_magazine/hmg08/small = 1)

