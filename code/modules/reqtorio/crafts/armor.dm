/datum/assembly_craft/armor
	group = "Armor"
	craft_time = 5 SECONDS

/datum/assembly_craft/armor/swat_mask
	name = "SWAT mask"
	input = list(/obj/item/stack/sheet/plasteel = 2, /obj/item/stack/sheet/glass/glass = 2, /obj/item/stack/sheet/cloth = 2)
	output = list(/obj/item/clothing/mask/gas/swat = 1)

/datum/assembly_craft/armor/b18
	name = "B18 armor set"
	input = list(/obj/item/stack/sheet/plasteel = 75, /obj/item/clothing/mask/gas/swat = 1, /obj/item/armor_module/module/valkyrie_autodoc, /obj/item/stack/sheet/mineral/platinum = 20, /obj/item/stack/sheet/mineral/osmium = 50, /obj/item/stack/sheet/mineral/phoron = 30)
	output = list(/datum/supply_packs/armor/b18)
	craft_time = 120 SECONDS

/datum/assembly_craft/armor/b17
	name = "B17 armor set"
	input = list(/obj/item/stack/sheet/plasteel = 50, /obj/item/clothing/suit/fire = 1, /obj/item/clothing/suit/radiation = 1, /obj/item/clothing/head/radiation = 1, /obj/item/storage/belt/grenade/b17, /obj/item/stack/sheet/mineral/platinum = 10, /obj/item/stack/sheet/mineral/osmium = 50, /obj/item/stack/sheet/mineral/phoron = 30)
	output = list(/datum/supply_packs/armor/b17)
	craft_time = 90 SECONDS
