/*******************************************************************************
EXPLOSIVES
*******************************************************************************/
/datum/assembly_craft/explosives
	group = "Explosives"
	craft_time = 8 SECONDS

/datum/assembly_craft/explosives/claymore
	name = "M20 Claymore anti-personnel mine"
	input = list(/obj/item/stack/sheet/composite = 1, /obj/item/stack/gun_powder = 5) // 8 + 5 = 13 points
	output = list(/obj/item/explosive/mine = 1) // 150 points

/datum/assembly_craft/explosives/minelayer
	name = "M21 APRDS \"Minelayer\""
	input = list(/obj/item/stack/sheet/metal = 5, /obj/item/stack/sheet/mineral/copper = 5) // 20 + 20 = 40 points
	output = list(/obj/item/minelayer = 1) // 50 points

//-------------------------------------------------------
//nades

/datum/assembly_craft/explosives/razornade
	name = "Razorburn grenade box"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/composite = 50, /obj/item/stack/sheet/metal = 50, /obj/item/stack/gun_powder = 15) // 400 + 200 + 15 = 615 points
	output = list(/obj/item/storage/box/visual/grenade/razorburn = 1) // 500 points

/datum/assembly_craft/explosives/sticky_tangle_box
	name = "M45-T adhesive tanglefoot grenade box"
	craft_time = 30 SECONDS
	input = list(/obj/item/stack/sheet/composite = 25, /obj/item/stack/gun_powder = 10, /obj/item/stack/sheet/mineral/phoron = 15) // 200 + 10 + 105 = 315 points
	output = list(/obj/item/storage/box/visual/grenade/drain/sticky = 1) // 300 points

/datum/assembly_craft/explosives/antigas_box
	name = "M40-AG anti-gas grenade box"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/composite = 45, /obj/item/stack/gun_powder = 25, /obj/item/stack/sheet/mineral/phoron = 30, /obj/item/stack/sheet/mineral/silver = 10) // 360 + 25 + 210 + 80 = 675 points
	output = list(/obj/item/storage/box/visual/grenade/antigas = 1) // 700 points

/datum/assembly_craft/explosives/sticky_box
	name = "M40 adhesive charge grenade box"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/composite = 20, /obj/item/stack/gun_powder = 20, /obj/item/stack/sheet/cloth = 20) // 160 + 20 + 80 = 260 points
	output = list(/obj/item/storage/box/visual/grenade/sticky = 1) // 310 points

/datum/assembly_craft/explosives/smokebomb_box
	name = "M40 HSDP smokebomb grenade box"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/composite = 15, /obj/item/stack/gun_powder = 25) // 120 + 25 = 145 points
	output = list(/obj/item/storage/box/visual/grenade/smokebomb = 1) // 310 points

/datum/assembly_craft/explosives/frag_box
	name = "M40 HEDP high explosive grenade box"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/composite = 25, /obj/item/stack/gun_powder = 25) // 200 + 25 = 225 points
	output = list(/obj/item/storage/box/visual/grenade/frag = 1) // 310 points

/datum/assembly_craft/explosives/cloaker_box
	name = "M45 cloaker grenade box"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/composite = 25, /obj/item/stack/gun_powder = 15, /obj/item/stack/sheet/mineral/phoron = 5) // 200 + 15 + 35 = 250 points
	output = list(/obj/item/storage/box/visual/grenade/cloaker = 1) // 310 points

/datum/assembly_craft/explosives/cloak_box
	name = "M40-2 SCDP grenade box"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/composite = 25, /obj/item/stack/gun_powder = 15, /obj/item/stack/sheet/mineral/phoron = 5) // 200 + 15 + 35 = 250 points
	output = list(/obj/item/storage/box/visual/grenade/cloak = 1) // 310 points

/datum/assembly_craft/explosives/lasburster_box
	name = "M80 lasburster grenade box"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/composite = 25, /obj/item/stack/gun_powder = 15, /obj/item/stack/sheet/mineral/silver = 5) // 200 + 15 + 40 = 255 points
	output = list(/obj/item/storage/box/visual/grenade/lasburster = 1) // 310 points

/datum/assembly_craft/explosives/incendiary_box
	name = "M40 HIDP incendiary explosive grenade box"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/composite = 25, /obj/item/stack/gun_powder = 25, /obj/item/stack/sheet/mineral/phoron = 5) // 200 + 25 + 35 = 260 points
	output = list(/obj/item/storage/box/visual/grenade/incendiary = 1) // 350 points

/datum/assembly_craft/explosives/bignade
	name = "M15 fragmentation grenade box"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/metal = 25, /obj/item/stack/gun_powder = 50) // 100 + 50 = 150 points
	output = list(/obj/item/storage/box/visual/grenade/m15 = 1) // 350 points

/datum/assembly_craft/explosives/trailblazer_box
	name = "M45 trailblazer grenade box"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/composite = 25, /obj/item/stack/gun_powder = 15, /obj/item/stack/sheet/mineral/phoron = 15) // 200 + 15 + 105 = 320 points
	output = list(/obj/item/storage/box/visual/grenade/trailblazer = 1) // 350 points

/datum/assembly_craft/explosives/phosphos
	name = "M40 HSDP grenade box"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 45, /obj/item/stack/gun_powder = 100) // 360 + 100 = 460 points
	output = list(/obj/item/storage/box/visual/grenade/phosphorus = 1) // 700 points

/datum/assembly_craft/explosives/hefa_box
	name = "M25 HEFA grenade box"
	craft_time = 30 SECONDS
	input = list(/obj/item/stack/sheet/composite = 50, /obj/item/stack/gun_powder = 35, /obj/item/stack/sheet/mineral/platinum = 5) // 400 + 35 + 60 = 495 points
	output = list(/obj/item/storage/box/visual/grenade/hefa = 1) // 550 points

/datum/assembly_craft/explosives/drain_box
	name = "M40-T gas grenade box"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/composite = 30, /obj/item/stack/gun_powder = 15, /obj/item/stack/sheet/mineral/phoron = 60) // 240 + 15 + 420 = 675 points
	output = list(/obj/item/storage/box/visual/grenade/drain = 1) // 700 points

/datum/assembly_craft/explosives/trailblazer_phosphorus_box
	name = "M45 phosphorous trailblazer grenade box"
	craft_time = 40 SECONDS
	input = list(/obj/item/stack/sheet/composite = 25, /obj/item/stack/gun_powder = 25, /obj/item/stack/sheet/mineral/phoron = 30) // 200 + 25 + 210 = 435 points
	output = list(/obj/item/storage/box/visual/grenade/trailblazer/phosphorus = 1) // 600 points

//-------------------------------------------------------
//charges

/datum/assembly_craft/explosives/c4
	name = "Plastic explosive"
	input = list(/obj/item/stack/sheet/composite = 1, /obj/item/stack/gun_powder = 5) // 8 + 5 = 13 points
	output = list(/obj/item/explosive/plastique = 1) // 30 points

/datum/assembly_craft/explosives/genghis
	name = "EX-62 Genghis incendiary charge"
	craft_time = 18 SECONDS
	input = list(/obj/item/stack/sheet/composite = 1, /obj/item/stack/gun_powder = 15) // 8 + 15 = 23 points
	output = list(/obj/item/explosive/plastique/genghis_charge = 1) // 150 points

/datum/assembly_craft/explosives/detpack
	name = "Detonation pack"
	craft_time = 12 SECONDS
	input = list(/obj/item/stack/sheet/composite = 1, /obj/item/stack/gun_powder = 10) // 8 + 10 = 18 points
	output = list(/obj/item/explosive/plastique/detpack = 1) // 50 points

/datum/assembly_craft/explosives/trench_charge
	name = "Trench charge"
	input = list(/obj/item/stack/sheet/composite = 1, /obj/item/stack/gun_powder = 5) // 8 + 5 = 13 points
	output = list(/obj/item/explosive/plastique/trench = 1) // 30 points

/datum/assembly_craft/explosives/detpack_trench_charge
	name = "Better trench charge"
	input = list(/obj/item/stack/sheet/composite = 1, /obj/item/stack/gun_powder = 10) // 8 + 10 = 18 points
	output = list(/obj/item/explosive/plastique/detpack/trench = 1) // 50 points

//-------------------------------------------------------
//T-50S mortar

/datum/assembly_craft/explosives/mortar_kit
	name = "T-50S mortar crate"
	craft_time = 15 SECONDS
	input = list(/obj/item/stack/sheet/mineral/osmium = 10, /obj/item/stack/sheet/metal = 10, /obj/item/stack/sheet/mineral/platinum = 2) // 60 + 40 + 24 = 124 points
	output = list(/obj/item/mortar_kit = 1) // 250 points

/datum/assembly_craft/explosives/mortar_he
	name = "T-50S mortar HE shell (x2)"
	input = list(/obj/item/stack/sheet/metal = 1, /obj/item/stack/gun_powder = 2) // 4 + 2 = 6 points
	output = list(/obj/item/mortal_shell/he = 2) // 10 points

/datum/assembly_craft/explosives/mortar_incendiary
	name = "T-50S mortar incendiary shell (x2)"
	input = list(/obj/item/stack/sheet/metal = 1, /obj/item/stack/gun_powder = 2) // 4 + 2 = 6 points
	output = list(/obj/item/mortal_shell/incendiary = 2) // 10 points

/datum/assembly_craft/explosives/mortar_flare
	name = "T-50S mortar flare shell (x2)"
	input = list(/obj/item/stack/sheet/metal = 1, /obj/item/stack/gun_powder = 1) // 4 + 1 = 5 points
	output = list(/obj/item/mortal_shell/flare = 2) // 5 points

/datum/assembly_craft/explosives/mortar_smoke
	name = "T-50S mortar smoke shell (x2)"
	input = list(/obj/item/stack/sheet/metal = 1, /obj/item/stack/gun_powder = 1) // 4 + 1 = 5 points
	output = list(/obj/item/mortal_shell/smoke = 2) // 5 points

/datum/assembly_craft/explosives/mortar_plasmaloss
	name = "T-50S mortar tanglefoot shell"
	input = list(/obj/item/stack/sheet/metal = 1, /obj/item/stack/gun_powder = 1, /obj/item/stack/sheet/mineral/phoron = 1) // 4 + 1 + 7 = 12 points
	output = list(/obj/item/mortal_shell/plasmaloss = 1) // 10 points

//-------------------------------------------------------
//T-10K knee mortar

/datum/assembly_craft/explosives/knee_mortar_kit
	name = "T-10K knee mortar"
	input = list(/obj/item/stack/sheet/metal = 10) // 40 points
	output = list(/obj/item/mortar_kit/knee = 1) // 50 points

/datum/assembly_craft/explosives/knee_mortar_ammo
	name = "TA-10K knee mortar HE shell"
	craft_time = 2 SECONDS
	input = list(/obj/item/stack/sheet/metal = 1, /obj/item/stack/gun_powder = 1) // 4 + 1 = 5 points
	output = list(/obj/item/mortal_shell/knee = 2) // 5 points

//-------------------------------------------------------
//TA-40L MLRS

/datum/assembly_craft/explosives/mlrs_kit
	name = "TA-40L multiple rocket system"
	craft_time = 40 SECONDS
	input = list(/obj/item/stack/sheet/mineral/osmium = 40, /obj/item/stack/sheet/mineral/platinum = 5) // 240 + 60 = 300 points
	output = list(/obj/item/mortar_kit/mlrs = 1) // 450 points

/datum/assembly_craft/explosives/mlrs_rockets
	name = "TA-40L MLRS rocket pack (x16)"
	input = list(/obj/item/stack/sheet/metal = 16, /obj/item/stack/gun_powder = 8) // 64 + 8 = 72 points
	output = list(/obj/item/storage/box/mlrs_rockets = 1) // 40 points

/datum/assembly_craft/explosives/mlrs_rockets_gas
	name = "TA-40L X-50 MLRS rocket pack (x16)"
	input = list(/obj/item/stack/sheet/metal = 16, /obj/item/stack/gun_powder = 16) // 64 + 16 = 80 points
	output = list(/obj/item/storage/box/mlrs_rockets_gas = 1) // 50 points

/datum/assembly_craft/explosives/mlrs_rockets_tangle
	name = "TA-40L T-33 MLRS rocket pack (x16)"
	input = list(/obj/item/stack/sheet/metal = 16, /obj/item/stack/gun_powder = 8, /obj/item/stack/sheet/mineral/phoron = 8) // 64 + 8 + 56 = 128 points
	output = list(/obj/item/storage/box/mlrs_rockets_tangle = 1) // 50 points

//-------------------------------------------------------
//AI targeting

/datum/assembly_craft/explosives/ai_target_beacon
	name = "AI artillery targeting module"
	input = list(/obj/item/stack/sheet/mineral/silver = 5, /obj/item/stack/sheet/glass/glass = 5, /obj/item/stack/sheet/mineral/copper = 5) // 40 + 10 + 20 = 70 points
	output = list(/obj/item/ai_target_beacon = 1) // 50 points

//-------------------------------------------------------
//TA-100Y howitzer

/datum/assembly_craft/explosives/howitzer_kit
	name = "TA-100Y howitzer"
	craft_time = 30 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 15, /obj/item/stack/sheet/mineral/osmium = 50, /obj/item/stack/sheet/mineral/platinum = 10) // 120 + 300 + 120 = 540 points
	output = list(/obj/item/mortar_kit/howitzer = 1) // 500 points

/datum/assembly_craft/explosives/howitzer_he
	name = "TA-100Y howitzer HE shell"
	input = list(/obj/item/stack/sheet/metal = 3, /obj/item/stack/gun_powder = 5) // 12 + 5 = 17 points
	output = list(/obj/item/mortal_shell/howitzer/he = 1) // 30 points

/datum/assembly_craft/explosives/howitzer_incendiary
	name = "TA-100Y howitzer incendiary shell"
	input = list(/obj/item/stack/sheet/metal = 3, /obj/item/stack/gun_powder = 5) // 12 + 5 = 17 points
	output = list(/obj/item/mortal_shell/howitzer/incendiary = 1) // 30 points

/datum/assembly_craft/explosives/howitzer_white_phos
	name = "TA-100Y howitzer white phosporous smoke shell"
	input = list(/obj/item/stack/sheet/metal = 3, /obj/item/stack/gun_powder = 5, /obj/item/stack/sheet/mineral/phoron = 2) // 12 + 5 + 14 = 31 points
	output = list(/obj/item/mortal_shell/howitzer/white_phos = 1) // 45 points

/datum/assembly_craft/explosives/howitzer_plasmaloss
	name = "TA-100Y howitzer tanglefoot shell"
	input = list(/obj/item/stack/sheet/metal = 3, /obj/item/stack/gun_powder = 4, /obj/item/stack/sheet/mineral/phoron = 1) // 12 + 4 + 7 = 23 points
	output = list(/obj/item/mortal_shell/howitzer/plasmaloss = 1) // 45 points
