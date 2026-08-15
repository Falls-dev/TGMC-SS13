// =============================================================================
// SW clone / imperial armor
// Soft armor tiers mirror SOM ERT modular suits (medium / light / heavy / lorica)
// =============================================================================

/obj/item/clothing/suit/storage/marine/clone
	name = "\improper Clone trooper armor"
	desc = "Standard plastoid armor covering most of the body."
	icon = 'icons/mob/clothing/suits/sw_suits.dmi'
	worn_icon_state_worn = TRUE
	worn_icon_list = list(
		slot_wear_suit_str = 'icons/mob/clothing/suits/sw_suits.dmi',
		slot_l_hand_str = 'icons/mob/inhands/clothing/suits_left.dmi',
		slot_r_hand_str = 'icons/mob/inhands/clothing/suits_right.dmi',
	)
	icon_state = "replicant_armor"
	worn_icon_state = "replicant_armor"
	// SOM medium (modular/som)
	soft_armor = list(MELEE = 45, BULLET = 70, LASER = 60, ENERGY = 60, BOMB = 50, BIO = 50, FIRE = 55, ACID = 50)
	slowdown = SLOWDOWN_ARMOR_MEDIUM
	// Keep pocket in attachments_allowed so starting suit/storage pockets still attach
	// (outfit suit_contents / spawn_humans unit-tests require working suit storage).
	attachments_allowed = list(
		/obj/item/armor_module/module/better_shoulder_lamp,
		/obj/item/armor_module/module/pluto,
		/obj/item/armor_module/module/valkyrie_autodoc/som,
		/obj/item/armor_module/module/fire_proof/som,
		/obj/item/armor_module/module/tyr_extra_armor/som,
		/obj/item/armor_module/module/mimir_environment_protection/som,
		/obj/item/armor_module/module/eshield/som,
		/obj/item/armor_module/storage/pocket,
		/obj/item/armor_module/storage/general,
		/obj/item/armor_module/storage/ammo_mag,
		/obj/item/armor_module/storage/engineering,
		/obj/item/armor_module/storage/medical,
		/obj/item/armor_module/storage/general/som,
		/obj/item/armor_module/storage/engineering/som,
		/obj/item/armor_module/storage/medical/som,
		/obj/item/armor_module/storage/injector,
		/obj/item/armor_module/storage/grenade,
		/obj/item/armor_module/storage/integrated,
		/obj/item/armor_module/armor/badge,
	)
	icon_state_variants = list("black")
	current_variant = "black"
	allowed_uniform_type = /obj/item/clothing/under
	starting_attachments = list(/obj/item/armor_module/storage/pocket)

// ----- Republic -----

/obj/item/clothing/suit/storage/marine/clone/pilot
	name = "\improper Clone pilot armor"
	desc = "Light plastoid armor used by Republic Navy pilots."
	icon_state = "reppilot_armor"
	worn_icon_state = "reppilot_armor"
	soft_armor = list(MELEE = 35, BULLET = 60, LASER = 50, ENERGY = 50, BOMB = 45, BIO = 45, FIRE = 50, ACID = 40)
	slowdown = 0

/obj/item/clothing/suit/storage/marine/clone/mp
	name = "\improper Clone military police armor"
	desc = "Heavy plastoid armor used by Republic military police."
	icon_state = "repmp_armor"
	worn_icon_state = "repmp_armor"
	// SOM veteran / medium-heavy
	soft_armor = list(MELEE = 50, BULLET = 75, LASER = 65, ENERGY = 65, BOMB = 55, BIO = 55, FIRE = 60, ACID = 55)

/obj/item/clothing/suit/storage/marine/clone/sgt
	name = "\improper Clone sergeant armor"
	desc = "Plastoid armor with green markings denoting sergeant rank."
	icon_state = "repsgt_armor"
	worn_icon_state = "repsgt_armor"
	soft_armor = list(MELEE = 45, BULLET = 70, LASER = 60, ENERGY = 60, BOMB = 50, BIO = 50, FIRE = 55, ACID = 50)

/obj/item/clothing/suit/storage/marine/clone/lieutenant
	name = "\improper Clone lieutenant armor"
	desc = "Plastoid armor with blue markings denoting lieutenant rank."
	icon_state = "replieutenant_armor"
	worn_icon_state = "replieutenant_armor"
	// SOM leader heavy
	soft_armor = list(MELEE = 60, BULLET = 80, LASER = 70, ENERGY = 70, BOMB = 60, BIO = 55, FIRE = 65, ACID = 55)
	slowdown = SLOWDOWN_ARMOR_HEAVY

/obj/item/clothing/suit/storage/marine/clone/captain
	name = "\improper Clone captain armor"
	desc = "Plastoid armor with red markings denoting captain rank."
	icon_state = "repcaptain_armor"
	worn_icon_state = "repcaptain_armor"
	soft_armor = list(MELEE = 60, BULLET = 80, LASER = 70, ENERGY = 70, BOMB = 60, BIO = 55, FIRE = 65, ACID = 55)
	slowdown = SLOWDOWN_ARMOR_HEAVY

/obj/item/clothing/suit/storage/marine/clone/commander
	name = "\improper Clone commander armor"
	desc = "Plastoid armor with yellow markings denoting commander rank."
	icon_state = "repcommander_armor"
	worn_icon_state = "repcommander_armor"
	soft_armor = list(MELEE = 60, BULLET = 80, LASER = 70, ENERGY = 70, BOMB = 60, BIO = 55, FIRE = 65, ACID = 55)
	slowdown = SLOWDOWN_ARMOR_HEAVY

/obj/item/clothing/suit/storage/marine/clone/mp/phase2
	name = "\improper Clone military police armor, phase II"
	desc = "Updated phase II armor used by Republic military police."
	icon_state = "repmp_phase2armor"
	worn_icon_state = "repmp_phase2armor"
	soft_armor = list(MELEE = 50, BULLET = 75, LASER = 65, ENERGY = 65, BOMB = 55, BIO = 55, FIRE = 60, ACID = 55)

/obj/item/clothing/suit/storage/marine/clone/legion501
	name = "\improper 501st Legion clone armor"
	desc = "Phase II plastoid armor bearing the blue markings of the 501st Legion."
	icon_state = "rep_501st"
	worn_icon_state = "rep_501st"
	soft_armor = list(MELEE = 50, BULLET = 75, LASER = 65, ENERGY = 65, BOMB = 55, BIO = 55, FIRE = 60, ACID = 55)

/obj/item/clothing/suit/storage/marine/clone/battalion212
	name = "\improper 212th Battalion clone armor"
	desc = "Phase II plastoid armor bearing the orange markings of the 212th Attack Battalion."
	icon_state = "rep_212th"
	worn_icon_state = "rep_212th"
	soft_armor = list(MELEE = 50, BULLET = 75, LASER = 65, ENERGY = 65, BOMB = 55, BIO = 55, FIRE = 60, ACID = 55)

/obj/item/clothing/suit/storage/marine/clone/battalion442
	name = "\improper 442nd Siege Battalion clone armor"
	desc = "Phase II plastoid armor bearing the markings of the 442nd Siege Battalion."
	icon_state = "rep_442nd"
	worn_icon_state = "rep_442nd"
	soft_armor = list(MELEE = 50, BULLET = 75, LASER = 65, ENERGY = 65, BOMB = 55, BIO = 55, FIRE = 60, ACID = 55)

/obj/item/clothing/suit/storage/marine/clone/commando
	name = "\improper Clone commando armor"
	desc = "Heavy plastoid armor used by clone commandos."
	icon_state = "repcommando"
	worn_icon_state = "repcommando"
	soft_armor = list(MELEE = 60, BULLET = 80, LASER = 70, ENERGY = 70, BOMB = 60, BIO = 55, FIRE = 65, ACID = 55)
	slowdown = SLOWDOWN_ARMOR_HEAVY

/obj/item/clothing/suit/storage/marine/clone/reinforced
	name = "\improper Reinforced clone trooper armor"
	desc = "Heavy plastoid armor with an additional blast plate."
	icon_state = "repreinforced"
	worn_icon_state = "repreinforced"
	soft_armor = list(MELEE = 50, BULLET = 75, LASER = 65, ENERGY = 65, BOMB = 55, BIO = 55, FIRE = 60, ACID = 55)
	slowdown = SLOWDOWN_ARMOR_MEDIUM

// Imperial Royal Guard (crimson)
/obj/item/clothing/suit/storage/marine/clone/guard
	name = "\improper Imperial Royal Guard armor"
	desc = "Extremely expensive plastoid armor with a crimson red robe attached."
	icon_state = "redguard"
	worn_icon_state = "redguard"
	// SOM lorica-tier
	soft_armor = list(MELEE = 60, BULLET = 85, LASER = 80, ENERGY = 80, BOMB = 65, BIO = 55, FIRE = 70, ACID = 60)
	slowdown = SLOWDOWN_ARMOR_MEDIUM

/obj/item/clothing/suit/storage/marine/clone/guard/senateguard
	name = "\improper Senate Guard armor"
	desc = "Extremely expensive plastoid armor with a royal blue robe attached."
	icon_state = "senateguard"
	worn_icon_state = "senateguard"
	soft_armor = list(MELEE = 60, BULLET = 85, LASER = 80, ENERGY = 80, BOMB = 65, BIO = 55, FIRE = 70, ACID = 60)

// ----- Empire -----

/obj/item/clothing/suit/storage/marine/sw/darth
	name = "\improper Dark Lord armor"
	desc = "A dark mechanical life-support suit. Breathing sounds ominously mechanical."
	icon_state = "darth_armor"
	worn_icon_state = "darth_armor"
	soft_armor = list(MELEE = 60, BULLET = 85, LASER = 80, ENERGY = 80, BOMB = 65, BIO = 75, FIRE = 90, ACID = 60)
	slowdown = SLOWDOWN_ARMOR_HEAVY

/obj/item/clothing/suit/storage/marine/sw/stormtrooper
	name = "\improper Stormtrooper armor"
	desc = "Standard Imperial plastoid armor covering most of the body."
	icon_state = "stormtrooper_armor"
	worn_icon_state = "stormtrooper_armor"
	soft_armor = list(MELEE = 45, BULLET = 70, LASER = 60, ENERGY = 60, BOMB = 50, BIO = 50, FIRE = 55, ACID = 50)
	slowdown = SLOWDOWN_ARMOR_MEDIUM

/obj/item/clothing/suit/storage/marine/sw/stormsurgeon
	name = "\improper Imperial stormtrooper surgeon armor"
	desc = "Stormtrooper armor with mint green highlights for field medics."
	icon_state = "sturmsurgeon_armor"
	worn_icon_state = "sturmsurgeon_armor"
	soft_armor = list(MELEE = 45, BULLET = 70, LASER = 60, ENERGY = 60, BOMB = 50, BIO = 50, FIRE = 55, ACID = 50)
	slowdown = SLOWDOWN_ARMOR_MEDIUM

/obj/item/clothing/suit/storage/marine/sw/stormradio
	name = "\improper Imperial stormtrooper radioman armor"
	desc = "Lightened stormtrooper armor with removed plates for added mobility."
	icon_state = "stormradio_armor"
	worn_icon_state = "stormradio_armor"
	soft_armor = list(MELEE = 35, BULLET = 60, LASER = 50, ENERGY = 50, BOMB = 45, BIO = 45, FIRE = 50, ACID = 40)
	slowdown = 0

// Officer drip: leather jacket + style light equalizer (used by imp_stormofficer jacket loadout)
/obj/item/clothing/suit/modular/style/leather_jacket/sw_officer
	name = "\improper Imperial officer jacket"
	desc = "A fashionable jacket issued to Imperial field officers."
	starting_attachments = list(/obj/item/armor_module/module/style/light_armor)
