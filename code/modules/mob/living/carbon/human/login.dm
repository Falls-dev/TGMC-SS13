/mob/living/carbon/human/Login()
	. = ..()
	species?.handle_login_special(src)

	if(istype(wear_ear, /obj/item/radio/headset/mainship))
		var/obj/item/radio/headset/mainship/headset = wear_ear
		headset.refresh_wearer_hud(src)

	if(HAS_TRAIT(src, TRAIT_IS_RESURRECTING))
		to_chat(src, span_notice("You are resurrecting, hold still..."))

	if(SStts.tts_enabled && !voice)
		voice = random_tts_voice()
