/// Accept an absolute HTTP(S) URL with a host and without credentials or control characters.
/proc/is_internet_media_url(url)
	if(!istext(url))
		return FALSE
	var/static/regex/media_url = regex(@{"^https?://(?:[a-z0-9.-]+|\[[0-9a-f:.]+\])(?::[0-9]{1,5})?(?:[/?#][^\x00-\x20\x7f\\]*)?$"}, "i")
	return media_url.Find(url) && media_url.match == url

/datum/internet_media/cobalt
	var/error

/// Resolve a supported source URL to a stream URL without running a local process.
/datum/internet_media/cobalt/proc/get_media_url(url)
	if(IsAdminAdvancedProcCall() || !check_rights(R_SOUND, FALSE))
		return
	var/cobalt = CONFIG_GET(string/cobalt_base_api)
	if(!is_internet_media_url(url) || !is_internet_media_url(cobalt))
		error = "Internet audio requires a valid media URL and configured Cobalt endpoint."
		return

	var/list/headers = list()
	headers["Accept"] = "application/json"
	headers["Content-Type"] = "application/json"

	var/auth_key = CONFIG_GET(string/cobalt_api_key)
	if(auth_key)
		if(!findtext(cobalt, "https://", 1, 9))
			error = "Cobalt API credentials require an HTTPS endpoint."
			return
		headers["Authorization"] = "Api-Key [auth_key]"

	var/datum/http_request/request = new
	request.prepare(RUSTG_HTTP_METHOD_POST, cobalt, json_encode(list(
		"url" = url,
		"downloadMode" = "audio"
	)), headers)

	request.begin_async()

	UNTIL(request.is_complete())

	var/datum/http_response/response_raw = request.into_response()

	if(response_raw.errored || response_raw.status_code != 200)
		error = "The Cobalt request failed."
		return

	var/list/response
	try
		response = json_decode(response_raw.body)
	catch
		error = "Cobalt returned invalid JSON."
		return

	if(!islist(response) || !(response["status"] in list("redirect", "tunnel")) || !is_internet_media_url(response["url"]))
		error = "Cobalt did not return a valid HTTP(S) audio URL."
		return

	return response["url"]
