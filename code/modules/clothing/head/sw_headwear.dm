// GTA:SA bandanas — worn sprites from head_0.dmi

/obj/item/clothing/head/fun
	icon = 'icons/mob/clothing/headwear/head_0.dmi'
	worn_icon_list = list(
		slot_head_str = 'icons/mob/clothing/headwear/head_0.dmi',
		slot_l_hand_str = 'icons/mob/inhands/clothing/hats_left.dmi',
		slot_r_hand_str = 'icons/mob/inhands/clothing/hats_right.dmi',
	)

/obj/item/clothing/head/fun/bandana_ballas
	name = "\improper Ballas bandana"
	desc = "A purple bandana tied in the front."
	icon_state = "bandana_ballas"
	worn_icon_state = "bandana_ballas"
	inv_hide_flags = HIDETOPHAIR

/obj/item/clothing/head/fun/bandana_grove
	name = "\improper Grove Street bandana"
	desc = "A green bandana tied in the front."
	icon_state = "bandana_grove"
	worn_icon_state = "bandana_grove"
	inv_hide_flags = HIDETOPHAIR

// Star Wars headwear — worn sprites from sw_helmets.dmi

/obj/item/clothing/head/sw
	icon = 'icons/mob/clothing/headwear/sw_helmets.dmi'
	worn_icon_list = list(
		slot_head_str = 'icons/mob/clothing/headwear/sw_helmets.dmi',
		slot_l_hand_str = 'icons/mob/inhands/clothing/hats_left.dmi',
		slot_r_hand_str = 'icons/mob/inhands/clothing/hats_right.dmi',
	)

/obj/item/clothing/head/sw/cap
	armor_protection_flags = HEAD
	soft_armor = list(MELEE = 10, BULLET = 5, LASER = 5, ENERGY = 5, BOMB = 0, BIO = 0, FIRE = 0, ACID = 0)

/obj/item/clothing/head/helmet/marine/sw
	icon = 'icons/mob/clothing/headwear/sw_helmets.dmi'
	worn_icon_list = list(
		slot_head_str = 'icons/mob/clothing/headwear/sw_helmets.dmi',
		slot_l_hand_str = 'icons/mob/inhands/clothing/hats_left.dmi',
		slot_r_hand_str = 'icons/mob/inhands/clothing/hats_right.dmi',
	)
	attachments_allowed = list()
	starting_attachments = list()
	marine_helmet_flags = NONE
	armor_protection_flags = HEAD
	soft_armor = list(MELEE = 30, BULLET = 35, LASER = 40, ENERGY = 35, BOMB = 25, BIO = 0, FIRE = 10, ACID = 5)
	inventory_flags = COVEREYES|BLOCKSHARPOBJ
	inv_hide_flags = HIDEEARS|HIDEEYES|HIDETOPHAIR

/obj/item/clothing/head/helmet/marine/sw/heavy
	soft_armor = list(MELEE = 45, BULLET = 50, LASER = 55, ENERGY = 50, BOMB = 35, BIO = 0, FIRE = 15, ACID = 10)

/obj/item/clothing/head/helmet/marine/sw/rebel
	name = "\improper Rebel trooper helmet"
	desc = "A reinforced plastoid helmet of the Rebel Alliance."
	icon_state = "rebel_helmet"
	worn_icon_state = "rebel_helmet"

/obj/item/clothing/head/helmet/marine/sw/rebel/black
	name = "\improper Rebel trooper helmet, dark"
	desc = "A dark variant of the Rebel Alliance trooper helmet."
	icon_state = "rebel_helmet_black"
	worn_icon_state = "rebel_helmet_black"

/obj/item/clothing/head/helmet/marine/sw/clone/phase2
	name = "\improper Phase II clone trooper helmet"
	desc = "A phase II helmet used by clone troopers of the Grand Army of the Republic."
	icon_state = "replicant_helmet2"
	worn_icon_state = "replicant_helmet2"

/obj/item/clothing/head/helmet/marine/sw/clone/legion501
	name = "\improper 501st Legion clone trooper helmet"
	desc = "A phase II helmet bearing the blue markings of the 501st Legion."
	icon_state = "replicant2_501st"
	worn_icon_state = "replicant2_501st"

/obj/item/clothing/head/helmet/marine/sw/clone/battalion212
	name = "\improper 212th Battalion clone trooper helmet"
	desc = "A phase II helmet bearing the orange markings of the 212th Attack Battalion."
	icon_state = "replicant2_212th"
	worn_icon_state = "replicant2_212th"

/obj/item/clothing/head/helmet/marine/sw/clone/scout
	name = "\improper Clone scout trooper helmet"
	desc = "A phase II helmet with additional plates for arctic and recon operations."
	icon_state = "replicant_bilizard"
	worn_icon_state = "replicant_bilizard"

/obj/item/clothing/head/helmet/marine/sw/clone/radiotech
	name = "\improper Clone radiotech helmet"
	desc = "A clone trooper helmet fitted with a long-range communications antenna."
	icon_state = "replicant_radiotech"
	worn_icon_state = "replicant_radiotech"

/obj/item/clothing/head/helmet/marine/sw/clone/commando
	name = "\improper Clone commando helmet"
	desc = "A plastoid helmet used by clone commandos of the Republic Army."
	icon_state = "replicant_commando"
	worn_icon_state = "replicant_commando"

/obj/item/clothing/head/helmet/marine/sw/clone/artillery
	name = "\improper Clone artillery crew helmet"
	desc = "A clone trooper helmet used by vehicle and artillery crews."
	icon_state = "replicant_art"
	worn_icon_state = "replicant_art"

/obj/item/clothing/head/helmet/marine/sw/clone/engineer
	name = "\improper Clone engineer helmet"
	desc = "A reinforced plastoid engineer helmet of the Republic Army."
	icon_state = "replicant_engi"
	worn_icon_state = "replicant_engi"

/obj/item/clothing/head/helmet/marine/sw/clone/phase1
	name = "\improper Phase I clone trooper helmet"
	desc = "A reinforced plastoid phase I helmet of the Grand Army of the Republic."
	icon_state = "replicant_helmet"
	worn_icon_state = "replicant_helmet"

/obj/item/clothing/head/helmet/marine/sw/clone/sgt
	name = "\improper Clone sergeant helmet, phase I"
	desc = "A phase I helmet with green markings denoting sergeant rank."
	icon_state = "repsgt_helmet"
	worn_icon_state = "repsgt_helmet"

/obj/item/clothing/head/helmet/marine/sw/clone/lt
	name = "\improper Clone lieutenant helmet, phase I"
	desc = "A phase I helmet with blue markings denoting lieutenant rank."
	icon_state = "replt_helmet"
	worn_icon_state = "replt_helmet"

/obj/item/clothing/head/helmet/marine/sw/clone/captain
	name = "\improper Clone captain helmet, phase I"
	desc = "A phase I helmet with red markings denoting captain rank."
	icon_state = "repcaptain_helmet"
	worn_icon_state = "repcaptain_helmet"

/obj/item/clothing/head/helmet/marine/sw/clone/pilot
	name = "\improper Clone pilot helmet, phase I"
	desc = "A reinforced plastoid pilot helmet of the Republic Navy."
	icon_state = "reppilot_helmet"
	worn_icon_state = "reppilot_helmet"

/obj/item/clothing/head/helmet/marine/sw/clone/commander
	name = "\improper Clone commander helmet, phase I"
	desc = "A phase I helmet with yellow markings denoting commander rank."
	icon_state = "repcommander_helmet"
	worn_icon_state = "repcommander_helmet"

/obj/item/clothing/head/helmet/marine/sw/clone/mp
	name = "\improper Clone military police helmet"
	desc = "A highly reinforced plastoid helmet of the Republic military police."
	icon_state = "repmp_helmet"
	worn_icon_state = "repmp_helmet"

/obj/item/clothing/head/sw/cap/repensign
	name = "\improper Republic Navy ensign cap"
	desc = "A tight-fitting blue-grey officer's cap."
	icon_state = "repensign_cap"
	worn_icon_state = "repensign_cap"

/obj/item/clothing/head/sw/cap/repnavalcaptain
	name = "\improper Republic Navy captain cap"
	desc = "A tight-fitting green officer's cap."
	icon_state = "repnavalcaptain_cap"
	worn_icon_state = "repnavalcaptain_cap"

/obj/item/clothing/head/sw/cap/repofficer_ensign
	name = "\improper Imperial officer cap"
	desc = "A tight-fitting grey officer's cap from the post-war Imperial Navy."
	icon_state = "repofficer_ensign"
	worn_icon_state = "repofficer_ensign"

/obj/item/clothing/head/sw/cap/repofficer_med
	name = "\improper Republic medical officer cap"
	desc = "A tight-fitting grey medical officer's cap."
	icon_state = "repofficer_med"
	worn_icon_state = "repofficer_med"

/obj/item/clothing/head/sw/cap/repofficer_navcaptain
	name = "\improper Imperial Navy captain cap"
	desc = "A tight-fitting green Imperial Navy captain's cap."
	icon_state = "repofficer_navcaptain"
	worn_icon_state = "repofficer_navcaptain"

/obj/item/clothing/head/sw/cap/imp_stormofficer
	name = "\improper Imperial stormtrooper officer cap"
	desc = "A tight-fitting black field cap worn by Stormtrooper Corps officers."
	icon_state = "impofficer_stormofficer"
	worn_icon_state = "impofficer_stormofficer"

/obj/item/clothing/head/helmet/marine/sw/repstormtrooper
	name = "\improper Republic shock trooper helmet"
	desc = "A reinforced helmet of the Republic's elite shock trooper corps."
	icon_state = "repstormtrooper_helmet"
	worn_icon_state = "repstormtrooper_helmet"

/obj/item/clothing/head/helmet/marine/sw/imperial/airborne
	name = "\improper Imperial airborne trooper helmet"
	desc = "A reinforced airborne helmet of the Imperial Army."
	icon_state = "repairborne_helmet"
	worn_icon_state = "repairborne_helmet"

/obj/item/clothing/head/helmet/marine/sw/clone/corps41
	name = "\improper 41st Elite Corps clone trooper helmet"
	desc = "A helmet bearing the distinctive markings of the 41st Elite Corps."
	icon_state = "rep4RF_helmet"
	worn_icon_state = "rep4RF_helmet"

/obj/item/clothing/head/helmet/marine/sw/imp_stormofficer
	name = "\improper Imperial stormtrooper officer helmet"
	desc = "A reinforced helmet worn by officers of the Imperial Stormtrooper Corps."
	icon_state = "impofficer_stormofficer"
	worn_icon_state = "impofficer_stormofficer"

/obj/item/clothing/head/helmet/marine/sw/redguard
	name = "\improper Imperial Royal Guard helmet"
	desc = "A reinforced plastoid helmet of the Emperor's Royal Guard."
	icon_state = "redguard"
	worn_icon_state = "redguard"

/obj/item/clothing/head/helmet/marine/sw/senateguard
	name = "\improper Senate Guard helmet"
	desc = "A reinforced plastoid helmet of the Galactic Senate Guard."
	icon_state = "senateguard"
	worn_icon_state = "senateguard"

/obj/item/clothing/head/helmet/marine/sw/stormsurgeon
	name = "\improper Imperial stormtrooper surgeon helmet"
	desc = "A reinforced helmet of the Imperial Medical Corps field surgeons."
	icon_state = "sturmsurgeon_helmet"
	worn_icon_state = "sturmsurgeon_helmet"

/obj/item/clothing/head/helmet/marine/sw/stormradio
	name = "\improper Imperial stormtrooper radioman helmet"
	desc = "A lighter stormtrooper helmet fitted for long-range communications."
	icon_state = "stormradio_helmet"
	worn_icon_state = "stormradio_helmet"
