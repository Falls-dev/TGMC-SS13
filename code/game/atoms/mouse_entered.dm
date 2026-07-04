/atom/MouseEntered(location, control, params)
	. = ..()
	var/mob/user = usr
	if(!user)
		return
	SEND_SIGNAL(user, COMSIG_ATOM_MOUSE_ENTERED, src)

