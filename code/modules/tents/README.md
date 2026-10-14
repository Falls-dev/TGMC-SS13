# Portable tents

Ported from cmss13-devs/cmss13 at commit
5419c94a5e10b0328ade2c861acaf8c9a4becda6:
https://github.com/cmss13-devs/cmss13/tree/5419c94a5e10b0328ade2c861acaf8c9a4becda6/code/modules/tents

Code and template layouts retain the upstream AGPL-3.0 license.
The seven `icons/obj/structures/tents_*.dmi` assets are credited to the
CM-SS13 development team and retain CC BY-SA 3.0:
https://creativecommons.org/licenses/by-sa/3.0/

TGMC adaptations: machinery paths, self-powered command intercoms in place of
CM telephones, local requisitions and medical vendors, a finite-stock ingredient
vendor, object integrity and damage, per-client roof visibility, map camouflage,
and TGMC surgery and thermal protection calculations. Medical tents reduce
surgery step time by 10%; tents add 0.7 cold protection, capped at 1. CM's surgery
pain modifier has no direct equivalent in TGMC and is not applied.

Spawn `/obj/item/folded_tent/cmd`, `/med`, `/reqs`, `/big`, or `/mess`.
Use the item in hand, choose offsets, and stand still for six seconds.
The entrance always faces south. A clear footprint on a ground level is required.
An unfolded shovel tears down a deployed tent in fifteen seconds. Fixed tent
equipment disappears with the tent; furniture and loose items remain.
