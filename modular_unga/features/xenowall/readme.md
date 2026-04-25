## Module ID: XENOWALL

Порт построек и визуала ксеностен из `UngaTGMC`.
Модуль добавляет к строительству ксенов гнёзда и специальные resin wall-варианты:
`bulletproof`, `fireproof` и `hardy`.

Отдельных `meleeproof` и `bombproof` стен в исходном переносе не было:
их роль выполняет `hardy resin wall`, которая даёт защиту от мили и взрывов.

### Defines/Helpers:

- `code/__DEFINES/xeno.dm`

Добавлено:
- define `ALIEN_NEST`
- `advanced_resin_images_list` для radial-menu строительства

### TG Proc/File Changes:

- `code/game/turfs/walls/resin.dm`
- `code/modules/mob/living/carbon/xenomorph/abilities.dm`
- `code/modules/mob/living/carbon/xenomorph/castes/hivelord/abilities_hivelord.dm`
- `code/modules/mob/living/carbon/xenomorph/castes/hivemind/abilities_hivemind.dm`

Что изменено:
- special resin walls переведены на модульные спрайты и описания
- `Secrete Resin` умеет показывать расширенный набор построек для нужных каст
- добавлена стоимость строительства `alien nest`
- добавлены проверки, чтобы `alien nest` и resin doors нельзя было строить слишком близко друг к другу
- `hivelord` получил `bulletproof`, `fireproof`, `hardy`, `sticky resin`, `thick resin door` и `alien nest`
- `hivemind` получил `bulletproof`, `fireproof`, `hardy`, `sticky resin`, `resin door` и `alien nest`

### Modular Assets:

- `modular_unga/features/wall_and_floor/icons/obj/smooth_objects/resin-wall-bullet.dmi`
- `modular_unga/features/wall_and_floor/icons/obj/smooth_objects/resin-wall-fire.dmi`
- `modular_unga/features/wall_and_floor/icons/obj/smooth_objects/resin-wall-hardy.dmi`
- `modular_unga/features/wall_and_floor/icons/Xeno/actions/construction.dmi`

### TGUI Files:

- N/A
