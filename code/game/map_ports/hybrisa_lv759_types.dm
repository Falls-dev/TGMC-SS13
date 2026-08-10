// LV759 / Hybrisa types from upstream TGMC (auto-extracted)

/obj/effect/decal/cleanable/dirt/grime1
	icon_state = "grime1"

/obj/effect/decal/cleanable/dirt/grime2
	icon_state = "grime2"

/obj/effect/decal/cleanable/dirt/grime3
	icon_state = "grime3"

/obj/effect/decal/cleanable/dirt/grime4
	icon_state = "grime4"

/obj/effect/landmark/patrol_point
	name = "Patrol exit point"
	icon = 'icons/effects/campaign_effects.dmi'
	faction = FACTION_TERRAGOV
	///ID to link with an associated start point
	var/id = null
	///minimap icon state
	var/minimap_icon = "patrol_1"
	///List of open turfs around the point to deploy onto
	var/list/deploy_turfs

/obj/effect/landmark/patrol_point/Initialize(mapload)
	. = ..()
	GLOB.patrol_point_list += src
	RegisterSignals(SSdcs, list(COMSIG_GLOB_GAMEMODE_LOADED, COMSIG_GLOB_CAMPAIGN_MISSION_LOADED), PROC_REF(finish_setup))

///Finishes setup after we know what gamemode it is
/obj/effect/landmark/patrol_point/proc/finish_setup(datum/source, mode_override = FALSE)
	SIGNAL_HANDLER
	UnregisterSignal(SSdcs, list(COMSIG_GLOB_GAMEMODE_LOADED, COMSIG_GLOB_CAMPAIGN_MISSION_LOADED))
	if(!(SSticker?.mode?.round_type_flags & MODE_TWO_HUMAN_FACTIONS) && !mode_override)
		return
	SSminimaps.add_marker(src, GLOB.faction_to_minimap_flag[faction], image('icons/UI_icons/map_blips_large.dmi', null, minimap_icon, MINIMAP_BLIPS_LAYER))

	deploy_turfs = filled_circle_turfs(src, 5)
	for(var/turf/turf AS in deploy_turfs)
		if(turf.density || isspaceturf(turf))
			deploy_turfs -= turf
			continue
		for(var/atom/movable/AM AS in turf)
			if(!AM.density)
				continue
			deploy_turfs -= turf
			break

/obj/effect/landmark/patrol_point/Destroy()
	GLOB.patrol_point_list -= src
	return ..()

///Moves the AM and sets up the effects
/obj/effect/landmark/patrol_point/proc/do_deployment(atom/movable/movable_to_move, list/mobs_moving)
	var/turf/target_turf = loc
	if(!isarmoredvehicle(movable_to_move)) //multitile vehicles can have clipping issues otherwise
		target_turf = pick(deploy_turfs)

	if(ismob(mobs_moving))
		mobs_moving = list(mobs_moving)

	//list of AM's visually deploying
	var/list/deploy_list = list(movable_to_move)
	if(length(movable_to_move.buckled_mobs))
		deploy_list += movable_to_move.buckled_mobs

	if(isliving(movable_to_move))
		var/mob/living_to_move = movable_to_move
		new /atom/movable/effect/rappel_rope(target_turf)
		living_to_move.trainteleport(target_turf)
	else
		movable_to_move.forceMove(target_turf)
		if(isvehicle(movable_to_move))
			var/obj/vehicle/moved_vehicle = movable_to_move
			mobs_moving += moved_vehicle.occupants
			if(moved_vehicle.hitbox)
				deploy_list += moved_vehicle.hitbox.tank_desants

	var/list/layer_list = list()
	for(var/atom/movable/AM AS in deploy_list)
		if(isliving(AM))
			add_spawn_protection(AM)

		AM.add_filter(PATROL_POINT_RAPPEL_EFFECT, 2, drop_shadow_filter(y = -RAPPEL_HEIGHT, color = COLOR_TRANSPARENT_SHADOW, size = 4))
		var/shadow_filter = AM.get_filter(PATROL_POINT_RAPPEL_EFFECT)

		layer_list[AM] = AM.layer
		AM.pixel_z += RAPPEL_HEIGHT
		AM.layer = FLY_LAYER

		animate(AM, pixel_z = AM.pixel_z - RAPPEL_HEIGHT, time = RAPPEL_DURATION)
		animate(shadow_filter, y = 0, size = 0.9, time = RAPPEL_DURATION, flags = ANIMATION_PARALLEL)

	addtimer(CALLBACK(src, PROC_REF(end_rappel), deploy_list, layer_list, mobs_moving), RAPPEL_DURATION)

	for(var/user in mobs_moving)
		SEND_GLOBAL_SIGNAL(COMSIG_GLOB_HVH_DEPLOY_POINT_ACTIVATED, user)

///Temporarily applies godmode to prevent spawn camping
/obj/effect/landmark/patrol_point/proc/add_spawn_protection(mob/living/user)
	user.ImmobilizeNoChain(RAPPEL_DURATION) //looks weird if they can move while rappeling
	user.status_flags |= GODMODE
	addtimer(CALLBACK(src, PROC_REF(remove_spawn_protection), user), 10 SECONDS)

///Ends the rappel effects
/obj/effect/landmark/patrol_point/proc/end_rappel(list/atom/movable/movables_to_move, list/layer_list, list/mobs_moving)
	for(var/atom/movable/AM AS in movables_to_move)
		AM.remove_filter(PATROL_POINT_RAPPEL_EFFECT)
		AM.layer = layer_list[AM]
		SEND_SIGNAL(AM, COMSIG_MOVABLE_PATROL_DEPLOYED, TRUE, 1.5, 2)
		if(ismecha(AM) || isarmoredvehicle(AM))
			new /obj/effect/temp_visual/rappel_dust(AM.loc, 3)
			playsound(AM.loc, 'sound/effects/alien/behemoth/stomp.ogg', 40, TRUE)
	for(var/user in mobs_moving)
		shake_camera(user, 0.2 SECONDS, 0.5)

///Removes spawn protection godmode
/obj/effect/landmark/patrol_point/proc/remove_spawn_protection(mob/user)
	user.status_flags &= ~GODMODE

/obj/effect/landmark/patrol_point/som
	faction = FACTION_SOM

/obj/effect/landmark/patrol_point/som/som_11
	name = "SOM exit point 1"
	icon_state = "red_1"
	id = "SOM_1"
	minimap_icon = "som_patrol_1"

/obj/effect/landmark/patrol_point/som/som_21
	name = "SOM exit point 2"
	id = "SOM_2"
	icon_state = "red_2"
	minimap_icon = "som_patrol_2"


/atom/movable/effect/rappel_rope
	name = "rope"
	icon = 'icons/obj/structures/prop/mainship.dmi'
	icon_state = "rope"
	layer = ABOVE_MOB_LAYER
	anchored = TRUE
	resistance_flags = RESIST_ALL
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

//Rope animation for standard deploy points
/atom/movable/effect/rappel_rope/Initialize(mapload)
	. = ..()
	playsound(loc, 'sound/effects/rappel.ogg', 50, TRUE, falloff = 2)
	playsound(loc, 'sound/effects/tadpolehovering.ogg', 100, TRUE, falloff = 2.5)
	balloon_alert_to_viewers("!!!")
	visible_message(span_userdanger("You see a dropship fly overhead and begin dropping ropes!"))
	ropeanimation()

///Starts the rope animation
/atom/movable/effect/rappel_rope/proc/ropeanimation()
	flick("rope_deploy", src)
	addtimer(CALLBACK(src, PROC_REF(ropeanimation_stop)), 2 SECONDS)

///End the animation and qdels
/atom/movable/effect/rappel_rope/proc/ropeanimation_stop()
	flick("rope_up", src)
	QDEL_IN(src, 5)

#undef PATROL_POINT_RAPPEL_EFFECT
#undef RAPPEL_DURATION
#undef RAPPEL_HEIGHT

/obj/effect/landmark/patrol_point/tgmc_11
	name = "TGMC exit point 1"
	id = "TGMC_1"
	icon_state = "blue_1"

/obj/effect/landmark/patrol_point/tgmc_21
	name = "TGMC exit point 2"
	id = "TGMC_2"
	icon_state = "blue_2"
	minimap_icon = "patrol_2"

/obj/effect/landmark/xeno_spawner_spawn
	name = "xeno spawner spawn landmark"
	icon = 'icons/Xeno/3x3building.dmi'
	icon_state = "spawner"

/obj/effect/landmark/xeno_spawner_spawn/Initialize(mapload)
	GLOB.xeno_spawner_turfs += loc
	..()
	return INITIALIZE_HINT_QDEL

/obj/effect/mapping_helpers/airlock/free_access
	name = "airlock free access helper"
	icon_state = "airlock_free_access"

/obj/effect/mapping_helpers/airlock/free_access/Initialize(mapload)
	. = ..()
	if(!mapload)
		log_world("### MAP WARNING, [src] spawned outside of mapload!")
		return
	var/obj/machinery/door/airlock/airlock = locate(/obj/machinery/door/airlock) in loc
	if(!airlock)
		CRASH("### MAP WARNING, [src] failed to find an airlock at [AREACOORD(src)]")
	airlock.req_access = null
	airlock.req_one_access = null

/obj/effect/spawner/random/misc/structure/large
	name = "base large structure spawner"
	icon_state = null

/obj/effect/spawner/random/misc/structure/large/car
	name = "random car spawner"
	icon_state = "carone"
	icon = 'icons/effects/random/64x64.dmi'
	spawn_with_original_direction = TRUE
	spawn_loot_chance = 25
	loot = list(
		/obj/effect/spawner/random/misc/structure/large/car/red,
		/obj/effect/spawner/random/misc/structure/large/car/black,
		/obj/effect/spawner/random/misc/structure/large/car/purple,
		/obj/effect/spawner/random/misc/structure/large/car/pink,
		/obj/effect/spawner/random/misc/structure/large/car/blue,
		/obj/effect/spawner/random/misc/structure/large/car/taxi,
		/obj/effect/spawner/random/misc/structure/large/car/cop,
		/obj/effect/spawner/random/misc/structure/large/car/light_blue,
		/obj/effect/spawner/random/misc/structure/large/car/desat_blue,
		/obj/effect/spawner/random/misc/structure/large/car/turquoise,
		/obj/effect/spawner/random/misc/structure/large/car/brown,
		/obj/effect/spawner/random/misc/structure/large/car/generic,
		/obj/effect/spawner/random/misc/structure/large/car/orange,
		/obj/effect/spawner/random/misc/structure/large/car/green,
	)

/obj/effect/spawner/random/misc/structure/large/car/black
	name = "random car spawner black"
	loot = list(
		/obj/structure/prop/urban/vehicles/meridian/black = 75,
		/obj/structure/prop/urban/vehicles/meridian/black/damageone = 35,
		/obj/structure/prop/urban/vehicles/meridian/black/damagetwo = 35,
		/obj/structure/prop/urban/vehicles/meridian/black/damagethree = 20,
		/obj/structure/prop/urban/vehicles/meridian/black/damagefour = 10,
		/obj/structure/prop/urban/vehicles/meridian/black/damagefive = 10,
	)

/obj/effect/spawner/random/misc/structure/large/car/carfour
	name = "random car spawner damage four"
	icon_state = "carfour"
	loot = list(
		/obj/structure/prop/urban/vehicles/meridian/red/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/black/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/purple/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/pink/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/blue/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/taxi/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/cop/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/light_blue/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/desat_blue/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/turquoise/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/brown/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/generic/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/orange/damagefour,
		/obj/structure/prop/urban/vehicles/meridian/green/damagefour,
	)

/obj/effect/spawner/random/misc/structure/large/car/cop
	name = "random car spawner cop"
	loot = list(
		/obj/structure/prop/urban/vehicles/meridian/cop = 75,
		/obj/structure/prop/urban/vehicles/meridian/cop/damageone = 35,
		/obj/structure/prop/urban/vehicles/meridian/cop/damagetwo = 35,
		/obj/structure/prop/urban/vehicles/meridian/cop/damagethree = 20,
		/obj/structure/prop/urban/vehicles/meridian/cop/damagefour = 10,
		/obj/structure/prop/urban/vehicles/meridian/cop/damagefive = 10,
	)

/obj/effect/spawner/random/misc/structure/large/car/desat_blue
	name = "random car spawner desat blue"
	loot = list(
		/obj/structure/prop/urban/vehicles/meridian/desat_blue = 75,
		/obj/structure/prop/urban/vehicles/meridian/desat_blue/damageone = 35,
		/obj/structure/prop/urban/vehicles/meridian/desat_blue/damagetwo = 35,
		/obj/structure/prop/urban/vehicles/meridian/desat_blue/damagethree = 20,
		/obj/structure/prop/urban/vehicles/meridian/desat_blue/damagefour = 10,
		/obj/structure/prop/urban/vehicles/meridian/desat_blue/damagefive = 10,
	)

/obj/effect/spawner/random/misc/structure/large/car/generic
	name = "random car spawner generic"
	loot = list(
		/obj/structure/prop/urban/vehicles/meridian/generic = 75,
		/obj/structure/prop/urban/vehicles/meridian/generic/damageone = 35,
		/obj/structure/prop/urban/vehicles/meridian/generic/damagetwo = 35,
		/obj/structure/prop/urban/vehicles/meridian/generic/damagethree = 20,
		/obj/structure/prop/urban/vehicles/meridian/generic/damagefour = 10,
		/obj/structure/prop/urban/vehicles/meridian/generic/damagefive = 10,
	)

/obj/effect/spawner/random/misc/structure/large/car/taxi
	name = "random car spawner taxi"
	loot = list(
		/obj/structure/prop/urban/vehicles/meridian/taxi = 75,
		/obj/structure/prop/urban/vehicles/meridian/taxi/damageone = 35,
		/obj/structure/prop/urban/vehicles/meridian/taxi/damagetwo = 35,
		/obj/structure/prop/urban/vehicles/meridian/taxi/damagethree = 20,
		/obj/structure/prop/urban/vehicles/meridian/taxi/damagefour = 10,
		/obj/structure/prop/urban/vehicles/meridian/taxi/damagefive = 10,
	)

/obj/effect/spawner/random/misc/structure/large/car/turquoise
	name = "random car spawner turquoise"
	loot = list(
		/obj/structure/prop/urban/vehicles/meridian/turquoise = 75,
		/obj/structure/prop/urban/vehicles/meridian/turquoise/damageone = 35,
		/obj/structure/prop/urban/vehicles/meridian/turquoise/damagetwo = 35,
		/obj/structure/prop/urban/vehicles/meridian/turquoise/damagethree = 20,
		/obj/structure/prop/urban/vehicles/meridian/turquoise/damagefour = 10,
		/obj/structure/prop/urban/vehicles/meridian/turquoise/damagefive = 10,
	)

/obj/item/card/data
	name = "data disk"
	desc = "A disk of data."
	icon_state = "data"
	var/function = "storage"
	var/data = "null"
	var/special = null

/obj/item/card/data/verb/label(t as text)
	set name = "Label Disk"
	set category = "IC.Object"
	set src in usr

	if (t)
		name = "data disk- '[t]'"
	else
		name = "data disk"

/obj/item/clothing/glasses/gglasses
	name = "green glasses"
	desc = "Forest green glasses, like the kind you'd wear when hatching a nasty scheme."
	icon_state = "gglasses"
	worn_icon_state = "gglasses"
	armor_protection_flags = NONE

/obj/item/clothing/head/soft/orange
	name = "orange cap"
	desc = "It's a baseball hat in a tasteless orange color."
	icon_state = "orangesoft"
	cap_color = "orange"

/obj/item/clothing/mask/pig
	name = "pig mask"
	desc = "A rubber pig mask."
	icon_state = "pig"
	worn_icon_state = "pig"
	inventory_flags = COVERMOUTH|COVEREYES
	inv_hide_flags = HIDEFACE|HIDEALLHAIR|HIDEEYES|HIDEEARS
	w_class = WEIGHT_CLASS_SMALL
	siemens_coefficient = 0.9
	armor_protection_flags = HEAD|FACE|EYES

/obj/item/clothing/suit/armor/swat/officer
	name = "officer jacket"
	desc = "An armored jacket used in special operations."
	icon_state = "detective"
	worn_icon_state = "det_suit"
	blood_overlay_type = "coat"
	inventory_flags = NONE
	inv_hide_flags = NONE
	armor_protection_flags = CHEST|ARMS

/obj/item/clothing/suit/poncho
	name = "poncho"
	desc = "A simple, comfortable poncho."
	icon_state = "classicponcho"

/obj/item/clothing/suit/poncho/green
	name = "green poncho"
	desc = "Your classic, non-racist poncho. This one is green."
	icon_state = "greenponcho"

/obj/item/clothing/suit/poncho/red
	name = "red poncho"
	desc = "Your classic, non-racist poncho. This one is red."
	icon_state = "redponcho"

/obj/item/clothing/suit/storage/internalaffairs
	name = "Internal Affairs Jacket"
	desc = "A smooth black jacket."
	icon_state = "ia_jacket_open"
	worn_icon_state = "ia_jacket"
	blood_overlay_type = "coat"
	armor_protection_flags = CHEST|ARMS

/obj/item/clothing/suit/storage/internalaffairs/verb/toggle()
	set name = "Toggle Coat Buttons"
	set category = "IC.Object"
	set src in usr

	if(!usr.canmove || usr.stat || usr.restrained())
		return FALSE

	switch(icon_state)
		if("ia_jacket_open")
			src.icon_state = "ia_jacket"
			to_chat(usr, "You button up the jacket.")
		if("ia_jacket")
			src.icon_state = "ia_jacket_open"
			to_chat(usr, "You unbutton the jacket.")
		else
			to_chat(usr, "You attempt to button-up the velcro on your [src], before promptly realising that it won't work.")
			return FALSE
	update_clothing_icon()	//so our overlays update

//Medical

/obj/item/clothing/tie/armband/med
	name = "medical armband"
	desc = "An armband, worn by the crew to display which department they're assigned to. This one is white."
	icon_state = "med"

/obj/item/clothing/under/assistantformal
	name = "assistant's formal uniform"
	desc = "An assistant's formal-wear. Why an assistant needs formal-wear is still unknown."
	icon_state = "assistant_formal"
	worn_icon_state = "gy_suit"

/obj/item/clothing/under/suit_jacket/burgundy
	name = "burgundy suit"
	desc = "A burgundy suit and black tie. Somewhat formal."
	icon_state = "burgundy_suit"

/obj/item/clothing/under/suit_jacket/checkered
	name = "checkered suit"
	desc = "That's a very nice suit you have there. Shame if something were to happen to it, eh?"
	icon_state = "checkered_suit"

/obj/item/clothing/under/suit_jacket/navy
	name = "navy suit"
	desc = "A navy suit and red tie, intended for the station's finest."
	icon_state = "navy_suit"

/obj/item/clothing/under/suit_jacket/tan
	name = "tan suit"
	desc = "A tan suit with a yellow tie. Smart, but casual."
	icon_state = "tan_suit"

/obj/item/device/flashlight/lamp/tripod
	name = "tripod lamp"
	desc = "An emergency light tube mounted onto a tripod. It seemingly lasts forever."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "tripod_lamp"
	light_range = 6//pretty good

/obj/item/device/flashlight/lamp/tripod/grey
	icon_state = "tripod_lamp_grey"

/obj/item/flashlight/lamp/verb/toggle_light()
	set name = "Toggle light"
	set category = "IC.Object"
	set src in oview(1)

	if(istype(usr, /mob/living/carbon/xenomorph)) //Sneaky xenos turning off the lights
		attack_alien(usr)
		return

	if(!usr.stat)
		attack_self(usr)

/obj/item/flashlight/lamp/attack_alien(mob/living/carbon/xenomorph/xeno_attacker, damage_amount = xeno_attacker.xeno_caste.melee_damage, damage_type = BRUTE, armor_type = MELEE, effects = TRUE, armor_penetration = xeno_attacker.xeno_caste.melee_ap, isrightclick = FALSE)
	if(xeno_attacker.status_flags & INCORPOREAL)
		return FALSE
	xeno_attacker.do_attack_animation(src, ATTACK_EFFECT_SMASH)
	playsound(loc, 'sound/effects/metalhit.ogg', 20, TRUE)
	xeno_attacker.visible_message(span_danger("\The [xeno_attacker] smashes [src]!"), \
	span_danger("We smash [src]!"), null, 5)
	deconstruct(FALSE)

/obj/item/prop/paint
	name = "paint bucket"
	desc = "It's a paint bucket."
	icon_state = "paint_empty"
	icon = 'icons/obj/items/items.dmi'

/obj/item/prop/paint/blue
	icon_state = "paint_blue"

/obj/item/prop/paint/violet
	icon_state = "paint_violet"

///BROKEN MARINE VENDOR PROPS

/obj/item/reagent_containers/cup/glass/drinkingglass
	name = "drinking glass"
	desc = "Your standard drinking glass."
	icon_state = "glass_empty"
	base_icon_state = "glass_empty"
	amount_per_transfer_from_this = 10
	fill_icon_thresholds = list(0)
	fill_icon_state = "drinking_glass"
	volume = 50
	max_integrity = 20
	resistance_flags = UNACIDABLE
	//the screwdriver cocktail can make a drinking glass into the world's worst screwdriver. beautiful.
	toolspeed = 25

	/// The type to compare to glass_style.required_container type, or null to use class type.
	/// This allows subtypes to utilize parent styles.
	var/base_container_type = null

/obj/item/reagent_containers/cup/glass/drinkingglass/Initialize(mapload, vol)
	. = ..()
	AddComponent( \
		/datum/component/takes_reagent_appearance, \
		CALLBACK(src, PROC_REF(on_cup_change)), \
		CALLBACK(src, PROC_REF(on_cup_reset)), \
		base_container_type = base_container_type, \
	)
	RegisterSignal(src, COMSIG_COMPONENT_CLEAN_ACT, PROC_REF(on_cleaned))

// Having our icon state change removes fill thresholds
/obj/item/reagent_containers/cup/glass/drinkingglass/on_cup_change(datum/glass_style/style)
	. = ..()
	fill_icon_thresholds = null

// And having our icon reset restores our fill thresholds
/obj/item/reagent_containers/cup/glass/drinkingglass/on_cup_reset()
	. = ..()
	fill_icon_thresholds ||= list(0)

/obj/item/reagent_containers/cup/glass/drinkingglass/examine(mob/user)
	. = ..()
	if(HAS_TRAIT(src, TRAIT_WAS_RENAMED))
		. += span_notice("This glass has been given a custom name. It can be removed by washing it.")

/obj/item/reagent_containers/cup/glass/drinkingglass/attack_alien(mob/living/carbon/xenomorph/xeno_attacker, damage_amount = xeno_attacker.xeno_caste.melee_damage, damage_type = BRUTE, armor_type = MELEE, effects = TRUE, armor_penetration = xeno_attacker.xeno_caste.melee_ap, isrightclick = FALSE)
	if(!CONFIG_GET(flag/fun_allowed))
		return FALSE
	attack_hand(xeno_attacker)

/obj/item/reagent_containers/cup/glass/drinkingglass/proc/on_cleaned(obj/source_component, obj/source)
	SIGNAL_HANDLER
	if(!HAS_TRAIT(src, TRAIT_WAS_RENAMED))
		return

	name = initial(name)
	desc = initial(desc)
	update_appearance(UPDATE_NAME | UPDATE_DESC)

//Shot glasses!//
//  This lets us add shots in here instead of lumping them in with drinks because >logic  //
//  The format for shots is the exact same as iconstates for the drinking glass, except you use a shot glass instead.  //
//  If it's a new drink, remember to add it to Chemistry-Reagents.dm  and Chemistry-Recipes.dm as well.  //
//  You can only mix the ported-over drinks in shot glasses for now (they'll mix in a shaker, but the sprite won't change for glasses). //
//  This is on a case-by-case basis, and you can even make a separate sprite for shot glasses if you want. //

/obj/item/roller/bedroll
	name = "folded bedroll"
	desc = "A standard issue USCMC bedroll, They've been in service for as long as you can remember. The tag on it states to unfold it before rest, but who needs rules anyway, right?"
	icon = 'icons/obj/rollerbed.dmi'
	icon_state = "bedroll"
	rollertype = /obj/structure/bed/bedroll

//Hospital Rollers (non foldable)

/obj/item/spacecash/c1
	name = "1 dollar bill"
	icon_state = "spacecash1"
	desc = "A single US Government minted one dollar bill. It has a picture of George Washington printed on it. Makes most people of english origin cry, but isn't worth very much. Could probably get you half a hot-dog in some systems. "
	worth = 1

/obj/item/spacecash/c10
	name = "10 dollar bill"
	icon_state = "spacecash10"
	desc = "A single US Government minted ten dollar bill. It has a picture of Alexander Hamilton on it, federal bank enthusiast, and victim of a terrible griefing incident. Could probably pay for a meal at a cheap restaurant, before tax and tip."
	worth = 10

/obj/item/spacecash/c100
	name = "100 dollar bill"
	icon_state = "spacecash100"
	desc = "A single US Government minted hundred dollar bill. It has a picture of Ben Franklin, lightning kite extraordinaire. You could probably pay for an entire day of shore leave activities with this, provided you aren't careless. (which you are)"
	worth = 100

/obj/item/spacecash/c20
	name = "20 dollar bill"
	icon_state = "spacecash20"
	desc = "A single US Government minted twenty dollar bill. It has a picture of Andrew Jackson on it, famed hero of the War of 1812 and slayer of indigenous peoples everywhere. Could probably afford you a nice 2-course meal at the local colony steakhouse."
	worth = 20

/obj/item/spacecash/c200
	name = "200 dollars"
	icon_state = "spacecash200"
	desc = "Two US Government minted hundred dollar bills. They both have pictures of Ben Franklin on them. Both Bens look at you expectedly and passionately from different angles."
	worth = 200

/obj/item/spacecash/c500
	name = "500 dollars"
	icon_state = "spacecash500"
	desc = "Five US Government minted hundred dollar bills. All of them have pictures of Ben Franklin on them. They all eagarly glare at you, making you feel as if you owe them something. "
	worth = 500


/proc/spawn_money(sum, spawnloc, mob/living/carbon/human/human_user)
	if(sum in list(1000,500,200,100,50,20,10,1))
		var/cash_type = text2path("/obj/item/spacecash/c[sum]")
		var/obj/cash = new cash_type (usr.loc)
		if(ishuman(human_user) && !human_user.get_active_held_item())
			human_user.put_in_hands(cash)
		return
	var/obj/item/spacecash/bundle/bundle = new (spawnloc)
	bundle.worth = sum
	bundle.update_appearance()
	if (ishuman(human_user) && !human_user.get_active_held_item())
		human_user.put_in_hands(bundle)

/obj/item/trash/crushed_bottle
	name = "crushed bottle"
	desc = "A crushed bottle, it's hard to see the label."
	icon_state = "blank_can_crushed"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 1

/obj/item/trash/crushed_bottle/sixpackcrushed_1
	icon_state = "6_pack_1_crushed"

/obj/item/trash/crushed_cup
	name = "crushed cup"
	desc = "A sad crushed and destroyed cup. It's now useless trash. What a waste."
	icon_state = "crushed_solocup"
	throwforce = 0
	w_class = WEIGHT_CLASS_TINY
	attack_verb = list("bludgeons", "whacks", "slaps")

/obj/item/trash/crushed_wbottle
	name = "crushed waterbottle"
	desc = "Overpriced 'Spring' water. Bottled by the Nanotrasen Corporation."
	icon_state = "waterbottle_crushed"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 1

/obj/item/trash/cuppa_joes/empty_cup
	name = "Empty Cuppa Joe's coffee cup"
	desc = "Have you got the CuppaJoe Smile? Stay perky! Freeze-dried CuppaJoe's Coffee."
	icon_state = "coffeecuppajoenolid"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 1

/obj/item/trash/cuppa_joes/Initialize(mapload)
	. = ..()
	pixel_x = rand(-10,10)
	pixel_y = rand(-10,10)

// Cuppa Joes no random axis

/obj/item/trash/cuppa_joes/lid
	name = "Cuppa Joe's coffee cup lid"
	desc = "Have you got the CuppaJoe Smile? Stay perky! Freeze-dried CuppaJoe's Coffee."
	icon_state = "coffeecuppajoelid"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 1

/obj/item/trash/cuppa_joes_static/empty_cup
	name = "Empty Cuppa Joe's coffee cup"
	desc = "Have you got the CuppaJoe Smile? Stay perky! Freeze-dried CuppaJoe's Coffee."
	icon_state = "coffeecuppajoenolid"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 1

/obj/item/trash/cuppa_joes_static/empty_cup_stack
	name = "Empty Cuppa Joe's coffee cup stack"
	desc = "Have you got the CuppaJoe Smile? Stay perky! Freeze-dried CuppaJoe's Coffee."
	icon_state = "coffeecuppajoestacknolid"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 1

/obj/item/trash/cuppa_joes_static/lid
	name = "Cuppa Joe's coffee cup lid"
	desc = "Have you got the CuppaJoe Smile? Stay perky! Freeze-dried CuppaJoe's Coffee."
	icon_state = "coffeecuppajoelid"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 1

/obj/item/trash/cuppa_joes_static/lid_stack
	name = "Cuppa Joe's coffee cup lid stack"
	desc = "Have you got the CuppaJoe Smile? Stay perky! Freeze-dried CuppaJoe's Coffee."
	icon_state = "coffeecuppajoelidstack"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 1

/obj/item/trash/nt_chips
	name = "\improper Nanotrasen Pepper Chips"
	icon_state = "nt_chips_pepper"
	desc = "An oily empty bag that once held Nanotrasen Chips."

/obj/item/trash/nt_chips/pepper
	name = "\improper Nanotrasen Pepper Chips"
	icon_state = "nt_chips_pepper"
	desc = "An oily empty bag that once held Nanotrasen Pepper Chips."

/obj/item/trash/trashbag
	name = "trash bag"
	desc = "It's the heavy-duty black polymer kind. Time to take out the trash!"
	icon_state = "ztrashbag"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 1

/obj/machinery/door/airlock/mainship/engineering/glass/free_access
	req_one_access = null

/obj/machinery/door/airlock/multi_tile/urban
	name = "\improper Airlock"
	icon_state = "door_closed"
	req_access = null

/obj/machinery/door/airlock/multi_tile/urban/generic
	icon = 'icons/obj/doors/hybrisa/hybrisa_2x1generic.dmi'
	opacity = FALSE
	req_one_access = list(ACCESS_CIVILIAN_PUBLIC)

/obj/machinery/door/airlock/multi_tile/urban/generic_solid
	icon = 'icons/obj/doors/hybrisa/hybrisa_2x1generic_solid.dmi'
	req_one_access = list(ACCESS_CIVILIAN_PUBLIC)

// Medical

/obj/machinery/door/airlock/multi_tile/urban/medical
	icon = 'icons/obj/doors/hybrisa/hybrisa_2x1medidoor.dmi'
	opacity = FALSE
	req_one_access = list(ACCESS_CIVILIAN_RESEARCH, ACCESS_CIVILIAN_PUBLIC)

/obj/machinery/door/airlock/multi_tile/urban/medical_solid
	icon = 'icons/obj/doors/hybrisa/hybrisa_2x1medidoor_solid.dmi'
	req_one_access = list(ACCESS_CIVILIAN_RESEARCH, ACCESS_CIVILIAN_PUBLIC)

// Personal

/obj/machinery/door/airlock/multi_tile/urban/personal
	icon = 'icons/obj/doors/hybrisa/hybrisa_2x1personaldoor_glass.dmi'
	opacity = FALSE
	req_one_access = list(ACCESS_CIVILIAN_RESEARCH)

/obj/machinery/door/airlock/multi_tile/urban/personal_solid_white
	icon = 'icons/obj/doors/hybrisa/hybrisa_2x1personaldoor_white.dmi'
	req_one_access = list(ACCESS_CIVILIAN_RESEARCH)

/obj/machinery/door/airlock/multi_tile/urban/personal_white
	icon = 'icons/obj/doors/hybrisa/hybrisa_2x1personaldoor_glass_white.dmi'
	opacity = FALSE
	req_one_access = list(ACCESS_CIVILIAN_RESEARCH)

/obj/machinery/door/airlock/urban
	openspeed = 4
	icon_state = "door_closed"
	req_access = null

/obj/machinery/door/airlock/urban/generic
	name = "\improper Airlock"
	icon = 'icons/obj/doors/hybrisa/hybrisa_generic_glass.dmi'
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/urban/generic_solid
	name = "\improper Airlock"
	icon = 'icons/obj/doors/hybrisa/hybrisa_generic.dmi'

// Medical

/obj/machinery/door/airlock/urban/medical
	name = "\improper Airlock"
	icon = 'icons/obj/doors/hybrisa/hybrisa_medidoor_glass.dmi'
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/urban/medical_solid
	name = "\improper Airlock"
	icon = 'icons/obj/doors/hybrisa/hybrisa_medidoor.dmi'

// Personal

/obj/machinery/door/airlock/urban/personal
	name = "\improper Airlock"
	icon = 'icons/obj/doors/hybrisa/hybrisa_personaldoor_glass.dmi'
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/urban/personal_solid
	name = "\improper Airlock"
	icon = 'icons/obj/doors/hybrisa/hybrisa_personaldoor.dmi'

// Personal White

/obj/machinery/door/airlock/urban/personal_solid_white
	name = "\improper Airlock"
	icon = 'icons/obj/doors/hybrisa/hybrisa_personaldoor_white.dmi'

/obj/machinery/door/poddoor/shutters/urban
	icon = 'icons/obj/structures/prop/urban/urbanshutters.dmi'
	icon_state = "almayer_pdoor"
	base_icon_state = "almayer_pdoor"
	desc = "It's a shutter. You can <B>open</b> it with a <B>crowbar</b>, or with <B>claws</b>"
	openspeed = 4
	///how long it takes xenos to open a shutter by hand
	var/lift_time = 10 SECONDS
	soft_armor = list(MELEE = 50, BULLET = 50, LASER = 50, ENERGY = 50, BOMB = 15, BIO = 50, FIRE = 50, ACID = 50)

/obj/machinery/door/poddoor/shutters/urban/attackby(obj/item/attacking_item, mob/user, params)
	. = ..()
	if(iscrowbar(attacking_item))
		user.balloon_alert(user, "lifting [src]...")
		if(!do_after(user, 15 SECONDS, NONE, src, BUSY_ICON_FRIENDLY))
			return
		balloon_alert_to_viewers("lifts [src]")
		open()

/obj/machinery/door/poddoor/shutters/urban/attack_alien(mob/living/carbon/xenomorph/xeno_attacker, damage_amount = xeno_attacker.xeno_caste.melee_damage, damage_type = BRUTE, armor_type = MELEE, effects = TRUE, armor_penetration = xeno_attacker.xeno_caste.melee_ap, isrightclick = FALSE)
	if(xeno_attacker.a_intent != INTENT_HELP)
		xeno_attacker.balloon_alert(xeno_attacker, "lifting [src]...")
		if(!xeno_attacker.mob_size == MOB_SIZE_BIG)
			if(!do_after(xeno_attacker, lift_time, NONE, src,  BUSY_ICON_HOSTILE))
				return
		else
			if(!do_after(xeno_attacker, 5 SECONDS, NONE, src, BUSY_ICON_HOSTILE))
				return
		open()
		balloon_alert_to_viewers("lifts [src]")

/obj/machinery/door/poddoor/shutters/urban/biohazard/white
	icon_state = "w_almayer_pdoor"
	icon = 'icons/obj/structures/prop/urban/urbanshutters.dmi'
	base_icon_state = "w_almayer_pdoor"

/obj/machinery/door/poddoor/shutters/urban/open_shutters
	icon_state = "almayer_pdoor"
	base_icon_state = "almayer_pdoor"
	opacity = FALSE
	layer = ABOVE_WINDOW_LAYER
	max_integrity = 100
	lift_time = 5 SECONDS
	soft_armor = list(MELEE = 30, BULLET = 30, LASER = 30, ENERGY = 30, BOMB = 10, BIO = 30, FIRE = 20, ACID = 20)

/obj/machinery/door/poddoor/shutters/urban/open_shutters/opened
	icon_state = "almayer_pdoor0"
	density = FALSE
	opacity = FALSE
	layer = BLASTDOOR_LAYER

/obj/machinery/door/poddoor/shutters/urban/secure_red_door
	desc = "That looks like it doesn't open easily."
	icon_state = "pdoor"
	base_icon_state = "pdoor"

/obj/machinery/door/poddoor/shutters/urban/security_lockdown
	icon = 'icons/obj/doors/mainship/blastdoors_shutters.dmi'
	icon_state = "pdoor"
	base_icon_state = "pdoor"
	lift_time = 15 SECONDS

/obj/machinery/door/poddoor/shutters/urban/shutters
	icon_state = "shutter"
	layer = ABOVE_WINDOW_LAYER

/obj/machinery/door/poddoor/shutters/urban/shutters/opened
	icon_state = "shutter0"
	base_icon_state = "shutter"
	density = FALSE
	opacity = FALSE
	layer = BLASTDOOR_LAYER

/obj/machinery/door/poddoor/shutters/urban/white
	desc = "That looks like it doesn't open easily."
	icon_state = "w_almayer_pdoor"
	base_icon_state = "w_almayer_pdoor"

/obj/machinery/hydroponics
	name = "hydroponics tray"
	icon = 'icons/obj/machines/hydroponics.dmi'
	icon_state = "hydrotray3"
	density = TRUE
	anchored = TRUE
	coverage = 40
	layer = BELOW_OBJ_LAYER
	resistance_flags = XENO_DAMAGEABLE
	allow_pass_flags = PASS_LOW_STRUCTURE|PASSABLE|PASS_WALKOVER
	max_integrity = 40
	soft_armor = list(MELEE = 0, BULLET = 80, LASER = 80, ENERGY = 80, BOMB = 0, BIO = 0, FIRE = 0, ACID = 0)

	var/draw_warnings = 1 //Set to 0 to stop it from drawing the alert lights.

	// Plant maintenance vars.
	var/waterlevel = 100       // Water (max 100)
	var/nutrilevel = 100       // Nutrient (max 100)
	var/pestlevel = 0          // Pests (max 10)
	var/weedlevel = 0          // Weeds (max 10)

	// Tray state vars.
	var/dead = 0               // Is it dead?
	var/harvest = 0            // Is it ready to harvest?
	var/age = 0                // Current plant age
	var/sampled = 0            // Have wa taken a sample?

	// Harvest/mutation mods.
	var/yield_mod = 0          // Modifier to yield
	var/mutation_mod = 0       // Modifier to mutation chance
	var/toxins = 0             // Toxicity in the tray?
	var/mutation_level = 0     // When it hits 100, the plant mutates.

	// Mechanical concerns.
	var/health = 0             // Plant health.
	var/lastproduce = 0        // Last time tray was harvested
	var/lastcycle = 0          // Cycle timing/tracking var.
	var/cycledelay = 150       // Delay per cycle.
	var/closed_system          // If set, the tray will attempt to take atmos from a pipe.
	var/force_update           // Set this to bypass the cycle time check.
	var/obj/temp_chem_holder   // Something to hold reagents during process_reagents()

	// Seed details/line data.
	var/datum/seed/seed = null // The currently planted seed

	// Reagent information for process(), consider moving this to a controller along
	// with cycle information under 'mechanical concerns' at some point.
	var/global/list/toxic_reagents = list(
		/datum/reagent/medicine/dylovene = -2,
		/datum/reagent/toxin = 2,
		/datum/reagent/fluorine = 2.5,
		/datum/reagent/chlorine = 1.5,
		/datum/reagent/toxin/acid = 1.5,
		/datum/reagent/toxin/acid/polyacid = 3,
		/datum/reagent/toxin/plantbgone = 3,
		/datum/reagent/medicine/cryoxadone = -3,
		/datum/reagent/radium = 2
		)
	var/global/list/nutrient_reagents = list(
		/datum/reagent/consumable/milk = 0.1,
		/datum/reagent/consumable/ethanol/beer = 0.25,
		/datum/reagent/phosphorus = 0.1,
		/datum/reagent/consumable/sugar = 0.1,
		/datum/reagent/consumable/sodawater = 0.1,
		/datum/reagent/ammonia = 1,
		/datum/reagent/diethylamine = 2,
		/datum/reagent/consumable/nutriment = 1,
		/datum/reagent/medicine/adminordrazine = 1,
		/datum/reagent/toxin/fertilizer/eznutrient = 1,
		/datum/reagent/toxin/fertilizer/robustharvest = 1,
		/datum/reagent/toxin/fertilizer/left4zed = 1
		)
	var/global/list/weedkiller_reagents = list(
		/datum/reagent/fluorine = -4,
		/datum/reagent/chlorine = -3,
		/datum/reagent/phosphorus = -2,
		/datum/reagent/consumable/sugar = 2,
		/datum/reagent/toxin/acid = -2,
		/datum/reagent/toxin/acid/polyacid = -4,
		/datum/reagent/toxin/plantbgone = -8,
		/datum/reagent/medicine/adminordrazine = -5
		)
	var/global/list/pestkiller_reagents = list(
		/datum/reagent/consumable/sugar = 2,
		/datum/reagent/diethylamine = -2,
		/datum/reagent/medicine/adminordrazine = -5
		)
	var/global/list/water_reagents = list(
		/datum/reagent/water = 1,
		/datum/reagent/medicine/adminordrazine = 1,
		/datum/reagent/consumable/milk = 0.9,
		/datum/reagent/consumable/ethanol/beer = 0.7,
		/datum/reagent/fluorine = -0.5,
		/datum/reagent/chlorine = -0.5,
		/datum/reagent/phosphorus = -0.5,
		/datum/reagent/water = 1,
		/datum/reagent/consumable/sodawater = 1,
		)

	// Beneficial reagents also have values for modifying yield_mod and mut_mod (in that order).
	var/global/list/beneficial_reagents = list(
		/datum/reagent/consumable/ethanol/beer = list( -0.05, 0,   0   ),
		/datum/reagent/fluorine = list( -2,    0,   0   ),
		/datum/reagent/chlorine = list( -1,    0,   0   ),
		/datum/reagent/phosphorus = list( -0.75, 0,   0   ),
		/datum/reagent/consumable/sodawater = list(  0.1,  0,   0   ),
		/datum/reagent/toxin/acid = list( -1,    0,   0   ),
		/datum/reagent/toxin/acid/polyacid = list( -2,    0,   0   ),
		/datum/reagent/toxin/plantbgone = list( -2,    0,   0.2 ),
		/datum/reagent/medicine/cryoxadone = list(  3,    0,   0   ),
		/datum/reagent/ammonia = list(  0.5,  0,   0   ),
		/datum/reagent/diethylamine = list(  1,    0,   0   ),
		/datum/reagent/consumable/nutriment = list(  0.5,  0.1,   0 ),
		/datum/reagent/radium = list( -1.5,  0,   0.2 ),
		/datum/reagent/medicine/adminordrazine = list(  1,    1,   1   ),
		/datum/reagent/toxin/fertilizer/robustharvest = list(  0,    0.2, 0   ),
		/datum/reagent/toxin/fertilizer/left4zed = list(  0,    0,   0.2 )
		)

	// Mutagen list specifies minimum value for the mutation to take place, rather
	// than a bound as the lists above specify.
	var/global/list/mutagenic_reagents = list(
		/datum/reagent/radium = 8,
		/datum/reagent/toxin/mutagen = 15
		)

/obj/machinery/hydroponics/Initialize(mapload)
	. = ..()

	var/static/list/connections = list(
		COMSIG_OBJ_TRY_ALLOW_THROUGH = PROC_REF(can_climb_over),
		COMSIG_FIND_FOOTSTEP_SOUND = TYPE_PROC_REF(/atom/movable, footstep_override),
		COMSIG_TURF_CHECK_COVERED = TYPE_PROC_REF(/atom/movable, turf_cover_check),
	)
	AddElement(/datum/element/connect_loc, connections)

	temp_chem_holder = new()
	temp_chem_holder.create_reagents(10)
	create_reagents(200, AMOUNT_VISIBLE|REFILLABLE)
	update_icon()
	start_processing()

/obj/machinery/hydroponics/process()

	//Do this even if we're not ready for a plant cycle.
	process_reagents()

	// Update values every cycle rather than every process() tick.
	if(force_update)
		force_update = 0
	else if(world.time < (lastcycle + cycledelay))
		return
	lastcycle = world.time

	// Mutation level drops each main tick.
	mutation_level -= rand(2,4)

	// Weeds like water and nutrients, there's a chance the weed population will increase.
	// Bonus chance if the tray is unoccupied.
	if(waterlevel > 10 && nutrilevel > 2 && prob(isnull(seed) ? 5 : 1))
		weedlevel += 1 * HYDRO_SPEED_MULTIPLIER

	// There's a chance for a weed explosion to happen if the weeds take over.
	// Plants that are themselves weeds (weed_tolerance > 10) are unaffected.
	if (weedlevel >= 10 && prob(10))
		if(!seed || weedlevel >= seed.weed_tolerance)
			weed_invasion()

	// If there is no seed data (and hence nothing planted),
	// or the plant is dead, process nothing further.
	if(!seed || dead)
		if(draw_warnings) update_icon() //Harvesting would fail to set alert icons properly.
		return

	// Advance plant age.
	if(prob(30)) age += 1 * HYDRO_SPEED_MULTIPLIER

	//Highly mutable plants have a chance of mutating every tick.
	if(seed.immutable == -1)
		var/mut_prob = rand(1,100)
		if(mut_prob <= 5) mutate(mut_prob == 1 ? 2 : 1)

	// Other plants also mutate if enough mutagenic compounds have been added.
	if(!seed.immutable)
		if(prob(min(mutation_level,100)))
			mutate((rand(100) < 15) ? 2 : 1)
			mutation_level = 0

	// Maintain tray nutrient and water levels.
	if(seed.nutrient_consumption > 0 && nutrilevel > 0 && prob(25))
		nutrilevel -= max(0,seed.nutrient_consumption * HYDRO_SPEED_MULTIPLIER)
	if(seed.water_consumption > 0 && waterlevel > 0  && prob(25))
		waterlevel -= max(0,seed.water_consumption * HYDRO_SPEED_MULTIPLIER)

	// Make sure the plant is not starving or thirsty. Adequate
	// water and nutrients will cause a plant to become healthier.
	var/healthmod = rand(1,3) * HYDRO_SPEED_MULTIPLIER
	if(seed.requires_nutrients && prob(35))
		health += (nutrilevel < 2 ? -healthmod : healthmod)
	if(seed.requires_water && prob(35))
		health += (waterlevel < 10 ? -healthmod : healthmod)

	// Check that pressure, heat and light are all within bounds.
	// First, handle an open system or an unconnected closed system.

	// Process it.
//	if(pressure < seed.lowkpa_tolerance || pressure > seed.highkpa_tolerance)
//		health -= healthmod

//	if(abs(temperature - seed.ideal_heat) > seed.heat_tolerance)
//		health -= healthmod

	// If we're attached to a pipenet, then we should let the pipenet know we might have modified some gasses
//	if (closed_system && connected_port)
//		update_connected_network()

	// Toxin levels beyond the plant's tolerance cause damage, but
	// toxins are sucked up each tick and slowly reduce over time.
	if(toxins > 0)
		var/toxin_uptake = max(1,round(toxins/10))
		if(toxins > seed.toxins_tolerance)
			health -= toxin_uptake
		toxins -= toxin_uptake

	// Check for pests and weeds.
	// Some carnivorous plants happily eat pests.
	if(pestlevel > 0)
		if(seed.carnivorous)
			health += HYDRO_SPEED_MULTIPLIER
			pestlevel -= HYDRO_SPEED_MULTIPLIER
		else if (pestlevel >= seed.pest_tolerance)
			health -= HYDRO_SPEED_MULTIPLIER

	// Some plants thrive and live off of weeds.
	if(weedlevel > 0)
		if(seed.parasite)
			health += HYDRO_SPEED_MULTIPLIER
			weedlevel -= HYDRO_SPEED_MULTIPLIER
		else if (weedlevel >= seed.weed_tolerance)
			health -= HYDRO_SPEED_MULTIPLIER

	// Handle life and death.
	// If the plant is too old, it loses health fast.
	if(age > seed.lifespan)
		health -= rand(3,5) * HYDRO_SPEED_MULTIPLIER

	// When the plant dies, weeds thrive and pests die off.
	if(health <= 0)
		dead = 1
		mutation_level = 0
		harvest = 0
		weedlevel += 1 * HYDRO_SPEED_MULTIPLIER
		pestlevel = 0

	// If enough time (in cycles, not ticks) has passed since the plant was harvested, we're ready to harvest again.
	else if(seed.products && length(seed.products) && age > seed.production && \
	(age - lastproduce) > seed.production && (!harvest && !dead))
		harvest = 1
		lastproduce = age

	if(prob(3))  // On each tick, there's a chance the pest population will increase
		pestlevel += 0.1 * HYDRO_SPEED_MULTIPLIER

	check_level_sanity()
	update_icon()

//Process reagents being input into the tray.
/obj/machinery/hydroponics/proc/process_reagents()

	if(!reagents)
		return

	if(reagents.total_volume <= 0)
		return

	reagents.trans_to(temp_chem_holder, min(reagents.total_volume,rand(1,3)))

	for(var/datum/reagent/R in temp_chem_holder.reagents.reagent_list)

		var/reagent_total = temp_chem_holder.reagents.get_reagent_amount(R.type)

		if(seed && !dead)
			//Handle some general level adjustments.
			if(toxic_reagents[R.type])
				toxins += toxic_reagents[R.type]         * reagent_total
			if(weedkiller_reagents[R.type])
				weedlevel -= weedkiller_reagents[R.type] * reagent_total
			if(pestkiller_reagents[R.type])
				pestlevel += pestkiller_reagents[R.type] * reagent_total

			// Beneficial reagents have a few impacts along with health buffs.
			if(beneficial_reagents[R.type])
				health += beneficial_reagents[R.type][1]       * reagent_total
				yield_mod += beneficial_reagents[R.type][2]    * reagent_total
				mutation_mod += beneficial_reagents[R.type][3] * reagent_total

			// Mutagen is distinct from the previous types and mostly has a chance of proccing a mutation.
			if(mutagenic_reagents[R.type])
				mutation_level += reagent_total*mutagenic_reagents[R.type]+mutation_mod

		// Handle nutrient refilling.
		if(nutrient_reagents[R.type])
			nutrilevel += nutrient_reagents[R.type]  * reagent_total

		// Handle water and water refilling.
		var/water_added = 0
		if(water_reagents[R.type])
			var/water_input = water_reagents[R.type] * reagent_total
			water_added += water_input
			waterlevel += water_input

		// Water dilutes toxin level.
		if(water_added > 0)
			toxins -= round(water_added/4)

	temp_chem_holder.reagents.clear_reagents()
	check_level_sanity()
	update_icon()

//Harvests the product of a plant.
/obj/machinery/hydroponics/proc/harvest(mob/user)

	//Harvest the product of the plant,
	if(!seed || !harvest || !user)
		return

	if(closed_system)
		to_chat(user, "You can't harvest from the plant while the lid is shut.")
		return

	seed.harvest(user,yield_mod)

	// Reset values.
	harvest = 0
	lastproduce = age

	if(!seed.harvest_repeat)
		yield_mod = 0
		seed = null
		dead = 0
		age = 0
		sampled = 0
		mutation_mod = 0

	check_level_sanity()
	update_icon()

//Clears out a dead plant.
/obj/machinery/hydroponics/proc/remove_dead(mob/user)
	if(!user || !dead)
		return

	if(closed_system)
		to_chat(user, "You can't remove the dead plant while the lid is shut.")
		return

	seed = null
	dead = 0
	sampled = 0
	age = 0
	yield_mod = 0
	mutation_mod = 0

	to_chat(user, "You remove the dead plant from the [src].")
	check_level_sanity()
	update_icon()

//Refreshes the icon and sets the luminosity
/obj/machinery/hydroponics/update_icon()
	update_bioluminescence()
	return ..()

/obj/machinery/hydroponics/update_overlays()
	. = ..()

	// Updates the plant overlay.
	if(!isnull(seed))

		if(draw_warnings && health <= (seed.endurance / 2))
			. += "over_lowhealth3"

		if(dead)
			. += "[seed.plant_icon]-dead"
		else if(harvest)
			. += "[seed.plant_icon]-harvest"
		else if(age < seed.maturation)

			var/t_growthstate
			if(age >= seed.maturation)
				t_growthstate = seed.growth_stages
			else
				t_growthstate = round(seed.maturation / seed.growth_stages)

			. += "[seed.plant_icon]-grow[t_growthstate]"
			lastproduce = age
		else
			. += "[seed.plant_icon]-grow[seed.growth_stages]"

	//Draw the cover.
	if(closed_system)
		. += "hydrocover"

	//Updated the various alert icons.
	if(draw_warnings)
		if(waterlevel <= 10)
			. += "over_lowwater3"
		if(nutrilevel <= 2)
			. += "over_lownutri3"
		if(weedlevel >= 5 || pestlevel >= 5 || toxins >= 40)
			. += "over_alert3"
		if(harvest)
			. += "over_harvest3"

/obj/machinery/hydroponics/proc/update_bioluminescence()
	// Update bioluminescence.
	if(seed)
		if(seed.biolum)
			if(seed.biolum_colour)
				set_light(round(seed.potency / 10), l_color = seed.biolum_colour)
			else
				set_light(round(seed.potency / 10))
			return

	set_light(0)

// If a weed growth is sufficient, this proc is called.
/obj/machinery/hydroponics/proc/weed_invasion()

	//Remove the seed if something is already planted.
	if(seed) seed = null
	seed = GLOB.seed_types[pick(list("reishi","nettles","amanita","mushrooms","plumphelmet","towercap","harebells","weeds"))]
	if(!seed)
		return //Weed does not exist, someone fucked up.

	dead = 0
	age = 0
	health = seed.endurance
	lastcycle = world.time
	harvest = 0
	weedlevel = 0
	pestlevel = 0
	sampled = 0
	update_icon()
	visible_message(span_notice("[src] has been overtaken by [seed.display_name]."))


/obj/machinery/hydroponics/proc/mutate(severity)

	// No seed, no mutations.
	if(!seed)
		return

	// Check if we should even bother working on the current seed datum.
	if(seed.mutants && length(seed.mutants) && severity > 1)
		mutate_species()
		return

	// We need to make sure we're not modifying one of the global seed datums.
	// If it's not in the global list, then no products of the line have been
	// harvested yet and it's safe to assume it's restricted to this tray.
	if(!isnull(GLOB.seed_types[seed.name]))
		seed = seed.diverge()
	seed.mutate(severity,get_turf(src))


/obj/machinery/hydroponics/proc/check_level_sanity()
	//Make sure various values are sane.
	if(seed)
		health = max(0,min(seed.endurance,health))
	else
		health = 0
		dead = 0

	mutation_level = max(0,min(mutation_level,100))
	nutrilevel = max(0,min(nutrilevel,10))
	waterlevel = max(0,min(waterlevel,100))
	pestlevel = max(0,min(pestlevel,10))
	weedlevel = max(0,min(weedlevel,10))
	toxins = max(0,min(toxins,10))

/obj/machinery/hydroponics/proc/mutate_species()

	var/previous_plant = seed.display_name
	var/newseed = seed.get_mutant_variant()
	seed = GLOB.seed_types[newseed] || seed

	dead = 0
	mutate(1)
	age = 0
	health = seed.endurance
	lastcycle = world.time
	harvest = 0
	weedlevel = 0

	update_icon()
	visible_message(span_warning("The <span class='notice'> [previous_plant] <span class='warning'> has suddenly mutated into <span class='notice'> [seed.display_name]!"))


/obj/machinery/hydroponics/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(.)
		return

	if(I.is_open_container())
		return

	else if(iswirecutter(I) || istype(I, /obj/item/tool/surgery/scalpel))
		if(!seed)
			to_chat(user, "There is nothing to take a sample from in \the [src].")
			return

		if(sampled)
			to_chat(user, "You have already sampled from this plant.")
			return

		if(dead)
			to_chat(user, "The plant is dead.")
			return

		// Create a sample.
		seed.harvest(user, yield_mod, 1)
		health -= (rand(3, 5) * 10)

		if(prob(30))
			sampled = TRUE

		// Bookkeeping.
		check_level_sanity()
		force_update = TRUE
		process()

	else if(istype(I, /obj/item/reagent_containers/syringe))
		var/obj/item/reagent_containers/syringe/S = I
		if(S.mode == 1)
			if(seed)
				return FALSE
			to_chat(user, "There's no plant to inject.")
			return TRUE
		else
			if(seed)
				to_chat(user, "You can't get any extract out of this plant.")
			else
				to_chat(user, "There's nothing to draw something from.")
			return TRUE

	else if(istype(I, /obj/item/seeds))
		var/obj/item/seeds/S = I

		if(seed)
			to_chat(user, span_warning("\The [src] already has seeds in it!"))
			return

		user.drop_held_item()

		if(!S.seed)
			to_chat(user, "The packet seems to be empty. You throw it away.")
			qdel(I)
			return

		to_chat(user, "You plant the [S.seed.seed_name] [S.seed.seed_noun].")

		if(S.seed.spread == 1)
			message_admins("[key_name(user)] has planted a creeper packet.")
			var/obj/effect/plant_controller/creeper/PC = new(get_turf(src))
			if(PC)
				PC.seed = S.seed
		else if(S.seed.spread == 2)
			message_admins("[key_name(user)] has planted a spreading vine packet.")
			var/obj/effect/plant_controller/PC = new(get_turf(src))
			if(PC)
				PC.seed = S.seed
		else
			seed = S.seed //Grab the seed datum.
			dead = FALSE
			age = 1
			//Snowflakey, maybe move this to the seed datum
			health = seed.endurance
			lastcycle = world.time

		qdel(I)

		check_level_sanity()
		update_icon()

	else if(istype(I, /obj/item/tool/minihoe))  // The minihoe
		if(weedlevel <= 0)
			to_chat(user, span_warning("This plot is completely devoid of weeds. It doesn't need uprooting."))
			return

		user.visible_message(span_warning("[user] starts uprooting the weeds."), span_warning("You remove the weeds from the [src]."))
		weedlevel = 0
		update_icon()

	else if(istype(I, /obj/item/storage/bag/plants))
		var/obj/item/storage/bag/plants/S = I

		attack_hand(user)
		for(var/obj/item/reagent_containers/food/snacks/grown/G in user.loc)
			if(!S.storage_datum.can_be_inserted(G, user))
				return
			S.storage_datum.handle_item_insertion(G, TRUE, user)

	else if(istype(I, /obj/item/tool/plantspray))
		var/obj/item/tool/plantspray/spray = I
		user.drop_held_item()
		toxins += spray.toxicity
		pestlevel -= spray.pest_kill_str
		weedlevel -= spray.weed_kill_str
		to_chat(user, "You spray [src] with [I].")
		playsound(loc, 'sound/effects/spray3.ogg', 25, 1, 3)
		qdel(I)

		check_level_sanity()
		update_icon()

	else if(iswrench(I))
		playsound(loc, 'sound/items/ratchet.ogg', 25, 1)
		anchored = !anchored
		to_chat(user, "You [anchored ? "wrench" : "unwrench"] \the [src].")


/obj/machinery/hydroponics/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return

	if(harvest)
		harvest(user)
	else if(dead)
		remove_dead(user)

	else
		if(seed && !dead)
			to_chat(usr, "[src] has [span_notice("[seed.display_name] \black planted.")]")
			if(health <= (seed.endurance / 2))
				to_chat(usr, "The plant looks [span_warning("unhealthy.")]")
		else
			to_chat(usr, "[src] is empty.")
		to_chat(usr, "Water: [round(waterlevel,0.1)]/100")
		to_chat(usr, "Nutrient: [round(nutrilevel,0.1)]/10")
		if(weedlevel >= 5)
			to_chat(usr, "[src] is [span_warning("filled with weeds!")]")
		if(pestlevel >= 5)
			to_chat(usr, "[src] is [span_warning("filled with tiny worms!")]")


/obj/machinery/hydroponics/verb/close_lid()
	set name = "Toggle Tray Lid"
	set category = "IC.Object"
	set src in view(1)

	if(!usr || usr.stat || usr.restrained())
		return

	closed_system = !closed_system
	to_chat(usr, "You [closed_system ? "close" : "open"] the tray's lid.")
	update_icon()

/obj/machinery/hydroponics/slashable
	resistance_flags = XENO_DAMAGEABLE
	max_integrity = 80

#undef HYDRO_SPEED_MULTIPLIER

/obj/machinery/light/blue
	base_icon_state = "btube"
	icon_state = "tube_empty"
	light_color = LIGHT_COLOR_BLUE_FLAME
	bulb_colour = LIGHT_COLOR_BLUE_FLAME
	desc = "A lighting fixture that is fitted with a bright blue fluorescent light tube. Looking at it for too long makes your eyes go watery."
	light_type = /obj/item/light_bulb/tube/blue

/obj/machinery/light/small/blue
	light_color = LIGHT_COLOR_BLUE_FLAME
	bulb_colour = LIGHT_COLOR_BLUE_FLAME
	fitting = "bbulb"
	brightness = 4
	desc = "A small lighting fixture that is fitted with a bright blue fluorescent light bulb. Looking at it for too long makes your eyes go watery."
	light_type = /obj/item/light_bulb/bulb/blue

/obj/machinery/light/spot/blue
	name = "spotlight"
	light_color = LIGHT_COLOR_BLUE_FLAME
	bulb_colour = LIGHT_COLOR_BLUE_FLAME
	desc = "A wide light fixture fitted with a large, blue, very bright fluorescent light tube. You want to sneeze just looking at it."
	fitting = "large tube"
	light_type = /obj/item/light_bulb/tube/large
	brightness = 12

/obj/machinery/light/small/built/Initialize(mapload)
	. = ..()
	status = LIGHT_EMPTY
	update(FALSE)

/obj/machinery/prop/fuel_enhancer
	name = "fuel enhancer"
	desc = "A fuel enhancement system for dropships. It improves the thrust produced by the fuel combustion for faster travels. Fits inside the engine attach points. You need a powerloader to lift it."
	icon = 'icons/obj/structures/prop/mainship.dmi'
	icon_state = "fuel_enhancer"
	coverage = 25
	max_integrity = 350
	resistance_flags = XENO_DAMAGEABLE

/obj/machinery/prop/structurelattice
	name = "structural lattice"
	desc = "Like rebar, but in space."
	icon = 'icons/obj/structures/prop/mainship.dmi'
	icon_state = "structure_lattice"
	coverage = 50
	max_integrity = 750
	resistance_flags = XENO_DAMAGEABLE

/obj/machinery/space_heater/radiator
	name = "radiator"
	desc = "It's a radiator. It heats the room through convection with hot water. This one has a red handle."
	icon_state = "radiator"
	density = FALSE

/obj/machinery/space_heater/radiator/red
	icon_state = "radiator-r"

/obj/structure/barricade/handrail/urban
	icon_state = "plasticroadbarrierred"
	stack_amount = 0 //we do not want it to drop any stuff when destroyed
	destroyed_stack_amount = 0
	barricade_type = "plasticroadbarrierred"
	soft_armor = list(MELEE = 0, BULLET = 50, LASER = 50, ENERGY = 50, BOMB = 15, BIO = 100, FIRE = 100, ACID = 10)

// Plastic

/obj/structure/barricade/handrail/urban/handrail
	name = "handrail"
	icon_state = "handrail_hybrisa"
	barricade_type = "handrail_hybrisa"

/obj/structure/barricade/handrail/urban/road/metal
	name = "metal road barrier"
	icon_state = "centerroadbarrier"
	barricade_type = "centerroadbarrier"

/obj/structure/barricade/handrail/urban/road/metal/metaltan
	name = "metal road barrier"
	icon_state = "centerroadbarrier"
	barricade_type = "centerroadbarrier"

/obj/structure/barricade/handrail/urban/road/plastic
	name = "plastic road barrier"
	icon_state = "plasticroadbarrierred"
	barricade_type = "plasticroadbarrierred"

/obj/structure/barricade/handrail/urban/road/plastic/black
	name = "plastic road barrier"
	icon_state = "plasticroadbarrierblack"
	barricade_type = "plasticroadbarrierblack"

//Wood

/obj/structure/barricade/handrail/urban/road/plastic/blue
	name = "plastic road barrier"
	icon_state = "plasticroadbarrierblue"
	barricade_type = "plasticroadbarrierblue"

/obj/structure/barricade/handrail/urban/road/plastic/red
	name = "plastic road barrier"
	icon_state = "plasticroadbarrierred"
	barricade_type = "plasticroadbarrierred"

/obj/structure/barricade/handrail/urban/road/wood
	name = "wood road barrier"
	icon_state = "roadbarrierwood"
	barricade_type = "roadbarrierwood"

/obj/structure/barricade/handrail/urban/road/wood/blue
	name = "wood road barrier"
	icon_state = "roadbarrierpolice"
	barricade_type = "roadbarrierpolice"

// Metal

/obj/structure/barricade/handrail/urban/road/wood/orange
	name = "wood road barrier"
	icon_state = "roadbarrierwood"
	barricade_type = "roadbarrierwood"

/obj/structure/barricade/wooden
	name = "wooden barricade"
	desc = "A wall made out of wooden planks nailed together. Not very sturdy, but can provide some concealment."
	icon = 'icons/obj/structures/barricades/misc.dmi'
	icon_state = "wooden"
	max_integrity = 100
	layer = OBJ_LAYER
	stack_type = /obj/item/stack/sheet/wood
	stack_amount = 5
	destroyed_stack_amount = 3
	hit_sound = "sound/effects/natural/woodhit.ogg"
	can_change_dmg_state = FALSE
	barricade_type = "wooden"
	can_wire = FALSE

/obj/structure/barricade/wooden/add_debris_element()
	AddElement(/datum/element/debris, DEBRIS_WOOD, -40, 5)

/obj/structure/barricade/wooden/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(.)
		return

	if(!istype(I, /obj/item/stack/sheet/wood))
		return
	var/obj/item/stack/sheet/wood/D = I
	if(obj_integrity >= max_integrity)
		return

	if(D.get_amount() < 1)
		balloon_alert(user, "need more wood!")
		return

	if(LAZYACCESS(user.do_actions, src))
		return

	balloon_alert_to_viewers("repairing...")

	if(!do_after(user, 2 SECONDS, NONE, src, BUSY_ICON_FRIENDLY) || obj_integrity >= max_integrity)
		return

	if(get_self_acid())
		balloon_alert(user, "it's melting!")
		return TRUE

	if(!D.use(1))
		return

	repair_damage(max_integrity, user)
	balloon_alert_to_viewers("repaired")
	update_icon()


/*----------------------*/
// METAL
/*----------------------*/

#define BARRICADE_METAL_LOOSE 0
#define BARRICADE_METAL_ANCHORED 1
#define BARRICADE_METAL_FIRM 2

#define CADE_TYPE_BOMB "concussive armor"
#define CADE_TYPE_MELEE "ballistic armor"
#define CADE_TYPE_ACID "caustic armor"

#define CADE_UPGRADE_REQUIRED_SHEETS 1

//cade armor defines
#define CADE_UPGRADE_BOMB 80
#define CADE_UPGRADE_MELEE list(melee = 30, bullet = 50, laser = 50, energy = 50)
#define CADE_UPGRADE_ACID 35

/obj/structure/bed/bedroll
	name = "unfolded bedroll"
	desc = "Perfect for those long missions, when there's nowhere else to sleep, you remembered to bring at least one thing of comfort."
	icon = 'icons/obj/rollerbed.dmi'
	icon_state = "bedroll_o"
	foldabletype = /obj/item/roller/bedroll
	accepts_bodybag = FALSE
	buildstacktype = null

/obj/structure/bed/roller/hospital
	name = "hospital bed"
	icon = 'icons/obj/rollerbed.dmi'
	icon_state = "bigrollerempty_up"
	foldabletype = null
	base_bed_icon = "bigrollerempty"

/obj/structure/bed/roller/hospital/bloody
	base_bed_icon = "bigrollerbloodempty"

/obj/structure/bed/roller/hospital_empty
	icon_state = "bigrollerempty2_down"
	foldabletype = null

/obj/structure/bed/roller/hospital_empty/bigrollerbloodempty
	icon_state = "bigrollerbloodempty_down"
	buckling_y = 2
	base_bed_icon = "bigrollerbloodempty"

// Hospital divider (not a bed)

/obj/structure/bed/roller/hospital_empty/bigrollerempty
	icon_state = "bigrollerempty_down"
	buckling_y = 2
	base_bed_icon = "bigrollerempty"

/obj/structure/bed/roller/hospital_empty/bigrollerempty2
	icon_state = "bigrollerempty2_down"
	buckling_y = 2
	base_bed_icon = "bigrollerempty2"

/obj/structure/bed/roller/hospital_empty/bigrollerempty3
	icon_state = "bigrollerempty3_down"
	buckling_y = 2
	base_bed_icon = "bigrollerempty3"

/obj/structure/bed/urban/hospital/hospitaldivider
	name = "hospital divider"
	desc = "A hospital divider for privacy."
	icon = 'icons/obj/structures/prop/urban/urbanrandomprops.dmi'
	icon_state = "hospitalcurtain"
	layer = ABOVE_MOB_LAYER
	anchored = TRUE

/obj/structure/cargo_container/nt
	icon_state = "NT"

/obj/structure/closet/crate/trashcart/food
	desc = "A heavy, metal foodcart with wheels."
	icon = 'icons/obj/structures/prop/urban/urbanrandomprops.dmi';
	icon_state = "foodcart2"
	icon_closed = "foodcart2"
	icon_opened = "foodcart2_open"
	name = "food cart"

/obj/structure/concrete_planter
	name = "concrete seated planter"
	desc = "A decorative concrete planter."
	icon = 'icons/obj/structures/prop/concrete_planter.dmi'
	icon_state = "planter"
	density = TRUE
	resistance_flags = XENO_DAMAGEABLE
	allow_pass_flags = PASS_LOW_STRUCTURE|PASSABLE|PASS_WALKOVER
	coverage = 80

/obj/structure/concrete_planter/Initialize(mapload)
	. = ..()
	setDir(dir)
	var/static/list/connections = list(
		COMSIG_OBJ_TRY_ALLOW_THROUGH = PROC_REF(can_climb_over),
	)
	AddElement(/datum/element/connect_loc, connections)
	AddComponent(/datum/component/climbable)

/obj/structure/concrete_planter/setDir(newdir)
	. = ..()
	if(dir & (EAST|WEST))
		pixel_x = -4
		bound_width = 32
		bound_height = 64
	else
		pixel_y = -7
		bound_width = 64
		bound_height = 32

/obj/structure/concrete_planter/seat
	name = "concrete seated planter"
	desc = "A decorative concrete planter with seating attached. The seats are fitted with synthetic leather, they've faded in time."
	icon_state = "planter_seats"

/obj/structure/dropship_piece/four/dropshipfront
	icon_state = "dropshipfrontwhite1"
	opacity = FALSE

/obj/structure/dropship_piece/four/dropshipventfour
	icon_state = "dropshipvent4"

/obj/structure/dropship_piece/four/dropshipventone
	icon_state = "dropshipvent1"

/obj/structure/dropship_piece/four/dropshipventthree
	icon_state = "dropshipvent3"

/obj/structure/dropship_piece/four/dropshipventtwo
	icon_state = "dropshipvent2"

/obj/structure/dropship_piece/four/dropshipwingtopone
	icon_state = "dropshipwingtop1"

/obj/structure/dropship_piece/four/dropshipwingtoptwo
	icon_state = "dropshipwingtop2"

/obj/structure/dropship_piece/four/rearwing/leftbottom
	icon_state = "white_rearwing_lb"

/obj/structure/dropship_piece/four/rearwing/lefttop
	icon_state = "white_rearwing_lt"

/obj/structure/dropship_piece/four/rearwing/rightbottom
	icon_state = "white_rearwing_rb"

//Dropship control console

/obj/structure/dropship_piece/four/rearwing/righttop
	icon_state = "white_rearwing_rt"

/obj/structure/fence/dark
	icon = 'icons/obj/smooth_objects/dark_fence.dmi'
	destroyed_icon = 'icons/obj/smooth_objects/brokenfence_dark.dmi'

/obj/structure/filingcabinet/nondense
	density = FALSE

/obj/structure/largecrate/random/barrel/black
	name = "black barrel"
	desc = "A black storage barrel"
	icon_state = "barrel_black"

/obj/structure/largecrate/random/barrel/brown
	name = "black brown"
	desc = "A black storage barrel"
	icon_state = "barrel_brown"

/obj/structure/largecrate/random/mini
	name = "small crate"
	desc = "The large supply crate's cousin, 1st removed."
	icon_state = "mini_crate"
	density = FALSE

/obj/structure/largecrate/random/mini/ammo
	desc = "A small metal crate. Here, Freeman ammo!"
	name = "small ammocase"
	icon_state = "mini_ammo"
	stuff = list(
		/obj/item/ammo_magazine/pistol,
		/obj/item/ammo_magazine/revolver,
		/obj/item/ammo_magazine/rifle,
		/obj/item/ammo_magazine/rifle/extended,
		/obj/item/ammo_magazine/shotgun,
		/obj/item/ammo_magazine/shotgun/buckshot,
		/obj/item/ammo_magazine/shotgun/flechette,
	)

/obj/structure/largecrate/random/mini/chest
	desc = "A small plastic crate wrapped with securing elastic straps."
	icon_state = "mini_chest"
	name = "small chest"

/obj/structure/largecrate/random/mini/chest/b
	icon_state = "mini_chest_b"
	name = "small chest"

/obj/structure/largecrate/random/mini/chest/c
	icon_state = "mini_chest_c"
	name = "small chest"

/obj/structure/largecrate/random/mini/med
	desc = "A small metal crate containing medical supplies."
	icon_state = "mini_medcase"
	name = "small medcase"
	num_things = 1 //funny lootbox tho.
	stuff = list(
		/obj/item/storage/pill_bottle/packet/tricordrazine,
		/obj/item/tool/crowbar/red,
		/obj/item/flashlight,
		/obj/item/storage/pill_bottle/packet/tramadol,
		/obj/item/stack/medical/splint,
		/obj/item/healthanalyzer,
		/obj/item/tool/extinguisher/mini,
		/obj/item/tool/shovel/etool,
		/obj/item/tool/screwdriver,
	)

/obj/structure/largecrate/random/barrel/deconstruct(disassembled = TRUE, mob/living/blame_mob)
	if(dropmetal)
		new /obj/item/stack/sheet/metal/small_stack(src)
	return ..()


/obj/structure/largecrate/random/barrel/welder_act(mob/living/user, obj/item/tool/weldingtool/welder)
	if(!welder.isOn())
		return FALSE
	if(!do_after(user, 5 SECONDS, NONE, src, BUSY_ICON_BUILD))
		return TRUE
	if(!welder.remove_fuel(1, user))
		return TRUE
	user.visible_message(span_notice("[user] welds \the [src] open."),
		span_notice("You weld open \the [src]."),
		span_notice("You hear loud hissing and the sound of metal falling over."))
	playsound(loc, 'sound/items/welder2.ogg', 25, TRUE)
	deconstruct(TRUE)
	return TRUE


/obj/structure/largecrate/random/barrel/examine(mob/user)
	. = ..()
	. += span_notice("You need a blowtorch to weld this open!")

/obj/structure/largecrate/random/barrel/add_debris_element()
	AddElement(/datum/element/debris, DEBRIS_SPARKS, -40, 8, 1)

/obj/structure/largecrate/random/mini/small_case
	desc = "A small hard-shell case. What could be inside?"
	icon_state = "mini_case"
	name = "small case"

/obj/structure/largecrate/random/mini/small_case/b
	icon_state = "mini_case_b"
	name = "small case"

/obj/structure/largecrate/random/mini/small_case/c
	icon_state = "mini_case_c"
	name = "small case"

/obj/structure/largecrate/random/mini/wooden
	desc = "A small wooden crate. Two supporting ribs cross this one's frame."
	icon_state = "mini_wooden"
	name = "wooden crate"

/obj/structure/lattice/autosmooth
	icon = 'icons/obj/smooth_objects/lattice.dmi'
	icon_state = "lattice-0"
	layer = ABOVE_ALL_MOB_LAYER
	plane = GAME_PLANE
	base_icon_state = "lattice"
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_LATTICE_ABOVE)
	canSmoothWith = list(SMOOTH_GROUP_LATTICE_ABOVE)
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/structure/platform/mineral
	icon_state = "stone"

/obj/structure/platform/urban
	max_integrity = 120

/obj/structure/platform/urban/metalplatform2
	name = "raised metal edge"
	desc = "A raised level of metal, often used to elevate areas above others. You could probably climb it."
	icon_state = "strata_metalplatform2"

/obj/structure/platform/urban/metalplatform4
	icon_state = "hybrisaplatform"
	name = "raised metal platform"
	desc = "A raised level of metal, often used to elevate areas above others. You could probably climb it."

/obj/structure/platform_decoration/mineral
	icon_state = "stone_deco"

/obj/structure/platform_decoration/urban/engineer_corner
	name = "raised metal corner"
	desc = "The corner of what appears to be raised piece of metal, often used to imply the illusion of elevation in non-Euclidean 2d spaces. But you don't know that, you're just a spaceman with a rifle."
	icon_state = "engineer_platform_deco"

/obj/structure/platform_decoration/urban/metalplatformdeco2
	name = "raised metal corner"
	desc = "A raised level of metal, often used to elevate areas above others. This is the corner."
	icon_state = "strata_metalplatform_deco2"

/obj/structure/platform_decoration/urban/metalplatformdeco3
	name = "raised metal corner"
	desc = "A raised level of metal, often used to elevate areas above others. This is the corner."
	icon_state = "strata_metalplatform_deco3"

/obj/structure/platform_decoration/urban/metalplatformdeco4
	icon_state = "hybrisaplatform_deco"
	name = "raised metal corner"
	desc = "A raised level of metal, often used to elevate areas above others. You could probably climb it."

/obj/structure/platform_decoration/urban/rockdark
	name = "raised rock corner"
	desc = "A collection of stones and rocks that cap the edge of some conveniently 1-meter-long lengths of perfectly climbable chest high walls."
	icon_state = "kutjevo_rock_decodark"

/obj/structure/prop/mainship/mission_planning_system/white
	icon_state = "mps_w"

/obj/structure/prop/mainship/sensor_computer1/black
	icon_state = "blacksensor_comp_b1"

/obj/structure/prop/mainship/sensor_computer1/white
	icon_state = "sensor_comp_w"

/obj/structure/prop/mainship/sensor_computer2/black
	icon_state = "blacksensor_comp_b2"

/obj/structure/prop/mainship/sensor_computer2/white
	icon_state = "sensor_comp_w2"

/obj/structure/prop/mainship/sensor_computer3/black
	icon_state = "blacksensor_comp_b3"

/obj/structure/prop/mainship/sensor_computer3/white
	icon_state = "sensor_comp_w3"

/obj/structure/reagent_dispensers/fueltank/spacefuel
	name = "spacecraft fuel-mix tank"
	desc = "A fuel tank mix with fuel designed for various spacecraft, very combustible.";
	icon = 'icons/obj/structures/prop/urban/urbanrandomprops.dmi';

/obj/structure/reagent_dispensers/water_cooler/nondense
	density = FALSE

/obj/structure/rock/dark
	name = "boulder"
	desc = "A large rock. It's not cooking anything."

/obj/structure/rock/dark/large
	icon = 'icons/obj/structures/boulder_largedark.dmi'
	icon_state = "boulder_largedark1"
	bound_height = 64
	bound_width = 64

/obj/structure/rock/dark/large/three
	icon_state = "boulder_largedark3"

/obj/structure/rock/dark/large/two
	icon_state = "boulder_largedark2"

/obj/structure/rock/dark/small
	icon_state = "bouldersmalldark1"
	icon = 'icons/obj/structures/boulder_small.dmi'

/obj/structure/rock/dark/small/three
	icon_state = "bouldersmalldark3"

// Cave props

/obj/structure/rock/dark/small/two
	icon_state = "bouldersmalldark2"

/obj/structure/rock/dark/stalagmite
	icon = 'icons/obj/structures/prop/urban/urbanrandomprops.dmi'
	name = "stalagmite"
	icon_state = "stalagmite"
	desc = "A cave stalagmite."
	density = FALSE

/obj/structure/rock/dark/stalagmite/five
	icon_state = "stalagmite5"

//randomised icons

/obj/structure/rock/dark/stalagmite/four
	icon_state = "stalagmite4"

/obj/structure/rock/dark/stalagmite/one
	icon_state = "stalagmite1"

/obj/structure/rock/dark/stalagmite/three
	icon_state = "stalagmite3"

/obj/structure/rock/dark/stalagmite/two
	icon_state = "stalagmite2"

/obj/structure/rock/dark/wide
	icon = 'icons/obj/structures/boulder_widedark.dmi'
	icon_state = "boulderwidedark"
	bound_height = 32
	bound_width = 64

/obj/structure/rock/dark/wide/two
	icon_state = "boulderwidedark2"

/obj/structure/sign/double/barsign
	icon = 'icons/obj/structures/barsigns.dmi'
	icon_state = "off"

/obj/structure/window_frame/urban
	icon = 'icons/obj/smooth_objects/urban_window_frame.dmi'
	icon_state = "col_window_frame-0"
	base_icon_state = "col_window_frame"

/obj/structure/window_frame/urban/colony/engineering/reinforced

/turf/closed/mineral/smooth/black_stone
	icon = 'icons/turf/walls/black_stone_walls.dmi'
	icon_state = "black_stone_walls-0"
	walltype = "lava_wall"
	base_icon_state = "black_stone_walls"

/turf/closed/mineral/smooth/black_stone/indestructible
	resistance_flags = RESIST_ALL
	icon_state = "wall-invincible"

/turf/closed/mineral/smooth/engineerwall
	name = "strange metal wall"
	desc = "Nigh indestructible walls that make up the hull of an unknown ancient ship."
	icon = 'icons/turf/walls/engineer_walls_turf.dmi'
	icon_state = "engineer_walls_turf-255"
	walltype = "wall"
	base_icon_state = "engineer_walls_turf"

/turf/closed/mineral/smooth/engineerwall/indestructible
	resistance_flags = RESIST_ALL
	icon_state = "wall-invincible"

/turf/closed/shuttle/dropship4
	name = "\improper Normandy"
	icon = 'icons/turf/dropship4.dmi'
	icon_state = "1"

/turf/closed/shuttle/dropship4/aisle
	icon_state = "shuttle_interior_aisle"

/turf/closed/shuttle/dropship4/backplate
	icon_state = "back1"

/turf/closed/shuttle/dropship4/brokenconsoleone
	icon_state = "brokendropshipconsole1"

/turf/closed/shuttle/dropship4/brokenconsolethree
	icon_state = "brokendropshipconsole3"

/turf/closed/shuttle/dropship4/corners
	icon_state = "shuttle_exterior_corners"

/turf/closed/shuttle/dropship4/cornersalt
	icon_state = "shuttle_interior_corneralt"

/turf/closed/shuttle/dropship4/cornersalt2
	icon_state = "shuttle_interior_alt2"

/turf/closed/shuttle/dropship4/damagedconsoleone
	icon_state = "damaged_console1"

/turf/closed/shuttle/dropship4/damagedconsolethree
	icon_state = "damaged_console3"

/turf/closed/shuttle/dropship4/damagedconsoletwo
	icon_state = "damaged_console2"

/turf/closed/shuttle/dropship4/door
	icon_state = "shuttle_rear_door"

/turf/closed/shuttle/dropship4/edge
	icon_state = "shuttle_interior_edge"

/turf/closed/shuttle/dropship4/edge/alt
	icon_state = "shuttle_interior_edgealt"

/turf/closed/shuttle/dropship4/engine_sidealt
	icon_state = "shuttle_side_engine_alt"

/turf/closed/shuttle/dropship4/engineone
	icon_state = "shuttle_interior_backengine"

/turf/closed/shuttle/dropship4/enginethree
	icon_state = "shuttle_interior_backengine3"

/turf/closed/shuttle/dropship4/enginetwo
	icon_state = "shuttle_interior_backengine2"

/turf/closed/shuttle/dropship4/finleft
	icon_state = "shuttle_exterior_finnleft"

/turf/closed/shuttle/dropship4/finright
	icon_state = "shuttle_exterior_finnright"

/turf/closed/shuttle/dropship4/fins
	icon_state = "shuttle_exterior_fins"

/turf/closed/shuttle/dropship4/glassfour
	icon_state = "shuttle_glass4"

/turf/closed/shuttle/dropship4/glassseven
	icon_state = "shuttle_glass7"

/turf/closed/shuttle/dropship4/glassthree
	icon_state = "shuttle_glass3"

/turf/closed/shuttle/dropship4/interiorwindow
	icon_state = "shuttle_interior_inwards"

/turf/closed/shuttle/dropship4/left_engine
	icon_state = "left_engine"

/turf/closed/shuttle/dropship4/right_engine
	icon_state = "right_engine"

/turf/closed/shuttle/dropship4/window
	icon_state = "shuttle_window_glass"
	opacity = FALSE
	allow_pass_flags = PASS_GLASS

/turf/closed/shuttle/dropship4/window/alt
	icon_state = "shuttle_window_glass_alt"

/turf/closed/shuttle/dropship4/zwing_left
	icon_state = "zwing_left"

/turf/closed/shuttle/dropship4/zwing_right
	icon_state = "zwing_right"

/turf/closed/wall/r_wall/bunker
	icon = 'icons/turf/walls/junkwall.dmi'
	icon_state = "junkwall-0"
	base_icon_state = "junkwall"

/turf/closed/wall/r_wall/engineership
	name = "strange metal wall"
	desc = "Nigh indestructible walls that make up the hull of an unknown ancient ship."
	icon = 'icons/turf/walls/engineer_walls.dmi'
	icon_state = "engineer_walls-0"
	walltype = "wall"
	base_icon_state = "engineer_walls"

/turf/closed/wall/r_wall/engineership/invincible
	resistance_flags = RESIST_ALL
	icon_state = "wall-invincible"

/turf/closed/wall/r_wall/urban
	name = "reinforced metal walls"
	desc = "A thick and chunky metal wall ribbed with reinforced steel. The surface is barren and imposing."
	icon = 'icons/turf/walls/hybrisa_colony_walls.dmi'
	icon_state = "wall-reinforced"
	walltype = "wall"
	base_icon_state = "hybrisa_colony_walls"

/turf/closed/wall/r_wall/white_research_wall
	icon = 'icons/turf/walls/white_research_wall.dmi'
	icon_state = "white_research_wall-0"
	base_icon_state = "white_research_wall"

/turf/closed/wall/urban
	name = "bare metal walls"
	desc = "A thick and chunky metal wall. The surface is barren and imposing."
	icon = 'icons/turf/walls/urban_wall_regular.dmi'
	icon_state = "urban_wall_regular-0"
	walltype = "wall"
	base_icon_state = "urban_wall_regular"

/turf/closed/wall/urban/colony/ribbed
	name = "bare metal walls"
	desc = "A thick and chunky metal wall. The surface is barren and imposing."
	icon = 'icons/turf/walls/hybrisa_colony_walls.dmi'
	icon_state = "wall-reinforced"
	walltype = "wall"
	base_icon_state = "hybrisa_colony_walls"

/turf/open/floor/bluefour
	icon_state = "blue4"

/turf/open/floor/bluethree
	icon_state = "blue3"

/turf/open/floor/box
	icon_state = "box"

/turf/open/floor/cyanfour
	icon_state = "cyan4"

/turf/open/floor/cyanthree
	icon_state = "cyan3"

/turf/open/floor/floorthree
	icon_state = "floor3"

/turf/open/floor/floortwo
	icon_state = "floor2"

/turf/open/floor/marked
	icon_state = "marked"

/turf/open/floor/multi_tiles
	icon_state = "multi_tiles"

/turf/open/floor/officesquares
	icon_state = "officesquares"

/turf/open/floor/officetiles
	icon_state = "officetiles"

/turf/open/floor/orange_cover
	icon_state = "orange_cover"

/turf/open/floor/orange_edge
	icon_state = "orange_edge"

/turf/open/floor/orange_icorner
	icon_state = "orange_icorner"

/turf/open/floor/plate
	icon_state = "plate"

/turf/open/floor/redfour
	icon_state = "red4"

/turf/open/floor/redone
	icon_state = "red1"

/turf/open/floor/redthree
	icon_state = "red3"

/turf/open/floor/spiralblueoffice
	icon_state = "spiralblueoffice"

/turf/open/floor/spiralplate
	icon_state = "spiralplate"

/turf/open/floor/squares
	icon_state = "squares"

/turf/open/floor/tile/dark/brown3
	icon_state = "darkbrown3"

/turf/open/floor/yellowthree
	icon_state = "yellow3"

/turf/open/ground/sandrock
	icon = 'icons/turf/ground_map.dmi'
	icon_state = "varadero_0"
	minimap_color = MINIMAP_DIRT

//////////////////////////////////////////////////////////////////////


// Stubs for map paths without explicit upstream type definitions
/turf/closed/wall/urban/colony
	parent_type = /turf/closed/wall/urban/colony/ribbed

/turf/closed/wall/urban/colony/engineering
	parent_type = /turf/closed/wall/urban/colony/engineering/ribbed

/obj/effect/urban/decal
	icon = 'icons/effects/64x64hybrisa_decals.dmi'
	layer = TURF_DECAL_LAYER
	plane = FLOOR_PLANE

/turf/open/floor/mainship/research/containment
	icon = 'icons/turf/mainship.dmi'
	icon_state = "containment"

/obj/structure/window/framed/urban/colony
	parent_type = /obj/structure/window/framed/urban/colony/office

/obj/structure/window/framed/urban/colony/engineering
	parent_type = /obj/structure/window/framed/urban/colony/engineering/hull

/obj/structure/window/framed/urban/spaceport
	parent_type = /obj/structure/window/framed/urban/spaceport/reinforced

/obj/effect/landmark/lv624/fog_blocker/xeno_spawn
	parent_type = /obj/effect/landmark/fog_blocker/xeno_spawn

/obj/structure/platform_decoration/shiva
	parent_type = /obj/structure/platform_decoration/shiva/catwalk

/obj/structure/platform_decoration/shiva/catwalk
	icon_state = "shiva_deco"
	name = "raised rubber cord platform"
	desc = "Reliable steel and a polymer rubber substitute. Doesn't crack under cold weather."
