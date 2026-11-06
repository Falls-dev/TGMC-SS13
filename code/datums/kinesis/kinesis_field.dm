/// Telekinesis for the TK-5 gauntlets.
///
/// The object is never dragged across the map. A simulated velocity disagrees with TGMC's
/// one-tile-per-step move and the object judders, overshoots and walks through walls. What the
/// field does instead is park the object out of the world and stand in for it with a graphic that
/// the cursor positions, and hand it back only to be thrown or set down.
///
/// The cursor comes from /client/MouseMove, which is the only channel TGMC has - the build itself
/// never sees the mouse. That channel also carries pixel precision, so both the graphic and the
/// throw direction are driven by the pointer rather than by where the wearer is facing. Sub-tile
/// placement is not exotic: mobs and items already use pixel offsets with SLIDE_STEPS.
///
/// Acquisition goes through the game's own click channels, which hand over the exact atom: a click
/// out of reach arrives as COMSIG_MOB_ATTACK_RANGED, a click within reach as COMSIG_MOB_CLICKON.
/// The object is then picked up normally, so it passes through a real hand slot instead of being
/// conjured into the field.
///
/// DCS hands a proc reference the signal's sender first, so both handlers take the mob, then what
/// was clicked, then the raw params. Getting that wrong reads the wearer as the target.


///Bracketing and prices for the reserve, in one block so the balance can be read at a glance.
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

///Picked up, and now only a graphic exists.
#define KINESIS_HELD "held"
///Nothing in the field.
#define KINESIS_EMPTY "empty"

/datum/kinesis_field
	///The gauntlets running this field.
	var/obj/item/clothing/gloves/kinesis/gauntlets
	///The mob wearing them.
	var/mob/living/user
	///The real object while it is being held, parked out of the world behind the graphic.
	var/atom/movable/subject
	///One of the KINESIS_* defines.
	var/state = KINESIS_EMPTY
	///The graphic standing in for the held object.
	var/obj/effect/kinesis_holo/holo
	///Whether the marker is armed, waiting for a click to name the target.
	var/marking = FALSE
	///Why can_grip last refused something, so the message can name the rule that fired.
	var/last_refusal


	// Geometry, in tiles, which DS13 calls metres.
	///Furthest an object can be from the wearer and still be taken.
	var/range = 4.5
	///Never travel further than this from the wearer, so a throw cannot fling something away.
	var/drop_range = 6
	///Newtons. Decides how hard something feels when it is thrown.
	var/launch_force = 30

/datum/kinesis_field
	///The tile the cursor was last seen over. Comparing against it is what makes an unmoving
	///cursor free.
	var/last_aimed
	///The tile the cursor is on. Drives both the throw direction and the held graphic, so it is
	///kept even while nothing there is grabbable - the pointer still aims the throw.
	var/aimed
	///The persistent preview. Lives for as long as the field is aiming.
	var/obj/effect/kinesis_aim_ghost/aim_ghost
	///What that ghost is currently a picture of.
	var/atom/movable/aim_ghost_of
	///The cursor in pixels within the map, not just the tile. screen-loc carries icon-y as the
	///offset inside the cell, so a tile-level reading throws that away; params2screenpixel
	///recovers it, and the throw direction and the grip graphic both want it. Sub-tile precision
	///is not exotic here - mobs and items already use pixel offsets with SLIDE_STEPS.
	///Measured size of a world tile in pixels, needed to turn an absolute pixel into an offset
	///inside a tile. 32 is BYOND's world icon size; the codebase has no define for it.
	var/tile_pixels = 32
	///The reserve left in the field.
	var/charge = 1000
	///What the reserve refills to when the gauntlets are switched off.
	var/max_charge = 1000
	///When the bar was last redrawn, so a full reserve costs nothing to watch.
	var/last_message = 0
	///When the reserve last topped itself up, so spending resets the clock the way a cell
	///does with last_use, and the bar does not tick while the wearer is actually working.
	var/last_charge_tick = 0
	///The add_timer id, so Destroy can stop it. -1 is what BYOND returns when a timer is not
	///stoppable, and is the safe value to hold before the timer exists.
	var/recharge_timer = -1
	///Passive refill, and whether tearing the field down instead resets it outright. Left TRUE this was
	///a deliberate fallback: a field torn down mid-round - thrown off, dropped, wearer killed - should
	///come back whole, because a reserve that leaked would silently soft-lock the gloves for the rest of
	///the shift. It is switchable only so the behaviour can be turned off without deleting the code that
	///does it.
	var/passive_charge = TRUE
	///Invisible atom parked under the cursor. /datum/beam needs two atoms and a cursor is not
	///one, so the pointer gets a stand-in to be the far end of the tether.
	var/obj/effect/kinesis_aim_anchor/aim_anchor
	///The DS13 lightning tether, drawn by TGMC's own /datum/beam rather than by porting
	///DS13's /obj/effect/projectile/tether, which needs a vector2 and a pixel-space API this
	///codebase does not have.
	var/datum/beam/tether
	var/max_launch_speed = 9

/datum/kinesis_field/New(obj/item/clothing/gloves/kinesis/_gauntlets, mob/living/_user)
	. = ..()
	gauntlets = _gauntlets
	user = _user
	RegisterSignal(user, COMSIG_MOB_CLICKON, PROC_REF(on_clickon))
	//Out of reach clicks arrive here, and this is the signal that carries the real atom.
	RegisterSignal(user, COMSIG_MOB_ATTACK_RANGED, PROC_REF(on_ranged_click))
	//The graphic is re-seated when the wearer moves or turns rather than on a timer, so it tracks
	//them exactly instead of stepping along behind.
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
	QDEL_NULL(aim_anchor)
	UnregisterSignal(user, list(COMSIG_MOB_CLICKON, COMSIG_MOB_ATTACK_RANGED, COMSIG_MOVABLE_MOVED, COMSIG_MOB_FACE_DIR))
	UnregisterSignal(user, COMSIG_MOB_DEATH)
	var/mob/living/carbon/human/wearer = user
	user = null
	. = ..()
	//Presentation is last, after release, signal cleanup and the parent destructor.
	if(istype(wearer))
		wearer.kinesis_hud_clear_charge()

// Acquisition.

///A click on something out of reach. Same three arguments as on_clickon - sender, then target,
///then params - so the target here is the real atom too. Both channels agree; either will do.
/datum/kinesis_field/proc/on_ranged_click(mob/clicker, atom/target, list/params)
	if(!marking || state != KINESIS_EMPTY)
		return
	marking = FALSE
	attempt_take(target)
	return COMSIG_MOB_CLICK_CANCELED

///A click within reach, which by definition never reaches RangedAttack. Note the three
///arguments: DCS hands a proc reference the signal's sender first, so this receives the mob,
///then what was clicked,then the raw params. Declaring it with two arguments is what made every
///earlier version of this file read A as the wearer and the target as a params string.
/datum/kinesis_field/proc/on_clickon(mob/clicker, atom/A, list/params)
	var/list/modifiers = params2list(params)
	//Throw and put down are checked before arming. Otherwise a right click while the marker was
	//armed grabbed whatever was under the cursor instead of throwing what was already held, which
	//reads as the throw being broken rather than as a click that went to the wrong branch.
	if(state == KINESIS_HELD && modifiers["right"])
		launch()
		return COMSIG_MOB_CLICK_CANCELED
	if(state == KINESIS_HELD && modifiers["left"])
		release_grip()
		return COMSIG_MOB_CLICK_CANCELED
	if(marking)
		marking = FALSE
		attempt_take(A)
		//Nothing else calls this on a failed grab, and hiding lives in update_tether. Without this
		//line the highlight only cleared once the player happened to trigger something else - press
		//R again, move far enough - which is exactly how it looked stuck on.
		update_tether()
		return COMSIG_MOB_CLICK_CANCELED

///Takes the target if the rules allow it, and says so plainly when they do not.
/datum/kinesis_field/proc/attempt_take(atom/target)
	var/atom/movable/wanted = target
	if(isnull(wanted))
		user.balloon_alert(user, "No target.")
		return FALSE
	if(!take_target(wanted))
		user.balloon_alert(user, "Refused: " + last_refusal + ".")
		return FALSE
	return TRUE

///Arms or disarms the marker. While armed the next map click is what gets taken, so the wearer
///chooses the object rather than the field grabbing whatever was closest. With something already
///held, the same key puts it down, which is the quickest way out of a hold.
/datum/kinesis_field/proc/toggle_marker()
	if(state != KINESIS_EMPTY)
		return release_grip()
	marking = !marking
	update_tether()
	if(marking)
		user.balloon_alert(user, "Marking: click what to take.")
	else
		user.balloon_alert(user, "Marker off.")

///What may be taken at all. Live mobs are refused and corpses allowed, exactly as in DS13, where
///a heavy body is picked up but is useless offensively because force divides by mass.
/datum/kinesis_field/proc/can_grip(atom/target)
	last_refusal = null
	//A click on bare floor arrives as the turf, not as an atom, and /turf has no anchored var -
	//reading it threw "undefined variable /turf/.../var/anchored" on every empty click. Turfs are
	//never grippable, so refusing them here is both correct and cheaper than casting later.
	if(!istype(target, /atom/movable))
		last_refusal = "not an object"
		return FALSE
	var/atom/movable/grabbable = target
	if(isnull(grabbable))
		last_refusal = "nothing"
		return FALSE
	//The field cannot close its own fist on the wearer. can_grip runs on whatever was clicked, and a
	//click that lands on your own sprite hands over you - which parked the wearer mid-stride, and a
	//field holding its own user is not a thing any of the rest of this can survive.
	if(grabbable == user)
		last_refusal = "yourself"
		user.balloon_alert(user, "Not yourself.")
		return FALSE
	//Vehicles can have a separate hitbox object which is not part of the vehicle's loc
	//contents. Parking the vehicle while the field follows the cursor would leave that
	//hitbox at the old position, allowing the vehicle to be used as a teleport anchor.
	//They also carry occupants, so never let the kinesis field take a vehicle at all.
	if(istype(grabbable, /obj/vehicle))
		last_refusal = "vehicle"
		return FALSE
	//A crate is a /obj/structure and every /obj/structure is anchored by default (structures.dm:4),
	//so the plain anchored refusal below threw crates out along with walls - and both of those paths
	//begin /obj/structure/, which is why they read as the same sort of thing at a glance. What
	//actually separates them is not the name but whether it can be unbolted, so that is the test.
	//Tanks and the big crate came in with the tanks and the cargo: all loose, all heavy, all bolted
	//to the floor, and all worth dragging rather than walking around.
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
	//No people. It worked, and it was removed on purpose: a field that can pick up a human will pick
	//up a human, including the one holding it, including the ones it should not have, and every one
	//of those is a thing that has to be handled specially rather than a thing that should be
	//possible. Corpses are a different matter and still allowed - a body is cargo.
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
	//Line of sight is drawn to a tile BESIDE the target, not to the tile the target is on. A dense
	//thing blocks the tile it stands on, so a closed crate blocks the sight line to itself and
	//check_path refused it every time - "no line" on a crate standing against the wall next to you.
	//Open the crate and it stops being dense, which is why it suddenly became grabbable and then
	//fell apart on everything else. A hand reaching for a crate reaches at the space beside it.
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

///Take it by the ordinary pickup path, then hand it to the graphic. The pickup is the important
///part: it is the one route by which the game guarantees the object is a real, reachable thing,
///so it cannot end up half in the map and half in the field.
///Which price bracket the field is holding something in. Read by cost_of and refund_of, and kept in
///one place so the numbers can be argued about in a single spot rather than hunted for in a proc.
/datum/kinesis_field/proc/tier_of(atom/target)
	if(istype(target, /mob/living))
		return KINESIS_TIER_BODY
	if(istype(target, /obj/structure/closet/crate) || istype(target, /obj/structure/closet))
		return KINESIS_TIER_CRATE
	return KINESIS_TIER_SMALL

///Charge to take something of this bracket, and to throw it again. A body has no throw price
///because a body is never thrown - it is set down, which costs nothing further.
/datum/kinesis_field/proc/cost_of(atom/target, throwing = FALSE)
	switch(tier_of(target))
		if(KINESIS_TIER_BODY)
			return throwing ? 0 : CHARGE_BODY
		if(KINESIS_TIER_CRATE)
			return throwing ? THROW_CRATE : CHARGE_CRATE
	return throwing ? THROW_SMALL : CHARGE_SMALL

///Drains the reserve, refusing when there is not enough left. One place decides whether an action is
///affordable, so a throw can never cost more than the grab it came from by accident.
/datum/kinesis_field/proc/spend(amount)
	if(amount <= 0)
		return TRUE
	if(charge < amount)
		user.balloon_alert(user, "The field is out of charge.")
		last_refusal = "no charge"
		return FALSE
	charge -= amount
	//The clock is pushed out on every spend, so the reserve refills from the moment the wearer stops
	//spending it rather than while he is in the middle of spending it. Without this the field would
	//quietly pay back the cost of a grab in the same second, and the whole balancing exercise would
	//be decorative. This is what last_use does for /obj/item/cell's self_recharge.
	last_charge_tick = world.time
	//Drawn here rather than left to the next mouse event: the mouse may well be resting still, and
	//a bar that only moved when the pointer did would sit on a quarter long after the reserve was
	//below it. The wearer has to be able to spend their last charge and see it go to zero.
	refresh_charge_hud()
	return TRUE

///Pushes the reserve onto the bar, if the gauntlets are still showing one.
/datum/kinesis_field/proc/refresh_charge_hud()
	set waitfor = FALSE
	if(isnull(gauntlets))
		return
	var/mob/living/carbon/human/wearer_now = user
	if(!istype(wearer_now))
		return
	wearer_now.kinesis_hud_set_charge(charge, max_charge)

///Charged on take and again on throw. The second cost is what stops a field being a free telekinetic
///tractor: without it you could pick something up for fifty and fling it for nothing, and the reserve
///would be an ornament.
/datum/kinesis_field/proc/take_target(atom/target)
	if(state != KINESIS_EMPTY)
		return FALSE
	var/atom/movable/wanted = target
	if(isnull(wanted))
		last_refusal = "nothing"
		return FALSE
	if(!can_grip(wanted))
		return FALSE
	//Both hands, not the active hand index. This used to be if(user.hand), which is mob_defines.dm:34
	//and is simply which hand is active - 0 before the first swap and 1 or 2 after, permanently.
	//So the field reported "your hands are full" on every grab for the rest of the round the moment
	//the wearer picked anything up, hands empty or not. get_held_items() is inventory.dm:405 and
	//answers the question that was actually being asked.
	if(length(user.get_held_items()))
		last_refusal = "hands full"
		user.balloon_alert(user, "Your hands are full.")
		return FALSE
	if(!spend(cost_of(wanted)))
		return FALSE
	//An item goes through a real hand slot, which is what guarantees it is a genuine reachable thing and
	//not a conjured copy. Anything else cannot: put_in_active_hand ends in do_pickup_animation, which
	//only exists on /obj/item, so a person or a crate threw "undefined proc or verb
	//.../do_pickup_animation" five times in one round. Those go straight out of the world instead and
	//are stood in for by the graphic, same as before.
	if(istype(wanted, /obj/item))
		user.put_in_active_hand(wanted)
		//A picked-up item's loc is the carrier, so this is the same check the engine itself uses.
		if(wanted.loc != user)
			last_refusal = "pickup refused"
			user.balloon_alert(user, "The field cannot reach it.")
			return FALSE
	else
		//A crate cannot be moved at all until it is unbolted, and a structure left anchored is a
		//crate still standing in the corridor with a grip held on nothing. Keep objects on the map:
		//the real structure must carry its collision and interaction procs while the holo moves.
		var/obj/structure/loose_thing = wanted
		if(istype(loose_thing, /obj/structure))
			loose_thing.anchored = FALSE
		if(!istype(wanted, /obj))
			wanted.loc = null
	become_holo(wanted)
	playsound(get_turf(user), 'sound/effects/telekinesis/kinesis_grab.ogg', 20, 1)
	to_chat(user, span_notice("You take hold of [wanted] with the field."))
	return TRUE

///Hands the object to the graphic, which parks it out of the world and stands in for it.
///
///Order matters and was the cause of objects vanishing on the first throw: the item must come
///out of the wearer's hand *before* the graphic hides it. Done the other way round the item is
///already locless when the inventory proc reaches for it, and then throw_at has no starting turf
///to walk away from, so the object is simply lost.
/datum/kinesis_field/proc/become_holo(atom/movable/thing)
	//Only an item is taken out of a hand this way, and only if it is in one. temporarilyRemoveItemFromInventory
	//runs UnEquip, which calls dropped() on the thing - a proc only /obj/item has - so pointing the
	//field at a person threw "undefined proc or verb .../dropped()". That aborted this proc one line
	//early: the charge had already been spent, the person was already parked, and no graphic was ever
	//made. A crate did exactly the same. Both are already out of the world by this point.
	if(istype(thing, /obj/item) && thing.loc == user)
		user.temporarilyRemoveItemFromInventory(thing)
	holo = new /obj/effect/kinesis_holo(get_turf(user), thing)
	subject = thing
	state = KINESIS_HELD
	//Place the real object immediately, not only on the next mouse event. This prevents the
	//first grab from leaving a structure's collision at the pickup tile while its holo is elsewhere.
	update_holo()
	//The object is a real atom again, so it can be hit. Losing it to a shot is the whole point of
	//putting it back in the world rather than parking it out.
	//
	//A poll on obj_integrity was the alternative and is worse: it only runs when something else
	//already ticked, which means standing still and shooting yourself would not drop anything until
	//the next mouse move. A signal is immediate.
	//
	//UnregisterSignal in this codebase is destructive - code/datums/signals.dm:84 keeps only one
	//entry per signal and drops the rest - so this is torn down again on release. Nothing else in
	//the codebase listens to COMSIG_ATOM_BULLET_ACT on an item, which is the only thing making that
	//safe.
	RegisterSignal(thing, COMSIG_ATOM_BULLET_ACT, PROC_REF(on_carried_bullet_act))
	//And the same for the object being deleted outright, which is how a grenade goes off. Its
	//appearance was already baked into the graphic by make_appearance, so when the real atom dies
	//the graphic keeps drawing a grenade that no longer exists - it exploded, damaged everything,
	//and then hung in the air as a ghost. Nothing unregisters here because the object is already
	//going away.
	RegisterSignal(thing, COMSIG_QDELETING, PROC_REF(on_carried_qdeleting))

///The carried object is being deleted, so there is nothing left to hold. The graphic goes with it
///rather than outliving it.
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

///The wearer moved or turned, so the graphic goes back in front of them.
/datum/kinesis_field/proc/on_wearer_shifted()
	update_holo()

// Releasing.

///Throw it along the gaze. The only time the real object moves under power, and a plain
///throw_at, so nothing can be dragged through a wall on the way there.
/datum/kinesis_field/proc/launch()
	if(state != KINESIS_HELD)
		return FALSE
	//The tether points at the graphic and take_back() deletes it. Left drawing, the beam keeps
	//aiming at a deleted atom and a second beam ends up left on the map.
	clear_tether()
	var/atom/movable/flung = take_back()
	if(isnull(flung))
		return FALSE
	//Charged here rather than on the grab, so the cost follows the object and not whatever happens
	//to be in hand. A body costs nothing to throw because a body cannot be thrown; set_one down is
	//not a throw and does not go through here.
	if(!spend(cost_of(flung, TRUE)))
		//Put it back rather than losing it: the grip is still open, the reserve simply will not
		//stretch to a fling.
		become_holo(flung)
		return FALSE
	//The object has been parked out of the world while held, so it has no turf of its own.
	//throw_at walks the object tile by tile from its current loc, and with no loc there is
	//nowhere to walk from - the object is destroyed instead of thrown. Give it the wearer's
	//turf first so the throw has a real starting point.
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

///Put it down at the wearer's feet, on the first nearby tile something can actually be placed on
///- a held crate should never end up inside a wall or in a doorway.
/datum/kinesis_field/proc/release_grip()
	if(state != KINESIS_HELD)
		return FALSE
	//Not the tile the wearer is standing on. A dead body is stripped and cleaned up, and anything
	//left lying on it goes with it, which is how the object was annihilated rather than dropped when
	//the field let go on death. The graphic's own tile is where the player was last holding it, and
	//it is also where the cursor was, which is the honest place to let go of it.
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
	//Nothing is held any more, so the tether has to be torn down now. Without this it kept drawing
	//towards the object that had just been set down until the cursor moved far enough to run
	//update_tether, which looked like the object was still being held.
	update_tether()
	return TRUE

///Pulls the real object back out from behind the graphic. The graphic's own reference is cleared
///first: Destroy hands the object back to wherever the graphic was standing, and since QDEL is
///deferred to the end of the frame that would otherwise run after this proc placed the object and
///drag it off again. That was the ghosting bug.
/datum/kinesis_field/proc/take_back()
	var/atom/movable/real
	if(!isnull(holo))
		real = holo.stored
		if(!isnull(real))
			UnregisterSignal(real, COMSIG_ATOM_BULLET_ACT)
		real = holo.stored
		//hand_back restores alpha and density before the reference is dropped, which matters now
		//that the object is a live atom on the map: a grenade left at alpha 0 would arm and vanish
		//again the next time it was picked up.
		holo.hand_back(get_turf(user))
		QDEL_NULL(holo)
	else
		real = subject
	subject = null
	state = KINESIS_EMPTY
	return real

///Used when the gauntlets switch off. The object is put back on the map rather than deleted, so
///switching the field off never eats whatever was in it.
///Used when the gauntlets switch off. The object is put back on the map rather than deleted, so
///switching the field off never eats whatever was in it.
///Tops the reserve up on a tick, so it comes back whether the gauntlets are switched on, switched
///off, or being worn by someone face down in a corridor. Nothing here runs every tick: the first
///two comparisons return long before any work happens, which is the same shape as
////obj/item/cell's self_recharge (power_cells.dm:52) behind its own charge_delay gate.
///
///No /proc/ on this definition. That keyword declares a NEW procedure, and declaring one that a
///parent already has is exactly what the compiler calls a duplicate. Overriding an inherited
///procedure means leaving /proc/ off, which is what /obj/item/cell/process() does four hundred
///lines away in this same codebase. Every earlier attempt here kept the keyword and was therefore
///never an override at all.
///
///Deliberately does not return ..(). The parent returns PROCESS_KILL, and the subsystem reads that
///as stop processing me forever - a field that recharged once and then never again.
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
	//A marine on the floor does not recharge his own gloves. Only the unworn rate keeps running
	//while he is down, and that is what stops a field emptied and then dropped from coming back
	//whole the instant something shakes him loose.
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
	//Refilled here, not on switch-off in the gloves, so it happens exactly once however the field is
	//torn down - unequipped, dropped, or the gauntlets switched off. A cell that recharged on both
	//paths would quietly refill twice, which is the sort of thing nobody notices until a balance
	//argument turns out to be wrong.
	if(!passive_charge)
		charge = max_charge
	refresh_charge_hud()

// The held graphic.

//Whether the field can hold an object on [wanted_tile] at all: the tile has to be free, and the wearer
//has to be able to see it. The second half is the part that was missing - forceMove puts an atom
//wherever it is told, with no opinion about walls, so the carried object was sliding through them.
//Named destination rather than to, which DM reserves.
/datum/kinesis_field/proc/reachable(turf/from, turf/destination)
	if(!isturf(from) || !isturf(destination))
		return FALSE
	if(destination == from)
		return TRUE
	//is_blocked_turf() cannot exclude the carried structure, which is intentionally still dense.
	//Check the tile locally so the object's own collision does not make every destination look blocked.
	if(destination.density)
		return FALSE
	for(var/atom/destination_occupant in destination)
		if(destination_occupant != holo?.stored && destination_occupant.density)
			return FALSE
	//Opacity as well as density. check_path bottoms out in LinkBlocked (unsorted.dm:179), which
	//only ever asks whether a tile is dense, and glass is see-through and not dense, so it went
	//straight through. You can see a window and still not swing a crate through it, so sight is not
	//reach.
	if(destination.opacity)
		return FALSE
	//What is standing on that tile decides it, and so does what the field is carrying. is_blocked_turf
	//answers "is this tile blocked" with one blunt yes for anything dense on it, which put tables and
	//chairs in the way of everything - a grenade can be held over a desk, a crate cannot be shoved
	//through one. Items have their density disabled while held; structures keep theirs active so their
	//collision and projectile handlers remain live.
	for(var/atom/occupant in destination)
		if(!occupant.density)
			continue
		//The carried structure is still on the map so its collision and interaction procs remain
		//active. It must not block the destination against itself while following the holo.
		if(occupant == holo?.stored)
			continue
		//Bolted to the floor or tied to the map: nothing goes through it. Narrowed through a typed
		//variable because /atom has no anchored var at all, and DM will not read a property off an
		//untyped one no matter what istype said a line earlier.
		var/atom/movable/fixture = occupant
		if(istype(fixture) && fixture.anchored)
			return FALSE
		if(!isnull(holo?.stored_density) && holo.stored_density)
			return FALSE
	//The carried structure is deliberately dense. Temporarily ignore only that atom while checking
	//the route; leaving it dense for the actual move preserves collision at its new position.
	var/obj/carried_object = holo?.stored
	var/old_carried_density = carried_object?.density
	if(carried_object)
		carried_object.density = FALSE
	var/path_result = check_path(from, destination, PASS_THROW)
	if(carried_object)
		carried_object.density = old_carried_density
	if(path_result != destination)
		return FALSE
	return TRUE

/datum/kinesis_field/proc/update_holo()
	if(isnull(holo))
		return
	//Knocked down, stunned, or dead: the grip does not survive any of them, whatever did it. A
	//xenomorph charge, a crusher, a defender - all shove the wearer over on the way through.
	//
	//incapacitated() is not enough on its own. code/modules/mob/mob_helpers.dm:366 defines it as
	//stat plus restrained(), and a knockdown is neither - it is lying_angle, which is exactly what
	//the xenomorph code itself tests for at charge_crush.dm:191. Checking only incapacitated() is why
	//being run over left the object hanging in the air.
	if(user.incapacitated() || user.lying_angle)
		release_grip()
		return
	var/turf/here = get_turf(user)
	if(!isturf(here))
		return
	//How far the graphic may be held from the wearer. Separate from drop_range on purpose: how far you
	//can hold something and how far you can throw it are different questions, and sharing one
	//number meant loosening the throw to give the grip room.
	var/grip_range = 2
	var/turf/wanted = aimed
	if(!isturf(wanted))
		wanted = turf_ahead()
	if(!isturf(wanted))
		return
	//Leash, by walking the tile back towards the wearer rather than scaling a vector. grip_range
	//is two tiles, so this is never more than a couple of steps.
	while(get_dist(here, wanted) > grip_range)
		wanted = get_step_towards(wanted, here)
	var/turf/seat = wanted
	var/turf/was = holo.loc
	//Collision is only worth working out when the object would actually change tile. check_path calls
	//get_line (math.dm:10), which builds a list and walks it a tile at a time, and this proc runs on
	//every single mouse event - so spinning the mouse meant hundreds of list allocations a second and
	//the server's tick budget went with it. Between tile crossings, which is the overwhelming
	//majority of events, there is nothing to collide with and this is now only a couple of reads.
	//
	//Hold position when the tile cannot be had. Sliding a step towards it every frame is right while a
	//wall is merely in the way, but when the tile is unreachable altogether every step is still
	//closer, and the object walked across the whole map towards somewhere it could never arrive.
	if(seat != holo.loc && !reachable(here, seat))
		seat = isturf(was) ? was : here
	if(holo.loc != seat)
		holo.forceMove(seat)
	//The object is a real atom again rather than something parked out of the world, so it has to
	//be carried along with the graphic.
	holo.carry_to(seat)
	//Whatever is left over after choosing the tile is the sprite's offset within it.

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

///Where a throw goes: along the gaze, never further than drop_range.
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
	//No cursor reading yet, so fall back to the old gaze walk rather than refusing to throw.
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

///Where an object put down from [from] should actually land.
///
///The graphic follows the cursor and the leash does not care about walls, so it can easily be
///sitting inside one - and putting a crate into a wall looks like the field ignoring geometry
///entirely. This walks outwards from where the object was, and among the tiles it finds prefers
///the ones furthest from the wearer: if the grip was pressed against a wall the object ends up
///beyond the player or above or below rather than wedged between them and the wall. Only if
///nothing within two tiles can take it does it fall back to the wearer, which covers a player who
///is genuinely walled in.
/datum/kinesis_field/proc/placeable_for(turf/from)
	var/turf/here = get_turf(user)
	if(!isturf(from))
		return nearest_free_turf()
	//The same test the carried object is held to, not merely "is this tile free". Asking only
	//is_blocked_turf meant any ordinary floor passed, and the far side of a wall is an ordinary
	//floor - which is how an item could still be put down through masonry. Placement and carrying
	//have to agree about what is reachable, so they call the same proc.
	if(reachable(here, from))
		return from
	if(!isturf(here))
		return null
	//Searched in preference order and returned immediately. Building the whole ring into a list and
	//sorting it for "furthest from the wearer" was forty-odd probes plus a sort, running synchronously
	//inside the death signal - which is what the micro freeze at death turned out to be. Tiles are
	//tried far before near so the object lands beyond the player or above or below rather than
	//wedged between them and the wall, and each is checked once.
	for(var/ring in 2 to 1 step -1)
		for(var/dx in -ring to ring)
			for(var/dy in -ring to ring)
				if(abs(dx) != ring && abs(dy) != ring)
					continue
				var/turf/probe = get_offset_target_turf(from, dx, dy)
				if(!isturf(probe) || probe == here)
					continue
				//reachable rather than is_blocked_turf, for the same reason: searching outwards from a
				//point on the far side of a wall would otherwise walk further away from the wearer,
				//never nearer.
				if(reachable(here, probe))
					return probe
	return nearest_free_turf()

///The first tile at or beside the wearer that something can actually be placed on. Ring 0 is the
///wearer's own tile, so an occupied spot walks outwards from there rather than sitting on the player.
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
				//Also sight-tested, or the fallback would put the object behind the player through the
				//wall their back is against.
				if(reachable(here, probe))
					return probe
	return here

///A tile that is not closed, not dense, and not already holding something dense. Superseded by
///TGMC's /proc/is_blocked_turf, which also counts anchored dense atoms; kept only because nothing
///else calls it and a thinner duplicate is one less thing to keep in step.
/proc/probe_can_place(turf/probe)
	if(isnull(probe) || probe.density)
		return FALSE
	for(var/obj/occupant in probe)
		if(istype(occupant, /atom/movable) && !occupant.anchored && occupant.density)
			return FALSE
	return TRUE

///A clear line from the wearer to the target. IS_OPAQUE_TURF is what the codebase uses to decide
///whether a tile blocks sight, which covers glass and grilles the way DS13's own pass_flags check
///did. Z stays at the wearer's level: the field should not reach through a deck.
/datum/kinesis_field/proc/has_clear_path(turf/source, turf/destination)
	if(source == destination)
		return TRUE
	//TGMC's own line of sight, /proc/check_path at code/__HELPERS/unsorted.dm:1217, which walks the
	//line through LinkBlocked and gets the diagonals right.
	//
	//This replaces a hand-rolled get_step_towards loop that only tested IS_OPAQUE_TURF. Anything
	//dense but see-through - a closed door, a window frame, a grille - is not opaque, so the loop
	//walked straight through it and the field pulled objects out through walls. PASS_THROW because
	//that is exactly what this is: a thrown path, minus the throwing.
	return check_path(source, destination, PASS_THROW) == destination

///Mass, standing in for the explicit mass var of the original. w_class runs 1 to 6 with 3 being
///an ordinary item, which lines up closely enough with the original's masses for a corpse to feel
///similar under the same force.
/datum/kinesis_field/proc/subject_mass(atom/movable/thing)
	var/obj/item/massed_item = thing
	if(istype(massed_item))
		return clamp(massed_item.w_class, WEIGHT_CLASS_TINY, WEIGHT_CLASS_GIGANTIC)
	return WEIGHT_CLASS_NORMAL
