//halter bullpup rifle
/obj/item/weapon/gun/rifle/nt_halter
	//Abomination of AR-21, PR-412, AR-18 and MPI-KM
	name = "\improper NT 'Yadot' assault rifle"
	desc = "An NTC bullpup rifle chambered in 7.62x39mm. Named for Yadot, a decorated marine who left TerraGov after an alleged dispute with command."
	icon = 'icons/obj/items/gun/rifle64.dmi'
	icon_state = "halter"
	worn_icon_state = "halter"
	worn_icon_list = list(
		slot_l_hand_str = 'icons/mob/inhands/gun/rifle_lefthand_64.dmi',
		slot_r_hand_str = 'icons/mob/inhands/gun/rifle_righthand_64.dmi',
		slot_s_store_str = 'icons/mob/clothing/back.dmi',
		slot_back_str = 'icons/mob/clothing/back.dmi',
	)
	inhand_x_dimension = 64
	inhand_y_dimension = 32
	fire_sound = 'sound/weapons/guns/fire/famas.ogg'
	dry_fire_sound = 'sound/weapons/guns/fire/m41a_empty.ogg'
	unload_sound = 'sound/weapons/guns/interact/m41a_unload.ogg'
	reload_sound = 'sound/weapons/guns/interact/m41a_reload.ogg'
	cocked_sound = 'sound/weapons/guns/interact/m16_cocked.ogg'
	caliber = CALIBER_762X39 //codex
	max_shells = 36 //codex
	default_ammo_type = /obj/item/ammo_magazine/rifle/nt_halter
	allowed_ammo_types = list(
		/obj/item/ammo_magazine/rifle/nt_halter,
		/obj/item/ammo_magazine/rifle/nt_halter/extended,
		/obj/item/ammo_magazine/rifle/nt_halter/drum,
		/obj/item/ammo_magazine/rifle/nt_halter/charged,
		/obj/item/ammo_magazine/rifle/nt_halter/smart,
		/obj/item/ammo_magazine/rifle/nt_halter/foxfire,
		/obj/item/ammo_magazine/rifle/nt_halter/laser,
		/obj/item/ammo_magazine/rifle/nt_halter/laser/extended,
		/obj/item/ammo_magazine/rifle/nt_halter/laser/drum,
		/obj/item/ammo_magazine/rifle/nt_halter/rubber,
		/obj/item/ammo_magazine/rifle/nt_halter/rubber/extended,
	)
	attachable_allowed = list(
		/obj/item/attachable/reddot,
		/obj/item/attachable/verticalgrip,
		/obj/item/attachable/angledgrip,
		/obj/item/attachable/lasersight,
		/obj/item/attachable/gyro,
		/obj/item/attachable/flashlight,
		/obj/item/attachable/flashlight/under,
		/obj/item/attachable/foldable/bipod,
		/obj/item/attachable/magnetic_harness,
		/obj/item/attachable/extended_barrel,
		/obj/item/attachable/heavy_barrel,
		/obj/item/attachable/suppressor,
		/obj/item/attachable/bayonet/converted,
		/obj/item/attachable/bayonet,
		/obj/item/attachable/bayonetknife/som,
		/obj/item/attachable/compensator,
		/obj/item/attachable/scope,
		/obj/item/attachable/scope/marine,
		/obj/item/attachable/scope/mini,
		/obj/item/weapon/gun/pistol/plasma_pistol,
		/obj/item/weapon/gun/shotgun/combat/masterkey,
		/obj/item/weapon/gun/flamer/mini_flamer,
		/obj/item/weapon/gun/grenade_launcher/underslung,
		/obj/item/attachable/motiondetector,
		/obj/item/attachable/buildasentry,
		/obj/item/weapon/gun/rifle/pepperball/pepperball_mini,
		/obj/item/weapon/gun/flamer/hydro_cannon,
		/obj/item/attachable/shoulder_mount,
	)

	gun_features_flags = GUN_CAN_POINTBLANK|GUN_AMMO_COUNTER|GUN_SMOKE_PARTICLES
	gun_firemode_list = list(GUN_FIREMODE_AUTOMATIC) //no twink ass firemodes, like god intended
	attachable_offset = list("muzzle_x" = 51, "muzzle_y" = 19,"rail_x" = 25, "rail_y" = 23, "under_x" = 35, "under_y" = 13, "stock_x" = 0, "stock_y" = 13)
	fire_delay = 0.2 SECONDS
	burst_amount = 1
	burst_delay = 0.15 SECONDS
	wield_delay = 0.7 SECONDS
	actions_types = list(/datum/action/item_action/aim_mode)
	aim_slowdown = 0.4
	aim_fire_delay = 0.1 SECONDS
	akimbo_scatter_mod = 24
	akimbo_additional_delay = 0.8
	aim_speed_modifier = 3
	scatter = -1
	scatter_unwielded = 18
	accuracy_mult_unwielded = 0.8
	force = 20 //like mpi-km i dont see why that gets more force but yes.

/obj/item/weapon/gun/rifle/nt_halter/cqb
	//more accurate but less AP version of v34 basically without stock option since its a bullpup, it IS the stock.
	name = "\improper NT 'Yadot-CQB' carbine"
	desc = "A compact carbine based on the NT 'Yadot' rifle, named for a decorated marine who left TerraGov after an alleged dispute with command. Its shorter barrel trades range and accuracy for easier handling in close quarters. Chambered in 7.62x39mm."
	icon = 'icons/obj/items/gun/rifle64.dmi'
	attachable_offset = list("muzzle_x" = 39, "muzzle_y" = 19,"rail_x" = 19, "rail_y" = 23, "under_x" = 29, "under_y" = 13, "stock_x" = 0, "stock_y" = 13)
	icon_state = "haltercqb"
	worn_icon_state = "haltercqb"
	fire_delay = 0.15 SECONDS
	aim_fire_delay = 0.1 SECONDS
	aim_speed_modifier = 2.5
	aim_slowdown = 0.3
	scatter = 10
	scatter_unwielded = 16
	wield_delay = 0.4 SECONDS
	movement_acc_penalty_mult = 4
	damage_falloff_mult = 1.2 //its a bullpup still
	akimbo_additional_delay = 1.5
	damage_mult = 0.9
	force = 15

//standard mag
/obj/item/ammo_magazine/rifle/nt_halter
	name = "\improper NT 'Yadot' magazine (7.62x39mm)"
	desc = "A magazine filled with 7.62x39mm rifle rounds for the Yadot series of firearms."
	caliber = CALIBER_762X39
	icon_state = "halter"
	icon = 'icons/obj/items/ammo/magazine.dmi'
	bonus_overlay = "halter_mag"
	default_ammo = /datum/ammo/bullet/rifle/heavy/halter
	max_rounds = 36
	aim_speed_mod = 0.1
	wield_delay_mod = 0.1 SECONDS

/datum/ammo/bullet/rifle/heavy/halter
	name = "heavy rifle bullet"
	//same caliber as mpi km
	penetration = 15
	sundering = 1.75

//extended mag
/obj/item/ammo_magazine/rifle/nt_halter/extended
	name = "\improper NT 'Yadot' extended magazine (7.62x39mm)"
	desc = "An extended magazine filled with 7.62x39mm rifle rounds for the Yadot series of firearms."
	max_rounds = 58 //close to mpi-km roughly
	icon_state = "halter_ex"
	bonus_overlay = "halter_ex"
	scatter_mod = 1
	aim_speed_mod = 0.2
	wield_delay_mod = 0.2 SECONDS

//drum mag
/obj/item/ammo_magazine/rifle/nt_halter/drum
	name = "\improper NT 'Yadot' drum magazine (7.62x39mm)"
	desc = "A drum magazine filled with 7.62x39mm rifle rounds for the Yadot series of firearms."
	max_rounds = 80
	icon_state = "halter_drum"
	bonus_overlay = "halter_drum"
	reload_delay = 1 SECONDS
	scatter_mod = 2
	aim_speed_mod = 0.3
	wield_delay_mod = 0.3 SECONDS

//emp mag
/obj/item/ammo_magazine/rifle/nt_halter/charged
	name = "\improper NT 'Yadot' taser magazine (7.62x39mm Taser)"
	desc = "A magazine filled with specialized 7.62x39mm rifle rounds to deliver a powerful shock ontop of blunt force, for the Yadot series of firearms. This has a 15% chance per shot to deliver an EM pulse."
	icon_state = "halter_charged"
	bonus_overlay = "halter_charged"
	default_ammo = /datum/ammo/bullet/rifle/heavy/halter/charged

/datum/ammo/bullet/rifle/heavy/halter/charged
	name = "heavy shocking rifle bullet"
	hud_state = "rifle_ap"
	damage = 20
	penetration = 10
	damage_type = BRUTE
	sundering = 2
	shrapnel_chance = 2
	bullet_color = COLOR_BRIGHT_BLUE
	var/emp_chance = 15

/datum/ammo/bullet/rifle/heavy/halter/charged/on_hit_mob(mob/target_mob, atom/movable/projectile/proj)
	. = ..()
	do_sparks(3, TRUE, target_mob)
	if(!ishuman(target_mob))
		return
	var/mob/living/carbon/human/human_victim = target_mob
	if(prob(emp_chance))
		empulse(target_mob.loc, 0,0,0,1)
	if(human_victim.species.species_flags & ROBOTIC_LIMBS)
		human_victim.adjust_stamina_loss(proj.damage)
		human_victim.add_slowdown(0.2,1)
		human_victim.AdjustStun(0.1 SECONDS)
		if(human_victim.get_stamina_loss() > 20)
			human_victim.overlay_fullscreen_timer(human_victim.get_stamina_loss(), 10, "glitch", /atom/movable/screen/fullscreen/robot_glitch)
		if((human_victim.get_stamina_loss() >= human_victim.maxHealth*2) && !human_victim.IsParalyzed())
			human_victim.ParalyzeNoChain(15 SECONDS) //fake unconscious basically
			human_victim.AdjustMute(15 SECONDS)
			human_victim.overlay_fullscreen_timer(15 SECONDS, 10, "bluescreen", /atom/movable/screen/fullscreen/dead/robot)
			human_victim.visible_message(span_warning("[human_victim] shudders violently whilst spitting out error text before collapsing, flailing on the ground randomly."), span_blue("You are bluescreening, but you should be able to recover from this by rebooting automatically in about 15s."), span_notice("You hear a clanker glitching."))
	else
		human_victim.adjust_stamina_loss(proj.damage/2)
		human_victim.AdjustStun(0.1 SECONDS)
		human_victim.jitter(3)
		human_victim.add_slowdown(0.1,1)
		human_victim.visible_message(span_warning("[human_victim] shakes with an electric shock!"), span_warning("You feel lightning mess up your nerves, locking your body!"), span_notice("You hear a clanker glitching."))

//smart mag
/obj/item/ammo_magazine/rifle/nt_halter/smart
	name = "\improper NT 'Yadot' smart magazine (7.62x39mm Smart)"
	desc = "A magazine filled with specialized 7.62x39mm rifle rounds that slightly sways to avoid friendlies but loses overall power, for the Yadot series of firearms."
	icon_state = "halter_smart"
	bonus_overlay = "halter_smart"
	default_ammo = /datum/ammo/bullet/rifle/heavy/halter/smart

//this just suck so imma let it be same as regular bullets, cause its also paid and you got aim mode which is good on this.
/datum/ammo/bullet/rifle/heavy/halter/smart
	name = "smart heavy rifle bullet"
	hud_state = "rifle_ap"
	ammo_behavior_flags = AMMO_BALLISTIC|AMMO_IFF
	bullet_color = COLOR_BLUE_GRAY

//foxfire mag
/obj/item/ammo_magazine/rifle/nt_halter/foxfire
	name = "\improper NT 'Yadot' foxfire magazine (7.62x39mm AP-I)"
	desc = "A magazine filled with specialized 7.62x39mm AP-I rifle rounds that pierce armor and ignite targets, for the Yadot series of firearms."
	icon_state = "halter_foxfire"
	bonus_overlay = "halter_foxfire"
	default_ammo = /datum/ammo/bullet/rifle/heavy/ap/foxfire

/datum/ammo/bullet/rifle/heavy/ap/foxfire
	name = "armor-piercing foxfire heavy rifle bullet"
	hud_state = "rifle_ap"
	//bit less crazy than actual heavy ap
	damage = 25
	penetration = 20
	sundering = 3
	bullet_color = COLOR_RED_LIGHT
	//incendiary was too op for the rof so we make it less likely by using a weaker deflag
	///Deflagrate AOE damage
	var/deflag_damage = 10
	///Multiplier for deflagrate chance
	var/deflagrate_mult = 0.7

/datum/ammo/bullet/rifle/heavy/ap/foxfire/on_hit_mob(mob/target_mob, atom/movable/projectile/proj)
	deflagrate(target_mob, proj, deflag_damage, deflagrate_mult)


//laser mag
/obj/item/ammo_magazine/rifle/nt_halter/laser
	name = "\improper NT 'Yadot' laser magazine (7.62x39mm LE)"
	desc = "A magazine filled with specialized 7.62x39mm single shot laser emitter rounds that shoots laser bolts instead of a standard round."
	icon_state = "halter_laser"
	bonus_overlay = "halter_laser"
	default_ammo = /datum/ammo/energy/lasgun/halter

/datum/ammo/energy/lasgun/halter
	//slightly less damage than regular bullets but except laser standard sundering and bullet speed.
	name = "Yadot laser bolt"
	penetration = 15
	bullet_color = COLOR_RED_LIGHT

//extended mag
/obj/item/ammo_magazine/rifle/nt_halter/laser/extended
	name = "\improper NT 'Yadot' extended laser magazine (7.62x39mm LE)"
	desc = "An extended magazine filled with 7.62x39mm laser emitter rounds for the Yadot series of firearms."
	max_rounds = 58
	icon_state = "halter_laser_ex"
	bonus_overlay = "halter_laser_ex"
	scatter_mod = 1
	aim_speed_mod = 0.2
	wield_delay_mod = 0.2 SECONDS


//extended mag
/obj/item/ammo_magazine/rifle/nt_halter/laser/drum
	name = "\improper NT 'Yadot' drum laser magazine (7.62x39mm)"
	desc = "A drum magazine filled with 7.62x39mm laser emitter rounds for the Yadot series of firearms."
	max_rounds = 80
	icon_state = "halter_laser_drum"
	bonus_overlay = "halter_laser_drum"
	reload_delay = 1 SECONDS
	scatter_mod = 2
	aim_speed_mod = 0.3
	wield_delay_mod = 0.3 SECONDS

//rubber mags
/obj/item/ammo_magazine/rifle/nt_halter/rubber
	name = "\improper NT 'Yadot' rubber magazine (7.62x39mm rub)"
	desc = "A magazine filled with 7.62x39mm rubber rifle rounds for the Yadot series of firearms."
	icon_state = "halter_rub"
	icon = 'icons/obj/items/ammo/magazine.dmi'
	bonus_overlay = "halter_rub_mag"
	default_ammo = /datum/ammo/bullet/rifle/heavy/rubber

/datum/ammo/bullet/rifle/heavy/rubber/halter
	penetration = 15
	sundering = 1.75

/obj/item/ammo_magazine/rifle/nt_halter/rubber/extended
	name = "\improper NT 'Yadot' extended rubber magazine (7.62x39mm rub)"
	desc = "An extended magazine filled with 7.62x39mm rubber rounds for the Yadot series of firearms."
	max_rounds = 58
	icon_state = "halter_rub_ex"
	bonus_overlay = "halter_rub_ex"

//The Deferson rapid engagement rifle.
/obj/item/weapon/gun/rifle/dragoon
	name = "\improper Deferson Mk1 rapid engagement rifle"
	desc = "A compact semi-automatic rifle built for short engagements and quick repositioning. Its integral magazine feeds from stripper clips and takes proprietary 9.8x22mm cartridges with triangular cases."
	icon = 'icons/obj/items/gun/marksman64.dmi'
	icon_state = "dragoon"
	worn_icon_state = "dragoon"
	worn_worn_icon_state_slots = list(slot_back_str = "garand")
	inhand_x_dimension = 64
	inhand_y_dimension = 32
	worn_icon_list = list(
		slot_l_hand_str = 'icons/mob/inhands/gun/marksman_lefthand_64.dmi',
		slot_r_hand_str = 'icons/mob/inhands/gun/marksman_righthand_64.dmi',
	)
	fire_sound = 'sound/weapons/guns/fire/mp38_1.ogg'
	dry_fire_sound = 'sound/weapons/guns/fire/sniper_empty.ogg'
	unload_sound = 'sound/weapons/guns/interact/c99_unload.ogg'
	reload_sound = 'sound/weapons/guns/interact/ml12_reload.ogg'
	empty_sound = null
	caliber = CALIBER_98x22 //codex
	max_chamber_items = 10 //codex
	default_ammo_type = /datum/ammo/bullet/dragoon
	allowed_ammo_types = list(
		/obj/item/ammo_magazine/rifle/boltclip/dragoon,
		/obj/item/ammo_magazine/rifle/boltclip/dragoon/pox
	)
	attachable_allowed = list(
		/obj/item/attachable/magnetic_harness,
		/obj/item/attachable/suppressor/unremovable/invisible,
		/obj/item/attachable/stock/dragoon,
		/obj/item/attachable/angledgrip,
		/obj/item/attachable/verticalgrip,
		/obj/item/attachable/motiondetector,
		/obj/item/attachable/scope/mini,
		/obj/item/attachable/flashlight,
		/obj/item/attachable/foldable/bipod
	)
	starting_attachment_types = list(/obj/item/attachable/suppressor/unremovable/invisible, /obj/item/attachable/stock/dragoon)

	gun_features_flags = GUN_WIELDED_FIRING_ONLY|GUN_AMMO_COUNTER|GUN_SMOKE_PARTICLES
	reciever_flags = AMMO_RECIEVER_HANDFULS|AMMO_RECIEVER_MULTICLIP

	gun_firemode_list = list(GUN_FIREMODE_SEMIAUTO)
	attachable_offset = list("muzzle_x" = 32, "muzzle_y" = 17,"rail_x" = 22, "rail_y" = 18, "under_x" = 32, "under_y" = 14, "stock_x" = 20, "stock_y" = 14)
	actions_types = list(/datum/action/item_action/aim_mode)
	aim_fire_delay = 1.25 SECONDS

	burst_amount = 0
	fire_delay = 0.5 SECONDS
	accuracy_mult = 1.15
	accuracy_mult_unwielded = 0.75
	scatter = 0
	scatter_unwielded = 25
	recoil = 0
	recoil_unwielded = 4
	aim_slowdown = 0.60
	movement_acc_penalty_mult = 3

/datum/ammo/bullet/dragoon
	name = "exotic rifle bullet"
	damage_falloff = 0.5
	ammo_behavior_flags = AMMO_BALLISTIC|AMMO_SNIPER
	accurate_range = 20
	shell_speed = 4
	max_range = 30
	handful_amount = 4
	damage = 45
	penetration = 17.5
	sundering = 2
	accurate_range_min = 4

/datum/ammo/bullet/dragoon/flathead
	name = "flathead exotic rifle bullet"
	handful_amount = 4
	damage_type = STAMINA
	damage = 45
	penetration = 15
	sundering = 20

/datum/ammo/bullet/dragoon/pox
	name = "green-tipped exotic rifle bullet"
	damage = 30
	penetration = 10
	sundering = 3

/datum/ammo/bullet/dragoon/pox/on_hit_mob(mob/target_mob, atom/movable/projectile/proj)
	if(iscarbon(target_mob))
		var/mob/living/carbon/carbon_victim = target_mob
		carbon_victim.reagents.add_reagent(/datum/reagent/toxin/poxomelanin, 4, no_overdose = FALSE)
/datum/ammo/energy/plasma_dmr
	name = "ionized plasma bolt"
	icon_state = "overchargedlaser_green"
	hud_state = "electrothermal"
	hud_state_empty = "electrothermal_empty"
	damage = 50
	accurate_range = 11
	max_range = 22
	penetration = 7
	shell_speed = 3.5
	damage_falloff = 2
	ammo_behavior_flags = AMMO_ENERGY|AMMO_INCENDIARY|AMMO_TARGET_TURF
	bullet_color = LIGHT_COLOR_ELECTRIC_GREEN

	///Fire burn time
	var/burn_time = 15
	///Fire damage
	var/burn_damage = 10
	///Fire color
	var/fire_color = "green"

/datum/ammo/energy/plasma_dmr/proc/drop_fire(atom/target, atom/movable/projectile/proj)
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return
	var/burn_mod = 1
	if(istype(target_turf, /turf/closed/wall))
		burn_mod = 3
	target_turf.ignite(burn_time, burn_damage * burn_mod, fire_color)

	for(var/mob/living/mob_caught in target_turf)
		if(mob_caught.stat == DEAD || mob_caught == target)
			continue
		mob_caught.adjust_fire_stacks(burn_damage)
		mob_caught.IgniteMob()

/datum/ammo/energy/plasma_dmr/on_hit_turf(turf/target_turf, atom/movable/projectile/proj)
	drop_fire(target_turf, proj)

/datum/ammo/energy/plasma_dmr/on_hit_mob(mob/target_mob, atom/movable/projectile/proj)
	drop_fire(target_mob, proj)

/datum/ammo/energy/plasma_dmr/on_hit_obj(obj/target_obj, atom/movable/projectile/proj)
	drop_fire(target_obj, proj)

/datum/ammo/energy/plasma_dmr/do_at_max_range(turf/target_turf, atom/movable/projectile/proj)
	drop_fire(target_turf, proj)

//PMR-14 Plasma Marksman Rifle
/obj/item/weapon/gun/rifle/plasma_dmr
	name = "\improper PMR-14 plasma marksman rifle"
	desc = "An experimental weapon designed to set the terrain and targets on fire. It hums with power as magnetic fields coil round each other. This is the Designated Marksman Rifle variant of the series with twenty bolts and higher projectile velocity."
	icon = 'icons/obj/items/gun/energy64.dmi'
	icon_state = "lamplighter"
	worn_icon_state = "lamplighter"
	worn_worn_icon_state_slots = list(slot_back_str = "plasmarifle")
	ammo_level_icon = ""
	inhand_x_dimension = 64
	inhand_y_dimension = 32
	worn_icon_list = list(
		slot_l_hand_str = 'icons/mob/inhands/gun/energy_lefthand_64.dmi',
		slot_r_hand_str = 'icons/mob/inhands/gun/energy_righthand_64.dmi',
	)
	gun_firemode_list = list(GUN_FIREMODE_AUTOMATIC)
	caliber = CALIBER_PLASMA
	max_shots = 20
	reload_sound = 'sound/weapons/guns/interact/tp14_reload.ogg'
	fire_sound = 'sound/weapons/guns/fire/laser3.ogg'
	default_ammo_type = /obj/item/ammo_magazine/rifle/plasma_dmr
	allowed_ammo_types = list(/obj/item/ammo_magazine/rifle/plasma_dmr)
	type_of_casings = null
	attachable_offset = list("muzzle_x" = 48, "muzzle_y" = 18,"rail_x" = 25, "rail_y" = 22, "under_x" = 30, "under_y" = 15, "stock_x" = 21, "stock_y" = 17)
	attachable_allowed = list(
		/obj/item/attachable/bayonet/converted,
		/obj/item/attachable/bayonet,
		/obj/item/attachable/bayonetknife/som,
		/obj/item/attachable/reddot,
		/obj/item/attachable/verticalgrip,
		/obj/item/attachable/angledgrip,
		/obj/item/attachable/lasersight,
		/obj/item/attachable/flashlight/under,
		/obj/item/attachable/flashlight,
		/obj/item/attachable/foldable/bipod,
		/obj/item/attachable/gyro,
		/obj/item/attachable/extended_barrel,
		/obj/item/attachable/magnetic_harness,
		/obj/item/attachable/scope,
		/obj/item/attachable/scope/marine,
		/obj/item/attachable/scope/mini/dmr,
		/obj/item/attachable/motiondetector,
		/obj/item/weapon/gun/pistol/plasma_pistol,
		/obj/item/weapon/gun/shotgun/combat/masterkey,
		/obj/item/weapon/gun/flamer/mini_flamer,
		/obj/item/weapon/gun/grenade_launcher/underslung,
		/obj/item/attachable/buildasentry,
		/obj/item/weapon/gun/rifle/pepperball/pepperball_mini,
		/obj/item/weapon/gun/flamer/hydro_cannon,
		/obj/item/attachable/shoulder_mount,
	)

	muzzleflash_iconstate = "muzzle_flash_laser"
	gun_features_flags = GUN_CAN_POINTBLANK|GUN_ENERGY|GUN_AMMO_COUNTER|GUN_IS_ATTACHMENT|GUN_SMOKE_PARTICLES|GUN_SHOWS_LOADED
	reciever_flags = AMMO_RECIEVER_MAGAZINES|AMMO_RECIEVER_AUTO_EJECT|AMMO_RECIEVER_DO_NOT_EJECT_HANDFULS|AMMO_RECIEVER_CYCLE_ONLY_BEFORE_FIRE
	actions_types = list()
	wield_delay = 1.5 SECONDS
	muzzle_flash_color = COLOR_GREEN

	aim_slowdown = 0.5
	fire_delay = 1 SECONDS
	scatter_unwielded = 20
	recoil = 0
	recoil_unwielded = 2

/obj/item/ammo_magazine/rifle/plasma_dmr
	name = "\improper PMR-14 plasma cell"
	desc = "An energy cell for the PMR-14 plasma marksman rifle."
	icon = 'icons/obj/items/ammo/magazine.dmi'
	caliber = CALIBER_PLASMA
	icon_state = "lamplighter"
	max_rounds = 20
	w_class = WEIGHT_CLASS_NORMAL
	default_ammo = /datum/ammo/energy/plasma_dmr
	magazine_flags = NONE
	icon_state_mini = "mag_plasma"
/obj/item/weapon/gun/pistol/xmdivider/ntc
	name = "\improper T105 Unity revolver"
	desc = "An NTC revolver reverse-engineered from Intertech's Divider. The T105 trades burst fire for more stopping power per shot and accepts standard .357 and Foxfire rounds."
	icon = 'icons/obj/items/gun/pistol64.dmi'
	icon_state = "t105"
	worn_icon_state = "t105"
	fire_animation = null
	worn_icon_list = list(
		slot_l_hand_str = 'icons/mob/inhands/gun/pistol_lefthand_1.dmi',
		slot_r_hand_str = 'icons/mob/inhands/gun/pistol_righthand_1.dmi',
	)
	caliber = CALIBER_357 //codex
	max_shells = 6
	default_ammo_type = /obj/item/ammo_magazine/pistol/ntunity
	allowed_ammo_types = list(/obj/item/ammo_magazine/pistol/xmdivider, /obj/item/ammo_magazine/pistol/ntunity)
	force = 8
	attachable_allowed = list(
		/obj/item/attachable/bayonet/converted,
		/obj/item/attachable/flashlight,
		/obj/item/attachable/compensator,
		/obj/item/attachable/heavy_barrel,
		/obj/item/attachable/extended_barrel,
		/obj/item/attachable/lasersight,
		/obj/item/attachable/lace,
	)
	attachable_offset = list("muzzle_x" = 32, "muzzle_y" = 20, "rail_x" = 17, "rail_y" = 22, "under_x" = 29, "under_y" = 15, "stock_x" = 10, "stock_y" = 18)
	burst_amount = 1
	//gonna adjust for no burst fire.
	windup_delay = 0.2 SECONDS
	fire_delay = 0.2 SECONDS
	scatter_unwielded = 4
	scatter = 1
	damage_mult = 1.3
	gun_firemode_list = list(GUN_FIREMODE_SEMIAUTO)
	recoil = 1
	recoil_unwielded = 5
	//no red dot, holo sight instead.
	accuracy_mult_unwielded = 0.8
	accuracy_mult = 1
	aim_speed_modifier = 0.50

//XM104 cylinder placed in pistols
/obj/item/ammo_magazine/pistol/ntunity
	name = "\improper T105 Unity Foxfire cylinder (.357)"
	desc = "A T105 Unity cylinder loaded with .357 Foxfire armor-piercing incendiary rounds."
	icon = 'icons/obj/items/ammo/pistol.dmi'
	default_ammo = /datum/ammo/bullet/revolver/heavy/foxfire
	max_rounds = 6
	caliber = CALIBER_357
	icon_state = "t105"
	icon_state_mini = "mag_pistol"
	bonus_overlay = "t105_fox"

/datum/ammo/bullet/revolver/heavy/foxfire
	name = "armor-piercing foxfire heavy revolver bullet"
	handful_amount = 6
	damage = 50
	penetration = 15
	sundering = 5
	ammo_behavior_flags = AMMO_INCENDIARY|AMMO_BALLISTIC

/datum/ammo/bullet/revolver/heavy/foxfire/on_hit_mob(mob/target_mob, atom/movable/projectile/proj)
    if(ishuman(target_mob))
        staggerstun(target_mob, proj, paralyze = 0, stun = 0, stagger = 1 SECONDS, slowdown = 1, knockback = 1)
    else
        staggerstun(target_mob, proj, paralyze = 1 SECONDS, stagger = 1 SECONDS, slowdown = 1, knockback = 1)

//NT-VORTEX

/obj/item/weapon/gun/smg/vortex
	name = "\improper Appolo submachine gun"
	desc = "A pirate-made submachine gun cobbled together from a Vector and converted to electromagnetic operation. Takes 9x19mm magazines and heats up under sustained fire. Use the unique action to unfold it before firing."
	icon_state = "vortex"
	icon = 'icons/obj/items/gun/submachinegun64.dmi'
	worn_icon_list = list(
		slot_l_hand_str = 'icons/mob/inhands/gun/submachinegun_lefthand_1.dmi',
		slot_r_hand_str = 'icons/mob/inhands/gun/submachinegun_righthand_1.dmi',
	)
	worn_icon_state = "vortex"
	worn_worn_icon_state_slots = list(slot_back_str = "v21")
	caliber = CALIBER_9X19
	max_shells = 60
	w_class = WEIGHT_CLASS_NORMAL
	equip_slot_flags = ITEM_SLOT_BACK
	type_of_casings = null
	default_ammo_type = /obj/item/ammo_magazine/smg/vortex
	allowed_ammo_types = list(
		/obj/item/ammo_magazine/smg/vortex,
		/obj/item/ammo_magazine/smg/vortex/rubber,
		/obj/item/ammo_magazine/smg/vortex/ap,
		/obj/item/ammo_magazine/smg/vortex/incendiary,
		/obj/item/ammo_magazine/smg/vortex/extended,
		/obj/item/ammo_magazine/smg/vortex/taser,
		/obj/item/ammo_magazine/smg/vortex/squashhead,
	)
	fire_sound = 'sound/weapons/guns/fire/vector_fire.ogg'
	gun_features_flags = GUN_CAN_POINTBLANK|GUN_AMMO_COUNTER|GUN_DEPLOYED_FIRE_ONLY
	gun_firemode_list = list(GUN_FIREMODE_AUTOMATIC)

	attachable_allowed = list(
		/obj/item/attachable/reddot,
		/obj/item/attachable/lasersight,
		/obj/item/attachable/flashlight,
		/obj/item/attachable/scope/mini,
		/obj/item/attachable/magnetic_harness,
		/obj/item/attachable/motiondetector,
		/obj/item/attachable/suppressor/unremovable/invisible/vortex,
	)

	//negating some of the suppressor barrel length increase effects in stats, this is only in this for the sound and muzzle flash removal etc
	starting_attachment_types = list(/obj/item/attachable/suppressor/unremovable/invisible/vortex)

	attachable_offset = list("muzzle_x" = 38, "muzzle_y" = 20,"rail_x" = 28, "rail_y" = 22, "under_x" = 31, "under_y" = 15, "stock_x" = 24, "stock_y" = 10)

	fire_delay = 0.1 SECONDS
	aim_slowdown = 0.15
	wield_delay = 0.3 SECONDS
	burst_amount = 1

	accuracy_mult = 1.15
	accuracy_mult_unwielded = 0.75

	recoil = 1
	recoil_unwielded = 7.5

	scatter = 1 //gets progressively worse while shot, also angled grip included in stats
	scatter_unwielded = 10
	aim_speed_modifier = 5.8
	min_scatter_unwielded = 8
	scatter_increase = 0.5
	scatter_increase_unwielded = 0.5
	scatter_decay = 3
	scatter_decay_unwielded = 3
	min_scatter = -1
	movement_acc_penalty_mult = 4

	akimbo_additional_delay = 0.7
	var/extended = FALSE

/obj/item/attachable/suppressor/unremovable/invisible/vortex
	name = "Electromagnetic firing system"

/obj/item/weapon/gun/smg/vortex/unique_action(mob/living/user)
	if(!do_after(user, 10, TRUE, src, BUSY_ICON_DANGER))
		return
	playsound(user, 'sound/weapons/guns/interact/m41a_unload.ogg', 25, 1)
	extended = !extended
	if(!extended)
		w_class = WEIGHT_CLASS_NORMAL
		gun_features_flags |= GUN_DEPLOYED_FIRE_ONLY
	else
		w_class = WEIGHT_CLASS_BULKY
		gun_features_flags &= ~GUN_DEPLOYED_FIRE_ONLY
	update_icon()


/obj/item/weapon/gun/smg/vortex/update_icon_state()
	. = ..()
	if((!length(chamber_items) && max_chamber_items) || (!rounds && !max_chamber_items))
		icon_state = base_gun_icon + "[extended ? "_dep" : ""]" + "_e"
	else
		icon_state = base_gun_icon + "[extended ? "_dep" : ""]"

/obj/item/weapon/gun/smg/vortex/update_worn_icon_state()
	var/current_state = worn_icon_state

	worn_icon_state = "[base_gun_icon][extended ? "_dep" : ""][item_flags & WIELDED ? "_w" : ""]"

	if(current_state != worn_icon_state && ishuman(gun_user))
		var/mob/living/carbon/human/human_user = gun_user
		if(src == human_user.l_hand)
			human_user.update_inv_l_hand()
		else if (src == human_user.r_hand)
			human_user.update_inv_r_hand()


/obj/item/ammo_magazine/smg/vortex
	name = "\improper Appolo SMG magazine (9x19mm Parabellum)"
	desc = "A 9x19mm Parabellum SMG magazine."
	caliber = CALIBER_9X19
	icon_state = "v21"
	icon_state_mini = "mag_smg"
	max_rounds = 60
	w_class = WEIGHT_CLASS_SMALL

/obj/item/ammo_magazine/smg/vortex/ap
	name = "\improper Appolo AP SMG magazine (9x19mm Parabellum)"
	desc = "A 9x19mm Parabellum SMG magazine, loaded in armor piercing rounds."
	icon_state = "v21_ap"
	default_ammo = /datum/ammo/bullet/smg/ap
	icon_state_mini = "mag_smg_green"

/obj/item/ammo_magazine/smg/vortex/squashhead
	name = "\improper Appolo squash-head SMG magazine (9x19mm Parabellum)"
	desc = "A 9x19mm Parabellum caseless SMG magazine, loaded in squash-head explosive rounds. Will shred the armor off of basically anything."
	icon_state = "v21_ap"
	default_ammo = /datum/ammo/bullet/smg/squash
	icon_state_mini = "mag_smg_green"

/obj/item/ammo_magazine/smg/vortex/rubber
	name = "\improper Appolo rubber SMG magazine (9x19mm Parabellum)"
	desc = "A 9x19mm Parabellum caseless SMG magazine, loaded in rubber rounds. Non-lethal."
	default_ammo = /datum/ammo/bullet/smg/vortex_rubber

/obj/item/ammo_magazine/smg/vortex/incendiary
	name = "\improper Appolo incendiary SMG magazine (9x19mm Parabellum)"
	desc = "A 9x19mm Parabellum caseless SMG magazine, loaded in incendiary rounds."
	icon_state = "v21_incend"
	default_ammo = /datum/ammo/bullet/smg/incendiary
	icon_state_mini = "mag_smg_red"

/obj/item/ammo_magazine/smg/vortex/extended
	name = "\improper Appolo extended SMG magazine (9x19mm Parabellum)"
	desc = "An extended 9x19mm Parabellum caseless SMG magazine."
	icon_state = "v21_extended"
	max_rounds = 90
	icon_state_mini = "mag_smg_yellow"
	w_class = WEIGHT_CLASS_NORMAL
	aim_speed_mod = 0.1

/obj/item/ammo_magazine/smg/vortex/taser
	name = "\improper Appolo HC SMG magazine (9x19mm Parabellum)"
	desc = "A 9x19mm Parabellum caseless SMG magazine, loaded with HC rounds. It uses High-Conductive projectiles charged by the EM gun itself. This has a 5% chance per shot to deliver an EM pulse."
	icon_state = "v21_rad"
	default_ammo = /datum/ammo/bullet/smg/taser
	icon_state_mini = "mag_smg_dark_blue"
	color = COLOR_DARK_CYAN

/datum/ammo/bullet/smg/taser
	name = "charged submachinegun bullet"
	hud_state = "smg_rad"
	damage = 15
	sundering = 1.5
	bullet_color = COLOR_BRIGHT_BLUE
	var/emp_chance = 5

/datum/ammo/bullet/smg/taser/on_hit_mob(mob/target_mob, atom/movable/projectile/proj)
	. = ..()
	do_sparks(1, TRUE, target_mob)
	if(!ishuman(target_mob))
		return
	var/mob/living/carbon/human/human_victim = target_mob
	if(prob(emp_chance))
		empulse(target_mob.loc, 0,0,0,1)
	if(human_victim.species.species_flags & ROBOTIC_LIMBS)
		human_victim.adjust_stamina_loss(proj.damage)
		if(human_victim.get_stamina_loss() > 25)
			human_victim.overlay_fullscreen_timer(human_victim.get_stamina_loss(), 10, "glitch", /atom/movable/screen/fullscreen/robot_glitch)
		if((human_victim.get_stamina_loss() >= human_victim.maxHealth*2) && !human_victim.IsParalyzed())
			human_victim.ParalyzeNoChain(15 SECONDS) //fake unconscious basically
			human_victim.AdjustMute(15 SECONDS)
			human_victim.overlay_fullscreen_timer(15 SECONDS, 10, "bluescreen", /atom/movable/screen/fullscreen/dead/robot)
			human_victim.visible_message(span_warning("[human_victim] shudders violently whilst spitting out error text before collapsing, flailing on the ground randomly."), span_blue("You are bluescreening, but you should be able to recover from this by rebooting automatically in about 15s."), span_notice("You hear a clanker glitching."))
	else
		human_victim.adjust_stamina_loss(proj.damage/2)

/datum/ammo/bullet/smg/taser/on_hit_obj(obj/target_obj, atom/movable/projectile/proj)
	. = ..()
	if(prob(emp_chance))
		do_sparks(3, TRUE, target_obj)
		empulse(target_obj, 0, 0, 0, 1)

/datum/ammo/bullet/smg/taser/on_hit_turf(turf/target_turf, atom/movable/projectile/proj)
	. = ..()
	if(prob(emp_chance))
		do_sparks(3, TRUE, target_turf)
		empulse(target_turf, 0, 0, 0, 1)
// RPO-S, old VSD disposable rocket launcher, thermobaric firing.

/obj/item/weapon/gun/launcher/rocket/oneuse/thermobaric
	name = "\improper RPO-S Disposable Incendiary Rocket Launcher"
	desc = "An old design still in circulation after being produced by the millions back in the day as the relatively simple, inexpensive design allowed it to be issued in mass and thrown around like candy."
	icon = 'icons/obj/items/gun/special64.dmi'
	icon_state = "rpo"
	worn_icon_state = "rpo"
	worn_icon_list = list(
		slot_l_hand_str = 'icons/mob/inhands/gun/special_lefthand_1.dmi',
		slot_r_hand_str = 'icons/mob/inhands/gun/special_righthand_1.dmi',
	)
	caliber = CALIBER_93MM //codex
	default_ammo_type = /obj/item/ammo_magazine/rocket/oneuse/thermobaric
	allowed_ammo_types = list(/obj/item/ammo_magazine/rocket/oneuse/thermobaric)

/obj/item/attachable/stock/dragoon
	icon = 'icons/obj/items/attachments/attachments.dmi'
	name = "\improper Deferson stock"
	desc = "An integral stock for the Deferson Mk1."
	icon_state = "dragoon"
	attach_features_flags = ATTACH_SAME_ICON
	pixel_shift_x = 32
	pixel_shift_y = 13
/obj/item/ammo_magazine/rifle/boltclip/dragoon
	icon = 'icons/obj/items/ammo/magazine.dmi'
	name = "clip of 9.8x22mm rifle rounds"
	desc = "A Disposible Stripper clip filled with exotic rifle bullets."
	icon_state = "clipdragoon"
	default_ammo = /datum/ammo/bullet/dragoon
	caliber = CALIBER_98x22
	max_rounds = 5
	w_class = WEIGHT_CLASS_SMALL
	icon_state_mini = "clips"
	reload_delay = 5
/obj/item/ammo_magazine/rifle/boltclip/dragoon/pox //Poison rounds
	name = "clip of green-tipped 9.8x22mm rifle rounds"
	desc = "A Disposible Stripper clip filled with exotic rifle bullets."
	icon_state = "clipdragoonp"
	default_ammo = /datum/ammo/bullet/dragoon/pox
	caliber = CALIBER_98x22
	max_rounds = 5
	w_class = WEIGHT_CLASS_SMALL
	icon_state_mini = "clips"
	reload_delay = 5
/obj/item/ammo_magazine/rocket/oneuse/thermobaric
	name = "\improper 93mm thermobaric Rocket"
	desc = "A rocket used to reload a one use rocket once returned to an armory."
	caliber = CALIBER_93MM
	icon_state = "rocket"
	w_class = WEIGHT_CLASS_BULKY
	max_rounds = 1
	default_ammo = /datum/ammo/rocket/oneuse/thermobaric
	reload_delay = 30
/datum/ammo/rocket/oneuse/thermobaric // disposable thermobaric
	name = "thermobaric Rocket"
	hud_state = "rpg_thermobaric"
	damage = 15
	accurate_range = 8
	penetration = 15
	sundering = 15
	max_range = 15
/datum/ammo/rocket/oneuse/thermobaric/drop_nade(turf/target_turf, atom/movable/projectile/proj)
	cell_explosion(target_turf, 75, 35)
	flame_radius(2, target_turf)

/datum/ammo/bullet/smg/vortex_rubber
	name = "rubber SMG round"
	damage_type = STAMINA
	damage = 25
	penetration = 0
