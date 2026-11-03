// Additional Campaign map compatibility.

// Campaign map ammunition uses the local CAS payload implementations.
/obj/structure/ship_ammo/cas/bomblet
	parent_type = /obj/structure/ship_ammo/cas/minirocket
/obj/structure/ship_ammo/cas/bomblet/medium
	explosion_power = 200
/obj/structure/ship_ammo/cas/bomb
	parent_type = /obj/structure/ship_ammo/cas/rocket/widowmaker
/obj/structure/ship_ammo/cas/bomb/fourhundred
	explosion_power = 450
/obj/structure/ship_ammo/cas/bomb/moab
	explosion_power = 650
	explosion_falloff = 65
/obj/structure/ship_ammo/cas/rocket/monarch
	parent_type = /obj/structure/ship_ammo/cas/rocket/keeper
/obj/structure/ship_ammo/cas/rocket/swansong
	parent_type = /obj/structure/ship_ammo/cas/rocket/widowmaker
