/obj/item/attachable/verticalgrip
	name = "vertical grip"
	desc = "A custom-built improved foregrip for better accuracy, moderately faster aimed movement speed, less recoil, and less scatter when wielded especially during burst fire. \nHowever, it also increases weapon size, slightly increases wield delay and makes unwielded fire more cumbersome."
	icon_state = "verticalgrip"
	wield_delay_mod = 0.2 SECONDS
	size_mod = 1
	slot = ATTACHMENT_SLOT_UNDER
	pixel_shift_x = 20
	accuracy_mod = 0.1
	recoil_mod = -2
	scatter_mod = -3
	burst_scatter_mod = -1
	accuracy_unwielded_mod = -0.05
	scatter_unwielded_mod = 3
	aim_speed_mod = -0.1
	aim_mode_movement_mult = -0.2

/obj/item/attachable/angledgrip
	name = "angled grip"
	desc = "A custom-built improved foregrip for less recoil, and faster wielding time. \nHowever, it also increases weapon size, and slightly hinders unwielded firing."
	icon_state = "angledgrip"
	wield_delay_mod = -0.3 SECONDS
	size_mod = 1
	slot = ATTACHMENT_SLOT_UNDER
	pixel_shift_x = 20
	recoil_mod = -1
	scatter_mod = 2
	accuracy_unwielded_mod = -0.1
	scatter_unwielded_mod = 1

/obj/item/attachable/gyro
	name = "gyroscopic stabilizer"
	desc = "A set of weights and balances to stabilize the weapon when burst firing or moving, especially while shooting one-handed. Greatly reduces movement penalties to accuracy. Significantly reduces burst scatter, recoil and general scatter. By increasing accuracy while moving, it let you move faster when taking aim."
	icon_state = "gyro"
	slot = ATTACHMENT_SLOT_UNDER
	scatter_mod = -1
	recoil_mod = -2
	movement_acc_penalty_mod = -2
	accuracy_unwielded_mod = 0.1
	scatter_unwielded_mod = -2
	recoil_unwielded_mod = -1
	aim_mode_movement_mult = -0.5

/obj/item/attachable/lasersight
	name = "laser sight"
	desc = "A laser sight placed under the barrel. Significantly increases one-handed accuracy and significantly reduces unwielded penalties to accuracy."
	icon_state = "lasersight"
	slot = ATTACHMENT_SLOT_UNDER
	pixel_shift_x = 17
	pixel_shift_y = 17
	accuracy_mod = 0.1
	accuracy_unwielded_mod = 0.15

/obj/item/attachable/lace
	name = "pistol lace"
	desc = "A simple lace to wrap around your wrist."
	icon_state = "lace"
	slot = ATTACHMENT_SLOT_MUZZLE //so you cannot have this and RC at once aka balance
	attach_features_flags = ATTACH_REMOVABLE|ATTACH_ACTIVATION
	attachment_action_type = /datum/action/item_action/toggle

/obj/item/attachable/lace/activate(mob/living/user, turn_off)
	if(lace_deployed)
		REMOVE_TRAIT(master_gun, TRAIT_NODROP, PISTOL_LACE_TRAIT)
		to_chat(user, span_notice("You feel the [src] loosen around your wrist!"))
		playsound(user, 'sound/weapons/fistunclamp.ogg', 25, 1, 7)
		icon_state = "lace"
	else if(turn_off)
		return
	else
		if(user.do_actions)
			return
		to_chat(user, span_notice("You deploy the [src]."))
		ADD_TRAIT(master_gun, TRAIT_NODROP, PISTOL_LACE_TRAIT)
		to_chat(user, span_warning("You feel the [src] shut around your wrist!"))
		playsound(user, 'sound/weapons/fistclamp.ogg', 25, 1, 7)
		icon_state = "lace-on"

	lace_deployed = !lace_deployed

	update_icon()
	return TRUE

/obj/item/attachable/lace/t500
	name = "R-500 lace"
	icon = 'icons/obj/items/attachments/attachments_64.dmi'
	slot = ATTACHMENT_SLOT_STOCK
	pixel_shift_x = 0
	pixel_shift_y = 0

/obj/item/attachable/burstfire_assembly
	name = "burst fire assembly"
	desc = "A mechanism re-assembly kit that allows for automatic fire, or more shots per burst if the weapon already has the ability."
	icon_state = "rapidfire"
	slot = ATTACHMENT_SLOT_UNDER
	burst_mod = 2
	gun_firemode_list_mod = list(GUN_FIREMODE_AUTOMATIC)

	var/list/saved_firemode_list = null

/obj/item/attachable/burstfire_assembly/on_attach(attaching_item, mob/user)
	if(!istype(attaching_item, /obj/item/weapon/gun))
		return

	master_gun = attaching_item

	saved_firemode_list = master_gun.gun_firemode_list.Copy()

	apply_modifiers(attaching_item, user, TRUE)

	if(attachment_action_type)
		var/datum/action/action_to_update = new attachment_action_type(src, master_gun)
		if(isliving(master_gun.loc))
			var/mob/living/living_user = master_gun.loc
			if(master_gun == living_user.l_hand || master_gun == living_user.r_hand)
				action_to_update.give_action(living_user)

	if(length(variants_by_parent_type))
		for(var/selection in variants_by_parent_type)
			if(istype(master_gun, selection))
				icon_state = variants_by_parent_type[selection]

	update_icon()

/obj/item/attachable/burstfire_assembly/on_detach(detaching_item, mob/user)
	if(!isgun(detaching_item))
		return

	activate(user, TRUE)

	apply_modifiers(detaching_item, user, FALSE)

	for(var/mode in master_gun.gun_firemode_list)
		if(!(mode in saved_firemode_list))
			master_gun.gun_firemode_list -= mode

	if(!(master_gun.gun_firemode in master_gun.gun_firemode_list))
		master_gun.gun_firemode = master_gun.gun_firemode_list[1]

	if(length(master_gun.gun_firemode_list) == 1)
		var/datum/action/old_action = locate(/datum/action/item_action/firemode) in master_gun.actions
		if(old_action)
			old_action.remove_action(user)
			qdel(old_action)

	for(var/datum/action/action_to_update AS in master_gun.actions)
		if(action_to_update.target != src)
			continue
		qdel(action_to_update)
		break

	master_gun = null
	icon_state = initial(icon_state)
	update_icon()
