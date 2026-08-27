/mob/living/carbon/xenomorph/warrior
	caste_base_type = /datum/xeno_caste/warrior
	name = "Warrior"
	desc = "A beefy, alien with an armored carapace."
	icon = 'icons/Xeno/castes/warrior/basic.dmi'
	icon_state = "Warrior Walking"
	effects_icon = 'icons/Xeno/castes/warrior/effects.dmi'
	bubble_icon = "alienroyal"
	health = 200
	maxHealth = 200
	plasma_stored = 50
	pixel_x = -16
	tier = XENO_TIER_TWO
	upgrade = XENO_UPGRADE_NORMAL
	bubble_icon = "alienroyal"

	skins = list(
		/datum/xenomorph_skin/warrior,
		/datum/xenomorph_skin/warrior/rouny,
	)

/mob/living/carbon/xenomorph/warrior/handle_special_state()
	var/datum/action/ability/xeno_action/toggle_agility/agility_action = actions_by_path[/datum/action/ability/xeno_action/toggle_agility]
	if(agility_action?.toggled)
		icon_state = "[xeno_caste.caste_name] Agility"
		return TRUE
	return FALSE

/mob/living/carbon/xenomorph/warrior/handle_special_wound_states(severity)
	. = ..()
	var/datum/action/ability/xeno_action/toggle_agility/agility_action = actions_by_path[/datum/action/ability/xeno_action/toggle_agility]
	if(agility_action?.toggled)
		return "wounded_agility_[severity]"

/mob/living/carbon/xenomorph/warrior/primordial
	upgrade = XENO_UPGRADE_PRIMO

/mob/living/carbon/xenomorph/warrior/Corrupted
	hivenumber = XENO_HIVE_CORRUPTED

/mob/living/carbon/xenomorph/warrior/Alpha
	hivenumber = XENO_HIVE_ALPHA

/mob/living/carbon/xenomorph/warrior/Beta
	hivenumber = XENO_HIVE_BETA

/mob/living/carbon/xenomorph/warrior/Zeta
	hivenumber = XENO_HIVE_ZETA

/mob/living/carbon/xenomorph/warrior/admeme
	hivenumber = XENO_HIVE_ADMEME

/mob/living/carbon/xenomorph/warrior/Corrupted/fallen
	hivenumber = XENO_HIVE_FALLEN
// ***************************************
// *********** Bulwark
// ***************************************

/mob/living/carbon/xenomorph/warrior/bulwark
	caste_base_type = /datum/xeno_caste/warrior/bulwark
	name = "Bulwark Warrior"
	icon = 'icons/Xeno/castes/warrior/bulwark.dmi'

	// Стойки
	var/plates_active = FALSE
	var/reflective_active = FALSE

	// Направленная броня (пассив +10/+10, в пластинах +20/0)
	var/front_armor_bonus = 10
	var/side_armor_bonus = 10

	// Штраф когтей в пластинах
	var/claw_damage_penalty = 0

/mob/living/carbon/xenomorph/warrior/bulwark/primordial
	upgrade = XENO_UPGRADE_PRIMO

/mob/living/carbon/xenomorph/warrior/bulwark/Corrupted
	hivenumber = XENO_HIVE_CORRUPTED

/mob/living/carbon/xenomorph/warrior/bulwark/Alpha
	hivenumber = XENO_HIVE_ALPHA

/mob/living/carbon/xenomorph/warrior/bulwark/Beta
	hivenumber = XENO_HIVE_BETA

/mob/living/carbon/xenomorph/warrior/bulwark/Zeta
	hivenumber = XENO_HIVE_ZETA

/mob/living/carbon/xenomorph/warrior/bulwark/admeme
	hivenumber = XENO_HIVE_ADMEME

/mob/living/carbon/xenomorph/warrior/bulwark/Corrupted/fallen
	hivenumber = XENO_HIVE_FALLEN

// *********** Иконки стоек ***********

/mob/living/carbon/xenomorph/warrior/bulwark/handle_special_state()
	if(reflective_active)
		icon_state = "[xeno_caste.caste_name] Shield Reflective"
		return TRUE
	if(plates_active)
		icon_state = "[xeno_caste.caste_name] Shield"
		return TRUE
	return FALSE

// *********** Лок направления (DIRLOCK в билде нет) ***********

/mob/living/carbon/xenomorph/warrior/bulwark/setDir(new_dir)
	if(reflective_active && new_dir != dir)
		return
	return ..()

// *********** Броня: +50% мили + направленная ***********

/mob/living/carbon/xenomorph/warrior/bulwark/modify_by_armor(damage_amount, armor_type, penetration, def_zone, attack_dir)
	. = ..()
	if(armor_type == MELEE)
		. *= 1.5
	// Направленная броня: спереди и сбоку, сзади — нет
	if(attack_dir)
		if(attack_dir == REVERSE_DIR(dir))
			. = max(. - front_armor_bonus, 0)
		else if(attack_dir != dir)
			. = max(. - side_armor_bonus, 0)

// *********** Запрет атак под щитом ***********

/mob/living/carbon/xenomorph/warrior/bulwark/UnarmedAttack(atom/A, mods)
	if(reflective_active)
		to_chat(src, span_xenowarning("We cannot attack while our reflective shield is raised!"))
		return
	return ..()

// *********** Само отражение ***********


var/reflecting_hit = FALSE

/mob/living/carbon/xenomorph/warrior/bulwark/projectile_hit(atom/movable/projectile/proj, cardinal_move, uncrossing)
	if(SEND_SIGNAL(src, COMSIG_XENO_PROJECTILE_HIT, proj, cardinal_move, uncrossing) & COMPONENT_PROJECTILE_DODGE)
		return FALSE
	if(proj.ammo.ammo_behavior_flags & AMMO_SKIPS_ALIENS)
		return FALSE

	// Спереди + щит активен + отражаемый тип
	if(reflective_active && (cardinal_move & REVERSE_DIR(dir)))
		if(!(proj.ammo.ammo_behavior_flags & (AMMO_XENO|AMMO_SNIPER)) && !istype(proj.ammo, /datum/ammo/rocket))
			proj.damage *= 0.5      // отражённый выстрел несёт половину урона
			proj.sundering = 0
			reflect_shot(proj)      // новый снаряд в стрелка
			proj.damage = 0         // оригинал гаснет на нас
			reflecting_hit = TRUE
			return TRUE             // движок сам остановит и удалит оригинал

	return ..()

// Оригиналу не даём себя ударить (он и так с 0 урона, но on_hit_mob у некоторых амм может вешать эффекты)
/mob/living/carbon/xenomorph/warrior/bulwark/do_projectile_hit(atom/movable/projectile/proj)
	if(reflecting_hit)
		reflecting_hit = FALSE
		return
	return ..()

// Отражённый выстрел — новый снаряд, как это делают движковые отражающие поверхности
/mob/living/carbon/xenomorph/warrior/bulwark/proc/reflect_shot(atom/movable/projectile/P)
	var/atom/shooter = P.firer
	if(!shooter)
		return
	var/atom/movable/projectile/N
	if(istype(P, /atom/movable/projectile/hitscan))
		var/atom/movable/projectile/hitscan/HP = P // каст к хитскану
		var/atom/movable/projectile/hitscan/H = new(get_turf(src))
		H.effect_icon = HP.effect_icon
		N = H
	else
		N = new(get_turf(src))
	N.generate_bullet(P.ammo)
	N.damage = P.damage
	N.fire_at(shooter, src, src, N.ammo.max_range, recursivity = TRUE)
