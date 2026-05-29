/turf/closed/interior/tank/door/arc
	name = "ARC side door"
	icon = 'icons/obj/vehicles/interiors/arc.dmi'
	icon_state = "exit_door"

/turf/closed/interior/tank/door/arc/get_enter_location()
	return get_step(src, NORTH) // Вход и выход южнее

/obj/structure/prop/vehicle/arc
	name = "ARC chassis"

	icon = 'icons/obj/vehicles/interiors/arc_chassis.dmi'
	icon_state = "arc_chassis"
	layer = WEEDWALL_LAYER
	plane = WALL_PLANE
	mouse_opacity = FALSE

/turf/closed/interior/tank/door/arc
