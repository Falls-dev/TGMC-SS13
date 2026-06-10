// Star Wars suits and armor — worn sprites from sw_suits.dmi

/obj/item/clothing/suit/sw
	icon = 'icons/mob/clothing/suits/sw_suits.dmi'
	worn_icon_state_worn = TRUE
	worn_icon_list = list(
		slot_wear_suit_str = 'icons/mob/clothing/suits/sw_suits.dmi',
		slot_l_hand_str = 'icons/mob/inhands/clothing/suits_left.dmi',
		slot_r_hand_str = 'icons/mob/inhands/clothing/suits_right.dmi',
	)
	blood_overlay_type = "armor"

/obj/item/clothing/suit/storage/marine/sw/rebel/vest
	name = "\improper Rebel trooper vest"
	desc = "A simple armored vest worn by Rebel Alliance troopers."
	icon = 'icons/mob/clothing/suits/sw_suits.dmi'
	icon_state = "rebel_vest"
	worn_icon_state = "rebel_vest"
	worn_icon_state_worn = TRUE
	worn_icon_list = list(
		slot_wear_suit_str = 'icons/mob/clothing/suits/sw_suits.dmi',
		slot_l_hand_str = 'icons/mob/inhands/clothing/suits_left.dmi',
		slot_r_hand_str = 'icons/mob/inhands/clothing/suits_right.dmi',
	)
	armor_features_flags = NONE
	actions_types = list()
	slowdown = 0
	allowed = list(/obj/item/weapon/gun)
	armor_protection_flags = CHEST|GROIN
	soft_armor = list(MELEE = 20, BULLET = 25, LASER = 20, ENERGY = 15, BOMB = 10, BIO = 0, FIRE = 5, ACID = 5)

/obj/item/clothing/suit/storage/marine/sw/rebel/vest/officer
	name = "\improper Rebel officer vest"
	desc = "A khaki and orange vest worn by officers of the Rebel Alliance."
	icon_state = "rebel_officer_vest"
	worn_icon_state = "rebel_officer_vest"
	soft_armor = list(MELEE = 25, BULLET = 30, LASER = 25, ENERGY = 20, BOMB = 15, BIO = 0, FIRE = 5, ACID = 5)

/obj/item/clothing/suit/storage/marine/sw
	icon = 'icons/mob/clothing/suits/sw_suits.dmi'
	worn_icon_state_worn = TRUE
	worn_icon_list = list(
		slot_wear_suit_str = 'icons/mob/clothing/suits/sw_suits.dmi',
		slot_l_hand_str = 'icons/mob/inhands/clothing/suits_left.dmi',
		slot_r_hand_str = 'icons/mob/inhands/clothing/suits_right.dmi',
	)
	armor_features_flags = NONE
	actions_types = list()
	blood_overlay_type = "armor"
	armor_protection_flags = CHEST|GROIN|LEGS|ARMS
	slowdown = SLOWDOWN_ARMOR_LIGHT
	w_class = WEIGHT_CLASS_HUGE
	allowed = list(/obj/item/weapon/gun)

/obj/item/clothing/suit/storage/marine/sw/clone
	name = "\improper Clone trooper armor"
	desc = "Standard plastoid armor covering most of the body."
	icon_state = "replicant_armor"
	worn_icon_state = "replicant_armor"
	soft_armor = list(MELEE = 35, BULLET = 40, LASER = 45, ENERGY = 35, BOMB = 40, BIO = 0, FIRE = 10, ACID = 10)

/obj/item/clothing/suit/storage/marine/sw/clone/pilot
	name = "\improper Clone pilot armor"
	desc = "Light plastoid armor used by Republic Navy pilots."
	icon_state = "reppilot_armor"
	worn_icon_state = "reppilot_armor"
	soft_armor = list(MELEE = 25, BULLET = 30, LASER = 35, ENERGY = 30, BOMB = 30, BIO = 0, FIRE = 10, ACID = 5)
	slowdown = 0

/obj/item/clothing/suit/storage/marine/sw/clone/mp
	name = "\improper Clone military police armor"
	desc = "Heavy plastoid armor used by Republic military police."
	icon_state = "repmp_armor"
	worn_icon_state = "repmp_armor"
	soft_armor = list(MELEE = 40, BULLET = 45, LASER = 40, ENERGY = 35, BOMB = 45, BIO = 0, FIRE = 10, ACID = 10)

/obj/item/clothing/suit/storage/marine/sw/clone/sgt
	name = "\improper Clone sergeant armor"
	desc = "Plastoid armor with green markings denoting sergeant rank."
	icon_state = "repsgt_armor"
	worn_icon_state = "repsgt_armor"
	soft_armor = list(MELEE = 38, BULLET = 42, LASER = 45, ENERGY = 38, BOMB = 42, BIO = 0, FIRE = 10, ACID = 10)

/obj/item/clothing/suit/storage/marine/sw/clone/lieutenant
	name = "\improper Clone lieutenant armor"
	desc = "Plastoid armor with blue markings denoting lieutenant rank."
	icon_state = "replieutenant_armor"
	worn_icon_state = "replieutenant_armor"
	soft_armor = list(MELEE = 38, BULLET = 42, LASER = 45, ENERGY = 38, BOMB = 42, BIO = 0, FIRE = 10, ACID = 10)

/obj/item/clothing/suit/storage/marine/sw/clone/captain
	name = "\improper Clone captain armor"
	desc = "Plastoid armor with red markings denoting captain rank."
	icon_state = "repcaptain_armor"
	worn_icon_state = "repcaptain_armor"
	soft_armor = list(MELEE = 40, BULLET = 45, LASER = 48, ENERGY = 40, BOMB = 45, BIO = 0, FIRE = 10, ACID = 10)

/obj/item/clothing/suit/storage/marine/sw/clone/commander
	name = "\improper Clone commander armor"
	desc = "Plastoid armor with yellow markings denoting commander rank."
	icon_state = "repcommander_armor"
	worn_icon_state = "repcommander_armor"
	soft_armor = list(MELEE = 42, BULLET = 48, LASER = 50, ENERGY = 42, BOMB = 48, BIO = 0, FIRE = 10, ACID = 10)

/obj/item/clothing/suit/storage/marine/sw/clone/mp/phase2
	name = "\improper Clone military police armor, phase II"
	desc = "Updated phase II armor used by Republic military police."
	icon_state = "repmp_phase2armor"
	worn_icon_state = "repmp_phase2armor"
	soft_armor = list(MELEE = 42, BULLET = 48, LASER = 45, ENERGY = 40, BOMB = 48, BIO = 0, FIRE = 10, ACID = 10)

/obj/item/clothing/suit/storage/marine/sw/clone/legion501
	name = "\improper 501st Legion clone armor"
	desc = "Phase II plastoid armor bearing the blue markings of the 501st Legion."
	icon_state = "rep_501st"
	worn_icon_state = "rep_501st"
	soft_armor = list(MELEE = 38, BULLET = 42, LASER = 48, ENERGY = 38, BOMB = 42, BIO = 0, FIRE = 10, ACID = 10)

/obj/item/clothing/suit/storage/marine/sw/clone/battalion212
	name = "\improper 212th Battalion clone armor"
	desc = "Phase II plastoid armor bearing the orange markings of the 212th Attack Battalion."
	icon_state = "rep_212th"
	worn_icon_state = "rep_212th"
	soft_armor = list(MELEE = 38, BULLET = 42, LASER = 48, ENERGY = 38, BOMB = 42, BIO = 0, FIRE = 10, ACID = 10)

/obj/item/clothing/suit/storage/marine/sw/clone/battalion442
	name = "\improper 442nd Siege Battalion clone armor"
	desc = "Phase II plastoid armor bearing the markings of the 442nd Siege Battalion."
	icon_state = "rep_442nd"
	worn_icon_state = "rep_442nd"
	soft_armor = list(MELEE = 38, BULLET = 42, LASER = 48, ENERGY = 38, BOMB = 42, BIO = 0, FIRE = 10, ACID = 10)

/obj/item/clothing/suit/storage/marine/sw/clone/commando
	name = "\improper Clone commando armor"
	desc = "Heavy plastoid armor used by clone commandos."
	icon_state = "repcommando"
	worn_icon_state = "repcommando"
	soft_armor = list(MELEE = 45, BULLET = 50, LASER = 52, ENERGY = 45, BOMB = 50, BIO = 0, FIRE = 15, ACID = 10)
	slowdown = SLOWDOWN_ARMOR_MEDIUM

/obj/item/clothing/suit/storage/marine/sw/clone/reinforced
	name = "\improper Reinforced clone trooper armor"
	desc = "Heavy plastoid armor with an additional blast plate."
	icon_state = "repreinforced"
	worn_icon_state = "repreinforced"
	soft_armor = list(MELEE = 45, BULLET = 55, LASER = 50, ENERGY = 45, BOMB = 55, BIO = 0, FIRE = 15, ACID = 10)
	slowdown = SLOWDOWN_ARMOR_MEDIUM

/obj/item/clothing/suit/storage/marine/sw/darth
	name = "\improper Dark Lord armor"
	desc = "A dark mechanical life-support suit. Breathing sounds ominously mechanical."
	icon_state = "darth_armor"
	worn_icon_state = "darth_armor"
	soft_armor = list(MELEE = 60, BULLET = 65, LASER = 70, ENERGY = 65, BOMB = 70, BIO = 50, FIRE = 80, ACID = 50)
	slowdown = SLOWDOWN_ARMOR_HEAVY

/obj/item/clothing/suit/storage/marine/sw/stormtrooper
	name = "\improper Stormtrooper armor"
	desc = "Standard Imperial plastoid armor covering most of the body."
	icon_state = "stormtrooper_armor"
	worn_icon_state = "stormtrooper_armor"
	soft_armor = list(MELEE = 38, BULLET = 45, LASER = 40, ENERGY = 35, BOMB = 40, BIO = 0, FIRE = 10, ACID = 10)

/obj/item/clothing/suit/storage/marine/sw/stormsurgeon
	name = "\improper Imperial stormtrooper surgeon armor"
	desc = "Stormtrooper armor with mint green highlights for field medics."
	icon_state = "sturmsurgeon_armor"
	worn_icon_state = "sturmsurgeon_armor"
	soft_armor = list(MELEE = 35, BULLET = 40, LASER = 38, ENERGY = 32, BOMB = 35, BIO = 0, FIRE = 10, ACID = 10)

/obj/item/clothing/suit/storage/marine/sw/stormradio
	name = "\improper Imperial stormtrooper radioman armor"
	desc = "Lightened stormtrooper armor with removed plates for added mobility."
	icon_state = "stormradio_armor"
	worn_icon_state = "stormradio_armor"
	soft_armor = list(MELEE = 28, BULLET = 32, LASER = 30, ENERGY = 28, BOMB = 25, BIO = 0, FIRE = 5, ACID = 5)
	slowdown = 0

/obj/item/clothing/suit/storage/marine/sw/redguard
	name = "\improper Imperial Royal Guard armor"
	desc = "Extremely expensive plastoid armor with a crimson red robe attached."
	icon_state = "redguard"
	worn_icon_state = "redguard"
	soft_armor = list(MELEE = 55, BULLET = 60, LASER = 65, ENERGY = 60, BOMB = 65, BIO = 0, FIRE = 20, ACID = 15)
	slowdown = SLOWDOWN_ARMOR_LIGHT

/obj/item/clothing/suit/storage/marine/sw/senateguard
	name = "\improper Senate Guard armor"
	desc = "Extremely expensive plastoid armor with a royal blue robe attached."
	icon_state = "senateguard"
	worn_icon_state = "senateguard"
	soft_armor = list(MELEE = 55, BULLET = 65, LASER = 65, ENERGY = 60, BOMB = 65, BIO = 0, FIRE = 20, ACID = 15)
	slowdown = SLOWDOWN_ARMOR_LIGHT
