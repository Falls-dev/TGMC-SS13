///Cursor-controlled telekinesis for TK-5.
#define KINESIS_TIER_SMALL 1
#define KINESIS_TIER_CRATE 2
#define KINESIS_TIER_BODY 3
#define KINESIS_CHARGE_DELAY 2
#define KINESIS_CHARGE_REGEN 100
#define KINESIS_CHARGE_UNWORN_RATE 10
#define CHARGE_SMALL 50
#define THROW_SMALL 100
#define CHARGE_CRATE 250
#define THROW_CRATE 300
#define CHARGE_BODY 500

#define KINESIS_HELD "held"
#define KINESIS_EMPTY "empty"

/datum/kinesis_field
	///The gauntlets running this field.
	var/obj/item/clothing/gloves/kinesis/gauntlets
	///The mob wearing them.
	var/mob/living/user
	///Held atom; the holo controls its visibility and position.
	var/atom/movable/subject
	///One of the KINESIS_* defines.
	var/state = KINESIS_EMPTY
	///The graphic standing in for the held object.
	var/obj/effect/kinesis_holo/holo
	///Whether the marker is armed, waiting for a click to name the target.
	var/marking = FALSE
	///Reason shown after a refused grab.
	var/last_refusal

	///Furthest an object can be from the wearer and still be taken.
	var/range = 4.5
	///Maximum throw distance in tiles.
	var/drop_range = 6
	///Throw speed numerator, divided by subject mass.
	var/launch_force = 30

	///Last tile used to update the target preview.
	var/last_aimed
	///Cursor tile used for holding and throwing.
	var/aimed
	///The persistent preview. Lives for as long as the field is aiming.
	var/obj/effect/kinesis_aim_ghost/aim_ghost
	///What that ghost is currently a picture of.
	var/atom/movable/aim_ghost_of
	///The reserve left in the field.
	var/charge = 1000
	///Maximum charge.
	var/max_charge = 1000
	///Last spend or recharge time; spending delays regeneration.
	var/last_charge_tick = 0
	///When FALSE, release_all() also refills the reserve.
	var/passive_charge = TRUE
	///Beam between the wearer and held effect.
	var/datum/beam/tether
	var/max_launch_speed = 9

/datum/kinesis_field/New(obj/item/clothing/gloves/kinesis/_gauntlets, mob/living/_user)
	. = ..()
	gauntlets = _gauntlets
	user = _user
	RegisterSignal(user, COMSIG_MOB_CLICKON, PROC_REF(on_clickon))
	//Out-of-reach targets also arrive through the ranged attack signal.
	RegisterSignal(user, COMSIG_MOB_ATTACK_RANGED, PROC_REF(on_ranged_click))
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_wearer_shifted))
	START_PROCESSING(SSobj, src)
	RegisterSignal(user, COMSIG_MOB_FACE_DIR, PROC_REF(on_wearer_shifted))

/datum/kinesis_field/Destroy(override = TRUE, ...)
	STOP_PROCESSING(SSobj, src)
	var/obj/item/clothing/gloves/kinesis/ds13/gloves = gauntlets
	if(istype(gloves) && gloves.field == src)
		gloves.field = null
	//release_all must not redraw a charge indicator while the field is being destroyed.
	gauntlets = null
	release_all()
	drop_preview()
	clear_tether()
	UnregisterSignal(user, list(COMSIG_MOB_CLICKON, COMSIG_MOB_ATTACK_RANGED, COMSIG_MOVABLE_MOVED, COMSIG_MOB_FACE_DIR))
	UnregisterSignal(user, COMSIG_MOB_DEATH)
	var/mob/living/carbon/human/wearer = user
	user = null
	. = ..()
	if(istype(wearer))
		wearer.kinesis_hud_clear_charge()

// Acquisition.

/datum/kinesis_field/proc/on_ranged_click(mob/clicker, atom/target, list/params)
	if(!marking || state != KINESIS_EMPTY)
		return
	marking = FALSE
	attempt_take(target)
	return COMSIG_MOB_CLICK_CANCELED

///Right-click throws; left-click places. Handle held objects before target selection.
/datum/kinesis_field/proc/on_clickon(mob/clicker, atom/A, list/params)
	var/list/modifiers = params2list(params)
	if(state == KINESIS_HELD && modifiers["right"])
		launch()
		return COMSIG_MOB_CLICK_CANCELED
	if(state == KINESIS_HELD && modifiers["left"])
		release_grip()
		return COMSIG_MOB_CLICK_CANCELED
	if(marking)
		marking = FALSE
		attempt_take(A)
		//Clear the preview even if the grab failed.
		update_tether()
		return COMSIG_MOB_CLICK_CANCELED

/datum/kinesis_field/proc/attempt_take(atom/target)
	var/atom/movable/wanted = target
	if(isnull(wanted))
		user.balloon_alert(user, "No target.")
		return FALSE
	if(!take_target(wanted))
		user.balloon_alert(user, "Refused: " + last_refusal + ".")
		return FALSE
	return TRUE

///Toggle target selection, or release the held object.
/datum/kinesis_field/proc/toggle_marker()
	if(state != KINESIS_EMPTY)
		return release_grip()
	marking = !marking
	update_tether()
	if(marking)
		user.balloon_alert(user, "Marking: click what to take.")
	else
		user.balloon_alert(user, "Marker off.")

/datum/kinesis_field/proc/can_grip(atom/target)
	last_refusal = null
	if(!istype(target, /atom/movable))
		last_refusal = "not an object"
		return FALSE
	var/atom/movable/grabbable = target
	if(grabbable == user)
		last_refusal = "yourself"
		user.balloon_alert(user, "Not yourself.")
		return FALSE
	//Vehicles have separate hitboxes and occupants that cannot follow the field safely.
	if(istype(grabbable, /obj/vehicle))
		last_refusal = "vehicle"
		return FALSE
	//Allow listed cargo structures despite their default anchoring.
	var/obj/structure/fixed_thing = grabbable
	if(istype(fixed_thing, /obj/structure))
		var/unscrewable = istype(fixed_thing, /obj/structure/closet) && !istype(fixed_thing, /obj/structure/closet/secure_closet)
		var/tank = istype(fixed_thing, /obj/structure/reagent_dispensers/fueltank) || istype(fixed_thing, /obj/structure/reagent_dispensers/watertank)
		if(!unscrewable && !tank && !istype(fixed_thing, /obj/structure/largecrate))
			last_refusal = "fixed in place"
			return FALSE
	else if(grabbable.anchored)
		last_refusal = "anchored"
		return FALSE
	//TK-5 can carry corpses, but not living mobs.
	var/mob/living/grabbable_body = grabbable
	if(istype(grabbable_body) && grabbable_body.stat != DEAD)
		last_refusal = "living"
		return FALSE
	if(!isturf(grabbable.loc))
		last_refusal = "not on the map"
		return FALSE
	if(get_dist(user, grabbable) > range)
		last_refusal = "too far"
		return FALSE
	var/turf/grabbable_from = get_turf(user)
	var/turf/grabbable_to = get_turf(grabbable)
	if(!isturf(grabbable_from) || !isturf(grabbable_to))
		last_refusal = "off map"
		return FALSE
	//Check adjacent tiles so a dense target does not block its own pickup path.
	var/can_see_it = FALSE
	for(var/step_dir in list(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST))
		var/turf/beside = get_step(grabbable_to, step_dir)
		if(!isturf(beside))
			continue
		if(beside == grabbable_from || has_clear_path(grabbable_from, beside))
			can_see_it = TRUE
			break
	if(!can_see_it)
		last_refusal = "no line"
		return FALSE
	return TRUE

/datum/kinesis_field/proc/tier_of(atom/target)
	if(istype(target, /mob/living))
		return KINESIS_TIER_BODY
	if(istype(target, /obj/structure/closet))
		return KINESIS_TIER_CRATE
	return KINESIS_TIER_SMALL

///Charge cost for grabbing or throwing; bodies have no additional throw cost.
/datum/kinesis_field/proc/cost_of(atom/target, throwing = FALSE)
	switch(tier_of(target))
		if(KINESIS_TIER_BODY)
			return throwing ? 0 : CHARGE_BODY
		if(KINESIS_TIER_CRATE)
			return throwing ? THROW_CRATE : CHARGE_CRATE
	return throwing ? THROW_SMALL : CHARGE_SMALL

/datum/kinesis_field/proc/spend(amount)
	if(amount <= 0)
		return TRUE
	if(charge < amount)
		user.balloon_alert(user, "The field is out of charge.")
		last_refusal = "no charge"
		return FALSE
	charge -= amount
	//Spending restarts the recharge delay.
	last_charge_tick = world.time
	refresh_charge_hud()
	return TRUE

/datum/kinesis_field/proc/refresh_charge_hud()
	set waitfor = FALSE
	if(isnull(gauntlets))
		return
	var/mob/living/carbon/human/wearer_now = user
	if(!istype(wearer_now))
		return
	wearer_now.kinesis_hud_set_charge(charge, max_charge)

/datum/kinesis_field/proc/take_target(atom/target)
	if(state != KINESIS_EMPTY)
		return FALSE
	var/atom/movable/wanted = target
	if(isnull(wanted))
		last_refusal = "nothing"
		return FALSE
	if(!can_grip(wanted))
		return FALSE
	if(length(user.get_held_items()))
		last_refusal = "hands full"
		user.balloon_alert(user, "Your hands are full.")
		return FALSE
	if(!spend(cost_of(wanted)))
		return FALSE
	//Only items support the inventory pickup path.
	if(istype(wanted, /obj/item))
		user.put_in_active_hand(wanted)
		if(wanted.loc != user)
			last_refusal = "pickup refused"
			user.balloon_alert(user, "The field cannot reach it.")
			return FALSE
	else
		//Keep structures on the map for collision and interactions.
		var/obj/structure/loose_thing = wanted
		if(istype(loose_thing, /obj/structure))
			loose_thing.anchored = FALSE
		if(!istype(wanted, /obj))
			wanted.loc = null
	become_holo(wanted)
	playsound(get_turf(user), 'sound/effects/telekinesis/kinesis_grab.ogg', 20, 1)
	to_chat(user, span_notice("You take hold of [wanted] with the field."))
	return TRUE

///Remove items from inventory before creating their hold effect.
/datum/kinesis_field/proc/become_holo(atom/movable/thing)
	if(istype(thing, /obj/item) && thing.loc == user)
		user.temporarilyRemoveItemFromInventory(thing)
	holo = new /obj/effect/kinesis_holo(get_turf(user), thing)
	subject = thing
	state = KINESIS_HELD
	//Align collision immediately, without waiting for a mouse event.
	update_holo()
	RegisterSignal(thing, COMSIG_ATOM_BULLET_ACT, PROC_REF(on_carried_bullet_act))
	RegisterSignal(thing, COMSIG_QDELETING, PROC_REF(on_carried_qdeleting))

///Remove the effect when its subject is deleted, without restoring the deleted atom.
/datum/kinesis_field/proc/on_carried_qdeleting()
	SIGNAL_HANDLER
	if(state != KINESIS_HELD)
		return
	subject = null
	state = KINESIS_EMPTY
	clear_tether()
	if(!isnull(holo))
		//Not hand_back: the object is mid-deletion, so there is nothing left to restore or move.
		holo.stored = null
		QDEL_NULL(holo)
	update_tether()

///A projectile reached the carried object, so the grip breaks and it drops.
/datum/kinesis_field/proc/on_carried_bullet_act(atom/movable/projectile/shot)
	SIGNAL_HANDLER
	if(state != KINESIS_HELD)
		return
	release_grip()

/datum/kinesis_field/proc/is_gripping()
	return state == KINESIS_HELD

/datum/kinesis_field/proc/on_wearer_shifted()
	update_holo()

// Releasing.

///Throw toward the cursor, falling back to the wearer's facing direction.
/datum/kinesis_field/proc/launch()
	if(state != KINESIS_HELD)
		return FALSE
	//Remove the beam before take_back() deletes its endpoint.
	clear_tether()
	var/atom/movable/flung = take_back()
	if(isnull(flung))
		return FALSE
	if(!spend(cost_of(flung, TRUE)))
		//Retain the grip if there is not enough charge to throw.
		become_holo(flung)
		return FALSE
	//throw_at requires a valid starting turf, including for parked mobs.
	var/turf/starting = get_turf(user)
	if(isnull(starting))
		starting = flung.loc
	if(isnull(starting))
		starting = get_turf(flung)
	if(isnull(starting))
		return FALSE
	flung.forceMove(starting)
	var/turf/aimed = throw_turf()
	if(isnull(aimed))
		to_chat(user, span_notice("You let [flung] fall at your feet."))
		return TRUE
	new /obj/effect/temp_visual/shockwave(starting, 2)
	playsound(user, 'sound/effects/telekinesis/kinesis_launch.ogg', 45, 1)
	flung.throw_at(aimed, max_launch_speed, launch_force / max(subject_mass(flung), 0.1), user)
	return TRUE

///Place the held object on a reachable tile near its current position.
/datum/kinesis_field/proc/release_grip()
	if(state != KINESIS_HELD)
		return FALSE
	var/turf/was_at = holo?.loc
	if(!isturf(was_at) || was_at == get_turf(user))
		was_at = aimed
	var/atom/movable/put_down = take_back()
	if(isnull(put_down))
		return FALSE
	var/turf/landing = placeable_for(was_at)
	if(!isturf(landing))
		landing = get_turf(user)
	put_down.forceMove(landing)
	to_chat(user, span_notice("You set [put_down] down."))
	update_tether()
	return TRUE

///Restore the subject before deleting its effect, so Destroy cannot move it again.
/datum/kinesis_field/proc/take_back()
	var/atom/movable/real
	if(!isnull(holo))
		real = holo.stored
		if(!isnull(real))
			UnregisterSignal(real, COMSIG_ATOM_BULLET_ACT)
		holo.hand_back(get_turf(user))
		QDEL_NULL(holo)
	else
		real = subject
	subject = null
	state = KINESIS_EMPTY
	return real

///Do not call the parent: its PROCESS_KILL return would stop regeneration.
/datum/kinesis_field/process()
	var/mob/living/wearer_now = user
	if(isnull(wearer_now))
		return
	if(world.time < last_charge_tick + KINESIS_CHARGE_DELAY * 10)
		return
	last_charge_tick = world.time
	if(charge >= max_charge)
		return
	var/switched_on = !isnull(gauntlets) && gauntlets.active
	//Use the slower rate while the wearer is incapacitated or lying down.
	var/rate = KINESIS_CHARGE_UNWORN_RATE
	if(switched_on && !wearer_now.incapacitated() && !wearer_now.lying_angle)
		rate = KINESIS_CHARGE_REGEN
	charge = min(max_charge, charge + rate)
	refresh_charge_hud()

/datum/kinesis_field/proc/release_all()
	marking = FALSE
	drop_preview()
	if(state == KINESIS_HELD)
		release_grip()
	if(!passive_charge)
		charge = max_charge
	refresh_charge_hud()

// The held graphic.

///Check destination collision and the path from the wearer.
/datum/kinesis_field/proc/reachable(turf/from, turf/destination)
	if(!isturf(from) || !isturf(destination))
		return FALSE
	if(destination == from)
		return TRUE
	//Exclude the carried structure from destination collision.
	if(destination.density)
		return FALSE
	for(var/atom/destination_occupant in destination)
		if(destination_occupant != holo?.stored && destination_occupant.density)
			return FALSE
	if(destination.opacity)
		return FALSE
	//Ignore the carried atom only during the path check; restore collision before moving.
	var/obj/carried_object = holo?.stored
	var/old_carried_density = carried_object?.density
	if(carried_object)
		carried_object.density = FALSE
	var/path_result = check_path(from, destination, PASS_THROW)
	if(carried_object)
		carried_object.density = old_carried_density
	return path_result == destination

/datum/kinesis_field/proc/update_holo()
	if(isnull(holo))
		return
	//Knockdown also breaks the grip; incapacitated() alone does not cover it.
	if(user.incapacitated() || user.lying_angle)
		release_grip()
		return
	var/turf/here = get_turf(user)
	if(!isturf(here))
		return
	//Holding range is independent of throw range.
	var/grip_range = 2
	var/turf/wanted = aimed
	if(!isturf(wanted))
		wanted = turf_ahead()
	if(!isturf(wanted))
		return
	while(get_dist(here, wanted) > grip_range)
		wanted = get_step_towards(wanted, here)
	var/turf/seat = wanted
	var/turf/was = holo.loc
	//Check paths only on tile changes; retain position if the destination is blocked.
	if(seat != holo.loc && !reachable(here, seat))
		seat = isturf(was) ? was : here
	if(holo.loc != seat)
		holo.forceMove(seat)
	holo.carry_to(seat)

///One tile ahead of wherever the wearer is looking, or their own tile if that is unusable.
/datum/kinesis_field/proc/turf_ahead()
	var/turf/here = get_turf(user)
	if(!isturf(here))
		return null
	var/mob/wearer = user
	var/turf/ahead = get_step(here, wearer.dir)
	if(isturf(ahead))
		return ahead
	return here

///Cursor target limited by drop_range, with a facing-direction fallback.
/datum/kinesis_field/proc/throw_turf()
	var/turf/pointed = aimed
	if(isturf(pointed))
		var/turf/here = get_turf(user)
		var/dx = pointed.x - here.x
		var/dy = pointed.y - here.y
		var/dist = sqrt(dx * dx + dy * dy)
		if(dist > drop_range)
			var/scale = drop_range / dist
			pointed = get_offset_target_turf(here, round(dx * scale), round(dy * scale))
		if(isturf(pointed))
			return pointed
	var/turf/here = get_turf(user)
	if(!isturf(here))
		return null
	var/mob/wearer = user
	var/turf/walked = here
	for(var/step in 1 to drop_range)
		var/turf/next = get_step(walked, wearer.dir)
		if(isnull(next) || next == walked)
			break
		walked = next
	return walked

///Find a reachable landing tile near the held position, then near the wearer.
/datum/kinesis_field/proc/placeable_for(turf/from)
	var/turf/here = get_turf(user)
	if(!isturf(from))
		return nearest_free_turf()
	//Placement uses the same collision rules as carrying.
	if(reachable(here, from))
		return from
	if(!isturf(here))
		return null
	//Search the outer ring first, without allocating or sorting a candidate list.
	for(var/ring in 2 to 1 step -1)
		for(var/dx in -ring to ring)
			for(var/dy in -ring to ring)
				if(abs(dx) != ring && abs(dy) != ring)
					continue
				var/turf/probe = get_offset_target_turf(from, dx, dy)
				if(!isturf(probe) || probe == here)
					continue
				if(reachable(here, probe))
					return probe
	return nearest_free_turf()

///Search from the wearer's tile outward for a reachable landing tile.
/datum/kinesis_field/proc/nearest_free_turf()
	var/turf/here = get_turf(user)
	if(!isturf(here))
		return null
	for(var/ring in 0 to 2)
		for(var/dx in -ring to ring)
			for(var/dy in -ring to ring)
				if(ring > 0 && abs(dx) != ring && abs(dy) != ring)
					continue
				var/turf/probe = get_offset_target_turf(here, dx, dy)
				if(reachable(here, probe))
					return probe
	return here

/datum/kinesis_field/proc/has_clear_path(turf/source, turf/destination)
	if(source == destination)
		return TRUE
	return check_path(source, destination, PASS_THROW) == destination

///Approximate throw mass using item weight class.
/datum/kinesis_field/proc/subject_mass(atom/movable/thing)
	var/obj/item/massed_item = thing
	if(istype(massed_item))
		return clamp(massed_item.w_class, WEIGHT_CLASS_TINY, WEIGHT_CLASS_GIGANTIC)
	return WEIGHT_CLASS_NORMAL
