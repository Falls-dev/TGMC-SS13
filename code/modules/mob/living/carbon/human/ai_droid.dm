/**
 * AI droids: bodies that the shipboard AI can step into to use its "hands".
 *
 * The AI's mind and client are transferred into the droid, so the AI gets the normal human HUD
 * (hands, throw mode, pulling, surgery). The droid is limited by design:
 * - it cannot leave its operating zone (a set of area types),
 * - it cannot attack, fire guns, prime grenades, wear clothes or climb into disposals,
 * - only an AI can control it (through the deploy action the AI owns).
 * While an AI is inside, the operating zone is outlined on the AI's screen only.
 */

///All AI droids that exist, used by the AI's deploy action to build its list
GLOBAL_LIST_EMPTY(ai_droids)

/mob/living/carbon/human/ai_droid
	name = "AI droid"
	real_name = "AI droid"
	faction = FACTION_TERRAGOV
	///Big mobs cannot be put into (or climb into) disposal units
	mob_size = MOB_SIZE_BIG
	///Name given to the droid. Set after the species change, otherwise a random name is generated
	var/droid_name = "AI droid"
	///Icon state in icons/mob/ai_droid.dmi
	var/droid_icon_state = "cargo"
	///Skill set of the droid
	var/droid_skills = /datum/skills/doctor
	///Access list put on the built-in ID card
	var/list/droid_access = list()
	///Data huds built into the droid (DATA_HUD_* defines)
	var/list/droid_huds = list()
	///Area types (subtypes included) the droid is not allowed to leave. If empty, the area it spawns in is used
	var/list/zone_area_types = list()
	///Every area instance that belongs to the zone, filled on init
	var/list/area/zone_areas
	///Built-in ID card, so doors and consoles work for the droid
	var/obj/item/card/id/droid_id
	///The AI currently controlling this droid
	var/mob/living/silicon/ai/controller
	///Zone images shown to the controlling client only
	var/list/image/zone_images
	///Action that sends the AI back to its core
	var/datum/action/ai_droid_return/return_action

/mob/living/carbon/human/ai_droid/Initialize(mapload)
	. = ..()
	GLOB.ai_droids += src
	set_species("Synthetic")
	name = droid_name
	real_name = droid_name
	//The body is a single custom icon, the human body layers are not used (see update_body below)
	icon = 'icons/mob/ai_droid.dmi'
	icon_state = droid_icon_state
	set_skills(getSkillsType(droid_skills))
	a_intent = INTENT_HELP
	for(var/hud_number in droid_huds)
		var/datum/atom_hud/built_in_hud = GLOB.huds[hud_number]
		built_in_hud?.add_hud_to(src)
	droid_id = new(src)
	droid_id.access = droid_access.Copy()
	droid_id.registered_name = droid_name
	//Build the zone from every area whose type matches. A droid without zone types stays in its starting area
	zone_areas = list()
	for(var/area_type in GLOB.areas_by_type)
		var/area/checked_area = GLOB.areas_by_type[area_type]
		if(checked_area && is_zone_area(checked_area))
			zone_areas += checked_area
	if(!length(zone_area_types))
		var/area/home_area = get_area(src)
		zone_area_types = list(home_area.type)
		zone_areas = list(home_area)
	return_action = new(src)
	RegisterSignal(src, COMSIG_MOB_ITEM_ATTACK, PROC_REF(block_item_attack))

/mob/living/carbon/human/ai_droid/Destroy()
	eject_ai()
	GLOB.ai_droids -= src
	for(var/hud_number in droid_huds)
		var/datum/atom_hud/built_in_hud = GLOB.huds[hud_number]
		built_in_hud?.remove_hud_from(src)
	zone_areas = null
	QDEL_NULL(droid_id)
	QDEL_NULL(return_action)
	return ..()

/mob/living/carbon/human/ai_droid/death(gibbed, deathmessage, silent)
	eject_ai()
	return ..()

// ***************************************
// *********** Appearance
// ***************************************

//The droid is drawn by its own icon, so the human body, hair and damage overlays are disabled.
/mob/living/carbon/human/ai_droid/update_body(update_icons = 1, force_cache_update = 0)
	return

/mob/living/carbon/human/ai_droid/update_hair()
	return

/mob/living/carbon/human/ai_droid/update_bodyparts()
	return

/mob/living/carbon/human/ai_droid/UpdateDamageIcon()
	return

//No status icon over the droid's head (it would show AFK whenever no AI is inside).
/mob/living/carbon/human/ai_droid/set_status_hud()
	return

/mob/living/carbon/human/ai_droid/set_simple_status_hud()
	return

// ***************************************
// *********** Restrictions
// ***************************************

///Droids can only hold things in their hands, nothing can be worn
/mob/living/carbon/human/ai_droid/equip_to_slot_if_possible(obj/item/item_to_equip, slot, ignore_delay = TRUE, del_on_fail = FALSE, warning = TRUE, redraw_mob = TRUE, override_nodrop = FALSE)
	if(slot != SLOT_L_HAND && slot != SLOT_R_HAND)
		if(warning)
			to_chat(src, span_warning("Droids cannot wear anything."))
		return FALSE
	return ..()

///Unarmed attacks against mobs are disabled, only helpful interactions are allowed
/mob/living/carbon/human/ai_droid/UnarmedAttack(atom/A, has_proximity, params)
	if(ismob(A) && (a_intent == INTENT_HARM || a_intent == INTENT_DISARM))
		to_chat(src, span_warning("Combat protocols are disabled."))
		return
	return ..()

///Hitting a mob with an item is blocked unless the item is harmless or the target can be operated on (surgery)
/mob/living/carbon/human/ai_droid/proc/block_item_attack(datum/source, mob/living/target, obj/item/attacking_item)
	SIGNAL_HANDLER
	if(!attacking_item.force || target.can_be_operated_on())
		return NONE
	to_chat(src, span_warning("Combat protocols are disabled."))
	return COMPONENT_ITEM_NO_ATTACK

///The droid carries its own ID card with the access of its department
/mob/living/carbon/human/ai_droid/get_idcard(hand_first)
	return droid_id || ..()

///Whether an area belongs to the operating zone of this droid
/mob/living/carbon/human/ai_droid/proc/is_zone_area(area/checked_area)
	for(var/area_type in zone_area_types)
		if(istype(checked_area, area_type))
			return TRUE
	return FALSE

///Blocks every step that would take the droid out of its zone and tells the AI which area stopped it
/mob/living/carbon/human/ai_droid/Move(atom/newloc, direction, glide_size_override)
	if(newloc)
		var/area/new_area = get_area(newloc)
		if(new_area && !is_zone_area(new_area))
			if(controller)
				to_chat(src, span_warning("Outside of the operating zone: [new_area] ([new_area.type])."))
			return FALSE
	return ..()

///An empty droid must not count as SSD, otherwise ghosts could take it over and the AFK status would show
/mob/living/carbon/human/ai_droid/Logout()
	. = ..()
	LAZYREMOVE(GLOB.ssd_living_mobs, src)
	set_afk_status(MOB_CONNECTED)

// ***************************************
// *********** AI control
// ***************************************

///Moves the AI into the droid. Returns TRUE on success
/mob/living/carbon/human/ai_droid/proc/deploy(mob/living/silicon/ai/ai)
	if(controller || stat == DEAD || QDELETED(src))
		to_chat(ai, span_warning("This droid cannot be controlled right now."))
		return FALSE
	if(ai.stat || !ai.mind || !ai.client)
		return FALSE
	controller = ai
	RegisterSignal(ai, COMSIG_QDELETING, PROC_REF(on_ai_deleted))
	ai.mind.transfer_to(src, TRUE)
	return_action.give_action(src)
	strip_hud()
	show_zone()
	to_chat(src, span_notice("You take control of [src]. The operating zone is highlighted."))
	return TRUE

///Sends the AI back to its core. The AI's eye stays where the droid is standing
/mob/living/carbon/human/ai_droid/proc/eject_ai()
	if(!controller)
		return
	var/mob/living/silicon/ai/ai = controller
	controller = null
	UnregisterSignal(ai, COMSIG_QDELETING)
	hide_zone(ai.client || client)
	return_action?.remove_action(src)
	var/turf/droid_turf = get_turf(src)
	if(mind && !QDELETED(ai))
		mind.transfer_to(ai, TRUE)
		//The AI's login moves its eye to the core, so move it back to the droid afterwards
		if(droid_turf && !QDELETED(ai.eyeobj))
			ai.eyeobj.setLoc(droid_turf)
		to_chat(ai, span_notice("You leave [src]. Your view stays where the droid stands."))

///Forget the controller if the AI is deleted while inside the droid
/mob/living/carbon/human/ai_droid/proc/on_ai_deleted(datum/source)
	SIGNAL_HANDLER
	controller = null

///Removes everything from the droid's HUD except the two hand slots
/mob/living/carbon/human/ai_droid/proc/strip_hud()
	if(!hud_used)
		return
	for(var/atom/movable/screen/box AS in hud_used.static_inventory + hud_used.toggleable_inventory)
		if(istype(box, /atom/movable/screen/inventory))
			var/atom/movable/screen/inventory/inv_box = box
			if(inv_box.slot_id == SLOT_L_HAND || inv_box.slot_id == SLOT_R_HAND)
				continue
		else if(!istype(box, /atom/movable/screen/toggle_inv))
			continue
		hud_used.static_inventory -= box
		hud_used.toggleable_inventory -= box
		client?.screen -= box
		qdel(box)

// ***************************************
// *********** Zone display
// ***************************************

///Shows the operating zone to the controlling client: a faint grid on every tile and a bright outline along the zone border
/mob/living/carbon/human/ai_droid/proc/show_zone()
	if(!client || !length(zone_areas))
		return
	hide_zone(client)
	zone_images = list()
	for(var/area/zone_area AS in zone_areas)
		for(var/turf/zone_turf in zone_area)
			zone_images += make_zone_image(zone_turf, "fill")
			for(var/direction in GLOB.cardinals)
				var/turf/neighbor = get_step(zone_turf, direction)
				if(neighbor && is_zone_area(get_area(neighbor)))
					continue
				zone_images += make_zone_image(zone_turf, "edge_[lowertext(dir2text_short(direction))]")
	client.images += zone_images

///Makes a single zone image. Images are only visible to the clients they are added to
/mob/living/carbon/human/ai_droid/proc/make_zone_image(turf/zone_turf, state)
	var/image/zone_image = image('icons/effects/ai_droid_zone.dmi', zone_turf, state)
	zone_image.plane = FLOOR_PLANE
	zone_image.layer = ABOVE_WEEDS_LAYER + 1
	zone_image.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	return zone_image

///Removes the zone images from the given client
/mob/living/carbon/human/ai_droid/proc/hide_zone(client/hider)
	if(hider && length(zone_images))
		hider.images -= zone_images
	zone_images = null

// ***************************************
// *********** Droid types
// ***************************************

/mob/living/carbon/human/ai_droid/cargo
	name = "cargo droid"
	droid_name = "Cargo Droid"
	droid_icon_state = "cargo"
	droid_skills = /datum/skills/civilian
	droid_access = list(ACCESS_MARINE_CARGO, ACCESS_MARINE_RO)
	zone_area_types = list(/area/mainship/squads/req, /area/shuttle/supply)

/mob/living/carbon/human/ai_droid/medical
	name = "medical droid"
	droid_name = "Medical Droid"
	droid_icon_state = "medical"
	droid_skills = /datum/skills/doctor
	zone_area_types = list(/area/mainship/medical)
	droid_access = list(ACCESS_MARINE_MEDBAY, ACCESS_MARINE_MEDPREP, ACCESS_MARINE_CHEMISTRY)
	droid_huds = list(DATA_HUD_MEDICAL_ADVANCED)
	zone_area_types = list(/area/mainship/medical)

// ***************************************
// *********** Spawners (place these on the map)
// ***************************************

///Creates a droid on its own tile after the map has loaded, then deletes itself
/obj/effect/ai_droid_spawner
	name = "AI droid spawner"
	invisibility = INVISIBILITY_ABSTRACT
	///Type of droid to create
	var/droid_type = /mob/living/carbon/human/ai_droid/cargo

/obj/effect/ai_droid_spawner/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/effect/ai_droid_spawner/LateInitialize()
	new droid_type(loc)
	qdel(src)

/obj/effect/ai_droid_spawner/cargo
	droid_type = /mob/living/carbon/human/ai_droid/cargo

/obj/effect/ai_droid_spawner/medical
	droid_type = /mob/living/carbon/human/ai_droid/medical

// ***************************************
// *********** Actions
// ***************************************

///Given to the droid while an AI is inside, sends the AI back to its core
/datum/action/ai_droid_return
	name = "Return to core"
	action_icon_state = "enter_droid"

/datum/action/ai_droid_return/action_activate()
	. = ..()
	var/mob/living/carbon/human/ai_droid/droid = owner
	droid.eject_ai()

///Given to the AI, lets it pick a free droid and step into it
/datum/action/deploy_droid
	name = "Control AI droid"
	action_icon_state = "enter_droid"

/datum/action/deploy_droid/action_activate()
	. = ..()
	var/mob/living/silicon/ai/ai = owner
	var/list/mob/living/carbon/human/ai_droid/free_droids = list()
	for(var/mob/living/carbon/human/ai_droid/droid AS in GLOB.ai_droids)
		if(droid.controller || droid.stat == DEAD)
			continue
		free_droids += droid
	if(!length(free_droids))
		to_chat(ai, span_warning("No free droids detected."))
		return
	var/mob/living/carbon/human/ai_droid/chosen = tgui_input_list(ai, "Which droid do you want to control?", "Droid choice", free_droids)
	if(!chosen)
		return
	chosen.deploy(ai)
