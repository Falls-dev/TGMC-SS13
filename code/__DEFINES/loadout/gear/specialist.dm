GLOBAL_LIST_INIT(specialist_gear_listed_products, list(
	/obj/item/storage/box/crate/spec/scout = list(CAT_SPECKIT, "Scout Set", 0, "white"),
	/obj/item/storage/box/crate/spec/sniper = list(CAT_SPECKIT, "Sniper Set", 0, "white"),
	/obj/item/storage/box/crate/spec/anti_materiel = list(CAT_SPECKIT, "Anti-Materiel Sniper Set", 0, "white"),
	/obj/item/storage/box/crate/spec/grenadier = list(CAT_SPECKIT, "Heavy Grenadier Set", 0, "white"),
	/obj/item/storage/box/crate/spec/sharp = list(CAT_SPECKIT, "SHARP Operator Set", 0, "white"),
	/obj/item/storage/box/crate/spec/demo = list(CAT_SPECKIT, "Demolitionist Set", 0, "white"),
	/obj/item/storage/box/crate/spec/pyro = list(CAT_SPECKIT, "Pyro Set", 0, "white"),
	/obj/item/storage/box/crate/spec/breacher = list(CAT_SPECKIT, "Breacher Set", 0, "white"),

// Бритчер сет
	/obj/item/ammo_magazine/shotgun/tracker = list(CAT_SPECSUP, "12 gauge tracker shells", 5, "spec_breacher"),
	/obj/item/ammo_magazine/shotgun/incendiary = list(CAT_SPECSUP, "Box of incendiary shells", 10, "spec_breacher"),
	/obj/item/implanter/blade = list(CAT_SPECSUP, "Mantis Blade Implant", 25, "spec_breacher"),
	/obj/item/implanter/sandevistan = list(CAT_SPECSUP, "Sandevistan Implant", 20, "spec_breacher"),
	/obj/item/storage/pill_bottle/russian_red = list(CAT_SPECSUP, "Russian Red Pills", 15, "spec_breacher"),
	/obj/item/storage/pill_bottle/doctor_delight = list(CAT_SPECSUP, "Doctor Delight Pills", 15, "spec_breacher"),

// Снайпер сет
	/obj/item/ammo_magazine/rifle/tx8 = list(CAT_SPECSUP, "BR-8 scout rifle magazine", 5, "spec_sniper"),
	/obj/item/ammo_magazine/rifle/tx8/incendiary = list(CAT_SPECSUP, "BR-8 scout rifle incendiary magazine", 10, "spec_sniper"),
	/obj/item/ammo_magazine/rifle/tx8/impact = list(CAT_SPECSUP, "BR-8 scout rifle impact magazine", 10, "spec_sniper"),

// Скаут сет
	/obj/item/ammo_magazine/sniper = list(CAT_SPECSUP, "SR-26 marksman magazine", 5, "spec_scout"),
	/obj/item/ammo_magazine/sniper/incendiary = list(CAT_SPECSUP, "SR-26 incendiary magazine", 10, "spec_scout"),
	/obj/item/ammo_magazine/sniper/flak = list(CAT_SPECSUP, "SR-26 flak magazine", 10, "spec_scout"),

// Демо сет
	/obj/item/ammo_magazine/rocket/sadar = list(CAT_SPECSUP, "RL-152 SADAR HE rocket", 10, "spec_demo"),
	/obj/item/ammo_magazine/rocket/sadar/ap = list(CAT_SPECSUP, "RL-152 SADAR AP rocket", 10, "spec_demo"),
	/obj/item/ammo_magazine/rocket/sadar/wp = list(CAT_SPECSUP, "RL-152 SADAR WP rocket", 10, "spec_demo"),

// Пиро сет
	/obj/item/ammo_magazine/flamer_tank/large = list(CAT_SPECSUP, "FL-84 incinerator tank", 15, "spec_pyro"),
	/obj/item/ammo_magazine/flamer_tank/large/G = list(CAT_SPECSUP, "FL-84 G-fuel tank", 20, "spec_pyro"),
	/obj/item/ammo_magazine/flamer_tank/large/X = list(CAT_SPECSUP, "FL-84 X-fuel tank", 20, "spec_pyro"),

// ШАРП сет
	/obj/item/ammo_magazine/rifle/tx54/incendiary = list(CAT_SPECSUP, "GL-54 incendiary magazine", 5, "spec_sharp"),
	/obj/item/ammo_magazine/rifle/tx54/incendiary/G = list(CAT_SPECSUP, "GL-54 G-fuel incendiary magazine", 10, "spec_sharp"),
	/obj/item/ammo_magazine/rifle/tx54/incendiary/X = list(CAT_SPECSUP, "GL-54 X-fuel incendiary magazine", 15, "spec_sharp"),
	/obj/item/ammo_magazine/rifle/tx54/smoke/tangle = list(CAT_SPECSUP, "GL-54 tanglefoot magazine", 5, "spec_sharp"),
	/obj/item/ammo_magazine/rifle/tx54/razor = list(CAT_SPECSUP, "GL-54 razor magazine", 20, "spec_sharp"),
	/obj/item/ammo_magazine/rifle/tx54/healing_foam = list(CAT_SPECSUP, "GL-54 healing foam magazine", 15, "spec_sharp"),

// Антиматериалка (рельса) сет
	/obj/item/ammo_magazine/railgun = list(CAT_SPECSUP, "RG-220 APDS round", 10, "spec_rail"),
	/obj/item/ammo_magazine/railgun/hvap = list(CAT_SPECSUP, "RG-220 HVAP round", 15, "spec_rail"),
	/obj/item/ammo_magazine/railgun/smart = list(CAT_SPECSUP, "RG-220 smart round", 15, "spec_rail"),
// Гренадёр сет
	/obj/item/storage/box/visual/grenade/frag = list(CAT_SPECSUP, "M40 HEDP grenade box", 5, "spec_grenadier"),
	/obj/item/storage/box/visual/grenade/hefa = list(CAT_SPECSUP, "M40 HEFA grenade box", 10, "spec_grenadier"),
	/obj/item/storage/box/visual/grenade/incendiary = list(CAT_SPECSUP, "M40 HIDP incendiary grenade box", 15, "spec_grenadier"),
	/obj/item/storage/box/visual/grenade/phosphorus = list(CAT_SPECSUP, "M40 HPDP phosphorous grenade box", 15, "spec_grenadier"),
	/obj/item/storage/box/visual/grenade/trailblazer/phosphorus = list(CAT_SPECSUP, "M40 trailblazer phosphorous grenade box", 20, "spec_grenadier"),
	/obj/item/storage/box/visual/grenade/drain/sticky = list(CAT_SPECSUP, "M40 drain sticky grenade box", 20, "spec_grenadier"),

// Остальное
	/obj/item/armor_module/module/fire_proof = list(CAT_SPECSUP, "Fireproof armor module", 25, "other"),
	/obj/item/armor_module/module/fire_proof_helmet = list(CAT_SPECSUP, "Fireproof helmet module", 25, "other"),
	/obj/item/minelayer = list(CAT_SPECSUP, "M-12 mine layer", 10, "other"),
	/obj/item/storage/box/explosive_mines = list(CAT_SPECSUP, "Box of M-12 mines", 15, "other"),
	/obj/item/implanter/jump_mod = list(CAT_SPECSUP, "Higher jump implant", 25, "other"),
	/obj/item/cell/night_vision_battery = list(CAT_SPECSUP, "Night vision battery", 15, "other"),
	/obj/item/explosive/plastique = list(CAT_SPECSUP, "Plastic explosive", 15, "other"),

))
