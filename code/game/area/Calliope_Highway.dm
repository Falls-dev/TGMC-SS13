// Calliope Highway — area definitions (Kutjevo-style interior/exterior layout)

/area/calliope
	name = "Calliope Highway"
	icon = 'icons/turf/area_kutjevo.dmi'
	icon_state = "kutjevo"
	minimap_color = MINIMAP_AREA_COLONY
	temperature = 308.7

/area/shuttle/drop1/lz1/calliope
	name = "Calliope - Dropship Landing Zone"
	icon = 'icons/turf/area_kutjevo.dmi'
	icon_state = "shuttle"
	minimap_color = MINIMAP_AREA_LZ
	ceiling = CEILING_NONE

/area/calliope/exterior
	name = "Calliope - Exterior"
	ceiling = CEILING_NONE
	icon_state = "ext"
	always_unpowered = TRUE

/area/calliope/interior
	name = "Calliope - Interior"
	icon_state = "int"
	always_unpowered = FALSE
	min_ambience_cooldown = 1 SECONDS
	max_ambience_cooldown = 1 SECONDS
	ambience = list('sound/ambience/ambienthum.ogg' = 1)

/area/calliope/interior/oob
	name = "Calliope -  Out Of Bounds"
	icon_state = "oob"
	ceiling = CEILING_DEEP_UNDERGROUND
	always_unpowered = TRUE

// Exterior zones
/area/calliope/exterior/highway
	name = "Calliope - Highway"
	icon_state = "scrubland"
	ambience = list(
		'sound/effects/wind/wind_2_1.ogg' = 1,
		'sound/effects/wind/wind_2_2.ogg' = 1,
		'sound/effects/wind/wind_3_1.ogg' = 1,
		'sound/effects/wind/wind_4_1.ogg' = 1,
		'sound/effects/wind/wind_4_2.ogg' = 1,
		'sound/effects/wind/wind_5_1.ogg' = 1,
	)
	min_ambience_cooldown = 10 SECONDS
	max_ambience_cooldown = 12 SECONDS

/area/calliope/exterior/highway/north
	name = "Calliope - Highway North"
	icon_state = "scrubland"

/area/calliope/exterior/highway/central
	name = "Calliope - Highway Central"
	icon_state = "stone_fields"

/area/calliope/exterior/highway/south
	name = "Calliope - Highway South"
	icon_state = "scrubland"

/area/calliope/exterior/complex_perimeter
	name = "Calliope Complex - Exterior"
	icon_state = "complex_border"
	minimap_color = MINIMAP_AREA_COLONY

/area/calliope/exterior/runoff_river
	name = "Calliope - Runoff River"
	icon_state = "rf_river"
	minimap_color = MINIMAP_WATER

/area/calliope/exterior/caves
	name = "Calliope - Caves"
	ceiling = CEILING_DEEP_UNDERGROUND
	icon_state = "colony_caves_0"
	minimap_color = MINIMAP_AREA_CAVES
	ambience = list(
		'sound/ambience/ambicave.ogg',
		'sound/ambience/ambilava1.ogg',
		'sound/ambience/ambilava2.ogg',
		'sound/ambience/ambicave2.ogg',
		'sound/effects/rocksfalling1.ogg',
		'sound/effects/rocksfalling2.ogg',
	)

/area/calliope/exterior/caves/east
	name = "Calliope - East Colony Caves"
	icon_state = "colony_caves_1"

/area/calliope/exterior/caves/west
	name = "Calliope - West Colony Caves"
	icon_state = "colony_caves_3"

// Interior zones — bunker complex
/area/calliope/interior/cargo_storage
	name = "Calliope Complex - Cargo Storage"
	icon_state = "storage"
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY

/area/calliope/interior/abandoned_church
	name = "Calliope - Abandoned Church"
	icon_state = "construction_int"
	ceiling = CEILING_METAL

/area/calliope/interior/barracks
	name = "Calliope Complex - Barracks"
	icon_state = "Colony_int"
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_LZ

/area/calliope/interior/medbay
	name = "Calliope Complex - Medical Bay"
	icon_state = "med0"
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_MEDBAY

/area/calliope/interior/fuel_depot
	name = "Calliope Complex - Fuel Depot"
	icon_state = "power"
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_ENGI

/area/calliope/interior/hallway
	name = "Calliope Complex - Hallway"
	icon_state = "colony_int"
	ceiling = CEILING_METAL

/area/calliope/interior/cafeteria
	name = "Calliope Complex - Cafeteria"
	icon_state = "colony_int"
	ceiling = CEILING_METAL

/area/calliope/interior/research_lab
	name = "Calliope Complex - Research Laboratory"
	icon_state = "botany0"
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_RESEARCH

/area/calliope/interior/power_station
	name = "Calliope Complex - Power Station"
	icon_state = "power"
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_ENGI

/area/calliope/interior/comms_center
	name = "Calliope Complex - Communications Center"
	icon_state = "ass_line"
	ceiling = CEILING_METAL

/area/calliope/interior/complex_checkpoint
	name = "Calliope Complex - Security Checkpoint"
	icon_state = "Colony_int"
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_SEC

/area/calliope/interior/cargo
	name = "Calliope Complex - Cargo Bay"
	icon_state = "storage"
	ceiling = CEILING_METAL

/area/calliope/interior/ruins
	name = "Calliope - Ruins"
	icon_state = "construction_int"
	ceiling = CEILING_UNDERGROUND_METAL
	minimap_color = MINIMAP_AREA_CAVES

/area/calliope/interior/engineering
	name = "Calliope Complex - Engineering"
	icon_state = "power_2"
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_ENGI

/area/calliope/interior/holding
	name = "Calliope Complex - Holding Cell"
	icon_state = "med5"
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_SEC

/area/calliope/interior/armory
	name = "Calliope Complex - Armory"
	icon_state = "power_2"
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_SEC

/area/calliope/interior/closet
	name = "Calliope Complex - Maintenance Closet"
	icon_state = "storage"
	ceiling = CEILING_METAL

/area/calliope/interior/observation_deck
	name = "Calliope Complex - Observation Deck"
	icon_state = "rf_overlook"
	ceiling = CEILING_METAL

/area/calliope/interior/buildings
	name = "Calliope - Colony Buildings"
	icon_state = "colony_int"
	ceiling = CEILING_METAL

/area/calliope/interior/east_checkpoint
	name = "Calliope Complex - East Security Checkpoint"
	icon_state = "Colony_int"
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_SEC

/area/calliope/interior/west_checkpoint
	name = "Calliope Complex - West Security Checkpoint"
	icon_state = "Colony_int"
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_SEC
