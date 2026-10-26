/area
	level = null
	name = "Unknown"
	icon = 'icons/turf/areas.dmi'
	icon_state = "unknown"
	layer = AREA_LAYER
	plane = AREA_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	invisibility = INVISIBILITY_LIGHTING
	minimap_color = null

	/// List of all turfs currently inside this area as nested lists indexed by zlevel.
	/// Acts as a filtered version of area.contents For faster lookup
	/// (area.contents is actually a filtered loop over world)
	/// Semi fragile, but it prevents stupid so I think it's worth it
	var/list/list/turf/turfs_by_zlevel = list() // TODO someone needs to go through and check that this is being used properly when it shoudld be

	/// turfs_by_z_level can hold MASSIVE lists, so rather then adding/removing from it each time we have a problem turf
	/// We should instead store a list of turfs to REMOVE from it, then hook into a getter for it
	/// There is a risk of this and contained_turfs leaking, so a subsystem will run it down to 0 incrementally if it gets too large
	/// This uses the same nested list format as turfs_by_zlevel
	var/list/list/turf/turfs_to_uncontain_by_zlevel = list()

	///Does the area has fire alarm?
	var/fire_alarm = FALSE

	var/unique = TRUE

	var/requires_power = TRUE
	var/always_unpowered = FALSE

	var/power_equip = TRUE
	var/power_light = TRUE
	var/power_environ = TRUE

	var/used_equip = FALSE
	var/used_light = FALSE
	var/used_environ = FALSE

	var/global/global_uid = 0
	var/uid

	var/atmos = TRUE
	var/atmosalm = FALSE
	var/poweralm = TRUE
	var/lightswitch = TRUE

	var/temperature = T20C

	var/parallax_movedir = 0

	///the material the ceiling is made of. Used for debris from airstrikes and orbital beacons in ceiling_debris()
	var/ceiling = CEILING_NONE
	///Used in designating the "level" of maps pretending to be multi-z one Z
	var/fake_zlevel
	///Is this area considered inside or outside
	var/outside = TRUE

	var/area_flags = NONE
	///Cameras in this area
	var/list/cameras
	var/list/ambience = list('sound/ambience/ambigen1.ogg', 'sound/ambience/ambigen3.ogg', 'sound/ambience/ambigen4.ogg', \
		'sound/ambience/ambigen5.ogg', 'sound/ambience/ambigen6.ogg', 'sound/ambience/ambigen7.ogg', 'sound/ambience/ambigen8.ogg',\
		'sound/ambience/ambigen9.ogg', 'sound/ambience/ambigen10.ogg', 'sound/ambience/ambigen11.ogg', 'sound/ambience/ambigen12.ogg',\
		'sound/ambience/ambigen14.ogg', 'sound/ambience/ambiatmos.ogg', 'sound/ambience/ambiatmos2.ogg')
	///Used to decide what the minimum time between ambience is
	var/min_ambience_cooldown = 40 SECONDS
	///Used to decide what the maximum time between ambience is
	var/max_ambience_cooldown = 120 SECONDS

	///Boolean to limit the areas (subtypes included) that atoms in this area can smooth with. Used for shuttles.
	var/area_limited_icon_smoothing = FALSE

/area/New()
	// This interacts with the map loader, so it needs to be set immediately
	// rather than waiting for atoms to initialize.
	if(unique)
		GLOB.areas_by_type[type] = src
	GLOB.areas += src
	return ..()

/area/Initialize(mapload, ...)
	icon_state = "" //Used to reset the icon overlay, I assume.
	uid = ++global_uid

	if(requires_power)
		luminosity = 0
	else
		power_light = TRUE
		power_equip = TRUE
		power_environ = TRUE

	. = ..()

	if(!static_lighting)
		blend_mode = BLEND_MULTIPLY
	reg_in_areas_in_z()
	update_base_lighting()
	return INITIALIZE_HINT_LATELOAD

/area/LateInitialize()
	power_change()		// all machines set to current power level, also updates icon

/area/Destroy() // todo this doesnt clean up everything it should
	if(GLOB.areas_by_type[type] == src)
		GLOB.areas_by_type[type] = null
	//this is not initialized until get_sorted_areas() is called so we have to do a null check
	if(!isnull(GLOB.sorted_areas))
		GLOB.sorted_areas -= src
	//just for sanity sake cause why not
	if(!isnull(GLOB.areas))
		GLOB.areas -= src
	STOP_PROCESSING(SSobj, src)
	//turf cleanup
	turfs_by_zlevel = null
	turfs_to_uncontain_by_zlevel = null
	return ..()

/area/Entered(atom/movable/arrived, atom/old_loc)
	set waitfor = FALSE
	SEND_SIGNAL(src, COMSIG_AREA_ENTERED, arrived, old_loc)
	SEND_SIGNAL(arrived, COMSIG_ENTER_AREA, src, old_loc,) //The atom that enters the area

/area/Exited(atom/movable/leaver, direction)
	SEND_SIGNAL(src, COMSIG_AREA_EXITED, leaver, direction)
	SEND_SIGNAL(leaver, COMSIG_EXIT_AREA, src, direction) //The atom that exits the area

/// Returns the highest zlevel that this area contains turfs for
/area/proc/get_highest_zlevel()
	for(var/area_zlevel in length(turfs_by_zlevel) to 1 step -1)
		if(length(turfs_to_uncontain_by_zlevel) >= area_zlevel)
			if(length(turfs_by_zlevel[area_zlevel]) - length(turfs_to_uncontain_by_zlevel[area_zlevel]) > 0)
				return area_zlevel
		else
			if(length(turfs_by_zlevel[area_zlevel]))
				return area_zlevel
	return 0

/// Returns a nested list of lists with all turfs split by zlevel.
/// only zlevels with turfs are returned. The order of the list is not guaranteed.
/area/proc/get_zlevel_turf_lists()
	if(length(turfs_to_uncontain_by_zlevel))
		cannonize_contained_turfs()

	var/list/zlevel_turf_lists = list()

	for(var/list/zlevel_turfs as anything in turfs_by_zlevel)
		if(length(zlevel_turfs))
			zlevel_turf_lists += list(zlevel_turfs)

	return zlevel_turf_lists

/// Returns a list with all turfs in this zlevel.
/area/proc/get_turfs_by_zlevel(zlevel)
	if(length(turfs_to_uncontain_by_zlevel) >= zlevel && length(turfs_to_uncontain_by_zlevel[zlevel]))
		cannonize_contained_turfs_by_zlevel(zlevel)

	if(length(turfs_by_zlevel) < zlevel)
		return list()

	return turfs_by_zlevel[zlevel]

/// Merges a list containing all of the turfs zlevel lists from get_zlevel_turf_lists inside one list. Use get_zlevel_turf_lists() or get_turfs_by_zlevel() unless you need all the turfs in one list to avoid generating large lists
/area/proc/get_turfs_from_all_zlevels()
	. = list()
	for (var/list/zlevel_turfs as anything in get_zlevel_turf_lists())
		. += zlevel_turfs

/// Ensures that the contained_turfs list properly represents the turfs actually inside us
/area/proc/cannonize_contained_turfs_by_zlevel(zlevel_to_clean, _autoclean = TRUE)
	// This is massively suboptimal for LARGE removal lists
	// Try and keep the mass removal as low as you can. We'll do this by ensuring
	// We only actually add to contained turfs after large changes (Also the management subsystem)
	// Do your damndest to keep turfs out of /area/space as a stepping stone
	// That sucker gets HUGE and will make this take actual seconds
	if(zlevel_to_clean <= length(turfs_by_zlevel) && zlevel_to_clean <= length(turfs_to_uncontain_by_zlevel))
		turfs_by_zlevel[zlevel_to_clean] -= turfs_to_uncontain_by_zlevel[zlevel_to_clean]

	if(!_autoclean) // Removes empty lists from the end of this list
		turfs_to_uncontain_by_zlevel[zlevel_to_clean] = list()
		return

	var/new_length = length(turfs_to_uncontain_by_zlevel)
	// Walk backwards thru the list
	for (var/i in length(turfs_to_uncontain_by_zlevel) to 0 step -1)
		if (i && length(turfs_to_uncontain_by_zlevel[i]))
			break // Stop the moment we find a useful list
		new_length = i

	if (new_length < length(turfs_to_uncontain_by_zlevel))
		turfs_to_uncontain_by_zlevel.len = new_length

	if (new_length >= zlevel_to_clean)
		turfs_to_uncontain_by_zlevel[zlevel_to_clean] = list()

/// Ensures that the contained_turfs list properly represents the turfs actually inside us
/area/proc/cannonize_contained_turfs()
	for(var/area_zlevel in 1 to length(turfs_to_uncontain_by_zlevel))
		cannonize_contained_turfs_by_zlevel(area_zlevel, _autoclean = FALSE)

	turfs_to_uncontain_by_zlevel = list()

/// Returns TRUE if we have contained turfs, FALSE otherwise
/area/proc/has_contained_turfs()
	for(var/area_zlevel in 1 to length(turfs_by_zlevel))
		if(length(turfs_to_uncontain_by_zlevel) >= area_zlevel)
			if(length(turfs_by_zlevel[area_zlevel]) - length(turfs_to_uncontain_by_zlevel[area_zlevel]) > 0)
				return TRUE
		else
			if(length(turfs_by_zlevel[area_zlevel]))
				return TRUE
	return FALSE

/**
 * Register this area as belonging to a z level
 *
 * Ensures the item is added to the SSmapping.areas_in_z list for this z
 */
/area/proc/reg_in_areas_in_z()
	if(!has_contained_turfs())
		return
	var/list/areas_in_z = SSmapping.areas_in_z
	if(!z)
		WARNING("No z found for [src]")
		return
	if(!areas_in_z["[z]"])
		areas_in_z["[z]"] = list()
	areas_in_z["[z]"] |= src

// A hook so areas can modify the incoming args
/area/proc/PlaceOnTopReact(list/new_baseturfs, turf/fake_turf_type, flags)
	return flags

/area/proc/power_alert(state, obj/source)
	if(state == poweralm)
		return

	poweralm = state

	for(var/obj/machinery/computer/station_alert/alert_computer as anything in GLOB.alert_consoles)
		if(alert_computer.z != source.z)
			continue
		if(state == 1)
			alert_computer.cancelAlarm("Power", src, source)
		else
			alert_computer.triggerAlarm("Power", src, null, source)

/area/proc/fire_alert()
	if(name == "Space") //no fire alarms in space
		return
	if(fire_alarm)
		return
	fire_alarm = TRUE
	var/list/cameras = list() // what does it even do?
	for(var/obj/machinery/computer/station_alert/alert_computer as anything in GLOB.alert_consoles)
		alert_computer.triggerAlarm("Fire", src, cameras, src)
	SEND_SIGNAL(src, COMSIG_AREA_FIRE_ALARM_SET, TRUE)

/area/proc/fire_reset()
	if(!fire_alarm)
		return
	fire_alarm = FALSE

	for(var/obj/machinery/computer/station_alert/alert_computer as anything in GLOB.alert_consoles)
		alert_computer.cancelAlarm("Fire", src, src)
	SEND_SIGNAL(src, COMSIG_AREA_FIRE_ALARM_SET, FALSE)

/area/proc/powered(chan)
	if(!requires_power)
		return TRUE

	if(always_unpowered)
		return FALSE

	switch(chan)
		if(EQUIP)
			return power_equip
		if(LIGHT)
			return power_light
		if(ENVIRON)
			return power_environ
	return FALSE

/area/proc/power_change()
	for(var/obj/machinery/M in src)
		M.power_change()
	update_icon()

/area/proc/usage(chan)
	var/used = 0
	switch(chan)
		if(LIGHT)
			used += used_light
		if(EQUIP)
			used += used_equip
		if(ENVIRON)
			used += used_environ
		if(TOTAL)
			used += used_light + used_equip + used_environ
	return used

/area/proc/clear_usage()
	used_equip = 0
	used_light = 0
	used_environ = 0

/area/proc/use_power(amount, chan)
	switch(chan)
		if(EQUIP)
			used_equip += amount
		if(LIGHT)
			used_light += amount
		if(ENVIRON)
			used_environ += amount

// Map-local climate and ambience: inherit gameplay properties from the original area.

/area/bigredv2/caves/east/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/caves/east/garbledradio/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/caves/lambda_lab/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/caves/north/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/caves/northeast/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/caves/northeast/garbledradio/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/caves/northwest/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/caves/rock/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/caves/south/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/caves/south/garbledradio/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/caves/southeast/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/caves/southeast/garbledradio/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/caves/southwest/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/caves/west/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/bar/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/c/theme_bigred_v2
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/bigredv2/outside/cargo/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/dorms/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/e/theme_bigred_v2
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/bigredv2/outside/engineering/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/filtration_plant/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/general_offices/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/hydroponics/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/marshal_office/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/n/theme_bigred_v2
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/bigredv2/outside/nanotrasen_lab/inside/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/nanotrasen_lab/inside/garbledradio/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/ne/theme_bigred_v2
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/bigredv2/outside/nw/theme_bigred_v2
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/bigredv2/outside/office_complex/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/s/theme_bigred_v2
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/bigredv2/outside/se/theme_bigred_v2
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/bigredv2/outside/space_port/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/space_port/two/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/sw/theme_bigred_v2
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/bigredv2/outside/telecomm/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/virology/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/w/theme_bigred_v2
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/lv624/lazarus/console/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/storage/testroom/theme_bigred_v2
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/template_noop/theme_bigred_v2
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/barren/theme_barrenquilla_mining_facility
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/barren/cave/central/theme_barrenquilla_mining_facility
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/barren/cave/east/theme_barrenquilla_mining_facility
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/barren/cave/lz1/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/cave/lz2/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/cave/north/theme_barrenquilla_mining_facility
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/barren/cave/northeast/theme_barrenquilla_mining_facility
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/barren/cave/northwest/theme_barrenquilla_mining_facility
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/barren/cave/west/theme_barrenquilla_mining_facility
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/barren/caves/rock/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/caves/south/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/caves/southeast/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/caves/southwest/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/civilian/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/civilian/botany/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/civilian/cook/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/civilian/laundry/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/civilian/workdorm/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/engie/engine/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/engie/three/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/engie/two/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/medical/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/medical/chemistry/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/medical/research/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/misc/ashshelter/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/misc/eastarmory/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/misc/genstorage/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/misc/refinery/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/misc/ruin/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/security/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/barren/security/nuke/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/general_offices/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/console/theme_barrenquilla_mining_facility
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/template_noop/theme_barrenquilla_mining_facility
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/ice_colony/exterior/surface/clearing/north/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/ice_colony/exterior/surface/clearing/pass/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/ice_colony/exterior/surface/clearing/south/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/ice_colony/exterior/surface/container_yard/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/ice_colony/exterior/surface/landing_pad/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/exterior/surface/landing_pad2/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/exterior/surface/taxiway/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/ice_colony/exterior/surface/valley/north/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/ice_colony/exterior/surface/valley/northeast/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/ice_colony/exterior/surface/valley/northwest/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/ice_colony/exterior/surface/valley/south/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/ice_colony/exterior/surface/valley/south/excavation/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/ice_colony/exterior/surface/valley/southeast/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/ice_colony/exterior/surface/valley/southwest/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/ice_colony/exterior/surface/valley/west/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/ice_colony/exterior/underground/caves/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/exterior/underground/caves/ice_nw/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/exterior/underground/caves/ice_se/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/exterior/underground/caves/ice_w/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/exterior/underground/caves/open/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/exterior/underground/caves/open/garbledradio/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/exterior/underground/caves/rock/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/bar/bar/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/bar/canteen/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/clinic/lobby/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/clinic/storage/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/clinic/treatment/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/command/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/disposals/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/dorms/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/dorms/canteen/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/dorms/lavatory/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/dorms/restroom_e/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/dorms/restroom_w/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/engineering/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/engineering/generator/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/engineering/tool/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/excavation/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/excavation/storage/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/excavationbarracks/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/garage/one/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/garage/repair/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/garage/three/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/garage/two/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/hangar/alpha/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/hangar/beta/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/hangar/checkpoint/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/hangar/hallway/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/hydroponics/lobby/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/hydroponics/north/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/hydroponics/south/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/mining/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/research/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/research/field_gear/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/research/tech_storage/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/research/temporary/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/storage_unit/power/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/storage_unit/research/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/storage_unit/telecomms/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/substation/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/surface/substation/smes/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/command/center/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/command/checkpoint/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/command/pv1/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/command/pv2/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/crew/bball/garbledradio/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/crew/canteen/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/crew/chapel/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/crew/disposals/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/crew/dorm_l/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/crew/dorm_r/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/crew/lavatory/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/crew/leisure/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/crew/library/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/crew/morgue/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/engineering/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/engineering/substation/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/hallway/north_west/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/hallway/north_west/garbledradio/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/hallway/south_east/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/hallway/south_east/garbledradio/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/hangar/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/maintenance/central/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/maintenance/east/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/maintenance/engineering/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/maintenance/engineering/garbledradio/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/maintenance/north/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/maintenance/south/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/medical/hallway/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/medical/hallway/garbledradio/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/medical/lobby/garbledradio/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/medical/storage/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/medical/treatment/garbledradio/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/reception/checkpoint_north/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/requesition/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/requesition/lobby/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/requesition/sec_storage/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/requesition/storage/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/responsehangar/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/security/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/security/armory/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/security/backroom/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/security/brig/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/security/detective/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/security/hallway/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/security/interrogation/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/security/marshal/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/storage/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/storage/highsec/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/ice_colony/underground/westroadtunnel/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/console/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/space/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/storage/testroom/theme_ice_colony_v2
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/lv624/ground/caves/central1/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/caves/central1/garbledradio/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/caves/central2/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/caves/central3/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/caves/central3/garbledradio/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/caves/central4/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/caves/central4/garbledradio/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/caves/central5/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/caves/central5/garbledradio/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/caves/east1/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/caves/east1/garbledradio/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/caves/rock/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/caves/west1/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/compound/c/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/compound/n/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/compound/ne/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/compound/se/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/compound/sw/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/filtration/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/jungle1/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/jungle10/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/jungle2/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/jungle3/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/jungle4/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/jungle5/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/jungle6/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/jungle7/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/jungle8/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/jungle9/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/river1/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/river2/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/river3/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/ruin/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/sand1/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/sand2/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/sand2/garbledradio/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/sand3/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/sand4/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/sand5/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/sand6/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/sand6/garbledradio/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/sand7/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/sand7/garbledradio/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/sand8/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/ground/sand9/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/armory/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/atmos/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/bar/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/canteen/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/captain/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/chapel/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/comms/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/corporate_affairs/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/crashed_ship/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/engineering/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/fitness/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/hydroponics/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/hydroponics/aux/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/internal_affairs/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/kitchen/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/main_hall/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/overgrown/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/quart/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/quartstorage/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/quartstorage/dome/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/quartstorage/outdoors/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/research/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/robotics/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/sandtemple/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/sandtemple/garbledradio/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/secure_storage/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/security/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/sleep_female/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/sleep_male/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/spaceport/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/spaceport2/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/tablefort/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/toilet/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/storage/testroom/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/template_noop/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/magmoor/cargo/freezer/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/cargo/processing/south/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/cargo/storage/secure/south/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/cargo/storage/south/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/cave/east/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/cave/north/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/cave/northeast/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/cave/northwest/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/cave/rock/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/cave/southeast/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/cave/southwest/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/cave/west/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/civilian/arrival/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/civilian/arrival/east/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/civilian/bar/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/civilian/basket/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/civilian/clean/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/civilian/clean/shower/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/civilian/clean/toilet/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/civilian/cook/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/civilian/cryostasis/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/civilian/dorms/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/civilian/gambling/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/civilian/jani/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/civilian/mosque/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/civilian/pool/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/civilian/rnr/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/command/commandroom/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/command/conference/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/command/lobby/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/command/lobby/east/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/command/office/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/command/office/main/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/compound/theme_magmoor_digsite_iv
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/magmoor/compound/east/theme_magmoor_digsite_iv
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/magmoor/compound/north/theme_magmoor_digsite_iv
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/magmoor/compound/northeast/theme_magmoor_digsite_iv
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/magmoor/compound/northwest/theme_magmoor_digsite_iv
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/magmoor/compound/south/theme_magmoor_digsite_iv
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/magmoor/compound/southeast/theme_magmoor_digsite_iv
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/magmoor/compound/southwest/theme_magmoor_digsite_iv
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/magmoor/compound/west/theme_magmoor_digsite_iv
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/magmoor/engi/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/engi/atmos/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/engi/garage/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/engi/power/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/engi/storage/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/engi/thermal/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/hydroponics/north/theme_magmoor_digsite_iv
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/magmoor/hydroponics/south/theme_magmoor_digsite_iv
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/magmoor/landing/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/landing/two/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/medical/breakroom/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/medical/chemistry/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/medical/cmo/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/medical/lobby/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/medical/morgue/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/medical/patient/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/medical/storage/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/medical/surgery/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/medical/treatment/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/mining/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/mining/garage/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/mining/storage/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/research/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/research/containment/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/research/rnd/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/research/rnd/lobby/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/research/serverroom/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/security/arrivals/east/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/security/arrivals/south/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/security/infocenter/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/security/lobby/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/security/storage/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/magmoor/volcano/theme_magmoor_digsite_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/storage/testroom/theme_magmoor_digsite_iv
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/orion_outpost/ground/outpostcent/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/ground/outposte/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/ground/outpostn/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/ground/outpostnw/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/ground/outposts/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/ground/outpostse/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/ground/outpostsw/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/ground/outpostw/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/ground/river/riverside_central/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/ground/river/riverside_north/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/ground/river/riverside_south/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/ground/underground/caveE/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/ground/underground/caveE/garbledradio/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/ground/underground/caveN/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/ground/underground/caveN/garbledradio/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/ground/underground/caveS/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/ground/underground/caveS/garbledradio/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/building/administration/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/building/ammodepot/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/building/armory/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/building/atc/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/building/barracks/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/building/breakroom/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/building/brig/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/building/bunker/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/building/canteen/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/building/cargo/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/building/command/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/building/dorms/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/building/engineering/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/building/medbay/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/building/monitor/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/building/nebuilding/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/building/prep/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/building/tadpolepad/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/building/vehicledepot/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/landing_pad/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/landing_pad2_external/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/landing_pad_2/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/orion_outpost/surface/landing_pad_external/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/storage/testroom/theme_orionoutpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/canteen/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/cellblock/highsec/north/north/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/cellblock/highsec/north/south/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/cellblock/highsec/south/north/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/cellblock/highsec/south/south/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/cellblock/lowsec/ne/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/cellblock/lowsec/nw/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/cellblock/lowsec/se/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/cellblock/lowsec/sw/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/cellblock/maxsec/north/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/cellblock/maxsec/south/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/cellblock/mediumsec/east/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/cellblock/mediumsec/north/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/cellblock/mediumsec/south/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/cellblock/mediumsec/west/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/cellblock/protective/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/cellblock/vip/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/chapel/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/cleaning/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/command/office/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/command/quarters/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/command/secretary_office/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/disposal/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/engineering/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/engineering/atmos/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/execution/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/hallway/central/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/hallway/east/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/hallway/engineering/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/hallway/entrance/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/hallway/staff/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/hangar/civilian/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/hangar/main/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/hangar_storage/main/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/hangar_storage/research/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/holding/holding1/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/holding/holding2/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/intake/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/kitchen/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/laundry/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/library/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/maintenance/hangar_barracks/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/maintenance/research_medbay/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/maintenance/residential/access/north/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/maintenance/residential/access/south/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/maintenance/residential/ne/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/maintenance/residential/nw/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/maintenance/residential/se/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/maintenance/residential/sw/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/maintenance/staff_research/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/medbay/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/medbay/foyer/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/medbay/morgue/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/medbay/surgery/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/monorail/west/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/parole/main/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/parole/protective_custody/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/pirate/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/quarters/research/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/quarters/security/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/quarters/staff/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/recreation/highsec/n/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/recreation/highsec/s/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/recreation/medsec/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/recreation/staff/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/research/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/research/RD/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/research/secret/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/research/secret/bioengineering/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/research/secret/biolab/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/research/secret/chemistry/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/research/secret/containment/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/research/secret/dissection/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/residential/central/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/residential/north/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/residential/south/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/security/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/security/armory/lethal/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/security/armory/riot/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/security/briefing/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/security/checkpoint/highsec/n/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/security/checkpoint/highsec/s/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/security/checkpoint/highsec_medsec/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/security/checkpoint/maxsec/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/security/checkpoint/maxsec_highsec/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/security/checkpoint/medsec/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/security/checkpoint/vip/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/security/head/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/security/monitoring/highsec/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/security/monitoring/lowsec/ne/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/security/monitoring/lowsec/sw/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/security/monitoring/maxsec/panopticon/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/security/monitoring/medsec/central/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/security/monitoring/medsec/south/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/security/monitoring/protective/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/storage/highsec/n/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/storage/highsec/s/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/storage/medsec/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/storage/vip/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/store/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/toilet/canteen/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/toilet/research/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/toilet/security/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/toilet/staff/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/visitation/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/prison/yard/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/storage/testroom/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/template_noop/theme_prison_station_fop
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/bigredv2/caves/rock/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg', 'sound/ambience/ambilava3.ogg')

/area/lv624/lazarus/console/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/arrivals/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/arrivals/securitylz1/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/arrivals/securitylz2/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/brig/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/brig/armoury/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/brig/gear_room/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/brig/wardens_office/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/cargo/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/cargo/engineering/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/cargo/office/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/cargo/security/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/caves/east/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/caves/north/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/caves/north_east/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/caves/north_west/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/caves/south/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/caves/south_east/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/caves/south_west/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/caves/west/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/dormitories/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/engineering/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/engineering/engine/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/engineering/hallway/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/engineering/security/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/hallway/central/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/hallway/east/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/hallway/northern/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/hallway/south_cent/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/hallway/south_east/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/hallway/south_west/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/hallway/west/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/lz1/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/lz2/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/medbay/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/medbay/chemistry/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/medbay/security/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/medbay/storage/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/medbay/surgery/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/science/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/science/hydponics/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/science/rd_office/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/science/research/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/science/security/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/science/xenobiology/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/outpost/yard/central/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/outpost/yard/east/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/outpost/yard/north/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/outpost/yard/north_east/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/outpost/yard/south/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/outpost/yard/south_east/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/outpost/yard/west/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/space/theme_research_outpost
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/crew_quarters/sleep/bedrooms/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/crew_quarters/sleep_male/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/lv624/ground/caves/central1/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/ground/caves/central2/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/ground/caves/east1/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/ground/caves/west1/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/ground/compound/c/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/lv624/ground/compound/n/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/lv624/ground/compound/se/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/lv624/ground/compound/sw/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/lv624/lazarus/canteen/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/comms/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/engineering/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/fitness/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/hydroponics/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/internal_affairs/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/medbay/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/quart/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/quartstorage/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/research/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/robotics/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/security/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/maintenance/apmaint/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/maintenance/substation/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/medical/medbay2/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/space/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/storage/tools/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/vapor_processing/cargo2/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/vapor_processing/cargo3/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/vapor_processing/cargo_maint_s/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/vapor_processing/caves/se/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/vapor_processing/east_compound/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/vapor_processing/south_compound/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/vapor_processing/west_compound/theme_vapor_processing
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/ai_monitored/storage/eva/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/ai_monitored/aisat/exterior/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/ai_monitored/turret_protected/ai/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/ai_monitored/turret_protected/ai_upload/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/ai_monitored/turret_protected/aisat_interior/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/asteroidcaves/derelictnortheast/theme_deltastation
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/deltastation/asteroidcaves/derelictwest/theme_deltastation
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/deltastation/asteroidcaves/easterntunnel/theme_deltastation
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/deltastation/asteroidcaves/exteriorasteroids/theme_deltastation
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/deltastation/asteroidcaves/northcaves/theme_deltastation
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/deltastation/asteroidcaves/northcaves/garbledradio/theme_deltastation
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/deltastation/asteroidcaves/northeastcaves/theme_deltastation
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/deltastation/asteroidcaves/rock/theme_deltastation
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/deltastation/asteroidcaves/securitycaves/theme_deltastation
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/deltastation/asteroidcaves/ship/theme_deltastation
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/deltastation/asteroidcaves/southlz/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/asteroidcaves/southtunnel/theme_deltastation
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/deltastation/asteroidcaves/westerncaves/theme_deltastation
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/deltastation/asteroidcaves/westerncaves/garbledradio/theme_deltastation
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/deltastation/cargo/drone_bay/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/cargo/lobby/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/cargo/miningoffice/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/cargo/office/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/cargo/sorting/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/cargo/storage/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/cargo/warehouse/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/command/bridge/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/command/corporate_showroom/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/command/gateway/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/command/heads_quarters/captain/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/command/heads_quarters/captain/private/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/command/heads_quarters/ce/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/command/heads_quarters/cmo/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/command/heads_quarters/hop/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/command/heads_quarters/hos/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/command/heads_quarters/qm/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/command/heads_quarters/rd/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/command/meeting_room/council/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/command/teleporter/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/commons/dorms/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/commons/dorms/laundry/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/commons/fitness/recreation/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/commons/locker/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/commons/lounge/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/commons/storage/primary/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/commons/storage/tools/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/commons/toilet/locker/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/commons/toilet/restrooms/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/commons/vacant_room/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/commons/vacant_room/commissary/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/commons/vacant_room/office/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/construction/mining/aux_base/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/engineering/atmos/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/engineering/atmos/hfr_room/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/engineering/atmos/mix/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/engineering/atmos/project/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/engineering/atmos/pumproom/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/engineering/atmos/storage/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/engineering/atmos/storage/gas/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/engineering/break_room/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/engineering/gravity_generator/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/engineering/hallway/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/engineering/lobby/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/engineering/main/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/engineering/storage/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/engineering/storage/tech/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/engineering/storage_shared/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/engineering/supermatter/theme_deltastation
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/deltastation/engineering/supermatter/room/theme_deltastation
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/deltastation/engineering/transit_tube/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/external/landingzone/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/hallway/primary/central/aft/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/hallway/primary/central/fore/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/hallway/primary/fore/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/hallway/primary/port/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/hallway/primary/starboard/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/hallway/secondary/command/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/hallway/secondary/construction/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/hallway/secondary/entry/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/hallway/secondary/exit/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/hallway/secondary/exit/departure_lounge/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/hallway/secondary/service/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/maintenance/central/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/maintenance/department/chapel/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/maintenance/department/crew_quarters/bar/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/maintenance/department/electrical/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/maintenance/department/engine/atmos/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/maintenance/department/eva/abandoned/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/maintenance/department/medical/morgue/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/maintenance/department/science/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/maintenance/department/science/xenobiology/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/maintenance/department/security/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/maintenance/disposal/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/maintenance/disposal/incinerator/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/maintenance/fore/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/maintenance/port/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/maintenance/port/aft/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/maintenance/port/fore/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/maintenance/solars/port/aft/theme_deltastation
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/deltastation/maintenance/solars/port/fore/theme_deltastation
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/deltastation/maintenance/solars/starboard/aft/theme_deltastation
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/deltastation/maintenance/solars/starboard/fore/theme_deltastation
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/deltastation/maintenance/starboard/aft/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/maintenance/starboard/lesser/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/medical/abandoned/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/medical/break_room/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/medical/chemistry/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/medical/coldroom/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/medical/cryo/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/medical/medbay/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/medical/medbay/lobby/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/medical/morgue/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/medical/paramedic/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/medical/pharmacy/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/medical/psychology/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/medical/storage/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/medical/surgery/theatre/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/medical/treatment_center/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/medical/virology/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/science/auxlab/firing_range/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/science/breakroom/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/science/circuits/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/science/explab/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/science/genetics/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/science/lab/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/science/lobby/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/science/ordnance/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/science/ordnance/burnchamber/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/science/ordnance/freezerchamber/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/science/ordnance/office/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/science/ordnance/storage/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/science/ordnance/testlab/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/science/research/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/science/research/abandoned/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/science/robotics/lab/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/science/robotics/mechbay/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/science/server/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/science/xenobiology/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/brig/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/checkpoint/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/checkpoint/customs/aft/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/checkpoint/customs/fore/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/checkpoint/engineering/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/checkpoint/escape/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/checkpoint/medical/medsci/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/checkpoint/supply/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/courtroom/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/detectives_office/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/detectives_office/private_investigators_office/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/execution/education/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/execution/transfer/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/holding_cell/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/interrogation/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/lockers/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/medical/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/office/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/prison/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/prison/garden/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/prison/mess/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/prison/safe/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/prison/toilet/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/prison/visit/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/prison/work/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/processing/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/range/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/security/warden/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/abandoned_gambling_den/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/abandoned_gambling_den/gaming/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/bar/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/bar/backroom/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/barber/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/cafeteria/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/chapel/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/chapel/funeral/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/chapel/office/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/chapel/storage/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/electronic_marketing_den/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/hydroponics/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/hydroponics/garden/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/hydroponics/garden/abandoned/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/janitor/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/kitchen/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/kitchen/abandoned/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/kitchen/coldroom/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/lawoffice/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/library/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/library/abandoned/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/library/artgallery/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/library/lounge/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/library/printer/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/library/private/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/theater/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/service/theater/abandoned/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/tcommsat/computer/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deltastation/tcommsat/server/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/holodeck/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/security/nuke_storage/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/template_noop/theme_deltastation
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/lv624/ground/caves/central1/theme_desparity
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/ground/caves/east1/theme_desparity
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/ground/caves/rock/theme_desparity
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/ground/caves/west1/theme_desparity
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/ground/jungle10/theme_desparity
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/lv624/ground/jungle5/theme_desparity
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/lv624/ground/jungle7/theme_desparity
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/lv624/ground/jungle9/theme_desparity
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/lv624/ground/river3/theme_desparity
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/lv624/lazarus/bar/theme_desparity
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/canteen/theme_desparity
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/captain/theme_desparity
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/chapel/theme_desparity
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/crashed_ship/desparity/theme_desparity
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/engineering/theme_desparity
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/fitness/theme_desparity
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/hydroponics/theme_desparity
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/medbay/theme_desparity
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/overgrown/theme_desparity
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/lv624/lazarus/quartstorage/outdoors/theme_desparity
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/research/caves/theme_desparity
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/security/theme_desparity
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/sleep_male/theme_desparity
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/spaceport/theme_desparity
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/spaceport2/theme_desparity
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/storage/testroom/theme_desparity
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/gelida/caves/central_caves/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/caves/central_caves/garbledradio/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/caves/east_caves/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/caves/east_caves/garbledradio/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/caves/west_caves/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/caves/west_caves/garbledradio/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/cavestructuretwo/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/a_block/admin/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/a_block/bridges/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/a_block/bridges/corpo/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/a_block/bridges/corpo_fitness/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/a_block/bridges/dorms_fitness/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/a_block/bridges/garden_bridge/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/a_block/bridges/op_centre/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/a_block/corpo/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/a_block/dorm_north/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/a_block/dorms/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/a_block/executive/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/a_block/fitness/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/a_block/garden/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/a_block/hallway/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/a_block/kitchen/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/a_block/medical/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/a_block/security/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/b_block/bar/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/b_block/bridge/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/b_block/hydro/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/c_block/bridge/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/c_block/cargo/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/c_block/casino/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/c_block/garage/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/c_block/mining/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/lone_buildings/chunk/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/indoors/lone_buildings/storage_blocks/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/landing_zone_1/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/landing_zone_2/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/landing_zone_forecon/UD6_Tornado/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/landing_zone_forecon/UD6_Typhoon/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/landing_zone_forecon/landing_zone_4/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/gelida/outdoors/colony_streets/central_streets/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/gelida/outdoors/colony_streets/east_central_street/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/gelida/outdoors/colony_streets/north_east_street/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/gelida/outdoors/colony_streets/north_street/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/gelida/outdoors/colony_streets/north_west_street/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/gelida/outdoors/colony_streets/south_east_street/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/gelida/outdoors/colony_streets/south_street/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/gelida/outdoors/colony_streets/south_west_street/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/gelida/outdoors/colony_streets/windbreaker/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/gelida/outdoors/n_rockies/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/gelida/outdoors/nw_rockies/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/gelida/outdoors/rock/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/gelida/outdoors/w_rockies/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/gelida/powergen/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/console/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/storage/testroom/theme_gelida_iv
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/icy_caves/caves/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/caves/alienstuff/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/caves/cavesbrig/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/caves/chapel/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/caves/crashed_ship/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/caves/east/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/caves/northern/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/caves/northwestmonorail/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/caves/northwestmonorail/breakroom/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/caves/northwestmonorail/hallway/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/caves/northwestmonorail/medbay/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/caves/northwestmonorail/morgue/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/caves/rock/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/caves/south/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/caves/underground_cafeteria/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/caves/weapon_vault/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/caves/west/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/outpost/LZ1/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/outpost/LZ2/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/outpost/dorms/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/outpost/engineering/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/outpost/garage/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/outpost/kitchen/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/outpost/medbay/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/outpost/mining/east/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/outpost/mining/west/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/outpost/office/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/outpost/outside/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/outpost/outside/center/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/outpost/refinery/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/outpost/research/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/icy_caves/outpost/security/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/console/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/space/theme_icy_caves
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/kutjevo/exterior/Northwest_Colony/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/colony_N_East/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/colony_S_East/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/colony_South/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/colony_central/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/colony_north/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/complex_border/botany_medical_cave/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/complex_border/med_park/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/complex_border/med_rec/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/construction/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/lz_dunes/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/lz_pad/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/lz_river/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/runoff_bridge/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/runoff_dunes/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/runoff_river/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/scrubland/north/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/scrubland/south/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/spring/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/stonyfields/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/telecomm/lz1_south/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/telecomm/lz2_north/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/exterior/telecomm/lz2_south/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/colony_South/power2/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/colony_central/mine_elevator/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/complex/Northwest_Dorms/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/complex/Northwest_Flight_Control/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/complex/Northwest_Security_Checkpoint/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/complex/botany/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/complex/botany/east/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/complex/botany/east_tech/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/complex/med/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/complex/med/auto_doc/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/complex/med/cells/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/complex/med/locks/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/complex/med/operating/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/complex/med/triage/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/construction/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/construction/two/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/filtration/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/foremans_office/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/oob/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/oob/dev_room/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/power/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/power/comms/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/kutjevo/interior/power_pt2_electric_boogaloo/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/storage/testroom/theme_kutjevo
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/deathmatch/theme_cs_mansion
	eorg_weather_type = /datum/weather/snow_storm
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deathmatch/theme_cs_militia
	eorg_weather_type = /datum/weather/ash_storm/sand
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/deathmatch/theme_de_dust2
	eorg_weather_type = /datum/weather/ash_storm/sand
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/deathmatch/theme_de_inferno
	eorg_weather_type = /datum/weather/snow_storm
	temperature = ICE_COLONY_TEMPERATURE
	ambience = list('sound/ambience/ambi_snow.ogg', 'sound/effects/wind/wind_2_1.ogg')

/area/deathmatch/theme_cs_office
	eorg_weather_type = /datum/weather/acid_rain/harmless
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/deathmatch/theme_de_nuke
	eorg_weather_type = /datum/weather/acid_rain/harmless
	temperature = T20C
	ambience = list('sound/ambience/jungle_amb1.ogg')

/area/deathmatch/theme_original
	eorg_weather_type = /datum/weather/ash_storm/sand
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/space/theme_original
	temperature = T20C
	ambience = list('sound/effects/wind/wind_2_1.ogg')

/area/bigredv2/outside/admin_building/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/medical/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/chapel/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/southcheckpoint/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/general_store/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/library/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/caves/rustedpreparea/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/caves/undergroundrobotics/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/caves/secomplex/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/bigredv2/outside/storage/theme_bigred_v2
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg')

/area/lv624/lazarus/quartstorage/two/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')

/area/lv624/lazarus/medbay/theme_lv624
	temperature = T20C
	ambience = list('sound/ambience/ambicave.ogg', 'sound/ambience/ambilava1.ogg', 'sound/ambience/ambilava2.ogg')
