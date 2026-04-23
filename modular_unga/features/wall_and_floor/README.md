# Респрайт стен и полов

> [!WARNING]
>
> Сейчас модуль собран не полностью модульным способом:
> спрайты стен с инициатусов были перенесены в `modular_unga/features/wall_and_floor/icons/`, а для их использования были изменены оригинальные TG-файлы в `code/`.

### Defines

- Отдельных новых `defines` для самого модуля стен и полов не добавлялось.
- Модуль использует новый набор иконок из `modular_unga/features/wall_and_floor/icons/`.

### TGMC Proc/File Changes

Изменены следующие оригинальные файлы TGMC:

- `code/__DEFINES/xeno.dm`
- `code/datums/elements/turf_transparency.dm`
- `code/game/objects/effects/acid_hole.dm`
- `code/game/objects/effects/decals/turfdecals/warning_stripes.dm`
- `code/game/objects/effects/landmarks/landmarks.dm`
- `code/game/objects/effects/weeds.dm`
- `code/game/objects/structures/fence.dm`
- `code/game/objects/structures/girders.dm`
- `code/game/objects/structures/grille.dm`
- `code/game/objects/structures/window.dm`
- `code/game/objects/structures/window_frame.dm`
- `code/game/objects/structures/xeno.dm`
- `code/game/turfs/walls/r_wall.dm`
- `code/game/turfs/walls/resin.dm`
- `code/game/turfs/walls/wall_types.dm`
- `code/game/turfs/walls/walls.dm`
- `code/modules/mob/living/carbon/xenomorph/abilities.dm`
- `code/modules/xenomorph/acidwell.dm`
- `code/modules/xenomorph/spawner.dm`

### Added Asset Paths

В модуль добавлен новый пакет спрайтов по следующим путям:

- `modular_unga/features/wall_and_floor/icons/turf/`
- `modular_unga/features/wall_and_floor/icons/turf/floors/`
- `modular_unga/features/wall_and_floor/icons/turf/walls/`
- `modular_unga/features/wall_and_floor/icons/obj/smooth_objects/`
- `modular_unga/features/wall_and_floor/icons/Xeno/`

Внутри этих папок лежат респрайты для:

- стен и укреплённых стен;
- полов и напольных покрытий;
- окон, оконных рам, решёток и гирдеров;
- смузовых объектов вроде `acid-hole`, `warning_stripes`, `fence`, `weedwall`, `resin-wall`;
- части ксено-ассетов, связанных со смолой, стенами и визуалами улья.

### TGUI Files

- Изменений в `tgui/` для этого модуля не было.
