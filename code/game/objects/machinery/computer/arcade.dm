/obj/machinery/computer/arcade
	name = "Black Donnovan II: Double Revenge"
	desc = "Does not support Pinball."
	icon = 'icons/obj/machines/computer.dmi'
	icon_state = "arcade"
	screen_overlay = "arcade_screen"
	circuit = /obj/item/circuitboard/computer/arcade
	interaction_flags = INTERACT_MACHINE_TGUI
	var/enemy_name = "Space Villain"
	var/temp = "Sponsored by Nanotrasen and the TerraGov Marine Corps" //Temporary message, for attack messages, etc
	var/player_hp = 30 //Player health/attack points
	var/player_mp = 10
	var/enemy_hp = 45 //Enemy health/attack points
	var/enemy_mp = 20
	var/gameover = 0
	var/blocked = 0 //Player cannot attack/heal while set
	var/list/prizes = list(
		/obj/item/spacecash/bundle/c10 = 4,
		/obj/item/tool/lighter/zippo = 2,
		/obj/item/storage/box/tgmc_mre = 2,
		/obj/item/camera = 2,
		/obj/item/camera_film = 4,
		/obj/item/toy/plush/farwa = 4,
		/obj/item/toy/plush/carp = 2,
		/obj/item/toy/plush/lizard = 2,
		/obj/item/toy/plush/snake = 2,
		/obj/item/toy/plush/slime = 2,
		/obj/item/toy/plush/moth = 2,
		/obj/item/toy/plush/rouny = 1,
		/obj/item/toy/plush/witch = 1,
		/obj/item/toy/plush/fairy = 1,
		/obj/item/toy/plush/royalqueen = 1,
		)

/obj/machinery/computer/arcade
	var/turtle = 0

/obj/machinery/computer/arcade/Initialize(mapload)
	. = ..()
	var/name_action
	var/name_part1
	var/name_part2

	name_action = pick("Defeat ", "Annihilate ", "Save ", "Strike ", "Stop ", "Destroy ", "Robust ", "Romance ", "Pwn ", "Own ")

	name_part1 = pick("the Automatic ", "Farmer ", "Lord ", "Professor ", "the Cuban ", "the Evil ", "the Dread King ", "the Space ", "Lord ", "the Great ", "Duke ", "General ")
	name_part2 = pick("Melonoid", "Murdertron", "Sorcerer", "Ruin", "Jeff", "Ectoplasm", "Crushulon", "Uhangoid", "Vhakoid", "Peteoid", "slime", "Griefer", "ERPer", "Lizard Man", "Unicorn")

	enemy_name = replacetext((name_part1 + name_part2), "the ", "")
	name = (name_action + name_part1 + name_part2)


/obj/machinery/computer/arcade/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Arcade", name)
		ui.open()

/obj/machinery/computer/arcade/ui_data(mob/user)
	. = list(
		"enemy_name" = enemy_name,
		"temp" = temp,
		"player_hp" = player_hp,
		"player_mp" = player_mp,
		"enemy_hp" = enemy_hp,
		"enemy_mp" = enemy_mp,
		"gameover" = gameover,
		"blocked" = blocked,
	)

/obj/machinery/computer/arcade/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("attack")
			if(blocked || gameover)
				return
			blocked = 1
			var/attackamt = rand(2, 6)
			temp = "Your sword strikes for [attackamt] damage!"
			SStgui.update_uis(src)
			if(turtle > 0)
				turtle--
			sleep(1 SECONDS)
			enemy_hp -= attackamt
			arcade_action()
			SStgui.update_uis(src)
			return TRUE
		if("heal")
			if(blocked || gameover)
				return
			blocked = 1
			var/pointamt = rand(1, 3)
			var/healamt = rand(6, 8)
			temp = "You use [pointamt] magic to heal for [healamt] damage!"
			SStgui.update_uis(src)
			turtle++
			sleep(1 SECONDS)
			player_mp -= pointamt
			player_hp += healamt
			arcade_action()
			SStgui.update_uis(src)
			return TRUE
		if("charge")
			if(blocked || gameover)
				return
			blocked = 1
			var/chargeamt = rand(4, 7)
			temp = "You regain [chargeamt] points"
			player_mp += chargeamt
			if(turtle > 0)
				turtle--
			SStgui.update_uis(src)
			sleep(1 SECONDS)
			arcade_action()
			SStgui.update_uis(src)
			return TRUE
		if("newgame")
			temp = "New Round"
			player_hp = 30
			player_mp = 10
			enemy_hp = 45
			enemy_mp = 20
			gameover = 0
			turtle = 0
			blocked = 0
			SStgui.update_uis(src)
			return TRUE


/obj/machinery/computer/arcade/proc/arcade_action()
	if ((src.enemy_mp <= 0) || (src.enemy_hp <= 0))
		if(!gameover)
			src.gameover = 1
			src.temp = "[src.enemy_name] has fallen! Rejoice!"

			if(!length(contents))
				var/prizeselect = pickweight(prizes)
				new prizeselect(src.loc)

				if(istype(prizeselect, /obj/item/toy/gun)) //Ammo comes with the gun
					new /obj/item/toy/gun_ammo(src.loc)

				else if(istype(prizeselect, /obj/item/clothing/suit/syndicatefake)) //Helmet is part of the suit
					new	/obj/item/clothing/head/syndicatefake(src.loc)

			else
				var/atom/movable/prize = pick(contents)
				prize.loc = src.loc

	else if ((src.enemy_mp <= 5) && (prob(70)))
		var/stealamt = rand(2,3)
		src.temp = "[src.enemy_name] steals [stealamt] of your power!"
		src.player_mp -= stealamt
		src.updateUsrDialog()

		if (src.player_mp <= 0)
			src.gameover = 1
			sleep(1 SECONDS)
			src.temp = "You have been drained! GAME OVER"

	else if ((src.enemy_hp <= 10) && (src.enemy_mp > 4))
		src.temp = "[src.enemy_name] heals for 4 health!"
		src.enemy_hp += 4
		src.enemy_mp -= 4

	else
		var/attackamt = rand(3,6)
		src.temp = "[src.enemy_name] attacks for [attackamt] damage!"
		src.player_hp -= attackamt

	if ((src.player_mp <= 0) || (src.player_hp <= 0))
		src.gameover = 1
		src.temp = "GAME OVER"

	blocked = 0



/obj/machinery/computer/arcade/emp_act(severity)
	if(machine_stat & (NOPOWER|BROKEN|DISABLED))
		return ..()
	var/empprize = null
	var/num_of_prizes = 0
	num_of_prizes = rand(1, 5 - severity)
	for(num_of_prizes; num_of_prizes > 0; num_of_prizes--)
		empprize = pickweight(prizes)
		new empprize(src.loc)

	return ..()
