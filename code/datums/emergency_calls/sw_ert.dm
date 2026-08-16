////////////////////////////////////////////////////////////////////////////////
// ЕРТ звёздных войн
////////////////////////////////////////////////////////////////////////////////

/// Shared helper: mind transfer + backstory print used by all SW ERTs
/datum/emergency_call/sw/proc/finish_spawn(datum/mind/M, mob/living/carbon/human/H)
	var/mob/original = M.current
	M.transfer_to(H, TRUE)
	H.fully_replace_character_name(M.name, H.real_name)
	if(original)
		qdel(original)
	print_backstory(H)

////////////////////////////////////////////////////////////////////////////////
// 1) Повстанцы - CLF но в обёртке ЗВ
////////////////////////////////////////////////////////////////////////////////

/datum/emergency_call/sw/rebels
	name = "Rebel Alliance Squad"
	base_probability = 10
	alignement_factor = 1 // hostile like CLF
	mob_min = 3
	mob_max = 10

/datum/emergency_call/sw/rebels/print_backstory(mob/living/carbon/human/H)
	to_chat(H, "<B>Вы - солдат Альянса повстанцев, участник нерегулярных формирований, сражающихся с тиранией повсюду, где она возникает.</B>")
	to_chat(H, "<B>Сигнал бедствия с[SSmapping.configs[SHIP_MAP].map_name] собрался до вашей ячейки. Уничтожьте союзников Империи.</B>")

/datum/emergency_call/sw/rebels/create_member(datum/mind/M)
	. = ..()
	if(!.)
		return
	var/mob/living/carbon/human/H = .
	finish_spawn(M, H)
	if(!leader)
		leader = H
		H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/rebel/officer))
		to_chat(H, "<p style='font-size:1.5em'>[span_notice("Ты командуешь этой группой повстанцев. За Альянс! За свободу!")]</p>")
		return
	if(medics < max_medics)
		H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/rebel/medic))
		to_chat(H, "<p style='font-size:1.5em'>[span_notice("Ты медик повстанцев, прикрепленный к этой группе.")]</p>")
		medics++
		return
	H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/rebel))
	to_chat(H, "<p style='font-size:1.5em'>[span_notice("Ты солдат повстанцев, откликнувшийся на сигнал бедствия.")]</p>")

////////////////////////////////////////////////////////////////////////////////
// 2) Клоны фазы 1 времён Республики
////////////////////////////////////////////////////////////////////////////////

/datum/emergency_call/sw/clone_basic
	name = "Clone Basic Squad"
	base_probability = 8
	alignement_factor = -1 // TerraGov-aligned
	mob_min = 9
	mob_max = 15
	var/engineers = 0
	var/max_engineers = 1
	var/mps = 0
	var/max_mps = 2
	var/pilots = 0
	var/max_pilots = 1

/datum/emergency_call/sw/clone_basic/print_backstory(mob/living/carbon/human/H)
	to_chat(H, "<B>Ты - клон-солдат Великой армии Республики.</B>")
	to_chat(H, "<B>Ваш штаб получил сигнал бедствия с [SSmapping.configs[SHIP_MAP].map_name]. Помогите союзникам Республики.</B>")
	to_chat(H, "<B>Хороший солдат выполняет приказы.</B>")

/datum/emergency_call/sw/clone_basic/create_member(datum/mind/M)
	. = ..()
	if(!.)
		return
	var/mob/living/carbon/human/H = .
	finish_spawn(M, H)
	if(!leader)
		leader = H
		H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/clone/lieutenant))
		to_chat(H, "<p style='font-size:1.5em'>[span_notice("Ты лейтенант этой группы клонов.")]</p>")
		return
	if(engineers < max_engineers)
		H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/clone/engineer))
		to_chat(H, "<p style='font-size:1.5em'>[span_notice("Ты инженер этой группы.")]</p>")
		engineers++
		return
	if(pilots < max_pilots)
		H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/clone/pilot))
		to_chat(H, "<p style='font-size:1.5em'>[span_notice("Ты пилот этой группы с навыками медицинской помощи.")]</p>")
		pilots++
		return
	if(mps < max_mps)
		H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/clone/mp))
		to_chat(H, "<p style='font-size:1.5em'>[span_notice("Ты ветеран этой группы.")]</p>")
		mps++
		return
	H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/clone/trooper))
	to_chat(H, "<p style='font-size:1.5em'>[span_notice("Ты солдат этой группы и самой Республики.")]</p>")

////////////////////////////////////////////////////////////////////////////////
// 3) Клоны фазы 2 времён Республики
////////////////////////////////////////////////////////////////////////////////

/datum/emergency_call/sw/clone_mk2
	name = "Clone Basic Mk.II Squad"
	base_probability = 7
	alignement_factor = -1
	mob_min = 8
	mob_max = 14
	var/artillery = 0
	var/max_artillery = 1
	var/mps = 0
	var/max_mps = 2
	var/sgts = 0
	var/max_sgts = 1

/datum/emergency_call/sw/clone_mk2/print_backstory(mob/living/carbon/human/H)
	to_chat(H, "<B>Ты - клон-солдат II фазы.</B>")
	to_chat(H, "<B>Высадитесь на [SSmapping.configs[SHIP_MAP].map_name] и защитите союзников Республики от врагов.</B>")

/datum/emergency_call/sw/clone_mk2/create_member(datum/mind/M)
	. = ..()
	if(!.)
		return
	var/mob/living/carbon/human/H = .
	finish_spawn(M, H)
	if(!leader)
		leader = H
		H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/clone_mk2/captain))
		to_chat(H, "<p style='font-size:1.5em'>[span_notice("Ты капитан этой группы клонов.")]</p>")
		return
	if(artillery < max_artillery)
		H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/clone_mk2/artillery))
		to_chat(H, "<p style='font-size:1.5em'>[span_notice("Ты артиллерист-инженер этой группы.")]</p>")
		artillery++
		return
	if(sgts < max_sgts)
		H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/clone_mk2/sgt))
		to_chat(H, "<p style='font-size:1.5em'>[span_notice("Ты сержант этой группы с навыками медицинской помощи.")]</p>")
		sgts++
		return
	if(mps < max_mps)
		H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/clone_mk2/mp))
		to_chat(H, "<p style='font-size:1.5em'>[span_notice("Ты ветеран этой группы.")]</p>")
		mps++
		return
	H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/clone_mk2/trooper))
	to_chat(H, span_notice("Ты солдат второй фазы этой группы и Республики."))

////////////////////////////////////////////////////////////////////////////////
// 4) 501 легион
////////////////////////////////////////////////////////////////////////////////

/datum/emergency_call/sw/legion501
	name = "501st Legion Detachment"
	base_probability = 5
	alignement_factor = -1
	mob_min = 7
	mob_max = 12
	var/radiotechs = 0
	var/max_radiotechs = 1

/datum/emergency_call/sw/legion501/print_backstory(mob/living/carbon/human/H)
	to_chat(H, "<B>Ты военный в 501й Легионе - кулак Верховного главнокомандующего.</B>")
	to_chat(H, "<B>Ваше командование получило сигнал бедствия с [SSmapping.configs[SHIP_MAP].map_name]. Помогите союзникам Республики.</B>")

/datum/emergency_call/sw/legion501/create_member(datum/mind/M)
	. = ..()
	if(!.)
		return
	var/mob/living/carbon/human/H = .
	finish_spawn(M, H)
	if(!leader)
		leader = H
		H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/legion501/commander))
		to_chat(H, "<p style='font-size:1.5em'>[span_notice("Ты командир 501 легиона.")]</p>")
		return
	if(radiotechs < max_radiotechs)
		H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/legion501/radiotech))
		to_chat(H, "<p style='font-size:1.5em'>[span_notice("Ты радиотехник 501 легиона. У себя в сумке есть дрон на радиоуправлении. Используй его для помощи отряду.")]</p>")
		radiotechs++
		return
	H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/legion501/trooper))
	to_chat(H, span_notice("Ты солдат 501 легиона."))

////////////////////////////////////////////////////////////////////////////////
// 5) 212 батальон
////////////////////////////////////////////////////////////////////////////////

/datum/emergency_call/sw/battalion212
	name = "212th Battalion Detachment"
	base_probability = 5
	alignement_factor = -1
	mob_min = 6
	mob_max = 12

/datum/emergency_call/sw/battalion212/print_backstory(mob/living/carbon/human/H)
	to_chat(H, "<B>Ты солдан в 212й батальона - подразделение основанное великим коммандером Коди.</B>")
	to_chat(H, "<B>Ваш батальон получил сигнал бедствия с [SSmapping.configs[SHIP_MAP].map_name].</B>")
	to_chat(H, "<B>Коммандер разрешил отправку части батальона для помощи союзникам Республики.</B>")

/datum/emergency_call/sw/battalion212/create_member(datum/mind/M)
	. = ..()
	if(!.)
		return
	var/mob/living/carbon/human/H = .
	finish_spawn(M, H)
	if(!leader)
		leader = H
		H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/battalion212/commando))
		to_chat(H, "<p style='font-size:1.5em'>[span_notice("Ты командир этой части 212 батальона.")]</p>")
		return
	H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/battalion212/trooper))
	to_chat(H, span_notice("Ты солдат 212 батальона."))

////////////////////////////////////////////////////////////////////////////////
// 6) 442 батальон
////////////////////////////////////////////////////////////////////////////////

/datum/emergency_call/sw/battalion442
	name = "442nd Siege Battalion Detachment"
	base_probability = 4
	alignement_factor = -1
	mob_min = 6
	mob_max = 12

/datum/emergency_call/sw/battalion442/print_backstory(mob/living/carbon/human/H)
	to_chat(H, "<B>Ты служишь в 442 батальоне - специалисты по осаде.</B>")
	to_chat(H, "<B>Штаб получил сигнал бедствия с судна [SSmapping.configs[SHIP_MAP].map_name]. Защитите союзников Республики.</B>")

/datum/emergency_call/sw/battalion442/create_member(datum/mind/M)
	. = ..()
	if(!.)
		return
	var/mob/living/carbon/human/H = .
	finish_spawn(M, H)
	if(!leader)
		leader = H
		H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/battalion442/commando))
		to_chat(H, "<p style='font-size:1.5em'>[span_notice("Ты командир 442 батальона.")]</p>")
		return
	H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/battalion442/trooper))
	to_chat(H, span_notice("Ты солдат 442 батальона."))

////////////////////////////////////////////////////////////////////////////////
// 7) Гвардия Сената
////////////////////////////////////////////////////////////////////////////////

/datum/emergency_call/sw/senateguard
	name = "Senate Guard Detachment"
	base_probability = 3
	alignement_factor = -1
	mob_min = 2
	mob_max = 6

/datum/emergency_call/sw/senateguard/print_backstory(mob/living/carbon/human/H)
	to_chat(H, "<B>Ты Гвардеец Сената - элитная защита первых лиц Республики.</B>")
	to_chat(H, "<B>Эвакуируй или обеспечь безопасность VIP персон на [SSmapping.configs[SHIP_MAP].map_name]. Никто не должен тебе мешать.</B>")

/datum/emergency_call/sw/senateguard/create_member(datum/mind/M)
	. = ..()
	if(!.)
		return
	var/mob/living/carbon/human/H = .
	finish_spawn(M, H)
	if(!leader)
		leader = H
	H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/senateguard))
	to_chat(H, "<p style='font-size:1.5em'>[span_notice("Ты Гвардеец Сената.")]</p>")

////////////////////////////////////////////////////////////////////////////////
// 8) Штурмовики времён Империи
////////////////////////////////////////////////////////////////////////////////

/datum/emergency_call/sw/stormtroopers
	name = "Imperial Stormtrooper Squad"
	base_probability = 8
	alignement_factor = 1 // VSD / hostile to TGMC
	mob_min = 10
	mob_max = 16
	var/airborne = 0
	var/max_airborne = 2
	var/radiomen = 0
	var/max_radiomen = 1

/datum/emergency_call/sw/stormtroopers/print_backstory(mob/living/carbon/human/H)
	to_chat(H, "<B>Вы служите Галактической Империи. Порядок будет поддерживаться. При необходимости силой.</B>")
	to_chat(H, "<B>Прибудьте на [SSmapping.configs[SHIP_MAP].map_name] и уничтожьте врагов Империи.</B>")

/datum/emergency_call/sw/stormtroopers/create_member(datum/mind/M)
	. = ..()
	if(!.)
		return
	var/mob/living/carbon/human/H = .
	finish_spawn(M, H)
	if(!leader)
		leader = H
		H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/stormtrooper/officer))
		to_chat(H, "<p style='font-size:1.5em'>[span_danger("Ты командир этого отряда. Да здравствует Империя!")]</p>")
		return
	if(medics < max_medics)
		H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/stormtrooper/surgeon))
		to_chat(H, "<p style='font-size:1.5em'>[span_danger("Ты полевой имперский медик.")]</p>")
		medics++
		return
	if(radiomen < max_radiomen)
		H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/stormtrooper/radio))
		to_chat(H, "<p style='font-size:1.5em'>[span_danger("Ты имперский инженер.")]</p>")
		radiomen++
		return
	if(airborne < max_airborne)
		H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/stormtrooper/airborne))
		to_chat(H, "<p style='font-size:1.5em'>[span_danger("Ты элитный имперский штурмовик.")]</p>")
		airborne++
		return
	H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/stormtrooper/standard))
	to_chat(H, span_danger("Ты имперский штурмовик."))

////////////////////////////////////////////////////////////////////////////////
// 9) Красная (Алая) Гвардия
////////////////////////////////////////////////////////////////////////////////

/datum/emergency_call/sw/redguard
	name = "Imperial Royal Guard Detachment"
	base_probability = 3
	alignement_factor = 1
	mob_min = 2
	mob_max = 6

/datum/emergency_call/sw/redguard/print_backstory(mob/living/carbon/human/H)
	to_chat(H, "<B>Ты - Алая Стража, багровая тень воли Императора.</B>")
	to_chat(H, "<B>Захвати VIP персон на [SSmapping.configs[SHIP_MAP].map_name] и эвакуируй их. Не оставляй свидетелей.</B>")

/datum/emergency_call/sw/redguard/create_member(datum/mind/M)
	. = ..()
	if(!.)
		return
	var/mob/living/carbon/human/H = .
	finish_spawn(M, H)
	if(!leader)
		leader = H
	H.apply_assigned_role_to_spawn(SSjob.GetJobType(/datum/job/sw/ert/redguard))
	to_chat(H, "<p style='font-size:1.5em'>[span_danger("Ты - член Алой Стражи.")]</p>")
