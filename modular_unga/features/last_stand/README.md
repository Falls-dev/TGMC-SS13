## Module ID: LAST_STAND

Порт режима `Last Stand` и его карты из `UngaTGMC`.

### Defines/Helpers:

- `code/__DEFINES/__game.dm`
- `code/__DEFINES/actions.dm`

Добавлено:
- `MAP_LAST_STAND`
- `ABILITY_LAST_STAND`

### TG Proc/File Changes:

- `code/datums/gamemodes/last_stand.dm`
- `code/datums/wave_spawner.dm`
- `code/_globalvars/lists/objects.dm`
- `code/game/objects/effects/landmarks/landmarks.dm`
- `tgmc.dme`

Что изменено:
- добавлен gamemode `/datum/game_mode/last_stand`
- добавлен `wave_spawner` для волн ксеноморфов
- добавлен landmark `last_stand_waves` для точек спавна волн
- режим использует обычные `/obj/machinery/nuclearbomb` через `GLOB.nuke_list`
- режим подключён в сборку через `tgmc.dme`

### Map Files:

- `_maps/last_stand.json`
- `_maps/map_files/Last_Stand/Last_Stand.dmm`

Что добавлено на карте:
- сама карта `Last Stand`
- точки волн `last_stand_waves`
- обычная `machinery`-нюка как цель защиты

### TGUI Files:

- N/A
