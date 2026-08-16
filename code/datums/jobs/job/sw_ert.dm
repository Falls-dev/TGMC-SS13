// =============================================================================
// Star Wars ERT jobs
// Factions: Rebels = CLF | Clones = TerraGov | Empire = VSD | Guards = Deathsquad
// Skills/loadout inspiration: SOM ERT + CLF (rebels) + SRF drone op (radiotech)
// =============================================================================

/datum/job/sw/ert
	job_category = JOB_CAT_MARINE
	access = ALL_ANTAGONIST_ACCESS
	minimal_access = ALL_ANTAGONIST_ACCESS
	skills_type = /datum/skills/crafty

// -----------------------------------------------------------------------------
// 1) REBEL ALLIANCE — CLF analogue (lasguns, militia gear)
// -----------------------------------------------------------------------------

/datum/job/sw/ert/rebel
	title = "Rebel Trooper"
	faction = FACTION_CLF
	outfit = /datum/outfit/job/sw/ert/rebel/trooper_mlaser
	multiple_outfits = TRUE
	outfits = list(
		/datum/outfit/job/sw/ert/rebel/trooper_mlaser,
		/datum/outfit/job/sw/ert/rebel/trooper_carbine,
		/datum/outfit/job/sw/ert/rebel/trooper_sniper,
	)

/datum/job/sw/ert/rebel/medic
	title = "Rebel Medic"
	skills_type = /datum/skills/combat_medic/crafty
	outfit = /datum/outfit/job/sw/ert/rebel/medic
	multiple_outfits = FALSE

/datum/job/sw/ert/rebel/officer
	title = "Rebel Officer"
	skills_type = /datum/skills/sl/clf
	outfit = /datum/outfit/job/sw/ert/rebel/officer
	multiple_outfits = FALSE

// -----------------------------------------------------------------------------
// 2) CLONE BASIC — phase I fireteam (TerraGov)
// -----------------------------------------------------------------------------

/datum/job/sw/ert/clone
	faction = FACTION_TERRAGOV
	skills_type = /datum/skills/crafty

/datum/job/sw/ert/clone/trooper
	title = "Clone Trooper"
	// Loot random: MPI-style pack vs SOM Marine-style pack (skills stay crafty)
	outfit = /datum/outfit/job/sw/ert/clone/trooper/marine
	multiple_outfits = TRUE
	outfits = list(
		/datum/outfit/job/sw/ert/clone/trooper/marine,
		/datum/outfit/job/sw/ert/clone/trooper/infantryman,
	)

/datum/job/sw/ert/clone/engineer
	title = "Clone Trooper Engineer"
	skills_type = /datum/skills/combat_engineer
	outfit = /datum/outfit/job/sw/ert/clone/engineer
	multiple_outfits = FALSE

/datum/job/sw/ert/clone/mp
	title = "Clone Military Police"
	skills_type = /datum/skills/som_veteran
	outfit = /datum/outfit/job/sw/ert/clone/mp
	multiple_outfits = FALSE

/datum/job/sw/ert/clone/pilot
	title = "Clone Pilot Medic"
	skills_type = /datum/skills/combat_medic/crafty
	outfit = /datum/outfit/job/sw/ert/clone/pilot
	multiple_outfits = FALSE

/datum/job/sw/ert/clone/lieutenant
	title = "Clone Lieutenant"
	job_category = JOB_CAT_COMMAND
	skills_type = /datum/skills/som_veteran/sl
	outfit = /datum/outfit/job/sw/ert/clone/lieutenant
	multiple_outfits = FALSE

// -----------------------------------------------------------------------------
// 3) CLONE BASIC MK.II — phase II fireteam
// -----------------------------------------------------------------------------

/datum/job/sw/ert/clone_mk2/trooper
	title = "Clone Reinforced Trooper"
	faction = FACTION_TERRAGOV
	outfit = /datum/outfit/job/sw/ert/clone_mk2/trooper/marine
	multiple_outfits = TRUE
	outfits = list(
		/datum/outfit/job/sw/ert/clone_mk2/trooper/marine,
		/datum/outfit/job/sw/ert/clone_mk2/trooper/infantryman,
	)

/datum/job/sw/ert/clone_mk2/artillery
	title = "Clone Artillery Engineer"
	faction = FACTION_TERRAGOV
	skills_type = /datum/skills/combat_engineer
	outfit = /datum/outfit/job/sw/ert/clone_mk2/artillery
	multiple_outfits = FALSE

/datum/job/sw/ert/clone_mk2/mp
	title = "Clone Military Police Phase II"
	faction = FACTION_TERRAGOV
	skills_type = /datum/skills/som_veteran
	outfit = /datum/outfit/job/sw/ert/clone_mk2/mp
	multiple_outfits = FALSE

/datum/job/sw/ert/clone_mk2/sgt
	title = "Clone Sergeant Medic"
	faction = FACTION_TERRAGOV
	skills_type = /datum/skills/combat_medic/crafty
	outfit = /datum/outfit/job/sw/ert/clone_mk2/sgt
	multiple_outfits = FALSE

/datum/job/sw/ert/clone_mk2/captain
	title = "Clone Captain"
	faction = FACTION_TERRAGOV
	job_category = JOB_CAT_COMMAND
	skills_type = /datum/skills/som_veteran/sl
	outfit = /datum/outfit/job/sw/ert/clone_mk2/captain
	multiple_outfits = FALSE

// -----------------------------------------------------------------------------
// 4) 501st LEGION
// -----------------------------------------------------------------------------

/datum/job/sw/ert/legion501/trooper
	title = "501st Legion Trooper"
	faction = FACTION_TERRAGOV
	skills_type = /datum/skills/crafty
	outfit = /datum/outfit/job/sw/ert/legion501/trooper/infantryman
	multiple_outfits = TRUE
	outfits = list(
		/datum/outfit/job/sw/ert/legion501/trooper/infantryman,
		/datum/outfit/job/sw/ert/legion501/trooper/veteran,
	)

/datum/job/sw/ert/legion501/radiotech
	title = "501st Radiotech Engineer"
	faction = FACTION_TERRAGOV
	skills_type = /datum/skills/combat_engineer
	outfit = /datum/outfit/job/sw/ert/legion501/radiotech
	multiple_outfits = FALSE

/datum/job/sw/ert/legion501/commander
	title = "501st Commander"
	faction = FACTION_TERRAGOV
	job_category = JOB_CAT_COMMAND
	skills_type = /datum/skills/som_veteran/sl
	outfit = /datum/outfit/job/sw/ert/legion501/commander
	multiple_outfits = FALSE

// -----------------------------------------------------------------------------
// 5) 212th BATTALION
// -----------------------------------------------------------------------------

/datum/job/sw/ert/battalion212/trooper
	title = "212th Battalion Trooper"
	faction = FACTION_TERRAGOV
	skills_type = /datum/skills/crafty
	outfit = /datum/outfit/job/sw/ert/battalion212/trooper/infantryman
	multiple_outfits = TRUE
	outfits = list(
		/datum/outfit/job/sw/ert/battalion212/trooper/infantryman,
		/datum/outfit/job/sw/ert/battalion212/trooper/veteran,
	)

/datum/job/sw/ert/battalion212/commando
	title = "212th Commando Leader"
	faction = FACTION_TERRAGOV
	job_category = JOB_CAT_COMMAND
	skills_type = /datum/skills/som_veteran/sl
	outfit = /datum/outfit/job/sw/ert/battalion212/commando
	multiple_outfits = FALSE

// -----------------------------------------------------------------------------
// 6) 442nd BATTALION
// -----------------------------------------------------------------------------

/datum/job/sw/ert/battalion442/trooper
	title = "442nd Battalion Trooper"
	faction = FACTION_TERRAGOV
	skills_type = /datum/skills/crafty
	outfit = /datum/outfit/job/sw/ert/battalion442/trooper/infantryman
	multiple_outfits = TRUE
	outfits = list(
		/datum/outfit/job/sw/ert/battalion442/trooper/infantryman,
		/datum/outfit/job/sw/ert/battalion442/trooper/veteran,
	)

/datum/job/sw/ert/battalion442/commando
	title = "442nd Commando Leader"
	faction = FACTION_TERRAGOV
	job_category = JOB_CAT_COMMAND
	skills_type = /datum/skills/som_veteran/sl
	outfit = /datum/outfit/job/sw/ert/battalion442/commando
	multiple_outfits = FALSE

// -----------------------------------------------------------------------------
// 7) SENATE GUARD — VIP extraction
// -----------------------------------------------------------------------------

/datum/job/sw/ert/senateguard
	title = "Senate Guardsman"
	faction = FACTION_DEATHSQUAD
	skills_type = /datum/skills/som_veteran
	outfit = /datum/outfit/job/sw/ert/senateguard
	multiple_outfits = FALSE

// -----------------------------------------------------------------------------
// 8) STORMTROOPERS — VSD faction, plasma weapons
// -----------------------------------------------------------------------------

/datum/job/sw/ert/stormtrooper
	faction = FACTION_VSD
	skills_type = /datum/skills/crafty

/datum/job/sw/ert/stormtrooper/standard
	title = "Imperial Stormtrooper"
	outfit = /datum/outfit/job/sw/ert/stormtrooper/standard/marine
	multiple_outfits = TRUE
	outfits = list(
		/datum/outfit/job/sw/ert/stormtrooper/standard/marine,
		/datum/outfit/job/sw/ert/stormtrooper/standard/infantryman,
	)

/datum/job/sw/ert/stormtrooper/airborne
	title = "Imperial Airborne Trooper"
	skills_type = /datum/skills/som_veteran
	outfit = /datum/outfit/job/sw/ert/stormtrooper/airborne/breacher
	multiple_outfits = TRUE
	outfits = list(
		/datum/outfit/job/sw/ert/stormtrooper/airborne/breacher,
		/datum/outfit/job/sw/ert/stormtrooper/airborne/rpg,
		/datum/outfit/job/sw/ert/stormtrooper/airborne/flamer,
		/datum/outfit/job/sw/ert/stormtrooper/airborne/culverin,
		/datum/outfit/job/sw/ert/stormtrooper/airborne/medic,
	)

/datum/job/sw/ert/stormtrooper/surgeon
	title = "Imperial Storm Surgeon"
	skills_type = /datum/skills/combat_medic/crafty
	outfit = /datum/outfit/job/sw/ert/stormtrooper/surgeon
	multiple_outfits = FALSE

/datum/job/sw/ert/stormtrooper/radio
	title = "Imperial Storm Radioman"
	skills_type = /datum/skills/combat_engineer
	outfit = /datum/outfit/job/sw/ert/stormtrooper/radio
	multiple_outfits = FALSE

/datum/job/sw/ert/stormtrooper/officer
	title = "Imperial Stormtrooper Officer"
	job_category = JOB_CAT_COMMAND
	skills_type = /datum/skills/som_veteran/sl
	outfit = /datum/outfit/job/sw/ert/stormtrooper/officer/jacket
	multiple_outfits = TRUE
	outfits = list(
		/datum/outfit/job/sw/ert/stormtrooper/officer/jacket,
		/datum/outfit/job/sw/ert/stormtrooper/officer/armored,
	)

// -----------------------------------------------------------------------------
// 9) RED GUARD — VIP extraction
// -----------------------------------------------------------------------------

/datum/job/sw/ert/redguard
	title = "Imperial Royal Guardsman"
	faction = FACTION_DEATHSQUAD
	skills_type = /datum/skills/som_veteran
	outfit = /datum/outfit/job/sw/ert/redguard
	multiple_outfits = FALSE
