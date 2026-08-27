/datum/xeno_caste/warrior
	caste_name = "Warrior"
	display_name = "Warrior"
	upgrade_name = ""
	caste_desc = "A powerful front line combatant."
	caste_type_path = /mob/living/carbon/xenomorph/warrior
	tier = XENO_TIER_TWO
	upgrade = XENO_UPGRADE_BASETYPE
	wound_type = "warrior" //used to match appropriate wound overlays

	// *** Melee Attacks *** //
	melee_damage = 23

	// *** Speed *** //
	speed = -0.5

	// *** Plasma *** //
	plasma_max = 200
	plasma_gain = 20

	// *** Health *** //
	max_health = 350

	// *** Sunder *** //
	sunder_multiplier = 0.8

	// *** Evolution *** //
	evolution_threshold = 225

	// *** Flags *** //
	caste_flags = CASTE_EVOLUTION_ALLOWED|CASTE_IS_STRONG
	can_flags = CASTE_CAN_BE_QUEEN_HEALED|CASTE_CAN_BE_GIVEN_PLASMA|CASTE_CAN_BE_LEADER|CASTE_CAN_HOLD_FACEHUGGERS|CASTE_CAN_HOLD_JELLY
	caste_traits = null

	// *** Defense *** //
	soft_armor = list(MELEE = 40, BULLET = 60, LASER = 60, ENERGY = 40, BOMB = 20, BIO = 50, FIRE = 25, ACID = 50)

	// *** Minimap Icon *** //
	minimap_icon = "warrior"

	actions = list(
		/datum/action/ability/xeno_action/xeno_resting,
		/datum/action/ability/xeno_action/watch_xeno,
		/datum/action/ability/activable/xeno/psydrain,
		/datum/action/ability/xeno_action/empower,
		/datum/action/ability/xeno_action/toggle_agility,
		/datum/action/ability/activable/xeno/warrior/lunge,
		/datum/action/ability/activable/xeno/warrior/fling,
		/datum/action/ability/activable/xeno/warrior/grapple_toss,
		/datum/action/ability/activable/xeno/warrior/punch,
		/datum/action/ability/activable/xeno/warrior/punch/jab,
	)

/datum/xeno_caste/warrior/normal
	upgrade = XENO_UPGRADE_NORMAL

/datum/xeno_caste/warrior/primordial
	upgrade_name = "Primordial"
	caste_desc = "A champion of the hive, methodically shatters its opponents with punches rather than slashes."
	primordial_message = "Our rhythm is unmatched and our strikes lethal, no single foe can stand against us."
	upgrade = XENO_UPGRADE_PRIMO

	actions = list(
		/datum/action/ability/xeno_action/xeno_resting,
		/datum/action/ability/xeno_action/watch_xeno,
		/datum/action/ability/activable/xeno/psydrain,
		/datum/action/ability/xeno_action/empower,
		/datum/action/ability/activable/xeno/warrior/lunge,
		/datum/action/ability/activable/xeno/warrior/fling,
		/datum/action/ability/activable/xeno/warrior/grapple_toss,
		/datum/action/ability/activable/xeno/warrior/punch,
		/datum/action/ability/activable/xeno/warrior/punch/jab,
		/datum/action/ability/activable/xeno/warrior/punch/flurry,
	)

/datum/xeno_caste/warrior/bulwark
	caste_name = "Warrior"
	display_name = "Bulwark"
	upgrade_name = ""
	caste_desc = "A heavily armored warrior strain. It trades snatch and grab tools for directional defenses and siege capabilities. Where there's a sword, there's a shield."
	caste_type_path = /mob/living/carbon/xenomorph/warrior/bulwark
	base_caste_type_path = /mob/living/carbon/xenomorph/warrior
	upgrade = XENO_UPGRADE_BASETYPE

	// *** Speed *** //
	speed = -0.4

	// *** Plasma *** //
	plasma_max = 400

	// *** Health *** //
	max_health = 600

	// *** Defense *** //
	soft_armor = list(MELEE = 40, BULLET = 60, LASER = 60, ENERGY = 40, BOMB = 30, BIO = 50, FIRE = 25, ACID = 50)

	// *** Bulwark stance config *** //
	var/plates_armor = 10
	var/plates_slowdown = 1.35
	var/plates_damage_penalty = 8

	actions = list(
		/datum/action/ability/xeno_action/xeno_resting,
		/datum/action/ability/xeno_action/watch_xeno,
		/datum/action/ability/activable/xeno/psydrain,
		/datum/action/ability/xeno_action/empower,
		/datum/action/ability/xeno_action/toggle_plates,
		/datum/action/ability/activable/xeno/plate_bash,
		/datum/action/ability/xeno_action/tail_sweep/bulwark,
		/datum/action/ability/xeno_action/reflective_shield,
	)

/datum/xeno_caste/warrior/bulwark/normal
	upgrade = XENO_UPGRADE_NORMAL

/datum/xeno_caste/warrior/bulwark/primordial
	upgrade_name = "Primordial"
	upgrade = XENO_UPGRADE_PRIMO
