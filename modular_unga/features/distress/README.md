## Module ID: DISTRESS

Порт режима `Distress Signal` из `UngaTGMC`, адаптированный под текущую кодовую базу.

### Defines/Helpers:

- добавлен `ABILITY_DISTRESS` что ссылается на оффовский `ABILITY_NUCLEARWAR`

Добавлено:
- `code/datums/gamemodes/distress.dm`

### TG Proc/File Changes:

- `code/__DEFINES/actions.dm`
- `tgmc.dme`

Что изменено:
- добавлен gamemode `/datum/game_mode/infestation/distress`
- режим является портом Nuclear War без спавна ядерной бомбы
- режим подключён в сборку через `tgmc.dme`

### TGUI Files:

- N/A
