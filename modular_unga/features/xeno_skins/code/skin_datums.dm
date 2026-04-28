/// Модульная система внешек ксеноморфов.
/datum/xenomorph_skin
	var/name = "Базовый"
	var/icon
	var/effects_icon
	var/admin_only = FALSE

/datum/xenomorph_skin/proc/get_effects_icon()
	return effects_icon || icon

// Drone
/datum/xenomorph_skin/drone/base
	name = "Классический"
	icon = 'icons/Xeno/castes/drone.dmi'

/datum/xenomorph_skin/drone/rouny
	name = "Rouny"
	icon = 'modular_unga/features/xeno_skins/icons/drone/rouny.dmi'
	admin_only = TRUE

/datum/xenomorph_skin/drone/king
	name = "King"
	icon = 'modular_unga/features/xeno_skins/icons/drone/king.dmi'

/datum/xenomorph_skin/drone/cyborg
	name = "Cyborg"
	icon = 'modular_unga/features/xeno_skins/icons/drone/cyborg.dmi'

/datum/xenomorph_skin/drone/hornet
	name = "Hornet"
	icon = 'modular_unga/features/xeno_skins/icons/drone/hornet.dmi'

// Boiler
/datum/xenomorph_skin/boiler/base
	name = "Классический"
	icon = 'icons/Xeno/castes/boiler.dmi'

/datum/xenomorph_skin/boiler/rouny
	name = "Rouny"
	icon = 'modular_unga/features/xeno_skins/icons/boiler/rouny.dmi'
	admin_only = TRUE

// Bull
/datum/xenomorph_skin/bull/base
	name = "Классический"
	icon = 'icons/Xeno/castes/bull.dmi'

/datum/xenomorph_skin/bull/rouny
	name = "Rouny"
	icon = 'modular_unga/features/xeno_skins/icons/bull/rouny.dmi'
	admin_only = TRUE

// Crusher
/datum/xenomorph_skin/crusher/base
	name = "Классический"
	icon = 'icons/Xeno/castes/crusher.dmi'

/datum/xenomorph_skin/crusher/rouny
	name = "Rouny"
	icon = 'modular_unga/features/xeno_skins/icons/crusher/rouny.dmi'
	admin_only = TRUE

// Defender
/datum/xenomorph_skin/defender/base
	name = "Классический"
	icon = 'icons/Xeno/castes/defender.dmi'

/datum/xenomorph_skin/defender/rouny
	name = "Rouny"
	icon = 'modular_unga/features/xeno_skins/icons/defender/rouny.dmi'
	admin_only = TRUE

// Defiler
/datum/xenomorph_skin/defiler/base
	name = "Классический"
	icon = 'icons/Xeno/castes/defiler.dmi'

/datum/xenomorph_skin/defiler/rouny
	name = "Rouny"
	icon = 'modular_unga/features/xeno_skins/icons/defiler/rouny.dmi'
	admin_only = TRUE

// Gorger
/datum/xenomorph_skin/gorger/base
	name = "Классический"
	icon = 'icons/Xeno/castes/gorger.dmi'

/datum/xenomorph_skin/gorger/rouny
	name = "Rouny"
	icon = 'modular_unga/features/xeno_skins/icons/gorger/rouny.dmi'
	admin_only = TRUE

// Hivelord
/datum/xenomorph_skin/hivelord/base
	name = "Классический"
	icon = 'icons/Xeno/castes/hivelord.dmi'

/datum/xenomorph_skin/hivelord/rouny
	name = "Rouny"
	icon = 'modular_unga/features/xeno_skins/icons/hivelord/rouny.dmi'
	admin_only = TRUE

// King
/datum/xenomorph_skin/king/base
	name = "Классический"
	icon = 'icons/Xeno/castes/king/king.dmi'

/datum/xenomorph_skin/king/red
	name = "Red"
	icon = 'icons/Xeno/castes/king/red.dmi'

// Praetorian
/datum/xenomorph_skin/praetorian/base
	name = "Классический"
	icon = 'icons/Xeno/castes/praetorian.dmi'

/datum/xenomorph_skin/praetorian/rouny
	name = "Rouny"
	icon = 'modular_unga/features/xeno_skins/icons/praetorian/rouny.dmi'
	admin_only = TRUE

/datum/xenomorph_skin/praetorian/tacticool
	name = "Tacticool"
	icon = 'modular_unga/features/xeno_skins/icons/praetorian/tacticool.dmi'

// Queen
/datum/xenomorph_skin/queen/base
	name = "Классический"
	icon = 'icons/Xeno/castes/queen.dmi'

/datum/xenomorph_skin/queen/rouny
	name = "Rouny"
	icon = 'modular_unga/features/xeno_skins/icons/queen/rouny.dmi'
	admin_only = TRUE

// Ravager
/datum/xenomorph_skin/ravager/base
	name = "Классический"
	icon = 'icons/Xeno/castes/ravager.dmi'

/datum/xenomorph_skin/ravager/rouny
	name = "Rouny"
	icon = 'modular_unga/features/xeno_skins/icons/ravager/rouny.dmi'
	admin_only = TRUE

/datum/xenomorph_skin/ravager/bonehead
	name = "Bonehead"
	icon = 'modular_unga/features/xeno_skins/icons/ravager/bone.dmi'

// Runner
/datum/xenomorph_skin/runner/base
	name = "Классический"
	icon = 'icons/Xeno/castes/runner.dmi'

/datum/xenomorph_skin/runner/rouny
	name = "Rouny"
	icon = 'modular_unga/features/xeno_skins/icons/runner/basic_rouny.dmi'
	admin_only = TRUE

/datum/xenomorph_skin/runner/gold
	name = "Gold"
	icon = 'modular_unga/features/xeno_skins/icons/runner/gold.dmi'

/datum/xenomorph_skin/runner/gold_rouny
	name = "Gold Rouny"
	icon = 'modular_unga/features/xeno_skins/icons/runner/gold_rouny.dmi'
	admin_only = TRUE

/datum/xenomorph_skin/runner/tacticool
	name = "Tacticool"
	icon = 'modular_unga/features/xeno_skins/icons/runner/tacticool.dmi'

// Scorpion
/datum/xenomorph_skin/scorpion/base
	name = "Классический"
	icon = 'icons/Xeno/castes/scorpion.dmi'

/datum/xenomorph_skin/scorpion/crab
	name = "Crab"
	icon = 'modular_unga/features/xeno_skins/icons/scorpion/crab.dmi'

// Shrike
/datum/xenomorph_skin/shrike/base
	name = "Классический"
	icon = 'icons/Xeno/castes/shrike.dmi'

/datum/xenomorph_skin/shrike/rouny
	name = "Rouny"
	icon = 'modular_unga/features/xeno_skins/icons/shrike/rouny.dmi'
	admin_only = TRUE

/datum/xenomorph_skin/shrike/joker
	name = "Joker"
	icon = 'modular_unga/features/xeno_skins/icons/shrike/joker.dmi'

/datum/xenomorph_skin/shrike/clown
	name = "Clown"
	icon = 'modular_unga/features/xeno_skins/icons/shrike/joker_rouny.dmi'
	admin_only = TRUE

// Warlock
/datum/xenomorph_skin/warlock/base
	name = "Классический"
	icon = 'icons/Xeno/castes/warlock.dmi'

/datum/xenomorph_skin/warlock/rouny
	name = "Rouny"
	icon = 'modular_unga/features/xeno_skins/icons/warlock/rouny.dmi'
	admin_only = TRUE

/datum/xenomorph_skin/warlock/arabian
	name = "Arabian"
	icon = 'modular_unga/features/xeno_skins/icons/warlock/arab.dmi'

// Warrior
/datum/xenomorph_skin/warrior/base
	name = "Классический"
	icon = 'icons/Xeno/castes/warrior.dmi'

/datum/xenomorph_skin/warrior/rouny
	name = "Rouny"
	icon = 'modular_unga/features/xeno_skins/icons/warrior/rouny.dmi'
	admin_only = TRUE
