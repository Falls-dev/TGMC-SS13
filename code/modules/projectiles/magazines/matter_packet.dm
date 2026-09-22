/// A universal ammunition container that can manufacture compatible ammunition.
/obj/item/matter_ammo_container/box
	name = "universal ammunition box"
	desc = "A universal ammunition box that produces compatible ammunition."
	icon = 'icons/obj/items/ammo/packet.dmi'
	icon_state = "box_matter"
	base_icon_state = "box_matter"
	icon_state_mini = "ammo_packet"
	worn_icon_state = "ammo_mag"
	worn_icon_list = list(
		slot_l_hand_str = 'icons/mob/inhands/weapons/ammo_left.dmi',
		slot_r_hand_str = 'icons/mob/inhands/weapons/ammo_right.dmi',
	)
	w_class = WEIGHT_CLASS_NORMAL
	equip_slot_flags = ITEM_SLOT_BELT
	atom_flags = CONDUCT
	throwforce = 2
	throw_speed = 2
	throw_range = 6
	var/matter_amount = 600
	var/max_matter_amount = 600

/obj/item/matter_ammo_container/box/Initialize(mapload, spawn_empty)
	. = ..()
	base_icon_state = icon_state
	if(spawn_empty)
		matter_amount = 0
	update_icon()

/obj/item/matter_ammo_container/box/update_icon_state()
	. = ..()
	if(matter_amount)
		icon_state = base_icon_state
		return
	icon_state = "[base_icon_state]_e"

/obj/item/matter_ammo_container/box/examine(mob/user)
	. = ..()
	if(matter_amount)
		. += "It is [round(100 * matter_amount / max_matter_amount)]% full."
	else
		. += "It's empty."

/// For a matter container, source is the magazine that will be refilled.
/obj/item/matter_ammo_container/box/proc/can_transfer_ammo(obj/item/ammo_magazine/source, mob/user, transfer_amount = 1, silent = FALSE)
	if(!source || !CHECK_BITFIELD(source.magazine_flags, MAGAZINE_REFILLABLE))
		return FALSE
	if(source.current_rounds >= source.max_rounds)
		if(!silent)
			to_chat(user, span_notice("[source] is already full."))
		return FALSE
	if(!source.default_ammo || source.default_ammo.matter_cost <= 0)
		if(!silent)
			to_chat(user, span_warning("This ammunition type cannot be produced by [src]."))
		return FALSE
	if(matter_amount < source.default_ammo.matter_cost)
		if(!silent)
			to_chat(user, span_warning("[src] does not contain enough universal ammunition."))
		return FALSE
	return TRUE

/// Fill a regular magazine from this container's universal ammunition.
/obj/item/matter_ammo_container/box/proc/refill_magazine(obj/item/ammo_magazine/target, mob/user)
	if(!can_transfer_ammo(target, user))
		return FALSE

	var/rounds_to_add = min(matter_amount / target.default_ammo.matter_cost, target.max_rounds - target.current_rounds)
	var/matter_used = rounds_to_add * target.default_ammo.matter_cost
	target.current_rounds += rounds_to_add
	matter_amount -= matter_used
	target.update_icon()
	update_icon()
	playsound(loc, 'sound/weapons/guns/interact/revolver_load.ogg', 25, 1)
	to_chat(user, span_notice("You add [rounds_to_add] rounds to [target] using [src]."))
	return TRUE

/// Reclaim universal ammunition from a magazine, matching matter_ammo_box behavior.
/obj/item/matter_ammo_container/box/proc/convert_ammo_to_matter(obj/item/ammo_magazine/source, mob/user)
	if(!source.default_ammo || source.default_ammo.matter_cost <= 0)
		to_chat(user, span_warning("This ammunition type cannot be reclaimed by [src]."))
		return FALSE
	if(matter_amount >= max_matter_amount)
		to_chat(user, span_warning("[src] is full!"))
		return FALSE

	var/rounds_to_remove = min(source.current_rounds, trunc((max_matter_amount - matter_amount) / source.default_ammo.matter_cost))
	var/matter_gained = rounds_to_remove * source.default_ammo.matter_cost
	if(!rounds_to_remove)
		return FALSE
	source.current_rounds -= rounds_to_remove
	matter_amount += matter_gained
	source.update_icon()
	update_icon()
	playsound(loc, 'sound/weapons/guns/interact/revolver_load.ogg', 25, 1)
	to_chat(user, span_notice("You recover universal ammunition from [source]."))
	if(source.current_rounds <= 0 && CHECK_BITFIELD(source.magazine_flags, MAGAZINE_HANDFUL))
		user.temporarilyRemoveItemFromInventory(source)
		qdel(source)
	return TRUE

/obj/item/matter_ammo_container/box/proc/transfer_matter_to_box(obj/item/matter_ammo_box/target, mob/user)
	if(!matter_amount)
		to_chat(user, span_warning("[src] is empty."))
		return FALSE
	if(target.requires_ground && !isturf(target.loc))
		to_chat(user, span_warning("[target] must be on the ground to be used."))
		return FALSE
	if(target.matter_amount >= target.max_matter_amount)
		to_chat(user, span_warning("[target] is full."))
		return FALSE
	var/transfer_amount = min(matter_amount, target.max_matter_amount - target.matter_amount)
	target.matter_amount += transfer_amount
	matter_amount -= transfer_amount
	target.update_icon()
	update_icon()
	to_chat(user, span_notice("You transfer universal ammunition from [src] to [target]."))
	return TRUE

/obj/item/matter_ammo_container/box/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/matter_ammo_container/box))
		var/obj/item/matter_ammo_container/box/other = I
		if(matter_amount >= max_matter_amount)
			to_chat(user, span_warning("[src] is full!"))
			return
		var/transfer_amount = min(other.matter_amount, max_matter_amount - matter_amount)
		matter_amount += transfer_amount
		other.matter_amount -= transfer_amount
		update_icon()
		other.update_icon()
		to_chat(user, span_notice("You transfer universal ammunition from [other] to [src]."))
		return
	if(istype(I, /obj/item/ammo_magazine))
		var/obj/item/ammo_magazine/source = I
		convert_ammo_to_matter(source, user)
		return
	if(istype(I, /obj/item/matter_ammo_box))
		var/obj/item/matter_ammo_box/box = I
		if(matter_amount >= max_matter_amount)
			to_chat(user, span_warning("[src] is full!"))
			return
		var/transfer_amount = min(box.matter_amount, max_matter_amount - matter_amount)
		matter_amount += transfer_amount
		box.matter_amount -= transfer_amount
		update_icon()
		box.update_icon()
		to_chat(user, span_notice("You transfer universal ammunition from [box] to [src]."))
		return
	. = ..()

/obj/item/matter_ammo_container/box/fire_act(burn_level, flame_color)
	if(QDELETED(src) || !matter_amount)
		return
	var/turf/explosion_loc = loc
	var/power = 5
	for(var/obj/item/matter_ammo_container/box/container in explosion_loc)
		if(!container.matter_amount)
			continue
		power++
		qdel(container)
	cell_explosion(explosion_loc, power, power)

/// Compact variant of a universal ammunition box.
/obj/item/matter_ammo_container/box/packet
	name = "universal ammunition packet"
	desc = "A compact universal ammunition packet that produces compatible ammunition."
	icon_state = "packet_matter"
	base_icon_state = "packet_matter"
	w_class = WEIGHT_CLASS_SMALL
	matter_amount = 400
	max_matter_amount = 400
