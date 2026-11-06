// BoxStation 2.1.3 areas, adapted to TGMC using Delta Station.
/area/boxstation
	name = "BoxStation"
	icon = 'icons/turf/areas_station.dmi'
	icon_state = "station"
	minimap_color = MINIMAP_AREA_COLONY
	outside = FALSE
	ceiling = CEILING_METAL

/area/boxstation/ai_monitored/nuke_storage
	parent_type = /area/deltastation/ai_monitored
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Vault"

/area/boxstation/ai_monitored/security/armory
	parent_type = /area/deltastation/ai_monitored/security/armory
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_SEC
	name = "Armory"

/area/boxstation/ai_monitored/storage/eva
	parent_type = /area/deltastation/ai_monitored
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "EVA Storage"

/area/boxstation/assembly/chargebay
	parent_type = /area/deltastation/science/robotics/mechbay
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_RESEARCH
	name = "Mech Bay"

/area/boxstation/assembly/robotics
	parent_type = /area/deltastation/science/robotics/lab
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_RESEARCH
	name = "Robotics Lab"

/area/boxstation/atmos
	parent_type = /area/deltastation/engineering/atmos
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_ENGI
	name = "Space"

/area/boxstation/bridge
	parent_type = /area/deltastation/command/bridge
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COMMAND
	name = "Bridge"

/area/boxstation/bridge/meeting_room
	parent_type = /area/deltastation/command/meeting_room
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COMMAND
	name = "Heads of Staff Meeting Room"

/area/boxstation/chapel/main
	parent_type = /area/deltastation/service/chapel
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_LIVING
	name = "Chapel"

/area/boxstation/chapel/office
	parent_type = /area/deltastation/service/chapel/office
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_LIVING
	name = "Chapel Office"

/area/boxstation/construction
	parent_type = /area/deltastation/construction
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_ENGI
	name = "Construction Area"

/area/boxstation/crew_quarters/bar
	parent_type = /area/deltastation/service/bar
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_LIVING
	name = "Bar"

/area/boxstation/crew_quarters/captain
	parent_type = /area/deltastation/command/heads_quarters/captain
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COMMAND
	name = "Captain's Office"

/area/boxstation/crew_quarters/courtroom
	parent_type = /area/deltastation/security/courtroom
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_SEC
	name = "Courtroom"

/area/boxstation/crew_quarters/fitness
	parent_type = /area/deltastation/commons/fitness
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_LIVING
	name = "Fitness Room"

/area/boxstation/crew_quarters/heads
	parent_type = /area/deltastation/command/heads_quarters
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COMMAND
	name = "Head of Personnel's Office"

/area/boxstation/crew_quarters/hor
	parent_type = /area/deltastation/command/heads_quarters/hop
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COMMAND
	name = "Research Director's Office"

/area/boxstation/crew_quarters/kitchen
	parent_type = /area/deltastation/service/kitchen
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_LIVING
	name = "Kitchen"

/area/boxstation/crew_quarters/locker
	parent_type = /area/deltastation/commons/locker
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_LIVING
	name = "Locker Room"

/area/boxstation/crew_quarters/locker/locker_toilet
	parent_type = /area/deltastation/commons/toilet/locker
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_LIVING
	name = "Locker Toilets"

/area/boxstation/crew_quarters/sleep
	parent_type = /area/deltastation/commons/dorms
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_LIVING
	name = "Dormitories"

/area/boxstation/crew_quarters/theatre
	parent_type = /area/deltastation/service/theater
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_LIVING
	name = "Theatre"

/area/boxstation/crew_quarters/toilet
	parent_type = /area/deltastation/commons/toilet
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_LIVING
	name = "Dormitory Toilets"

/area/boxstation/engine/break_room
	parent_type = /area/deltastation/engineering/break_room
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_ENGI
	name = "Engineering Foyer"

/area/boxstation/engine/chiefs_office
	parent_type = /area/deltastation/command/heads_quarters/ce
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COMMAND
	name = "Chief Engineer's office"

/area/boxstation/engine/engine_smes
	parent_type = /area/deltastation/engineering/engine_smes
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_ENGI
	name = "Engineering SMES"

/area/boxstation/engine/engineering
	parent_type = /area/deltastation/engineering/main
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_ENGI
	name = "Engineering"

/area/boxstation/engine/gravity_generator
	parent_type = /area/deltastation/engineering/gravity_generator
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_ENGI
	name = "Gravity Generator Room"

/area/boxstation/gateway
	parent_type = /area/deltastation
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Gateway"

/area/boxstation/hallway/primary/aft
	parent_type = /area/deltastation/hallway/primary/aft
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Aft Primary Hallway"

/area/boxstation/hallway/primary/central
	parent_type = /area/deltastation/hallway/primary/central
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Central Primary Hallway"

/area/boxstation/hallway/primary/fore
	parent_type = /area/deltastation/hallway/primary/fore
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Fore Primary Hallway"

/area/boxstation/hallway/primary/port
	parent_type = /area/deltastation/hallway/primary/port
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Port Primary Hallway"

/area/boxstation/hallway/primary/starboard
	parent_type = /area/deltastation/hallway/primary/starboard
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Starboard Primary Hallway"

/area/boxstation/hallway/secondary/construction
	parent_type = /area/deltastation/hallway/secondary/construction
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Construction Area"

/area/boxstation/hallway/secondary/entry
	parent_type = /area/deltastation/hallway/secondary/entry
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Arrival Shuttle Hallway"

/area/boxstation/hallway/secondary/exit
	parent_type = /area/deltastation/hallway/secondary/exit
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Escape Shuttle Hallway"

/area/boxstation/holodeck/rec_center
	parent_type = /area/deltastation
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Space"

/area/boxstation/hydroponics
	parent_type = /area/deltastation/service/hydroponics
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_LIVING
	name = "Hydroponics"

/area/boxstation/janitor
	parent_type = /area/deltastation/service/janitor
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_LIVING
	name = "Custodial Closet"

/area/boxstation/lawoffice
	parent_type = /area/deltastation/service/lawoffice
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_LIVING
	name = "Law Office"

/area/boxstation/library
	parent_type = /area/deltastation/service/library
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_LIVING
	name = "Space"

/area/boxstation/maintenance/aft
	parent_type = /area/deltastation/maintenance/aft
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Engineering Maintenance"

/area/boxstation/maintenance/asmaint
	parent_type = /area/deltastation/maintenance/starboard/aft
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Medbay Maintenance"

/area/boxstation/maintenance/asmaint2
	parent_type = /area/deltastation/maintenance/starboard/greater
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Science Maintenance"

/area/boxstation/maintenance/auxsolarport
	parent_type = /area/deltastation/maintenance/solars/port/aft
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_ENGI_CAVE
	name = "Fore Port Solar Maintenance"

/area/boxstation/maintenance/auxsolarstarboard
	parent_type = /area/deltastation/maintenance/solars/starboard/aft
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_ENGI_CAVE
	name = "Fore Starboard Solar Maintenance"

/area/boxstation/maintenance/disposal
	parent_type = /area/deltastation/maintenance/disposal
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Waste Disposal"

/area/boxstation/maintenance/electrical
	parent_type = /area/deltastation/maintenance/department/electrical
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_ENGI
	name = "Electrical Maintenance"

/area/boxstation/maintenance/fpmaint
	parent_type = /area/deltastation/maintenance/port/fore
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "EVA Maintenance"

/area/boxstation/maintenance/fpmaint2
	parent_type = /area/deltastation/maintenance/port/greater
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Arrivals North Maintenance"

/area/boxstation/maintenance/fsmaint
	parent_type = /area/deltastation/maintenance/starboard/fore
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Dormitory Maintenance"

/area/boxstation/maintenance/fsmaint2
	parent_type = /area/deltastation/maintenance/starboard/lesser
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Bar Maintenance"

/area/boxstation/maintenance/incinerator
	parent_type = /area/deltastation/maintenance/disposal/incinerator
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Incinerator"

/area/boxstation/maintenance/maintcentral
	parent_type = /area/deltastation/maintenance/central
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Bridge Maintenance"

/area/boxstation/maintenance/port
	parent_type = /area/deltastation/maintenance/port
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Locker Room Maintenance"

/area/boxstation/maintenance/portsolar
	parent_type = /area/deltastation/maintenance/solars/port/fore
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_ENGI_CAVE
	name = "Aft Port Solar Maintenance"

/area/boxstation/maintenance/starboardsolar
	parent_type = /area/deltastation/maintenance/solars/starboard/fore
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_ENGI_CAVE
	name = "Aft Starboard Solar Maintenance"

/area/boxstation/medical/chemistry
	parent_type = /area/deltastation/medical/chemistry
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_MEDBAY
	name = "Chemistry"

/area/boxstation/medical/cmo
	parent_type = /area/deltastation/command/heads_quarters/cmo
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COMMAND
	name = "Chief Medical Officer's office"

/area/boxstation/medical/genetics
	parent_type = /area/deltastation/science/genetics
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_RESEARCH
	name = "Genetics Lab"

/area/boxstation/medical/medbay
	parent_type = /area/deltastation/medical/medbay/central
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_MEDBAY
	name = "Medbay"

/area/boxstation/medical/morgue
	parent_type = /area/deltastation/medical/morgue
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_MEDBAY
	name = "Morgue"

/area/boxstation/medical/research
	parent_type = /area/deltastation/medical/medbay/central
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_MEDBAY
	name = "Medical Research"

/area/boxstation/medical/sleeper
	parent_type = /area/deltastation/medical/treatment_center
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_MEDBAY
	name = "Medbay Treatment Center"

/area/boxstation/medical/virology
	parent_type = /area/deltastation/medical/virology
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_MEDBAY
	name = "Virology"

/area/boxstation/quartermaster/miningdock
	parent_type = /area/deltastation/cargo/miningdock
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_CELL_HIGH
	name = "Mining Dock"

/area/boxstation/quartermaster/office
	parent_type = /area/deltastation/cargo/office
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_CELL_HIGH
	name = "Cargo Office"

/area/boxstation/quartermaster/qm
	parent_type = /area/deltastation/command/heads_quarters/qm
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COMMAND
	name = "Quartermaster's Office"

/area/boxstation/quartermaster/storage
	parent_type = /area/deltastation/cargo/storage
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_CELL_HIGH
	name = "Cargo Bay"

/area/boxstation/security/brig
	parent_type = /area/deltastation/security/brig
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_SEC
	name = "Brig"

/area/boxstation/security/checkpoint/engineering
	parent_type = /area/deltastation/security/checkpoint/engineering
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_SEC
	name = "Security Post - Engineering"

/area/boxstation/security/checkpoint/medical
	parent_type = /area/deltastation/security/checkpoint/medical
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_SEC
	name = "Security Post - Medbay"

/area/boxstation/security/checkpoint/science
	parent_type = /area/deltastation/security/checkpoint/science
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_SEC
	name = "Security Post - Science"

/area/boxstation/security/checkpoint/supply
	parent_type = /area/deltastation/security/checkpoint/supply
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_SEC
	name = "Security Post - Cargo Bay"

/area/boxstation/security/checkpoint2
	parent_type = /area/deltastation/security/checkpoint
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_SEC
	name = "Security Checkpoint"

/area/boxstation/security/detectives_office
	parent_type = /area/deltastation/security/detectives_office
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_SEC
	name = "Detective's Office"

/area/boxstation/security/hos
	parent_type = /area/deltastation/command/heads_quarters/hos
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COMMAND
	name = "Head of Security's Office"

/area/boxstation/security/main
	parent_type = /area/deltastation/security/office
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_SEC
	name = "Security Office"

/area/boxstation/security/prison
	parent_type = /area/deltastation/security/prison
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_SEC
	name = "Prison Wing"

/area/boxstation/security/processing
	parent_type = /area/deltastation/security/holding_cell
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_SEC
	name = "Labor Shuttle Dock"

/area/boxstation/security/transfer
	parent_type = /area/deltastation/security/execution/transfer
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_SEC
	name = "Transfer Centre"

/area/boxstation/security/vacantoffice
	parent_type = /area/deltastation/security/office
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_SEC
	name = "Vacant Office"

/area/boxstation/security/warden
	parent_type = /area/deltastation/security/warden
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_SEC
	name = "Brig Control"

/area/boxstation/shuttle/abandoned
	parent_type = /area/deltastation
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Abandoned Ship"

/area/boxstation/shuttle/arrival
	parent_type = /area/deltastation
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Arrival Shuttle"

/area/boxstation/shuttle/escape
	parent_type = /area/deltastation
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Emergency Shuttle"

/area/boxstation/shuttle/labor
	parent_type = /area/deltastation
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Labor Camp Shuttle"

/area/boxstation/shuttle/pod_1
	parent_type = /area/deltastation
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Escape Pod One"

/area/boxstation/shuttle/pod_2
	parent_type = /area/deltastation
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Escape Pod Two"

/area/boxstation/shuttle/pod_3
	parent_type = /area/deltastation
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Escape Pod Three"

/area/boxstation/shuttle/pod_4
	parent_type = /area/deltastation
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Escape Pod Four"

/area/boxstation/shuttle/supply
	parent_type = /area/deltastation
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Supply Shuttle"

/area/boxstation/shuttle/syndicate
	parent_type = /area/deltastation
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Syndicate Infiltrator"

/area/boxstation/shuttle/transport
	parent_type = /area/deltastation
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "Transport Shuttle"

/area/boxstation/solar/auxport
	parent_type = /area/deltastation/solars/port/aft
	outside = TRUE
	ceiling = CEILING_NONE
	minimap_color = MINIMAP_AREA_ENGI
	name = "Space"

/area/boxstation/solar/auxstarboard
	parent_type = /area/deltastation/solars/starboard/aft
	outside = TRUE
	ceiling = CEILING_NONE
	minimap_color = MINIMAP_AREA_ENGI
	name = "Space"

/area/boxstation/solar/port
	parent_type = /area/deltastation/solars/port/fore
	outside = TRUE
	ceiling = CEILING_NONE
	minimap_color = MINIMAP_AREA_ENGI
	name = "Space"

/area/boxstation/solar/starboard
	parent_type = /area/deltastation/solars/starboard/fore
	outside = TRUE
	ceiling = CEILING_NONE
	minimap_color = MINIMAP_AREA_ENGI
	name = "Space"

/area/boxstation/space
	parent_type = /area/space
	name = "Space"
	outside = TRUE
	ceiling = CEILING_NONE
	requires_power = FALSE
	always_unpowered = TRUE

/area/boxstation/space/nearstation
	parent_type = /area/space
	name = "Space"
	outside = TRUE
	ceiling = CEILING_NONE
	requires_power = FALSE
	always_unpowered = TRUE

/area/boxstation/storage/art
	parent_type = /area/deltastation/commons/storage/art
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_LIVING
	name = "Art Supply Storage"

/area/boxstation/storage/emergency
	parent_type = /area/deltastation/commons/storage/emergency/port
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_LIVING
	name = "Starboard Emergency Storage"

/area/boxstation/storage/emergency2
	parent_type = /area/deltastation/commons/storage/emergency/starboard
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_LIVING
	name = "Port Emergency Storage"

/area/boxstation/storage/primary
	parent_type = /area/deltastation/commons/storage/primary
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_LIVING
	name = "Primary Tool Storage"

/area/boxstation/storage/tech
	parent_type = /area/deltastation/engineering/storage/tech
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_ENGI
	name = "Technical Storage"

/area/boxstation/storage/tools
	parent_type = /area/deltastation/commons/storage/tools
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_LIVING
	name = "Auxiliary Tool Storage"

/area/boxstation/tcommsat/computer
	parent_type = /area/deltastation/tcommsat/computer
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COMMAND
	name = "Telecoms Control Room"

/area/boxstation/tcommsat/server
	parent_type = /area/deltastation/tcommsat/server
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COMMAND
	name = "Telecoms Server Room"

/area/boxstation/teleporter
	parent_type = /area/deltastation/command/teleporter
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COMMAND
	name = "Teleporter"

/area/boxstation/toxins/explab
	parent_type = /area/deltastation/science/explab
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_RESEARCH
	name = "Experimentation Lab"

/area/boxstation/toxins/lab
	parent_type = /area/deltastation/science/lab
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_RESEARCH
	name = "Research and Development"

/area/boxstation/toxins/misc_lab
	parent_type = /area/deltastation/science/research
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_RESEARCH
	name = "Testing Lab"

/area/boxstation/toxins/mixing
	parent_type = /area/deltastation/science/ordnance/burnchamber
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_RESEARCH
	name = "Toxins Mixing Room"

/area/boxstation/toxins/server
	parent_type = /area/deltastation/science/server
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_RESEARCH
	name = "Server Room"

/area/boxstation/toxins/storage
	parent_type = /area/deltastation/science
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_RESEARCH
	name = "Toxins Storage"

/area/boxstation/toxins/test_area
	parent_type = /area/deltastation/science/ordnance/testlab
	outside = TRUE
	ceiling = CEILING_NONE
	minimap_color = MINIMAP_AREA_RESEARCH
	name = "Toxins Test Area"

/area/boxstation/toxins/xenobiology
	parent_type = /area/deltastation/science/xenobiology
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_RESEARCH
	name = "Xenobiology Lab"

/area/boxstation/turret_protected/AIsatextAS
	parent_type = /area/deltastation/ai_monitored/turret_protected/aisat
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "AI Sat Ext"

/area/boxstation/turret_protected/AIsatextFP
	parent_type = /area/deltastation/ai_monitored/turret_protected/aisat
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "AI Sat Ext"

/area/boxstation/turret_protected/AIsatextFS
	parent_type = /area/deltastation/ai_monitored/turret_protected/aisat
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "AI Sat Ext"

/area/boxstation/turret_protected/ai
	parent_type = /area/deltastation/ai_monitored/turret_protected/ai
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "AI Chamber"

/area/boxstation/turret_protected/ai_upload
	parent_type = /area/deltastation/ai_monitored/turret_protected/ai_upload
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "AI Upload Chamber"

/area/boxstation/turret_protected/aisat_interior
	parent_type = /area/deltastation/ai_monitored/turret_protected/aisat_interior
	outside = FALSE
	ceiling = CEILING_METAL
	minimap_color = MINIMAP_AREA_COLONY
	name = "AI Satellite Antechamber"

/area/boxstation/landingzone
	parent_type = /area/deltastation/external/landingzone
	name = "BoxStation Landing Zone"
	requires_power = FALSE
	outside = TRUE
	ceiling = CEILING_NONE
