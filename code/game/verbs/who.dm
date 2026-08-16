/client/verb/who()
	set name = "Who"
	set category = "OOC"

	SSwho.who.ui_interact(mob)

/client/verb/staffwho()
	set category = "Admin"
	set name = "Staffwho"

	SSwho.staff_who.ui_interact(mob)
