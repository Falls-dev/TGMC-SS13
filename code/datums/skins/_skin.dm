///There must be a way to do it better than this, as I just use it as a list
/datum/xenomorph_skin
	///Name of skin which will be seen in skins list
	var/name = "Basic"
	///Icon to which we switch
	var/icon
	///Icon of our effects to which we switch
	var/effects_icon
	///The access we need to have to be able to change to this skin
	var/access_needed = BOOSTY_TIER_1
	/// Если у ксена больше/меньше 3 состояний повреждений (effects_icon)
	var/max_wound_states = 3
	/// Звук при выборе скина
	var/select_sound = null
	/// Кастомный звук смерти
	var/death_sound = null
	/// Кастомный звук атаки
	var/attack_sound = null
	/// Шанс срабатывания кастомного звука атаки (в %)
	var/attack_sound_chance = 100
	/// Кастомный звук при получении урона (вместо hiss! и roar!)
	var/pain_sound = null
	/// Кастомный звук когда мы убиваем человека
	var/kill_sound = null
