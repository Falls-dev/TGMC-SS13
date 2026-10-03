/*******************************************************************************
CLOTHING
*******************************************************************************/
/datum/assembly_craft/clothing
	craft_time = 10 SECONDS
	group = "Clothing"

/datum/assembly_craft/clothing/jetpack_marine
	name = "Jetpack"
	input = list(/obj/item/stack/sheet/plasteel = 5, /obj/item/stack/sheet/cloth = 10)
	output = list(/obj/item/jetpack_marine = 1)

/datum/assembly_craft/clothing/lightpack
	name = "Combat backpack"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/cloth = 25)
	output = list(/obj/item/storage/backpack/lightpack = 1)

/datum/assembly_craft/clothing/rpg_bag
	name = "TGMC rocket bag"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/cloth = 25)
	output = list(/obj/item/storage/holster/backholster/rpg = 1)

/datum/assembly_craft/clothing/rlquad_bag
	name = "TGMC RL-57 bag"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/cloth = 25)
	output = list(/obj/item/storage/holster/backholster/rlquad = 1)

/datum/assembly_craft/clothing/b17_grenade_rig
	name = "M276 pattern M40 HEDP rig Mk II"
	craft_time = 20 SECONDS
	input = list(/obj/item/stack/sheet/cloth = 25)
	output = list(/obj/item/storage/belt/grenade/b17 = 1)

/datum/assembly_craft/clothing/dispenser
	name = "Dispenser"
	craft_time = 30 SECONDS
	input = list(/obj/item/stack/sheet/plasteel = 10, /obj/item/stack/sheet/composite = 20)
	output = list(/obj/item/storage/backpack/dispenser = 1)

/datum/assembly_craft/clothing/night_vision_battery
	name = "Night vision battery"
	input = list(/obj/item/stack/sheet/plasteel = 2, /obj/item/stack/sheet/mineral/platinum = 2)
	output = list(/obj/item/cell/night_vision_battery = 1)
