/datum/action/ability/activable/xeno/charge/forward_charge/unprecise
	cooldown_duration = 30 SECONDS

/datum/action/ability/activable/xeno/charge/forward_charge/unprecise/use_ability(atom/A)
	return ..(get_turf(A))

/datum/action/ability/activable/xeno/charge/forward_charge/unprecise/mob_hit(datum/source, mob/living/living_target)
	. = ..()

	if(iscarbon(living_target))
		var/mob/living/carbon/C = living_target
		C.Paralyze(3 SECONDS)

	return TRUE
