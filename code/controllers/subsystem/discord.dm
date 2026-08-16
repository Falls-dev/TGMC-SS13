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

/// Чекер на то, настроен ли KAIN API
/datum/controller/subsystem/discord/proc/is_aperture_api_configured()
	return !!CONFIG_GET(string/KAIN_API_URL) && !!CONFIG_GET(string/KAIN_API_TOKEN)

/// Формирует URL адрес для GET-запроса к KAIN API
/datum/controller/subsystem/discord/proc/build_aperture_api_url(endpoint, lookup_ckey)
	var/base = CONFIG_GET(string/KAIN_API_URL)
	if(copytext(base, length(base)) == "/")
		base = copytext(base, 1, length(base))
	return "[base]/[endpoint]?token=[url_encode(CONFIG_GET(string/KAIN_API_TOKEN))]&q=ss13_nick&who=[url_encode(lookup_ckey)]"

/**
 * Выполняет GET-запрос к KAIN API
 * Возвращает http_response если пришёл успешный ответ
 * Или возвращает null если API не настроен либо запрос не удался
 */
/datum/controller/subsystem/discord/proc/aperture_api_get(endpoint, lookup_ckey)
	if(!is_aperture_api_configured() || !lookup_ckey)
		return null
	var/datum/http_request/req = new()
	req.prepare(RUSTG_HTTP_METHOD_GET, build_aperture_api_url(endpoint, lookup_ckey), "")
	req.begin_async()
	UNTIL(req.is_complete())
	return req.into_response()

/**
 * Выполняет поиск регистрации в Discord через по аргументу/search
 * Варианты ответа:
 * - Если ничего не найдено то 0
 * - Если найдено то список JSON
 * - Если ошибка то null
 */
/datum/controller/subsystem/discord/proc/lookup_registration(lookup_ckey)
	if(!lookup_ckey)
		return null
	lookup_ckey = ckey(lookup_ckey)

	var/datum/http_response/res = aperture_api_get("search", lookup_ckey)
	if(!res || res.errored)
		return null

	if(res.status_code && res.status_code != 200)
		return null

	var/body = trim(res.body)
	if(!body)
		return null

	if(body == "0")
		return 0

	var/list/data
	try
		data = json_decode(body)
	catch
		return null

	if(!islist(data))
		return null
	return data

/**
 * Возвращает уровень Boosty
 * Если "fail_null" равен `TRUE` то при ошибках возвращается "null", иначе возвращается "BOOSTY_TIER_0"
 * Желательно "fail_null" ставить в значение "FALSE" чтобы не срало ошибками
 */
/datum/controller/subsystem/discord/proc/get_boosty_tier(ckey, fail_null = FALSE)
// Для тестов выставляем автоматически третий тир
	#ifdef TESTING
	return BOOSTY_TIER_3
	#endif

	if(!ckey)
		return fail_null ? null : BOOSTY_TIER_0

	ckey = ckey(ckey) // Костыль

	// Уровни установленные в config/boosty.txt имеют приоритет выше
	if(ckey in boosty_overrides)
		return boosty_overrides[ckey]

	// Брать данные из кэша чтоб не дёргать каждый раз API
	if(ckey in boosty_cache)
		return boosty_cache[ckey]

	// Нет API - нет запроса
	if(!is_aperture_api_configured())
		return fail_null ? null : BOOSTY_TIER_0

	var/datum/http_response/res = aperture_api_get("tier", ckey)
	if(!res || res.errored)
		return fail_null ? null : BOOSTY_TIER_0

	if(res.status_code && res.status_code != 200)
		return fail_null ? null : BOOSTY_TIER_0

	var/body = trim(res.body)
	if(!body)
		return fail_null ? null : BOOSTY_TIER_0

	var/tier = text2num(body)
	if(isnull(tier))
		return fail_null ? null : BOOSTY_TIER_0

	// Допустимыми ответами API являются только значения от 0 до 3
	// Остальное считается ошибкой
	if(tier < BOOSTY_TIER_0 || tier > BOOSTY_TIER_3)
		return fail_null ? null : BOOSTY_TIER_0

	boosty_cache[ckey] = tier
	return tier
