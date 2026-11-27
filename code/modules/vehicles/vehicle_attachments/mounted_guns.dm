/obj/item/vehicle_module/mounted_gun
	icon = 'icons/obj/vehicles.dmi'
	icon_state = ""
	slot = ATTACHMENT_SLOT_WEAPON
	w_class = WEIGHT_CLASS_BULKY
	attach_features_flags = ATTACH_ACTIVATION|ATTACH_REMOVABLE|ATTACH_NO_HANDS
	///The gun mounted on a vehicle. Initial value is the type to use
	var/obj/item/weapon/gun/mounted_gun
	///Firing angle for the mounted weapon
	var/firing_angle = 120

/obj/item/vehicle_module/mounted_gun/Initialize(mapload)
	if(!mounted_gun)
		return INITIALIZE_HINT_QDEL
	. = ..()
	mounted_gun = new mounted_gun(src)
	mounted_gun.gun_fire_angle = firing_angle
	action_icon = mounted_gun.icon
	action_icon_state = mounted_gun.icon_state

/obj/item/vehicle_module/mounted_gun/Destroy()
	QDEL_NULL(mounted_gun)
	return ..()

/obj/item/vehicle_module/mounted_gun/on_unbuckle(datum/source, mob/living/unbuckled_mob, force = FALSE)
	if(mounted_gun.loc == unbuckled_mob)
		unbuckled_mob.dropItemToGround(mounted_gun, TRUE)
	return ..()

/obj/item/vehicle_module/mounted_gun/activate(mob/living/user)
	if(mounted_gun.loc == user)
		on_weapon_equipped(null, user)
		return FALSE
	if(!user.put_in_active_hand(mounted_gun) && !user.put_in_inactive_hand(mounted_gun))
		to_chat(user, span_warning("Could not equip weapon! Click [parent] with a free hand to equip."))
		return FALSE
	RegisterSignal(mounted_gun, COMSIG_MOVABLE_MOVED, PROC_REF(on_weapon_moved))
	RegisterSignal(mounted_gun, COMSIG_ITEM_EQUIPPED, PROC_REF(on_weapon_equipped))
	return TRUE

///Handles the weapon being moved
/obj/item/vehicle_module/mounted_gun/proc/on_weapon_moved(obj/item/source)
	SIGNAL_HANDLER
	if(ismob(mounted_gun.loc)) //we have to handle it after its fully equipped or it becomes cursed
		return
	reequip_weapon()

///Handles the weapon being put into an equip slot
/obj/item/vehicle_module/mounted_gun/proc/on_weapon_equipped(obj/item/source, mob/user)
	SIGNAL_HANDLER
	user.dropItemToGround(mounted_gun, TRUE)
	reequip_weapon()

///Safely puts the weapon back into storage
/obj/item/vehicle_module/mounted_gun/proc/reequip_weapon()
	UnregisterSignal(mounted_gun, list(COMSIG_MOVABLE_MOVED, COMSIG_ITEM_EQUIPPED))
	mounted_gun.forceMove(src)



/obj/item/vehicle_module/mounted_gun/autocannon
	name = "dual AC-32 light autocannons"
	desc = "A pair of triple barreled 'light' gatling guns designed to be mounted in light vehicles such as the SOM hover bikes. A smaller calibre round is used for optimal internal magazine capacity, but makes up for this with a ferocious rate of fire."
	icon = 'icons/obj/vehicles/big_bike.dmi'
	icon_state = "bike_autocannon"
	should_use_obj_appeareance = FALSE
	mounted_gun = /obj/item/weapon/gun/bike_autocannon

/obj/item/vehicle_module/mounted_gun/volkite
	name = "mounted Demi-Culverin"
	desc = "A paired set of volkite weapons mounted into light vehicles such as SOM hover bikes. While they lack the raw power of some other volkite weapons, they make up for this through sheer volume of fire and integrate recharging power source."
	icon = 'icons/obj/vehicles/hover_bike.dmi'
	icon_state = "bike_volkite"
	attachment_layer = TANK_DECORATION_LAYER + 0.01
	should_use_obj_appeareance = FALSE
	mounted_gun = /obj/item/weapon/gun/energy/lasgun/lasrifle/volkite/demi_culverin

///bike volkite

/obj/item/vehicle_module/mounted_gun/minigun
	name = "dual V-44 light gatling guns"
	desc = "A pair of triple barreled 'light' gatling guns designed to be mounted in light vehicles such as SOM hover bikes. A smaller calibre round is used for optimal internal magazine capacity, but makes up for this with a ferocious rate of fire."
	icon = 'icons/obj/vehicles/hover_bike.dmi'
	icon_state = "bike_minigun"
	attachment_layer = TANK_DECORATION_LAYER + 0.01
	should_use_obj_appeareance = FALSE
	mounted_gun = /obj/item/weapon/gun/bike_minigun
