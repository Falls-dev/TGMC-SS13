/obj/machinery/computer/operating
	name = "Operating Computer"
	anchored = TRUE
	density = TRUE
	icon_state = "computer_small"
	screen_overlay = "operating"
	circuit = /obj/item/circuitboard/computer/operating
	interaction_flags = INTERACT_MACHINE_TGUI
	var/mob/living/carbon/human/victim = null
	var/obj/machinery/optable/table = null

/obj/machinery/computer/operating/Initialize(mapload)
	. = ..()
	for(dir in list(NORTH,EAST,SOUTH,WEST))
		table = locate(/obj/machinery/optable, get_step(src, dir))
		if (table)
			table.computer = src
			break

/obj/machinery/computer/operating/Destroy()
	table = null
	return ..()

/obj/machinery/computer/operating/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "OperatingComputer", name)
		ui.open()

/obj/machinery/computer/operating/ui_data(mob/user)
	. = list()
	.["hasTable"] = !!table

	if(table?.check_victim())
		victim = table.victim
		if(ishuman(victim))
			var/mob/living/carbon/human/H = victim
			.["patient"] = list(
				"name" = H.real_name,
				"age" = H.age,
				"blood_type" = H.blood_type,
				"health" = H.health,
				"maxHealth" = H.maxHealth,
				"bruteLoss" = H.get_brute_loss(),
				"toxLoss" = H.get_tox_loss(),
				"fireLoss" = H.get_fire_loss(),
				"oxyLoss" = H.get_oxy_loss(),
				"stat" = H.stat,
				"pulse" = H.get_pulse(GETPULSE_TOOL),
			)
			return

	victim = null
	.["patient"] = null

/obj/machinery/computer/operating/valhalla
	use_power = NO_POWER_USE
