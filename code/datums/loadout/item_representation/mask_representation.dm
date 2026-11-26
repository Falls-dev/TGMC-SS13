/**
 * Representation for masks that can have attachments (like the ICC trophy lenses)
 */
/datum/item_representation/mask
	var/list/datum/item_representation/armor_module/attachments = list()

/datum/item_representation/mask/New(obj/item/item_to_copy)
	if(!item_to_copy)
		return
	if(!istype(item_to_copy, /obj/item/clothing/mask))
		CRASH("/datum/item_representation/mask created from an item that is not a mask")
	. = ..()
	var/obj/item/clothing/mask/mask_to_copy = item_to_copy
	for(var/key in mask_to_copy.attachments_by_slot)
		if(!isitem(mask_to_copy.attachments_by_slot[key]))
			continue
		attachments += new /datum/item_representation/armor_module(mask_to_copy.attachments_by_slot[key])

/datum/item_representation/mask/instantiate_object(datum/loadout_seller/seller, master = null, mob/living/user)
	. = ..()
	if(!.)
		return
	var/obj/item/clothing/mask/new_mask = .
	for(var/datum/item_representation/armor_module/armor_attachement AS in attachments)
		armor_attachement.install_on_armor(seller, new_mask, user)
	new_mask.update_icon()

/datum/item_representation/mask/get_tgui_data()
	var/list/tgui_data = list()
	tgui_data["name"] = initial(item_type.name)
	tgui_data["icons"] = list()

	var/icon/icon_to_convert
	var/icon_state = initial(item_type.icon_state)

	if(initial(item_type.greyscale_config))
		icon_to_convert = icon(SSgreyscale.GetColoredIconByType(initial(item_type.greyscale_config), colors), icon_state, dir = SOUTH)
	else
		icon_to_convert = icon(initial(item_type.icon), icon_state, SOUTH)

	tgui_data["icons"] += list(list(
		"icon" = icon2base64(icon_to_convert),
		"translateX" = NO_OFFSET,
		"translateY" = NO_OFFSET,
		"scale" = 1,
	))

	for(var/datum/item_representation/armor_module/module AS in attachments)
		if(!initial(module.item_type.icon_state))
			continue

		var/second_icon_state = initial(module.item_type.icon_state)
		if(initial(module.item_type.greyscale_config))
			icon_to_convert = icon(SSgreyscale.GetColoredIconByType(initial(module.item_type.greyscale_config), module.colors), second_icon_state, dir = SOUTH)
		else
			icon_to_convert = icon(initial(module.item_type.icon), second_icon_state, SOUTH)

		tgui_data["icons"] += list(list(
			"icon" = icon2base64(icon_to_convert),
			"translateX" = NO_OFFSET,
			"translateY" = NO_OFFSET,
			"scale" = 1,
		))

	return tgui_data
