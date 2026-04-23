## Module ID: DISTRESS

Порт режима `Distress Signal` из `UngaTGMC`, адаптированный под текущую кодовую базу.

### Defines/Helpers:

- `code/__DEFINES/actions.dm`

Добавлено:
- `ABILITY_DISTRESS`

### TG Proc/File Changes:

- `code/datums/gamemodes/distress.dm`
- `tgmc.dme`

Что изменено:
- добавлен gamemode `/datum/game_mode/infestation/distress`
- режим использует локальные job paths и доступные mode flags этого форка
- стартовые `psy points` выданы через `add_strategic_psy_points` и `add_tactical_psy_points`
- дистресс работает как отдельный infestation-вариант без собственного спавна ядерной бомбы
- режим подключён в сборку через `tgmc.dme`

### TGUI Files:

- N/A
