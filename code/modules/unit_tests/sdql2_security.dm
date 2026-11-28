/datum/unit_test/sdql2_security/Run()
	var/datum/SDQL2_query/query = allocate(/datum/SDQL2_query, list("type" = "select"))
	var/mob/previous_user = usr
	usr = null
	var/query_run = query.Run()
	query.admin_del()
	usr = previous_user

	TEST_ASSERT(!query_run, "Running a query requires an authenticated debug administrator.")
	TEST_ASSERT(!QDELETED(query), "An unauthenticated user cannot delete a query.")

	var/plain_text = "Orbit < Sector & Dock > Gate"
	var/list/rendered = list()
	query.SDQL_print(plain_text, rendered)
	TEST_ASSERT_EQUAL(rendered.Join(), "[html_encode(plain_text)]<br>", "Query results render plain text inside server-owned HTML.")

	var/list/entries = list("Destination" = plain_text)
	rendered.Cut()
	query.SDQL_print(entries, rendered)
	TEST_ASSERT(findtext(rendered.Join(), html_encode(plain_text)), "Nested result values are HTML-encoded.")

/datum/admins/rights_test_fixture/New()
	// This holder has no client or entry in the admin directory.
	return

/datum/unit_test/admin_rights_security/Run()
	var/datum/admins/holder = allocate(/datum/admins/rights_test_fixture)
	TEST_ASSERT(!holder.check_for_rights(R_DEBUG), "A missing rank cannot grant debug rights.")
	holder.rank = allocate(/datum/admin_rank, "Test rank")
	holder.rank.rights = NONE
	TEST_ASSERT(!holder.check_for_rights(R_ADMIN), "A zero-rights rank cannot grant admin rights.")
	TEST_ASSERT(holder.check_for_rights(R_NONE), "An explicit holder-only check continues to accept zero-rights ranks.")
	holder.rank.rights = R_MENTOR
	TEST_ASSERT(!holder.check_for_rights(R_DEBUG), "An unrelated flag cannot grant debug rights.")
	TEST_ASSERT(holder.check_for_rights(R_ADMIN | R_MENTOR), "One matching flag satisfies an any-of rights mask.")
