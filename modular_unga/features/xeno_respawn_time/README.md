## Module ID: XENO_RESPAWN_TIME

Модуль добавляет отдельный таймер респавна для ксеноморфов.

Помимо самого таймера, модуль меняет связанную логику:
- проверку доступности респавна в ларву
- показ таймера в статус-панели
- запрет на мгновенный takeover SSD-ксенов до окончания xeno respawn timer
- отдельные значения таймера для разных режимов

### Defines/Helpers:

- `modular_unga/features/xeno_respawn_time/includes.dm`
- `code/__DEFINES/mode.dm`

Добавлено:
- `XENODEATHTIME_CHECK`
- `XENODEATHTIME_MESSAGE`

### TG Proc/File Changes:

- `code/datums/gamemodes/_game_mode.dm`
- `code/datums/gamemodes/crash.dm`
- `code/datums/gamemodes/last_stand.dm`
- `code/modules/mob/living/carbon/xenomorph/hive_datum.dm`
- `code/datums/actions/observer_action.dm`
- `code/modules/mob/dead/observer/observer.dm`
- `code/_globalvars/misc.dm`
- `code/modules/mob/new_player/new_player.dm`
- `code/modules/mob/living/death.dm`
- `code/modules/mob/living/living.dm`
- `code/game/objects/machinery/cryopod.dm`
- `code/modules/shuttle/shuttle.dm`
- `code/modules/mob/living/carbon/xenomorph/castes/hivemind/hivemind.dm`

Что изменено:
- в базовом gamemode добавлен `var/xenorespawn_time`
- в статус-панели показывается `Xeno respawn timer`
- в `Crash` установлен xeno respawn timer `2 MINUTES`
- в `Last Stand` установлен xeno respawn timer `1 MINUTES`
- очередь ларв учитывает xeno respawn timer перед выдачей новой ларвы
- takeover SSD xeno и offered xeno проверяют таймер перед передачей моба
- время смерти берётся из `GLOB.key_to_time_of_role_death`

### TGUI Files:

- N/A
