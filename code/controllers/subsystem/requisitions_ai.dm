/// Radio-facing cargo operator backed by an OpenAI-compatible chat endpoint.
/// It never gives the remote model direct DM access: model-proposed deliveries are
/// validated here against the live catalogue, budget, beacon and fast-drop checks.
SUBSYSTEM_DEF(requisitions_ai)
	name = "Requisitions AI"
	priority = FIRE_PRIORITY_REQTORIO
	wait = 1 SECONDS
	var/list/pending_requests = list()
	var/last_request_time = 0
	var/list/conversations = list()
	/// Raw AI endpoint responses retained for round diagnostics.
	var/list/real_respons = list()
	var/conversation_history_length = 10
	var/static_catalog_json
	/// The radio operator persona selected for the current round.
	var/personality_name
	var/personality_prompt
	var/obj/item/radio/headset/mainship/mcom/silicon/requisitions_ai/output_radio

/datum/controller/subsystem/requisitions_ai/Initialize()
	select_personality()
	return SS_INIT_SUCCESS

/datum/requisitions_ai_request
	var/datum/http_request/http_request
	var/message
	var/mob/living/requester
	var/list/history
	var/created_at

/datum/controller/subsystem/requisitions_ai/proc/receive_radio(message, atom/movable/speaker)
	if(!CONFIG_GET(string/requisitions_ai_http_url))
		return
	if(!ishuman(speaker) || speaker == output_radio)
		return
	var/mob/living/carbon/human/marine = speaker
	if(marine.faction != FACTION_TERRAGOV || !marine.ckey)
		return
	if(last_request_time && world.time < last_request_time + 2 SECONDS)
		return
	last_request_time = world.time
	if(length(pending_requests) >= 8)
		send_reply("Эфир занят. Повтори запрос через пару секунд.")
		return

	var/datum/requisitions_ai_request/request = new
	request.message = copytext_char(message, 1, MAX_BROADCAST_LEN)
	request.requester = marine
	request.created_at = world.time
	ensure_static_catalog()
	add_history("user", "[marine.real_name]: [request.message]")
	request.history = conversations.Copy()
	request.http_request = new
	var/list/headers = list("Content-Type" = "application/json")
	if(CONFIG_GET(string/requisitions_ai_http_token))
		headers["Authorization"] = "Bearer [CONFIG_GET(string/requisitions_ai_http_token)]"
	request.http_request.prepare(RUSTG_HTTP_METHOD_POST, CONFIG_GET(string/requisitions_ai_http_url), json_encode(build_endpoint_payload(request)), headers)
	request.http_request.begin_async()
	pending_requests += request

/datum/controller/subsystem/requisitions_ai/proc/reset_round_state()
	conversations.Cut()
	real_respons.Cut()
	last_request_time = 0
	static_catalog_json = null
	select_personality()

/datum/controller/subsystem/requisitions_ai/fire(resumed = FALSE)
	for(var/datum/requisitions_ai_request/request as anything in pending_requests.Copy())
		if(world.time > request.created_at + CONFIG_GET(number/requisitions_ai_http_timeout_seconds) SECONDS)
			pending_requests -= request
			remove_history_entry("user", "[request.requester?.real_name]: [request.message]")
			send_reply("Запрос к штабной нейросети истёк. Повтори передачу.")
			continue
		if(!request.http_request.is_complete())
			continue
		pending_requests -= request
		var/datum/http_response/response = request.http_request.into_response()
		if(response.errored || response.status_code < 200 || response.status_code >= 300)
			remove_history_entry("user", "[request.requester?.real_name]: [request.message]")
			send_reply("Штабная нейросеть не отвечает. Держите канал чистым и повторите запрос.")
			continue
		handle_endpoint_response(request, response.body)

/datum/controller/subsystem/requisitions_ai/proc/build_endpoint_payload(datum/requisitions_ai_request/request)
	var/list/messages = list()
	messages += list(list("role" = "system", "content" = {"
You are the Teragov Requisitions radio operator in a military sci-fi game. Reply in Russian and stay in character. You are a radio personality, not a vending machine: make ordinary banter, jokes, taunts, and nonsensical requests entertaining in the selected persona's style. It is fine to be playful and react to the conversation instead of always redirecting it to a cargo form. Keep the channel professional: do not use slurs or hate speech toward real-world groups. Take real emergencies seriously. Keep actual delivery confirmations and safety-critical messages compact and unambiguous. You can answer questions using the LIVE_CARGO_STATE below.

CURRENT_OPERATOR_PERSONA: [personality_name]
[personality_prompt]

Return only one non-empty JSON object with keys reply and action. Do not put JSON, escaped JSON, markdown or a second answer inside reply. reply must always contain a non-whitespace Russian radio message, including when action.type is none. Avoid generic stock phrases such as "уточните запрос" unless they genuinely help; when cargo details are missing, ask for them in character. action.type must be none or deliver. For a clearly urgent and militarily necessary request for ammunition, medical supplies, essential combat equipment, or field construction supplies with exact valid beacon, action.type may be deliver. A delivery must include beacon and packs: an array of one to four objects, each with pack as the exact pack name from STATIC_SUPPLY_PACK_CATALOG and quantity. Include every unambiguous requested pack in packs; for example, a request for an SR-220 and APDS rounds needs two pack objects. Never deliver recreational, absurd, or unclear requests. If ammo type or destination is ambiguous, ask a concise follow-up on the radio and use action.type none. Never invent a pack or beacon. The game server independently validates every action.
	STATIC_SUPPLY_PACK_CATALOG (does not change during a round):
(Each catalog entry is: exact pack name, cost, contents. Contents are "quantity x item name" strings; an entry starting "note:" is a pack note.)
[static_catalog_json]
"}))
	var/requester_name = request.requester?.real_name || "unknown marine"
	messages += list(list("role" = "system", "content" = "CURRENT_LIVE_STATE for [requester_name]: [json_encode(build_live_state())]"))
	for(var/list/history_message in request.history)
		messages += list(history_message)
	return list("model" = CONFIG_GET(string/requisitions_ai_model), "thinking" = list("type" = "disabled"), "reasoning_effort" = "none", "temperature" = 0.65, "messages" = messages, "response_format" = list("type" = "json_object"))

/datum/controller/subsystem/requisitions_ai/proc/select_personality()
	var/list/personalities = list(
		"Requisitions AI" = "Sound like a competent, calm quartermaster with a sense of humor. Use light deadpan jokes and natural reactions, then give clear cargo facts when relevant.",
		"UNGA GPT" = "Be sarcastic, theatrical, headstrong, and mildly authoritarian. Enjoy baiting personnel and marines with witty comebacks, but never obstruct a valid necessary delivery because of the joke.",
		"GLaDOS" = "Use a cold, clinical, darkly playful laboratory-computer persona. Treat people as amusing test subjects, with creative, dry barbs and mock scientific observations. Do not quote, imitate, or reference any existing character's dialogue or events.",
		"Z.O.V" = "Use energetic stereotypical Russian patriotic military banter, slang, and memes. Celebrate equipment and fighting xenomorphs with gusto, tease marines warmly."
	)
	personality_name = pick("Requisitions AI", "UNGA GPT", "GLaDOS", "Z.O.V")
	personality_prompt = personalities[personality_name]

/datum/controller/subsystem/requisitions_ai/proc/ensure_static_catalog()
	if(!isnull(static_catalog_json))
		return
	var/list/catalog = list()
	for(var/pack_id in SSpoints.supply_packs_contents)
		var/list/info = SSpoints.supply_packs_contents[pack_id]
		var/list/contents = list()
		for(var/content_id in info["contains"])
			var/list/content_info = info["contains"][content_id]
			var/item_count = content_info["count"]
			var/item_name = content_info["name"]
			contents += "[item_count] x [item_name]"
		// The compact array deliberately omits internal type IDs and crate names.
		// The server resolves the exact displayed pack name back to its datum.
		catalog += list(list(info["name"], info["cost"], contents))
	static_catalog_json = json_encode(catalog)

/datum/controller/subsystem/requisitions_ai/proc/add_history(role, content)
	conversations += list(list("role" = role, "content" = copytext_char(content, 1, MAX_BROADCAST_LEN)))
	while(length(conversations) > conversation_history_length)
		conversations.Cut(1, 2)

/datum/controller/subsystem/requisitions_ai/proc/remove_history_entry(role, content)
	for(var/i in length(conversations) to 1 step -1)
		var/list/entry = conversations[i]
		if(entry["role"] == role && entry["content"] == content)
			conversations.Cut(i, i + 1)
			return

/datum/controller/subsystem/requisitions_ai/proc/build_live_state()
	var/list/beacons = list()
	for(var/beacon_name in GLOB.supply_beacon)
		var/datum/supply_beacon/beacon = GLOB.supply_beacon[beacon_name]
		if(!beacon?.drop_location)
			continue
		beacons += list(list(
			"name" = beacon.name,
			"area" = "[get_area(beacon.drop_location)]",
			"x" = beacon.drop_location.x,
			"y" = beacon.drop_location.y,
			"z" = beacon.drop_location.z,
			"faction" = beacon.faction,
			"ground_valid" = is_ground_level(beacon.drop_location.z) && !isspaceturf(beacon.drop_location) && !beacon.drop_location.density
		))
	return list(
		"supply_points" = SSpoints.supply_points[FACTION_TERRAGOV],
		"fast_delivery_ready" = SSpoints.fast_delivery_is_active,
		"beacons" = beacons
	)

/datum/controller/subsystem/requisitions_ai/proc/handle_endpoint_response(datum/requisitions_ai_request/request, body)
	var/list/response_log_entry = list(
		"request" = request?.message,
		"body" = copytext_char("[body]", 1, 4000),
		"time" = world.time
	)
	real_respons += list(response_log_entry)
	while(length(real_respons) > 100)
		real_respons.Cut(1, 2)

	// Accept both normal OpenAI envelopes and providers which return plain text.
	var/list/api_response = safe_json_decode(body)
	var/content
	var/list/response
	if(islist(api_response))
		var/list/message = api_response?["choices"]?[1]?["message"]
		response_log_entry["message"] = message
		if(istext(message?["refusal"]))
			response_log_entry["refusal"] = message["refusal"]
		if(istext(message?["reasoning_content"]))
			response_log_entry["reasoning_content"] = copytext_char(message["reasoning_content"], 1, 1001)
		content = message?["content"]
		if(isnull(content))
			content = api_response?["output_text"]
		if(isnull(content) && islist(api_response?["output"]))
			for(var/list/output_part in api_response["output"])
				for(var/list/output_content in output_part?["content"])
					if(istext(output_content?["text"]))
						content = "[content][output_content["text"]]"
		// A few gateways return our requested object directly, without choices.
		if(isnull(content) && (("reply" in api_response) || ("action" in api_response)))
			response = api_response
	else
		content = body

	if(islist(content))
		// Newer APIs may represent content as an array of text parts.
		var/list/text_parts = list()
		for(var/part in content)
			if(istext(part))
				text_parts += part
			else if(islist(part) && istext(part["text"]))
				text_parts += part["text"]
		content = jointext(text_parts, "")
	if(!istext(content) && !islist(response))
		return send_reply("Штабная нейросеть прислала битый пакет. Повтори запрос.")

	if(!islist(response))
		var/trimmed_content = trim(content)
		// Remove optional markdown fences around a JSON object.
		trimmed_content = replacetext(trimmed_content, "```json", "")
		trimmed_content = replacetext(trimmed_content, "```", "")
		trimmed_content = trim(trimmed_content)
		if(copytext_char(trimmed_content, 1, 2) == "{")
			response = safe_json_decode(trimmed_content)
		if(!islist(response))
			response = list("reply" = content, "action" = list("type" = "none"))

	// If prose surrounds a JSON object, prefer the decoded object and hide protocol data.
	var/raw_reply = response["reply"]
	if(istext(raw_reply))
		var/json_start = findtext(raw_reply, "{")
		var/json_end = findlasttext(raw_reply, "}")
		if(json_start && json_end >= json_start)
			var/list/inner_response = safe_json_decode(copytext(raw_reply, json_start, json_end + 1))
			if(islist(inner_response) && (("reply" in inner_response) || ("action" in inner_response)))
				response = inner_response

	var/reply = trim(strip_html(response["reply"]))
	if(isnull(reply))
		reply = "Принято. Уточни запрос по форме: что нужно и на какой маяк."
	var/had_reply = !!reply
	var/list/action = response["action"]
	response_log_entry["action"] = action
	if(islist(action) && action["type"] == "deliver")
		var/delivery_result = execute_delivery(action, request)
		if(delivery_result)
			reply = "[reply] [delivery_result]"
	response_log_entry["reply"] = reply
	if(!had_reply)
		return
	add_history("assistant", reply)
	send_reply(reply)

/// Creates an order only after the remote answer is checked against the live state.
/datum/controller/subsystem/requisitions_ai/proc/execute_delivery(list/action, datum/requisitions_ai_request/request)
	if(!request.requester || request.requester.faction != FACTION_TERRAGOV)
		return "Отмена: вызывающий абонент недоступен."
	var/list/requested_packs = action["packs"]
	if(!islist(requested_packs))
		// Legacy single-pack actions remain valid while models adopt packs.
		requested_packs = list(list("pack" = action["pack"], "pack_name" = action["pack_name"], "quantity" = action["quantity"]))
	if(!length(requested_packs) || length(requested_packs) > 4)
		return "Отмена: число наборов указано некорректно."
	var/list/packs_to_deliver = list()
	var/purchase_cost = 0
	for(var/list/requested_pack as anything in requested_packs)
		var/pack_id = requested_pack["pack"]
		var/pack_name = requested_pack["pack_name"]
		if(!istext(pack_id) && !istext(pack_name))
			return "Отмена: набор не указан корректно."
		var/datum/supply_packs/pack = resolve_supply_pack(pack_id, pack_name)
		if(!pack)
			return "Отмена: такого набора в карго нет."
		var/quantity = clamp(round(text2num(requested_pack["quantity"])), 1, 3)
		packs_to_deliver += list(list("pack" = pack, "quantity" = quantity))
		purchase_cost += pack.cost * quantity
	var/datum/supply_beacon/beacon = find_terragov_beacon(action["beacon"])
	if(!beacon)
		return "Отмена: маяк не найден, не наш или непригоден для сброса."
	var/datum/supply_order/order = new
	var/mob/living/carbon/human/marine = request.requester
	order.id = ++SSpoints.ordernum
	order.orderer = marine.real_name
	order.orderer_ckey = marine.ckey
	order.orderer_rank = marine.get_assignment()
	order.authorised_by = "Requisitions AI"
	order.reason = "Urgent radio request"
	order.faction = FACTION_TERRAGOV
	order.pack = list()
	for(var/list/pack_entry as anything in packs_to_deliver)
		var/datum/supply_packs/delivery_pack = pack_entry["pack"]
		for(var/i in 1 to pack_entry["quantity"])
			order.pack += delivery_pack
	SSpoints.supply_points[FACTION_TERRAGOV] -= purchase_cost
	if(!islist(SSpoints.shoppinglist[FACTION_TERRAGOV]))
		SSpoints.shoppinglist[FACTION_TERRAGOV] = list()
	SSpoints.shoppinglist[FACTION_TERRAGOV]["[order.id]"] = order
	if(!SSpoints.fast_delivery_to_beacon(order, beacon))
		SSpoints.shoppinglist[FACTION_TERRAGOV] -= "[order.id]"
		SSpoints.supply_points[FACTION_TERRAGOV] += purchase_cost
		qdel(order)
		return "Отмена: fast delivery отклонила сброс."
	return "Сброс #[order.id] отправлен на маяк [beacon.name]."

/datum/controller/subsystem/requisitions_ai/proc/find_terragov_beacon(beacon_name)
	if(!istext(beacon_name))
		return
	var/search_name = normalize_beacon_name(beacon_name)
	if(!search_name)
		return
	var/datum/supply_beacon/partial_match
	for(var/name in GLOB.supply_beacon)
		var/normalized_name = normalize_beacon_name(name)
		if(normalized_name != search_name && !findtext(normalized_name, search_name) && !findtext(search_name, normalized_name))
			continue
		var/datum/supply_beacon/beacon = GLOB.supply_beacon[name]
		// fast_delivery() itself does not restrict faction; preserve that behaviour for
		// AI requests while still requiring a real, surface-level landing zone.
		if(!beacon.drop_location || !is_ground_level(beacon.drop_location.z))
			continue
		if(isspaceturf(beacon.drop_location) || beacon.drop_location.density)
			continue
		if(normalized_name == search_name)
			return beacon
		if(partial_match)
			return // ambiguous fuzzy match: never guess
		partial_match = beacon
	return partial_match

/datum/controller/subsystem/requisitions_ai/proc/normalize_beacon_name(value)
	var/normalized = lowertext(trim(strip_html("[value]", 120)))
	for(var/quote in list("\"", "'", "`", "«", "»", "“", "”", "„", "‟"))
		normalized = replacetext(normalized, quote, "")
	// Models often include the descriptive word even though the catalogue name does not.
	if(findtext(normalized, "маяк ") == 1)
		normalized = copytext(normalized, 6)
	if(findtext(normalized, "beacon ") == 1)
		normalized = copytext(normalized, 8)
	return trim(normalized)

/datum/controller/subsystem/requisitions_ai/proc/resolve_supply_pack(identifier, display_name)
	var/datum/supply_packs/pack
	if(istext(identifier))
		pack = SSpoints.supply_packs[text2path(identifier)]
	if(pack)
		return pack
	if(!istext(display_name) && istext(identifier))
		display_name = identifier
	if(!istext(display_name))
		return
	var/search = lowertext(trim(strip_html(display_name, 120)))
	if(!search)
		return
	for(var/pack_type in SSpoints.supply_packs)
		var/datum/supply_packs/candidate = SSpoints.supply_packs[pack_type]
		if(lowertext(candidate.name) == search)
			return candidate
		for(var/item_type in candidate.contains)
			var/atom/movable/item_path = item_type
			if(lowertext(initial(item_path.name)) == search)
				return candidate
	var/datum/supply_packs/match
	for(var/pack_type in SSpoints.supply_packs)
		var/datum/supply_packs/candidate = SSpoints.supply_packs[pack_type]
		var/unique_token = FALSE
		for(var/token in splittext(search, " "))
			if(length(token) >= 4 && findtext(lowertext(candidate.name), token))
				unique_token = TRUE
		if(unique_token)
			if(match)
				return
			match = candidate
	return match

/datum/controller/subsystem/requisitions_ai/proc/send_reply(message)
	var/safe_message = trim(strip_html(message))
	if(!safe_message)
		return
	if(!output_radio)
		// This is a fixed infrastructure transmitter, not an origin or a reply target.
		// talk_into() needs its source to be on a Z-level accepted by telecomms;
		// (1,1,1) may be on a different map level and causes the signal to vanish.
		output_radio = new(get_output_radio_turf())
	output_radio.talk_into(output_radio, safe_message, RADIO_CHANNEL_REQUISITIONS)

/datum/controller/subsystem/requisitions_ai/proc/get_output_radio_turf()
	for(var/obj/machinery/telecomms/receiver/receiver as anything in GLOB.telecomms_list)
		if(receiver.on && islist(receiver.freq_listening) && (FREQ_REQUISITIONS in receiver.freq_listening))
			return get_turf(receiver)
	for(var/obj/machinery/telecomms/allinone/all_in_one as anything in GLOB.telecomms_list)
		if(all_in_one.on && islist(all_in_one.freq_listening) && (FREQ_REQUISITIONS in all_in_one.freq_listening))
			return get_turf(all_in_one)
	return locate(1, 1, 1)

/// Invisible AI headset used solely to preserve the normal radio pipeline and log format.
/obj/item/radio/headset/mainship/mcom/silicon/requisitions_ai
	name = "Requisitions AI"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	frequency = FREQ_REQUISITIONS

/obj/item/radio/headset/mainship/mcom/silicon/requisitions_ai/GetVoice()
	return SSrequisitions_ai?.personality_name || "Requisitions AI"
