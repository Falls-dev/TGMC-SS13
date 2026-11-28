/datum/unit_test/admin_ticket_security/Run()
	TEST_ASSERT(!admin_ticket_has_access(TICKET_ADMIN, NONE), "Players cannot open admin tickets through the staff panel")
	TEST_ASSERT(!admin_ticket_has_access(TICKET_ADMIN, R_MENTOR), "Mentors cannot open admin tickets")
	TEST_ASSERT(!admin_ticket_has_access(TICKET_ADMIN, R_ADMIN), "An admin holder still needs the ticket permission")
	TEST_ASSERT(admin_ticket_has_access(TICKET_ADMIN, R_ADMINTICKET), "Ticket staff can open admin tickets")
	TEST_ASSERT(admin_ticket_has_access(TICKET_MENTOR, R_MENTOR), "Mentors can open mentor tickets")
	TEST_ASSERT(admin_ticket_has_access(TICKET_MENTOR, R_ADMINTICKET), "Ticket staff can open mentor tickets")
	TEST_ASSERT(!admin_ticket_has_access(TICKET_MENTOR, NONE), "Players cannot open mentor tickets through the staff panel")
	TEST_ASSERT(!admin_ticket_has_access(null, R_EVERYTHING), "Unknown ticket tiers are denied")

	var/message = "Экипаж: Алекс, 'O'Neil' & R&D (2 < 3)."
	TEST_ASSERT_EQUAL(normalize_admin_message("  [message]  "), message, "Ticket and PM input keeps punctuation as plain text")
	TEST_ASSERT_EQUAL(normalize_admin_message(list(message)), "", "Non-text input is discarded")
	TEST_ASSERT_EQUAL(length_char(normalize_admin_message(repeat_string(MAX_MESSAGE_LEN + 1, "Ж"))), MAX_MESSAGE_LEN, "Message limit counts Unicode characters")
	TEST_ASSERT_EQUAL(html_decode(sanitize(normalize_admin_message(message))), message, "HTML output round-trips the message exactly once")

/datum/unit_test/character_name_rendering/Run()
	TEST_ASSERT_EQUAL(reject_bad_name("anne o'neil", TRUE), "Anne O'Neil", "Punctuation in a valid character name is retained")
	TEST_ASSERT_NULL(reject_bad_name(list("Anne O'Neil"), TRUE), "Malformed name values are rejected")
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	speaker.name = "Anne O'Neil & Co (2 < 3)"
	speaker.real_name = speaker.name
	var/rendered = speaker.compose_message(speaker, null, "Hello", null, list())
	TEST_ASSERT(findtext(rendered, html_encode(speaker.name)), "Speech encodes the display name at the HTML boundary")
	TEST_ASSERT(!findtext(rendered, speaker.name), "Speech does not insert the raw display name into HTML")
	TEST_ASSERT(findtext(key_name_admin(speaker), html_encode(speaker.name)), "Admin identity markup encodes the name of a mob without a ckey")
	TEST_ASSERT(findtext(key_name(speaker), speaker.name), "Plain-text logs keep the original name")
