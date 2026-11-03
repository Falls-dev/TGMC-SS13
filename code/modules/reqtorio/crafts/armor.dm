/datum/assembly_craft/armor
	group = "Armor"
	craft_time = 5 SECONDS

/datum/assembly_craft/armor/swat_mask
	name = "SWAT mask"
	input = list(/obj/item/stack/sheet/plasteel = 2, /obj/item/stack/sheet/glass/glass = 2, /obj/item/stack/sheet/cloth = 2)
	output = list(/obj/item/clothing/mask/gas/swat = 1)

/datum/assembly_craft/armor/b18
	name = "B18 armor set"
	input = list(/obj/item/stack/sheet/plasteel = 50, /obj/item/armor_module/module/mimir_environment_protection/mimir_helmet = 1, /obj/item/armor_module/module/mimir_environment_protection = 1, /obj/item/armor_module/module/tyr_extra_armor = 1, /obj/item/armor_module/module/tyr_head/mark2 = 1, /obj/item/clothing/mask/gas/swat = 1, /obj/item/armor_module/module/valkyrie_autodoc, /obj/item/stack/sheet/mineral/platinum = 20, /obj/item/stack/sheet/mineral/osmium = 50, /obj/item/stack/sheet/mineral/phoron = 30)
	output = list(/datum/supply_packs/armor/b18)
	craft_time = 120 SECONDS

/datum/assembly_craft/armor/b17
	name = "B17 armor set"
	input = list(/obj/item/stack/sheet/plasteel = 50, /obj/item/armor_module/module/mimir_environment_protection/mimir_helmet = 1, /obj/item/armor_module/module/mimir_environment_protection = 1, /obj/item/armor_module/module/tyr_extra_armor = 1, /obj/item/armor_module/module/tyr_head/mark2 = 1, /obj/item/clothing/suit/fire = 1, /obj/item/clothing/suit/radiation = 1, /obj/item/clothing/head/radiation = 1, /obj/item/storage/belt/grenade/b17, /obj/item/stack/sheet/mineral/platinum = 10, /obj/item/stack/sheet/mineral/osmium = 50, /obj/item/stack/sheet/mineral/phoron = 30)
	output = list(/datum/supply_packs/armor/b17)
	craft_time = 90 SECONDS

/datum/assembly_craft/armor/valkyrie_autodoc
	name = "Valkyrie automedical system"
	craft_time = 30 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 10, /obj/item/stack/sheet/mineral/platinum = 5, /obj/item/stack/sheet/mineral/silver = 10, /obj/item/stack/sheet/glass/glass = 10) // 80 + 60 + 80 + 20 = 240 points
	output = list(/obj/item/armor_module/module/valkyrie_autodoc = 1) // 200 points

/datum/assembly_craft/armor/fire_proof
	name = "Surt thermal insulation system"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 5, /obj/item/stack/sheet/mineral/phoron = 10, /obj/item/stack/sheet/cloth = 5) // 40 + 70 + 20 = 130 points
	output = list(/obj/item/armor_module/module/fire_proof = 1, /obj/item/armor_module/module/fire_proof_helmet = 1) // 120 points

/datum/assembly_craft/armor/tyr_extra_armor
	name = "Tyr Mk.2 armor reinforcement system"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 8, /obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/sheet/cloth = 5) // 64 + 30 + 20 = 114 points
	output = list(/obj/item/armor_module/module/tyr_extra_armor = 1, /obj/item/armor_module/module/tyr_head/mark2 = 1) // 120 points

/datum/assembly_craft/armor/mimir_extra_armor
	name = "Mimir Mk.2 environmental resistance system"
	craft_time = 25 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 10, /obj/item/stack/sheet/mineral/osmium = 10, /obj/item/stack/sheet/mineral/phoron = 5) // 80 + 60 + 35 = 175 points
	output = list(/obj/item/armor_module/module/mimir_environment_protection/mimir_helmet = 1, /obj/item/armor_module/module/mimir_environment_protection = 1) // 160 points

/datum/assembly_craft/armor/artemis_mark_two
	name = "Freyr Mk.2 visual assistance helmet system"
	craft_time = 10 SECONDS
	input = list(/obj/item/stack/sheet/glass/glass = 10, /obj/item/stack/sheet/mineral/silver = 2, /obj/item/stack/sheet/mineral/copper = 3) // 20 + 16 + 12 = 48 points
	output = list(/obj/item/armor_module/module/binoculars/artemis_mark_two = 1) // 40 points

/datum/assembly_craft/armor/robot_physical
	name = "Cingulata physical protection armor set"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 40, /obj/item/stack/sheet/mineral/osmium = 50, /obj/item/stack/sheet/mineral/platinum = 15) // 320 + 300 + 180 = 800 points
	output = list(/obj/item/clothing/head/helmet/marine/robot/advanced/physical = 1, /obj/item/clothing/suit/storage/marine/robot/advanced/physical = 1) // 600 points

/datum/assembly_craft/armor/robot_acid
	name = "Exidobate acid protection armor set"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 40, /obj/item/stack/sheet/mineral/osmium = 50, /obj/item/stack/sheet/mineral/phoron = 20) // 320 + 300 + 140 = 760 points
	output = list(/obj/item/clothing/head/helmet/marine/robot/advanced/acid = 1, /obj/item/clothing/suit/storage/marine/robot/advanced/acid = 1) // 600 points

/datum/assembly_craft/armor/robot_bomb
	name = "Tardigrada bomb protection armor set"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 40, /obj/item/stack/sheet/mineral/osmium = 50, /obj/item/stack/sheet/mineral/platinum = 15) // 320 + 300 + 180 = 800 points
	output = list(/obj/item/clothing/head/helmet/marine/robot/advanced/bomb = 1, /obj/item/clothing/suit/storage/marine/robot/advanced/bomb = 1) // 600 points

/datum/assembly_craft/armor/robot_fire
	name = "Urodela fire protection armor set"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 40, /obj/item/stack/sheet/mineral/osmium = 50, /obj/item/stack/sheet/mineral/phoron = 25) // 320 + 300 + 175 = 795 points
	output = list(/obj/item/clothing/head/helmet/marine/robot/advanced/fire = 1, /obj/item/clothing/suit/storage/marine/robot/advanced/fire = 1) // 600 points
