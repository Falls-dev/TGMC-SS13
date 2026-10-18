/datum/assembly_craft/operations
	group = "Operations"
	craft_time = 8 SECONDS

/datum/assembly_craft/operations/supply_beacon
	name = "Supply beacon"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/metal = 10, /obj/item/stack/sheet/glass/glass = 5, /obj/item/stack/sheet/mineral/copper = 5) // 40 + 10 + 20 = 70 points
	output = list(/obj/item/supply_beacon = 1) // 100 points

/datum/assembly_craft/operations/orbital_bombardment_beacon
	name = "Orbital beacon"
	craft_time = 10 SECONDS
	input = list(/obj/item/stack/sheet/metal = 5, /obj/item/stack/sheet/glass/glass = 2, /obj/item/stack/sheet/mineral/silver = 1) // 20 + 4 + 8 = 32 points
	output = list(/obj/item/orbital_bombardment_beacon = 1) // 30 points

/datum/assembly_craft/operations/fulton_extraction_pack
	name = "Fulton extraction pack"
	craft_time = 5 SECONDS
	input = list(/obj/item/stack/sheet/cloth = 10) // 40 points
	output = list(/obj/item/fulton_extraction_pack = 1) // 50 points

/datum/assembly_craft/operations/minerupgrade_automatic
	name = "Mining computer"
	craft_time = 15 SECONDS
	input = list(/obj/item/stack/sheet/metal = 5, /obj/item/stack/sheet/mineral/copper = 5, /obj/item/stack/sheet/glass/glass = 2) // 20 + 20 + 4 = 44 points
	output = list(/obj/item/minerupgrade/automatic = 1) // 50 points

/datum/assembly_craft/operations/minerupgrade_reinforcement
	name = "Reinforced components box"
	craft_time = 15 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 3, /obj/item/stack/sheet/mineral/silver = 3) // 24 + 24 = 48 points
	output = list(/obj/item/minerupgrade/reinforcement = 1) // 50 points

/datum/assembly_craft/operations/minerupgrade_overclock
	name = "High-efficiency drill"
	craft_time = 15 SECONDS
	input = list(/obj/item/stack/sheet/mineral/platinum = 1, /obj/item/stack/sheet/mineral/silver = 1, /obj/item/stack/sheet/mineral/osmium = 5) // 12 + 8 + 30 = 50 points
	output = list(/obj/item/minerupgrade/overclock = 1) // 50 points

/datum/assembly_craft/operations/pinpointer
	name = "Xeno structure pinpointer"
	craft_time = 40 SECONDS
	input = list(/obj/item/stack/sheet/metal = 5, /obj/item/stack/sheet/mineral/silver = 1, /obj/item/stack/sheet/glass/glass = 5) // 20 + 8 + 10 = 38 points
	output = list(/obj/item/pinpointer = 1) // 200 points

/datum/assembly_craft/operations/exportpad
	name = "ASRS Bluespace Export Point"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/mineral/platinum = 5, /obj/item/stack/sheet/mineral/osmium = 10, /obj/item/stack/sheet/mineral/phoron = 10, /obj/item/stack/sheet/plasteel = 5) // 60 + 60 + 70 + 40 = 230 points
	output = list(/obj/machinery/exportpad = 1) // 300 points

/datum/assembly_craft/operations/ob_warhead_cluster
	name = "Cluster orbital warhead"
	craft_time = 40 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 10, /obj/item/stack/sheet/mineral/phoron = 8, /obj/item/stack/gun_powder = 10) // 80 + 56 + 10 = 146 points
	output = list(/obj/structure/ob_ammo/warhead/cluster = 1) // 200 points

/datum/assembly_craft/operations/ob_warhead_explosive
	name = "HE orbital warhead"
	craft_time = 60 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 15, /obj/item/stack/sheet/mineral/phoron = 10, /obj/item/stack/gun_powder = 15) // 120 + 70 + 15 = 205 points
	output = list(/obj/structure/ob_ammo/warhead/explosive = 1) // 300 points

/datum/assembly_craft/operations/ob_warhead_incendiary
	name = "Incendiary orbital warhead"
	craft_time = 40 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 10, /obj/item/stack/sheet/mineral/phoron = 10, /obj/item/stack/gun_powder = 8) // 80 + 70 + 8 = 158 points
	output = list(/obj/structure/ob_ammo/warhead/incendiary = 1) // 200 points

/datum/assembly_craft/operations/ob_warhead_plasmaloss
	name = "Plasma draining orbital warhead"
	craft_time = 30 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 10, /obj/item/stack/sheet/mineral/phoron = 5, /obj/item/stack/gun_powder = 6) // 80 + 35 + 6 = 121 points
	output = list(/obj/structure/ob_ammo/warhead/plasmaloss = 1) // 150 points

/datum/assembly_craft/operations/ob_fuel
	name = "Solid fuel"
	craft_time = 5 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 1, /obj/item/stack/sheet/mineral/phoron = 5) // 8 + 35 = 43 points
	output = list(/obj/structure/ob_ammo/ob_fuel = 1) // 50 points

/datum/assembly_craft/operations/drop_pod
	name = "Zeus orbital drop pod"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/metal = 5, /obj/item/stack/sheet/glass/glass = 3) // 20 + 6 = 26 points
	output = list(/obj/structure/droppod = 1) // 50 points
