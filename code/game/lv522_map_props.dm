// Static LV522 prop definitions; imported art is staged in temp/LV522.

/obj/structure/prop/tower
	name = "destroyed comms tower"
	desc = "An old company comms tower used to transmit communications between subspace bodies. Looks like this one has seen better days."
	icon = 'temp/LV522/icons/obj/structures/machinery/comm_tower.dmi'
	icon_state = "comm_tower_destroyed"
	density = TRUE
	layer = ABOVE_MOB_LAYER
	bound_height = 96

/obj/structure/prop/dam/drill
	name = "mining drill"
	desc = "An old mining drill, seemingly used for mining. And possibly drilling."
	icon = 'temp/LV522/icons/obj/structures/props/industrial/drill.dmi'
	icon_state = "drill"
	bound_height = 96
	var/on = FALSE//if this is set to on by default, the drill will start on, doi

/obj/structure/prop/dam/truck
	name = "truck"
	desc = "An old truck, seems to be broken down."
	icon = 'temp/LV522/icons/obj/structures/props/vehicles/vehicles.dmi'
	icon_state = "truck"
	bound_height = 64
	bound_width = 64

/obj/structure/prop/dam/van/damaged
	icon_state = "van_damaged"

/obj/structure/prop/dam/crane
	name = "cargo crane"
	icon = 'temp/LV522/icons/obj/structures/props/vehicles/vehicles.dmi'
	icon_state = "crane"
	bound_height = 64
	bound_width = 64

/obj/structure/prop/dam/crane/damaged
	icon_state = "crane_damaged"

/obj/structure/prop/dam/crane/cargo
	icon_state = "crane_cargo"

/obj/structure/prop/server_equipment
	name = "server rack"
	desc = "A rack full of hard drives, micro-computers, and ethernet cables."
	icon = 'temp/LV522/icons/obj/structures/props/server_equipment.dmi'
	icon_state = "rackframe"
	density = TRUE
	max_integrity = 150

/obj/structure/prop/server_equipment/yutani_server
	name = "Yutani OS server box"
	desc = "Yutani OS is a proprietary operating system used by the Company to run most all of their servers, banking, and management systems. A code leak in 2144 led some amateur hackers to believe that Yutani OS is loosely based on the 2017 release of TempleOS. But the Company has refuted these claims."
	icon_state = "yutani_server_on"

/obj/structure/prop/server_equipment/yutani_server/broken
	icon_state = "yutani_server_broken"

/obj/structure/prop/server_equipment/yutani_server/off
	icon_state = "yutani_server_off"

/obj/structure/prop/server_equipment/laptop
	name = "laptop"
	desc = "Laptops, porta-comps, and reel-back computers, all of these and more available at your local Wey-Mart electronics section!"
	icon_state = "laptop_off"
	density = FALSE

/obj/structure/prop/server_equipment/laptop/closed
	icon_state = "laptop_closed"

/obj/structure/prop/server_equipment/laptop/on
	icon_state = "laptop_on"
	desc = "The screen is stuck on some sort of boot-loop in terrible garish green. All the text is in Rusoek, a creole language spawned out of the borders of UA and UPP space from some Korean settlements."

/obj/structure/prop/turbine_extras
	name = "power turbine struts"
	icon = 'temp/LV522/icons/obj/structures/props/industrial/biomass_turbine.dmi'
	icon_state = "support_struts_r"
	desc = "Pipes, or maybe support struts that lead into, or perhaps support that big ol' turbine."
	density = FALSE

/obj/structure/prop/turbine_extras/border
	name = "power turbine warning stripes"
	icon_state = "biomass_turbine_border"
	desc = "Warning markers. Keep a safe distance, high voltage!"
	layer = 2.5

/obj/structure/prop/turbine_extras/left
	name = "power turbine struts"
	icon_state = "support_struts_l"

/obj/structure/prop/cash_register/off/open
	icon_state = "cash_register_off_open"

/obj/structure/prop/invuln/lifeboat_hatch_placeholder
	density = FALSE
	name = "non-functional hatch"
	desc = "You'll need more than a prybar for this one."
	icon = 'temp/LV522/icons/obj/structures/machinery/bolt_target.dmi'
	icon_state = "closed"

/obj/structure/prop/invuln/lifeboat_hatch_placeholder/terminal
	icon = 'temp/LV522/icons/obj/structures/machinery/bolt_terminal.dmi'
	icon_state = "closed"

/obj/structure/prop/ice_colony/ground_wire
	name = "ground wire"
	desc = "A small string of black wire hangs between two marker posts. Probably used to mark off an area."
	icon_state = "small_wire"

/obj/structure/prop/ice_colony/surveying_device
	name = "surveying device"
	desc = "A small laser measuring tool and camera mounted on a tripod. Comes in a stark safety yellow."
	icon_state = "surveying_device"
	anchored = FALSE

/obj/structure/prop/ice_colony/dense/planter_box
	icon_state = "planter_box_soil"
	name = "grow box"
	desc = "A root lattice is half buried inside the grow box."

/obj/structure/prop/ice_colony/flamingo
	density = FALSE
	name = "lawn flamingo"
	desc = "For ornamenting your suburban lawn... or your ice colony."
	icon_state = "flamingo"

/obj/structure/prop/holidays/string_lights
	name = "M1 pattern festive bulb strings"
	desc = "Strung from strut to strut, these standard issue M1 pattern 'festive bulb strings' flicker and shimmer to the tune of the output frequency of the Almayer's Engine... or the local power grid. Might want to ask the Bravo's to check which one it is for ya. Ya damn jarhead."
	icon_state = "string_lights"

/obj/structure/prop/holidays/wreath
	name = "M1 pattern festive needle torus"
	desc = "In 2140 after a two different sublevels of the São Luís Bay Underground Habitat burned out (evidence points to a Bladerunner incident, but local police denies such claims) due to actual wreaths made with REAL needles, these have been issued ever since. They're made of ''''''pine'''''' scented poly-kevlon. According to the grunts from the American Corridor, during the SACO riots, protestors would pack these things into pillow cases, forming rudimentary body armor against soft point ballistics."
	icon_state = "wreath"

/obj/structure/prop/vehicles
	name = "van"
	desc = "An old van, seems to be broken down."
	icon = 'temp/LV522/icons/obj/structures/props/vehicles/vehicles.dmi'
	icon_state = "van"
	bound_height = 64
	bound_width = 64

/obj/structure/prop/vehicles/crawler
	name = "colony crawler"
	desc = "It is a tread bound crawler used in harsh conditions. Supplied by Orbital Blue International; 'Your friends, in the Aerospace business.' A subsidiary of Weyland Yutani."
	icon_state = "crawler"
	density = TRUE

/obj/structure/prop/invuln/overhead/flammable_pipe/fly
	density = FALSE

/obj/structure/prop/invuln/minecart_tracks
	name = "rails"
	icon_state = "rail"
	icon = 'temp/LV522/icons/obj/structures/props/mining.dmi'
	density =  0
	desc = "Minecarts and rail vehicles go on these."
	layer = 3

/obj/structure/prop/invuln/minecart_tracks/bumper
	name = "rail bumpers"
	icon_state = "rail_bumpers"
	desc = "This (usually) stops minecarts and other rail vehicles at the end of a line of track."

/obj/structure/prop/invuln/ice_prefab
	name = "prefabricated structure"
	desc = "This structure is made of metal support rods and robust poly-kevlon plastics. A derivative of the stuff used in UA ballistics vests, USCM and UPP uniforms. The loose walls roll with each gust of wind."
	icon = 'temp/LV522/icons/obj/structures/props/ice_colony/fabs_tileset.dmi'
	icon_state = "fab"
	density = TRUE
	layer = 3
	bound_width = 32
	bound_height = 32

/obj/structure/prop/invuln/ice_prefab/trim
	layer = ABOVE_MOB_LAYER
	density = FALSE

/obj/structure/prop/invuln/ice_prefab/roof_greeble
	icon = 'temp/LV522/icons/obj/structures/props/ice_colony/fabs_greebles.dmi'
	icon_state = "antenna"
	layer = ABOVE_MOB_LAYER
	desc = "Windsocks, Air-Con units, solarpanels, oh my!"
	density = FALSE

/obj/structure/prop/invuln/ice_prefab/standalone
	density = TRUE
	icon = 'temp/LV522/icons/obj/structures/props/ice_colony/fabs_64.dmi'
	icon_state = "orange"//instance icons
	layer = 3
	bound_width = 64
	bound_height = 64

/obj/structure/prop/invuln/ice_prefab/standalone/trim
	icon_state = "orange_trim"//instance icons
	layer = ABOVE_MOB_LAYER
	density = FALSE

/obj/structure/prop/invuln/remote_console_pod
	name = "Remote Console Pod"
	desc = "A drop pod used to launch remote piloting equipment to USCM areas of operation."
	icon = 'temp/LV522/icons/obj/structures/droppod_32x64.dmi'
	icon_state = "techpod_open"
	layer = ABOVE_MOB_LAYER

/obj/structure/prop/invuln/overhead_pipe
	name = "overhead pipe segment"
	desc = ""
	icon = 'temp/LV522/icons/obj/pipes/pipes.dmi'
	icon_state = "intact-scrubbers"
	density = FALSE
	layer = RIPPLE_LAYER

/obj/structure/prop/invuln/fire
	name = "fire"
	desc = "That isn't going out any time soon."
	color = "#FF7700"
	icon = 'temp/LV522/icons/effects/fire.dmi'
	icon_state = "dynamic_2"
	layer = MOB_LAYER
	light_range = 3
	light_on = TRUE

/obj/structure/prop/invuln/pipe_water
	name = "pipe water"
	desc = ""
	icon = 'temp/LV522/icons/obj/structures/props/watercloset.dmi'
	icon_state = "water"
	density = 0

/obj/structure/prop/invuln/lattice_prop
	desc = "A lightweight support lattice."
	name = "lattice"
	icon = 'temp/LV522/icons/obj/structures/props/smoothlattice.dmi'
	icon_state = "lattice0"
	density = FALSE
	layer = RIPPLE_LAYER

/obj/structure/prop/invuln/rope
	name = "rope"
	desc = "A secure rope looks like someone might've been hiding out on those rocks."
	icon = 'temp/LV522/icons/obj/structures/props/dropship/dropship_equipment.dmi'
	icon_state = "rope"
	density = FALSE

/obj/structure/prop/almayer/computers/sensor_computer1
	name = "sensor computer"
	desc = "The IBM series 10 computer retrofitted to work as a sensor computer for the ship. While somewhat dated it still serves its purpose."
	icon = 'temp/LV522/icons/obj/structures/props/almayer/almayer_props.dmi'
	icon_state = "sensor_comp1"

/obj/structure/prop/almayer/computers/sensor_computer2
	name = "sensor computer"
	desc = "The IBM series 10 computer retrofitted to work as a sensor computer for the ship. While somewhat dated it still serves its purpose."
	icon = 'temp/LV522/icons/obj/structures/props/almayer/almayer_props.dmi'
	icon_state = "sensor_comp2"

/obj/structure/prop/almayer/computers/sensor_computer3
	name = "sensor computer"
	desc = "The IBM series 10 computer retrofitted to work as a sensor computer for the ship. While somewhat dated it still serves its purpose."
	icon = 'temp/LV522/icons/obj/structures/props/almayer/almayer_props.dmi'
	icon_state = "sensor_comp3"

/obj/structure/prop/ice_colony/hula_girl

/obj/structure/prop/structure_lattice

// BEGIN MAP VISUAL REPAIRS
/obj/structure/prop/invuln/overhead/flammable_pipe/fly
	icon = 'temp/LV522/icons/obj/structures/props/industrial/overhead_ducting.dmi'
	icon_state = "flammable_pipe_1"
