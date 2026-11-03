/datum/component/easy_restock
	///Parent storage. Use this over checking the item directly.
	var/datum/storage/reloading_storage

/datum/component/easy_restock/Initialize()
	. = ..()
	var/atom/atom_parent = parent
	if(!atom_parent.storage_datum)
		return COMPONENT_INCOMPATIBLE

/datum/component/easy_restock/Destroy(force, silent)
	reloading_storage = null
	return ..()

/datum/component/easy_restock/RegisterWithParent()
	var/atom/atom_parent = parent
	reloading_storage = atom_parent.storage_datum
	RegisterSignal(parent, COMSIG_ATOM_ATTACKBY_ALTERNATE, PROC_REF(on_parent_attackby_alternate))
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))

/datum/component/easy_restock/UnregisterFromParent()
	UnregisterSignal(parent, list(
		COMSIG_ATOM_ATTACKBY_ALTERNATE,
		COMSIG_ATOM_EXAMINE,
	))

/datum/component/easy_restock/proc/on_examine(datum/source, mob/user, list/details)
	SIGNAL_HANDLER
	details += span_notice("You can easily restock magazines inside via right click with an ammo box or universal ammunition container.")

/datum/component/easy_restock/proc/on_parent_attackby_alternate(datum/source, obj/item/ammo_source, mob/user, params)
	SIGNAL_HANDLER
	if(!istype(ammo_source, /obj/item/ammo_magazine) && !istype(ammo_source, /obj/item/matter_ammo_container/box))
		return
	if(!reloading_storage)
		CRASH("[user] attempted to reload [ammo_source] on [source], but it has no storage attached!")
	INVOKE_ASYNC(src, PROC_REF(do_tac_reload), ammo_source, user, params)

/datum/component/easy_restock/proc/do_tac_reload(obj/item/ammo_source, mob/user, params)
	var/atom/atom_parent = parent
	if(istype(ammo_source, /obj/item/matter_ammo_container/box))
		var/obj/item/matter_ammo_container/box/matter_box = ammo_source
		for(var/obj/item/ammo_magazine/item_to_restock in atom_parent.contents)
			if(!matter_box.matter_amount)
				return COMPONENT_NO_AFTERATTACK
			if(!matter_box.can_transfer_ammo(item_to_restock, user, 1, TRUE))
				continue
			matter_box.refill_magazine(item_to_restock, user)
		return COMPONENT_NO_AFTERATTACK

	if(!istype(ammo_source, /obj/item/ammo_magazine))
		return
	var/obj/item/ammo_magazine/ammo_box = ammo_source
	for(var/obj/item/ammo_magazine/item_to_restock in atom_parent.contents)
		var/amount_to_transfer = ammo_box.current_rounds

		if(!item_to_restock.can_transfer_ammo(ammo_box, user, amount_to_transfer, TRUE))
			continue

		if(item_to_restock.default_ammo != ammo_box.default_ammo)
			if(item_to_restock.current_rounds == 0)
				item_to_restock.transfer_ammo(ammo_box, user, amount_to_transfer, TRUE)
				return COMPONENT_NO_AFTERATTACK
			continue

		item_to_restock.transfer_ammo(ammo_box, user, amount_to_transfer)
		return COMPONENT_NO_AFTERATTACK
