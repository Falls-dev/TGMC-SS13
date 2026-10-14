/// Invisible perimeter walls. Linking happens after all template atoms initialize.
/obj/structure/blocker/tent
	name = "tent wall"
	icon = 'icons/obj/structures/tents_equipment.dmi'
	icon_state = "curtains-classic"
	atom_flags = ON_BORDER
	invisibility = INVISIBILITY_MAXIMUM
	density = TRUE
	allow_pass_flags = PASS_THROW | PASS_PROJECTILE
	obj_flags = NONE
	coverage = 0
	var/obj/structure/tent/linked_tent

/obj/structure/blocker/tent/Initialize(mapload)
	. = ..()
	var/static/list/connections = list(COMSIG_ATOM_EXIT = PROC_REF(on_try_exit))
	AddElement(/datum/element/connect_loc, connections)
	return INITIALIZE_HINT_LATELOAD

/obj/structure/blocker/tent/LateInitialize()
	linked_tent = locate(/obj/structure/tent) in loc
	if(!linked_tent)
		qdel(src)
		return
	RegisterSignal(linked_tent, COMSIG_QDELETING, PROC_REF(collapse))

/obj/structure/blocker/tent/Destroy()
	linked_tent = null
	return ..()

/obj/structure/blocker/tent/proc/collapse()
	SIGNAL_HANDLER
	qdel(src)

/obj/structure/blocker/tent/full_tile
	atom_flags = NONE

/obj/structure/blocker/tent/projectile_hit(atom/movable/projectile/proj, cardinal_move, uncrossing)
	return FALSE
