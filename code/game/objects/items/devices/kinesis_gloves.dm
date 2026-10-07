/// Telekinesis gauntlets.
///
/// TGMC has carried the telekinesis code over from the /tg/station13 lineage since
/// the fork, but nothing ever handed it out - no datum in the codebase enabled
/// TK_USER, so the whole system sat there unreachable. These gauntlets enable it.
///
/// Enabling it is the two lines documented at the top of code/_onclick/telekinesis.dm:
/// register the ranged attack handler and raise the TK_USER flag.

/obj/item/clothing/gloves/kinesis
	name = "\improper TK-7 telekinesis gauntlets"
	desc = "Engineered gauntlets that let the wearer hold and throw small objects without touching them. Must be switched on before use."
	icon = 'icons/obj/clothing/gloves.dmi'
	//TODO: dedicated sprites. Borrowed from the health analyzer gloves for now, and
	//deactive_state matches it, so switching on and off does not change the icon yet.
	icon_state = "medscan_gloves"
	worn_icon_state = "medscan_gloves"
	equip_slot_flags = ITEM_SLOT_GLOVES
	actions_types = list(/datum/action/item_action/toggle)
	///Whether the gauntlets may be switched on at all.
	var/toggleable = TRUE
	///Icon state shown while the gauntlets are switched off.
	var/deactive_state = "medscan_gloves"
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
		enable_field(user)

/obj/item/clothing/gloves/kinesis/unequipped(mob/user, slot)
	. = ..()
	disable_field(user)

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
		enable_field(wearer)
	else
		//Safe to call unconditionally - it only ever tears an existing field down.
		disable_field(wearer)
	wearer?.update_inv_gloves()

/obj/item/clothing/gloves/kinesis/update_icon_state()
	. = ..()
	icon_state = active ? initial(icon_state) : deactive_state

///Hands the wearer the telekinesis handler and raises TK_USER, which is what
///tk_grab checks on every tick to decide whether it may keep holding anything.
/obj/item/clothing/gloves/kinesis/proc/enable_field(mob/living/user)
	if(!istype(user))
		return
	RegisterSignal(user, COMSIG_MOB_ATTACK_RANGED, TYPE_PROC_REF(/mob/living, on_ranged_attack_tk))
	ENABLE_BITFIELD(user.status_flags, TK_USER)

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
