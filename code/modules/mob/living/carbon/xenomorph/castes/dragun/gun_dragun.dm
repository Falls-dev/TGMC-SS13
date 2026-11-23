/obj/item/weapon/gun/dragun
	name = "Dragun arm rifle"
	desc = "An integrated acid rifle powered by the Dragun's plasma. It must be held with both hands to fire."
	icon = 'icons/Xeno/dragun_item.dmi'
	icon_state = "hand_dragun"
	worn_icon_state = "hand_dragun"
	worn_icon_list = list()
	item_flags = TWOHANDED|HAND_ITEM|DELONDROP
	resistance_flags = RESIST_ALL
	force = 75
	gun_features_flags = GUN_WIELDED_FIRING_ONLY|GUN_WIELDED_STABLE_FIRING_ONLY|GUN_NO_PITCH_SHIFT_NEAR_EMPTY
	reciever_flags = AMMO_RECIEVER_CYCLE_ONLY_BEFORE_FIRE
	default_ammo_type = null
	allowed_ammo_types = list()
	attachable_allowed = list()
	max_chamber_items = 0
	ammo_datum_type = /datum/ammo/xeno/acid
	gun_firemode_list = list(GUN_FIREMODE_SEMIAUTO)
	fire_delay = 0.5 SECONDS
	wield_delay = 0.5 SECONDS
	aim_slowdown = 0.35
	gun_skill_category = SKILL_RIFLES
	/// Provisional cost until the caste's weapon balance is finalized.
	var/plasma_cost = 10

/// Use the complete unarmed interaction path, including intent, hive/host
/// protection, barriers, posture, blocked hands, and the caste attack delay.
/obj/item/weapon/gun/dragun/melee_attack_chain(mob/user, atom/target, params, rightclick)
	if(!can_operate(user))
		return
	var/mob/living/carbon/xenomorph/dragun/dragun = user
	if(dragun.hand_dragun != src || dragun.get_active_held_item() != src)
		return
	var/list/modifiers = params2list(params)
	modifiers["right"] = rightclick
	RegisterSignal(dragun, COMSIG_XENOMORPH_ATTACK_LIVING, PROC_REF(blade_damage))
	. = dragun.UnarmedAttack(target, TRUE, modifiers)
	UnregisterSignal(dragun, COMSIG_XENOMORPH_ATTACK_LIVING)

/// Adjust only this blade swing; normal empty-hand attacks and abilities keep
/// their own damage. The normal harm proc still handles armor and shields.
/obj/item/weapon/gun/dragun/proc/blade_damage(mob/living/carbon/xenomorph/dragun/source, mob/living/target, damage, list/damage_mod, list/armor_mod)
	SIGNAL_HANDLER
	damage_mod += (force - source.xeno_caste.melee_damage) * source.xeno_melee_damage_modifier

/obj/item/weapon/gun/dragun/Initialize(mapload)
	. = ..()
	QDEL_NULL(muzzle_flash)
	ADD_TRAIT(src, TRAIT_NODROP, TRAIT_GENERIC)

/obj/item/weapon/gun/dragun/can_operate(mob/user)
	return istype(user, /mob/living/carbon/xenomorph/dragun) && loc == user

/// Projectiles identify their source as the gun, rather than its owner.
/// Expose the owner's hive so the existing xeno bullet_act protection applies.
/obj/item/weapon/gun/dragun/get_xeno_hivenumber()
	if(istype(loc, /mob/living/carbon/xenomorph/dragun))
		return loc.get_xeno_hivenumber()
	return ..()

/obj/item/weapon/gun/dragun/gun_on_cooldown(mob/user)
	// An integrated weapon cannot be juggled. Xenos lack the human cooldown signal responder.
	// Keep the normal last_fired/fire_delay check without human skills or anti-juggling.
	if(can_operate(user))
		return ..(null)
	return ..()

/obj/item/weapon/gun/dragun/able_to_fire(mob/user)
	if(!..())
		return FALSE
	var/mob/living/carbon/xenomorph/dragun/owner = user
	if(owner.hand_dragun != src || owner.get_active_held_item() != src)
		return FALSE
	if(owner.plasma_stored < plasma_cost)
		to_chat(owner, span_warning("We need more plasma to fire our rifle!"))
		return FALSE
	return TRUE

/obj/item/weapon/gun/dragun/wield(mob/user)
	if(!can_operate(user) || user.get_active_held_item() != src)
		return FALSE
	return ..()

/obj/item/weapon/gun/dragun/toggle_wielded(mob/user, wielded)
	. = ..()
	user.update_icons()

// The weapon is already part of the body sprite in both poses; retain only the HUD icon.
/obj/item/weapon/gun/dragun/make_worn_icon(species_type, slot_name, inhands, default_icon, default_layer)
	if(!inhands)
		return null
	return ..()

/obj/item/weapon/gun/dragun/update_icon_state()
	icon_state = "hand_dragun"

/obj/item/weapon/gun/dragun/cycle(mob/living/user, after_fire = TRUE)
	if(!after_fire && !in_chamber && can_operate(user))
		in_chamber = get_ammo_object()

/obj/item/weapon/gun/dragun/do_fire(obj/object_to_fire)
	if(!able_to_fire(gun_user))
		return FALSE
	var/mob/living/carbon/xenomorph/dragun/owner = gun_user
	. = ..()
	if(.)
		owner.use_plasma(plasma_cost)

/obj/item/weapon/gun/dragun/reload(obj/item/new_mag, mob/living/user, force = FALSE)
	return FALSE

/obj/item/weapon/gun/dragun/unload(mob/living/user, drop = TRUE, after_fire = FALSE)
	return FALSE

/obj/item/weapon/gun/dragun/proc/fire_acid_at(turf/target_turf)
	if(!target_turf || !gun_user || !(item_flags & FULLY_WIELDED))
		return FALSE
	if(gun_on_cooldown(gun_user))
		return FALSE
	set_target(target_turf)
	return Fire()
