// the power monitoring computer
// for the moment, just report the status of all APCs in the same powernet
/obj/machinery/power/monitor
	name = "power monitoring computer"
	desc = "It monitors power levels across the station."
	icon = 'icons/obj/machines/computer.dmi'
	icon_state = "computer"
	//computer stuff
	density = TRUE
	anchored = TRUE
	circuit = /obj/item/circuitboard/computer/powermonitor
	use_power = IDLE_POWER_USE
	idle_power_usage = 300
	active_power_usage = 300
	interaction_flags = INTERACT_MACHINE_TGUI
	light_range = 1
	light_power = 0.5
	light_color = LIGHT_COLOR_EMISSIVE_YELLOW
	/// Screen overlay icon
	var/screen_overlay = "power"
	///Supply/demand history for the UI
	var/list/history = list()
	var/record_size = 60
	var/record_interval = 5 SECONDS
	var/next_record = 0

/obj/machinery/power/monitor/core
	name = "Core Power Monitoring"

/obj/machinery/power/monitor/grid
	name = "Main Power Grid Monitoring"

/obj/machinery/power/monitor/Initialize(mapload)
	. = ..()
	history["supply"] = list()
	history["demand"] = list()
	var/obj/structure/cable/attached = null
	var/turf/T = loc
	if(isturf(T))
		attached = locate() in T
	if(attached)
		powernet = attached.powernet
	update_icon()

/obj/machinery/power/monitor/process()
	if(powernet)
		record()

/obj/machinery/power/monitor/proc/record()
	if(world.time < next_record)
		return
	next_record = world.time + record_interval

	var/list/supply = history["supply"]
	supply += powernet ? powernet.avail : 0
	if(length(supply) > record_size)
		supply.Cut(1, 2)

	var/list/demand = history["demand"]
	demand += powernet ? powernet.viewload : 0
	if(length(demand) > record_size)
		demand.Cut(1, 2)

/obj/machinery/power/monitor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PowerMonitor", name)
		ui.open()

/obj/machinery/power/monitor/ui_data(mob/user)
	. = list()
	.["attached"] = !!powernet
	.["supply"] = powernet ? powernet.avail : 0
	.["demand"] = powernet ? powernet.viewload : 0
	.["supply_text"] = DisplayPower(powernet ? powernet.avail : 0)
	.["demand_text"] = DisplayPower(powernet ? powernet.viewload : 0)
	.["history"] = history

	var/list/areas = list()
	if(powernet)
		for(var/obj/machinery/power/terminal/term AS in powernet.nodes)
			var/obj/machinery/power/apc/apc = term.master
			if(!istype(apc))
				continue
			areas += list(list(
				"name" = "[apc.area]",
				"charge" = apc.cell ? round(apc.cell.percent()) : 0,
				"load" = DisplayPower(apc.lastused_total),
				"charging" = apc.charging,
				"eqp" = apc.equipment,
				"lgt" = apc.lighting,
				"env" = apc.environ,
			))
	.["areas"] = areas

/obj/machinery/power/monitor/update_icon()
	. = ..()
	if(machine_stat & (BROKEN|DISABLED|NOPOWER))
		set_light(0)
	else
		set_light(initial(light_range))

/obj/machinery/power/monitor/update_icon_state()
	. = ..()
	if(machine_stat & (BROKEN|DISABLED))
		icon_state = "[initial(icon_state)]_broken"
	else
		icon_state = initial(icon_state)

/obj/machinery/power/monitor/update_overlays()
	. = ..()
	if(!screen_overlay)
		return
	if(machine_stat & (BROKEN|DISABLED|NOPOWER))
		return
	. += emissive_appearance(icon, screen_overlay, src, alpha = src.alpha)
	. += mutable_appearance(icon, screen_overlay, alpha = src.alpha)

//copied from computer.dm
/obj/machinery/power/monitor/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(.)
		return
	return attack_hand(user)

/obj/machinery/power/monitor/screwdriver_act(mob/living/user, obj/item/I)
	. = ..()
	if(!circuit)
		return
	playsound(loc, 'sound/items/screwdriver.ogg', 25, 1)
	if(!do_after(user, 2 SECONDS, NONE, src, BUSY_ICON_BUILD))
		return

	var/obj/structure/computerframe/A = new(loc)
	var/obj/item/circuitboard/computer/M = new circuit(A)
	A.circuit = M
	A.anchored = TRUE
	for(var/obj/C in src)
		C.forceMove(loc)
	if(machine_stat & BROKEN)
		to_chat(user, span_notice("The broken glass falls out."))
		new /obj/item/shard(loc)
		A.state = 3
		A.icon_state = "3"
	else
		to_chat(user, span_notice("You disconnect the monitor."))
		A.state = 4
		A.icon_state = "4"
	M.deconstruct(src)
	qdel(src)
