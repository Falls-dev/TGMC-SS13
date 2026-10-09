/// Telekinesis gauntlets.
///
/// TGMC has carried the telekinesis code over from the /tg/station13 lineage since
/// the fork, but nothing ever handed it out - no datum in the codebase enabled
/// TK_USER, so the whole system sat there unreachable. These gauntlets enable it.
///
/// Enabling it is the two lines documented at the top of code/_onclick/telekinesis.dm:
/// register the ranged attack handler and raise the TK_USER flag.
///
/// Admin-only. Nothing in the codebase spawns, vendors or loadouts them, so they are
/// reachable through the spawn menu alone. Note that the telekinesis they expose is the
/// untouched /tg/station13 implementation: it has no line of sight check, no mass model
/// and no power cost, and clicking an anchored object falls through to a free ranged
/// unarmed attack. See telekinesis.dm for the details.
/obj/item/clothing/gloves/kinesis
	name = "\improper TK-7 telekinesis gauntlets"
	desc = "Engineered gauntlets that let the wearer hold and throw small objects without touching them. Must be switched on before use."
	icon = 'icons/obj/clothing/gloves.dmi'
	icon_state = "kinesis_gloves"
	equip_slot_flags = ITEM_SLOT_GLOVES
	actions_types = list(/datum/action/item_action/toggle)
	///Whether the gauntlets may be switched on at all.
	var/toggleable = TRUE
	///Icon state shown while the gauntlets are switched off.
	///Both "kinesis_gloves" and "kinesis_gloves_off" exist in two files with the same
	///state names: icons/obj/clothing/gloves.dmi for the inventory icon and
	///icons/mob/clothing/hands.dmi for the one drawn on the wearer, so flipping
	///icon_state is enough to switch both at once.
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

///The field only exists while the gauntlets are worn, so switching them on while
///they sit in a backpack does nothing, and equipping them while on starts working.
/obj/item/clothing/gloves/kinesis/equipped(mob/living/carbon/human/user, slot)
	. = ..()
	if(active && user.gloves == src)
		power_on_field(user)

/obj/item/clothing/gloves/kinesis/unequipped(mob/user, slot)
	. = ..()
	disable_field(user)
	//Taking them off switches them off. It used to only tear the field down, which left the gauntlets
	//sitting switched on in a backpack - and anything already held went with the field rather than
	//being handed back to a wearer who no longer had the gloves on. Off is also the honest state: if
	//they are on the floor or in a bag they are doing nothing.
	set_active(FALSE)

/obj/item/clothing/gloves/kinesis/dropped(mob/user)
	. = ..()
	disable_field(user)

/obj/item/clothing/gloves/kinesis/ui_action_click(mob/user, datum/action/item_action/action)
	if(!istype(action, /datum/action/item_action/toggle))
		return ..()
	if(!toggleable || !can_interact(user))
		return FALSE
	set_active(!active)
	return TRUE

///Flips the gauntlets and plays the matching sound. Initialization clears active
///first so a gauntlet that spawns switched on does not make the switch-on noise.
/obj/item/clothing/gloves/kinesis/proc/set_active(enabled)
	if(active == enabled)
		return
	active = enabled
	if(active)
		playsound(get_turf(src), activation_sound, 15)
	else
		playsound(get_turf(src), deactivation_sound, 15)
	update_icon()
	//Switching on has to reach the wearer here, not just from equipped(), otherwise
	//wearing them first and switching on second leaves the field down forever.
	var/mob/living/carbon/human/wearer = loc
	if(istype(wearer) && wearer.gloves == src && active)
		power_on_field(wearer)
	else
		//Safe to call unconditionally - it only ever tears an existing field down.
		power_off_field(wearer)
	wearer?.update_inv_gloves()
	update_action_button_icons()
	if(istype(wearer))
		to_chat(wearer, active ? "You power up the telekinesis field." : "You shut the telekinesis field down.")

///The single point where "the field goes live" is decided. Two different fields hang off
///these gauntlets, so subclasses redirect them rather than duplicating set_active.
/obj/item/clothing/gloves/kinesis/proc/power_on_field(mob/living/user)
	enable_field(user)

/obj/item/clothing/gloves/kinesis/proc/power_off_field(mob/living/user)
	disable_field(user)

/obj/item/clothing/gloves/kinesis/update_icon_state()
	. = ..()
	icon_state = active ? initial(icon_state) : deactive_state

///Hands the wearer the telekinesis handler and raises TK_USER, which is what
///tk_grab checks on every tick to decide whether it may keep holding anything.
/obj/item/clothing/gloves/kinesis/proc/enable_field(mob/living/user)
	if(!istype(user))
		return
	RegisterSignal(user, COMSIG_MOB_ATTACK_RANGED, PROC_REF(on_ranged_attack_tk))
	ENABLE_BITFIELD(user.status_flags, TK_USER)

///A proc reference is invoked on the object it was written in, not on the mob the signal
///was registered on. Registering TYPE_PROC_REF(/mob/living, on_ranged_attack_tk) instead
///tries to run the handler on the gauntlets and throws a runtime error on every click, so
///the call is relayed through the wearer. No SIGNAL_HANDLER here, so laser eyes and
///anything else on COMSIG_MOB_ATTACK_RANGED keep working alongside telekinesis.
/obj/item/clothing/gloves/kinesis/proc/on_ranged_attack_tk(mob/living/user, atom/target)
	user?.on_ranged_attack_tk(user, target)

///Removes access. Anything already held is let go straight away rather than waiting
///for tk_grab to notice the dropped flag on its next process tick, so the wearer
///cannot throw what they are holding one last time after switching off.
/obj/item/clothing/gloves/kinesis/proc/disable_field(mob/living/user)
	if(!istype(user))
		return
	//Two arguments only - this codebase overrides UnregisterSignal and it drops every
	//listener this item has on that signal, not one named proc.
	UnregisterSignal(user, COMSIG_MOB_ATTACK_RANGED)
	DISABLE_BITFIELD(user.status_flags, TK_USER)
	for(var/obj/item/tk_grab/held in user.get_held_items())
		held.focus = null
		user.temporarilyRemoveItemFromInventory(held)
		qdel(held)

/// TK-5. Same shell as the TK-7, but the field is DS13's rather than the inherited
/// /tg/station13 telekinesis, so nothing here touches TK_USER or tk_grab.
///
/// Arranged the way a Half-Life 2 gravity gun is: mark a target, the field drags it in to arm's
/// reach, and past that it is a graphic floating ahead of wherever you are looking. Right click
/// throws it along your gaze, left click sets it down at the nearest spot you can reach. Nothing
/// is dragged across the map, so nothing can judder or pass through a wall.
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
	//The reserve is the field's whole limiting mechanic, so it is on the examine text rather than
	//only discoverable by spending it and being refused.
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

///Starts a DS13 field. This is the counterpart to enable_field, which is what raises
///TK_USER instead - the two fields share nothing but the gauntlets they are bolted to.
/obj/item/clothing/gloves/kinesis/ds13/proc/enable_field_ds(mob/living/user)
	if(!istype(user) || field)
		return
	field = new(src, user)
	to_chat(user, span_notice("You power up the telekinesis field."))

///Tears the field down, which lets go of whatever it was holding.
/obj/item/clothing/gloves/kinesis/ds13/proc/disable_field_ds(mob/living/user)
	if(!istype(user))
		return
	if(field)
		QDEL_NULL(field)

///Mark a target, or set down what is held. This is the action button's default job, and the one
///its key does. While the field is empty it arms the marker, and the next map click is what gets
///taken - so the wearer picks the object rather than the field picking the closest one.
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

///Right click throws it where the wearer is looking, left click sets it down. Both are handled
///by the field through COMSIG_MOB_CLICKON, since a worn item never sees its own Click.

///Plain item_action, not the toggle subtype: it has no on/off state of its own and must not
///flip the gauntlets, so it takes the item straight through ui_action_click.
/datum/action/item_action/kinesis_launch
	name = "Throw held object"
	desc = "Throw whatever the field is holding in the direction you are looking."

///Mark a target, or set down what is held. Keybound rather than left-click driven, because the
///left button is needed for setting things down and the right one for throwing.
/datum/action/item_action/kinesis_grab
	name = "Telekinetic grab"
	desc = "Arms the field, then click the thing you want taken. Use again to set it down."
	keybinding_signals = list(KEYBINDING_NORMAL = COMSIG_ITEM_KINESIS_GRAB)
