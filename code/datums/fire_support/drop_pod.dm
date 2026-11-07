/datum/fire_support/droppod/New()
	. = ..()
	disable_pods()

/datum/fire_support/droppod/proc/enable_pods(datum/source)
	SIGNAL_HANDLER
	RegisterSignal(SSdcs, COMSIG_GLOB_CAMPAIGN_MISSION_ENDED, PROC_REF(disable_pods))
	UnregisterSignal(SSdcs, COMSIG_GLOB_CAMPAIGN_ENABLE_DROPPODS)
	enable_firesupport(-1) //pods can be used separately, restocked, emptied, etc. select_target will check if there's actually a pod available.

///Disabled the datum from use
/datum/fire_support/droppod/proc/disable_pods(datum/source)
	SIGNAL_HANDLER
	RegisterSignal(SSdcs, COMSIG_GLOB_CAMPAIGN_ENABLE_DROPPODS, PROC_REF(enable_pods))
	UnregisterSignal(SSdcs, COMSIG_GLOB_CAMPAIGN_MISSION_ENDED)
	disable(TRUE)

