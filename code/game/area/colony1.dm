/area/colony1
	parent_type = /area/mainship
	name = "Colony 1"
	outside = FALSE

/area/colony1/valley_wilderness
	parent_type = /area/ice_colony/exterior/surface/valley
	requires_power = FALSE
	name = "Wilderness Valley"
	minimap_color = MINIMAP_AREA_COLONY

/area/colony1/command/cic
	name = "Combat Information Center"
	icon_state = "cic"
	minimap_color = MINIMAP_AREA_COMMAND

/area/colony1/command/corporateliaison
	name = "Operations Officer Office"
	icon_state = "corporatespace"
	minimap_color = MINIMAP_AREA_COMMAND

/area/colony1/command/telecomms
	name = "Telecommunications"
	icon_state = "tcomms"
	minimap_color = MINIMAP_AREA_COMMAND

/area/colony1/engineering/ce_room
	name = "Chief Ship Engineer Office"
	icon_state = "ceroom"
	minimap_color = MINIMAP_AREA_ENGI

/area/colony1/engineering/engine_core
	name = "Engine Reactor Core Room"
	icon_state = "coreroom"
	minimap_color = MINIMAP_AREA_ENGI

/area/colony1/engineering/engineering_workshop
	name = "Engineering Workshop"
	icon_state = "workshop"
	minimap_color = MINIMAP_AREA_ENGI

/area/colony1/engineering/lower_engineering
	name = "Engineering Lower"
	icon_state = "lowerengineering"
	minimap_color = MINIMAP_AREA_ENGI

/area/colony1/engineering/upper_engine_monitoring
	name = "Engine Reactor Monitoring"
	icon_state = "uppermonitoring"
	minimap_color = MINIMAP_AREA_ENGI

/area/colony1/engineering/upper_engineering
	name = "Upper Engineering"
	icon_state = "upperengineering"
	minimap_color = MINIMAP_AREA_ENGI

/area/colony1/hallways/aft_hallway
	name = "Hallway Aft"
	icon_state = "aft"

/area/colony1/hallways/bathroom
	name = "Bathroom"
	icon_state = "port"

/area/colony1/hallways/hangar
	name = "Hangar"
	icon_state = "hangar"
	minimap_color = MINIMAP_AREA_LZ

/area/colony1/hallways/starboard_hallway
	name = "Hallway Starboard"
	icon_state = "starboard"

/area/colony1/hallways/stern_hallway
	name = "Hallway Stern"
	icon_state = "stern"

/area/colony1/living/bridgebunks
	name = "Staff Officer Bunks"
	icon_state = "livingspace"
	minimap_color = MINIMAP_AREA_COMMAND

/area/colony1/living/captain_mess
	name = "Captain's Mess"
	icon_state = "briefing"
	minimap_color = MINIMAP_AREA_COMMAND

/area/colony1/living/chapel
	name = "Chapel"
	icon_state = "officerrnr"
	minimap_color = MINIMAP_AREA_LIVING

/area/colony1/living/commandbunks
	name = "Captain's Bunk"
	icon_state = "livingspace"
	minimap_color = MINIMAP_AREA_COMMAND

/area/colony1/living/grunt_rnr
	name = "Lounge"
	icon_state = "gruntrnr"
	minimap_color = MINIMAP_AREA_LIVING

/area/colony1/living/officer_study
	name = "Officer's Study"
	icon_state = "officerstudy"
	minimap_color = MINIMAP_AREA_LIVING

/area/colony1/living/starboard_garden
	name = "Garden"
	icon_state = "starboardemb"
	minimap_color = MINIMAP_AREA_LIVING

/area/colony1/medical/medical_science
	name = "Medical Research laboratories"
	icon_state = "science"
	minimap_color = MINIMAP_AREA_MEDBAY

/area/colony1/shipboard/brig
	name = "Brig"
	icon_state = "brig"
	minimap_color = MINIMAP_AREA_SEC

/area/colony1/shipboard/brig_cells
	name = "Brig Cells"
	icon_state = "brigcells"
	minimap_color = MINIMAP_AREA_SEC

/area/colony1/hangar2
	name = "Hangar 2"
	icon_state = "hangar"
	minimap_color = MINIMAP_AREA_LZ

/area/colony1/dorm1
	name = "Dormitories 1"
	icon_state = "livingspace"

/area/colony1/dorm2
	name = "Dormitories 2"
	icon_state = "livingspace"

/area/colony1/fcroom
	name = "Field Commander's Office"
	icon_state = "hos_office"
	minimap_color = "#2d3fa2d0"

/area/colony1/hydro
	name = "Sulaco Hydroponics"
	icon_state = "garden"
	minimap_color = MINIMAP_AREA_LIVING

/area/colony1/annex/corporateliaison
	parent_type = /area/mainship/command/corporateliaison
	outside = FALSE

/area/colony1/annex/engine_core
	parent_type = /area/mainship/engineering/engine_core
	outside = FALSE

/area/colony1/annex/engineering_workshop
	parent_type = /area/mainship/engineering/engineering_workshop
	outside = FALSE

/area/colony1/annex/grunt_rnr
	parent_type = /area/mainship/living/grunt_rnr
	outside = FALSE

/area/colony1/annex/lower_medical
	parent_type = /area/mainship/medical/lower_medical
	outside = FALSE

/area/colony1/annex/sensors
	parent_type = /area/mainship/shipboard/sensors
	outside = FALSE

/area/colony1/annex/requisitions
	parent_type = /area/mainship/squads/req
	outside = FALSE
