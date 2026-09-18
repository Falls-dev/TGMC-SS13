/obj/item/storage/box/crate
	name = "crate"
	desc = "It's just an ordinary wooden crate."
	icon = 'icons/obj/items/storage/box.dmi'
	icon_state = "case"

/obj/item/storage/box/crate/Initialize(mapload, ...)
	. = ..()
	storage_datum.foldable = /obj/item/stack/sheet/wood

/obj/item/storage/box/crate/update_icon_state()
	. = ..()
	icon_state = length(contents) ? initial(icon_state) : "empty_case"

/obj/item/storage/box/crate/m42c_system
	name = "\improper antimaterial scoped rifle system (recon set)"
	desc = "A large case containing your very own long-range sniper rifle. Drag this sprite into you to open it up!\nNOTE: You cannot put items back inside this case."
	icon_state = "sniper_case"
	w_class = WEIGHT_CLASS_HUGE
	slowdown = 1

/obj/item/storage/box/crate/m42c_system/Initialize(mapload, ...)
	. = ..()
	storage_datum.storage_slots = 12
	storage_datum.max_storage_space = 0

/obj/item/storage/box/crate/m42c_system/PopulateContents()
	new /obj/item/clothing/suit/modular/xenonauten/light(src)
	new /obj/item/clothing/head/modular/m10x(src)
	new /obj/item/clothing/glasses/night/m42_night_goggles(src)
	new /obj/item/ammo_magazine/sniper(src)
	new /obj/item/ammo_magazine/sniper/incendiary(src)
	new /obj/item/ammo_magazine/sniper/flak(src)
	new /obj/item/binoculars/tactical(src)
	new /obj/item/storage/backpack/marine/smock(src)
	new /obj/item/weapon/gun/pistol/vp70(src)
	new /obj/item/ammo_magazine/pistol/vp70(src)
	new /obj/item/ammo_magazine/pistol/vp70(src)
	new /obj/item/weapon/gun/rifle/sniper/antimaterial(src)
	new /obj/item/bodybag/tarp(src)

/obj/item/storage/box/crate/m42c_system_Jungle
	name = "\improper antimaterial scoped rifle system (marksman set)"
	desc = "A large case containing your very own long-range sniper rifle. Drag this sprite into you to open it up!\nNOTE: You cannot put items back inside this case."
	icon_state = "sniper_case"
	w_class = WEIGHT_CLASS_HUGE
	slowdown = 1

/obj/item/storage/box/crate/m42c_system_Jungle/Initialize(mapload, ...)
	. = ..()
	storage_datum.storage_slots = 9
	storage_datum.max_storage_space = 0

/obj/item/storage/box/crate/m42c_system_Jungle/PopulateContents()
	new /obj/item/clothing/suit/modular/xenonauten/light(src)
	new /obj/item/clothing/head/modular/m10x(src)
	new /obj/item/clothing/glasses/m42_goggles(src)
	new /obj/item/ammo_magazine/sniper(src)
	new /obj/item/ammo_magazine/sniper(src)
	new /obj/item/ammo_magazine/sniper/incendiary(src)
	new /obj/item/weapon/gun/rifle/sniper/antimaterial(src)
	if(SSmapping.configs[GROUND_MAP].environment_traits[MAP_COLD])
		new /obj/item/clothing/under/marine/camo/snow(src)
		new /obj/item/storage/backpack/marine/satchel(src)
		new /obj/item/bodybag/tarp/snow(src)
	else
		new /obj/item/facepaint/sniper(src)
		new /obj/item/storage/backpack/marine/smock(src)
		new /obj/item/bodybag/tarp(src)

/obj/item/storage/box/crate/sentry
	name = "\improper ST-571 sentry crate"
	desc = "A large case containing all you need to set up an automated sentry."
	icon_state = "sentry_case"
	w_class = WEIGHT_CLASS_HUGE
	storage_type = /datum/storage/box/crate/sentry

/obj/item/storage/box/crate/sentry/PopulateContents()
	new /obj/item/weapon/gun/sentry/basic(src)
	new /obj/item/ammo_magazine/sentry(src)

/obj/item/storage/box/crate/spec
	name = "specialist equipment case"
	desc = "A large case containing specialist equipment. Drag this sprite onto yourself to open it up!\nNOTE: You cannot put items back inside this case."
	icon_state = "sniper_case"
	w_class = WEIGHT_CLASS_HUGE
	slowdown = 1

/obj/item/storage/box/crate/spec/Initialize(mapload, ...)
	. = ..()
	storage_datum.foldable = null
	storage_datum.storage_slots = 24
	storage_datum.max_storage_space = 0
	storage_datum.max_w_class = WEIGHT_CLASS_GIGANTIC

/obj/item/storage/box/crate/spec/scout
	name = "\improper Scout specialist equipment case"
	desc = "A large case containing a BR-8 scout rifle, thermal cloak, night optics, C4 and scout binoculars.\nDrag this sprite onto yourself to open it up! NOTE: You cannot put items back inside this case."

/obj/item/storage/box/crate/spec/scout/PopulateContents()
	new /obj/item/weapon/gun/rifle/tx8/scout(src)
	new /obj/item/ammo_magazine/rifle/tx8(src)
	new /obj/item/ammo_magazine/rifle/tx8(src)
	if(prob(50))
		new /obj/item/ammo_magazine/rifle/tx8/incendiary(src)
	else
		new /obj/item/ammo_magazine/rifle/tx8/impact(src)
	new /obj/item/storage/backpack/marine/satchel/scout_cloak(src)
	new /obj/item/clothing/glasses/night/m42_night_goggles(src)
	new /obj/item/explosive/plastique(src)
	new /obj/item/explosive/plastique(src)
	new /obj/item/binoculars/tactical/scout(src)
	new /obj/item/bodybag/tarp(src)

/obj/item/storage/box/crate/spec/sniper
	name = "\improper Sniper specialist equipment case"
	desc = "A large case containing an SR-26 scoped rifle, night optics, smock, sniper cloak and mixed sniper ammunition.\nDrag this sprite onto yourself to open it up! NOTE: You cannot put items back inside this case."

/obj/item/storage/box/crate/spec/sniper/PopulateContents()
	new /obj/item/weapon/gun/rifle/sniper/antimaterial(src)
	new /obj/item/ammo_magazine/sniper(src)
	new /obj/item/ammo_magazine/sniper(src)
	if(prob(50))
		new /obj/item/ammo_magazine/sniper/incendiary(src)
	else
		new /obj/item/ammo_magazine/sniper/flak(src)
	new /obj/item/implanter/skill/firearms(src)
	new /obj/item/clothing/glasses/night_vision(src)
	new /obj/item/binoculars/tactical(src)
	if(SSmapping.configs[GROUND_MAP].environment_traits[MAP_COLD])
		new /obj/item/clothing/under/marine/camo/snow(src)
		new /obj/item/storage/backpack/marine/satchel(src)
		new /obj/item/bodybag/tarp/snow(src)
	else
		new /obj/item/facepaint/sniper(src)
		new /obj/item/storage/backpack/marine/smock(src)
		new /obj/item/bodybag/tarp(src)

/obj/item/storage/box/crate/spec/anti_materiel
	name = "\improper Anti-materiel sniper specialist equipment case"
	desc = "A large case containing an RG-220 railgun, night optics, smock and anti-armor ammunition.\nDrag this sprite onto yourself to open it up! NOTE: You cannot put items back inside this case."

/obj/item/storage/box/crate/spec/anti_materiel/PopulateContents()
	new /obj/item/weapon/gun/rifle/railgun(src)
	new /obj/item/ammo_magazine/railgun(src)
	new /obj/item/ammo_magazine/railgun(src)
	if(prob(50))
		new /obj/item/ammo_magazine/railgun/hvap(src)
	else
		new /obj/item/ammo_magazine/railgun/smart(src)
		new /obj/item/ammo_magazine/railgun/smart(src)
	new /obj/item/clothing/glasses/night/m56_goggles(src)
	new /obj/item/implanter/skill/firearms(src)
	new /obj/item/storage/backpack/marine/smock(src)
	new /obj/item/bodybag/tarp(src)
	new /obj/item/facepaint/sniper(src)
	new /obj/item/binoculars/tactical(src)

/obj/item/storage/box/crate/spec/grenadier
	name = "\improper Heavy grenadier specialist equipment case"
	desc = "A large case containing a GL-70 grenade launcher and a high-capacity grenade belt.\nDrag this sprite onto yourself to open it up! NOTE: You cannot put items back inside this case."

/obj/item/storage/box/crate/spec/grenadier/PopulateContents()
	new /obj/item/weapon/gun/grenade_launcher/multinade_launcher/unloaded(src)
	if(prob(50))
		new /obj/item/storage/box/visual/grenade/trailblazer/phosphorus(src)
	else
		new /obj/item/storage/box/visual/grenade/drain/sticky(src)
	new /obj/item/storage/belt/grenade/b17(src)
	new /obj/item/storage/pouch/explosive/antigas(src)
	new /obj/item/storage/box/visual/grenade/hefa(src)
	new /obj/item/explosive/plastique(src)
	new /obj/item/binoculars/tactical(src)

/obj/item/storage/box/crate/spec/sharp
	name = "\improper SHARP operator specialist equipment case"
	desc = "A large case containing a GL-54 airburst grenade launcher and mixed 20mm magazines.\nDrag this sprite onto yourself to open it up! NOTE: You cannot put items back inside this case."

/obj/item/storage/box/crate/spec/sharp/PopulateContents()
	new /obj/item/weapon/gun/rifle/tx54(src)
	new /obj/item/ammo_magazine/rifle/tx54(src)
	new /obj/item/ammo_magazine/rifle/tx54(src)
	if(prob(50))
		new /obj/item/ammo_magazine/rifle/tx54/incendiary/G(src)
		new /obj/item/ammo_magazine/rifle/tx54/incendiary/G(src)
	else
		new /obj/item/ammo_magazine/rifle/tx54/incendiary/X(src)
	new /obj/item/ammo_magazine/rifle/tx54/smoke/antigas(src)
	new /obj/item/weapon/shield/riot/marine/deployable(src)
	new /obj/item/binoculars/tactical(src)

/obj/item/storage/box/crate/spec/demo
	name = "\improper Demolitionist specialist equipment case"
	desc = "A large case containing an RL-152 SADAR bag with mixed rockets and C4.\nDrag this sprite onto yourself to open it up! NOTE: You cannot put items back inside this case."

/obj/item/storage/box/crate/spec/demo/PopulateContents()
	new /obj/item/storage/holster/backholster/rlsadar/full(src)
	if(prob(50))
		new /obj/item/ammo_magazine/rocket/sadar(src)
		new /obj/item/ammo_magazine/rocket/sadar(src)
	else if(prob(50))
		new /obj/item/ammo_magazine/rocket/sadar/ap(src)
	else
		new /obj/item/ammo_magazine/rocket/sadar/wp(src)
	new /obj/item/ammo_magazine/rocket/sadar/wp(src)
	new /obj/item/explosive/plastique(src)
	new /obj/item/explosive/plastique(src)
	new /obj/item/explosive/plastique(src)
	new /obj/item/explosive/plastique(src)
	new /obj/item/explosive/plastique/genghis_charge(src)
	new /obj/item/explosive/plastique/genghis_charge(src)
	new /obj/item/binoculars/tactical(src)

/obj/item/storage/box/crate/spec/pyro
	name = "\improper Pyrotechnician specialist equipment case"
	desc = "A large case containing an FL-84 flamethrower bag, spare tanks and extinguishers.\nDrag this sprite onto yourself to open it up! NOTE: You cannot put items back inside this case."

/obj/item/storage/box/crate/spec/pyro/PopulateContents()
	new /obj/item/storage/holster/backholster/flamer(src)
	new /obj/item/weapon/gun/flamer/big_flamer/marinestandard(src)
	if(prob(50))
		new /obj/item/ammo_magazine/flamer_tank/large(src)
		new /obj/item/ammo_magazine/flamer_tank/large(src)
	else
		new /obj/item/ammo_magazine/flamer_tank/large/G(src)
	new /obj/item/ammo_magazine/flamer_tank/large/X(src)
	new /obj/item/ammo_magazine/flamer_tank/large/X(src)
	new /obj/item/tool/extinguisher(src)
	new /obj/item/tool/extinguisher/mini(src)
	new /obj/item/binoculars/tactical(src)

/obj/item/storage/box/crate/spec/breacher
	name = "\improper Breacher specialist equipment case"
	desc = "A large case containing an SH-39 combat shotgun, boarding shield, sledgehammer and breaching charges.\nDrag this sprite onto yourself to open it up! NOTE: You cannot put items back inside this case."

/obj/item/storage/box/crate/spec/breacher/PopulateContents()
	new /obj/item/weapon/gun/shotgun/zx76(src)
	new /obj/item/ammo_magazine/shotgun/incendiary(src)
	new /obj/item/ammo_magazine/shotgun/tracker(src)
	if(prob(50))
		new /obj/item/storage/holster/blade/katana/full(src)
		new /obj/item/weapon/shield/riot/marine(src)
	else
		new /obj/item/weapon/twohanded/sledgehammer(src)
	new /obj/item/explosive/plastique(src)
	new /obj/item/explosive/plastique(src)
	new /obj/item/binoculars/tactical(src)
