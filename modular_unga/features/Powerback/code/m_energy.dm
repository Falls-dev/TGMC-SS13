//ORIGINAL FILE: code/modules/projectiles/magazines/energy.dm

/obj/item/cell/lasgun/plasma
	rechargable = FALSE

/obj/item/cell/lasgun/volkite
	reload_delay = 0


/obj/item/cell/lasgun/volkite/powerpack/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(.)
		return
	if(istype(I, /obj/item/weapon/gun) && loc == user)
		var/obj/item/weapon/gun/gun = I
		if(!CHECK_BITFIELD(gun.reciever_flags, AMMO_RECIEVER_MAGAZINES))
			return
		gun.reload(src, user)
		return

	if(!istype(I, cell_type))
		return
	if(I != user.r_hand && I != user.l_hand)
		to_chat(user, span_warning("[I] must be in your hand to do that."))
		return
	var/obj/item/cell/our_cell = I
	// RU TGMC EDIT ADDITION BEGIN (te_powerback)
	if(!our_cell.rechargable)
		balloon_alert(user, "Not rechargeable")
		return
	// RU TGMC EDIT ADDITION END
	var/charge_difference = our_cell.maxcharge - our_cell.charge
	if(charge_difference)
		var/charge_used = use_charge(user, charge_difference)
		our_cell.charge += charge_used
		our_cell.update_icon()
	else
		to_chat(user, span_warning("This cell is already at maximum charge!"))


/obj/item/cell/lasgun/volkite/powerpack/marine_back
	name = "\improper TE powerback"
	desc = "A heavy reinforced backpack with an array of ultradensity energy cells. Click drag cells to the powerpack to recharge."
	icon = 'modular_unga/features/powerback/icons/powerpack.dmi'
	icon_state = "pp_100"
	maxcharge = 2400
	base_icon_state = "pp"

/obj/item/cell/lasgun/volkite/powerpack/marine_back/Initialize(mapload)
	. = ..()
	update_icon()

/obj/item/cell/lasgun/volkite/powerpack/marine_back/update_icon_state()
	. = ..()
	icon_state = base_icon_state
	switch(PERCENT(charge/maxcharge))
		if(75 to INFINITY)
			icon_state += "_100"
		if(50 to 74.9)
			icon_state += "_75"
		if(25 to 49.9)
			icon_state += "_50"
		if(0.1 to 24.9)
			icon_state += "_25"
		else
			icon_state += "_0"

	if(ishuman(loc))
		var/mob/living/carbon/human/human = loc
		human.update_inv_back()
