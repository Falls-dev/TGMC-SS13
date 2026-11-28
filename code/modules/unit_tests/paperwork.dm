/datum/unit_test/paperwork/Run()
	var/source = "Status: <ready> & waiting"
	var/encoded_source = html_encode(source)
	var/fax = generate_templated_fax("Brig", source, source, "[source]\n[source]", source, "Command")
	TEST_ASSERT(findtext(fax, "<b>[encoded_source]</b>"), "Fax subjects should be rendered as text")
	TEST_ASSERT(findtext(fax, "[encoded_source]<br />[encoded_source]"), "Fax bodies should escape text and keep line breaks")
	TEST_ASSERT(!findtext(fax, source), "Fax template fields should not insert raw markup")

	var/paper = parse_pencode("\[b\][encoded_source]\[/b\]")
	TEST_ASSERT(findtext(paper, "<b>[encoded_source]</b>"), "Pencode should format text without decoding it")
	TEST_ASSERT_EQUAL(record_text_html(source), encoded_source, "Record printers should display markup as text")
	TEST_ASSERT_EQUAL(record_text_html(encoded_source), encoded_source, "Stored encoded record fields should display once")
	TEST_ASSERT_EQUAL(record_text_html(30), "30", "Record printers should display numeric fields")
