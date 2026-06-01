/datum/species/zombie
	name = "Zombie"
	icobase = 'icons/mob/human_races/r_husk.dmi'
	total_health = 125
	species_flags = NO_BREATHE|NO_SCAN|NO_BLOOD|NO_POISON|NO_PAIN|NO_CHEM_METABOLIZATION|NO_STAMINA|HAS_UNDERWEAR|HEALTH_HUD_ALWAYS_DEAD|PARALYSE_RESISTANT
	lighting_cutoff = LIGHTING_CUTOFF_HIGH
	blood_color = "#110a0a"
	hair_color = "#000000"
	slowdown = 0.5
	default_language_holder = /datum/language_holder/zombie
	has_organ = list(
		ORGAN_SLOT_HEART = /datum/internal_organ/heart,
		ORGAN_SLOT_LUNGS = /datum/internal_organ/lungs,
		ORGAN_SLOT_LIVER = /datum/internal_organ/liver,
		ORGAN_SLOT_STOMACH = /datum/internal_organ/stomach,
		ORGAN_SLOT_KIDNEYS = /datum/internal_organ/kidneys,
		ORGAN_SLOT_BRAIN = /datum/internal_organ/brain,
		ORGAN_SLOT_APPENDIX = /datum/internal_organ/appendix,
		ORGAN_SLOT_EYES = /datum/internal_organ/eyes
	)
	death_message = "seizes up and falls limp..."
	///Sounds made randomly by the zombie
	var/list/sounds = list('sound/hallucinations/growl1.ogg','sound/hallucinations/growl2.ogg','sound/hallucinations/growl3.ogg','sound/hallucinations/veryfar_noise.ogg','sound/hallucinations/wail.ogg')
	///Time before resurrecting if dead
	var/revive_time = 1 MINUTES
	///How much burn and burn damage can you heal every Life tick (half a sec)
	var/heal_rate = 10
	///Our faction
	var/faction = FACTION_ZOMBIE
	///A claw type that we spawn in hands of the zombie
	var/claw_type = /obj/item/weapon/zombie_claw
	///Whether this zombie type can jump
	var/can_jump = FALSE
	///List of special actions given by this species
	var/list/action_list

/datum/species/zombie/on_species_gain(mob/living/carbon/human/H, datum/species/old_species)
	. = ..()
	for(var/datum/limb/limb AS in H.limbs)
		if(!istype(limb, /datum/limb/head))
			continue
		limb.vital = FALSE
		break

	H.set_undefibbable()
	H.faction = faction
	H.language_holder = new default_language_holder()
	H.set_oxy_loss(0)
	H.set_tox_loss(0)
	H.set_clone_loss(0)
	H.dropItemToGround(H.r_hand, TRUE)
	H.dropItemToGround(H.l_hand, TRUE)
	H.dextrous = FALSE //Prevents from opening cades
	if(istype(H.wear_id, /obj/item/card/id))
		var/obj/item/card/id/id = H.wear_id
		id.access = list() // A bit gamey, but let's say ids have a security against zombies
		id.iff_signal = NONE
	H.equip_to_slot_or_del(new claw_type, SLOT_R_HAND)
	H.equip_to_slot_or_del(new claw_type, SLOT_L_HAND)
	var/datum/atom_hud/health_hud = GLOB.huds[DATA_HUD_MEDICAL_OBSERVER]
	health_hud.add_hud_to(H)
	H.job = new /datum/job/zombie //Prevent from skewing the respawn timer if you take a zombie, it's a ghost role after all
	for(var/datum/action/action AS in H.actions)
		action.remove_action(H)
	var/datum/action/rally_zombie/rally_zombie = new
	rally_zombie.give_action(H)
	var/datum/action/set_agressivity/set_zombie_behaviour = new
	set_zombie_behaviour.give_action(H)
	if(can_jump)
		H.set_jump_component(cost = 0)

	for(var/action_type in action_list)
		var/datum/action/action = new action_type()
		action.give_action(H)

/datum/species/zombie/post_species_loss(mob/living/carbon/human/H)
	. = ..()
	for(var/datum/limb/limb AS in H.limbs)
		if(!istype(limb, /datum/limb/head))
			continue
		limb.vital = TRUE
		break

	var/datum/atom_hud/health_hud = GLOB.huds[DATA_HUD_MEDICAL_OBSERVER]
	health_hud.remove_hud_from(H)
	qdel(H.r_hand)
	qdel(H.l_hand)
	for(var/datum/action/action AS in H.actions)
		action.remove_action(H)
	if(can_jump)
		H.set_jump_component()

/datum/species/zombie/handle_unique_behavior(mob/living/carbon/human/H)
	if(H.stat == DEAD)
		return
	if(prob(10))
		playsound(get_turf(H), pick(sounds), 50)
	for(var/datum/limb/limb AS in H.limbs) //Regrow some limbs
		if(limb.limb_status & LIMB_DESTROYED && !(limb.parent?.limb_status & LIMB_DESTROYED) && prob(4))
			limb.remove_limb_flags(LIMB_DESTROYED)
			if(istype(limb, /datum/limb/hand/l_hand))
				H.equip_to_slot_or_del(new claw_type, SLOT_L_HAND)
			else if (istype(limb, /datum/limb/hand/r_hand))
				H.equip_to_slot_or_del(new claw_type, SLOT_R_HAND)
			H.update_body()
		else if(limb.limb_status & LIMB_BROKEN && prob(20))
			limb.remove_limb_flags(LIMB_BROKEN | LIMB_SPLINTED | LIMB_STABILIZED)

	if(H.health != total_health)
		H.heal_limbs(heal_rate)

	for(var/organ_slot in has_organ)
		var/datum/internal_organ/internal_organ = H.get_organ_slot(organ_slot)
		internal_organ?.heal_organ_damage(1)
	H.update_health()

/datum/species/zombie/handle_death(mob/living/carbon/human/H)
	if(H.on_fire)
		addtimer(CALLBACK(src, PROC_REF(fade_out_and_qdel_in), H), 1 MINUTES)
		return
	if(!H.has_working_organs())
		SSmobs.stop_processing(H)
		addtimer(CALLBACK(src, PROC_REF(fade_out_and_qdel_in), H), 1 MINUTES)
		return
	addtimer(CALLBACK(H, TYPE_PROC_REF(/mob/living/carbon/human, revive_to_crit), TRUE, FALSE), revive_time)

/datum/species/zombie/can_revive_to_crit(mob/living/carbon/human/H)
	if(H.on_fire || !H.has_working_organs() || isspaceturf(get_turf(H)))
		SSmobs.stop_processing(H)
		addtimer(CALLBACK(src, PROC_REF(fade_out_and_qdel_in), H), 20 SECONDS)
		return FALSE
	return TRUE

/// We start fading out the human and qdel them in set time
/datum/species/zombie/proc/fade_out_and_qdel_in(mob/living/carbon/human/H, time = 5 SECONDS)
	fade_out(H, our_time = time)
	QDEL_IN(H, time)

/datum/species/zombie/fast
	name = "Fast zombie"
	slowdown = 0
	can_jump = TRUE

/datum/species/zombie/fast/on_species_gain(mob/living/carbon/human/H, datum/species/old_species)
	. = ..()
	H.transform = matrix().Scale(0.8, 0.8)

/datum/species/zombie/fast/post_species_loss(mob/living/carbon/human/H)
	. = ..()
	H.transform = matrix().Scale(1.25, 1.25)

/datum/species/zombie/tank
	name = "Tank zombie"
	slowdown = 1
	heal_rate = 30
	total_health = 350
	claw_type = /obj/item/weapon/zombie_claw/tank

/datum/species/zombie/tank/on_species_gain(mob/living/carbon/human/H, datum/species/old_species)
	. = ..()
	H.transform = matrix().Scale(1.2, 1.2)
	ADD_TRAIT(H, TRAIT_STUNIMMUNE, ZOMBIE_TRAIT)
	H.set_move_resist(MOVE_FORCE_EXTREMELY_STRONG)

/datum/species/zombie/tank/post_species_loss(mob/living/carbon/human/H)
	. = ..()
	H.transform = matrix().Scale(0.8, 0.8)
	REMOVE_TRAIT(H, TRAIT_STUNIMMUNE, ZOMBIE_TRAIT)
	H.set_move_resist(initial(H.move_resist))

/datum/species/zombie/strong
	name = "Strong zombie" //These are zombies created from marines, they are stronger, but of course rarer
	slowdown = -0.5
	heal_rate = 20
	total_health = 200
	claw_type = /obj/item/weapon/zombie_claw/strong

/datum/species/zombie/strong/on_species_gain(mob/living/carbon/human/H, datum/species/old_species)
	. = ..()
	H.add_atom_colour(COLOR_DARK_BROWN, FIXED_COLOR_PRIORITY)

/datum/species/zombie/strong/post_species_loss(mob/living/carbon/human/H, datum/species/old_species)
	. = ..()
	H.remove_atom_colour(COLOR_DARK_BROWN, FIXED_COLOR_PRIORITY)

/datum/species/zombie/psi_zombie
	name = "Psi zombie" //reanimated by psionic ability
	slowdown = -0.5
	heal_rate = 20
	total_health = 200
	faction = FACTION_SECTOIDS
	claw_type = /obj/item/weapon/zombie_claw/no_zombium

/datum/species/zombie/smoker
	name = "Smoker zombie"
	action_list = list(/datum/action/ability/emit_gas)

/datum/species/zombie/hunter
	name = "Hunter zombie"
	total_health = 175
	slowdown = 0
	can_jump = TRUE
	claw_type = /obj/item/weapon/zombie_claw/strong
	action_list = list(/datum/action/ability/activable/pounce)

/datum/species/zombie/hunter/on_species_gain(mob/living/carbon/human/H, datum/species/old_species)
	. = ..()
	H.add_atom_colour(COLOR_ALMOST_BLACK, FIXED_COLOR_PRIORITY)

/datum/species/zombie/hunter/post_species_loss(mob/living/carbon/human/H, datum/species/old_species)
	. = ..()
	H.remove_atom_colour(COLOR_ALMOST_BLACK, FIXED_COLOR_PRIORITY)

/datum/species/zombie/boomer
	name = "Boomer zombie"
	heal_rate = 20
	total_health = 250
	action_list = list(
		/datum/action/ability/activable/bile_spit,
		/datum/action/ability/boomer_explode,
	)

/datum/species/zombie/boomer/on_species_gain(mob/living/carbon/human/H, datum/species/old_species)
	. = ..()
	H.add_atom_colour(COLOR_TOXIN_HUSKPOWDER, FIXED_COLOR_PRIORITY)

/datum/species/zombie/boomer/post_species_loss(mob/living/carbon/human/H, datum/species/old_species)
	. = ..()
	H.remove_atom_colour(COLOR_TOXIN_HUSKPOWDER, FIXED_COLOR_PRIORITY)
