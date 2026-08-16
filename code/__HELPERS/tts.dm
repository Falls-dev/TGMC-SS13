/proc/tts_speech_filter(text)
	// Only allow alphanumeric characters and whitespace
	var/static/regex/bad_chars_regex = regex("\[^a-zA-Zа-яА-ЯёЁ0-9 ,?.!'&-]", "g")
	return bad_chars_regex.Replace(text, " ")
