#include "code/xeno_mutations.dm"

#include "code/m_xenomorph.dm"
#include "code/xenomorph/m_life.dm"
#include "code/xenomorph/m_evolution.dm"
#include "code/xenomorph/m_hive_datum.dm"
#include "code/m_resinshaping.dm"
#include "code/m_atom_hud.dm"
#include "code/m_atom_movable.dm"
#include "code/m_round_statistic.dm"

#include "code/xenomorph/castes/defender/m_mutations_defender.dm"
#include "code/xenomorph/castes/drone/m_mutations_drone.dm"
#include "code/xenomorph/castes/runner/m_mutations_runner.dm"
#include "code/xenomorph/castes/sentinel/m_mutations_sentinel.dm"

#include "code/m_asset_list_items.dm"

#include "code/m_mobs_codex.dm"
#include "code/m_debuffs.dm"

/datum/modpack/z_example_modpack
	id = "z_example_modpack"
	icon = 'modular_unga/z_example_modpack/preview.dmi'
	name = "Название модпака"
	group = "Группа, в которой он будет"
	desc = "Ваше описание, только сильно много не пишите тут, а то вы"
	author = "К\*дер, что это все закодил/стащил"
