/datum/assembly_craft/engineering
	group = "Engineering"
	craft_time = 10 SECONDS

/datum/assembly_craft/engineering/plas50
	name = "50 metal + 30 phoron > 50 plasteel"
	input = list(/obj/item/stack/sheet/metal = 50, /obj/item/stack/sheet/mineral/phoron = 30) // 200 + 200 = 400 points
	output = list(/obj/item/stack/sheet/plasteel/large_stack = 1) // 400 points

/datum/assembly_craft/engineering/plas_deconstruction
	name = "50 plasteel > 50 metal, 30 phoron"
	input = list(/obj/item/stack/sheet/plasteel = 50) // 400 points
	output = list(/obj/item/stack/sheet/metal/large_stack = 1, /obj/item/stack/sheet/mineral/phoron/medium_stack = 1) // 200 + 200 = 400 points

/datum/assembly_craft/engineering/composite
	name = "25 metal + 25 copper > 50 composite"
	input = list(/obj/item/stack/sheet/metal = 25, /obj/item/stack/sheet/mineral/copper = 25) // 100 + 100 = 200 points
	output = list(/obj/item/stack/sheet/composite/large_stack = 1) // 400 points

/datum/assembly_craft/engineering/jeweler_steel
	name = "2 metal + 1 platinum > 3 jeweler steel"
	input = list(/obj/item/stack/sheet/metal = 2, /obj/item/stack/sheet/mineral/platinum = 1) // 8 + 12 = 20 points
	output = list(/obj/item/stack/sheet/jeweler_steel = 3) // 20 points

/datum/assembly_craft/engineering/osmium50_silver
	name = "25 silver + 10 phoron > 50 osmium"
	input = list(/obj/item/stack/sheet/mineral/silver = 25, /obj/item/stack/sheet/mineral/phoron = 10) // 200 + 66 = 266 points
	output = list(/obj/item/stack/sheet/mineral/osmium/large_stack = 1) // 300 points

/datum/assembly_craft/engineering/osmium50_copper
	name = "50 copper + 10 phoron > 50 osmium"
	input = list(/obj/item/stack/sheet/mineral/copper = 50, /obj/item/stack/sheet/mineral/phoron = 10) // 200 + 66 = 266 points
	output = list(/obj/item/stack/sheet/mineral/osmium/large_stack = 1) // 300 points

/datum/assembly_craft/engineering/osmium50_plasteel
	name = "25 plasteel + 15 phoron > 50 osmium"
	input = list(/obj/item/stack/sheet/plasteel = 25, /obj/item/stack/sheet/mineral/phoron = 15) // 200 + 100 = 300 points
	output = list(/obj/item/stack/sheet/mineral/osmium/large_stack = 1) // 300 points

/datum/assembly_craft/engineering/junk_platinum_convert
	name = "5 junk > 4 copper, 1 platinum"
	craft_time = 15 SECONDS
	input = list(/obj/item/stack/sheet/mineral/junk = 5) // 30 points
	output = list(/obj/item/stack/sheet/mineral/copper = 4, /obj/item/stack/sheet/mineral/platinum = 1) // 16 + 12 = 28 points

/datum/assembly_craft/engineering/junk_silver_convert
	name = "4 junk > 1 plasteel, 1 silver"
	craft_time = 8 SECONDS
	input = list(/obj/item/stack/sheet/mineral/junk = 4) // 24 points
	output = list(/obj/item/stack/sheet/plasteel = 1, /obj/item/stack/sheet/mineral/silver = 1) // 8 + 8 = 16 points

/datum/assembly_craft/engineering/junk_phoron_convert
	name = "5 junk > 3 glass, 2 phoron"
	craft_time = 5 SECONDS
	input = list(/obj/item/stack/sheet/mineral/junk = 5) // 30 points
	output = list(/obj/item/stack/sheet/glass/glass = 3, /obj/item/stack/sheet/mineral/phoron = 2) // 6 + 13 = 19 points

/datum/assembly_craft/engineering/junk_phoron_metal
	name = "50 junk > 50 metal"
	craft_time = 15 SECONDS
	input = list(/obj/item/stack/sheet/mineral/junk = 50) // 300 points
	output = list(/obj/item/stack/sheet/metal/large_stack = 1) // 200 points

/datum/assembly_craft/engineering/deployable_floodlight
	name = "Deployable floodlight"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 3, /obj/item/stack/sheet/glass/glass = 3) // 24 + 6 = 30 points
	output = list(/obj/item/deployable_floodlight = 1) // 30 points
