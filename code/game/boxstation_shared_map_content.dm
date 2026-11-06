// Shared visual definitions required by the retained maps after retiring LV522.

/obj/structure/prop/invuln/fire
	name = "fire"
	desc = "That isn't going out any time soon."
	color = "#FF7700"
	icon = 'temp/BoxStation/shared/icons/effects/fire.dmi'
	icon_state = "dynamic_2"
	layer = MOB_LAYER
	light_range = 3
	light_on = TRUE

/obj/structure/prop/boxstation/obj_structure_machinery_blackbox_recorder
	parent_type = /obj/structure/prop
	anchored = TRUE
	density = TRUE
	icon = 'temp/BoxStation/shared/icons/obj/structures/props/server_equipment.dmi'
	icon_state = "blackbox"
	layer = OBJ_LAYER
	name = "Blackbox Recorder"

/obj/structure/prop/boxstation/obj_structure_machinery_body_scanconsole
	parent_type = /obj/structure/prop
	anchored = TRUE
	density = FALSE
	icon = 'temp/BoxStation/shared/icons/obj/structures/machinery/cryogenics.dmi'
	icon_state = "body_scannerconsole"
	layer = OBJ_LAYER
	name = "body scanner console"

/obj/structure/prop/boxstation/obj_structure_machinery_cryo_cell
	parent_type = /obj/structure/prop
	anchored = TRUE
	density = FALSE
	desc = "A donation from the old A.W. project, using cryogenic technology. It slowly heals whoever is inside the tube."
	icon = 'temp/BoxStation/shared/icons/obj/structures/machinery/cryogenics2.dmi'
	layer = BELOW_OBJ_LAYER
	name = "cryo cell"

/obj/structure/prop/boxstation/obj_structure_machinery_medical_pod_bodyscanner
	parent_type = /obj/structure/prop
	anchored = TRUE
	density = TRUE
	icon = 'temp/BoxStation/shared/icons/obj/structures/machinery/cryogenics.dmi'
	icon_state = "body_scanner"
	layer = OBJ_LAYER
	name = "body scanner"

/turf/open/floor/boxstation/bluegrid
	parent_type = /turf/open/floor
	icon = 'temp/BoxStation/shared/icons/turf/floors/floors.dmi'
	icon_state = "bcircuit"
	name = "floor"
	smoothing_flags = NONE

