// Tools used for research
/obj/item/tool/research
	///Skill type needed to use the tool
	var/skill_type = SKILL_MEDICAL
	///Skill level needed to use the tool
	var/skill_threshold = SKILL_MEDICAL_EXPERT

/obj/item/tool/research/xeno_analyzer
	name = "xenomorph analyzer"
	desc = "A tool for analyzing xenomorphs for research material. Just click on a xenomorph. Can be used to befriend Newt."
	icon = 'icons/obj/items/surgery_tools.dmi'
	icon_state = "predator_bonesaw"
	///List of rewards for each xeno tier
	var/static/list/xeno_tier_rewards = list(
		XENO_TIER_ZERO = list(
			/obj/item/research_resource/xeno/tier_one,
		),
		XENO_TIER_ONE = list(
			/obj/item/research_resource/xeno/tier_one,
		),
		XENO_TIER_TWO = list(
			/obj/item/research_resource/xeno/tier_two,
		),
		XENO_TIER_THREE = list(
			/obj/item/research_resource/xeno/tier_three,
		),
		XENO_TIER_FOUR = list(
			/obj/item/research_resource/xeno/tier_four,
		),
	)

/obj/item/tool/research/xeno_analyzer/attack(mob/living/M, mob/living/user)
	if(!isxeno(M))
		return ..()

	var/mob/living/carbon/xenomorph/target_xeno = M

	var/list/xeno_rewards = xeno_tier_rewards[target_xeno.tier]
	if(!xeno_rewards)
		balloon_alert(user, "Can't research")
		return ..()

	if(HAS_TRAIT(target_xeno, TRAIT_RESEARCHED))
		balloon_alert(user, "Already probed")
		return ..()

	if(user.skills.getRating(SKILL_MEDICAL) < SKILL_MEDICAL_EXPERT)
		user.balloon_alert_to_viewers("Tries to find weak point on [target_xeno]")
		var/fumbling_time = 15 SECONDS - 2 SECONDS * user.skills.getRating(SKILL_MEDICAL)
		if(!do_after(user, fumbling_time, NONE, src, BUSY_ICON_UNSKILLED))
			return ..()
	user.balloon_alert_to_viewers("Begins cutting [target_xeno]")
	if(!do_after(user, 5 SECONDS, NONE, src, BUSY_ICON_FRIENDLY))
		return ..()

	if(HAS_TRAIT(target_xeno, TRAIT_RESEARCHED))
		balloon_alert(user, "Already probed")
		return ..()

	var/reward_typepath = pick(xeno_rewards)
	var/obj/reward = new reward_typepath
	reward.forceMove(get_turf(user))
	ADD_TRAIT(target_xeno, TRAIT_RESEARCHED, TRAIT_RESEARCHED)
	return ..()

/obj/item/tool/research/excavation_tool
    name = "Archaeological omni-brush"
    desc = "A high-precision archaeological brush. Use it in your hand to change the soil removal step (1, 2, 5, 10, 20, 30 cm)."
    icon = 'icons/obj/items/surgery_tools.dmi'
    icon_state = "omni_brush_1"
    skill_type = SKILL_MEDICAL
    skill_threshold = SKILL_MEDICAL_EXPERT
    var/list/dig_sizes = list(1, 2, 5, 10, 20, 30)
    var/dig_mode_index = 1

/obj/item/tool/research/excavation_tool/examine(mob/user)
    . = ..()
    var/current_size = dig_sizes[dig_mode_index]
    . += span_notice("Current brush step: [current_size] cm")

/obj/item/tool/research/excavation_tool/attack_self(mob/user)
    dig_mode_index++
    if(dig_mode_index > length(dig_sizes))
        dig_mode_index = 1
    var/current_size = dig_sizes[dig_mode_index]

    icon_state = "omni_brush_[current_size]"

    balloon_alert(user, "Brush: [current_size] cm")

/obj/item/tool/research/excavation_tool/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
    if(!proximity_flag)
        return ..()

    var/turf/T = get_turf(target)
    if(!T)
        return ..()

    var/datum/dig_site/S = SSxeno_archaeology?.get_site_at(T)
    if(!S)
        balloon_alert(user, "There's nothing here")
        return

    if(user.skills.getRating(skill_type) < skill_threshold)
        balloon_alert(user, "Skill issue")
        return

    var/current_size = dig_sizes[dig_mode_index]

    user.visible_message(span_notice("[user] begins to carefully remove the soil..."), \
    span_notice("You begin careful excavation [S.site_name]..."))

    var/dig_time = 3 SECONDS + (current_size * 0.1 SECONDS)

    if(!do_after(user, dig_time, target = T))
        return

    S = SSxeno_archaeology?.get_site_at(T)
    if(!S)
        return

    S.current_depth += current_size

    if(S.current_depth == S.target_depth)
        user.visible_message(span_notice("[user] retrieves the remains"), \
        span_boldnotice("You have cleared the fossil."))

        spawn_remains(T, S.tier)
        SSxeno_archaeology.clear_site(S)

    else if(S.current_depth > S.target_depth)
        user.visible_message(span_danger("There is a crunching sound coming from [S.site_name]!"), \
        span_danger("You hear the crunch!"))

        new /obj/item/research_resource/remains/tier_zero(T)
        SSxeno_archaeology.clear_site(S)

    else
        to_chat(user, span_info("You have cleared the soil layer."))

/obj/item/tool/research/excavation_tool/proc/spawn_remains(turf/T, tier)
    switch(tier)
        if(0)
            new /obj/item/research_resource/remains/tier_zero(T)
        if(1)
            new /obj/item/research_resource/remains/tier_one(T)
        if(2)
            new /obj/item/research_resource/remains/tier_two(T)
        if(3)
            new /obj/item/research_resource/remains/tier_three(T)
        if(4)
            new /obj/item/research_resource/remains/tier_four(T)
