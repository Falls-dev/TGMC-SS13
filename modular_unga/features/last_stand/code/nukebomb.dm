///Last Stand nuclear bomb
/obj/structure/nuclearbomb
	name = "nuclear fission explosive"
	desc = "You probably shouldn't stick around to see if it's armed."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "nuclearbomb0"
	density = TRUE
	anchored = TRUE
	coverage = 20
	atom_flags = CRITICAL_ATOM
	max_integrity = 1000
	resistance_flags = XENO_DAMAGEABLE|PROJECTILE_IMMUNE|UNACIDABLE
	layer = BELOW_MOB_LAYER

/obj/structure/nuclearbomb/Initialize(mapload)
	. = ..()
	GLOB.nuclear_bombs += src

/obj/structure/nuclearbomb/attacked_by(obj/item/I, mob/living/user, def_zone)
	return FALSE

/obj/structure/nuclearbomb/ex_act(severity, direction)
	return

/obj/structure/nuclearbomb/obj_destruction(damage_amount, damage_type, damage_flag)
	explosion(loc, 60, 30, 50, 0, 40, explosion_cause=src) //funny kaboom
	return ..()

/obj/structure/nuclearbomb/Destroy()
	GLOB.nuclear_bombs -= src
	return ..()
