//Previous onborder walls had problems with getting in the way for a lot of things since they are located on same tile as interior.
//these are staying beyond the walking area and are not getting in the way of shots, spits and other stuff.

//for mapping
//WALL_LAYER 2.02
//INTERIOR_WALL_SOUTH_LAYER 5.2
/obj/structure/interior_wall
	name = "interior wall"
	desc = "An interior wall."
	icon = 'icons/obj/vehicles/interiors/tank.dmi'
	density = TRUE
	opacity = TRUE
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = BELOW_CLOSED_TURF_LAYER
	resistance_flags = RESIST_ALL

/obj/structure/interior_wall/ex_act()
	return

//roof for small vehicles to emphasize small space

/obj/effect/vehicle_roof
	name = "interior roof"
	desc = "An interior roof."
	icon = 'icons/obj/vehicles/interiors/tank.dmi'
	density = FALSE
	opacity = FALSE
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_ALL_MOB_LAYER
	resistance_flags = RESIST_ALL

	alpha = 80

/obj/effect/vehicle_roof/ex_act()
	return

/obj/effect/landmark/interior/spawn
	name = "interior interactable spawner"

/obj/effect/landmark/interior/spawn/link_interior(datum/interior/link)
	on_load(link)

/obj/effect/landmark/interior/spawn/proc/on_load(datum/interior/link)
	qdel(src)

/obj/effect/landmark/interior/spawn/entrance
	name = "entrance marker"
	icon_state = "arrow"
	///Turf type to change this marker's location into.
	var/exit_type = /turf/closed/interior/tank/door

/obj/effect/landmark/interior/spawn/entrance/on_load(datum/interior/link)
	var/turf/exit_turf = get_turf(src)
	if(!exit_turf || !exit_type)
		qdel(src)
		return
	if(!ispath(exit_type, /turf))
		CRASH("Invalid interior exit type [exit_type] for [src]")
	exit_turf.ChangeTurf(exit_type)
	var/turf/closed/interior/tank/door/door = exit_turf
	if(istype(door))
		if(name != initial(name))
			door.name = name
		if(desc != initial(desc))
			door.desc = desc
		door.setDir(dir)
		door.alpha = alpha
		door.pixel_x = pixel_x
		door.pixel_y = pixel_y
		door.link_interior(link)
	qdel(src)

/obj/effect/landmark/interior/spawn/vehicle_driver_seat
	name = "driver's seat spawner"
	icon = 'icons/obj/armored/3x3/tank_interior.dmi'
	icon_state = "comfychair"
	color = "red"

/obj/effect/landmark/interior/spawn/vehicle_driver_seat/on_load(datum/interior/link)
	var/obj/structure/bed/chair/vehicle_crew/driver/driver_seat = new(loc)
	driver_seat.setDir(dir)
	driver_seat.alpha = alpha
	driver_seat.pixel_x = pixel_x
	driver_seat.pixel_y = pixel_y
	driver_seat.link_interior(link)
	qdel(src)

/obj/effect/landmark/interior/spawn/vehicle_driver_seat/armor
	icon = 'icons/obj/vehicles/interiors/general.dmi'
	icon_state = "armor_chair"

/obj/effect/landmark/interior/spawn/vehicle_driver_seat/armor/on_load(datum/interior/link)
	var/obj/structure/bed/chair/vehicle_crew/driver/driver_seat = new(loc)
	driver_seat.icon = icon
	driver_seat.icon_state = icon_state
	driver_seat.setDir(dir)
	driver_seat.alpha = alpha
	driver_seat.pixel_x = pixel_x
	driver_seat.pixel_y = pixel_y
	driver_seat.link_interior(link)
	qdel(src)

/obj/effect/landmark/interior/spawn/vehicle_driver_seat/armor/wy
	icon = 'icons/obj/vehicles/interiors/general_wy.dmi'
