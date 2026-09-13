/*
Doesn't do anything or hold anything anymore.
Generated per the various mags, and then changed based on the number of
casings. .dir is the main thing that controls the icon. It modifies
the icon_state to look like more casings are hitting the ground.
There are 8 directions, 8 bullets are possible so after that it tries to grab the next
icon_state while reseting the direction. After 16 casings, it just ignores new
ones. At that point there are too many anyway. Shells and bullets leave different
items, so they do not intersect. This is far more efficient than using Blend() or
Turn() or Shift() as there is virtually no overhead. ~N
*/
/obj/item/ammo_casing
	name = "spent casing"
	desc = "Empty and useless now."
	icon = 'icons/obj/items/casings.dmi'
	icon_state = "cartridge_1"
	throwforce = 1
	w_class = WEIGHT_CLASS_TINY
	layer = LOW_ITEM_LAYER //Below other objects
	dir = 1 //Always north when it spawns.
	atom_flags = CONDUCT|DIRLOCK
	var/casing_lifetime = 55 SECONDS
	var/max_casings_on_tile = 40

/obj/item/ammo_casing/Initialize(mapload, shot_dir)
	. = ..()
	if(!shot_dir)
		shot_dir = dir || pick(GLOB.cardinals)
	INVOKE_ASYNC(src, PROC_REF(spawn_casing_animation), shot_dir)
	limit_casings()
	addtimer(CALLBACK(src, PROC_REF(fade_and_del)), casing_lifetime)

/obj/item/ammo_casing/proc/spawn_casing_animation(shot_dir)
	var/offset_x = rand(-16,16)
	var/offset_y = rand(-16,16)
	pixel_x += rand(-3,3)
	pixel_y += rand(0,5)
	animate(
		src,
		pixel_z = rand(12,20),
		transform = turn(matrix(), rand(-180,180)),
		time = 2,
		easing = EASE_OUT
	)
	sleep(2)
	animate(
		src,
		pixel_z = 0,
		pixel_x = pixel_x + offset_x,
		pixel_y = pixel_y + offset_y,
		transform = turn(matrix(), rand(-360,360)),
		time = 5,
		easing = EASE_IN
	)

/obj/item/ammo_casing/proc/limit_casings()
	var/list/casings = list()
	for(var/obj/item/ammo_casing/C in loc)
		casings += C
	if(casings.len > max_casings_on_tile)
		var/obj/item/ammo_casing/oldest = casings[1]
		if(oldest != src)
			qdel(oldest)

/obj/item/ammo_casing/proc/fade_and_del()
	if(QDELETED(src))
		return
	animate(
		src,
		alpha = 0,
		time = 5
	)
	QDEL_IN(src, 5)

/obj/item/ammo_casing/attack_hand(mob/user)
	return

/obj/item/ammo_casing/bullet

/obj/item/ammo_casing/cartridge
	name = "spent cartridge"
	icon_state = "cartridge"

/obj/item/ammo_casing/shell
	name = "spent shell"
	icon_state = "shell"
