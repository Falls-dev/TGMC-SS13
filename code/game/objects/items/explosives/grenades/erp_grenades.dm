/obj/structure/closet/secure_closet/xeno_cage
	name = "NTC specialised containment cage"
	desc = "A secure container designed to contain dangerous lifeforms such as xenomorphs. It will heal whatever comes in it out of critical but does not stasis."
	icon_state = "xeno_cage_locked"
	icon_closed = "xeno_cage"
	icon_locked = "xeno_cage_locked"
	icon_broken = "xeno_cage_damage"
	icon_off = "xeno_cage"
	icon_opened = "xeno_cage_open"
	max_integrity = 500
	icon = 'icons/obj/structures/xeno_cage.dmi'
	max_mob_size = MOB_SIZE_BIG
	drag_delay = 0 //wheels yay
	anchored = FALSE

/obj/structure/closet/secure_closet/xeno_cage/attack_generic(mob/user, damage_amount, damage_type, armor_type, effects, armor_penetration)
	if(user.loc == src)
		visible_message("[user] bangs uselessly on the inside of [src]!")
		return 0
	. = ..()

/obj/structure/closet/secure_closet/xeno_cage/attackby(obj/item/I, mob/user, params)
	if(user.loc == src)
		visible_message("[user] bangs uselessly on the inside of [src] with [I]!")
		return TRUE
	. = ..()

/obj/structure/closet/secure_closet/xeno_cage/close()
	. = ..()
	for(var/mob/living/carbon/livingthing in contents)
		if(livingthing.InCritical())
			if(!isxeno(livingthing))
				if(!(livingthing.species.species_flags & NO_CHEM_METABOLIZATION))
					livingthing.reagents.add_reagent(/datum/reagent/medicine/inaprovaline, 5)
				else if(livingthing.species.species_flags & NO_CHEM_METABOLIZATION)
					livingthing.heal_overall_damage(livingthing.get_crit_threshold()+5, livingthing.get_crit_threshold()+5, TRUE, TRUE)
			else
				livingthing.heal_overall_damage(livingthing.get_crit_threshold()+5, livingthing.get_crit_threshold()+5, FALSE, TRUE)
		livingthing.AdjustParalyzed(5 SECONDS)

/obj/structure/closet/secure_closet/xeno_cage/open()
	for(var/mob/living/carbon/livingthing in contents)
		livingthing.AdjustParalyzed(5 SECONDS)
	. = ..()

/obj/item/explosive/grenade/cagenade
	name = "CG1 widerange species capture grenade"
	icon = 'icons/obj/items/grenade.dmi'
	icon_state = "grenade_sticky_pmc"
	worn_icon_state = "grenade_sticky_pmc"
	desc = "Unfolds into a xeno containment device when thrown, Gotta catch em all. Use on a stunned target, it does not stick and only catch things it's right on top of after the timer is up."
	hitsound = null

/obj/item/explosive/grenade/cagenade/throw_impact(atom/hit_atom, speed, bounce)
	. = ..()
	if(!QDELETED(src) && isliving(hit_atom))
		var/mob/living/captured_mob = hit_atom
		Move(captured_mob.loc) //go beneath people

/obj/item/explosive/grenade/cagenade/prime()
	var/turf/target = get_turf(src)
	if(!target)
		qdel(src)
		return
	cell_explosion(target, 30, 30)
	var/obj/structure/closet/secure_closet/xeno_cage/cage = new(target)
	cage.locked = FALSE
	cage.opened = TRUE
	cage.density = FALSE
	qdel(src)
	if(!cage.close())
		return
	cage.locked = TRUE
	cage.update_icon()
	if(length(cage.contents))
		playsound(target, 'sound/machines/ping.ogg', 25, TRUE)
	else
		playsound(target, 'sound/machines/buzz-two.ogg', 25, TRUE)

/obj/structure/closet/secure_closet/xeno_cage/MouseDrop(atom/over, src_location, over_location, src_control, over_control, params)
	. = ..()
	if(!Adjacent(usr))
		return
	if(!ishuman(usr))
		return
	if(length(contents))
		return FALSE
	if(ishuman(usr))
		if(!opened)
			to_chat(usr, span_warning("You must open [src] before packing it up"))
			return
		visible_message("[usr] begins to pack [src] up!")
		if(do_after(usr, 2 SECONDS, TRUE, src, BUSY_ICON_FRIENDLY))
			if(!opened)
				to_chat(usr, span_warning("You must open [src] before packing it up"))
				return
			var/mob/living/carbon/human/huser = usr
			var/grenade = new /obj/item/explosive/grenade/cagenade(loc)
			huser.put_in_any_hand_if_possible(grenade)
			qdel(src)
/obj/item/explosive/grenade/ionplasma
	name = "\improper M55 plasmafire grenade"
	desc = "The M55 plasmafire grenade, nickamed 'GOBLIN' has a grenade casing design similar to the M15 model but disperses ionizing plasma fire in a tight radius. This grenade is used to cut off tight bottlenecks and enforce prolonged area denial compared to the M40 HIDP incendiary grenade. It is set to detonate in 3 seconds."
	icon = 'icons/obj/items/grenade.dmi'
	icon_state = "grenade_ionplasma"
	worn_icon_state = "grenade_fire"
	hud_state = "electrothermal"
	det_time = 3 SECONDS
	icon_state_mini = "grenade_green"

/obj/item/explosive/grenade/ionplasma/prime()
	plasma_radius(1, get_turf(src))
	playsound(loc, SFX_INCENDIARY_EXPLOSION, 35)
	qdel(src)


/obj/item/explosive/grenade/ionplasma/proc/plasma_radius(radius = 1, turf/epicenter, burn_intensity = 30, burn_duration = 35, burn_damage = 20, fire_stacks = 10, colour = "green", fire_type = /obj/fire/flamer) //~Art updated fire.
	if(!epicenter)
		return
	radius = clamp(radius, 1, 50) //Sanitize inputs
	for(var/turf/turf_to_flame as anything in filled_turfs(epicenter, radius, "square", pass_flags_checked = PASS_AIR))
		var/burn_mod = iswallturf(turf_to_flame) ? 3 : 1

		turf_to_flame.ignite(randfloat(burn_duration*0.1, burn_duration), burn_intensity * burn_mod, colour, fire_stacks, burn_damage, fire_type)

		for(var/mob/living/mob_caught in turf_to_flame)
			if(mob_caught.stat == DEAD)
				continue
			mob_caught.adjust_fire_stacks(burn_damage)
			mob_caught.IgniteMob()

/obj/item/storage/box/visual/grenade/ionplasma
	name = "\improper M55 PLASFIRE grenade box"
	desc = "A secure box holding 25 M55 PLASFIRE grenades. These will burn hot with ionizing plasma, don't store near the flamer fuel."
	spawn_number = 25
	spawn_type = /obj/item/explosive/grenade/ionplasma
	closed_overlay = "grenade_box_overlay_m55"
