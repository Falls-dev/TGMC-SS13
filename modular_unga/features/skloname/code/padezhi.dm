////////////////////////////////////////////////////////////////////////////////
//
//
// Этот код написан демонами в подвале и куском валтоса.
// Если собираетесь копипастить это, то рекомендуется ничего здесь не трогать или оно сломается нахуй.
// Я предупредил.
//
//
////////////////////////////////////////////////////////////////////////////////

ADMIN_VERB(test_name_sklonenie, R_DEBUG, "Test Name Sklonenie", "Введите слово для склонения", ADMIN_CATEGORY_DEBUG, pizdos as text)
	if(pizdos)
		to_chat(src, "Начальное слово: [pizdos]")

		to_chat(src, "Ж. Родительный: [skloname(pizdos, RODITELNI, 	"female")]")
		to_chat(src, "Ж. Дательный: [skloname(pizdos,   DATELNI, 		"female")]")
		to_chat(src, "Ж. Винительный: [skloname(pizdos, VINITELNI, 	"female")]")
		to_chat(src, "Ж. Творительный: [skloname(pizdos,TVORITELNI, 	"female")]")
		to_chat(src, "Ж. Предложный: [skloname(pizdos,  PREDLOZHNI, 	"female")]")

		to_chat(src, "М. Родительный: [skloname(pizdos, RODITELNI, 	"male")]")
		to_chat(src, "М. Дательный: [skloname(pizdos, 	 DATELNI, 		"male")]")
		to_chat(src, "М. Винительный: [skloname(pizdos, VINITELNI, 	"male")]")
		to_chat(src, "М. Творительный: [skloname(pizdos,TVORITELNI, 	"male")]")
		to_chat(src, "М. Предложный: [skloname(pizdos,  PREDLOZHNI, 	"male")]")

		to_chat(src, "С. Родительный: [skloname(pizdos, RODITELNI)]")
		to_chat(src, "С. Дательный: [skloname(pizdos,   DATELNI)]")
		to_chat(src, "С. Винительный: [skloname(pizdos, VINITELNI)]")
		to_chat(src, "С. Творительный: [skloname(pizdos,TVORITELNI)]")
		to_chat(src, "С. Предложный: [skloname(pizdos,  PREDLOZHNI)]")
	else
		return

// Кусок выше - это тестовый админский верб для проверки склонения слов
// Проки для склонения лежат в "modular_unga\_helpers\_main_modular_helpers_include.dm"
// Дефайны для склонения лежат в "modular_unga\_defines\_main_modular_defines_include.dm"
