/**
 * Message-related procs
 *
 * Message format (/list):
 * - type - Message type, must be one of defines in `code/__DEFINES/chat.dm`
 * - text - Plain message text
 * - html - HTML message text
 * - Optional metadata, can be any key/value pair.
 *
 * Copyright (c) 2020 Aleksej Komarov
 * SPDX-License-Identifier: MIT
 */

/proc/message_to_html(message)
	// Here it is possible to add a switch statement
	// to custom-handle various message types.
	return message["html"] || chat_text_to_html(message["text"])

/// Format plain chat text for an HTML output while retaining its line breaks.
/proc/chat_text_to_html(text, allow_break_tag = FALSE)
	if(!istext(text))
		return ""
	if(allow_break_tag)
		var/static/regex/break_tag = regex(@"<br[ \t]*/?>", "gi")
		text = break_tag.Replace(text, "\n")
	var/static/carriage_return = ascii2text(13)
	text = replacetext(text, "[carriage_return]\n", "\n")
	text = replacetext(text, carriage_return, "\n")
	var/list/lines = splittext(text, "\n")
	for(var/index in 1 to length(lines))
		lines[index] = html_encode(lines[index])
	return lines.Join("<br>")
