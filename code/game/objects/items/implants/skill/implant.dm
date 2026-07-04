/obj/item/implant/skill
	implant_flags = BENEFICIAL_IMPLANT|HIGHLANDER_IMPLANT
	w_class = WEIGHT_CLASS_TINY
	/// Maximum skill a user can possess
	var/list/max_skills
	//vars for update skills
	var/cqc
	var/melee_weapons
	var/firearms
	var/pistols
	var/shotguns
	var/rifles
	var/smgs
	var/heavy_weapons
	var/smartgun
	var/engineer
	var/construction
	var/leadership
	var/medical
	var/surgery
	var/pilot
	var/police
	var/powerloader
	var/large_vehicle
	var/mech_pilot
	var/stamina

/obj/item/implant/skill/try_implant(mob/living/carbon/human/target, mob/living/user)
	. = ..()
	if(!.)
		return
	for(var/skill in max_skills)
		if(target.skills.getRating(skill) >= max_skills[skill])
			balloon_alert(user, "Nothing to learn!")
			return FALSE
	return TRUE

/obj/item/implant/skill/implant(mob/living/carbon/human/target, mob/living/user)
	. = ..()
	if(!.)
		return
	target.set_skills(target.skills.modifyRating(cqc, melee_weapons, firearms, pistols, shotguns, rifles, smgs, heavy_weapons, smartgun,\
	engineer, construction, leadership, medical, surgery, pilot, police, powerloader, large_vehicle, mech_pilot, stamina))
	return TRUE

/obj/item/implant/skill/unimplant()
	if(!implanted)
		return FALSE
	implant_owner.set_skills(implant_owner.skills.modifyRating(-cqc, -melee_weapons, -firearms, -pistols, -shotguns, -rifles, -smgs, -heavy_weapons, -smartgun,\
	-engineer, -construction, -leadership, -medical, -surgery, -pilot, -police, -powerloader, -large_vehicle, -mech_pilot, -stamina))
	return ..()

/obj/item/implant/skill/afterattack(atom/target, mob/user, has_proximity, click_parameters)
	. = ..()
	if(istype(target, /obj/item/implanter/skill/cargo))
		var/obj/item/implanter/skill/cargo/implanter = target
		if(implanter.spent)
			balloon_alert(user, "Already spent!")
			return
		user?.temporarilyRemoveItemFromInventory(src)
		forceMove(implanter)
		implanter.internal_implant = src
		implanter.icon_state = "cargo_full"
		implanter.spent = TRUE

/obj/item/implant/hud

	// what kind of HUD do we want?
	var/hud_type
	// do we want it to be activated by default?
	var/hud_active

/obj/item/implant/hud/implant(mob/living/carbon/human/target, mob/living/user)
	. = ..()
	if(.)
		var/datum/atom_hud/H = GLOB.huds[hud_type]
		if(H)
			H.add_hud_to(target)

/obj/item/implant/hud/activate()
	. = ..()
	if(!.)
		return FALSE

	hud_active = !hud_active

	var/datum/atom_hud/H = GLOB.huds[hud_type]
	if(!H || !implant_owner)
		return TRUE

	if(hud_active)
		H.add_hud_to(implant_owner)
		to_chat(implant_owner, span_notice("You activate your [name]."))
	else
		H.remove_hud_from(implant_owner)
		to_chat(implant_owner, span_notice("You deactivate your [name]."))

	return TRUE

/obj/item/implant/hud/unimplant()
	if(hud_active && implant_owner)
		var/datum/atom_hud/H = GLOB.huds[hud_type]
		if(H)
			H.remove_hud_from(implant_owner)
		hud_active = FALSE

	return ..()
