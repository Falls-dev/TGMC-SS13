/// TK-7 uses the TK_USER telekinesis handler; TK-5 overrides it with a cursor-controlled field.
/obj/item/clothing/gloves/kinesis
	name = "\improper TK-7 telekinesis gauntlets"
	desc = "Engineered gauntlets that let the wearer hold and throw small objects without touching them. Must be switched on before use."
	icon = 'icons/Mods-dmi/kinesis/Obj/kinesis.dmi'
	worn_icon_list = list(slot_gloves_str = 'icons/Mods-dmi/kinesis/Mob/kinesis.dmi')
	icon_state = "kinesis_gloves"
	equip_slot_flags = ITEM_SLOT_GLOVES
	actions_types = list(/datum/action/item_action/toggle)
	///Whether the gauntlets may be switched on at all.
	var/toggleable = TRUE
	///Inactive state shared by the inventory and worn icons.
	var/deactive_state = "kinesis_gloves_off"
	var/activation_sound = 'sound/effects/telekinesis/kinesis_grab.ogg'
	var/deactivation_sound = 'sound/effects/telekinesis/kinesis_powerloss.ogg'

/obj/item/clothing/gloves/kinesis/Initialize(mapload)
	. = ..()
	if(active) //for gauntlets that spawn switched on
		active = FALSE
		set_active(TRUE)

/obj/item/clothing/gloves/kinesis/examine(mob/user)
	. = ..()
	var/mob/living/carbon/human/wearer = loc
	if(istype(wearer) && CHECK_BITFIELD(wearer.status_flags, TK_USER))
		. += span_notice("Its field is live. Click a distant object to grab it, click again to throw or use it.")
	else if(active)
		. += span_notice("It is switched on but its field is not running. Take it off and put it back on.")
	else
		. += span_notice("It is switched off. Use the action button or alt-click yourself to switch it on.")

/obj/item/clothing/gloves/kinesis/attack_self(mob/user)
	if(toggleable && can_interact(user))
		set_active(!active)
		return TRUE

/obj/item/clothing/gloves/kinesis/equipped(mob/living/carbon/human/user, slot)
	. = ..()
	if(active && user.gloves == src)
		power_on_field(user)

/obj/item/clothing/gloves/kinesis/unequipped(mob/user, slot)
	. = ..()
	power_off_field(user)
	set_active(FALSE)

/obj/item/clothing/gloves/kinesis/dropped(mob/user)
	. = ..()
	power_off_field(user)

/obj/item/clothing/gloves/kinesis/ui_action_click(mob/user, datum/action/item_action/action)
	if(!istype(action, /datum/action/item_action/toggle))
		return ..()
	if(!toggleable || !can_interact(user))
		return FALSE
	set_active(!active)
	return TRUE

/obj/item/clothing/gloves/kinesis/proc/set_active(enabled)
	if(active == enabled)
		return
	active = enabled
	if(active)
		playsound(get_turf(src), activation_sound, 15)
	else
		playsound(get_turf(src), deactivation_sound, 15)
	update_icon()
	//Also activate when toggled after equipping.
	var/mob/living/carbon/human/wearer = loc
	if(istype(wearer) && wearer.gloves == src && active)
		power_on_field(wearer)
	else
		power_off_field(wearer)
	if(istype(wearer))
		wearer.update_inv_gloves()
	update_action_button_icons()
	if(istype(wearer))
		to_chat(wearer, active ? "You power up the telekinesis field." : "You shut the telekinesis field down.")

///Overridden by TK-5 to select its field implementation.
/obj/item/clothing/gloves/kinesis/proc/power_on_field(mob/living/user)
	enable_field(user)

/obj/item/clothing/gloves/kinesis/proc/power_off_field(mob/living/user)
	disable_field(user)

/obj/item/clothing/gloves/kinesis/update_icon_state()
	. = ..()
	icon_state = active ? initial(icon_state) : deactive_state

/obj/item/clothing/gloves/kinesis/proc/enable_field(mob/living/user)
	if(!istype(user))
		return
	RegisterSignal(user, COMSIG_MOB_ATTACK_RANGED, PROC_REF(on_ranged_attack_tk))
	ENABLE_BITFIELD(user.status_flags, TK_USER)

///Relay the signal to the wearer; the registered callback runs on the gauntlets.
/obj/item/clothing/gloves/kinesis/proc/on_ranged_attack_tk(mob/living/user, atom/target)
	user?.on_ranged_attack_tk(user, target)

///Release held items immediately when disabling the field.
/obj/item/clothing/gloves/kinesis/proc/disable_field(mob/living/user)
	if(!istype(user))
		return
	UnregisterSignal(user, COMSIG_MOB_ATTACK_RANGED)
	DISABLE_BITFIELD(user.status_flags, TK_USER)
	for(var/obj/item/tk_grab/held in user.get_held_items())
		held.focus = null
		user.temporarilyRemoveItemFromInventory(held)
		qdel(held)

/// TK-5 uses a charged, cursor-controlled field instead of TK_USER.
/obj/item/clothing/gloves/kinesis/ds13
	name = "\improper TK-5 telekinesis gauntlets"
	desc = "Second generation telekinesis gauntlets. Reach out and the field hauls an object \
	into the space in front of you, where it hangs in a telekinetic grip until you throw it \
	or set it down."
	actions_types = list(
		/datum/action/item_action/toggle,
		/datum/action/item_action/kinesis_grab,
		/datum/action/item_action/kinesis_launch,
	)
	///The running field, if the gauntlets are on and worn.
	var/datum/kinesis_field/field

/obj/item/clothing/gloves/kinesis/ds13/examine(mob/user)
	. = ..()
	var/datum/kinesis_field/field_now = field
	if(isnull(field_now))
		if(active)
			. += span_notice("It is switched on but its field is not running. Take it off and put it back on.")
		else
			. += span_notice("It is switched off. Use the action button or alt-click yourself to switch it on.")
		. += span_notice("Its reserve reads full.")
		return
	var/pct = round(100 * field_now.charge / field_now.max_charge)
	var/status
	switch(pct)
		if(0)
			status = span_danger("empty")
		if(1 to 25)
			status = span_warning("[pct]%")
		else
			status = span_notice("[pct]%")
	. += span_notice("Its reserve reads [status].")
	if(active)
		if(field_now.is_gripping())
			. += span_notice("Its field is holding [field_now.subject].")
		else if(field_now.marking)
			. += span_notice("Its field is armed. Click the object you want it to take.")
		else
			. += span_notice("Its field is live. Use the grab key to arm it, then click the object you \
			want. Right click throws it where you are pointing, left click sets it down.")
	else
		. += span_notice("It is switched off.")

/obj/item/clothing/gloves/kinesis/ds13/power_on_field(mob/living/user)
	enable_field_ds(user)

/obj/item/clothing/gloves/kinesis/ds13/power_off_field(mob/living/user)
	disable_field_ds(user)

/obj/item/clothing/gloves/kinesis/ds13/Destroy()
	disable_field_ds()
	return ..()

/obj/item/clothing/gloves/kinesis/ds13/proc/enable_field_ds(mob/living/user)
	if(!istype(user) || field)
		return
	field = new(src, user)
	show_charge_hud(user)
	to_chat(user, span_notice("You power up the telekinesis field."))

/obj/item/clothing/gloves/kinesis/ds13/proc/disable_field_ds(mob/living/user)
	var/mob/living/owner = field?.user
	var/datum/kinesis_field/old_field = field
	//Detach before deletion releases the held object.
	field = null
	qdel(old_field)
	hide_charge_hud(owner ? owner : user)

///Visible to anyone who can see the wearer, including when the wearer has no client.
/obj/item/clothing/gloves/kinesis/ds13/proc/show_charge_hud(mob/living/user)
	set waitfor = FALSE
	var/mob/living/carbon/human/wearer = user
	if(!istype(wearer) || QDELETED(field))
		return
	wearer.kinesis_hud_set_charge(field.charge, field.max_charge)

/obj/item/clothing/gloves/kinesis/ds13/proc/hide_charge_hud(mob/living/user)
	set waitfor = FALSE
	var/mob/living/carbon/human/wearer = user
	if(!istype(wearer))
		return
	wearer.kinesis_hud_clear_charge()

///Arm target selection, or release the held object.
/obj/item/clothing/gloves/kinesis/ds13/proc/grab_or_place(mob/user)
	if(isnull(field))
		return FALSE
	return field.toggle_marker()

/obj/item/clothing/gloves/kinesis/ds13/ui_action_click(mob/user, datum/action/item_action/action)
	if(istype(action, /datum/action/item_action/kinesis_launch))
		if(!istype(user) || !can_interact(user))
			return FALSE
		if(!field?.is_gripping())
			user.balloon_alert(user, "Nothing held.")
			return FALSE
		return field.launch()
	if(istype(action, /datum/action/item_action/kinesis_grab))
		if(!istype(user) || !can_interact(user))
			return FALSE
		return grab_or_place(user)
	return ..()

///Right-click throws; left-click places. The field handles both through COMSIG_MOB_CLICKON.
/datum/action/item_action/kinesis_launch
	name = "Throw held object"
	desc = "Throw whatever the field is holding in the direction you are looking."

/datum/action/item_action/kinesis_grab
	name = "Telekinetic grab"
	desc = "Arms the field, then click the thing you want taken. Use again to set it down."
	keybinding_signals = list(KEYBINDING_NORMAL = COMSIG_ITEM_KINESIS_GRAB)
