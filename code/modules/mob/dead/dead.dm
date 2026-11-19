//Dead mobs can exist whenever. This is needful

INITIALIZE_IMMEDIATE(/mob/dead)

/mob/dead
	sight = SEE_TURFS | SEE_MOBS | SEE_OBJS | SEE_SELF
	move_resist = INFINITY
	resistance_flags = RESIST_ALL

/mob/dead/dust()	//ghosts can't be vaporised.
	return

/mob/dead/gib()		//ghosts can't be gibbed.
	return

/mob/dead/forceMove(atom/destination)
	var/atom/oldloc = loc
	set_loc_with_z_tracking(destination)
	Moved(oldloc, NONE, TRUE)

/mob/dead/abstract_move(atom/destination, track_z = TRUE)
	return ..(destination, track_z)
