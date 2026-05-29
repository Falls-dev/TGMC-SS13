/obj/vehicle/sealed/armored/multitile/box_van
	name = "\improper VAN - Korobochka"
	desc = "A small box-type van. It's a compact vehicle with a rectangular cargo area, typically designed for transporting goods or small equipment. It features a high roof and straight sides, providing ample vertical space for storage. Its size makes it maneuverable and ideal for urban driving and tight spaces."
	icon = 'icons/obj/armored/2x2/box_van.dmi'
	icon_state = "van_base"
	//damage_icon_path = 'icons/obj/armored/2x2/box-van_damage_overlay.dmi'
	hitbox = /obj/hitbox/medium
	interior = /datum/interior/armored/box_van
	permitted_weapons = NONE
	permitted_mods = NONE
	armored_flags = ARMORED_HAS_HEADLIGHTS|ARMORED_PURCHASABLE_TRANSPORT|ARMORED_SELF_WALL_DAMAGE
	required_entry_skill = SKILL_LARGE_VEHICLE_DEFAULT
	minimap_icon_state = "van"
	turret_icon = null
	pixel_w = 0
	pixel_z = -40
	max_integrity = 200
	soft_armor = list(MELEE = 10, BULLET = 20 , LASER = 20, ENERGY = 20, BOMB = 10, BIO = 10, FIRE = 10, ACID = 10)
	max_occupants = 5
	enter_delay = 0.2 SECONDS
	ram_damage = 5
	move_delay = 0.15 SECONDS
	glide_size = 8.5
	easy_load_list = list(
		/obj/structure/largecrate,
		/obj/structure/closet/crate,
	)
