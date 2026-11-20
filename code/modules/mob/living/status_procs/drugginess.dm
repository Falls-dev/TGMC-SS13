///Modify mob's drugginess in either direction, minimum zero. Adds or removes druggy overlay as appropriate.
/mob/living/proc/adjust_drugginess(amount)
	druggy = max(druggy + amount, 0)
	if(druggy)
		var/atom/movable/screen/fullscreen/overlay = fullscreens["high"]
		if(!overlay || overlay.removal_timer)
			overlay_fullscreen("high", /atom/movable/screen/fullscreen/high)
	else
		var/atom/movable/screen/fullscreen/overlay = fullscreens["high"]
		if(overlay && !overlay.removal_timer)
			clear_fullscreen("high")

///Sets mob's drugginess to provided amount, minimum 0. Adds or removes druggy overlay as appropriate.
/mob/living/proc/set_drugginess(amount)
	druggy = max(amount, 0)
	if(druggy)
		var/atom/movable/screen/fullscreen/overlay = fullscreens["high"]
		if(!overlay || overlay.removal_timer)
			overlay_fullscreen("high", /atom/movable/screen/fullscreen/high)
	else
		var/atom/movable/screen/fullscreen/overlay = fullscreens["high"]
		if(overlay && !overlay.removal_timer)
			clear_fullscreen("high")
