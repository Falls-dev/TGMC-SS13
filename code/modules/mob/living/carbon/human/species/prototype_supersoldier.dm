/datum/species/human/prototype_supersoldier
	name = "Prototype Supersoldier"
	max_stamina = 30
	slowdown = 0.5
	inherent_traits = list(TRAIT_TOO_TALL)
	inherent_actions = list(/datum/action/supersoldier_stims)
	namepool = /datum/namepool/prototype_supersoldier
	species_flags = HAS_SKIN_TONE|HAS_LIPS|HAS_UNDERWEAR

/datum/species/human/prototype_supersoldier/on_species_gain(mob/living/carbon/human/H, datum/species/old_species)
	. = ..()
	H.health_threshold_crit = -25

/datum/species/human/prototype_supersoldier/post_species_loss(mob/living/carbon/human/H)
	. = ..()
	H.health_threshold_crit = initial(H.health_threshold_crit)
