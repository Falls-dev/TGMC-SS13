// Все новые модули включены здесь
// Некоторые модули можно легко исключить из последовательности компиляции кода, закомментировав строку которая начинается с #define
// Которую необходимо удалить в файле code\__DEFINES\__unga_modpaks_includes.dm
// Имейте в виду, что модуль может находиться не только в папке modular, но и быть встроен непосредственно в код TGMC и покрыт структурой #ifdef - #endif

#include "__modpack\assets_modpacks.dm"
#include "__modpack\modpack.dm" //modpack obj
#include "__modpack\modpacks_subsystem.dm" //actually mods subsystem + tgui in "tgui/packages/tgui/interfaces/Modpacks.tsx"

/* --FEATURES-- */
#include "features\skloname\includes.dm"
#include "features\wall_and_floor\includes.dm"
#include "features\xenowall\includes.dm"
#include "features\distress\includes.dm"
#include "features\last_stand\includes.dm"
#include "features\auto_upstream\includes.dm"
#include "features\shoulder\includes.dm"
#include "features\unga_guns\includes.dm"
#include "features\xeno_respawn_time\includes.dm"
#include "features\Powerback\includes.dm"

/* -- REVERTS -- */
#include "reverts\allow_tadpole_construct\includes.dm"
#include "reverts\no_tutorial\includes.dm"

/* --TRANSLATIONS-- */
#include "ru_translate\ru_announce\includes.dm"
#include "ru_translate\ru_maps\includes.dm"
