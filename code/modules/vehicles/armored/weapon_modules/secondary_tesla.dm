//Довольно глупо реализовывать механику энергооружия для техники лишь для теслы. Сделаем костыль.
/obj/item/armored_weapon/secondary_tesla
	name = "\improper SHG-BLCK secondary tesla"
	desc = "Увеличенная тесла-шок пушка морпехов с питанием от техники. Идеально для поддержки со спины."
	icon_state = "tesla"
	hud_state_empty = "flame_empty"
	interior_fire_sound = null
	armored_weapon_flags = MODULE_SECONDARY
	ammo = /obj/item/ammo_magazine/tank/tesla
	fire_sound = list('sound/weapons/guns/fire/tesla.ogg')
	accepted_ammo = list(/obj/item/ammo_magazine/tank/tesla)
	fire_mode = GUN_FIREMODE_SEMIAUTO
	projectile_delay = 4 SECONDS //У ручной пушки кд 4
	max_ammo = 0 //Ничо брать нельзя



/obj/item/ammo_magazine/tank/tesla
	name = "Tesla cell"
	desc = "Не то, что вы должны видеть"
	icon_state = "sflamer"
	max_rounds = INFINITY //Бесконечный БК
	default_ammo = /datum/ammo/energy/tesla/focused //Чтоб летело через тиммейтов
