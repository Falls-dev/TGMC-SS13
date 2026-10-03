/*******************************************************************************
EXPLOSIVES
*******************************************************************************/
/datum/assembly_craft/explosives
	group = "Explosives"
	craft_time = 8 SECONDS

/datum/assembly_craft/explosives/claymore
	name = "M20 Claymore anti-personnel mine"
	input = list(/obj/item/stack/sheet/composite = 2, /obj/item/stack/gun_powder = 5)
	output = list(/obj/item/explosive/mine = 1)

/datum/assembly_craft/explosives/minelayer
	name = "M21 APRDS \"Minelayer\""
	input = list(/obj/item/stack/sheet/metal = 5, /obj/item/stack/sheet/mineral/copper = 5)
	output = list(/obj/item/minelayer = 1)

//-------------------------------------------------------
//nades

/datum/assembly_craft/explosives/razornade
	name = "Razorburn grenade box"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/composite = 50, /obj/item/stack/sheet/metal = 50, /obj/item/stack/gun_powder = 15)
	output = list(/obj/item/storage/box/visual/grenade/razorburn = 1)

/datum/assembly_craft/explosives/sticky_tangle_box
	name = "M45-T adhesive tanglefoot grenade box"
	craft_time = 30 SECONDS
	input = list(/obj/item/stack/sheet/composite = 25, /obj/item/stack/gun_powder = 10, /obj/item/stack/sheet/mineral/phoron = 15)
	output = list(/obj/item/storage/box/visual/grenade/drain/sticky = 1)

/datum/assembly_craft/explosives/antigas_box
	name = "M40-AG anti-gas grenade box"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/composite = 45, /obj/item/stack/gun_powder = 25, /obj/item/stack/sheet/mineral/phoron = 30, /obj/item/stack/sheet/mineral/silver = 10)
	output = list(/obj/item/storage/box/visual/grenade/antigas = 1)

/datum/assembly_craft/explosives/sticky_box
	name = "M40 adhesive charge grenade box"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/composite = 20, /obj/item/stack/gun_powder = 20, /obj/item/stack/sheet/cloth = 20)
	output = list(/obj/item/storage/box/visual/grenade/sticky = 1)

/datum/assembly_craft/explosives/smokebomb_box
	name = "M40 HSDP smokebomb grenade box"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/composite = 15, /obj/item/stack/gun_powder = 25)
	output = list(/obj/item/storage/box/visual/grenade/smokebomb = 1)

/datum/assembly_craft/explosives/frag_box
	name = "M40 HEDP high explosive grenade box"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/composite = 25, /obj/item/stack/gun_powder = 25)
	output = list(/obj/item/storage/box/visual/grenade/frag = 1)

/datum/assembly_craft/explosives/cloaker_box
	name = "M45 cloaker grenade box"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/composite = 25, /obj/item/stack/gun_powder = 15, /obj/item/stack/sheet/mineral/phoron = 5)
	output = list(/obj/item/storage/box/visual/grenade/cloaker = 1)

/datum/assembly_craft/explosives/cloak_box
	name = "M40-2 SCDP grenade box"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/composite = 25, /obj/item/stack/gun_powder = 15, /obj/item/stack/sheet/mineral/phoron = 5)
	output = list(/obj/item/storage/box/visual/grenade/cloak = 1)

/datum/assembly_craft/explosives/lasburster_box
	name = "M80 lasburster grenade box"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/composite = 25, /obj/item/stack/gun_powder = 15, /obj/item/stack/sheet/mineral/silver = 5)
	output = list(/obj/item/storage/box/visual/grenade/lasburster = 1)

/datum/assembly_craft/explosives/incendiary_box
	name = "M40 HIDP incendiary explosive grenade box"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/composite = 25, /obj/item/stack/gun_powder = 25, /obj/item/stack/sheet/mineral/phoron = 5)
	output = list(/obj/item/storage/box/visual/grenade/incendiary = 1)

/datum/assembly_craft/explosives/bignade
	name = "M15 fragmentation grenade box"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/metal = 25, /obj/item/stack/gun_powder = 50)
	output = list(/obj/item/storage/box/visual/grenade/m15 = 1)

/datum/assembly_craft/explosives/trailblazer_box
	name = "M45 trailblazer grenade box"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/composite = 25, /obj/item/stack/gun_powder = 15, /obj/item/stack/sheet/mineral/phoron = 15)
	output = list(/obj/item/storage/box/visual/grenade/trailblazer = 1)

/datum/assembly_craft/explosives/phosphos
	name = "M40 HSDP grenade box"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 45, /obj/item/stack/gun_powder = 100)
	output = list(/obj/item/storage/box/visual/grenade/phosphorus = 1)

/datum/assembly_craft/explosives/hefa_box
	name = "M25 HEFA grenade box"
	craft_time = 30 SECONDS
	input = list(/obj/item/stack/sheet/composite = 50, /obj/item/stack/gun_powder = 35, /obj/item/stack/sheet/mineral/platinum = 5)
	output = list(/obj/item/storage/box/visual/grenade/hefa = 1)

/datum/assembly_craft/explosives/drain_box
	name = "M40-T gas grenade box"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/composite = 30, /obj/item/stack/gun_powder = 15, /obj/item/stack/sheet/mineral/phoron = 60)
	output = list(/obj/item/storage/box/visual/grenade/drain = 1)

/datum/assembly_craft/explosives/trailblazer_phosphorus_box
	name = "M45 phosphorous trailblazer grenade box"
	craft_time = 40 SECONDS
	input = list(/obj/item/stack/sheet/composite = 25, /obj/item/stack/gun_powder = 25, /obj/item/stack/sheet/mineral/phoron = 30)
	output = list(/obj/item/storage/box/visual/grenade/trailblazer/phosphorus = 1)

//-------------------------------------------------------
//charges

/datum/assembly_craft/explosives/c4
	name = "Plastic explosive"
	input = list(/obj/item/stack/sheet/composite = 1, /obj/item/stack/gun_powder = 5)
	output = list(/obj/item/explosive/plastique = 1)

/datum/assembly_craft/explosives/genghis
	name = "EX-62 Genghis incendiary charge"
	craft_time = 18 SECONDS
	input = list(/obj/item/stack/sheet/composite = 1, /obj/item/stack/gun_powder = 15)
	output = list(/obj/item/explosive/plastique/genghis_charge = 1)

/datum/assembly_craft/explosives/detpack
	name = "Detonation pack"
	craft_time = 12 SECONDS
	input = list(/obj/item/stack/sheet/composite = 1, /obj/item/stack/gun_powder = 10)
	output = list(/obj/item/explosive/plastique/detpack = 1)

/datum/assembly_craft/explosives/trench_charge
	name = "Trench charge"
	input = list(/obj/item/stack/sheet/composite = 1, /obj/item/stack/gun_powder = 5)
	output = list(/obj/item/explosive/plastique/trench = 1)

/datum/assembly_craft/explosives/detpack_trench_charge
	name = "Better trench charge"
	input = list(/obj/item/stack/sheet/composite = 1, /obj/item/stack/gun_powder = 10)
	output = list(/obj/item/explosive/plastique/detpack/trench = 1)

//-------------------------------------------------------
//T-50S mortar

/datum/assembly_craft/explosives/mortar_kit
	name = "T-50S mortar crate"
	craft_time = 15 SECONDS
	input = list(/obj/item/stack/sheet/mineral/osmium = 10, /obj/item/stack/sheet/metal = 10, /obj/item/stack/sheet/mineral/platinum = 2)
	output = list(/obj/item/mortar_kit = 1)

/datum/assembly_craft/explosives/mortar_he
	name = "T-50S mortar HE shell (x2)"
	input = list(/obj/item/stack/sheet/metal = 1, /obj/item/stack/gun_powder = 2)
	output = list(/obj/item/mortal_shell/he = 2)

/datum/assembly_craft/explosives/mortar_incendiary
	name = "T-50S mortar incendiary shell (x2)"
	input = list(/obj/item/stack/sheet/metal = 1, /obj/item/stack/gun_powder = 2)
	output = list(/obj/item/mortal_shell/incendiary = 2)

/datum/assembly_craft/explosives/mortar_flare
	name = "T-50S mortar flare shell (x2)"
	input = list(/obj/item/stack/sheet/metal = 1, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/mortal_shell/flare = 2)

/datum/assembly_craft/explosives/mortar_smoke
	name = "T-50S mortar smoke shell (x2)"
	input = list(/obj/item/stack/sheet/metal = 1, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/mortal_shell/smoke = 2)

/datum/assembly_craft/explosives/mortar_plasmaloss
	name = "T-50S mortar tanglefoot shell"
	input = list(/obj/item/stack/sheet/metal = 1, /obj/item/stack/gun_powder = 1, /obj/item/stack/sheet/mineral/phoron = 1)
	output = list(/obj/item/mortal_shell/plasmaloss = 1)

//-------------------------------------------------------
//T-10K knee mortar

/datum/assembly_craft/explosives/knee_mortar_kit
	name = "T-10K knee mortar"
	input = list(/obj/item/stack/sheet/metal = 10)
	output = list(/obj/item/mortar_kit/knee = 1)

/datum/assembly_craft/explosives/knee_mortar_ammo
	name = "TA-10K knee mortar HE shell"
	craft_time = 2 SECONDS
	input = list(/obj/item/stack/sheet/metal = 1, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/mortal_shell/knee = 2)

//-------------------------------------------------------
//TA-40L MLRS

/datum/assembly_craft/explosives/mlrs_kit
	name = "TA-40L multiple rocket system"
	craft_time = 40 SECONDS
	input = list(/obj/item/stack/sheet/mineral/osmium = 40, /obj/item/stack/sheet/mineral/platinum = 5)
	output = list(/obj/item/mortar_kit/mlrs = 1)

/datum/assembly_craft/explosives/mlrs_rockets
	name = "TA-40L MLRS rocket pack (x16)"
	input = list(/obj/item/stack/sheet/metal = 16, /obj/item/stack/gun_powder = 8)
	output = list(/obj/item/storage/box/mlrs_rockets = 1)

/datum/assembly_craft/explosives/mlrs_rockets_gas
	name = "TA-40L X-50 MLRS rocket pack (x16)"
	input = list(/obj/item/stack/sheet/metal = 16, /obj/item/stack/gun_powder = 16)
	output = list(/obj/item/storage/box/mlrs_rockets_gas = 1)

/datum/assembly_craft/explosives/mlrs_rockets_tangle
	name = "TA-40L T-33 MLRS rocket pack (x16)"
	input = list(/obj/item/stack/sheet/metal = 16, /obj/item/stack/gun_powder = 8, /obj/item/stack/sheet/mineral/phoron = 8)
	output = list(/obj/item/storage/box/mlrs_rockets_tangle = 1)

//-------------------------------------------------------
//AI targeting

/datum/assembly_craft/explosives/ai_target_beacon
	name = "AI artillery targeting module"
	input = list(/obj/item/stack/sheet/mineral/silver = 5, /obj/item/stack/sheet/glass/glass = 5, /obj/item/stack/sheet/mineral/copper = 5)
	output = list(/obj/item/ai_target_beacon = 1)

//-------------------------------------------------------
//TA-100Y howitzer

/datum/assembly_craft/explosives/howitzer_kit
	name = "TA-100Y howitzer"
	craft_time = 30 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 15, /obj/item/stack/sheet/mineral/osmium = 50, /obj/item/stack/sheet/mineral/platinum = 10)
	output = list(/obj/item/mortar_kit/howitzer = 1)

/datum/assembly_craft/explosives/howitzer_he
	name = "TA-100Y howitzer HE shell"
	input = list(/obj/item/stack/sheet/metal = 3, /obj/item/stack/gun_powder = 5)
	output = list(/obj/item/mortal_shell/howitzer/he = 1)

/datum/assembly_craft/explosives/howitzer_incendiary
	name = "TA-100Y howitzer incendiary shell"
	input = list(/obj/item/stack/sheet/metal = 3, /obj/item/stack/gun_powder = 5)
	output = list(/obj/item/mortal_shell/howitzer/incendiary = 1)

/datum/assembly_craft/explosives/howitzer_white_phos
	name = "TA-100Y howitzer white phosporous smoke shell"
	input = list(/obj/item/stack/sheet/metal = 3, /obj/item/stack/gun_powder = 5, /obj/item/stack/sheet/mineral/phoron = 2)
	output = list(/obj/item/mortal_shell/howitzer/white_phos = 1)

/datum/assembly_craft/explosives/howitzer_plasmaloss
	name = "TA-100Y howitzer tanglefoot shell"
	input = list(/obj/item/stack/sheet/metal = 3, /obj/item/stack/gun_powder = 4, /obj/item/stack/sheet/mineral/phoron = 1)
	output = list(/obj/item/mortal_shell/howitzer/plasmaloss = 1)
