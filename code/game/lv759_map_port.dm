// LV759 map content imported from Official-TGMC. Media is staged under temp/LV759.
// Map dependencies absent from this TGMC build.
#define HYDRO_SPEED_MULTIPLIER 1
#define SMOOTH_GROUP_LATTICE_ABOVE S_OBJ(33)
#define PATROL_POINT_RAPPEL_EFFECT "patrol_point_rappel_effect"
#define RAPPEL_DURATION 0.6 SECONDS
#define RAPPEL_HEIGHT 128

/obj/item/spacecash/c1
	name = "1 dollar bill"
	icon_state = "spacecash1"
	desc = "A single US Government minted one dollar bill. It has a picture of George Washington printed on it. Makes most people of english origin cry, but isn't worth very much. Could probably get you half a hot-dog in some systems. "
	worth = 1

/obj/item/spacecash/c10
	name = "10 dollar bill"
	icon_state = "spacecash10"
	desc = "A single US Government minted ten dollar bill. It has a picture of Alexander Hamilton on it, federal bank enthusiast, and victim of a terrible griefing incident. Could probably pay for a meal at a cheap restaurant, before tax and tip."
	worth = 10

/obj/item/spacecash/c20
	name = "20 dollar bill"
	icon_state = "spacecash20"
	desc = "A single US Government minted twenty dollar bill. It has a picture of Andrew Jackson on it, famed hero of the War of 1812 and slayer of indigenous peoples everywhere. Could probably afford you a nice 2-course meal at the local colony steakhouse."
	worth = 20

/obj/item/spacecash/c100
	name = "100 dollar bill"
	icon_state = "spacecash100"
	desc = "A single US Government minted hundred dollar bill. It has a picture of Ben Franklin, lightning kite extraordinaire. You could probably pay for an entire day of shore leave activities with this, provided you aren't careless. (which you are)"
	worth = 100

/obj/item/spacecash/c200
	name = "200 dollars"
	icon_state = "spacecash200"
	desc = "Two US Government minted hundred dollar bills. They both have pictures of Ben Franklin on them. Both Bens look at you expectedly and passionately from different angles."
	worth = 200

/obj/item/spacecash/c500
	name = "500 dollars"
	icon_state = "spacecash500"
	desc = "Five US Government minted hundred dollar bills. All of them have pictures of Ben Franklin on them. They all eagarly glare at you, making you feel as if you owe them something. "
	worth = 500

/obj/machinery/hydroponics
	name = "hydroponics tray"
	icon = 'icons/obj/machines/hydroponics.dmi'
	icon_state = "hydrotray3"
	density = TRUE
	anchored = TRUE
	coverage = 40
	layer = BELOW_OBJ_LAYER
	resistance_flags = XENO_DAMAGEABLE
	allow_pass_flags = PASS_LOW_STRUCTURE|PASSABLE|PASS_WALKOVER
	max_integrity = 40
	soft_armor = list(MELEE = 0, BULLET = 80, LASER = 80, ENERGY = 80, BOMB = 0, BIO = 0, FIRE = 0, ACID = 0)

	var/draw_warnings = 1 //Set to 0 to stop it from drawing the alert lights.

	// Plant maintenance vars.
	var/waterlevel = 100       // Water (max 100)
	var/nutrilevel = 100       // Nutrient (max 100)
	var/pestlevel = 0          // Pests (max 10)
	var/weedlevel = 0          // Weeds (max 10)

	// Tray state vars.
	var/dead = 0               // Is it dead?
	var/harvest = 0            // Is it ready to harvest?
	var/age = 0                // Current plant age
	var/sampled = 0            // Have wa taken a sample?

	// Harvest/mutation mods.
	var/yield_mod = 0          // Modifier to yield
	var/mutation_mod = 0       // Modifier to mutation chance
	var/toxins = 0             // Toxicity in the tray?
	var/mutation_level = 0     // When it hits 100, the plant mutates.

	// Mechanical concerns.
	var/health = 0             // Plant health.
	var/lastproduce = 0        // Last time tray was harvested
	var/lastcycle = 0          // Cycle timing/tracking var.
	var/cycledelay = 150       // Delay per cycle.
	var/closed_system          // If set, the tray will attempt to take atmos from a pipe.
	var/force_update           // Set this to bypass the cycle time check.
	var/obj/temp_chem_holder   // Something to hold reagents during process_reagents()

	// Seed details/line data.
	var/datum/seed/seed = null // The currently planted seed

	// Reagent information for process(), consider moving this to a controller along
	// with cycle information under 'mechanical concerns' at some point.
	var/global/list/toxic_reagents = list(
		/datum/reagent/medicine/dylovene = -2,
		/datum/reagent/toxin = 2,
		/datum/reagent/fluorine = 2.5,
		/datum/reagent/chlorine = 1.5,
		/datum/reagent/toxin/acid = 1.5,
		/datum/reagent/toxin/acid/polyacid = 3,
		/datum/reagent/toxin/plantbgone = 3,
		/datum/reagent/medicine/cryoxadone = -3,
		/datum/reagent/radium = 2
		)
	var/global/list/nutrient_reagents = list(
		/datum/reagent/consumable/milk = 0.1,
		/datum/reagent/consumable/ethanol/beer = 0.25,
		/datum/reagent/phosphorus = 0.1,
		/datum/reagent/consumable/sugar = 0.1,
		/datum/reagent/consumable/sodawater = 0.1,
		/datum/reagent/ammonia = 1,
		/datum/reagent/diethylamine = 2,
		/datum/reagent/consumable/nutriment = 1,
		/datum/reagent/medicine/adminordrazine = 1,
		/datum/reagent/toxin/fertilizer/eznutrient = 1,
		/datum/reagent/toxin/fertilizer/robustharvest = 1,
		/datum/reagent/toxin/fertilizer/left4zed = 1
		)
	var/global/list/weedkiller_reagents = list(
		/datum/reagent/fluorine = -4,
		/datum/reagent/chlorine = -3,
		/datum/reagent/phosphorus = -2,
		/datum/reagent/consumable/sugar = 2,
		/datum/reagent/toxin/acid = -2,
		/datum/reagent/toxin/acid/polyacid = -4,
		/datum/reagent/toxin/plantbgone = -8,
		/datum/reagent/medicine/adminordrazine = -5
		)
	var/global/list/pestkiller_reagents = list(
		/datum/reagent/consumable/sugar = 2,
		/datum/reagent/diethylamine = -2,
		/datum/reagent/medicine/adminordrazine = -5
		)
	var/global/list/water_reagents = list(
		/datum/reagent/water = 1,
		/datum/reagent/medicine/adminordrazine = 1,
		/datum/reagent/consumable/milk = 0.9,
		/datum/reagent/consumable/ethanol/beer = 0.7,
		/datum/reagent/fluorine = -0.5,
		/datum/reagent/chlorine = -0.5,
		/datum/reagent/phosphorus = -0.5,
		/datum/reagent/water = 1,
		/datum/reagent/consumable/sodawater = 1,
		)

	// Beneficial reagents also have values for modifying yield_mod and mut_mod (in that order).
	var/global/list/beneficial_reagents = list(
		/datum/reagent/consumable/ethanol/beer = list( -0.05, 0,   0   ),
		/datum/reagent/fluorine = list( -2,    0,   0   ),
		/datum/reagent/chlorine = list( -1,    0,   0   ),
		/datum/reagent/phosphorus = list( -0.75, 0,   0   ),
		/datum/reagent/consumable/sodawater = list(  0.1,  0,   0   ),
		/datum/reagent/toxin/acid = list( -1,    0,   0   ),
		/datum/reagent/toxin/acid/polyacid = list( -2,    0,   0   ),
		/datum/reagent/toxin/plantbgone = list( -2,    0,   0.2 ),
		/datum/reagent/medicine/cryoxadone = list(  3,    0,   0   ),
		/datum/reagent/ammonia = list(  0.5,  0,   0   ),
		/datum/reagent/diethylamine = list(  1,    0,   0   ),
		/datum/reagent/consumable/nutriment = list(  0.5,  0.1,   0 ),
		/datum/reagent/radium = list( -1.5,  0,   0.2 ),
		/datum/reagent/medicine/adminordrazine = list(  1,    1,   1   ),
		/datum/reagent/toxin/fertilizer/robustharvest = list(  0,    0.2, 0   ),
		/datum/reagent/toxin/fertilizer/left4zed = list(  0,    0,   0.2 )
		)

	// Mutagen list specifies minimum value for the mutation to take place, rather
	// than a bound as the lists above specify.
	var/global/list/mutagenic_reagents = list(
		/datum/reagent/radium = 8,
		/datum/reagent/toxin/mutagen = 15
		)

/obj/machinery/hydroponics/slashable
	resistance_flags = XENO_DAMAGEABLE
	max_integrity = 80

#undef HYDRO_SPEED_MULTIPLIER

/obj/effect/mapping_helpers/airlock/free_access
	name = "airlock free access helper"
	icon_state = "airlock_free_access"

/obj/structure/filingcabinet/nondense
	density = FALSE

/obj/machinery/light/blue
	base_icon_state = "btube"
	icon_state = "tube_empty"
	light_color = LIGHT_COLOR_BLUE_FLAME
	bulb_colour = LIGHT_COLOR_BLUE_FLAME
	desc = "A lighting fixture that is fitted with a bright blue fluorescent light tube. Looking at it for too long makes your eyes go watery."
	light_type = /obj/item/light_bulb/tube/blue

/obj/machinery/light/small/blue
	light_color = LIGHT_COLOR_BLUE_FLAME
	bulb_colour = LIGHT_COLOR_BLUE_FLAME
	fitting = "bbulb"
	brightness = 4
	desc = "A small lighting fixture that is fitted with a bright blue fluorescent light bulb. Looking at it for too long makes your eyes go watery."
	light_type = /obj/item/light_bulb/bulb/blue

/obj/machinery/light/spot/blue
	name = "spotlight"
	light_color = LIGHT_COLOR_BLUE_FLAME
	bulb_colour = LIGHT_COLOR_BLUE_FLAME
	desc = "A wide light fixture fitted with a large, blue, very bright fluorescent light tube. You want to sneeze just looking at it."
	fitting = "large tube"
	light_type = /obj/item/light_bulb/tube/large
	brightness = 12

/obj/structure/dropship_piece/four/dropshipfront
	icon_state = "dropshipfrontwhite1"
	opacity = FALSE

/obj/structure/dropship_piece/four/dropshipventone
	icon_state = "dropshipvent1"

/obj/structure/dropship_piece/four/dropshipventtwo
	icon_state = "dropshipvent2"

/obj/structure/dropship_piece/four/dropshipwingtopone
	icon_state = "dropshipwingtop1"

/obj/structure/dropship_piece/four/dropshipwingtoptwo
	icon_state = "dropshipwingtop2"

/obj/structure/dropship_piece/four/dropshipventthree
	icon_state = "dropshipvent3"

/obj/structure/dropship_piece/four/dropshipventfour
	icon_state = "dropshipvent4"

/obj/structure/dropship_piece/four/rearwing/lefttop
	icon_state = "white_rearwing_lt"

/obj/structure/dropship_piece/four/rearwing/righttop
	icon_state = "white_rearwing_rt"

/obj/structure/dropship_piece/four/rearwing/leftbottom
	icon_state = "white_rearwing_lb"

/obj/structure/dropship_piece/four/rearwing/rightbottom
	icon_state = "white_rearwing_rb"

/obj/item/reagent_containers/cup/glass/drinkingglass
	name = "drinking glass"
	desc = "Your standard drinking glass."
	icon_state = "glass_empty"
	base_icon_state = "glass_empty"
	amount_per_transfer_from_this = 10
	fill_icon_thresholds = list(0)
	fill_icon_state = "drinking_glass"
	volume = 50
	max_integrity = 20
	resistance_flags = UNACIDABLE
	//the screwdriver cocktail can make a drinking glass into the world's worst screwdriver. beautiful.
	toolspeed = 25

	/// The type to compare to glass_style.required_container type, or null to use class type.
	/// This allows subtypes to utilize parent styles.
	var/base_container_type = null

/obj/item/clothing/glasses/gglasses
	name = "green glasses"
	desc = "Forest green glasses, like the kind you'd wear when hatching a nasty scheme."
	icon_state = "gglasses"
	worn_icon_state = "gglasses"
	armor_protection_flags = NONE

/obj/item/clothing/head/soft/orange
	name = "orange cap"
	desc = "It's a baseball hat in a tasteless orange color."
	icon_state = "orangesoft"
	cap_color = "orange"

/obj/item/clothing/mask/pig
	name = "pig mask"
	desc = "A rubber pig mask."
	icon_state = "pig"
	worn_icon_state = "pig"
	inventory_flags = COVERMOUTH|COVEREYES
	inv_hide_flags = HIDEFACE|HIDEALLHAIR|HIDEEYES|HIDEEARS
	w_class = WEIGHT_CLASS_SMALL
	siemens_coefficient = 0.9
	armor_protection_flags = HEAD|FACE|EYES

/obj/item/clothing/suit/armor/swat/officer
	name = "officer jacket"
	desc = "An armored jacket used in special operations."
	icon_state = "detective"
	worn_icon_state = "det_suit"
	blood_overlay_type = "coat"
	inventory_flags = NONE
	inv_hide_flags = NONE
	armor_protection_flags = CHEST|ARMS

/obj/item/clothing/suit/storage/internalaffairs
	name = "Internal Affairs Jacket"
	desc = "A smooth black jacket."
	icon_state = "ia_jacket_open"
	worn_icon_state = "ia_jacket"
	blood_overlay_type = "coat"
	armor_protection_flags = CHEST|ARMS

/obj/item/clothing/suit/poncho
	name = "poncho"
	desc = "A simple, comfortable poncho."
	icon_state = "classicponcho"

/obj/item/clothing/suit/poncho/green
	name = "green poncho"
	desc = "Your classic, non-racist poncho. This one is green."
	icon_state = "greenponcho"

/obj/item/clothing/suit/poncho/red
	name = "red poncho"
	desc = "Your classic, non-racist poncho. This one is red."
	icon_state = "redponcho"

/obj/item/clothing/under/color

/obj/item/clothing/under/assistantformal
	name = "assistant's formal uniform"
	desc = "An assistant's formal-wear. Why an assistant needs formal-wear is still unknown."
	icon_state = "assistant_formal"
	worn_icon_state = "gy_suit"

/obj/item/clothing/under/suit_jacket/navy
	name = "navy suit"
	desc = "A navy suit and red tie, intended for the station's finest."
	icon_state = "navy_suit"

/obj/item/clothing/under/suit_jacket/burgundy
	name = "burgundy suit"
	desc = "A burgundy suit and black tie. Somewhat formal."
	icon_state = "burgundy_suit"

/obj/item/clothing/under/suit_jacket/checkered
	name = "checkered suit"
	desc = "That's a very nice suit you have there. Shame if something were to happen to it, eh?"
	icon_state = "checkered_suit"

/obj/item/clothing/under/suit_jacket/tan
	name = "tan suit"
	desc = "A tan suit with a yellow tie. Smart, but casual."
	icon_state = "tan_suit"

/obj/item/clothing/tie/armband/med
	name = "medical armband"
	desc = "An armband, worn by the crew to display which department they're assigned to. This one is white."
	icon_state = "med"

/turf/closed/mineral/smooth/black_stone
	icon = 'temp/LV759/icons/turf/walls/black_stone_walls.dmi'
	icon_state = "black_stone_walls-0"
	walltype = "lava_wall"
	base_icon_state = "black_stone_walls"

/turf/closed/mineral/smooth/black_stone/indestructible
	resistance_flags = RESIST_ALL
	icon_state = "wall-invincible"

/turf/closed/mineral/smooth/engineerwall
	name = "strange metal wall"
	desc = "Nigh indestructible walls that make up the hull of an unknown ancient ship."
	icon = 'temp/LV759/icons/turf/walls/engineer_walls_turf.dmi'
	icon_state = "engineer_walls_turf-255"
	walltype = "wall"
	base_icon_state = "engineer_walls_turf"

/turf/closed/mineral/smooth/engineerwall/indestructible
	resistance_flags = RESIST_ALL
	icon_state = "wall-invincible"

/turf/closed/shuttle/dropship4
	name = "\improper Normandy"
	icon = 'temp/LV759/icons/turf/dropship4.dmi'
	icon_state = "1"

/turf/closed/shuttle/dropship4/edge
	icon_state = "shuttle_interior_edge"

/turf/closed/shuttle/dropship4/edge/alt
	icon_state = "shuttle_interior_edgealt"

/turf/closed/shuttle/dropship4/aisle
	icon_state = "shuttle_interior_aisle"

/turf/closed/shuttle/dropship4/door
	icon_state = "shuttle_rear_door"

/turf/closed/shuttle/dropship4/window
	icon_state = "shuttle_window_glass"
	opacity = FALSE
	allow_pass_flags = PASS_GLASS

/turf/closed/shuttle/dropship4/engineone
	icon_state = "shuttle_interior_backengine"

/turf/closed/shuttle/dropship4/enginetwo
	icon_state = "shuttle_interior_backengine2"

/turf/closed/shuttle/dropship4/enginethree
	icon_state = "shuttle_interior_backengine3"

/turf/closed/shuttle/dropship4/engine_sidealt
	icon_state = "shuttle_side_engine_alt"

/turf/closed/shuttle/dropship4/fins
	icon_state = "shuttle_exterior_fins"

/turf/closed/shuttle/dropship4/damagedconsoleone
	icon_state = "damaged_console1"

/turf/closed/shuttle/dropship4/damagedconsoletwo
	icon_state = "damaged_console2"

/turf/closed/shuttle/dropship4/damagedconsolethree
	icon_state = "damaged_console3"

/turf/closed/shuttle/dropship4/brokenconsoleone
	icon_state = "brokendropshipconsole1"

/turf/closed/shuttle/dropship4/brokenconsolethree
	icon_state = "brokendropshipconsole3"

/turf/closed/shuttle/dropship4/corners
	icon_state = "shuttle_exterior_corners"

/turf/closed/shuttle/dropship4/interiorwindow
	icon_state = "shuttle_interior_inwards"

/turf/closed/shuttle/dropship4/cornersalt
	icon_state = "shuttle_interior_corneralt"

/turf/closed/shuttle/dropship4/cornersalt2
	icon_state = "shuttle_interior_alt2"

/turf/closed/shuttle/dropship4/finleft
	icon_state = "shuttle_exterior_finnleft"

/turf/closed/shuttle/dropship4/finright
	icon_state = "shuttle_exterior_finnright"

/turf/closed/shuttle/dropship4/glassthree
	icon_state = "shuttle_glass3"

/turf/closed/shuttle/dropship4/glassfour
	icon_state = "shuttle_glass4"

/turf/closed/shuttle/dropship4/glassseven
	icon_state = "shuttle_glass7"

/turf/closed/shuttle/dropship4/zwing_left
	icon_state = "zwing_left"

/turf/closed/shuttle/dropship4/zwing_right
	icon_state = "zwing_right"

/turf/closed/shuttle/dropship4/window/alt
	icon_state = "shuttle_window_glass_alt"

/turf/closed/shuttle/dropship4/left_engine
	icon_state = "left_engine"

/turf/closed/shuttle/dropship4/right_engine
	icon_state = "right_engine"

/turf/closed/shuttle/dropship4/backplate
	icon_state = "back1"

/turf/open/ground/sandrock
	icon = 'temp/LV759/icons/turf/ground_map.dmi'
	icon_state = "varadero_0"
	minimap_color = MINIMAP_DIRT

/turf/open/floor/tile/dark/brown3
	icon_state = "darkbrown3"

/turf/open/floor/squares
	icon_state = "squares"

/turf/open/floor/box
	icon_state = "box"

/turf/open/floor/plate
	icon_state = "plate"

/turf/open/floor/officetiles
	icon_state = "officetiles"

/turf/open/floor/officesquares
	icon_state = "officesquares"

/turf/open/floor/spiralblueoffice
	icon_state = "spiralblueoffice"

/turf/open/floor/spiralplate
	icon_state = "spiralplate"

/turf/open/floor/marked
	icon_state = "marked"

/turf/open/floor/urban_plating
	icon_state = "urban_plating"

/turf/open/floor/urban_wood
	icon_state = "wood"

/turf/open/floor/floortwo
	icon_state = "floor2"

/turf/open/floor/floorthree
	icon_state = "floor3"

/turf/open/floor/multi_tiles
	icon_state = "multi_tiles"

/turf/open/floor/orange_cover
	icon_state = "orange_cover"

/turf/open/floor/orange_edge
	icon_state = "orange_edge"

/turf/open/floor/orange_icorner
	icon_state = "orange_icorner"

/turf/open/floor/bluethree
	icon_state = "blue3"

/turf/open/floor/bluefour
	icon_state = "blue4"

/turf/open/floor/cyanthree
	icon_state = "cyan3"

/turf/open/floor/cyanfour
	icon_state = "cyan4"

/turf/open/floor/yellowthree
	icon_state = "yellow3"

/turf/open/floor/redone
	icon_state = "red1"

/turf/open/floor/redthree
	icon_state = "red3"

/turf/open/floor/redfour
	icon_state = "red4"

/turf/open/floor/prison/whitered
	icon_state = "whitered"

/turf/open/floor/prison/ramptop
	icon_state = "ramptop"

/turf/open/urban/street
	name = "floor"
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "cement1"
	baseturfs = /turf/open/urban/street/asphalt

/turf/open/urban/street/cement1
	icon_state = "cement1"

/turf/open/urban/street/cement2
	icon_state = "cement2"

/turf/open/urban/street/cement3
	icon_state = "cement3"

/turf/open/urban/street/asphalt
	icon_state = "asphalt_old"
	minimap_color = MINIMAP_DIRT

/turf/open/urban/street/sidewalk
	icon_state = "sidewalk"

/turf/open/urban/street/sidewalkfull
	icon_state = "sidewalkfull"

/turf/open/urban/street/sidewalkcenter
	icon_state = "sidewalkcenter"
	minimap_color = MINIMAP_DIRT

/turf/open/urban/street/roadlines3
	icon_state = "asphalt_old_roadlines3"

/turf/open/urban/street/roadlines4
	icon_state = "asphalt_old_roadlines4"

/turf/open/urban/street/underground_unweedable
	name = "floor"
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "underground"
	baseturfs = /turf/open/urban/street/asphalt

/turf/open/floor/urban/carpet
	name = "floor"
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "carpetred"

/turf/open/floor/urban/carpet/carpetfadedred
	icon_state = "carpetfadedred"

/turf/open/floor/urban/carpet/carpetgreen
	icon_state = "carpetgreen"

/turf/open/floor/urban/carpet/carpetbeige
	icon_state = "carpetbeige"

/turf/open/floor/urban/carpet/carpetblack
	icon_state = "carpetblack"

/turf/open/floor/urban/carpet/carpetred
	icon_state = "carpetred"

/turf/open/floor/urban/carpet/carpetdarkerblue
	icon_state = "carpetdarkerblue"

/turf/open/floor/urban/carpet/carpetorangered
	icon_state = "carpetorangered"

/turf/open/floor/urban/carpet/carpetblue
	icon_state = "carpetblue"

/turf/open/floor/urban/carpet/carpetpatternbrown
	icon_state = "carpetpatternbrown"

/turf/open/floor/urban/carpet/carpetreddeco
	icon_state = "carpetred_deco"

/turf/open/floor/urban/carpet/carpetbluedeco
	icon_state = "carpetblue_deco"

/turf/open/floor/urban/carpet/carpetblackdeco
	icon_state = "carpetblack_deco"

/turf/open/floor/urban/carpet/carpetbeigedeco
	icon_state = "carpetbeige_deco"

/turf/open/floor/urban/carpet/carpetgreendeco
	icon_state = "carpetgreen_deco"

/turf/open/floor/urban/tile
	name = "floor"
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "supermartfloor1"

/turf/open/floor/urban/tile/supermartfloor1
	icon_state = "supermartfloor1"

/turf/open/floor/urban/tile/supermartfloor2
	icon_state = "supermartfloor2"

/turf/open/floor/urban/tile/cuppajoesfloor
	icon_state = "cuppafloor"

/turf/open/floor/urban/tile/tilered
	icon_state = "tilered"

/turf/open/floor/urban/tile/tileblue
	icon_state = "tileblue"

/turf/open/floor/urban/tile/tilegreen
	icon_state = "tilegreen"

/turf/open/floor/urban/tile/tileblackcheckered
	icon_state = "tileblack"

/turf/open/floor/urban/tile/tilewhitecheckered
	icon_state = "tilewhitecheck"

/turf/open/floor/urban/tile/tilebeigecheckered
	icon_state = "tilebeigecheck"

/turf/open/floor/urban/tile/tilebeige
	icon_state = "tilebeige"

/turf/open/floor/urban/tile/tilewhite
	icon_state = "tilewhite"

/turf/open/floor/urban/tile/tilegrey
	icon_state = "tilegrey"

/turf/open/floor/urban/tile/blacktileshiny
	icon_state = "blacktileshiny"

/turf/open/floor/urban/tile/cementflat
	icon_state = "cementflat"

/turf/open/floor/urban/tile/beige_bigtile
	icon_state = "beige_bigtile"

/turf/open/floor/urban/tile/yellow_bigtile
	icon_state = "yellow_bigtile"

/turf/open/floor/urban/tile/darkgrey_bigtile
	icon_state = "darkgrey_bigtile"

/turf/open/floor/urban/tile/darkbrown_bigtile
	icon_state = "darkbrown_bigtile"

/turf/open/floor/urban/tile/darkbrowncorner_bigtile
	icon_state = "darkbrowncorner_bigtile"

/turf/open/floor/urban/tile/asteroidfloor_bigtile
	icon_state = "asteroidfloor_bigtile"

/turf/open/floor/urban/tile/asteroidwarning_bigtile
	icon_state = "asteroidwarning_bigtile"

/turf/open/floor/urban/tile/lightbeige_bigtile
	icon_state = "lightbeige_bigtile"

/turf/open/floor/urban/tile/green_bigtile
	icon_state = "green_bigtile"

/turf/open/floor/urban/tile/greenfull_bigtile
	icon_state = "greenfull_bigtile"

/turf/open/floor/urban/wood
	name = "floor"
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "darkerwood"

/turf/open/floor/urban/wood/blackwood
	icon_state = "blackwood"

/turf/open/floor/urban/wood/darkerwood
	icon_state = "darkerwood"

/turf/open/floor/urban/wood/redwood
	icon_state = "redwood"

/turf/open/floor/urban/metal
	name = "floor"
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "bluemetal1"

/turf/open/floor/urban/metal/bluemetal1
	icon_state = "bluemetal1"

/turf/open/floor/urban/metal/bluemetalfull
	icon_state = "bluemetalfull"

/turf/open/floor/urban/metal/bluemetalcorner
	icon_state = "bluemetalcorner"

/turf/open/floor/urban/metal/grated
	icon_state = "rampsmaller"

/turf/open/floor/urban/metal/stripe_red
	icon_state = "stripe_red"

/turf/open/floor/urban/metal/zbrownfloor1
	icon_state = "zbrownfloor1"

/turf/open/floor/urban/metal/zbrownfloor_corner
	icon_state = "zbrownfloorcorner1"

/turf/open/floor/urban/metal/zbrownfloor_full
	icon_state = "zbrownfloorfull1"

/turf/open/floor/urban/metal/greenmetal1
	icon_state = "greenmetal1"

/turf/open/floor/urban/metal/greenmetalfull
	icon_state = "greenmetalfull"

/turf/open/floor/urban/metal/metalwhitefull
	icon_state = "metalwhitefull"

/turf/open/floor/urban/misc/spaceport1
	icon_state = "spaceport1"

/turf/open/floor/urban/misc/spaceport2
	icon_state = "spaceport2"

/turf/open/urban/dropship
	name = "floor"
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "dropshipfloor1"

/turf/open/urban/dropship/dropship2
	icon_state = "dropshipfloor2"

/turf/open/urban/dropship/dropship3
	icon_state = "dropshipfloor2"

/turf/open/urban/dropship/dropship3
	icon_state = "dropshipfloor3"

/turf/open/urban/dropship/dropship4
	icon_state = "dropshipfloor4"

/turf/open/urban/dropship/dropshipfloorcorner1
	icon_state = "dropshipfloorcorner1"

/turf/open/urban/dropship/dropshipfloorcorner2
	icon_state = "dropshipfloorcorner2"

/turf/open/engineership
	name = "floor"
	desc = "A strange metal floor, unlike any metal you've seen before."
	icon = 'temp/LV759/icons/turf/engineership.dmi'
	icon_state = "hybrisa"
	baseturfs = /turf/open/urban/street/asphalt

/turf/open/engineership/engineer_floor1
	icon_state = "engineer_metalfloor_3"

/turf/open/engineership/engineer_floor2
	icon_state = "engineer_floor_4"

/turf/open/engineership/engineer_floor3
	icon_state = "engineer_metalfloor_2"

/turf/open/engineership/engineer_floor4
	icon_state = "engineer_metalfloor_1"

/turf/open/engineership/engineer_floor5
	icon_state = "engineerlight"

/turf/open/engineership/engineer_floor8
	icon_state = "engineer_floor_5"

/turf/open/engineership/engineer_floor9
	icon_state = "engineer_metalfloor_4"

/turf/open/engineership/engineer_floor13
	icon_state = "outerhull_dir"

/turf/open/engineership/pillars
	name = "strange metal pillar"
	desc = "A strange metal pillar, unlike any metal you've seen before."
	icon_state = "eng_pillar1"

/turf/open/engineership/pillars/north/pillar4
	icon_state = "eng_pillar4"

/turf/open/engineership/pillars/east/pillareast4
	icon_state = "eng_pillareast4"

/turf/open/urbanshale
	name = "shale"
	icon = 'temp/LV759/icons/turf/auto_shaledesaturated.dmi'
	mediumxenofootstep = FOOTSTEP_GRAVEL
	barefootstep = FOOTSTEP_GRAVEL
	shoefootstep = FOOTSTEP_GRAVEL
	minimap_color = MINIMAP_SHALE

/turf/open/urbanshale/layer0_plate
	icon_state = "shale_1_alt"

/turf/open/urbanshale/layer1
	icon_state = "shale_1"

/turf/open/urbanshale/layer2
	icon_state = "shale_2"

/turf/closed/wall/r_wall/bunker
	icon = 'temp/LV759/icons/turf/walls/junkwall.dmi'
	icon_state = "junkwall-0"
	base_icon_state = "junkwall"

/turf/closed/wall/r_wall/white_research_wall
	icon = 'temp/LV759/icons/turf/walls/white_research_wall.dmi'
	icon_state = "white_research_wall-0"
	base_icon_state = "white_research_wall"

/turf/closed/wall/r_wall/urban
	name = "reinforced metal walls"
	desc = "A thick and chunky metal wall ribbed with reinforced steel. The surface is barren and imposing."
	icon = 'temp/LV759/icons/turf/walls/hybrisa_colony_walls.dmi'
	icon_state = "wall-reinforced"
	walltype = "wall"
	base_icon_state = "hybrisa_colony_walls"

/turf/closed/wall/r_wall/engineership
	name = "strange metal wall"
	desc = "Nigh indestructible walls that make up the hull of an unknown ancient ship."
	icon = 'temp/LV759/icons/turf/walls/engineer_walls.dmi'
	icon_state = "engineer_walls-0"
	walltype = "wall"
	base_icon_state = "engineer_walls"

/turf/closed/wall/r_wall/engineership/invincible
	resistance_flags = RESIST_ALL
	icon_state = "wall-invincible"

/turf/closed/wall/urban
	name = "bare metal walls"
	desc = "A thick and chunky metal wall. The surface is barren and imposing."
	icon = 'temp/LV759/icons/turf/walls/urban_wall_regular.dmi'
	icon_state = "urban_wall_regular-0"
	walltype = "wall"
	base_icon_state = "urban_wall_regular"

/turf/closed/wall/urban/colony/ribbed
	name = "bare metal walls"
	desc = "A thick and chunky metal wall. The surface is barren and imposing."
	icon = 'temp/LV759/icons/turf/walls/hybrisa_colony_walls.dmi'
	icon_state = "wall-reinforced"
	walltype = "wall"
	base_icon_state = "hybrisa_colony_walls"

/turf/closed/wall/urban/colony
	name = "bare metal colony wall"
	icon = 'temp/LV759/icons/turf/walls/hybrisa_colony_walls.dmi'
	icon_state = "wall-0"
	walltype = "wall"
	base_icon_state = "hybrisa_colony_walls"

/turf/closed/wall/urban/colony/engineering
	name = "bare metal engineering wall"
	icon = 'temp/LV759/icons/turf/walls/hybrisa_colony_walls.dmi'
	icon_state = "wall-0"
	walltype = "wall"
	base_icon_state = "hybrisa_colony_walls"

/obj/item/card/data
	name = "data disk"
	desc = "A disk of data."
	icon_state = "data"
	var/function = "storage"
	var/data = "null"
	var/special = null

/obj/item/device/flashlight/lamp/tripod
	name = "tripod lamp"
	desc = "An emergency light tube mounted onto a tripod. It seemingly lasts forever."
	icon = 'temp/LV759/icons/obj/lighting.dmi'
	icon_state = "tripod_lamp"
	light_range = 6//pretty good

/obj/item/device/flashlight/lamp/tripod/grey
	icon_state = "tripod_lamp_grey"

/obj/item/trash/nt_chips
	name = "\improper Nanotrasen Pepper Chips"
	icon_state = "nt_chips_pepper"
	desc = "An oily empty bag that once held Nanotrasen Chips."

/obj/item/trash/nt_chips/pepper
	name = "\improper Nanotrasen Pepper Chips"
	icon_state = "nt_chips_pepper"
	desc = "An oily empty bag that once held Nanotrasen Pepper Chips."

/obj/item/trash/crushed_cup
	name = "crushed cup"
	desc = "A sad crushed and destroyed cup. It's now useless trash. What a waste."
	icon_state = "crushed_solocup"
	throwforce = 0
	w_class = WEIGHT_CLASS_TINY
	attack_verb = list("bludgeons", "whacks", "slaps")

/obj/item/trash/trashbag
	name = "trash bag"
	desc = "It's the heavy-duty black polymer kind. Time to take out the trash!"
	icon_state = "ztrashbag"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 1

/obj/item/trash/crushed_wbottle
	name = "crushed waterbottle"
	desc = "Overpriced 'Spring' water. Bottled by the Nanotrasen Corporation."
	icon_state = "waterbottle_crushed"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 1

/obj/item/trash/crushed_bottle
	name = "crushed bottle"
	desc = "A crushed bottle, it's hard to see the label."
	icon_state = "blank_can_crushed"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 1

/obj/item/trash/crushed_bottle/sixpackcrushed_1
	icon_state = "6_pack_1_crushed"

/obj/item/trash/cuppa_joes/lid
	name = "Cuppa Joe's coffee cup lid"
	desc = "Have you got the CuppaJoe Smile? Stay perky! Freeze-dried CuppaJoe's Coffee."
	icon_state = "coffeecuppajoelid"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 1

/obj/item/trash/cuppa_joes/empty_cup
	name = "Empty Cuppa Joe's coffee cup"
	desc = "Have you got the CuppaJoe Smile? Stay perky! Freeze-dried CuppaJoe's Coffee."
	icon_state = "coffeecuppajoenolid"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 1

/obj/item/trash/cuppa_joes_static/lid
	name = "Cuppa Joe's coffee cup lid"
	desc = "Have you got the CuppaJoe Smile? Stay perky! Freeze-dried CuppaJoe's Coffee."
	icon_state = "coffeecuppajoelid"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 1

/obj/item/trash/cuppa_joes_static/empty_cup
	name = "Empty Cuppa Joe's coffee cup"
	desc = "Have you got the CuppaJoe Smile? Stay perky! Freeze-dried CuppaJoe's Coffee."
	icon_state = "coffeecuppajoenolid"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 1

/obj/item/trash/cuppa_joes_static/empty_cup_stack
	name = "Empty Cuppa Joe's coffee cup stack"
	desc = "Have you got the CuppaJoe Smile? Stay perky! Freeze-dried CuppaJoe's Coffee."
	icon_state = "coffeecuppajoestacknolid"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 1

/obj/item/trash/cuppa_joes_static/lid_stack
	name = "Cuppa Joe's coffee cup lid stack"
	desc = "Have you got the CuppaJoe Smile? Stay perky! Freeze-dried CuppaJoe's Coffee."
	icon_state = "coffeecuppajoelidstack"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 1

/obj/machinery/space_heater/radiator
	name = "radiator"
	desc = "It's a radiator. It heats the room through convection with hot water. This one has a red handle."
	icon_state = "radiator"
	density = FALSE

/obj/machinery/space_heater/radiator/red
	icon_state = "radiator-r"

/obj/machinery/streetlight/street
	name = "Colony Streetlight"
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x64_urbanrandomprops.dmi'
	icon_state = "street_off"
	layer = MOB_BELOW_PIGGYBACK_LAYER
	resistance_flags = XENO_DAMAGEABLE
	max_integrity = 220
	density = FALSE

/obj/machinery/streetlight/traffic
	name = "traffic light"
	desc = "A traffic light"
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x64_urbanrandomprops.dmi'
	icon_state = "trafficlight"
	bound_width = 32
	bound_height = 32
	density = FALSE
	max_integrity = 200
	layer = MOB_BELOW_PIGGYBACK_LAYER
	resistance_flags = XENO_DAMAGEABLE

/obj/machinery/streetlight/traffic_alt
	name = "traffic light"
	desc = "A traffic light"
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x64_urbanrandomprops.dmi'
	icon_state = "trafficlight_alt"
	bound_width = 32
	bound_height = 32
	density = FALSE
	max_integrity = 200
	layer = ABOVE_MOB_LAYER
	resistance_flags = XENO_DAMAGEABLE

/obj/machinery/streetlight/engineer_circular
	name = "circular light"
	icon_state = "engineerlight_off"
	desc = "A huge circular light"
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanrandomprops.dmi'
	density = FALSE
	resistance_flags = RESIST_ALL
	wrenchable = FALSE
	layer = HIGH_TURF_LAYER
	light_color =  "#00ffa0"
	light_power = 6

/obj/structure/barricade/wooden
	name = "wooden barricade"
	desc = "A wall made out of wooden planks nailed together. Not very sturdy, but can provide some concealment."
	icon = 'temp/LV759/icons/obj/structures/barricades/misc.dmi'
	icon_state = "wooden"
	max_integrity = 100
	layer = OBJ_LAYER
	stack_type = /obj/item/stack/sheet/wood
	stack_amount = 5
	destroyed_stack_amount = 3
	hit_sound = "sound/effects/natural/woodhit.ogg"
	can_change_dmg_state = FALSE
	barricade_type = "wooden"
	can_wire = FALSE

/obj/structure/sign/double/barsign
	icon = 'temp/LV759/icons/obj/structures/barsigns.dmi'
	icon_state = "off"

/obj/structure/cargo_container/nt
	icon_state = "NT"

/obj/structure/concrete_planter
	name = "concrete seated planter"
	desc = "A decorative concrete planter."
	icon = 'temp/LV759/icons/obj/structures/prop/concrete_planter.dmi'
	icon_state = "planter"
	density = TRUE
	resistance_flags = XENO_DAMAGEABLE
	allow_pass_flags = PASS_LOW_STRUCTURE|PASSABLE|PASS_WALKOVER
	coverage = 80

/obj/structure/concrete_planter/seat
	name = "concrete seated planter"
	desc = "A decorative concrete planter with seating attached. The seats are fitted with synthetic leather, they've faded in time."
	icon_state = "planter_seats"

/obj/structure/fence/dark
	icon = 'temp/LV759/icons/obj/smooth_objects/dark_fence.dmi'
	icon_state = "darkfence"

/obj/structure/barricade/handrail/urban
	icon_state = "plasticroadbarrierred"
	stack_amount = 0 //we do not want it to drop any stuff when destroyed
	destroyed_stack_amount = 0
	barricade_type = "plasticroadbarrierred"
	soft_armor = list(MELEE = 0, BULLET = 50, LASER = 50, ENERGY = 50, BOMB = 15, BIO = 100, FIRE = 100, ACID = 10)

/obj/structure/barricade/handrail/urban/road/plastic
	name = "plastic road barrier"
	icon_state = "plasticroadbarrierred"
	barricade_type = "plasticroadbarrierred"

/obj/structure/barricade/handrail/urban/road/plastic/red
	name = "plastic road barrier"
	icon_state = "plasticroadbarrierred"
	barricade_type = "plasticroadbarrierred"

/obj/structure/barricade/handrail/urban/road/plastic/blue
	name = "plastic road barrier"
	icon_state = "plasticroadbarrierblue"
	barricade_type = "plasticroadbarrierblue"

/obj/structure/barricade/handrail/urban/road/plastic/black
	name = "plastic road barrier"
	icon_state = "plasticroadbarrierblack"
	barricade_type = "plasticroadbarrierblack"

/obj/structure/barricade/handrail/urban/road/wood
	name = "wood road barrier"
	icon_state = "roadbarrierwood"
	barricade_type = "roadbarrierwood"

/obj/structure/barricade/handrail/urban/road/wood/orange
	name = "wood road barrier"
	icon_state = "roadbarrierwood"
	barricade_type = "roadbarrierwood"

/obj/structure/barricade/handrail/urban/road/wood/blue
	name = "wood road barrier"
	icon_state = "roadbarrierpolice"
	barricade_type = "roadbarrierpolice"

/obj/structure/barricade/handrail/urban/road/metal
	name = "metal road barrier"
	icon_state = "centerroadbarrier"
	barricade_type = "centerroadbarrier"

/obj/structure/barricade/handrail/urban/road/metal/metaltan
	name = "metal road barrier"
	icon_state = "centerroadbarrier"
	barricade_type = "centerroadbarrier"

/obj/structure/barricade/handrail/urban/handrail
	name = "handrail"
	icon_state = "handrail_hybrisa"
	barricade_type = "handrail_hybrisa"

/obj/structure/prop/urban
	name = "GENERIC URBAN PROP NAME"

/obj/structure/prop/urban/supermart
	name = "long rack"
	icon_state = "longrack1"
	desc = "A long shelf filled with various foodstuffs"
	icon = 'temp/LV759/icons/obj/structures/prop/urban/supermart.dmi'
	density = TRUE

/obj/structure/prop/urban/supermart/rack/longrackempty
	name = "shelf"
	desc = "A long empty shelf."
	icon_state = "longrackempty"

/obj/structure/prop/urban/supermart/rack/longrack1
	name = "shelf"
	desc = "A long shelf filled with various foodstuffs"
	icon_state = "longrack1"

/obj/structure/prop/urban/supermart/rack/longrack2
	name = "shelf"
	desc = "A long shelf filled with various foodstuffs"
	icon_state = "longrack2"

/obj/structure/prop/urban/supermart/rack/longrack3
	name = "shelf"
	desc = "A long shelf filled with various foodstuffs"
	icon_state = "longrack3"

/obj/structure/prop/urban/supermart/rack/longrack5
	name = "shelf"
	desc = "A long shelf filled with various foodstuffs"
	icon_state = "longrack5"

/obj/structure/prop/urban/supermart/rack/longrack6
	name = "shelf"
	desc = "A long shelf filled with various foodstuffs"
	icon_state = "longrack6"

/obj/structure/prop/urban/supermart/rack/longrack7
	name = "shelf"
	desc = "A long shelf filled with various foodstuffs"
	icon_state = "longrack7"

/obj/structure/prop/urban/supermart/freezer
	name = "commercial freezer"
	desc = "A commercial grade freezer."
	icon_state = "freezerupper"
	density = TRUE

/obj/structure/prop/urban/supermart/freezer/supermartfreezer1
	icon_state = "freezerupper"

/obj/structure/prop/urban/supermart/freezer/supermartfreezer2
	icon_state = "freezerlower"

/obj/structure/prop/urban/supermart/freezer/supermartfreezer3
	icon_state = "freezermid"

/obj/structure/prop/urban/supermart/freezer/supermartfreezer4
	icon_state = "freezerupper1"

/obj/structure/prop/urban/supermart/freezer/supermartfreezer5
	icon_state = "freezerlower1"

/obj/structure/prop/urban/supermart/freezer/supermartfreezer6
	icon_state = "freezermid1"

/obj/structure/prop/urban/supermart/supermartfruitbasketempty
	name = "basket"
	desc = "A basket."
	icon_state = "supermarketbasketempty"

/obj/structure/prop/urban/supermart/supermartfruitbasketoranges
	name = "basket"
	desc = "A basket full of oranges."
	icon_state = "supermarketbasket1"

/obj/structure/prop/urban/supermart/supermartfruitbasketpears
	name = "basket"
	desc = "A basket full of pears."
	icon_state = "supermarketbasket2"

/obj/structure/prop/urban/supermart/supermartfruitbasketcarrots
	name = "basket"
	desc = "A basket full of carrots."
	icon_state = "supermarketbasket3"

/obj/structure/prop/urban/supermart/supermartfruitbasketmelons
	name = "basket"
	desc = "A basket full of melons."
	icon_state = "supermarketbasket4"

/obj/structure/prop/urban/supermart/supermartfruitbasketapples
	name = "basket"
	desc = "A basket full of apples."
	icon_state = "supermarketbasket5"

/obj/structure/prop/urban/furniture
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbantables.dmi'
	icon_state = "blackmetaltable"
	resistance_flags = XENO_DAMAGEABLE

/obj/structure/prop/urban/furniture/tables
	icon_state = "table_pool"
	allow_pass_flags = PASS_LOW_STRUCTURE|PASSABLE|PASS_WALKOVER

/obj/structure/prop/urban/furniture/tables/tableblack
	name = "large metal table"
	desc = "A large black metal table, looks very expensive."
	icon_state = "blackmetaltable"
	density = TRUE
	bound_height = 32
	bound_width = 64

/obj/structure/prop/urban/furniture/tables/tablepool
	name = "pool table"
	desc = "A large table used for Pool."
	icon_state = "table_pool"
	density = TRUE
	bound_height = 32
	bound_width = 64

/obj/structure/prop/urban/furniture/tables/tablegambling
	name = "gambling table"
	desc = "A large table used for gambling."
	icon_state = "table_cards"
	density = TRUE
	bound_height = 32
	bound_width = 64

/obj/structure/bed/urban/chairs
	name = "expensive chair"
	desc = "An expensive looking chair"
	resistance_flags = XENO_DAMAGEABLE
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanrandomprops.dmi'

/obj/structure/bed/urban/chairs/black
	icon_state = "comfychair_zenithblack"

/obj/structure/bed/urban/chairs/red
	icon_state = "comfychair_zenithred"

/obj/structure/bed/urban/chairs/brown
	icon_state = "comfychair_zenithbrown"

/obj/structure/bed/urban
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanrandomprops.dmi'
	icon_state = "hybrisa"

/obj/structure/bed/urban/prisonbed
	name = "bunk bed"
	desc = "A sorry looking bunk-bed."
	icon_state = "prisonbed"

/obj/structure/bed/urban/bunkbed1
	name = "bunk bed"
	desc = "A comfy looking bunk-bed."
	icon_state = "zbunkbed"

/obj/structure/bed/urban/bunkbed2
	name = "bunk bed"
	desc = "A comfy looking bunk-bed."
	icon_state = "zbunkbed2"

/obj/structure/bed/urban/bunkbed3
	name = "bunk bed"
	desc = "A comfy looking bunk-bed."
	icon_state = "zbunkbed3"

/obj/structure/bed/urban/bunkbed4
	name = "bunk bed"
	desc = "A comfy looking bunk-bed."
	icon_state = "zbunkbed4"

/obj/structure/prop/urban/xenobiology
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanxenocryogenics.dmi'
	icon_state = "xenocellemptyon"
	layer = ABOVE_MOB_LAYER

/obj/structure/prop/urban/xenobiology/small/empty
	name = "specimen containment cell"
	desc = "It's empty."
	icon_state = "xenocellemptyon"
	density = TRUE

/obj/structure/prop/urban/xenobiology/small/offempty
	name = "specimen containment cell"
	desc = "It's turned off and empty."
	icon_state = "xenocellemptyoff"
	density = TRUE

/obj/structure/prop/urban/xenobiology/small/larva
	name = "specimen containment cell"
	desc = "There is something worm-like inside..."
	icon_state = "xenocelllarva"
	density = TRUE

/obj/structure/prop/urban/xenobiology/small/egg
	name = "specimen containment cell"
	desc = "There is, what looks like some sort of egg inside..."
	icon_state = "xenocellegg"
	density = TRUE

/obj/structure/prop/urban/xenobiology/small/hugger
	name = "specimen containment cell"
	desc = "There's something spider-like inside..."
	icon_state = "xenocellhugger"
	density = TRUE

/obj/structure/prop/urban/xenobiology/small/cracked1
	name = "specimen containment cell"
	desc = "Looks like something broke it...from the inside."
	icon_state = "xenocellcrackedempty"
	density = TRUE

/obj/structure/prop/urban/xenobiology/small/cracked2
	name = "specimen containment cell"
	desc = "Looks like something broke it...from the inside."
	icon_state = "xenocellcrackedempty2"
	density = TRUE

/obj/structure/prop/urban/xenobiology/small/crackedegg
	name = "specimen containment cell"
	desc = "Looks like something broke it, there's a giant empty egg inside."
	icon_state = "xenocellcrackedegg"
	density = TRUE

/obj/structure/prop/urban/xenobiology/big
	name = "specimen containment cell"
	desc = "A giant tube with a hulking monstrosity inside, is this thing alive?"
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanxenocryogenics2.dmi'
	icon_state = "bigqueencryo1"

/obj/structure/prop/urban/xenobiology/big/bigleft
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanxenocryogenics2.dmi'
	icon_state = "bigqueencryo1"
	layer = ABOVE_MOB_LAYER

/obj/structure/prop/urban/xenobiology/big/bigright
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanxenocryogenics2.dmi'
	icon_state = "bigqueencryo2"
	layer = ABOVE_MOB_LAYER

/obj/structure/prop/urban/xenobiology/big/bigbottomleft
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanxenocryogenics2.dmi'
	icon_state = "bigqueencryo3"
	density = TRUE
	layer = ABOVE_MOB_LAYER

/obj/structure/prop/urban/xenobiology/big/bigbottomright
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanxenocryogenics2.dmi'
	icon_state = "bigqueencryo4"
	density = TRUE
	layer = ABOVE_MOB_LAYER

/obj/structure/prop/urban/xenobiology/misc
	name = "strange egg"
	desc = "A strange ancient looking egg, it seems to be inert."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanrandomprops.dmi'
	icon_state = "inertegg"
	layer = 2

/obj/structure/prop/urban/engineer
	icon = 'temp/LV759/icons/obj/structures/prop/urban/engineerjockey.dmi'

/obj/structure/prop/urban/engineer/spacejockey
	name = "Giant Pilot"
	desc = "A Giant Alien life form. Looks like it's been dead a long time. Fossilized. Looks like it's growing out of the chair. Bones are bent outward, like it exploded from inside."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/engineerjockey.dmi'
	icon_state = "spacejockey"
	layer = ABOVE_MOB_LAYER
	resistance_flags = RESIST_ALL

/obj/structure/prop/urban/engineer/engineerpillar
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanengineerpillarangled.dmi'
	icon_state = "engineerpillar_SW1fade"
	bound_height = 64
	bound_width = 128
	layer = ABOVE_MOB_LAYER

/obj/structure/prop/urban/engineer/engineerpillar/northwesttop
	name = "strange pillar"
	icon_state = "engineerpillar_NW1"

/obj/structure/prop/urban/engineer/engineerpillar/northwestbottom
	name = "strange pillar"
	icon_state = "engineerpillar_NW2"

/obj/structure/prop/urban/engineer/engineerpillar/smallsouthwest1
	name = "strange pillar"
	icon_state = "engineerpillar_SW1fade"

/obj/structure/prop/urban/airport
	name = "nose cone"
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanrandomprops.dmi'
	icon_state = "dropshipfrontwhite1"

/obj/structure/prop/urban/airport/dropshipenginedamage
	name = "dropship damage"
	desc = "the engine appears to have severe damage."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "dropship_engine_damage"
	bound_height = 64
	bound_width = 96

/obj/structure/prop/urban/airport/refuelinghose
	name = "refueling hose"
	desc = "A long refueling hose that connects to various types of dropships."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "fuelline1"
	bound_height = 64
	bound_width = 96
	layer = ABOVE_WEEDS_LAYER
	plane = FLOOR_PLANE

/obj/structure/prop/urban/airport/refuelinghose2
	name = "refueling hose"
	desc = "A long refueling hose that connects to various types of dropships."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "fuelline2"
	bound_height = 64
	bound_width = 96
	layer = ABOVE_WEEDS_LAYER
	plane = FLOOR_PLANE

/obj/structure/prop/urban/misc
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanrandomprops.dmi'
	icon_state = "roadbarrier"

/obj/structure/prop/urban/misc/floorprops
	icon_state = "solidgrate1"

/obj/structure/prop/urban/misc/floorprops/grate
	name = "solid metal grate"
	desc = "A metal grate."
	icon_state = "solidgrate1"
	layer = LATTICE_LAYER

/obj/structure/prop/urban/misc/floorprops/floorglass2
	name = "reinforced glass floor"
	desc = "A heavily reinforced glass floor panel, this looks almost indestructible."
	icon_state = "solidgrate3"
	layer = 2.1

/obj/structure/prop/urban/misc/graffiti
	name = "graffiti"
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "zgraffiti4"
	bound_height = 64
	bound_width = 96
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/structure/prop/urban/misc/graffiti/graffiti1
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "zgraffiti1"

/obj/structure/prop/urban/misc/graffiti/graffiti2
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "zgraffiti2"

/obj/structure/prop/urban/misc/graffiti/graffiti3
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "zgraffiti3"

/obj/structure/prop/urban/misc/graffiti/graffiti4
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "zgraffiti4"

/obj/structure/prop/urban/misc/graffiti/graffiti5
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "zgraffiti5"

/obj/structure/prop/urban/misc/graffiti/graffiti6
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "zgraffiti6"

/obj/structure/prop/urban/misc/graffiti/graffiti7
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "zgraffiti7"

/obj/structure/prop/urban/misc/blood
	name = "blood"
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "wallblood_floorblood"

/obj/structure/prop/urban/misc/blood/blood1
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "wallblood_floorblood"

/obj/structure/prop/urban/misc/blood/blood2
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "wall_blood_1"

/obj/structure/prop/urban/misc/blood/blood3
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "wall_blood_2"

/obj/structure/prop/urban/misc/fire/fire1
	name = "fire"
	desc = "It's hot, smoking even."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x96-urbanrandomprops.dmi'
	icon_state = "zfire_smoke"
	layer = 5
	light_on = TRUE
	light_power = 2
	light_range = 3

/obj/structure/prop/urban/misc/cabinet
	name = "cabinet"
	desc = "a small cabinet with drawers."
	icon_state = "sidecabinet"

/obj/structure/prop/urban/misc/trash/green
	name = "trash bin"
	desc = "A Nanotrasen trash bin used for disposing your unwanted items, or you can just throw your shit on the ground like every other asshole."
	icon_state = "trashgreen"

/obj/structure/prop/urban/misc/redmeter
	name = "meter"
	icon_state = "redmeter"

/obj/structure/prop/urban/misc/slotmachine
	name = "slot machine"
	desc = "A slot machine."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x64_urbanrandomprops.dmi'
	icon_state = "slotmachine"
	bound_width = 32
	bound_height = 32
	anchored = TRUE
	density = TRUE
	layer = 3.2

/obj/structure/prop/urban/misc/atm
	name = "\improper NanoTrasen Automatic Teller Machine"
	desc = "For all your monetary needs!"
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x64_urbanrandomprops.dmi'
	icon_state = "atm"
	bound_width = 32
	bound_height = 32
	anchored = TRUE
	density = TRUE
	layer = 3.2

/obj/structure/prop/urban/misc/slotmachine_broken
	name = "slot machine"
	desc = "A broken slot machine."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x64_urbanrandomprops.dmi'
	icon_state = "slotmachine_broken"
	bound_width = 32
	bound_height = 32
	anchored = TRUE
	density = TRUE
	layer = 3.2

/obj/structure/prop/urban/misc/coffeestuff/coffeemachine1
	name = "coffee machine"
	desc = "A coffee machine."
	icon_state = "coffee"

/obj/structure/prop/urban/misc/coffeestuff/coffeemachine2
	name = "coffee machine"
	desc = "A coffee machine."
	icon_state = "coffee_cup"

/obj/structure/prop/urban/misc/machinery/screens
	name = "monitor"
	desc = "A screen, useful for broadcasting events. It looks like it's seen better days."
	resistance_flags = XENO_DAMAGEABLE
	max_integrity = 50

/obj/structure/prop/urban/misc/machinery/screens/frame
	icon_state = "frame"

/obj/structure/prop/urban/misc/machinery/screens/redalert
	icon_state = "redalert"

/obj/structure/prop/urban/misc/machinery/screens/redalertblank
	icon_state = "redalertblank"

/obj/structure/prop/urban/misc/machinery/screens/entertainment
	icon_state = "entertainment"

/obj/structure/prop/urban/misc/machinery/screens/telescreen
	icon_state = "telescreen"

/obj/structure/prop/urban/misc/machinery/screens/telescreenbroke
	icon_state = "telescreenb"

/obj/structure/prop/urban/misc/machinery/screens/telescreenbrokespark
	icon_state = "telescreenbspark"

/obj/structure/prop/urban/misc/machinery/screens/multimonitorsmall_off
	icon_state = "multimonitorsmall_off"

/obj/structure/prop/urban/misc/machinery/screens/multimonitorsmall_on
	icon_state = "multimonitorsmall_on"

/obj/structure/prop/urban/misc/machinery/screens/multimonitormedium_off
	icon_state = "multimonitormedium_off"

/obj/structure/prop/urban/misc/machinery/screens/multimonitormedium_on
	icon_state = "multimonitormedium_on"

/obj/structure/prop/urban/misc/machinery/screens/multimonitorbig_off
	icon_state = "multimonitorbig_off"

/obj/structure/prop/urban/misc/machinery/screens/multimonitorbig_on
	icon_state = "multimonitorbig_on"

/obj/structure/prop/urban/misc/machinery/screens/bluemultimonitorsmall_off
	icon_state = "bluemultimonitorsmall_off"

/obj/structure/prop/urban/misc/machinery/screens/bluemultimonitorsmall_on
	icon_state = "bluemultimonitorsmall_on"

/obj/structure/prop/urban/misc/machinery/screens/bluemultimonitormedium_on
	icon_state = "bluemultimonitormedium_on"

/obj/structure/prop/urban/misc/machinery/screens/bluemultimonitorbig_on
	icon_state = "bluemultimonitorbig_on"

/obj/structure/prop/urban/misc/machinery/screens/wallegg_off
	icon_state = "wallegg_off"

/obj/structure/prop/urban/misc/machinery/screens/wallegg_on
	icon_state = "wallegg_on"

/obj/structure/prop/urban/misc/fake/pipes
	name = "disposal pipe"
	desc = "A small pipe."

/obj/structure/prop/urban/misc/fake/pipes/pipe1
	layer = 2
	icon_state = "pipe-s"

/obj/structure/prop/urban/misc/fake/pipes/pipe2
	layer = 2
	icon_state = "pipe-c"

/obj/structure/prop/urban/misc/fake/pipes/pipe3
	layer = 2
	icon_state = "pipe-j1"

/obj/structure/prop/urban/misc/fake/pipes/pipe4
	layer = 2
	icon_state = "pipe-y"

/obj/structure/prop/urban/misc/fake/pipes/pipe5
	layer = 2
	icon_state = "pipe-b"

/obj/structure/prop/urban/misc/fake/wire
	name = "power cable"
	desc = "A small gauge wire for conducting electricity."
	layer = ABOVE_NORMAL_TURF_LAYER

/obj/structure/prop/urban/misc/fake/wire/red
	layer = 2
	icon_state = "intactred"

/obj/structure/prop/urban/misc/fake/wire/yellow
	layer = 2
	icon_state = "intactyellow"

/obj/structure/prop/urban/misc/fake/wire/blue
	layer = 2
	icon_state = "intactblue"

/obj/structure/prop/urban/misc/fake/heavydutywire
	name = "heavy duty wire"
	desc = "A heavy duty wire for conducting electricity."

/obj/structure/prop/urban/misc/fake/heavydutywire/heavy2
	layer = 2
	icon_state = "1-2"

/obj/structure/prop/urban/misc/fake/heavydutywire/heavy3
	layer = 2
	icon_state = "1-4"

/obj/structure/prop/urban/misc/fake/heavydutywire/heavy4
	layer = 2
	icon_state = "1-2-4"

/obj/structure/prop/urban/misc/fake/lattice
	name = "structural lattice"

/obj/structure/prop/urban/misc/fake/lattice/full
	icon_state = "latticefull"
	layer = 2

/obj/structure/prop/urban/containersextended
	name = "cargo container"
	desc = "a cargo container."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/containersextended.dmi'
	icon_state = "blackwyleft"
	bound_width = 32
	bound_height = 32
	density = TRUE
	max_integrity = 200
	opacity = TRUE
	anchored = TRUE
	layer = 5

/obj/structure/prop/urban/containersextended/blueleft
	name = "cargo container"
	icon_state = "blueleft"

/obj/structure/prop/urban/containersextended/blueright
	name = "cargo container"
	icon_state = "blueright"

/obj/structure/prop/urban/containersextended/greenleft
	name = "cargo container"
	icon_state = "greenleft"

/obj/structure/prop/urban/containersextended/greenright
	name = "cargo container"
	icon_state = "greenright"

/obj/structure/prop/urban/containersextended/tanleft
	name = "cargo container"
	icon_state = "tanleft"

/obj/structure/prop/urban/containersextended/tanright
	name = "cargo container"
	icon_state = "tanright"

/obj/structure/prop/urban/containersextended/redleft
	name = "cargo container"
	icon_state = "redleft"

/obj/structure/prop/urban/containersextended/redright
	name = "cargo container"
	icon_state = "redright"

/obj/structure/prop/urban/containersextended/greywyleft
	name = "\improper Nanotrasen cargo container"
	icon_state = "greywyleft"

/obj/structure/prop/urban/containersextended/greywyright
	name = "\improper Nanotrasen cargo container"
	icon_state = "greywyright"

/obj/structure/prop/urban/containersextended/lightgreywyleft
	name = "\improper Nanotrasen cargo container"
	icon_state = "lightgreywyleft"

/obj/structure/prop/urban/containersextended/lightgreywyright
	name = "\improper Nanotrasen cargo container"
	icon_state = "lightgreywyright"

/obj/structure/prop/urban/containersextended/blackwyleft
	name = "\improper Nanotrasen cargo container"
	icon_state = "blackwyleft"

/obj/structure/prop/urban/containersextended/blackwyright
	name = "\improper Nanotrasen cargo container"
	icon_state = "blackwyright"

/obj/structure/prop/urban/containersextended/whitewyleft
	name = "\improper Nanotrasen cargo container"
	icon_state = "whitewyleft"

/obj/structure/prop/urban/containersextended/whitewyright
	name = "\improper Nanotrasen cargo container"
	icon_state = "whitewyright"

/obj/structure/prop/urban/containersextended/tanwywingsleft
	name = "cargo container"
	icon_state = "tanwywingsleft"

/obj/structure/prop/urban/containersextended/tanwywingsright
	name = "cargo container"
	icon_state = "tanwywingsright"

/obj/structure/prop/urban/containersextended/greenwywingsleft
	name = "cargo container"
	icon_state = "greenwywingsleft"

/obj/structure/prop/urban/containersextended/greenwywingsright
	name = "cargo container"
	icon_state = "greenwywingsright"

/obj/structure/prop/urban/containersextended/bluewywingsleft
	name = "cargo container"
	icon_state = "bluewywingsleft"

/obj/structure/prop/urban/containersextended/bluewywingsright
	name = "cargo container"
	icon_state = "bluewywingsright"

/obj/structure/prop/urban/containersextended/redwywingsleft
	name = "cargo container"
	icon_state = "redwywingsleft"

/obj/structure/prop/urban/containersextended/redwywingsright
	name = "cargo container"
	icon_state = "redwywingsright"

/obj/structure/prop/urban/containersextended/medicalleft
	name = "medical cargo containers"
	icon_state = "medicalleft"

/obj/structure/prop/urban/containersextended/medicalright
	name = "medical cargo containers"
	icon_state = "medicalright"

/obj/structure/prop/urban/containersextended/emptymedicalright
	name = "medical cargo container"
	icon_state = "emptymedicalright"

/obj/structure/prop/urban/containersextended/graffiti
	name = "defaced cargo container"
	icon_state = "grafcontain_l"

/obj/structure/prop/urban/containersextended/graffiti/two
	name = "defaced cargo container"
	icon_state = "grafcontain_rm"

/obj/structure/prop/urban/containersextended/graffiti/three
	name = "defaced cargo container"
	icon_state = "grafcontain_r"

/obj/structure/prop/urban/containersextended/graffiti/four
	name = "defaced cargo container"
	icon_state = "grafcontain2_l"

/obj/structure/prop/urban/containersextended/graffiti/five
	name = "defaced cargo container"
	icon_state = "grafcontain2_rm"

/obj/structure/prop/urban/containersextended/graffiti/seven
	name = "defaced cargo container"
	icon_state = "grafcontain3_l"

/obj/structure/prop/urban/containersextended/graffiti/eight
	name = "defaced cargo container"
	icon_state = "grafcontain3_rm"

/obj/structure/prop/urban/containersextended/graffiti/nine
	name = "defaced cargo container"
	icon_state = "grafcontain3_r"

/obj/structure/prop/urban/fakeplatforms
	name = "platform"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanrandomprops.dmi'

/obj/structure/prop/urban/fakeplatforms/platform1
	icon_state = "engineer_platform"

/obj/structure/prop/urban/fakeplatforms/platform3
	icon_state = "platform"

/obj/structure/prop/urban/fakeplatforms/platform4
	icon_state = "zenithplatform3"

/obj/structure/prop/urban/fakeplatforms/rockplatform
	icon_state = "kutjevo_rockdark_fake"
	icon = 'temp/LV759/icons/obj/structures/platforms.dmi'

/obj/structure/prop/urban/misc/buildinggreeblies
	name = "machinery"
	desc = "A strange piece of machinery attached to a wall..."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x64_urbanrandomprops.dmi'
	icon_state = "buildingventbig1"
	bound_width = 64
	bound_height = 32
	density = FALSE
	max_integrity = 200
	anchored = TRUE
	layer = 5
	coverage = 50

/obj/structure/prop/urban/misc/buildinggreeblies/greeble1
	icon_state = "buildingventbig2"

/obj/structure/prop/urban/misc/buildinggreeblies/greeble2
	icon_state = "buildingventbig3"

/obj/structure/prop/urban/misc/buildinggreeblies/greeble3
	icon_state = "buildingventbig4"

/obj/structure/prop/urban/misc/buildinggreeblies/greeble4
	icon_state = "buildingventbig5"

/obj/structure/prop/urban/misc/buildinggreeblies/greeble5
	icon_state = "buildingventbig6"

/obj/structure/prop/urban/misc/buildinggreeblies/greeble6
	icon_state = "buildingventbig7"

/obj/structure/prop/urban/misc/buildinggreeblies/greeble7
	icon_state = "buildingventbig8"

/obj/structure/prop/urban/misc/buildinggreeblies/greeble9
	icon_state = "buildingventbig10"
	bound_width = 32

/obj/structure/prop/urban/misc/buildinggreeblies/greeble10
	icon_state = "buildingventbig11"
	bound_width = 32
	bound_height = 64

/obj/structure/prop/urban/misc/buildinggreeblies/greeble11
	icon_state = "buildingventbig12"
	bound_width = 32
	bound_height = 64

/obj/structure/prop/urban/misc/buildinggreeblies/greeble12
	icon_state = "buildingventbig13"
	bound_width = 32
	bound_height = 64

/obj/structure/prop/urban/misc/buildinggreebliessmall
	name = "wall vent"
	desc = "A small piece of odd looking machinery..."
	icon_state = "smallwallvent1"
	density = FALSE

/obj/structure/prop/urban/misc/buildinggreebliessmall2
	name = "wall vent"
	icon_state = "smallwallvent2"

/obj/structure/prop/urban/misc/buildinggreebliessmall2
	name = "wall vent"
	icon_state = "smallwallvent2"

/obj/structure/prop/urban/misc/buildinggreebliessmall3
	name = "wall vent"
	icon_state = "smallwallvent3"

/obj/structure/prop/urban/misc/buildinggreebliessmall/computer
	name = "machinery"
	icon_state = "zcomputermachine"
	density = TRUE

/obj/structure/prop/urban/misc/metergreen
	name = "meter"
	desc = "A power meter, useful for gauging energy fluctuations."
	icon_state = "biggreenmeter1"

/obj/structure/prop/urban/misc/concretestatue
	name = "concrete statue"
	desc = "A decorative statue with the Nanotrasen 'Wings' adorned on it, A corporate brutalist piece of art."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x64_urbanrandomprops.dmi'
	icon_state = "concretesculpture"
	bound_width = 64
	bound_height = 64
	density = TRUE
	anchored = TRUE

/obj/structure/prop/urban/misc/firehydrant
	name = "fire hydrant"
	desc = "A fire hydrant public water outlet, designed for quick access to water."
	icon_state = "firehydrant"
	density = FALSE
	anchored = TRUE
	resistance_flags = XENO_DAMAGEABLE
	max_integrity = 150

/obj/structure/prop/urban/misc/phonebox
	name = "phonebox"
	desc = "A phone-box, it doesn't seem to be working, the line must be down."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x64_urbanrandomprops.dmi'
	icon_state = "phonebox_closed"
	layer = ABOVE_MOB_LAYER
	bound_width = 32
	bound_height = 32
	density = TRUE
	anchored = TRUE

/obj/structure/prop/urban/misc/phonebox/broken
	desc = "A phone-box, it doesn't seem to be working, the line must be down. The glass has been broken."
	icon_state = "phonebox_closed_broken"

/obj/structure/prop/urban/misc/phonebox/lightup
	desc = "A phone-box, it doesn't seem to be working, the line must be down."
	icon_state = "phonebox_closed_light"

/obj/structure/prop/urban/misc/bench
	name = "bench"
	desc = "A metal frame, with seats that are fitted with synthetic leather, they've faded in time."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x64_urbanrandomprops.dmi'
	icon_state = "seatedbench"
	bound_width = 32
	bound_height = 64
	layer = 4
	density = FALSE
	max_integrity = 200
	anchored = TRUE
	resistance_flags = XENO_DAMAGEABLE

/obj/structure/prop/urban/signs
	name = "neon sign"
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urban64x64_signs.dmi'
	icon_state = "jacksopen_on"
	bound_height = 64
	bound_width = 64
	layer = ABOVE_MOB_LAYER
	resistance_flags = XENO_DAMAGEABLE
	max_integrity = 80

/obj/structure/prop/urban/signs/casniosign
	name = "casino sign"
	icon_state = "nightgoldcasinoopen_on"

/obj/structure/prop/urban/signs/jackssign
	name = "jack's surplus sign"
	icon_state = "jacksopen_on"

/obj/structure/prop/urban/signs/opensign
	name = "open sign"
	icon_state = "open_on"

/obj/structure/prop/urban/signs/pizzasign
	name = "pizza sign"
	icon_state = "pizzaneon_on"

/obj/structure/prop/urban/signs/weymartsign
	name = "ntmart sign"
	icon_state = "weymartsign2"

/obj/structure/prop/urban/signs/mechanicsign
	name = "mechanic sign"
	icon_state = "mechanicopen_on2"

/obj/structure/prop/urban/signs/cuppajoessign
	name = "cuppa joe's sign"
	icon_state = "cuppajoes"

/obj/structure/prop/urban/signs/barsign
	name = "bar sign"
	icon_state = "barsign_on"

/obj/structure/prop/urban/signs/high_voltage
	name = "warning sign"
	desc = "DANGER - HIGH VOLTAGE - DEATH!."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanrandomprops.dmi'
	icon_state = "shockyBig"

/obj/structure/prop/urban/signs/high_voltage/small
	name = "warning sign"
	desc = "DANGER - HIGH VOLTAGE - DEATH!."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanrandomprops.dmi'
	icon_state = "shockyTiny"

/obj/structure/prop/urban/billboardsandsigns/bigbillboards
	name = "billboard"
	desc = "A advertisement billboard."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/32x64_urbanbillboards.dmi'
	icon_state = "billboard_bigger"
	density = FALSE
	max_integrity = 200
	anchored = TRUE

/obj/structure/prop/urban/billboardsandsigns/bigbillboards/billboard1
	icon_state = "billboard1"

/obj/structure/prop/urban/billboardsandsigns/bigbillboards/billboard2
	icon_state = "billboard2"

/obj/structure/prop/urban/billboardsandsigns/bigbillboards/billboard3
	icon_state = "billboard3"

/obj/structure/prop/urban/billboardsandsigns/bigbillboards/billboard4
	icon_state = "billboard4"

/obj/structure/prop/urban/billboardsandsigns/bigroadsigns
	name = "road sign"
	desc = "A road sign."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x64_urbanrandomprops.dmi'
	icon_state = "roadsign_1"
	bound_width = 64
	bound_height = 32
	density = FALSE
	max_integrity = 200
	anchored = TRUE
	layer = 8

/obj/structure/prop/urban/billboardsandsigns/bigroadsigns/road_sign_1
	icon_state = "roadsign_1"

/obj/structure/prop/urban/billboardsandsigns/bigroadsigns/road_sign_2
	icon_state = "roadsign_2"

/obj/structure/prop/urban/factory
	icon = 'temp/LV759/icons/obj/structures/prop/urban/64x64_urbanrandomprops.dmi'
	icon_state = "factory_roboticarm"

/obj/structure/prop/urban/factory/robotic_arm
	name = "Robotic arm"
	desc = "A robotic arm used in the construction of 'Meridian' Automobiles."
	icon_state = "factory_roboticarm"
	bound_width = 64
	bound_height = 32
	anchored = TRUE

/obj/structure/prop/urban/factory/robotic_arm/flipped
	icon_state = "factory_roboticarm2"

/obj/structure/prop/urban/factory/conveyor_belt
	name = "large conveyor belt"
	desc = "A large conveyor belt used in industrial factories."
	icon_state = "factory_conveyer"
	density = FALSE

/obj/structure/prop/urban/lattice_prop
	desc = "A support lattice."
	name = "lattice"
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urban_lattice.dmi'
	icon_state = "lattice1"
	density = FALSE
	layer = RIPPLE_LAYER
	max_integrity = 6000

/obj/structure/prop/urban/lattice_prop/lattice_1
	icon_state = "lattice1"

/obj/structure/prop/urban/lattice_prop/lattice_2
	icon_state = "lattice2"

/obj/structure/prop/urban/lattice_prop/lattice_3
	icon_state = "lattice3"

/obj/structure/prop/urban/lattice_prop/lattice_4
	icon_state = "lattice4"

/obj/structure/prop/urban/lattice_prop/lattice_5
	icon_state = "lattice5"

/obj/structure/prop/urban/lattice_prop/lattice_6
	icon_state = "lattice6"

/obj/structure/prop/urban/vehicles/large
	icon = 'temp/LV759/icons/obj/structures/prop/urban/128x32_vehiclesexpanded.dmi'
	layer = ABOVE_MOB_LAYER

/obj/structure/prop/urban/vehicles/large/ambulance
	name = "ambulance"
	desc = "Seems to be broken down."
	icon_state = "ambulance"
	bound_height = 32
	bound_width = 96

/obj/structure/prop/urban/vehicles/large/armored_trucks
	icon_state = "armoredtruck_wy_security_1"
	bound_height = 32
	bound_width = 96

/obj/structure/prop/urban/vehicles/large/armored_trucks/nt_security/truck_1
	name = "\improper Nanotrasen security truck"
	desc = "Seems to be broken down."
	icon_state = "armoredtruck_nt_security_1"

/obj/structure/prop/urban/vehicles/large/armored_trucks/nt_security/truck_2
	name = "\improper Nanotrasen security truck"
	desc = "Seems to be broken down."
	icon_state = "armoredtruck_nt_security_2"

/obj/structure/prop/urban/vehicles/large/armored_trucks/heavy_loader/white
	name = "heavy loader truck"
	desc = "Seems to be broken down."
	icon_state = "armoredtruck_white_white"

/obj/structure/prop/urban/vehicles/large/armored_trucks/heavy_loader/white_teal
	name = "heavy loader truck"
	desc = "Seems to be broken down."
	icon_state = "armoredtruck_white_teal"

/obj/structure/prop/urban/vehicles/large/armored_trucks/heavy_loader/blue_white
	name = "heavy loader truck"
	desc = "Seems to be broken down."
	icon_state = "armoredtruck_blue_white"

/obj/structure/prop/urban/vehicles/large/mega_hauler_truck
	name = "mega-hauler truck"
	icon_state = "longtruck_kellandmining"
	desc = "Seems to be broken down."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/128x32_vehiclesexpanded.dmi'
	bound_height = 32
	bound_width = 128
	resistance_flags = XENO_DAMAGEABLE
	max_integrity = 1000 //mega hauler trucks are still tanks that soak up fire
	coverage = 100
	soft_armor = list(MELEE = 30, BULLET = 90, LASER = 95, ENERGY = 55, BOMB = 60, BIO = 10, FIRE = 10, ACID = 10)

/obj/structure/prop/urban/vehicles/large/mega_hauler_truck/kelland
	icon_state = "longtruck_kellandmining"

/obj/structure/prop/urban/vehicles/large/mega_hauler_truck/red_stripe
	icon_state = "longtruck_blue_redstripe"

/obj/structure/prop/urban/vehicles/large/mega_hauler_truck/blue_stripe
	icon_state = "longtruck_red_bluestripe"

/obj/structure/prop/urban/vehicles/large/mega_hauler_truck/brown
	icon_state = "longtruck_brown"

/obj/structure/prop/urban/vehicles/large/mega_hauler_truck/donk
	icon_state = "longtruck_donk"

/obj/structure/prop/urban/vehicles/large/mega_hauler_truck/nt_black
	name = "\improper Nanotrasen mega-hauler truck"
	icon_state = "longtruck_nt_black"

/obj/structure/prop/urban/vehicles/large/mega_hauler_truck/nt_blue
	name = "\improper Nanotrasen mega-hauler truck"
	icon_state = "longtruck_nt_blue"

/obj/structure/prop/urban/vehicles/large/suv
	name = "SUV"
	desc = "Seems to be broken down."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/vehiclesexpanded.dmi'
	icon_state = "SUV"
	bound_height = 32
	bound_width = 64
	coverage = 75

/obj/structure/prop/urban/vehicles/large/truck
	name = "truck"
	icon_state = "zentruck1"
	desc = "Seems to be broken down."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/vehiclesexpanded.dmi'
	bound_height = 32
	bound_width = 64
	max_integrity = 120

/obj/structure/prop/urban/vehicles/large/truck/truck2
	icon_state = "zentruck3"

/obj/structure/prop/urban/vehicles/large/truck/truck3
	icon_state = "zentruck4"

/obj/structure/prop/urban/vehicles/large/truck/truck4
	icon_state = "zentruck5"

/obj/structure/prop/urban/vehicles/large/truck/truck5
	icon_state = "truck_cargo"

/obj/structure/prop/urban/vehicles/large/truck/truck6
	icon_state = "truck"

/obj/structure/prop/urban/vehicles/large/truck/garbage
	name = "garbage truck"
	icon_state = "zengarbagetruck"
	desc = "Seems to be broken down."

/obj/structure/prop/urban/vehicles/large/truck/mining
	name = "mining supply truck"
	icon_state = "truck_mining"
	desc = "Seems to be broken down."

/obj/structure/prop/urban/vehicles/large/colonycrawlers
	icon_state = "crawler_wy2"
	icon = 'temp/LV759/icons/obj/structures/prop/urban/vehiclesexpanded.dmi'
	bound_height = 32
	bound_width = 64

/obj/structure/prop/urban/vehicles/large/colonycrawlers/mining
	icon_state = "miningcrawler1"
	desc = "It is a tread bound crawler used in harsh conditions. Supplied by The Kelland Mining Company; A subsidiary of Nanotrasen."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/vehiclesexpanded.dmi'

/obj/structure/prop/urban/vehicles/large/colonycrawlers/mining2
	icon_state = "crawler_fuel"
	desc = "It is a tread bound crawler used in harsh conditions. Supplied by The Kelland Mining Company; A subsidiary of Nanotrasen."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/vehiclesexpanded.dmi'

/obj/structure/prop/urban/vehicles/large/colonycrawlers/mining3
	icon_state = "crawler_covered_bed"
	desc = "It is a tread bound crawler used in harsh conditions. Supplied by The Kelland Mining Company; A subsidiary of Nanotrasen."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/vehiclesexpanded.dmi'

/obj/structure/prop/urban/vehicles/large/colonycrawlers/science
	icon_state = "crawler_wy2"
	desc = "It is a tread bound crawler used in harsh conditions. This one is designed for personnel transportation. Supplied by Orbital Blue International; 'Your friends, in the Aerospace business.' A subsidiary of Nanotrasen."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/vehiclesexpanded.dmi'

/obj/structure/prop/urban/vehicles/large/colonycrawlers/science
	name = "\improper Nanotrasen colony crawler"

/obj/structure/prop/urban/vehicles/large/colonycrawlers/science/science1
	icon_state = "crawler_wy1"
	icon = 'temp/LV759/icons/obj/structures/prop/urban/vehiclesexpanded.dmi'

/obj/structure/prop/urban/vehicles/large/colonycrawlers/science/science2
	icon_state = "crawler_wy2"
	icon = 'temp/LV759/icons/obj/structures/prop/urban/vehiclesexpanded.dmi'

/obj/structure/prop/urban/vehicles/large/colonycrawlers/mining
	name = "kelland mining colony crawler"

/obj/structure/prop/urban/vehicles/large/colonycrawlers/mining/mining1
	desc = "It is a tread bound crawler used in harsh conditions. Supplied by The Kelland Mining Company; A subsidiary of Nanotrasen."
	icon_state = "miningcrawler2"

/obj/structure/prop/urban/vehicles/large/colonycrawlers/mining/mining2
	desc = "It is a tread bound crawler used in harsh conditions. Supplied by The Kelland Mining Company; A subsidiary of Nanotrasen."
	icon_state = "miningcrawler3"

/obj/structure/prop/urban/vehicles/large/colonycrawlers/mining/mining3
	desc = "It is a tread bound crawler used in harsh conditions. Supplied by The Kelland Mining Company; A subsidiary of Nanotrasen."
	icon_state = "miningcrawler4"

/obj/structure/prop/urban/vehicles/large/suv/misc
	name = "\improper Nanotrasen rapid response vehicle"
	desc = "Seems to be broken down."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/vehiclesexpanded.dmi'
	icon_state = "WYSUV1"
	bound_height = 32
	bound_width = 64

/obj/structure/prop/urban/vehicles/large/suv/misc/whitevan
	name = "maintenance SUV"
	desc = "Seems to be broken down."
	icon_state = "whitevan"

/obj/structure/prop/urban/vehicles/large/suv/misc/maintenance
	name = "maintenance SUV"
	desc = "Seems to be broken down."
	icon_state = "maintenaceSUV"

/obj/structure/prop/urban/vehicles/large/van
	name = "van"
	desc = "Seems to be broken down."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/vehiclesexpanded.dmi'
	icon_state = "greyvan"
	bound_height = 32
	bound_width = 64

/obj/structure/prop/urban/vehicles/large/van/vandamaged
	name = "van"
	desc = "A shell of a vehicle, broken down beyond repair."
	icon_state = "greyvan_damaged"

/obj/structure/prop/urban/vehicles/large/van/vanpizza
	name = "pizza delivery van"
	icon_state = "pizzavan"

/obj/structure/prop/urban/vehicles/large/van/vanmining
	name = "Kelland Mining van"
	icon_state = "kellandminingvan"

/obj/structure/prop/urban/vehicles/large/van/hyperdynevan
	name = "Hyperdyne van"
	icon_state = "hyperdynevan"

/obj/structure/prop/urban/vehicles/large/crashedcarsleft
	name = "car pileup"
	desc = "Burned out wrecked vehicles block your path."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/crashedcars.dmi'
	icon_state = "crashedcarsleft"
	bound_height = 64
	bound_width = 64
	layer = 5

/obj/structure/prop/urban/vehicles/large/crashedcarsright
	name = "car pileup"
	desc = "Burned out wrecked vehicles block your path."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/crashedcars.dmi'
	icon_state = "crashedcarsright"
	bound_height = 64
	bound_width = 64
	layer = 5

/obj/structure/lattice/autosmooth
	icon = 'temp/LV759/icons/obj/smooth_objects/lattice.dmi'
	icon_state = "lattice-0"
	layer = ABOVE_ALL_MOB_LAYER
	plane = GAME_PLANE
	base_icon_state = "lattice"
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_LATTICE_ABOVE)
	canSmoothWith = list(SMOOTH_GROUP_LATTICE_ABOVE)
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/structure/platform/urban
	max_integrity = 120

/obj/structure/platform_decoration/urban/engineer_corner
	name = "raised metal corner"
	desc = "The corner of what appears to be raised piece of metal, often used to imply the illusion of elevation in non-Euclidean 2d spaces. But you don't know that, you're just a spaceman with a rifle."
	icon_state = "engineer_platform_deco"

/obj/structure/platform_decoration/urban/rockdark
	name = "raised rock corner"
	desc = "A collection of stones and rocks that cap the edge of some conveniently 1-meter-long lengths of perfectly climbable chest high walls."
	icon_state = "kutjevo_rock_decodark"

/obj/structure/platform_decoration/urban/metalplatformdeco2
	name = "raised metal corner"
	desc = "A raised level of metal, often used to elevate areas above others. This is the corner."
	icon_state = "strata_metalplatform_deco2"

/obj/structure/platform/urban/metalplatform2
	name = "raised metal edge"
	desc = "A raised level of metal, often used to elevate areas above others. You could probably climb it."
	icon_state = "strata_metalplatform2"

/obj/structure/platform_decoration/urban/metalplatformdeco3
	name = "raised metal corner"
	desc = "A raised level of metal, often used to elevate areas above others. This is the corner."
	icon_state = "strata_metalplatform_deco3"

/obj/structure/platform/urban/metalplatform4
	icon_state = "hybrisaplatform"
	name = "raised metal platform"
	desc = "A raised level of metal, often used to elevate areas above others. You could probably climb it."

/obj/structure/platform_decoration/urban/metalplatformdeco4
	icon_state = "hybrisaplatform_deco"
	name = "raised metal corner"
	desc = "A raised level of metal, often used to elevate areas above others. You could probably climb it."

/obj/structure/platform/mineral
	icon_state = "stone"

/obj/structure/platform_decoration/mineral
	icon_state = "stone_deco"

/obj/machinery/prop/structurelattice
	name = "structural lattice"
	desc = "Like rebar, but in space."
	icon = 'temp/LV759/icons/obj/structures/prop/mainship.dmi'
	icon_state = "structure_lattice"
	coverage = 50
	max_integrity = 750
	resistance_flags = XENO_DAMAGEABLE

/obj/machinery/prop/fuel_enhancer
	name = "fuel enhancer"
	desc = "A fuel enhancement system for dropships. It improves the thrust produced by the fuel combustion for faster travels. Fits inside the engine attach points. You need a powerloader to lift it."
	icon = 'temp/LV759/icons/obj/structures/prop/mainship.dmi'
	icon_state = "fuel_enhancer"
	coverage = 25
	max_integrity = 350
	resistance_flags = XENO_DAMAGEABLE

/obj/structure/prop/mainship/mission_planning_system/white
	icon_state = "mps_w"

/obj/structure/prop/mainship/sensor_computer1/white
	icon_state = "sensor_comp_w"

/obj/structure/prop/mainship/sensor_computer1/black
	icon_state = "blacksensor_comp_b1"

/obj/structure/prop/mainship/sensor_computer2/white
	icon_state = "sensor_comp_w2"

/obj/structure/prop/mainship/sensor_computer2/black
	icon_state = "blacksensor_comp_b2"

/obj/structure/prop/mainship/sensor_computer3/white
	icon_state = "sensor_comp_w3"

/obj/structure/prop/mainship/sensor_computer3/black
	icon_state = "blacksensor_comp_b3"

/obj/item/prop/paint
	name = "paint bucket"
	desc = "It's a paint bucket."
	icon_state = "paint_empty"
	icon = 'temp/LV759/icons/obj/items/items.dmi'

/obj/item/prop/paint/blue
	icon_state = "paint_blue"

/obj/item/prop/paint/violet
	icon_state = "paint_violet"

/obj/structure/reagent_dispensers/fueltank/spacefuel
	name = "spacecraft fuel-mix tank"
	desc = "A fuel tank mix with fuel designed for various spacecraft, very combustible.";
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanrandomprops.dmi';

/obj/structure/reagent_dispensers/water_cooler/nondense
	density = FALSE

/obj/structure/rock/dark
	name = "boulder"
	desc = "A large rock. It's not cooking anything."

/obj/structure/rock/dark/large
	icon = 'temp/LV759/icons/obj/structures/boulder_largedark.dmi'
	icon_state = "boulder_largedark1"
	bound_height = 64
	bound_width = 64

/obj/structure/rock/dark/large/two
	icon_state = "boulder_largedark2"

/obj/structure/rock/dark/large/three
	icon_state = "boulder_largedark3"

/obj/structure/rock/dark/wide
	icon = 'temp/LV759/icons/obj/structures/boulder_widedark.dmi'
	icon_state = "boulderwidedark"
	bound_height = 32
	bound_width = 64

/obj/structure/rock/dark/wide/two
	icon_state = "boulderwidedark2"

/obj/structure/rock/dark/small
	icon_state = "bouldersmalldark1"
	icon = 'temp/LV759/icons/obj/structures/boulder_small.dmi'

/obj/structure/rock/dark/small/two
	icon_state = "bouldersmalldark2"

/obj/structure/rock/dark/small/three
	icon_state = "bouldersmalldark3"

/obj/structure/rock/dark/stalagmite
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanrandomprops.dmi'
	name = "stalagmite"
	icon_state = "stalagmite"
	desc = "A cave stalagmite."
	density = FALSE

/obj/structure/rock/dark/stalagmite/one
	icon_state = "stalagmite1"

/obj/structure/rock/dark/stalagmite/two
	icon_state = "stalagmite2"

/obj/structure/rock/dark/stalagmite/three
	icon_state = "stalagmite3"

/obj/structure/rock/dark/stalagmite/four
	icon_state = "stalagmite4"

/obj/structure/rock/dark/stalagmite/five
	icon_state = "stalagmite5"

/obj/structure/prop/urban/vehicles
	icon = 'temp/LV759/icons/obj/structures/prop/urban/vehiclesexpanded.dmi'
	icon_state = "SUV"
	max_integrity = 100
	resistance_flags = XENO_DAMAGEABLE
	density = TRUE
	///used to determine the probability that a car will detonate upon being destroyed

/obj/structure/prop/urban/vehicles/meridian
	name = "\improper Mono-Spectra"
	desc = "The 'Mono-Spectra', a mass-produced civilian vehicle for extraterrestrial markets, in and outside of Terra controlled space. Produced by 'Meridian' a car marque and associated operating division of the Nanotrasen Corporation."
	icon = 'temp/LV759/icons/obj/structures/prop/urban_vehicles/meridian_red.dmi'
	icon_state = "meridian_red"
	bound_height = 32
	bound_width = 64
	layer = ABOVE_MOB_LAYER
	resistance_flags = XENO_DAMAGEABLE
	coverage = 40
	base_icon_state = "meridian_red"
	max_integrity = 60
	allow_pass_flags = PASS_LOW_STRUCTURE|PASSABLE|PASS_WALKOVER
	soft_armor = list(MELEE = 10, BULLET = 75, LASER = 45, ENERGY = 45, BOMB = 20, BIO = 10, FIRE = 10, ACID = 10)

/obj/structure/prop/urban/vehicles/meridian/red
	icon = 'temp/LV759/icons/obj/structures/prop/urban_vehicles/meridian_red.dmi'
	icon_state = "meridian_red"
	base_icon_state = "meridian_red"

/obj/structure/prop/urban/vehicles/meridian/red/damagethree
	icon_state = "meridian_red_damage_3"
	max_integrity = 30

/obj/structure/prop/urban/vehicles/meridian/red/damagefour
	icon_state = "meridian_red_damage_4"
	max_integrity = 20

/obj/structure/prop/urban/vehicles/meridian/blue
	icon = 'temp/LV759/icons/obj/structures/prop/urban_vehicles/meridian_blue.dmi'
	icon_state = "meridian_blue"
	base_icon_state = "meridian_blue"

/obj/structure/prop/urban/vehicles/meridian/brown
	icon = 'temp/LV759/icons/obj/structures/prop/urban_vehicles/meridian_brown.dmi'
	icon_state = "meridian_brown"
	base_icon_state = "meridian_brown"

/obj/structure/prop/urban/vehicles/meridian/green
	icon = 'temp/LV759/icons/obj/structures/prop/urban_vehicles/meridian_green.dmi'
	icon_state = "meridian_green"
	base_icon_state = "meridian_green"

/obj/structure/prop/urban/vehicles/meridian/light_blue
	icon = 'temp/LV759/icons/obj/structures/prop/urban_vehicles/meridian_lightblue.dmi'
	icon_state = "meridian_lightblue"
	base_icon_state = "meridian_lightblue"

/obj/structure/prop/urban/vehicles/meridian/light_blue/damagethree
	icon_state = "meridian_lightblue_damage_3"
	max_integrity = 30

/obj/structure/prop/urban/vehicles/meridian/pink
	icon = 'temp/LV759/icons/obj/structures/prop/urban_vehicles/meridian_pink.dmi'
	icon_state = "meridian_pink"
	base_icon_state = "meridian_pink"

/obj/structure/prop/urban/vehicles/meridian/pink/damagethree
	icon_state = "meridian_pink_damage_3"
	max_integrity = 30

/obj/structure/prop/urban/vehicles/meridian/purple
	icon = 'temp/LV759/icons/obj/structures/prop/urban_vehicles/meridian_purple.dmi'
	icon_state = "meridian_purple"
	base_icon_state = "meridian_purple"

/obj/structure/prop/urban/vehicles/meridian/turquoise
	icon = 'temp/LV759/icons/obj/structures/prop/urban_vehicles/meridian_turquoise.dmi'
	icon_state = "meridian_turquoise"
	base_icon_state = "meridian_turquoise"

/obj/structure/prop/urban/vehicles/meridian/turquoise/damagethree
	icon_state = "meridian_turquoise_damage_3"
	max_integrity = 30

/obj/structure/prop/urban/vehicles/meridian/orange
	icon = 'temp/LV759/icons/obj/structures/prop/urban_vehicles/meridian_orange.dmi'
	icon_state = "meridian_orange"
	base_icon_state = "meridian_orange"

/obj/structure/prop/urban/vehicles/meridian/generic
	icon = 'temp/LV759/icons/obj/structures/prop/urban_vehicles/meridian_wy.dmi'
	icon_state = "meridian_wy"
	base_icon_state = "meridian_wy"

/obj/structure/prop/urban/vehicles/meridian/generic/damagethree
	icon_state = "meridian_wy_damage_3"
	max_integrity = 30

/obj/structure/prop/urban/vehicles/meridian/taxi
	icon = 'temp/LV759/icons/obj/structures/prop/urban_vehicles/meridian_taxi.dmi'
	icon_state = "meridian_taxi"
	base_icon_state = "meridian_taxi"

/obj/structure/prop/urban/vehicles/meridian/taxi/damagetwo
	icon_state = "meridian_taxi_damage_2"
	max_integrity = 40

/obj/structure/prop/urban/vehicles/meridian/marshalls
	name = "colonial marshalls rapid response SUV"
	desc = "Seems to be broken down."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/vehiclesexpanded.dmi'
	icon_state = "marshalls2"

/obj/structure/prop/urban/vehicles/meridian/chassis
	name = "\improper Mono-Spectra Chassis"
	desc = "A Mono-Spectra chassis in the early stages of assembly."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/vehiclesexpanded.dmi'
	icon_state = "MeridianCar_shell"

/obj/structure/window/framed/urban
	name = "window"
	icon = 'temp/LV759/icons/obj/smooth_objects/urban_window.dmi'
	icon_state = "chigusa_wall-0"
	base_icon_state = "chigusa_wall"
	max_integrity = 100 //Was 600
	reinf = TRUE
	dir = 5
	window_frame = /obj/structure/window_frame/urban

/obj/structure/window/framed/urban/reinforced

/obj/structure/window/framed/urban/marshalls/cell

/obj/structure/window/framed/urban/colony/office

/obj/structure/window/framed/urban/colony/hospital

/obj/structure/window/framed/urban/colony/engineering/hull

/obj/structure/window_frame/urban
	icon = 'temp/LV759/icons/obj/smooth_objects/urban_window_frame.dmi'
	icon_state = "col_window_frame-0"
	base_icon_state = "col_window_frame"

/obj/structure/window_frame/urban/colony/engineering/reinforced

/obj/structure/closet/crate/trashcart/food
	desc = "A heavy, metal foodcart with wheels."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanrandomprops.dmi';
	icon_state = "foodcart2"
	icon_closed = "foodcart2"
	icon_opened = "foodcart2_open"
	name = "food cart"

/obj/structure/largecrate/random/mini
	name = "small crate"
	desc = "The large supply crate's cousin, 1st removed."
	icon_state = "mini_crate"
	density = FALSE

/obj/structure/largecrate/random/mini/chest
	desc = "A small plastic crate wrapped with securing elastic straps."
	icon_state = "mini_chest"
	name = "small chest"

/obj/structure/largecrate/random/mini/chest/b
	icon_state = "mini_chest_b"
	name = "small chest"

/obj/structure/largecrate/random/mini/chest/c
	icon_state = "mini_chest_c"
	name = "small chest"

/obj/structure/largecrate/random/mini/wooden
	desc = "A small wooden crate. Two supporting ribs cross this one's frame."
	icon_state = "mini_wooden"
	name = "wooden crate"

/obj/structure/largecrate/random/mini/small_case
	desc = "A small hard-shell case. What could be inside?"
	icon_state = "mini_case"
	name = "small case"

/obj/structure/largecrate/random/mini/small_case/b
	icon_state = "mini_case_b"
	name = "small case"

/obj/structure/largecrate/random/mini/small_case/c
	icon_state = "mini_case_c"
	name = "small case"

/obj/structure/largecrate/random/mini/ammo
	desc = "A small metal crate. Here, Freeman ammo!"
	name = "small ammocase"
	icon_state = "mini_ammo"
	stuff = list(
		/obj/item/ammo_magazine/pistol,
		/obj/item/ammo_magazine/revolver,
		/obj/item/ammo_magazine/rifle,
		/obj/item/ammo_magazine/rifle/extended,
		/obj/item/ammo_magazine/shotgun,
		/obj/item/ammo_magazine/shotgun/buckshot,
		/obj/item/ammo_magazine/shotgun/flechette,
	)

/obj/structure/largecrate/random/mini/med
	desc = "A small metal crate containing medical supplies."
	icon_state = "mini_medcase"
	name = "small medcase"
	num_things = 1 //funny lootbox tho.
	stuff = list(
		/obj/item/storage/pill_bottle/packet/tricordrazine,
		/obj/item/tool/crowbar/red,
		/obj/item/flashlight,
		/obj/item/storage/pill_bottle/packet/tramadol,
		/obj/item/stack/medical/splint,
		/obj/item/healthanalyzer,
		/obj/item/tool/extinguisher/mini,
		/obj/item/tool/shovel/etool,
		/obj/item/tool/screwdriver,
	)

/obj/structure/largecrate/random/barrel/black
	name = "black barrel"
	desc = "A black storage barrel"
	icon_state = "barrel_black"

/obj/structure/largecrate/random/barrel/brown
	name = "black brown"
	desc = "A black storage barrel"
	icon_state = "barrel_brown"

/obj/structure/bed/bedroll
	name = "unfolded bedroll"
	desc = "Perfect for those long missions, when there's nowhere else to sleep, you remembered to bring at least one thing of comfort."
	icon = 'temp/LV759/icons/obj/rollerbed.dmi'
	icon_state = "bedroll_o"
	foldabletype = /obj/item/roller/bedroll
	accepts_bodybag = FALSE
	buildstacktype = null

/obj/item/roller/bedroll
	name = "folded bedroll"
	desc = "A standard issue USCMC bedroll, They've been in service for as long as you can remember. The tag on it states to unfold it before rest, but who needs rules anyway, right?"
	icon = 'temp/LV759/icons/obj/rollerbed.dmi'
	icon_state = "bedroll"
	rollertype = /obj/structure/bed/bedroll

/obj/structure/bed/roller/hospital
	name = "hospital bed"
	icon = 'temp/LV759/icons/obj/rollerbed.dmi'
	icon_state = "bigrollerempty_up"
	foldabletype = null
	base_bed_icon = "bigrollerempty"

/obj/structure/bed/roller/hospital/bloody
	base_bed_icon = "bigrollerbloodempty"

/obj/structure/bed/roller/hospital_empty
	icon_state = "bigrollerempty2_down"
	foldabletype = null

/obj/structure/bed/roller/hospital_empty/bigrollerempty
	icon_state = "bigrollerempty_down"
	buckling_y = 2
	base_bed_icon = "bigrollerempty"

/obj/structure/bed/roller/hospital_empty/bigrollerempty2
	icon_state = "bigrollerempty2_down"
	buckling_y = 2
	base_bed_icon = "bigrollerempty2"

/obj/structure/bed/roller/hospital_empty/bigrollerempty3
	icon_state = "bigrollerempty3_down"
	buckling_y = 2
	base_bed_icon = "bigrollerempty3"

/obj/structure/bed/roller/hospital_empty/bigrollerbloodempty
	icon_state = "bigrollerbloodempty_down"
	buckling_y = 2
	base_bed_icon = "bigrollerbloodempty"

/obj/structure/bed/urban/hospital/hospitaldivider
	name = "hospital divider"
	desc = "A hospital divider for privacy."
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanrandomprops.dmi'
	icon_state = "hospitalcurtain"
	layer = ABOVE_MOB_LAYER
	anchored = TRUE

/obj/structure/bed/chair/sofa/corsat/verticaltop/white
	icon_state = "bench_vet3"

/obj/structure/bed/chair/sofa/corsat/verticalmiddle/white
	icon_state = "bench_vet2"

/obj/structure/bed/chair/sofa/corsat/verticalsouth/white
	icon_state = "bench_vet1"

/obj/machinery/door/airlock/mainship/engineering/glass/free_access
	req_one_access = null

/obj/machinery/door/airlock/urban
	openspeed = 4
	icon_state = "door_closed"
	req_access = null

/obj/machinery/door/airlock/urban/generic
	name = "\improper Airlock"
	icon = 'temp/LV759/icons/obj/doors/hybrisa/hybrisa_generic_glass.dmi'
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/urban/generic_solid
	name = "\improper Airlock"
	icon = 'temp/LV759/icons/obj/doors/hybrisa/hybrisa_generic.dmi'

/obj/machinery/door/airlock/urban/medical
	name = "\improper Airlock"
	icon = 'temp/LV759/icons/obj/doors/hybrisa/hybrisa_medidoor_glass.dmi'
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/urban/medical_solid
	name = "\improper Airlock"
	icon = 'temp/LV759/icons/obj/doors/hybrisa/hybrisa_medidoor.dmi'

/obj/machinery/door/airlock/urban/personal
	name = "\improper Airlock"
	icon = 'temp/LV759/icons/obj/doors/hybrisa/hybrisa_personaldoor_glass.dmi'
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/urban/personal_solid
	name = "\improper Airlock"
	icon = 'temp/LV759/icons/obj/doors/hybrisa/hybrisa_personaldoor.dmi'

/obj/machinery/door/airlock/urban/personal_solid_white
	name = "\improper Airlock"
	icon = 'temp/LV759/icons/obj/doors/hybrisa/hybrisa_personaldoor_white.dmi'

/obj/machinery/door/airlock/multi_tile/urban
	name = "\improper Airlock"
	icon_state = "door_closed"
	req_access = null

/obj/machinery/door/airlock/multi_tile/urban/generic
	icon = 'temp/LV759/icons/obj/doors/hybrisa/hybrisa_2x1generic.dmi'
	opacity = FALSE
	req_one_access = list(ACCESS_CIVILIAN_PUBLIC)

/obj/machinery/door/airlock/multi_tile/urban/generic_solid
	icon = 'temp/LV759/icons/obj/doors/hybrisa/hybrisa_2x1generic_solid.dmi'
	req_one_access = list(ACCESS_CIVILIAN_PUBLIC)

/obj/machinery/door/airlock/multi_tile/urban/medical
	icon = 'temp/LV759/icons/obj/doors/hybrisa/hybrisa_2x1medidoor.dmi'
	opacity = FALSE
	req_one_access = list(ACCESS_CIVILIAN_RESEARCH, ACCESS_CIVILIAN_PUBLIC)

/obj/machinery/door/airlock/multi_tile/urban/medical_solid
	icon = 'temp/LV759/icons/obj/doors/hybrisa/hybrisa_2x1medidoor_solid.dmi'
	req_one_access = list(ACCESS_CIVILIAN_RESEARCH, ACCESS_CIVILIAN_PUBLIC)

/obj/machinery/door/airlock/multi_tile/urban/personal
	icon = 'temp/LV759/icons/obj/doors/hybrisa/hybrisa_2x1personaldoor_glass.dmi'
	opacity = FALSE
	req_one_access = list(ACCESS_CIVILIAN_RESEARCH)

/obj/machinery/door/airlock/multi_tile/urban/personal_white
	icon = 'temp/LV759/icons/obj/doors/hybrisa/hybrisa_2x1personaldoor_glass_white.dmi'
	opacity = FALSE
	req_one_access = list(ACCESS_CIVILIAN_RESEARCH)

/obj/machinery/door/airlock/multi_tile/urban/personal_solid_white
	icon = 'temp/LV759/icons/obj/doors/hybrisa/hybrisa_2x1personaldoor_white.dmi'
	req_one_access = list(ACCESS_CIVILIAN_RESEARCH)

/obj/machinery/door/poddoor/shutters/urban
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanshutters.dmi'
	icon_state = "almayer_pdoor"
	base_icon_state = "almayer_pdoor"
	desc = "It's a shutter. You can <B>open</b> it with a <B>crowbar</b>, or with <B>claws</b>"
	openspeed = 4
	///how long it takes xenos to open a shutter by hand
	var/lift_time = 10 SECONDS
	soft_armor = list(MELEE = 50, BULLET = 50, LASER = 50, ENERGY = 50, BOMB = 15, BIO = 50, FIRE = 50, ACID = 50)

/obj/machinery/door/poddoor/shutters/urban/open_shutters
	icon_state = "almayer_pdoor"
	base_icon_state = "almayer_pdoor"
	opacity = FALSE
	layer = ABOVE_WINDOW_LAYER
	max_integrity = 100
	lift_time = 5 SECONDS
	soft_armor = list(MELEE = 30, BULLET = 30, LASER = 30, ENERGY = 30, BOMB = 10, BIO = 30, FIRE = 20, ACID = 20)

/obj/machinery/door/poddoor/shutters/urban/open_shutters/opened
	icon_state = "almayer_pdoor0"
	density = FALSE
	opacity = FALSE
	layer = BLASTDOOR_LAYER

/obj/machinery/door/poddoor/shutters/urban/shutters
	icon_state = "shutter"
	layer = ABOVE_WINDOW_LAYER

/obj/machinery/door/poddoor/shutters/urban/shutters/opened
	icon_state = "shutter0"
	base_icon_state = "shutter"
	density = FALSE
	opacity = FALSE
	layer = BLASTDOOR_LAYER

/obj/machinery/door/poddoor/shutters/urban/white
	desc = "That looks like it doesn't open easily."
	icon_state = "w_almayer_pdoor"
	base_icon_state = "w_almayer_pdoor"

/obj/machinery/door/poddoor/shutters/urban/secure_red_door
	desc = "That looks like it doesn't open easily."
	icon_state = "pdoor"
	base_icon_state = "pdoor"

/obj/machinery/door/poddoor/shutters/urban/biohazard/white
	icon_state = "w_almayer_pdoor"
	icon = 'temp/LV759/icons/obj/structures/prop/urban/urbanshutters.dmi'
	base_icon_state = "w_almayer_pdoor"

/obj/machinery/door/poddoor/shutters/urban/security_lockdown
	icon = 'temp/LV759/icons/obj/doors/mainship/blastdoors_shutters.dmi'
	icon_state = "pdoor"
	base_icon_state = "pdoor"
	lift_time = 15 SECONDS

/obj/effect/urban
	icon = 'icons/effects/64x64hybrisa_decals.dmi'
	icon_state = "weylandyutanilogo1"
	layer = TURF_DECAL_LAYER
	plane = FLOOR_PLANE

/obj/effect/urban/decal/road
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "Z_W1"

/obj/effect/urban/decal/road/lines1
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "Z_W1"

/obj/effect/urban/decal/road/lines2
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "Z_N2"

/obj/effect/urban/decal/road/lines3
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "Z_S3"

/obj/effect/urban/decal/road/lines4
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "Z_E4"

/obj/effect/urban/decal/road/lines5
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "Z_M1"

/obj/effect/urban/decal/road/lines6
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "Z_M2"

/obj/effect/urban/decal/road/corner
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "Z_corner"

/obj/effect/urban/decal/road/roadmiddle
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "roadlinesmiddle"

/obj/effect/urban/decal/road/road_edge
	name = "road"
	icon_state = "thin_road_edge_decal1"

/obj/effect/urban/decal/road/road_edge/two
	name = "road"
	icon_state = "thin_road_edge_decal2"

/obj/effect/urban/decal/road/road_edge/three
	name = "road"
	icon_state = "thin_road_edge_decal3"

/obj/effect/urban/decal/road/road_edge/four
	name = "road"
	icon_state = "thin_road_edge_decal4"

/obj/effect/urban/decal/road/road_edge/five
	name = "road"
	icon_state = "thin_road_edge_decal5"

/obj/effect/urban/decal/road/road_edge/six
	name = "road"
	icon_state = "thin_road_edge_decal6"

/obj/effect/urban/decal/road/road_edge/seven
	name = "road"
	icon_state = "thin_road_edge_decal7"

/obj/effect/urban/decal/road/road_edge/eight
	name = "road"
	icon_state = "thin_road_edge_decal8"

/obj/effect/urban/decal/road/road_edge/nine
	name = "road"
	icon_state = "thin_road_edge_decal9"

/obj/effect/urban/decal/road/road_edge/ten
	name = "road"
	icon_state = "thin_road_edge_decal10"

/obj/effect/urban/decal/road/road_edge/eleven
	name = "road"
	icon_state = "thin_road_edge_decal11"

/obj/effect/urban/decal/road/road_edge/twelve
	name = "road"
	icon_state = "thin_road_edge_decal12"

/obj/effect/urban/decal/road/road_stop
	name = "road"
	icon_state = "thin_road_stop_decal"

/obj/effect/urban/decal/road/road_stop/one
	name = "road"
	icon_state = "thin_road_stop_decal1"

/obj/effect/urban/decal/road/road_stop/two
	name = "road"
	icon_state = "thin_road_stop_decal2"

/obj/effect/urban/decal/road/road_stop/three
	name = "road"
	icon_state = "thin_road_stop_decal3"

/obj/effect/urban/decal/road/road_stop/five
	name = "road"
	icon_state = "thin_stop_decal5"

/obj/effect/urban/decal/doubleroad
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "ZD_W1"

/obj/effect/urban/decal/doubleroad/lines1
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "ZD_W1"

/obj/effect/urban/decal/doubleroad/lines2
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "ZD_N2"

/obj/effect/urban/decal/doubleroad/lines3
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "ZD_S3"

/obj/effect/urban/decal/doubleroad/lines4
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "ZD_E4"

/obj/effect/urban/decal/gold
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "Z_S"

/obj/effect/urban/decal/gold/line1
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "Z_S"

/obj/effect/urban/decal/gold/line2
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "Z_E"

/obj/effect/urban/decal/gold/line3
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "Z_N"

/obj/effect/urban/decal/gold/line4
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "Z_W"

/obj/effect/urban/decal/warningstripes_angled
	name = "warning stripes"
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "warningstripes_angled"

/obj/effect/urban/decal/warningstripes_angled_corner
	name = "warning stripes"
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "warningstripes_angled_corner"

/obj/effect/urban/decal/grate
	name = "solid metal grate"
	desc = "A metal grate."
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "zhalfgrate1"

/obj/effect/urban/decal/checkpoint_decal
	icon = 'icons/effects/64x64hybrisa_decals.dmi'
	icon_state = "checkpoint_decal"

/obj/effect/urban/decal/workers_decal
	icon = 'icons/effects/64x64hybrisa_decals.dmi'
	icon_state = "workers_decal"

/obj/effect/urban/decal/dirt
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "dirt"

/obj/effect/urban/decal/dirt_2
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "dirt_2"

/obj/effect/urban/decal/bloodtrail
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "bloodtrail"

/obj/effect/urban/decal/tiretrack
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "tiremarks"

/obj/effect/urban/decal/trash //curse you zenith for never defining any of your 16 trash additions
	name = "garbage"
	desc = "Some trash plastered to the ground."
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "trash_1"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/urban/decal/trash/two
	icon_state = "trash_2"

/obj/effect/urban/decal/trash/three
	icon_state = "trash_3"

/obj/effect/urban/decal/trash/four
	icon_state = "trash_4"

/obj/effect/urban/decal/trash/five
	icon_state = "trash_5"

/obj/effect/urban/decal/trash/six
	icon_state = "trash_6"

/obj/effect/urban/decal/trash/seven
	icon_state = "trash_7"

/obj/effect/urban/decal/trash/eight
	icon_state = "trash_8"

/obj/effect/urban/decal/trash/nine
	icon_state = "trash_9"

/obj/effect/urban/decal/trash/ten
	icon_state = "trash_10"

/obj/effect/urban/decal/trash/eleven
	icon_state = "trash_11"

/obj/effect/urban/decal/trash/twelve
	icon_state = "trash_12"

/obj/effect/urban/decal/trash/thirteen
	icon_state = "trash_13"

/obj/effect/urban/decal/trash/fourteen
	icon_state = "trash_14"

/obj/effect/urban/decal/trash/fifteen
	icon_state = "trash_15"

/obj/effect/urban/decal/trash/sixteen
	icon_state = "trash_16"

/obj/effect/urban/decal/trash/seventeen
	icon_state = "trash_17"

/obj/effect/urban/decal/engineership_corners
	icon = 'temp/LV759/icons/turf/desertdam_map.dmi'
	icon_state = "engPlatform_corners"

/obj/effect/landmark/xeno_spawner_spawn
	parent_type = /obj/effect/landmark/xeno_silo_spawn
	name = "xeno spawner spawn landmark"
	icon = 'temp/LV759/icons/Xeno/3x3building.dmi'
	icon_state = "spawner"

/obj/effect/landmark/lv624

/obj/effect/landmark/lv624/fog_blocker
	parent_type = /obj/effect/landmark/fog_blocker
	name = "fog blocker"
	icon_state = "fog_spawn"

/obj/effect/landmark/lv624/fog_blocker/xeno_spawn
	parent_type = /obj/effect/landmark/fog_blocker/xeno_spawn
	name = "xeno spawn protection"

/obj/effect/spawner/random/misc/structure/large
	name = "base large structure spawner"
	icon_state = null

/obj/effect/spawner/random/misc/structure/large/car
	name = "random car spawner"
	icon_state = "carone"
	icon = 'temp/LV759/icons/effects/random/64x64.dmi'
	spawn_with_original_direction = TRUE
	spawn_loot_chance = 25
	loot = list(
		/obj/effect/spawner/random/misc/structure/large/car/red,
		/obj/effect/spawner/random/misc/structure/large/car/black,
		/obj/effect/spawner/random/misc/structure/large/car/purple,
		/obj/effect/spawner/random/misc/structure/large/car/pink,
		/obj/effect/spawner/random/misc/structure/large/car/blue,
		/obj/effect/spawner/random/misc/structure/large/car/taxi,
		/obj/effect/spawner/random/misc/structure/large/car/cop,
		/obj/effect/spawner/random/misc/structure/large/car/light_blue,
		/obj/effect/spawner/random/misc/structure/large/car/desat_blue,
		/obj/effect/spawner/random/misc/structure/large/car/turquoise,
		/obj/effect/spawner/random/misc/structure/large/car/brown,
		/obj/effect/spawner/random/misc/structure/large/car/generic,
		/obj/effect/spawner/random/misc/structure/large/car/orange,
		/obj/effect/spawner/random/misc/structure/large/car/green,
	)

/obj/effect/spawner/random/misc/structure/large/car/carfour
	name = "random car spawner damage four"
	icon_state = "carfour"
	loot = list(
		/obj/structure/prop/urban/vehicles/meridian/red/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/black/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/purple/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/pink/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/blue/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/taxi/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/cop/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/light_blue/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/desat_blue/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/turquoise/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/brown/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/generic/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/orange/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/green/damagefour,
	)

/obj/effect/spawner/random/misc/structure/large/car/black
	name = "random car spawner black"
	loot = list(
		/obj/structure/prop/urban/vehicles/meridian/black = 75,
		/obj/structure/prop/urban/vehicles/meridian/black/damageone = 35,
		/obj/structure/prop/urban/vehicles/meridian/black/damagetwo = 35,
		/obj/structure/prop/urban/vehicles/meridian/black/damagethree = 20,
		/obj/structure/prop/urban/vehicles/meridian/black/damagefour = 10,
		/obj/structure/prop/urban/vehicles/meridian/black/damagefive = 10,
	)

/obj/effect/spawner/random/misc/structure/large/car/cop
	name = "random car spawner cop"
	loot = list(
		/obj/structure/prop/urban/vehicles/meridian/cop = 75,
		/obj/structure/prop/urban/vehicles/meridian/cop/damageone = 35,
		/obj/structure/prop/urban/vehicles/meridian/cop/damagetwo = 35,
		/obj/structure/prop/urban/vehicles/meridian/cop/damagethree = 20,
		/obj/structure/prop/urban/vehicles/meridian/cop/damagefour = 10,
		/obj/structure/prop/urban/vehicles/meridian/cop/damagefive = 10,
	)

/obj/effect/spawner/random/misc/structure/large/car/desat_blue
	name = "random car spawner desat blue"
	loot = list(
		/obj/structure/prop/urban/vehicles/meridian/desat_blue = 75,
		/obj/structure/prop/urban/vehicles/meridian/desat_blue/damageone = 35,
		/obj/structure/prop/urban/vehicles/meridian/desat_blue/damagetwo = 35,
		/obj/structure/prop/urban/vehicles/meridian/desat_blue/damagethree = 20,
		/obj/structure/prop/urban/vehicles/meridian/desat_blue/damagefour = 10,
		/obj/structure/prop/urban/vehicles/meridian/desat_blue/damagefive = 10,
	)

/obj/effect/spawner/random/misc/structure/large/car/turquoise
	name = "random car spawner turquoise"
	loot = list(
		/obj/structure/prop/urban/vehicles/meridian/turquoise = 75,
		/obj/structure/prop/urban/vehicles/meridian/turquoise/damageone = 35,
		/obj/structure/prop/urban/vehicles/meridian/turquoise/damagetwo = 35,
		/obj/structure/prop/urban/vehicles/meridian/turquoise/damagethree = 20,
		/obj/structure/prop/urban/vehicles/meridian/turquoise/damagefour = 10,
		/obj/structure/prop/urban/vehicles/meridian/turquoise/damagefive = 10,
	)

/obj/effect/spawner/random/misc/structure/large/car/generic
	name = "random car spawner generic"
	loot = list(
		/obj/structure/prop/urban/vehicles/meridian/generic = 75,
		/obj/structure/prop/urban/vehicles/meridian/generic/damageone = 35,
		/obj/structure/prop/urban/vehicles/meridian/generic/damagetwo = 35,
		/obj/structure/prop/urban/vehicles/meridian/generic/damagethree = 20,
		/obj/structure/prop/urban/vehicles/meridian/generic/damagefour = 10,
		/obj/structure/prop/urban/vehicles/meridian/generic/damagefive = 10,
	)

/obj/effect/spawner/random/misc/structure/large/car/taxi
	name = "random car spawner taxi"
	loot = list(
		/obj/structure/prop/urban/vehicles/meridian/taxi = 75,
		/obj/structure/prop/urban/vehicles/meridian/taxi/damageone = 35,
		/obj/structure/prop/urban/vehicles/meridian/taxi/damagetwo = 35,
		/obj/structure/prop/urban/vehicles/meridian/taxi/damagethree = 20,
		/obj/structure/prop/urban/vehicles/meridian/taxi/damagefour = 10,
		/obj/structure/prop/urban/vehicles/meridian/taxi/damagefive = 10,
	)

/obj/effect/landmark/patrol_point
	name = "Patrol exit point"
	icon = 'temp/LV759/icons/effects/campaign_effects.dmi'
	faction = FACTION_TERRAGOV
	///ID to link with an associated start point
	var/id = null
	///minimap icon state
	var/minimap_icon = "patrol_1"
	///List of open turfs around the point to deploy onto
	var/list/deploy_turfs

/obj/effect/landmark/patrol_point/tgmc_11
	name = "TGMC exit point 1"
	id = "TGMC_1"
	icon_state = "blue_1"

/obj/effect/landmark/patrol_point/tgmc_21
	name = "TGMC exit point 2"
	id = "TGMC_2"
	icon_state = "blue_2"
	minimap_icon = "patrol_2"

/obj/effect/landmark/patrol_point/som
	faction = FACTION_SOM

/obj/effect/landmark/patrol_point/som/som_11
	name = "SOM exit point 1"
	icon_state = "red_1"
	id = "SOM_1"
	minimap_icon = "som_patrol_1"

/obj/effect/landmark/patrol_point/som/som_21
	name = "SOM exit point 2"
	id = "SOM_2"
	icon_state = "red_2"
	minimap_icon = "som_patrol_2"

/obj/effect/landmark/patrol_point/xeno
	faction = FACTION_XENO

/obj/effect/landmark/patrol_point/xeno/xeno_11
	name = "Xeno exit point 1"
	icon_state = "purple_1"
	id = "Xeno_1"
	minimap_icon = "xeno_patrol_1"

/obj/effect/landmark/patrol_point/xeno/xeno_21
	name = "Xeno exit point 2"
	icon_state = "purple_2"
	id = "Xeno_2"
	minimap_icon = "xeno_patrol_2"

/obj/effect/decal/cleanable/dirt/grime1
	icon_state = "grime1"

/obj/effect/decal/cleanable/dirt/grime2
	icon_state = "grime2"

/obj/effect/decal/cleanable/dirt/grime3
	icon_state = "grime3"

/obj/effect/decal/cleanable/dirt/grime4
	icon_state = "grime4"

/obj/item/light_bulb/tube/blue
	name = "blue light tube"
	icon_state = "ltube"
	base_icon_state = "ltube"

/obj/item/light_bulb/bulb/blue
	name = "blue light bulb"
	icon_state = "lbulb"
	base_icon_state = "lbulb"

/obj/structure/prop/urban/vehicles/meridian/black
	icon = 'temp/LV759/icons/obj/structures/prop/urban_vehicles/meridian_wy.dmi'
	icon_state = "meridian_wy"
	base_icon_state = "meridian_wy"

/obj/structure/prop/urban/vehicles/meridian/black/damageone
	icon_state = "meridian_wy_damage_3"

/obj/structure/prop/urban/vehicles/meridian/black/damagetwo
	icon_state = "meridian_wy_damage_3"

/obj/structure/prop/urban/vehicles/meridian/black/damagethree
	icon_state = "meridian_wy_damage_3"

/obj/structure/prop/urban/vehicles/meridian/black/damagefour
	icon_state = "meridian_wy_damage_3"

/obj/structure/prop/urban/vehicles/meridian/black/damagefive
	icon_state = "meridian_wy_damage_3"

/obj/structure/prop/urban/vehicles/meridian/cop
	icon = 'temp/LV759/icons/obj/structures/prop/urban_vehicles/meridian_wy.dmi'
	icon_state = "meridian_wy"
	base_icon_state = "meridian_wy"

/obj/structure/prop/urban/vehicles/meridian/cop/damageone
	icon_state = "meridian_wy_damage_3"

/obj/structure/prop/urban/vehicles/meridian/cop/damagetwo
	icon_state = "meridian_wy_damage_3"

/obj/structure/prop/urban/vehicles/meridian/cop/damagethree
	icon_state = "meridian_wy_damage_3"

/obj/structure/prop/urban/vehicles/meridian/cop/damagefour
	icon_state = "meridian_wy_damage_3"

/obj/structure/prop/urban/vehicles/meridian/cop/damagefive
	icon_state = "meridian_wy_damage_3"

/obj/structure/prop/urban/vehicles/meridian/desat_blue
	icon = 'temp/LV759/icons/obj/structures/prop/urban_vehicles/meridian_blue.dmi'
	icon_state = "meridian_blue"
	base_icon_state = "meridian_blue"

/obj/structure/prop/urban/vehicles/meridian/desat_blue/damageone
	icon_state = "meridian_blue_damage_3"

/obj/structure/prop/urban/vehicles/meridian/desat_blue/damagetwo
	icon_state = "meridian_blue_damage_3"

/obj/structure/prop/urban/vehicles/meridian/desat_blue/damagethree
	icon_state = "meridian_blue_damage_3"

/obj/structure/prop/urban/vehicles/meridian/desat_blue/damagefour
	icon_state = "meridian_blue_damage_3"

/obj/structure/prop/urban/vehicles/meridian/desat_blue/damagefive
	icon_state = "meridian_blue_damage_3"

/obj/effect/spawner/random/misc/structure/large/car/red
	name = "random red car spawner"
	loot = list(/obj/structure/prop/urban/vehicles/meridian/red)

/obj/effect/spawner/random/misc/structure/large/car/black
	name = "random black car spawner"
	loot = list(/obj/structure/prop/urban/vehicles/meridian/generic)

/obj/effect/spawner/random/misc/structure/large/car/purple
	name = "random purple car spawner"
	loot = list(/obj/structure/prop/urban/vehicles/meridian/purple)

/obj/effect/spawner/random/misc/structure/large/car/pink
	name = "random pink car spawner"
	loot = list(/obj/structure/prop/urban/vehicles/meridian/pink)

/obj/effect/spawner/random/misc/structure/large/car/blue
	name = "random blue car spawner"
	loot = list(/obj/structure/prop/urban/vehicles/meridian/blue)

/obj/effect/spawner/random/misc/structure/large/car/taxi
	name = "random taxi car spawner"
	loot = list(/obj/structure/prop/urban/vehicles/meridian/taxi)

/obj/effect/spawner/random/misc/structure/large/car/cop
	name = "random cop car spawner"
	loot = list(/obj/structure/prop/urban/vehicles/meridian/generic)

/obj/effect/spawner/random/misc/structure/large/car/light_blue
	name = "random light blue car spawner"
	loot = list(/obj/structure/prop/urban/vehicles/meridian/light_blue)

/obj/effect/spawner/random/misc/structure/large/car/desat_blue
	name = "random desat blue car spawner"
	loot = list(/obj/structure/prop/urban/vehicles/meridian/desat_blue)

/obj/effect/spawner/random/misc/structure/large/car/turquoise
	name = "random turquoise car spawner"
	loot = list(/obj/structure/prop/urban/vehicles/meridian/turquoise)

/obj/effect/spawner/random/misc/structure/large/car/brown
	name = "random brown car spawner"
	loot = list(/obj/structure/prop/urban/vehicles/meridian/brown)

/obj/effect/spawner/random/misc/structure/large/car/generic
	name = "random generic car spawner"
	loot = list(/obj/structure/prop/urban/vehicles/meridian/generic)

/obj/effect/spawner/random/misc/structure/large/car/orange
	name = "random orange car spawner"
	loot = list(/obj/structure/prop/urban/vehicles/meridian/orange)

/obj/effect/spawner/random/misc/structure/large/car/green
	name = "random green car spawner"
	loot = list(/obj/structure/prop/urban/vehicles/meridian/green)


/obj/structure/prop/urban/vehicles/meridian/red/damageone
	icon_state = "meridian_red_damage_1"

/obj/structure/prop/urban/vehicles/meridian/red/damagetwo
	icon_state = "meridian_red_damage_2"

/obj/structure/prop/urban/vehicles/meridian/red/damagethree
	icon_state = "meridian_red_damage_3"

/obj/structure/prop/urban/vehicles/meridian/red/damagefour
	icon_state = "meridian_red_damage_4"

/obj/structure/prop/urban/vehicles/meridian/red/damagefive
	icon_state = "meridian_red_damage_5"

/obj/structure/prop/urban/vehicles/meridian/black/damageone
	icon_state = "meridian_black_damage_1"

/obj/structure/prop/urban/vehicles/meridian/black/damagetwo
	icon_state = "meridian_black_damage_2"

/obj/structure/prop/urban/vehicles/meridian/black/damagethree
	icon_state = "meridian_black_damage_3"

/obj/structure/prop/urban/vehicles/meridian/black/damagefour
	icon_state = "meridian_black_damage_4"

/obj/structure/prop/urban/vehicles/meridian/black/damagefive
	icon_state = "meridian_black_damage_5"

/obj/structure/prop/urban/vehicles/meridian/purple/damageone
	icon_state = "meridian_purple_damage_1"

/obj/structure/prop/urban/vehicles/meridian/purple/damagetwo
	icon_state = "meridian_purple_damage_2"

/obj/structure/prop/urban/vehicles/meridian/purple/damagethree
	icon_state = "meridian_purple_damage_3"

/obj/structure/prop/urban/vehicles/meridian/purple/damagefour
	icon_state = "meridian_purple_damage_4"

/obj/structure/prop/urban/vehicles/meridian/purple/damagefive
	icon_state = "meridian_purple_damage_5"

/obj/structure/prop/urban/vehicles/meridian/pink/damageone
	icon_state = "meridian_pink_damage_1"

/obj/structure/prop/urban/vehicles/meridian/pink/damagetwo
	icon_state = "meridian_pink_damage_2"

/obj/structure/prop/urban/vehicles/meridian/pink/damagethree
	icon_state = "meridian_pink_damage_3"

/obj/structure/prop/urban/vehicles/meridian/pink/damagefour
	icon_state = "meridian_pink_damage_4"

/obj/structure/prop/urban/vehicles/meridian/pink/damagefive
	icon_state = "meridian_pink_damage_5"

/obj/structure/prop/urban/vehicles/meridian/blue/damageone
	icon_state = "meridian_blue_damage_1"

/obj/structure/prop/urban/vehicles/meridian/blue/damagetwo
	icon_state = "meridian_blue_damage_2"

/obj/structure/prop/urban/vehicles/meridian/blue/damagethree
	icon_state = "meridian_blue_damage_3"

/obj/structure/prop/urban/vehicles/meridian/blue/damagefour
	icon_state = "meridian_blue_damage_4"

/obj/structure/prop/urban/vehicles/meridian/blue/damagefive
	icon_state = "meridian_blue_damage_5"

/obj/structure/prop/urban/vehicles/meridian/taxi/damageone
	icon_state = "meridian_taxi_damage_1"

/obj/structure/prop/urban/vehicles/meridian/taxi/damagetwo
	icon_state = "meridian_taxi_damage_2"

/obj/structure/prop/urban/vehicles/meridian/taxi/damagethree
	icon_state = "meridian_taxi_damage_3"

/obj/structure/prop/urban/vehicles/meridian/taxi/damagefour
	icon_state = "meridian_taxi_damage_4"

/obj/structure/prop/urban/vehicles/meridian/taxi/damagefive
	icon_state = "meridian_taxi_damage_5"

/obj/structure/prop/urban/vehicles/meridian/cop/damageone
	icon_state = "meridian_cop_damage_1"

/obj/structure/prop/urban/vehicles/meridian/cop/damagetwo
	icon_state = "meridian_cop_damage_2"

/obj/structure/prop/urban/vehicles/meridian/cop/damagethree
	icon_state = "meridian_cop_damage_3"

/obj/structure/prop/urban/vehicles/meridian/cop/damagefour
	icon_state = "meridian_cop_damage_4"

/obj/structure/prop/urban/vehicles/meridian/cop/damagefive
	icon_state = "meridian_cop_damage_5"

/obj/structure/prop/urban/vehicles/meridian/light_blue/damageone
	icon_state = "meridian_lightblue_damage_1"

/obj/structure/prop/urban/vehicles/meridian/light_blue/damagetwo
	icon_state = "meridian_lightblue_damage_2"

/obj/structure/prop/urban/vehicles/meridian/light_blue/damagethree
	icon_state = "meridian_lightblue_damage_3"

/obj/structure/prop/urban/vehicles/meridian/light_blue/damagefour
	icon_state = "meridian_lightblue_damage_4"

/obj/structure/prop/urban/vehicles/meridian/light_blue/damagefive
	icon_state = "meridian_lightblue_damage_5"

/obj/structure/prop/urban/vehicles/meridian/desat_blue/damageone
	icon_state = "meridian_desatblue_damage_1"

/obj/structure/prop/urban/vehicles/meridian/desat_blue/damagetwo
	icon_state = "meridian_desatblue_damage_2"

/obj/structure/prop/urban/vehicles/meridian/desat_blue/damagethree
	icon_state = "meridian_desatblue_damage_3"

/obj/structure/prop/urban/vehicles/meridian/desat_blue/damagefour
	icon_state = "meridian_desatblue_damage_4"

/obj/structure/prop/urban/vehicles/meridian/desat_blue/damagefive
	icon_state = "meridian_desatblue_damage_5"

/obj/structure/prop/urban/vehicles/meridian/turquoise/damageone
	icon_state = "meridian_turquoise_damage_1"

/obj/structure/prop/urban/vehicles/meridian/turquoise/damagetwo
	icon_state = "meridian_turquoise_damage_2"

/obj/structure/prop/urban/vehicles/meridian/turquoise/damagethree
	icon_state = "meridian_turquoise_damage_3"

/obj/structure/prop/urban/vehicles/meridian/turquoise/damagefour
	icon_state = "meridian_turquoise_damage_4"

/obj/structure/prop/urban/vehicles/meridian/turquoise/damagefive
	icon_state = "meridian_turquoise_damage_5"

/obj/structure/prop/urban/vehicles/meridian/brown/damageone
	icon_state = "meridian_brown_damage_1"

/obj/structure/prop/urban/vehicles/meridian/brown/damagetwo
	icon_state = "meridian_brown_damage_2"

/obj/structure/prop/urban/vehicles/meridian/brown/damagethree
	icon_state = "meridian_brown_damage_3"

/obj/structure/prop/urban/vehicles/meridian/brown/damagefour
	icon_state = "meridian_brown_damage_4"

/obj/structure/prop/urban/vehicles/meridian/brown/damagefive
	icon_state = "meridian_brown_damage_5"

/obj/structure/prop/urban/vehicles/meridian/generic/damageone
	icon_state = "meridian_wy_damage_1"

/obj/structure/prop/urban/vehicles/meridian/generic/damagetwo
	icon_state = "meridian_wy_damage_2"

/obj/structure/prop/urban/vehicles/meridian/generic/damagethree
	icon_state = "meridian_wy_damage_3"

/obj/structure/prop/urban/vehicles/meridian/generic/damagefour
	icon_state = "meridian_wy_damage_4"

/obj/structure/prop/urban/vehicles/meridian/generic/damagefive
	icon_state = "meridian_wy_damage_5"

/obj/structure/prop/urban/vehicles/meridian/orange/damageone
	icon_state = "meridian_orange_damage_1"

/obj/structure/prop/urban/vehicles/meridian/orange/damagetwo
	icon_state = "meridian_orange_damage_2"

/obj/structure/prop/urban/vehicles/meridian/orange/damagethree
	icon_state = "meridian_orange_damage_3"

/obj/structure/prop/urban/vehicles/meridian/orange/damagefour
	icon_state = "meridian_orange_damage_4"

/obj/structure/prop/urban/vehicles/meridian/orange/damagefive
	icon_state = "meridian_orange_damage_5"

/obj/structure/prop/urban/vehicles/meridian/green/damageone
	icon_state = "meridian_green_damage_1"

/obj/structure/prop/urban/vehicles/meridian/green/damagetwo
	icon_state = "meridian_green_damage_2"

/obj/structure/prop/urban/vehicles/meridian/green/damagethree
	icon_state = "meridian_green_damage_3"

/obj/structure/prop/urban/vehicles/meridian/green/damagefour
	icon_state = "meridian_green_damage_4"

/obj/structure/prop/urban/vehicles/meridian/green/damagefive


/obj/structure/platform_decoration/shiva
	name = "raised ice colony platform corner"
	icon = 'icons/obj/structures/platforms.dmi'
	icon_state = "shiva_deco"

/obj/structure/window/framed/urban/spaceport
	name = "spaceport window"

/obj/item/storage/belt/marine/t12
	name = "T-12 ammunition belt"

// BEGIN MAP VISUAL REPAIRS
/turf/open/floor/urban_plating
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "urban_plating"

/turf/open/floor/iron/bluespace
	icon = 'temp/LV759/tgstation/icons/turf/floors.dmi'
	icon_state = "bluespace"

/turf/open/floor/iron/recharge_floor
	icon = 'temp/LV759/tgstation/icons/turf/floors.dmi'
	icon_state = "recharge_floor"

/turf/open/floor/iron/showroomfloor
	icon = 'temp/LV759/tgstation/icons/turf/floors.dmi'
	icon_state = "showroomfloor"

/turf/open/floor/iron/stairs
	icon = 'temp/LV759/tgstation/icons/turf/floors.dmi'
	icon_state = "stairs"

/turf/open/floor/iron/terracotta
	icon = 'temp/LV759/tgstation/icons/turf/floors.dmi'
	icon_state = "terracotta"

/turf/open/floor/iron/vaporwave
	icon = 'temp/LV759/tgstation/icons/turf/floors.dmi'
	icon_state = "pinkblack"

/turf/open/floor/marked
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "marked"

/turf/open/floor/multi_tiles
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "multi_tiles"

/turf/open/floor/officesquares
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "officesquares"

/turf/open/floor/officetiles
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "officetiles"

/turf/open/floor/orange_cover
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "orange_cover"

/turf/open/floor/orange_edge
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "orange_edge"

/turf/open/floor/orange_icorner
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "orange_icorner"

/turf/open/floor/plate
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "plate"

/turf/open/floor/redfour
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "red4"

/turf/open/floor/redone
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "red1"

/turf/open/floor/redthree
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "red3"

/turf/open/floor/spiralblueoffice
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "spiralblueoffice"

/turf/open/floor/spiralplate
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "spiralplate"

/turf/open/floor/squares
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "squares"

/turf/open/floor/yellowthree
	icon = 'temp/LV759/icons/turf/floors.dmi'
	icon_state = "yellow3"

/obj/item/trash/crushed_bottle
	icon = 'temp/LV759/icons/obj/items/trash.dmi'
	icon_state = "blank_can_crushed"

/obj/item/trash/crushed_cup
	icon = 'temp/LV759/icons/obj/items/trash.dmi'
	icon_state = "crushed_solocup"

/obj/item/trash/crushed_wbottle
	icon = 'temp/LV759/icons/obj/items/trash.dmi'
	icon_state = "waterbottle_crushed"

/obj/item/trash/cuppa_joes
	icon = 'temp/LV759/icons/obj/items/trash.dmi'
	icon_state = "coffeecuppajoenolid"

/obj/item/trash/cuppa_joes_static
	icon = 'temp/LV759/icons/obj/items/trash.dmi'
	icon_state = "coffeecuppajoenolid"

/turf/closed/wall/urban/colony
	icon = 'temp/LV759/icons/turf/walls/hybrisa_colony_walls.dmi'
	icon_state = "hybrisa_colony_walls-0"
	base_icon_state = "hybrisa_colony_walls"
	smoothing_flags = SMOOTH_BITMASK

/turf/closed/wall/urban/colony/engineering
	icon = 'temp/LV759/icons/turf/walls/hybrisa_colony_walls.dmi'
	icon_state = "hybrisa_colony_walls-0"
	base_icon_state = "hybrisa_colony_walls"
	smoothing_flags = SMOOTH_BITMASK

/obj/machinery/space_heater/radiator
	icon = 'temp/LV759/icons/obj/machines/atmos.dmi'
	icon_state = "radiator"

/obj/machinery/space_heater/radiator/red
	icon = 'temp/LV759/icons/obj/machines/atmos.dmi'
	icon_state = "radiator-r"

/obj/structure/barricade/handrail/urban/handrail
	icon = 'temp/LV759/icons/obj/structures/handrail.dmi'
	icon_state = "handrail_hybrisa"
	barricade_type = "handrail_hybrisa"

/obj/structure/barricade/handrail/urban/road
	icon = 'temp/LV759/icons/obj/structures/handrail.dmi'
	icon_state = "plasticroadbarrierred"
	barricade_type = "plasticroadbarrierred"

/obj/structure/fence/dark
	icon = 'temp/LV759/icons/obj/smooth_objects/dark_fence.dmi'
	icon_state = "fence-icon"

/obj/item/trash/trashbag
	icon = 'temp/LV759/icons/obj/items/trash.dmi'
	icon_state = "ztrashbag"

/obj/structure/bed/roller/hospital_empty
	icon = 'temp/LV759/icons/obj/rollerbed.dmi'
	icon_state = "bigrollerempty2_down"
	base_bed_icon = "bigrollerempty2"

/obj/item/autopsy_scanner
	icon = 'temp/LV759/icons/obj/items/surgery_tools.dmi'
	icon_state = "autopsy_scanner"

/obj/machinery/space_heater/radiator/update_icon_state()
	. = ..()
	icon_state = initial(icon_state)
