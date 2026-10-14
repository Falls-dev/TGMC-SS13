/// Links fixed tent equipment after the whole template has initialized.
/datum/component/tent_supported_object
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/obj/structure/tent/linked_tent

/datum/component/tent_supported_object/Initialize()
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE
	var/atom/movable/source = parent
	linked_tent = locate(/obj/structure/tent) in source.loc
	if(linked_tent)
		RegisterSignal(linked_tent, COMSIG_QDELETING, PROC_REF(tent_collapse))

/datum/component/tent_supported_object/Destroy()
	linked_tent = null
	return ..()

/datum/component/tent_supported_object/proc/tent_collapse()
	SIGNAL_HANDLER
	qdel(parent)

/obj/structure/tent_curtain
	name = "tent curtains"
	icon = 'icons/obj/structures/tents_equipment.dmi'
	icon_state = "curtains-classic-o"
	desc = "Field tent curtains. Use to open or close them."
	atom_flags = ON_BORDER
	layer = ABOVE_OBJ_LAYER
	dir = SOUTH
	alpha = 180
	obj_flags = NONE
	allow_pass_flags = PASS_THROW | PASS_PROJECTILE
	coverage = 0
	var/camouflage = "classic"

/obj/structure/tent_curtain/Initialize(mapload)
	. = ..()
	switch(SSmapping.configs[GROUND_MAP]?.armor_style)
		if(MAP_ARMOR_STYLE_JUNGLE)
			camouflage = "jungle"
		if(MAP_ARMOR_STYLE_DESERT)
			camouflage = "desert"
		if(MAP_ARMOR_STYLE_ICE)
			camouflage = "snow"
		if(MAP_ARMOR_STYLE_PRISON)
			camouflage = "urban"
	var/static/list/connections = list(COMSIG_ATOM_EXIT = PROC_REF(on_try_exit))
	AddElement(/datum/element/connect_loc, connections)
	update_icon()
	return INITIALIZE_HINT_LATELOAD

/obj/structure/tent_curtain/LateInitialize()
	AddComponent(/datum/component/tent_supported_object)

/obj/structure/tent_curtain/update_icon_state()
	. = ..()
	icon_state = "curtains-[camouflage][density ? "" : "-o"]"

/obj/structure/tent_curtain/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	playsound(src, 'sound/effects/rustle1.ogg', 10, TRUE)
	density = !density
	update_icon()
	return TRUE

/obj/structure/tent_curtain/attack_alien(mob/living/carbon/xenomorph/user)
	visible_message(span_warning("[user] tears [src] to shreds!"))
	qdel(src)
	return TRUE

/obj/item/radio/intercom/tent
	name = "field command intercom"
	frequency = FREQ_COMMAND

/obj/item/radio/intercom/tent/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/item/radio/intercom/tent/LateInitialize()
	AddComponent(/datum/component/tent_supported_object)

/obj/item/radio/intercom/tent/process()
	return // Self-powered field radio.

/obj/machinery/computer/camera_advanced/overwatch/tent
	use_power = NO_POWER_USE

/obj/machinery/computer/camera_advanced/overwatch/tent/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/camera_advanced/overwatch/tent/LateInitialize()
	AddComponent(/datum/component/tent_supported_object)

/obj/machinery/computer/supplycomp/tent
	use_power = NO_POWER_USE

/obj/machinery/computer/supplycomp/tent/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/supplycomp/tent/LateInitialize()
	AddComponent(/datum/component/tent_supported_object)

/obj/machinery/vending/nanomed/tent
	use_power = NO_POWER_USE

/obj/machinery/vending/nanomed/tent/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/vending/nanomed/tent/LateInitialize()
	AddComponent(/datum/component/tent_supported_object)

/obj/machinery/vending/cargo_supply/tent
	use_power = NO_POWER_USE

/obj/machinery/vending/cargo_supply/tent/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/vending/cargo_supply/tent/LateInitialize()
	AddComponent(/datum/component/tent_supported_object)

/obj/machinery/microwave/tent
	use_power = NO_POWER_USE

/obj/machinery/microwave/tent/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/microwave/tent/LateInitialize()
	AddComponent(/datum/component/tent_supported_object)

/obj/machinery/vending/coffee/tent
	use_power = NO_POWER_USE

/obj/machinery/vending/coffee/tent/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/vending/coffee/tent/LateInitialize()
	AddComponent(/datum/component/tent_supported_object)

/obj/machinery/vending/ingredients/tent
	use_power = NO_POWER_USE

/obj/machinery/vending/ingredients/tent/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/vending/ingredients/tent/LateInitialize()
	AddComponent(/datum/component/tent_supported_object)

/obj/machinery/processor/tent
	use_power = NO_POWER_USE

/obj/machinery/processor/tent/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/processor/tent/LateInitialize()
	AddComponent(/datum/component/tent_supported_object)

/// Local ingredient vendor for the ported mess tent.
/obj/machinery/vending/ingredients
	name = "field kitchen ingredients"
	icon_state = "snack"
	icon_vend = "snack-vend"
	icon_deny = "snack-deny"
	products = list(
		/obj/item/reagent_containers/food/snacks/egg = 12,
		/obj/item/reagent_containers/food/snacks/flour = 8,
		/obj/item/reagent_containers/food/snacks/meat = 12,
	)

/obj/structure/tent_curtain/projectile_hit(atom/movable/projectile/proj, cardinal_move, uncrossing)
	return FALSE
