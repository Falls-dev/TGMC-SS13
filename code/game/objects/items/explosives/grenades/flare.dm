#define FLARE_FIRE_STACKS 5

/obj/item/explosive/grenade/flare
	name = "\improper M40 FLDP grenade"
	desc = "A TGMC standard issue flare utilizing the standard DP canister chassis. Capable of being loaded in any grenade launcher, or thrown by hand."
	icon_state = "flare_grenade"
	worn_icon_state = "flare_grenade"
	det_time = 0
	throwforce = 1
	dangerous = FALSE
	w_class = WEIGHT_CLASS_TINY
	hud_state = "grenade_frag"
	light_system = MOVABLE_LIGHT
	light_range = 8
	light_color = LIGHT_COLOR_FLARE
	throw_sound = null
	overlay_type = null
	groundhit_sound_is_playable = FALSE
	var/fuel = 0
	var/lower_fuel_limit = 300
	var/upper_fuel_limit = 450
	/// Tint for the greyscale flare flame
	var/flame_tint = "#ddbbbb"
	/// Color correction, added to the whole flame overlay
	var/flame_base_tint = "#ff0000"
	// "But, why are there two colors?"
	// The flame_tint is applied multiplicatively to the greyscale animation
	// However it represents levels within the flame, not the color of the flame as a whole.
	// To get around this, we additively apply flame_base_tint for coloring.

/obj/item/explosive/grenade/flare/update_icon()
	overlays?.Cut()
	. = ..()
	if(active)
		icon_state = "[initial(icon_state)]_active"
		var/image/flame = image('icons/obj/items/grenade.dmi', src, "flare_flame")
		flame.color = flame_tint
		flame.appearance_flags = KEEP_APART|RESET_COLOR|RESET_TRANSFORM
		var/image/flame_base = image('icons/obj/items/grenade.dmi', src, "flare_flame")
		flame_base.color = flame_base_tint
		flame_base.appearance_flags = KEEP_APART|RESET_COLOR
		flame_base.blend_mode = BLEND_ADD
		flame.overlays += flame_base
		overlays += flame
	else if(!active)
		icon_state = "[initial(icon_state)]_empty"
	else
		icon_state = "[initial(icon_state)]"

/obj/item/explosive/grenade/flare/dissolvability(acid_strength)
	return 2

/obj/item/explosive/grenade/flare/acid_spray_act(mob/living/carbon/xenomorph/X)
	if(!active)
		return
	turn_off()

/obj/item/explosive/grenade/flare/Initialize(mapload)
	. = ..()
	fuel = rand(lower_fuel_limit, upper_fuel_limit) // Sorry for changing this so much but I keep under-estimating how long X number of ticks last in seconds.

/obj/item/explosive/grenade/flare/fire_act(burn_level, flame_color)
	if(!fuel) //it's out of fuel, an empty shell.
		return
	if(!active)
		turn_on()

/obj/item/explosive/grenade/flare/prime()
	return

/obj/item/explosive/grenade/flare/Destroy()
	turn_off()
	return ..()

/obj/item/explosive/grenade/flare/process()
	fuel = max(fuel - 1, 0)
	if(!fuel || !active)
		turn_off()

/obj/item/explosive/grenade/flare/throw_impact(atom/hit_atom, speed)
	if(isopenturf(hit_atom))
		var/obj/alien/weeds/node/N = locate() in loc
		if(N)
			qdel(N)
			turn_off()
	. = ..()
	if(!.)
		return
	if(!active)
		return

	if(isliving(hit_atom))
		var/mob/living/living_target = hit_atom
		living_target.fire_stacks += FLARE_FIRE_STACKS
		living_target.IgniteMob()

		var/target_zone = check_zone(living_target.zone_selected)
		if(!target_zone || rand(40))
			target_zone = "chest"
		if(launched && CHECK_BITFIELD(resistance_flags, ON_FIRE) && !living_target.on_fire)
			living_target.apply_damage(randfloat(throwforce * 0.75, throwforce * 1.25), BURN, target_zone, FIRE, updating_health = TRUE) //Do more damage if launched from a proper launcher and active

/obj/item/explosive/grenade/flare/attack_self(mob/user)
	if(!fuel)
		to_chat(user, span_notice("It's out of fuel."))
		return
	if(active)
		return

	user.visible_message(span_notice("[user] activates the flare."), span_notice("You depress the ignition button, activating it!"))
	turn_on(user)

/obj/item/explosive/grenade/flare/activate(mob/user)
	if(!active)
		turn_on(user)


///Shuts the flare off
/obj/item/explosive/grenade/flare/proc/turn_off()
	active = FALSE
	fuel = 0
	heat = 0
	force = initial(force)
	damtype = initial(damtype)
	update_icon()
	set_light_on(FALSE)
	STOP_PROCESSING(SSobj, src)

///Activates the flare
/obj/item/explosive/grenade/flare/proc/turn_on()
	active = TRUE
	force = 5
	throwforce = 10
	ENABLE_BITFIELD(resistance_flags, ON_FIRE)
	heat = 1500
	damtype = BURN
	update_icon()
	set_light_on(TRUE)
	playsound(src,'sound/items/flare.ogg', 15, 1)
	START_PROCESSING(SSobj, src)

/obj/item/explosive/grenade/flare/animation_spin(speed = 5, loop_amount = -1, clockwise = TRUE, sections = 3, anim_flags = NONE, angular_offset = 0, pixel_fuzz = 0)
	clockwise = pick(TRUE, FALSE)
	angular_offset = rand(360)
	pixel_fuzz = 16
	return ..(speed, loop_amount, clockwise, sections, anim_flags, angular_offset, pixel_fuzz)

/obj/item/explosive/grenade/flare/pickup()
	if(transform)
		apply_transform(matrix()) // reset rotation
	pixel_x = 0
	pixel_y = 0
	return ..()

//Starts on
/obj/item/explosive/grenade/flare/on/Initialize(mapload)
	. = ..()
	turn_on()

/obj/item/explosive/grenade/flare/civilian
	name = "flare"
	desc = "A NT standard emergency flare. There are instructions on the side, it reads 'pull cord, make light'."
	icon_state = "flare"
	worn_icon_state = "flare"

/obj/item/explosive/grenade/flare/cas
	name = "\improper M50 CFDP signal flare"
	desc = "A TGMC signal flare utilizing the standard DP canister chassis. Capable of being loaded in any grenade launcher, or thrown by hand. When activated, provides a target for CAS pilots."
	icon_state = "cas_flare_grenade"
	worn_icon_state = "cas_flare_grenade"
	hud_state = "grenade_frag"
	lower_fuel_limit = 25
	upper_fuel_limit = 30
	light_power = 5
	light_color = LIGHT_COLOR_GREEN
	var/datum/squad/user_squad
	var/obj/effect/overlay/temp/laser_target/cas/target
	flame_base_tint = "#00aa00"
	flame_tint = "#aaccaa"

/obj/item/explosive/grenade/flare/cas/turn_on(mob/living/carbon/human/user)
	. = ..()
	if(user.assigned_squad)
		user_squad = user.assigned_squad
	var/turf/TU = get_turf(src)
	if(!istype(TU))
		return
	if(is_ground_level(TU.z))
		target = new(src, null, name, user_squad)//da lazer is stored in the grenade

/obj/item/explosive/grenade/flare/cas/process()
	. = ..()
	var/turf/TU = get_turf(src)
	if(is_ground_level(TU.z))
		if(!target && active)
			target = new(src, null, name, user_squad)

/obj/item/explosive/grenade/flare/cas/turn_off()
	QDEL_NULL(target)
	return ..()

///Flares that the tadpole flare launcher launches
/obj/item/explosive/grenade/flare/strongerflare
	lower_fuel_limit = 10
	upper_fuel_limit = 20
	light_system = STATIC_LIGHT//movable light has a max range
	light_color = LIGHT_COLOR_CYAN
	light_range = 12
	flame_base_tint = "#7de1e1"
	flame_tint = "#acd8d8"

/obj/item/explosive/grenade/flare/strongerflare/throw_impact(atom/hit_atom, speed)
	. = ..()
	if(!.)
		return
	anchored = TRUE//prevents marines from picking up and running around with a stronger flare

/obj/item/explosive/grenade/flare/strongerflare/turn_off()
	. = ..()
	set_light(0)
