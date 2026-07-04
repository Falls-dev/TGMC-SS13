/datum/buildmode_mode/boom
	key = "boom"
	var/power_choice
	var/falloff_choice
	var/falloff_shape_choice


/datum/buildmode_mode/boom/show_help(client/user)
	to_chat(user, custom_boxed_message("purple_box",\
		"[span_bold("Kaboom")] -> Mouse Button on obj/turf/mob\n\
		NOTE: Using the \"Config/Launch Supplypod\" verb allows you to do this in an IC way (ie making a cruise missile come down from the sky and explode wherever you click!)"))

/datum/buildmode_mode/boom/change_settings(client/user)
	power_choice = tgui_input_number(user, "Explosion Power", "Choose explosion power", 250, 5000, 1)
	if(isnull(power_choice))
		return
	falloff_choice = tgui_input_number(user, "Explosion Falloff", "Choose explosion falloff", 50, 5000, 1)
	if(isnull(falloff_choice))
		return
	switch(tgui_alert(user, "Falloff Shape", "Choose falloff shape", list("Linear", "Exponential"), 0))
		if("Linear")
			falloff_shape_choice = EXPLOSION_FALLOFF_SHAPE_LINEAR
		if("Exponential")
			falloff_shape_choice = EXPLOSION_FALLOFF_SHAPE_EXPONENTIAL

/datum/buildmode_mode/boom/handle_click(client/user, params, obj/object)
	var/list/pa = params2list(params)
	var/left_click = pa.Find("left")

	if(left_click)
		cell_explosion(object, power_choice, falloff_choice, falloff_shape_choice, silent = TRUE)
		to_chat(user, span_notice("Success."))
		log_admin("Build Mode: [key_name(user)] caused an explosion (power = [power_choice], falloff = [falloff_choice], falloff_shape = [falloff_shape_choice] at [AREACOORD(object)]")
