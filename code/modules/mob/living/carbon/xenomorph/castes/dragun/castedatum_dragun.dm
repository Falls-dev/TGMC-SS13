/datum/xeno_caste/dragun
	caste_name = "Dragun"
	display_name = "Dragun"
	upgrade_name = ""
	caste_desc = "A heavily armored T3 xenomorph carrying an integrated acid rifle and blade. Its dense body heals at half the normal rate."
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
	can_flags = CASTE_CAN_BE_QUEEN_HEALED|CASTE_CAN_BE_GIVEN_PLASMA|CASTE_CAN_BE_LEADER|CASTE_CAN_BE_RULER|CASTE_CAN_HOLD_DRAGUN_BONES
	caste_traits = list(TRAIT_STOPS_TANK_COLLISION)

	// *** Defense *** //
	soft_armor = list(MELEE = 55, BULLET = 65, LASER = 60, ENERGY = 55, BOMB = 40, BIO = 30, FIRE = 30, ACID = 30)

	// *** Minimap Icon *** //
	minimap_icon = "dragun"

	// Innate actions and integrated weapon abilities.
	actions = list(
		/datum/action/ability/xeno_action/xeno_resting,
		/datum/action/ability/xeno_action/watch_xeno,
		/datum/action/ability/activable/xeno/psydrain,
		/datum/action/ability/activable/xeno/dragun_slash,
		/datum/action/ability/activable/xeno/dragun_taran,
		/datum/action/ability/activable/xeno/dragun_bite,
		/datum/action/ability/xeno_action/dragun_charge,
		/datum/action/ability/activable/xeno/psydrain/dragun_bones,
		/datum/action/ability/xeno_action/dragun_create_live,
		/datum/action/ability/xeno_action/dragun_aim,
		/datum/action/ability/xeno_action/dragun_create_bolt,
		/datum/action/ability/xeno_action/dragun_load_bone,
		/datum/action/ability/xeno_action/dragun_hide_bone,
		/datum/action/ability/xeno_action/dragun_heal_bone,
	)

/datum/xeno_caste/dragun/normal
	upgrade = XENO_UPGRADE_NORMAL

/datum/xeno_caste/dragun/primordial
	plasma_max = 400
	upgrade_name = "Primordial"
	caste_desc = "A primordial Dragun with expanded plasma reserves and a five-stage acid rifle charge. Its dense body heals at half the normal rate."
	primordial_message = "Our plasma reserves swell. We can charge our acid rifle to devastating strength."
	upgrade = XENO_UPGRADE_PRIMO
