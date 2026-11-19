/datum/action/ability/activable/xeno/transfer_plasma/nymph
	plasma_transfer_amount = PLASMA_TRANSFER_AMOUNT * 2
	max_range = 2

/datum/action/ability/activable/xeno/transfer_plasma/nymph/can_use_ability(atom/A, silent = FALSE, override_flags)
	return ..(A, silent, override_flags|ABILITY_IGNORE_SELECTED_ABILITY)

/datum/action/ability/activable/xeno/psychic_cure/nymph_salve
	name = "Nymph Salve"
	desc = "Mend the wounds of a nearby sister."
	action_icon_state = "heal_xeno"
	action_icon = 'icons/Xeno/actions/drone.dmi'
	cooldown_duration = 6 SECONDS
	ability_cost = 40
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_ACIDIC_SALVE,
	)
	heal_range = 2
	target_flags = ABILITY_MOB_TARGET
	var/heal_percent = 0.1

/datum/action/ability/activable/xeno/psychic_cure/nymph_salve/can_use_ability(atom/target, silent = FALSE, override_flags)
	. = ..(target, silent, override_flags|ABILITY_IGNORE_SELECTED_ABILITY)
	if(!.)
		return FALSE
	if(target == owner || !owner.issamexenohive(target))
		return FALSE

/datum/action/ability/activable/xeno/psychic_cure/nymph_salve/use_ability(atom/target)
	if(xeno_owner.do_actions)
		return FALSE
	xeno_owner.face_atom(target)
	if(!do_after(xeno_owner, 1 SECONDS, NONE, target, BUSY_ICON_FRIENDLY, BUSY_ICON_MEDICAL))
		return FALSE
	if(!can_use_ability(target, TRUE, ABILITY_IGNORE_SELECTED_ABILITY))
		return FALSE
	var/mob/living/carbon/xenomorph/patient = target
	xeno_owner.visible_message(span_xenowarning("\The [xeno_owner] drools soothing resin over [patient]!"))
	playsound(patient, SFX_ALIEN_DROOL, 25)
	new /obj/effect/temp_visual/telekinesis(get_turf(patient))
	var/heal_amount = patient.maxHealth * heal_percent
	HEAL_XENO_DAMAGE(patient, heal_amount, FALSE)
	succeed_activate()
	add_cooldown()
