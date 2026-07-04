// Van interior stuff

/turf/closed/interior/van
	name = "van interior wall"
	desc = "An interior wall."
	icon = 'icons/obj/vehicles/interiors/van.dmi'
	icon_state = "van_right_1"
	density = TRUE
	opacity = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_WINDOW_LAYER
	resistance_flags = RESIST_ALL

/obj/effect/vehicle_roof/van
	name = "\improper van interior roof"
	icon = 'icons/obj/vehicles/interiors/van.dmi'
	icon_state = "roof_1"

/turf/closed/interior/tank/door/van/left
	name = "Van left door"
	icon = 'icons/obj/vehicles/interiors/van.dmi'
	icon_state = "interior_door"

/turf/closed/interior/tank/door/van/right
	name = "Van right door"
	icon = 'icons/obj/vehicles/interiors/van.dmi'
	icon_state = "exterior_door_unique"
	dir = SOUTH

/turf/closed/interior/tank/door/van/backleft
	name = "Van back exit"
	icon = 'icons/obj/vehicles/interiors/van.dmi'
	icon_state = "back_2"
	dir = WEST

/turf/closed/interior/tank/door/van/backright
	name = "Van back exit"
	icon = 'icons/obj/vehicles/interiors/van.dmi'
	icon_state = "back_1"
	dir = WEST
