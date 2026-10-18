GLOBAL_LIST_INIT(all_assembly_craft_groups, list(
	"Operations",
	"Weapons",
	"Smartguns",
	"Stationary",
	"Launchers",
	"Explosives",
	"Armor",
	"Clothing",
	"Medical",
	"Engineering",
	"Supplies",
	"Imports",
	"Vehicles",
	"Factory",
))

/datum/assembly_craft
	var/name
	var/notes
	var/list/input
	var/list/output
	var/craft_time = 1 SECONDS
	var/group

//metal = 4 points
//silver = 8 points //used to craft osmium
//glass = 2 points
//osmium = 6 points //only craftable
//plasteel = 8 points
//phoron = 6.6 points //craft using junk
//gun powder ~ 1 point
//cloth = 4 points
//platinum = 12 points
//copper = 4 points
//junk = 6 points so expensive.. for junk
//composite = 8 points
//jeweler steel = 6.6 points
