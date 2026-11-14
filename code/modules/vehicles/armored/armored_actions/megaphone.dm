/datum/action/vehicle/sealed/armored/megaphone
	name = "Megaphone"
	desc = "Позволяет говорить свою волю внешнему миру. Вы этого не услышите, а все снаружи - да."
	action_icon = 'icons/mob/actions/actions_vehicle.dmi'
	action_icon_state = "car_megaphone"
	keybinding_signals = list(KEYBINDING_NORMAL = COMSIG_KB_VEHICLE_MEGAPHONE)

/datum/action/vehicle/sealed/armored/megaphone/action_activate(trigger_flags)
	/*
	if(!owner?.client || !chassis || !(owner in chassis.occupants))
		return
	*/
	var/inputed_text = input(usr, "Сообщение услышат все вокруг техники", "Megaphone")
	if(TIMER_COOLDOWN_RUNNING(chassis, COOLDOWN_ARMORED_MEGAPHONE))
		return
	if(!inputed_text || inputed_text == "")
		return
	usr.say(inputed_text) //Здесь чел из экипажа это типо в трубку пиздит, чтоб слышал его сосед и он сам
	inputed_text = "<span style=\"font-size: [36]px;\">[inputed_text]</span>" //Увеличиваем размер
	TIMER_COOLDOWN_START(chassis, COOLDOWN_ARMORED_MEGAPHONE, 1 SECONDS)
	chassis.say(inputed_text)
	for(var/mob/somebody in get_hearers_in_view(7, chassis))
		if(!somebody.client)
			continue
		if(somebody.stat == UNCONSCIOUS || somebody.stat == DEAD)
			continue //Без сознания
		///Бро, тут очень важный момент. chassis.hitbox для того чтоб рунчат шёл с центра танка.
		somebody.create_chat_message(chassis.hitbox, /datum/language/common, inputed_text)


