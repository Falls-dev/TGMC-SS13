/*
NOTES:
There is a DB table to track ckeys and associated discord IDs.
This system REQUIRES TGS, and will auto-disable if TGS is not present.
The SS uses fire() instead of just pure shutdown, so people can be notified if it comes back after a crash, where the SS wasn't properly shutdown
It only writes to the disk every 5 minutes, and it won't write to disk if the file is the same as it was the last time it was written. This is to save on disk writes
The system is kept per-server (EG: Terry will not notify people who pressed notify on Sybil), but the accounts are between servers so you dont have to relink on each server.

##################
# HOW THIS WORKS #
##################

ROUNDSTART:
1] The file is loaded and the discord IDs are extracted
2] A ping is sent to the discord with the IDs of people who wished to be notified
3] The file is emptied

MIDROUND:
1] Someone usees the notify verb, it adds their discord ID to the list.
2] On fire, it will write that to the disk, as long as conditions above are correct

END ROUND:
1] The file is force-saved, incase it hasn't fired at end round

This is an absolute clusterfuck, but its my clusterfuck -aa07
*/

SUBSYSTEM_DEF(discord)
	name = "Discord"
	wait = 3000
	init_order = INIT_ORDER_DISCORD
	/// List that holds accounts to link, used in conjunction with TGS
	var/list/account_link_cache = list()
	/// list of people who tried to use Boosty styff, so we don't call the API every time
	var/list/boosty_cache = list()
	/// Manual Boosty tier overrides from config/boosty.txt (ckey = tier)
	var/list/boosty_overrides = list()
	/// Is TGS enabled (If not we won't fire because otherwise this is useless)
	var/enabled = FALSE

/datum/controller/subsystem/discord/Initialize(start_timeofday)
	load_boosty_overrides()
	// Check for if we are using TGS, otherwise return and disables firing
	if(world.TgsAvailable())
		enabled = TRUE // Allows other procs to use this (Account linking, etc)
		return SS_INIT_SUCCESS
	else
		can_fire = FALSE // We dont want excess firing
		return SS_INIT_NO_NEED

/datum/controller/subsystem/discord/fire()
	if(!enabled)
		return // Dont do shit if its disabled

// Returns ID from ckey
/datum/controller/subsystem/discord/proc/lookup_id(lookup_ckey)
	//We cast the discord ID to varchar to prevent BYOND mangling
	//it into it's scientific notation
	var/datum/db_query/query_get_discord_id = SSdbcore.NewQuery(
		"SELECT CAST(discord_id AS CHAR(25)) FROM [format_table_name("player")] WHERE ckey = :ckey",
		list("ckey" = lookup_ckey)
	)
	if(!query_get_discord_id.Execute())
		qdel(query_get_discord_id)
		return
	if(query_get_discord_id.NextRow())
		. = query_get_discord_id.item[1]
	qdel(query_get_discord_id)

// Returns ckey from ID
/datum/controller/subsystem/discord/proc/lookup_ckey(lookup_id)
	var/datum/db_query/query_get_discord_ckey = SSdbcore.NewQuery(
		"SELECT ckey FROM [format_table_name("player")] WHERE discord_id = :discord_id",
		list("discord_id" = lookup_id)
	)
	if(!query_get_discord_ckey.Execute())
		qdel(query_get_discord_ckey)
		return
	if(query_get_discord_ckey.NextRow())
		. = query_get_discord_ckey.item[1]
	qdel(query_get_discord_ckey)

// Finalises link
/datum/controller/subsystem/discord/proc/link_account(ckey)
	var/datum/db_query/link_account = SSdbcore.NewQuery(
		"UPDATE [format_table_name("player")] SET discord_id = :discord_id WHERE ckey = :ckey",
		list("discord_id" = account_link_cache[ckey], "ckey" = ckey)
	)
	link_account.Execute()
	qdel(link_account)
	account_link_cache -= ckey

// Unlink account (Admin verb used)
/datum/controller/subsystem/discord/proc/unlink_account(ckey)
	var/datum/db_query/unlink_account = SSdbcore.NewQuery(
		"UPDATE [format_table_name("player")] SET discord_id = NULL WHERE ckey = :ckey",
		list("ckey" = ckey)
	)
	unlink_account.Execute()
	qdel(unlink_account)

// Clean up a discord account mention
/datum/controller/subsystem/discord/proc/id_clean(input)
	var/regex/num_only = regex("\[^0-9\]", "g")
	return num_only.Replace(input, "")

/// Loads manual Boosty tier overrides from config/boosty.txt
/datum/controller/subsystem/discord/proc/load_boosty_overrides(filename = "config/boosty.txt")
	boosty_overrides = list()
	if(!fexists(filename))
		return
	for(var/line in file2list(filename))
		if(!line)
			continue
		line = trim(line)
		if(!length(line) || copytext(line, 1, 2) == "#")
			continue
		var/list/parts = splittext(line, "=")
		if(length(parts) < 2)
			continue
		var/override_ckey = ckey(parts[1])
		var/tier = text2num(trim(parts[2]))
		if(!override_ckey || isnull(tier))
			continue
		tier = clamp(tier, BOOSTY_TIER_0, BOOSTY_TIER_3)
		boosty_overrides[override_ckey] = tier

/datum/controller/subsystem/discord/proc/get_boosty_tier(ckey, silent = TRUE)
	#ifdef TESTING
	if(!silent)
		to_chat(usr, span_warning("Test mod gave you tier 3 boost"))
	return BOOSTY_TIER_3
	#endif

	if(!ckey)
		return BOOSTY_TIER_0

	ckey = ckey(ckey)

	// Manual overrides from config/boosty.txt take priority over the API
	if(ckey in boosty_overrides)
		return boosty_overrides[ckey]

	// Use cache if possible (including tier 0)
	if(ckey in boosty_cache)
		return boosty_cache[ckey]

	var/api_url = CONFIG_GET(string/boosty_api_url)
	var/api_token = CONFIG_GET(string/boosty_api_token)
	if(!api_url || !api_token)
		if(!silent)
			to_chat(usr, span_warning("Boosty API is not configured."))
		return BOOSTY_TIER_0

	var/url = "[api_url]?token=[url_encode(api_token)]&q=ss13_nick&who=[url_encode(ckey)]"
	var/datum/http_request/req = new()
	req.prepare(RUSTG_HTTP_METHOD_GET, url, "")
	req.begin_async()
	UNTIL(req.is_complete())
	var/datum/http_response/res = req.into_response()

	if(res.errored || !res.body)
		if(!silent)
			var/error_text = res.error
			if(!error_text)
				error_text = "empty response"
			to_chat(usr, span_warning("Failed to check Boosty tier: [error_text]"))
		return BOOSTY_TIER_0

	var/tier = text2num(trim(res.body))
	if(isnull(tier))
		if(!silent)
			to_chat(usr, span_warning("Invalid Boosty API response: [res.body]"))
		return BOOSTY_TIER_0

	tier = clamp(tier, BOOSTY_TIER_0, BOOSTY_TIER_3)
	boosty_cache[ckey] = tier
	return tier
