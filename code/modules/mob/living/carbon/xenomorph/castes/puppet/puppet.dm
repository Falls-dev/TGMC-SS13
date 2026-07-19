/mob/living/carbon/xenomorph/puppet
	caste_base_type = /datum/xeno_caste/puppet
	name = "Puppet"
	desc = "A reanimated body, crudely pieced together and held in place by an ominous energy tethered to some unknown force."
	icon = 'icons/Xeno/castes/puppet.dmi'
	icon_state = "Puppet Running"
	health = 225
	maxHealth = 225
	plasma_stored = 0
	pixel_x = 0
	tier = XENO_TIER_MINION
	upgrade = XENO_UPGRADE_BASETYPE
	pull_speed = -1
	allow_pass_flags = PASS_XENO
	pass_flags = PASS_XENO
	voice_filter = @{"[0:a] asplit [out0][out2]; [out0] asetrate=%SAMPLE_RATE%*0.9,aresample=%SAMPLE_RATE%,atempo=1/0.9,aformat=channel_layouts=mono,volume=0.2 [p0]; [out2] asetrate=%SAMPLE_RATE%*1.1,aresample=%SAMPLE_RATE%,atempo=1/1.1,aformat=channel_layouts=mono,volume=0.2[p2]; [p0][0][p2] amix=inputs=3"}
	///our master
	var/mob/living/carbon/xenomorph/master_puppeter

/mob/living/carbon/xenomorph/puppet/handle_special_state() //prevent us from using different run/walk sprites
	icon_state = "[xeno_caste.caste_name] Running"
	return TRUE

/mob/living/carbon/xenomorph/puppet/Initialize(mapload, mob/living/carbon/xenomorph/mother)
	. = ..()
	master_puppeter = mother
	if(master_puppeter)
		AddComponent(/datum/component/ai_controller, /datum/ai_behavior/puppet, master_puppeter)
		transfer_to_hive(master_puppeter.get_xeno_hivenumber())
	else
		AddComponent(/datum/component/ai_controller, /datum/ai_behavior/xeno)

/mob/living/carbon/xenomorph/puppet/on_death()
	. = ..()
	if(!QDELETED(src))
		gib()

/mob/living/carbon/xenomorph/puppet/Life(seconds_per_tick, times_fired)
	. = ..()
	if(!master_puppeter)
		return
	if(get_dist(src, master_puppeter) > PUPPET_WITHER_RANGE)
		adjust_brute_loss(100)

/mob/living/carbon/xenomorph/puppet/med_hud_set_status()
	. = ..()
	hud_set_blessings()

/mob/living/carbon/xenomorph/puppet/proc/hud_set_blessings()
	var/image/holder = hud_list[XENO_BLESSING_HUD]
	if(!holder)
		return
	for(var/datum/status_effect/effect AS in status_effects)
		if(istype(effect, /datum/status_effect/blessing))
			holder.overlays += image('icons/mob/hud/xeno_misc.dmi', icon_state = initial(effect.id))
