/**
 *
 *  Chestplates
 *
 */
/obj/item/armor_module/armor/chest
	icon_state = "chest"
	slot = ATTACHMENT_SLOT_CHESTPLATE
	greyscale_config = /datum/greyscale_config/armor_mk1/infantry

/obj/item/armor_module/armor/chest/marine
	name = "\improper Jaeger Pattern Medium Infantry chestplates"
	desc = "Designed for use with the Jaeger Combat Exoskeleton. It provides moderate protection and encumbrance when attached and is fairly easy to attach and remove from armor. Click on the armor frame to attach it. This armor appears to be marked as a Infantry armor piece."
	soft_armor = MARINE_ARMOR_MEDIUM
	slowdown = SLOWDOWN_ARMOR_MEDIUM

/obj/item/armor_module/armor/chest/marine/skirmisher
	name = "\improper Jaeger Pattern Light Skirmisher chestplates"
	desc = "Designed for use with the Jaeger Combat Exoskeleton. It provides minor protection and encumbrance when attached and is fairly easy to attach and remove from armor. Click on the armor frame to attach it. This armor appears to be marked as a Skirmisher armor piece."
	soft_armor = MARINE_ARMOR_LIGHT
	slowdown = SLOWDOWN_ARMOR_VERY_LIGHT
	greyscale_config = /datum/greyscale_config/armor_mk1/skirmisher

/obj/item/armor_module/armor/chest/marine/skirmisher/scout
	name = "\improper Jaeger Pattern Light Scout chestplates"
	desc = "Designed for use with the Jaeger Combat Exoskeleton. It provides minor protection and encumbrance when attached and is fairly easy to attach and remove from armor. Click on the armor frame to attach it. This armor appears to be marked as a Scout armor piece."
	greyscale_config = /datum/greyscale_config/armor_mk1/scout

/obj/item/armor_module/armor/chest/marine/skirmisher/trooper
	name = "\improper Jaeger Pattern Trooper chestplates"
	desc = "Designed for use with the Jaeger Combat Exoskeleton. It provides high protection and encumbrance when attached and is fairly easy to attach and remove from armor. Click on the armor frame to attach it. This armor appears to be marked as a Trooper armor piece."
	greyscale_config = /datum/greyscale_config/armor_mk1/trooper

/obj/item/armor_module/armor/chest/marine/assault
	name = "\improper Jaeger Pattern Heavy Assault chestplates"
	desc = "Designed for use with the Jaeger Combat Exoskeleton. It provides high protection and encumbrance when attached and is fairly easy to attach and remove from armor. Click on the armor frame to attach it. This armor appears to be marked as a Assault armor piece."
	soft_armor = MARINE_ARMOR_HEAVY
	slowdown = SLOWDOWN_ARMOR_HEAVY
	greyscale_config = /datum/greyscale_config/armor_mk1

/obj/item/armor_module/armor/chest/marine/eva
	name = "\improper Jaeger Pattern Medium EVA chestplates"
	desc = "Designed for use with the Jaeger Combat Exoskeleton. It provides moderate protection and encumbrance when attached and is fairly easy to attach and remove from armor. Click on the armor frame to attach it. This armor appears to be marked as a EVA armor piece."
	greyscale_config = /datum/greyscale_config/armor_mk1/eva

/obj/item/armor_module/armor/chest/marine/assault/eod
	name = "\improper Jaeger Pattern Heavy EOD chestplates"
	desc = "Designed for use with the Jaeger Combat Exoskeleton. It provides high protection and encumbrance when attached and is fairly easy to attach and remove from armor. Click on the armor frame to attach it. This armor appears to be marked as a EOD armor piece."
	greyscale_config = /datum/greyscale_config/armor_mk1/eod

/obj/item/armor_module/armor/chest/marine/helljumper
	name = "\improper Jaeger Pattern Hell Jumper chestplates"
	desc = "Designed for use with the Jaeger Combat Exoskeleton. It provides high protection and encumbrance when attached and is fairly easy to attach and remove from armor. Click on the armor frame to attach it. This armor appears to be marked as a Hell Jumper armor piece."
	greyscale_config = /datum/greyscale_config/armor_mk1/helljumper

/obj/item/armor_module/armor/chest/marine/ranger
	name = "\improper Jaeger Pattern Ranger chestplates"
	desc = "Designed for use with the Jaeger Combat Exoskeleton. It provides high protection and encumbrance when attached and is fairly easy to attach and remove from armor. Click on the armor frame to attach it. This armor appears to be marked as a Ranger armor piece."
	greyscale_config = /datum/greyscale_config/armor_mk1/ranger

/obj/item/armor_module/armor/chest/marine/mjolnir
	name = "\improper Jaeger Pattern Mjolnir chestplates"
	desc = "Designed for use with the Jaeger Combat Exoskeleton. It provides moderate protection and encumbrance when attached and is fairly easy to attach and remove from armor. Click on the armor frame to attach it. This armor appears to be marked as a Mjolnir armor piece."
	greyscale_config = /datum/greyscale_config/armor_mk1/mjolnir

/obj/item/armor_module/armor/chest/marine/kabuto
	name = "\improper Style Pattern Kabuto chestplates"
	desc = "Designed for use with the Jaeger Combat Exoskeleton. It provides high protection and encumbrance when attached and is fairly easy to attach and remove from armor. Click on the armor frame to attach it. This armor appears to be marked as a Kabuto armor piece."
	greyscale_config = /datum/greyscale_config/armor_mk1/kabuto

/obj/item/armor_module/armor/chest/marine/hotaru
	name = "\improper Style Pattern Hotaru chestplates"
	desc = "Designed for use with the Jaeger Combat Exoskeleton. It provides high protection and encumbrance when attached and is fairly easy to attach and remove from armor. Click on the armor frame to attach it. This armor appears to be marked as a Hotaru armor piece."
	greyscale_config = /datum/greyscale_config/armor_mk1/hotaru

/obj/item/armor_module/armor/chest/marine/dashe
	name = "\improper Style Pattern Dashe chestplates"
	desc = "Designed for use with the Jaeger Combat Exoskeleton. It provides high protection and encumbrance when attached and is fairly easy to attach and remove from armor. Click on the armor frame to attach it. This armor appears to be marked as a Dashe armor piece."
	greyscale_config = /datum/greyscale_config/armor_mk1/dashe

// Hardsuit Chest Plates
/obj/item/armor_module/armor/chest/marine/hardsuit
	icon_state_variants = list(
		"normal",
		"webbing",
	)
	current_variant = "normal"
	greyscale_colors = ARMOR_PALETTE_BLACK
	colorable_colors = ARMOR_PALETTES_LIST
	colorable_allowed = ICON_STATE_VARIANTS_ALLOWED|PRESET_COLORS_ALLOWED
	starting_attachments = list(/obj/item/armor_module/armor/secondary_color/chest/webbing)
	attachments_allowed = list(/obj/item/armor_module/armor/secondary_color/chest/webbing)
	attachments_by_slot = list(ATTACHMENT_SLOT_CHEST_SECONDARY_COLOR)

/obj/item/armor_module/armor/chest/marine/hardsuit/syndicate_markfive
	name = "\improper FleckTex Mark V Breacher chestplates"
	desc = "Designed for use with the FleckTex WY-01 Exoskeleton. It offers high protection when attached and is fairly easy to attach and remove from armor. Click on the armor frame to attach it. All arm plates have the same armor and slowdown, meaning that only changing the chestplate makes significant armor difference. This armor appears to be marked as a Mark V armor piece."
	soft_armor = MARINE_ARMOR_HEAVY
	slowdown = SLOWDOWN_ARMOR_HEAVY
	greyscale_config = /datum/greyscale_config/hardsuit_variant/syndicate_markfive

/obj/item/armor_module/armor/chest/marine/hardsuit/syndicate_markthree
	name = "\improper FleckTex Mark III Marauder chestplates"
	desc = "Designed for use with the FleckTex WY-01 Exoskeleton. It offers medium protection when attached and is fairly easy to attach and remove from armor. Click on the armor frame to attach it. All arm plates have the same armor and slowdown, meaning that only changing the chestplate makes significant armor difference. This armor appears to be marked as a Mark III armor piece."
	soft_armor = MARINE_ARMOR_MEDIUM
	slowdown = SLOWDOWN_ARMOR_MEDIUM
	greyscale_config = /datum/greyscale_config/hardsuit_variant/syndicate_markthree

/obj/item/armor_module/armor/chest/marine/hardsuit/syndicate_markone
	name = "\improper FleckTex Mark I Raider chestplates"
	desc = "Designed for use with the FleckTex WY-01 Exoskeleton. It offers ight protection when attached and is fairly easy to attach and remove from armor. Click on the armor frame to attach it. All arm plates have the same armor and slowdown, meaning that only changing the chestplate makes significant armor difference. This armor appears to be marked as a Mark I armor piece."
	soft_armor = MARINE_ARMOR_LIGHT
	slowdown = SLOWDOWN_ARMOR_VERY_LIGHT
	greyscale_config = /datum/greyscale_config/hardsuit_variant

//VSD Hardsuits
/obj/item/armor_module/armor/chest/marine/vsd_hardsuit
	name = "\improper Crasher Super-Heavy MT/41 'Phobos' chestplate"
	desc = "Designed for use with the CrashCore MT/P Exoskeleton. It provides a very good amount protection, with the cost of encumbrance when attached and is fairly easy to attach and remove from armor. Click on the armor frame to attach it. Meaning that only changing the chestplate makes significant armor difference. This armor appears to be marked as a 'Phobos' armor piece."
	soft_armor = MARINE_ARMOR_HEAVY
	slowdown = SLOWDOWN_ARMOR_HEAVY
	greyscale_config = /datum/greyscale_config/vsd_hardsuit
	starting_attachments = list(/obj/item/armor_module/armor/secondary_color/chest/visor_color)

/obj/item/armor_module/armor/chest/marine/vsd_hardsuit/clementia
	name = "\improper Crasher Super-Heavy MT/41 'Clementia' chestplate"
	desc = "Designed for use with the CrashCore MT/P Exoskeleton. It provides a very good amount protection, with the cost of encumbrance when attached and is fairly easy to attach and remove from armor. Click on the armor frame to attach it. Meaning that only changing the chestplate makes significant armor difference. This armor appears to be marked as a 'Clementia' armor piece."
	greyscale_config = /datum/greyscale_config/vsd_hardsuit/alt
	starting_attachments = list(/obj/item/armor_module/armor/secondary_color/chest)

/obj/item/armor_module/armor/chest/marine/vsd_hardsuit/hephaestus
	name = "\improper Crasher Super-Heavy MT/41 'Hephaestus' chestplate"
	desc = "Designed for use with the CrashCore MT/P Exoskeleton. It provides a very good amount protection, with the cost of encumbrance when attached and is fairly easy to attach and remove from armor. Click on the armor frame to attach it. Meaning that only changing the chestplate makes significant armor difference. This armor appears to be marked as a 'Hephaestus' armor piece."
	greyscale_config = /datum/greyscale_config/vsd_hardsuit/alt_two
	starting_attachments = list(/obj/item/armor_module/armor/secondary_color/chest)
