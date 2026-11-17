/obj/item/weapon/gun/tacticoolspear
	name = "M-23 TACTICOOL spear"
	desc = "A TACTICOOL spear. Used for TACTICOOLNESS in combat."
	icon = 'icons/obj/items/weapons64.dmi'
	icon_state = "spear"
	worn_icon_state = "spear"
	worn_icon_list = list(
		slot_l_hand_str = 'icons/mob/inhands/weapons/twohanded_left.dmi',
		slot_r_hand_str = 'icons/mob/inhands/weapons/twohanded_right.dmi',
	)
	force = 40
	w_class = WEIGHT_CLASS_BULKY
	equip_slot_flags = ITEM_SLOT_BACK
	force_activated = 75
	throwforce = 75
	throw_speed = 3
	reach = 2
	edge = 1
	sharp = IS_SHARP_ITEM_SIMPLE
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("attacks", "stabs", "jabs", "tears", "gores")
	/// Kept for compatibility with spear state and its visual orientation.
	var/current_angle = 45
	gun_features_flags = NONE
	attachments_by_slot = list(ATTACHMENT_SLOT_UNDER)
	attachable_allowed = list(
		/obj/item/attachable/flashlight,
		/obj/item/weapon/gun/pistol/plasma_pistol,
		/obj/item/weapon/gun/shotgun/combat/masterkey,
		/obj/item/weapon/gun/flamer/mini_flamer,
		/obj/item/weapon/gun/grenade_launcher/underslung,
		/obj/item/weapon/gun/rifle/pepperball/pepperball_mini,
		/obj/item/weapon/gun/energy/lasgun/lasrifle/pocket_beam,
	)
	attachable_offset = list("muzzle_x" = 59, "muzzle_y" = 16, "rail_x" = 26, "rail_y" = 18, "under_x" = 40, "under_y" = 12)

/obj/item/weapon/gun/tacticoolspear/Initialize(mapload, spawn_empty)
	. = ..()
	AddElement(/datum/element/strappable)

/// The spear itself is melee-only; the normal gun firing signal is reserved for its active underbarrel attachment.
/obj/item/weapon/gun/tacticoolspear/start_fire(datum/source, atom/object, turf/location, control, params, bypass_checks = FALSE)
	var/list/modifiers = params2list(params)
	if(!modifiers["right"] || !active_attachable)
		return
	return ..()
