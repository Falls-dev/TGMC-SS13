// Verb to link discord accounts to BYOND accounts
/client/verb/linkdiscord()
	set category = "OOC.Discord"
	set name = "Link Discord Account"
	set desc = "Register your account via the Discord bot."

	var/bot_url = CONFIG_GET(string/discord_bot_url)
	if(!bot_url)
		to_chat(src, span_warning("Регистрация временно недоступна."))
		return

	var/choice = tgui_alert(usr, "Для привязки аккаунта нужно пройти регистрацию в Discord-боте.\nДля этого напишите в личку бота команду '/reg' с вашим никнеймом и следуйте инструкциям.\nОткрыть бота?", "Регистрация", list("Да", "Нет"))
	if(choice == "Да")
		DIRECT_OUTPUT(src, link(bot_url))

/client/verb/check_discord()
	set category = "OOC.Discord"
	set name = "Check Discord ID"
	set desc = "Check your Discord registration status"

	if(TIMER_COOLDOWN_RUNNING(src, COOLDOWN_CHECK_DISCORD))
		to_chat(src, span_warning("Подождите немного перед повторной проверкой."))
		return
	TIMER_COOLDOWN_START(src, COOLDOWN_CHECK_DISCORD, 3 SECONDS)

	if(!SSdiscord)
		to_chat(src, span_notice("Сервер ещё запускается. Подождите немного."))
		return

	if(!SSdiscord.is_aperture_api_configured())
		to_chat(src, span_warning("Возникла ошибка, попробуйте позднее."))
		return

	var/result = SSdiscord.lookup_registration(usr.ckey)
	if(result == 0)
		to_chat(usr, span_notice("Данные не найдены. Вы точно регистрировались?"))
		return

	if(!islist(result))
		to_chat(usr, span_warning("Возникла ошибка, попробуйте позднее."))
		return

	var/list/data = result
	var/active = text2num(data["active"])
	switch(active)
		if(1)
			to_chat(usr, span_notice("Регистрация не завершена. Продолжите регистрацию через бота или обратитесь к администрации за помощью."))
		if(2)
			to_chat(usr, span_notice("Вы зарегестрированы."))
		else
			to_chat(usr, span_warning("Возникла ошибка, попробуйте позднее."))

/client/verb/boosty_roly()
	set category = "OOC.Discord"
	set name = "Check Boosty"
	set desc = "Check your Boosty subscription tier"

	if(TIMER_COOLDOWN_RUNNING(src, COOLDOWN_CHECK_DISCORD))
		to_chat(src, span_warning("Подождите немного перед повторной проверкой."))
		return
	TIMER_COOLDOWN_START(src, COOLDOWN_CHECK_DISCORD, 3 SECONDS)

	if(!SSdiscord)
		to_chat(src, span_notice("Сервер ещё запускается. Подождите немного."))
		return

	var/tier = SSdiscord.get_boosty_tier(usr.ckey, TRUE)
	if(isnull(tier))
		to_chat(usr, span_warning("Возникла ошибка, попробуйте позднее."))
		return

	if(tier == BOOSTY_TIER_0)
		to_chat(usr, span_notice("У вас нет подписки."))
		return

	if(tier >= BOOSTY_TIER_1 && tier <= BOOSTY_TIER_3)
		to_chat(usr, span_notice("У вас [tier] уровень подписки."))
		return

	to_chat(usr, span_warning("Возникла ошибка, попробуйте позднее."))
