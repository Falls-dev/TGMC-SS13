/client
	/// Current yaw-angle client is facing when using 3D webclient
	var/e3d_angle = 0
	var/e3d_received_stats = FALSE
	var/e3d_stats = null

/client/verb/e3d_setangle(angle as num)
	set hidden = TRUE
	set instant = TRUE
	set name = ".e3d_setangle"
	e3d_angle = angle

/client/verb/e3d_webgl_stats(stats as text)
	set hidden = TRUE
	set name = ".e3d_webgl_stats"
	if(e3d_received_stats)
		return
	if(length(stats) > 2500)
		return
	e3d_stats = params2list(stats)
	if(e3d_stats["gl_extensions"])
		e3d_stats["gl_extensions"] = splittext(e3d_stats["gl_extensions"], ",")
	if(e3d_stats["gl2_extensions"])
		e3d_stats["gl2_extensions"] = splittext(e3d_stats["gl2_extensions"], ",")

/// use in place of browse_rsc so the 3D webclient also receives the resource
/proc/browse_rsc_web(target, resource, path)
	target << browse_rsc(resource, path)
	if(!path)
		path = "[resource]"
		path = copytext(path, findlasttext(path, "/") + 1)
	if(path)
		target << output("\ref[fcopy_rsc(resource)]=[path]", "byond-wcp:browse_rsc")

/mob
	var/e3d_eye_height = 0.82

/mob/proc/e3d_update_client()
	if(!client)
		return
	winset(client, null, "e3d-eye-height=[e3d_eye_height]")

/proc/extract_e3d_tag(screen_loc)
	if(!screen_loc)
		return ""
	var/char = length(screen_loc)+1

	while(char > 1)
		var/code = text2ascii(screen_loc, char-1)
		if(code >= 9 && code <= 13)
			char--
		else
			break
	return copytext(screen_loc, char)

/proc/modify_e3d_tag(screen_loc, new_tag)
	if(!screen_loc)
		return new_tag
	var/char = length(screen_loc)+1

	while(char > 1)
		var/code = text2ascii(screen_loc, char-1)
		if(code >= 9 && code <= 13)
			char--
		else
			break
	return "[copytext(screen_loc, 1, char)][new_tag]"
