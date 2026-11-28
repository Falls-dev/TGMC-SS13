/datum/unit_test/ooc_nickname/Run()
	var/nickname = html_encode("Anne O'Neil & Co")
	var/admin_nickname = "<span class='ooc-nickname adminooc'>[nickname]</span>"
	var/custom_nickname = "<span class='ooc-nickname' style='color:#12AbF0'>[nickname]</span>"

	TEST_ASSERT_EQUAL(format_ooc_nickname(nickname, "Admin", FALSE, TRUE, "#12AbF0"), custom_nickname, "An authorized hex color applies to the escaped nickname")
	TEST_ASSERT_EQUAL(format_ooc_nickname(nickname, "Admin", FALSE, FALSE, "#12AbF0"), admin_nickname, "The rank color is used when custom colors are disabled")
	TEST_ASSERT_EQUAL(format_ooc_nickname(nickname, "Admin", FALSE, TRUE, "#12gbf0"), admin_nickname, "An invalid preference falls back to the rank color")
	TEST_ASSERT_EQUAL(format_ooc_nickname(nickname, "Admin", TRUE, TRUE, "#12AbF0"), nickname, "Stealth staff retain the ordinary channel color")
	TEST_ASSERT_EQUAL(format_ooc_nickname(nickname, null, FALSE, TRUE, "#12AbF0"), nickname, "Players without a staff rank retain the ordinary channel color")
	TEST_ASSERT_EQUAL(format_ooc_nickname(nickname, "Other rank", FALSE, TRUE, null), "<span class='ooc-nickname otherooc'>[nickname]</span>", "An unlisted rank uses the fallback class")
