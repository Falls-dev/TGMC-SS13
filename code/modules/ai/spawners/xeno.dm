/obj/effect/ai_node/spawner/xeno
	name = "Xeno AI spawner"

//////Generic xeno spawners
////////Tier ones

/obj/effect/ai_node/spawner/xeno/runnergang	// RUNNNER GANG RUNNER GANG
	spawn_types = list(/mob/living/carbon/xenomorph/runner/ai)
	spawn_amount = 4
	spawn_delay = 10 SECONDS
	max_amount = 10

/obj/effect/ai_node/spawner/xeno/defender
	spawn_types = list(/mob/living/carbon/xenomorph/defender/ai)
	spawn_amount = 4
	spawn_delay = 10 SECONDS
	max_amount = 10

/obj/effect/ai_node/spawner/xeno/sentinel
	spawn_types = list(/mob/living/carbon/xenomorph/sentinel/ai)
	spawn_amount = 4
	spawn_delay = 10 SECONDS
	max_amount = 10

/obj/effect/ai_node/spawner/xeno/drone
	spawn_types = list(/mob/living/carbon/xenomorph/drone/ai)
	spawn_amount = 4
	spawn_delay = 10 SECONDS
	max_amount = 10

/obj/effect/ai_node/spawner/xeno/tierones
	spawn_types = list(/mob/living/carbon/xenomorph/runner/ai, /mob/living/carbon/xenomorph/sentinel/ai, /mob/living/carbon/xenomorph/defender/ai, /mob/living/carbon/xenomorph/drone/ai)
	spawn_amount = 4
	spawn_delay = 10 SECONDS
	max_amount = 10

/////////////Tier twos

/obj/effect/ai_node/spawner/xeno/spitter
	spawn_types = list(/mob/living/carbon/xenomorph/spitter/ai)
	spawn_amount = 4
	spawn_delay = 10 SECONDS
	max_amount = 10

/obj/effect/ai_node/spawner/xeno/warrior
	spawn_types = list(/mob/living/carbon/xenomorph/warrior/ai)
	spawn_amount = 4
	spawn_delay = 10 SECONDS
	max_amount = 10

/obj/effect/ai_node/spawner/xeno/hivelord
	spawn_types = list(/mob/living/carbon/xenomorph/hivelord/ai)
	spawn_amount = 4
	spawn_delay = 10 SECONDS
	max_amount = 10

/obj/effect/ai_node/spawner/xeno/hunter
	spawn_types = list(/mob/living/carbon/xenomorph/hunter/ai)
	spawn_amount = 4
	spawn_delay = 10 SECONDS
	max_amount = 10

/obj/effect/ai_node/spawner/xeno/tiertwos
	spawn_types = list(/mob/living/carbon/xenomorph/hunter/ai =33, /mob/living/carbon/xenomorph/warrior/ai =33, /mob/living/carbon/xenomorph/spitter/ai =33)
	spawn_amount = 4
	spawn_delay = 10 SECONDS
	max_amount = 10

////////////////////Tier 3s

/obj/effect/ai_node/spawner/xeno/ravager
	spawn_types = list(/mob/living/carbon/xenomorph/ravager/ai)
	spawn_amount = 4
	spawn_delay = 10 SECONDS
	max_amount = 10

/obj/effect/ai_node/spawner/xeno/boiler
	spawn_types = list(/mob/living/carbon/xenomorph/boiler/ai)
	spawn_amount = 4
	spawn_delay = 10 SECONDS
	max_amount = 10

/obj/effect/ai_node/spawner/xeno/praetorian
	spawn_types = list(/mob/living/carbon/xenomorph/praetorian/ai)
	spawn_amount = 4
	spawn_delay = 10 SECONDS
	max_amount = 10

/obj/effect/ai_node/spawner/xeno/crusher
	spawn_types = list(/mob/living/carbon/xenomorph/crusher/ai)
	spawn_amount = 4
	spawn_delay = 10 SECONDS
	max_amount = 10


/obj/effect/ai_node/spawner/xeno/tierthrees
	spawn_types = list(/mob/living/carbon/xenomorph/crusher/ai =1, /mob/living/carbon/xenomorph/praetorian/ai =1, /mob/living/carbon/xenomorph/boiler/ai =1, /mob/living/carbon/xenomorph/ravager/ai =1)
	spawn_amount = 4
	spawn_delay = 10 SECONDS
	max_amount = 10

/////////////Tier 4s

/obj/effect/ai_node/spawner/xeno/queen
	spawn_types = list(/mob/living/carbon/xenomorph/queen/ai)
	spawn_amount = 4
	spawn_delay = 10 SECONDS
	max_amount = 10
