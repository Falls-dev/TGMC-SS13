/obj/machinery/tank_part_fabricator
	name = "vehicle part fabricator"
	desc = "A large automated 3D printer for producing new vehicle parts and maintaining old ones."
	density = TRUE
	anchored = TRUE
	use_power = IDLE_POWER_USE
	req_access = list(ACCESS_MARINE_ARMORED)
	idle_power_usage = 20
	bound_width = 64
	icon = 'icons/obj/machines/drone_fab.dmi'
	icon_state = "drone_fab_idle"
	/// actual UI that will be interacted with
	var/datum/supply_ui/vehicles/supply_ui

/obj/machinery/tank_part_fabricator/interact(mob/user)
	. = ..()
	if(.)
		return
	if(!allowed(user))
		return
	if(!supply_ui)
		supply_ui = new(src)
		supply_ui.shuttle_id = SHUTTLE_VEHICLE_SUPPLY
		supply_ui.home_id = "vehicle_home"
		supply_ui.faction = FACTION_TERRAGOV
	return supply_ui.interact(user)

/**
 * Tank weapon fabricator for the Combined Arms campaign mission.
 * Tanks spawn without a primary weapon, this machine hands out a weapon kit (the gun and its ammo) for each tank.
 * Only works while a mission with tank_fabricator_enabled is running, and only for its own faction.
 */
/obj/machinery/campaign_tank_fabricator
	name = "tank weapon fabricator"
	desc = "A large automated fabricator that produces the primary weapon and ammunition for the battalion's tanks. One weapon kit is available per deployed tank."
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE
	resistance_flags = INDESTRUCTIBLE
	bound_width = 64
	icon = 'icons/obj/machines/drone_fab.dmi'
	icon_state = "drone_fab_idle"
	///Faction that can use this fabricator
	var/fabricator_faction = FACTION_TERRAGOV
	///Weapon kits, kit name = list(item type = amount)
	var/list/weapon_kits = list(
		"LTB main cannon" = list(
			/obj/item/armored_weapon = 1,
			/obj/item/ammo_magazine/tank/ltb_cannon/heavy = 18,
			/obj/item/ammo_magazine/tank/ltb_cannon/apfds = 12,
			/obj/item/ammo_magazine/tank/ltb_cannon/canister/incendiary = 5,
		),
		"LTA-AP chaingun" = list(
			/obj/item/armored_weapon/ltaap = 1,
			/obj/item/ammo_magazine/tank/ltaap_chaingun/hv = 20,
		),
		"Bushwhacker autocannon" = list(
			/obj/item/armored_weapon/tank_autocannon = 1,
			/obj/item/ammo_magazine/tank/autocannon = 6,
			/obj/item/ammo_magazine/tank/autocannon/high_explosive = 4,
		),
	)
	///Stops two people choosing at the same time
	var/in_use = FALSE

/obj/machinery/campaign_tank_fabricator/som
	fabricator_faction = FACTION_SOM
	weapon_kits = list(
		"Volkite carronade" = list(
			/obj/item/armored_weapon/volkite_carronade = 1,
			/obj/item/ammo_magazine/tank/volkite_carronade = 20,
		),
		"Particle lance" = list(
			/obj/item/armored_weapon/particle_lance = 1,
			/obj/item/ammo_magazine/tank/particle_lance = 30,
		),
		"Coilgun" = list(
			/obj/item/armored_weapon/coilgun = 1,
			/obj/item/ammo_magazine/tank/coilgun = 40,
		),
	)

/obj/machinery/campaign_tank_fabricator/interact(mob/user)
	. = ..()
	if(.)
		return
	var/mob/living/living_user = user
	if(!istype(living_user) || living_user.faction != fabricator_faction)
		to_chat(user, span_warning("Access denied, this fabricator doesn't recognise you."))
		return
	if(in_use)
		to_chat(user, span_warning("[src] is already in use."))
		return
	if(!can_dispense(user))
		return
	in_use = TRUE
	var/list/kit_names = list()
	for(var/kit_name in weapon_kits)
		kit_names += kit_name
	var/chosen_kit = tgui_input_list(user, "Choose the primary weapon kit for a tank. Only one kit per tank.", "Tank weapon fabricator", kit_names)
	in_use = FALSE
	if(!chosen_kit || !weapon_kits[chosen_kit])
		return
	if(!Adjacent(user) || user.incapacitated())
		return
	//the mission could have ended or the kits could have run out while the menu was open
	if(!can_dispense(user))
		return
	dispense_kit(user, chosen_kit)

///Checks the mission is the right type, still running, and that this faction has kits left. Tells the user why not if it fails
/obj/machinery/campaign_tank_fabricator/proc/can_dispense(mob/user)
	var/datum/campaign_mission/mission = get_current_mission()
	if(!mission?.tank_fabricator_enabled || mission.outcome)
		to_chat(user, span_warning("[src] is offline. It only operates during a Combined Arms operation."))
		return FALSE
	if(LAZYACCESS(mission.tank_kits_remaining, fabricator_faction) <= 0)
		to_chat(user, span_warning("[src] has already produced a weapon kit for every tank deployed to this mission."))
		return FALSE
	return TRUE

///Takes one kit from the mission's allowance and drops the weapon and its ammo in front of the machine
/obj/machinery/campaign_tank_fabricator/proc/dispense_kit(mob/user, kit_name)
	var/datum/campaign_mission/mission = get_current_mission()
	var/kits_left = LAZYACCESS(mission.tank_kits_remaining, fabricator_faction) - 1
	LAZYSET(mission.tank_kits_remaining, fabricator_faction, kits_left)
	var/list/kit = weapon_kits[kit_name]
	var/turf/drop_turf = get_step(src, SOUTH)
	if(!drop_turf || drop_turf.density)
		drop_turf = get_turf(src)
	for(var/obj/typepath AS in kit)
		for(var/num = 1 to kit[typepath])
			new typepath(drop_turf)
	visible_message(span_notice("[src] whirs and ejects the [kit_name] weapon kit."))
	to_chat(user, span_notice("[kits_left] weapon kit\s remaining for your battalion this mission."))
