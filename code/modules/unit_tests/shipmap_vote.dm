/datum/unit_test/shipmap_vote/Run()
	var/datum/map_config/talos = allocate(/datum/map_config)
	talos.map_name = "Talos"
	var/list/ship_maps = list("Talos" = talos)

	var/datum/game_mode/next_mode = allocate(/datum/game_mode/extended)
	var/list/choices = get_shipmap_vote_choices(ship_maps, next_mode, 100)
	TEST_ASSERT_EQUAL(length(choices), 1, "One eligible ship can be selected without opening a ballot.")
	TEST_ASSERT_EQUAL(choices[1], "Talos", "The only eligible ship is Talos.")

	next_mode.blacklist_ship_maps = list("Talos")
	TEST_ASSERT_EQUAL(length(get_shipmap_vote_choices(ship_maps, next_mode, 100)), 0, "An incompatible ship leaves no eligible choices.")

	var/datum/map_config/other_ship = allocate(/datum/map_config)
	other_ship.map_name = "Other Ship"
	other_ship.config_min_users = 10
	other_ship.config_max_users = 20
	var/list/other_ship_maps = list("Other Ship" = other_ship)
	TEST_ASSERT_EQUAL(length(get_shipmap_vote_choices(other_ship_maps, next_mode, 9)), 0, "The minimum player count is enforced.")
	TEST_ASSERT_EQUAL(length(get_shipmap_vote_choices(other_ship_maps, next_mode, 10)), 1, "The minimum player count is inclusive.")
	TEST_ASSERT_EQUAL(length(get_shipmap_vote_choices(other_ship_maps, next_mode, 21)), 0, "The maximum player count is enforced.")
	other_ship.voteweight = 0
	TEST_ASSERT_EQUAL(length(get_shipmap_vote_choices(other_ship_maps, next_mode, 15)), 0, "A ship with zero vote weight cannot be selected automatically.")
