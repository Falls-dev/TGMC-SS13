/*******************************************************************************
Smartguns
*******************************************************************************/

/datum/assembly_craft/smartguns
	group = "Smartguns"
	craft_time = 5 SECONDS

/datum/assembly_craft/smartguns/sg29
	name = "SG-29 ammo drum"
	input = list(/obj/item/stack/sheet/mineral/osmium = 15, /obj/item/stack/gun_powder = 5)
	output = list(/obj/item/ammo_magazine/sg29 = 1)

/datum/assembly_craft/smartguns/t25
	name = "T-25 magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/ammo_magazine/rifle/t25 = 1)

/datum/assembly_craft/smartguns/t25_packet
	name = "box of 10x26mm high-pressure"
	input = list(/obj/item/stack/sheet/mineral/osmium = 10, /obj/item/stack/gun_powder = 5)
	output = list(/obj/item/ammo_magazine/packet/t25 = 1)

/datum/assembly_craft/smartguns/t25_extended
	name = "T-25 extended magazine"
	input = list(/obj/item/stack/sheet/plasteel = 5, /obj/item/stack/sheet/mineral/osmium = 10, /obj/item/stack/gun_powder = 2)
	output = list(/obj/item/ammo_magazine/rifle/t25/extended = 1)

/datum/assembly_craft/smartguns/smartgun_minigun_box
	name = "SG-85 ammo bin"
	input = list(/obj/item/stack/sheet/mineral/osmium = 10, /obj/item/stack/gun_powder = 5)
	output = list(/obj/item/ammo_magazine/packet/smart_minigun = 1)

/datum/assembly_craft/smartguns/sg62
	name = "SG-62 ammo magazine"
	input = list(/obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/ammo_magazine/rifle/sg62 = 1)

/datum/assembly_craft/smartguns/sg62
	name = "SG-62 box of 10x27mm"
	input = list(/obj/item/stack/sheet/mineral/osmium = 10, /obj/item/stack/gun_powder = 5)
	output = list(/obj/item/ammo_magazine/packet/sg62 = 1)

/datum/assembly_craft/smartguns/sg153
	name = "SG-153 spotting rifle ammo"
	input = list(/obj/item/stack/sheet/mineral/osmium = 5, /obj/item/stack/gun_powder = 1)
	output = list(/obj/item/ammo_magazine/rifle/sg153 = 1)

/datum/assembly_craft/smartguns/sg153/highimpact
	name = "SG-153 high impact spotting rifle ammo"
	output = list(/obj/item/ammo_magazine/rifle/sg153/highimpact = 1)

/datum/assembly_craft/smartguns/sg153/heavyrubber
	name = "SG-153 heavy rubber spotting rifle ammo"
	output = list(/obj/item/ammo_magazine/rifle/sg153/heavyrubber = 1)

/datum/assembly_craft/smartguns/sg153/plasmaloss
	name = "SG-153 tanglefoot spotting rifle ammo"
	output = list(/obj/item/ammo_magazine/rifle/sg153/plasmaloss = 1)

/datum/assembly_craft/smartguns/sg153/tungsten
	name = "SG-153 tungsten spotting rifle ammo"
	output = list(/obj/item/ammo_magazine/rifle/sg153/tungsten = 1)

/datum/assembly_craft/smartguns/sg153/incendiary
	name = "SG-153 incendiary spotting rifle ammo"
	output = list(/obj/item/ammo_magazine/rifle/sg153/incendiary = 1)

/datum/assembly_craft/smartguns/sg153/flak
	name = "SG-153 flak spotting rifle ammo"
	output = list(/obj/item/ammo_magazine/rifle/sg153/flak = 1)
