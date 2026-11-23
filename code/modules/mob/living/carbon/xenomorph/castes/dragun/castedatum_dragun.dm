/datum/xeno_caste/dragun
	caste_name = "Dragun"
	display_name = "Dragun"
	upgrade_name = ""
	caste_desc = "A heavy T3 xenomorph carrying an integrated acid rifle and blade."
	caste_type_path = /mob/living/carbon/xenomorph/dragun
	tier = XENO_TIER_THREE
	upgrade = XENO_UPGRADE_BASETYPE
	wound_type = "dragun"

	// *** Melee Attacks *** //
	melee_damage = 26

	// *** Speed *** //
	speed = -0.4

	// *** Plasma *** //
	plasma_max = 300
	plasma_gain = 25

	// *** Health *** //
	max_health = 450

	// *** Flags *** //
	caste_flags = CASTE_EVOLUTION_ALLOWED|CASTE_IS_STRONG|CASTE_STAGGER_RESISTANT
	can_flags = CASTE_CAN_BE_QUEEN_HEALED|CASTE_CAN_BE_GIVEN_PLASMA|CASTE_CAN_BE_LEADER|CASTE_CAN_BE_RULER
	caste_traits = list(TRAIT_STOPS_TANK_COLLISION)

	// *** Defense *** //
	soft_armor = list(MELEE = 50, BULLET = 55, LASER = 55, ENERGY = 50, BOMB = 35, BIO = 30, FIRE = 30, ACID = 30)

	// *** Minimap Icon *** //
	minimap_icon = "dragun"

	// Only standard xenomorph actions are available for now.
	actions = list(
		/datum/action/ability/xeno_action/xeno_resting,
		/datum/action/ability/xeno_action/watch_xeno,
		/datum/action/ability/activable/xeno/psydrain,
		/datum/action/ability/activable/xeno/dragun_slash,
		/datum/action/ability/activable/xeno/dragun_taran,
		/datum/action/ability/activable/xeno/dragun_bite,
	)

/datum/xeno_caste/dragun/normal
	upgrade = XENO_UPGRADE_NORMAL

/datum/xeno_caste/dragun/primordial
	upgrade_name = "Primordial"
	caste_desc = "A primordial Dragun, waiting for its specialized abilities to be awakened."
	primordial_message = "We are not yet complete. We will grow beyond this form."
	upgrade = XENO_UPGRADE_PRIMO
