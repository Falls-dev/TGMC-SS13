// SW rebel armor — stats aligned to SOM light battle armor
/obj/item/clothing/suit/storage/faction/militia/rebel
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
	slowdown = 0
	// SOM light: modular/som/light
	soft_armor = list(MELEE = 35, BULLET = 60, LASER = 50, ENERGY = 50, BOMB = 45, BIO = 45, FIRE = 50, ACID = 40)

/obj/item/clothing/suit/storage/faction/militia/rebel/officer
	name = "\improper Rebel officer vest"
	desc = "A khaki and orange vest worn by officers of the Rebel Alliance."
	icon_state = "rebel_officer_vest"
	worn_icon_state = "rebel_officer_vest"
	soft_armor = list(MELEE = 40, BULLET = 65, LASER = 55, ENERGY = 55, BOMB = 50, BIO = 45, FIRE = 50, ACID = 45)
