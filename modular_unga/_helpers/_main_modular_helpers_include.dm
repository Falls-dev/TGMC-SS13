// Put all you modular helpers here, it would be pasted right before TG Helpers
// So you can easily use your helpers in TG code folder, not only in our modular folder

///////////////////////////////////////////////
////////// Проки для склонялки слов ///////////
///////////////////////////////////////////////
/proc/sklonenie_item_tvor(msgfrom as text)
	if(length(msgfrom) <= 2)
		return msgfrom
	var/word_end = copytext_char(msgfrom, -2)
	if(word_end == "ёт" || word_end == "ет")
		return replacetext_char(msgfrom, copytext_char(word_end, -2), "ю ", -2)
	else if (word_end == "бит")
		return replacetext_char(msgfrom, copytext_char(word_end, -3), "блю", -2)
	else if (word_end == "нит")
		return replacetext_char(msgfrom, copytext_char(word_end, -3), "ню", -2)
	else if (word_end == "рю")
		return replacetext_char(msgfrom, copytext_char(word_end, -2), "ню", -2)
	return msgfrom

/proc/skloname(msgfrom as text, rule, gender = null)
	var/to_ret = ""
	for(var/word in splittext_char(msgfrom, " "))
		to_ret += " [skloname_do(word, rule, gender)]"
	return copytext_char(to_ret, 2)

/proc/skloname_do(msgfrom as text, rule, gender = null)
	if(length(msgfrom) <= 2)
		return msgfrom

	var/word_end = ""
	var/i = 0

	//берём последние 2 буквы
	word_end = copytext_char(msgfrom, -2)

	for(var/end in GLOB.PTwoStop)
		if(end == word_end)
			return msgfrom

	//берём последнюю букву
	word_end = copytext_char(msgfrom, -1)

	for(var/end in GLOB.POneStop)
		if(end == word_end)
			return msgfrom

	if(gender == "male")
		for(var/end in GLOB.PmaleOneFrom)
			if(end == word_end)
				return replacetext_char(msgfrom, copytext_char(end, -1), GLOB.PmaleOneTo[rule], -1)

	if(gender == "female")
		//берём последние 3 буквы
		word_end = copytext_char(msgfrom, -3)

		for(var/end in GLOB.PfemaleThreeFrom)
			if(end == word_end)
				return replacetext_char(msgfrom, copytext_char(end, -1), GLOB.PfemaleThreeTo[rule], -3)

		//берём последние 2 буквы
		word_end = copytext_char(msgfrom, -2)

		for(var/end in GLOB.PfemaleTwoFrom)
			if(end == word_end)
				if(i == 0)
					return replacetext_char(msgfrom, copytext_char(end, -2), GLOB.PfemaleTwoTo[rule], -2)
				else
					return replacetext_char(msgfrom, copytext_char(end, -1), GLOB.PfemaleTwoTo[rule + 5], -2)
			i++

		for(var/end in GLOB.PfemaleOneFrom)
			if(end == word_end)
				if(rule == VINITELNI || rule == TVORITELNI)
					return "[msgfrom][GLOB.PfemaleOneTo[rule]]"
				return replacetext_char(msgfrom, copytext_char(end, -1), GLOB.PfemaleOneTo[rule], -1)

		for(var/end in GLOB.PfemaleOneStop)
			if(end == word_end)
				return msgfrom

	//берём последние 4 буквы
	word_end = copytext_char(msgfrom, -4)

	for(var/end in GLOB.PFourFrom)
		if(end == word_end)
			return replacetext_char(msgfrom, copytext_char(end, -2), GLOB.PFourTo[rule], -4)

	for(var/end in GLOB.PFourOtherFrom)
		if(end == word_end)
			return replacetext_char(msgfrom, copytext_char(end, -1), GLOB.PFourOtherTo[rule], -4)

	for(var/end in GLOB.PFourListFrom)
		if(end == word_end)
			return replacetext_char(msgfrom, copytext_char(end, -2), GLOB.PFourListTo[rule], -4)

	for(var/end in GLOB.PFourListOtherFrom)
		if(end == word_end)
			return replacetext_char(msgfrom, copytext_char(end, -2), GLOB.PFourListOtherTo[rule], -4)

	//берём последние 3 буквы
	word_end = copytext_char(msgfrom, -3)

	for(var/end in GLOB.PThreeFrom)
		if(end == word_end)
			return "[msgfrom][GLOB.PThreeTo[rule]]"

	for(var/end in GLOB.PThreeListFrom)
		if(end == word_end)
			return replacetext_char(msgfrom, copytext_char(end, -1), GLOB.PThreeListTo[rule], -3)

	for(var/end in GLOB.PThreeListOtherFrom)
		if(end == word_end)
			if(rule == TVORITELNI)
				return replacetext_char(msgfrom, copytext_char(end, -2), GLOB.PThreeListOtherTo[rule], -3)
			return replacetext_char(msgfrom, copytext_char(end, -1), GLOB.PThreeListOtherTo[rule], -3)

	for(var/end in GLOB.PThreeListTooFrom)
		if(end == word_end)
			if(rule == TVORITELNI)
				return replacetext_char(msgfrom, copytext_char(end, -1), GLOB.PThreeListTooTo[rule], -3)
			return replacetext_char(msgfrom, copytext_char(end, -2), GLOB.PThreeListTooTo[rule], -3)

	if("кий" == word_end)
		if(rule == TVORITELNI)
			return replacetext_char(msgfrom, copytext_char("кий", -1), GLOB.POtherListTo[rule], -3)
		return replacetext_char(msgfrom, copytext_char("кий", -2), GLOB.POtherListTo[rule], -3)

	//берём последние 2 буквы
	word_end = copytext_char(msgfrom, -2)

	i = 0
	for(var/end in GLOB.PTwoFrom)
		if(end == word_end)
			if(i == 0)
				return "[msgfrom][GLOB.PTwoTo[rule]]"
			if(i <= 9)
				return replacetext_char(msgfrom, copytext_char(end, -1), GLOB.PTwoTo[rule + (5 * i)], -2)
			else
				return replacetext_char(msgfrom, copytext_char(end, -2), GLOB.PTwoTo[rule + (5 * i)], -2)
		i++

	for(var/end in GLOB.PTwoListFrom)
		if(end == word_end)
			return replacetext_char(msgfrom, copytext_char(end, -1), GLOB.PTwoListTo[rule], -2)

	for(var/end in GLOB.PTwoListOtherFrom)
		if(end == word_end)
			return "[msgfrom][GLOB.PTwoListOtherTo[rule]]"

	if("ый" == word_end)
		if(rule == TVORITELNI)
			return replacetext_char(msgfrom, copytext_char("ый", -1), GLOB.POtherListTo[rule], -2)
		return replacetext_char(msgfrom, copytext_char("ый", -2), GLOB.POtherListTo[rule], -2)

	//берём последюю букву
	word_end = copytext_char(msgfrom, -1)

	i = 0
	for(var/end in GLOB.POneFrom)
		if(end == word_end)
			return replacetext_char(msgfrom, copytext_char(end, -1), GLOB.POneTo[rule + (5 * i)], -1)
		i++

	for(var/end in GLOB.POneListFrom)
		if(end == word_end)
			return "[msgfrom][GLOB.POneListTo[rule]]"

	for(var/end in GLOB.POneListOtherFrom)
		if(end == word_end)
			return "[msgfrom][GLOB.POneListOtherTo[rule]]"

	for(var/end in GLOB.POneListTooFrom)
		if(end == word_end)
			return "[msgfrom][GLOB.POneListTooTo[rule]]"

	return msgfrom // возвращаем слово, если оно чудом не нашло своего конца



///////////////////////////////////////////////
// Направления сторон света на русском языке //
///////////////////////////////////////////////
/proc/dir2rutext(direction)
	switch(direction)
		if(NORTH)
			return "север"
		if(SOUTH)
			return "юг"
		if(EAST)
			return "восток"
		if(WEST)
			return "запад"
		if(NORTHEAST)
			return "северо-восток"
		if(SOUTHEAST)
			return "юго-восток"
		if(NORTHWEST)
			return "северо-запад"
		if(SOUTHWEST)
			return "юго-запад"

//И сокращённая версия
/proc/dir2rutext_short(direction)
	switch(direction)
		if(NORTH)
			return "С"
		if(SOUTH)
			return "Ю"
		if(EAST)
			return "В"
		if(WEST)
			return "З"
		if(NORTHEAST)
			return "СВ"
		if(SOUTHEAST)
			return "ЮВ"
		if(NORTHWEST)
			return "СЗ"
		if(SOUTHWEST)
			return "ЮЗ"
