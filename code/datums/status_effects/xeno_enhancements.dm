// ***************************************
// *********** Enhancement mutation status effects
// ***************************************
// Base type of the status effects applied by the leveled "Enhancement" mutations (see datums/xeno_mutations_leveled.dm).
// Same pattern as /datum/status_effect/carapace: one effect type per level, the "/two" and "/three" subtypes only set `level`.
// The effect is applied by /datum/mutation_menu/purchase_mutation() (and re-applied by reapply_mutation_effects()) and removed when the
// parent level is replaced, on evolution, or when the xenomorph is deleted. Everything apply_enhancement() changes must be reverted by remove_enhancement().

/atom/movable/screen/alert/status_effect/xeno_enhancement
	name = "Enhancement"
	desc = "An enhancement mutation is active."
	icon_state = "xenobuff_attack"

/datum/status_effect/xeno_enhancement
	id = "xeno_enhancement"
	duration = -1
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/xeno_enhancement
	/// The xenomorph that owns this status effect.
	var/mob/living/carbon/xenomorph/xenomorph_owner
	/// The level of the mutation this effect belongs to. Set by the "/two" and "/three" subtypes.
	var/level = 1
	/// TRUE once apply_enhancement() succeeded. Status effects get on_remove() called even if on_apply() failed, so this guards against reverting something that was never applied.
	var/enhancement_active = FALSE

/datum/status_effect/xeno_enhancement/on_creation(mob/living/new_owner, ...)
	. = ..()
	if(!. || QDELETED(src) || !linked_alert)
		return
	// The alert shows the name and numbers of the level, taken from the registered mutation so they can't go out of sync.
	var/datum/xeno_mutation/level_mutation = get_xeno_mutation_by_effect(type)
	if(!level_mutation)
		return
	linked_alert.name = level_mutation.name
	linked_alert.desc = level_mutation.buff_desc

/datum/status_effect/xeno_enhancement/on_apply()
	if(!isxeno(owner))
		return FALSE
	xenomorph_owner = owner
	if(!apply_enhancement())
		xenomorph_owner = null
		return FALSE
	enhancement_active = TRUE
	return TRUE

/datum/status_effect/xeno_enhancement/on_remove()
	if(enhancement_active)
		enhancement_active = FALSE
		remove_enhancement()
	xenomorph_owner = null
	return ..()

/// Applies the effect of the current level. Must return TRUE on success. If it returns FALSE it must not have changed anything.
/datum/status_effect/xeno_enhancement/proc/apply_enhancement()
	return TRUE

/// Reverts everything apply_enhancement() did. Only called after a successful apply_enhancement().
/datum/status_effect/xeno_enhancement/proc/remove_enhancement()
	return

/// Returns the entry of a per-level list that belongs to the current level.
/datum/status_effect/xeno_enhancement/proc/get_level_value(list/per_level_values)
	return per_level_values[clamp(level, 1, length(per_level_values))]
