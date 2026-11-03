GLOBAL_LIST_INIT(gear_datums, populate_gear_list())


/proc/populate_gear_list()
	. = list()
	for(var/type in subtypesof(/datum/gear))
		var/datum/gear/G = new type()
		.[G.display_name] = G

/datum/gear
	var/display_name       //Name/index.
	var/path               //Path to item.
	var/cost               //Number of points used.
	var/slot               //Slot to equip to.
	var/squad			   //Здесь можно задать отряд, который нужен для выдачи этого предмета. Пример: "Bravo"

/datum/gear/flower
	display_name = "Flower Pin"
	path = /obj/item/clothing/head/hairflower
	cost = 1
	slot = SLOT_HEAD

/datum/gear/bandanna_grey
	display_name = "surplus bandanna (grey)"
	path = /obj/item/clothing/head/bandanna/grey
	cost = 3
	slot = SLOT_HEAD

/datum/gear/bandanna_red
	display_name = "surplus bandanna (red)"
	path = /obj/item/clothing/head/bandanna/red
	cost = 3
	slot = SLOT_HEAD

/datum/gear/bandanna_brown
	display_name = "surplus bandanna (brown)"
	path = /obj/item/clothing/head/bandanna/brown
	cost = 3
	slot = SLOT_HEAD

/datum/gear/eye_patch
	display_name = "Eye Patch"
	path = /obj/item/clothing/glasses/eyepatch
	cost = 2
	slot = SLOT_GLASSES

/datum/gear/beret
	display_name = "surplus beret (blue)"
	path = /obj/item/clothing/head/tgmcberet
	cost = 3
	slot = SLOT_HEAD


/datum/gear/beret_tan
	display_name = "surplus beret (tan)"
	path = /obj/item/clothing/head/tgmcberet/tan
	cost = 3
	slot = SLOT_HEAD


/datum/gear/beret_green
	display_name = "surplus beret (green)"
	path = /obj/item/clothing/head/tgmcberet/green
	cost = 3
	slot = SLOT_HEAD

/datum/gear/beret_green
	display_name = "surplus beret (red)"
	path = /obj/item/clothing/head/tgmcberet/red2
	cost = 3
	slot = SLOT_HEAD

/datum/gear/beret_darkgreen
	display_name = "surplus beret (dark green)"
	path = /obj/item/clothing/head/tgmcberet/darkgreen
	cost = 3
	slot = SLOT_HEAD

/datum/gear/beret_bloodred
	display_name = "surplus beret (blood red)"
	path = /obj/item/clothing/head/tgmcberet/bloodred
	cost = 3
	slot = SLOT_HEAD

/datum/gear/beret_bloodred/blue
	display_name = "surplus beret (dark blue)"
	path = /obj/item/clothing/head/tgmcberet/blueberet
	cost = 3
	slot = SLOT_HEAD

/datum/gear/beret_snow
	display_name = "surplus beret (snow)"
	path = /obj/item/clothing/head/tgmcberet/snow
	cost = 3
	slot = SLOT_HEAD


/datum/gear/headband_green
	display_name = "surplus headband (green)"
	path = /obj/item/clothing/head/headband
	cost = 3
	slot = SLOT_HEAD


/datum/gear/headband_red
	display_name = "surplus headband (red)"
	path = /obj/item/clothing/head/headband/red
	cost = 3
	slot = SLOT_HEAD


/datum/gear/headpiece
	display_name = "surplus earpiece"
	path = /obj/item/clothing/head/headset
	cost = 3
	slot = SLOT_HEAD


/datum/gear/cap
	display_name = "surplus cap"
	path = /obj/item/clothing/head/tgmccap
	cost = 3
	slot = SLOT_HEAD


/datum/gear/booniehat
	display_name = "surplus boonie hat"
	path = /obj/item/clothing/head/boonie
	cost = 3
	slot = SLOT_HEAD

/datum/gear/glasses
	display_name = "Prescription Glasses"
	path = /obj/item/clothing/glasses/regular
	cost = 2
	slot = SLOT_GLASSES


/datum/gear/shades
	display_name = "Big shades"
	path = /obj/item/clothing/glasses/sunglasses/fake/big
	cost = 2
	slot = SLOT_GLASSES


/datum/gear/sunglasses
	display_name = "Sunglasses"
	path = /obj/item/clothing/glasses/sunglasses/fake
	cost = 2
	slot = SLOT_GLASSES


/datum/gear/cigar
	display_name = "Cigar"
	path = /obj/item/clothing/mask/cigarette/cigar
	cost = 2
	slot = SLOT_WEAR_MASK


/datum/gear/cigarette
	display_name = "Cigarette"
	path = /obj/item/clothing/mask/cigarette
	cost = 2
	slot = SLOT_WEAR_MASK

/datum/gear/cigarette/pipe
	display_name = "Smoking pipe"
	path = /obj/item/clothing/mask/cigarette/pipe
	cost = 3
	slot = SLOT_WEAR_MASK

/datum/gear/cigarette/pipe/corn
	display_name = "Corn cob pipe"
	path = /obj/item/clothing/mask/cigarette/pipe/cobpipe
	cost = 3
	slot = SLOT_WEAR_MASK

/datum/gear/cigarette/pipe/corn/curved
	display_name = "Curved corn cob pipe"
	path = /obj/item/clothing/mask/cigarette/pipe/cobpipe/curved
	cost = 3
	slot = SLOT_WEAR_MASK

/datum/gear/cigarette/pipe/bone
	display_name = "Europan bone pipe"
	path = /obj/item/clothing/mask/cigarette/pipe/bonepipe
	cost = 3
	slot = SLOT_WEAR_MASK

/datum/gear/bgoggles
	display_name = "Ballistic goggles"
	path = /obj/item/clothing/glasses/mgoggles
	cost = 2
	slot = SLOT_GLASSES


/datum/gear/kotahi
	display_name = "Kotahi deck"
	path = /obj/item/toy/deck/kotahi
	cost = 2
	slot = SLOT_IN_BACKPACK

/datum/gear/cards
	display_name = "Deck of cards"
	path = /obj/item/toy/deck
	cost = 2
	slot = SLOT_IN_BACKPACK

/datum/gear/pig
	display_name = "Pig toy"
	path = /obj/item/toy/plush/pig
	cost = 5
	slot = SLOT_IN_BACKPACK

/datum/gear/hachimaki
	display_name = "Ancient pilot headband and scarf kit"
	path = /obj/item/clothing/head/hachimaki
	cost = 2
	slot = SLOT_HEAD

/datum/gear/koran
	display_name = "Koran"
	path = /obj/item/storage/bible/koran
	cost = 1
	slot = SLOT_IN_BACKPACK

/datum/gear/namaz
	display_name = "Prayer rug"
	path = /obj/item/namaz
	cost = 1
	slot = SLOT_IN_BACKPACK

/datum/gear/orange_glasses
	display_name = "Orange glasses"
	path = /obj/item/clothing/glasses/orange
	cost = 2
	slot = SLOT_GLASSES

/datum/gear/rosary
	display_name = "Rosary"
	path = /obj/item/rosary
	cost = 1
	slot = SLOT_IN_BACKPACK

/datum/gear/card/ace/hearts
	display_name = "Old Ace of Hearts card"
	path = /obj/item/toy/card/ace/hearts
	cost = 1
	slot = SLOT_IN_BACKPACK

/datum/gear/card/ace/spades
	display_name = "Old Ace of Spades card"
	path = /obj/item/toy/card/ace/spades
	cost = 1
	slot = SLOT_IN_BACKPACK

/datum/gear/bravo_hawaii
	display_name = "The Bravo Hawaiian shirt"
	path = /obj/item/clothing/under/marine/bravo_hawaii
	cost = 4
	slot = SLOT_W_UNIFORM
	squad = "Bravo"

/datum/gear/delta_tomahawk
	display_name = "Delta Tomahawk"
	path = /obj/item/weapon/sword/tomahawk/classic
	cost = 4
	slot = SLOT_R_HAND
	squad = "Delta"

/datum/gear/delta_turtleneck
	display_name = "The TGMC Delta turtleneck"
	path = /obj/item/clothing/under/marine/squad/neck/delta
	cost = 2
	slot = SLOT_W_UNIFORM
	squad = "Delta"

/datum/gear/charlie_turtleneck
	display_name = "The TGMC Charlie turtleneck"
	path = /obj/item/clothing/under/marine/squad/neck/charlie
	cost = 2
	slot = SLOT_W_UNIFORM
	squad = "Charlie"

/datum/gear/bravo_turtleneck
	display_name = "The TGMC Bravo turtleneck"
	path = /obj/item/clothing/under/marine/squad/neck/bravo
	cost = 2
	slot = SLOT_W_UNIFORM
	squad = "Bravo"

/datum/gear/alpha_turtleneck
	display_name = "The TGMC Alpha turtleneck"
	path = /obj/item/clothing/under/marine/squad/neck/alpha
	cost = 2
	slot = SLOT_W_UNIFORM
	squad = "Alpha"
