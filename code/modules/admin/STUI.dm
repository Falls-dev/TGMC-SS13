/*   This is code made by Stuicey.
		Ported from RU-CMSS13 and adapted to TGMC admin APIs.
		STUI - System Tabbed User Interface
		A system that allows admins to filter their chats
		DEFAULT CONFIG LENGTH == 150
*/

#define STUI_TEXT_ATTACK "Attack"
#define STUI_TEXT_STAFF "Staff Logs"
#define STUI_TEXT_STAFF_CHAT "Staff Chat"
#define STUI_TEXT_OOC "OOC"
#define STUI_TEXT_GAME "Game"
#define STUI_TEXT_DEBUG "Debug"
#define STUI_TEXT_RUNTIME "Runtime"
#define STUI_TEXT_TGUI "TGUI"

GLOBAL_DATUM_INIT(STUI, /datum/STUI, new)

/datum/STUI
	var/name = "STUI"
	var/list/attack = list()
	var/list/admin = list()
	var/list/staff = list()
	var/list/ooc = list()
	var/list/game = list()
	var/list/debug = list()
	var/list/runtime = list()
	var/list/tgui = list()
	/// Bitflag of log groups that need UI refresh attention.
	var/processing = 0

/datum/STUI/ui_state(mob/user)
	return GLOB.always_state

/datum/STUI/ui_status(mob/user, datum/ui_state/state)
	if(!check_other_rights(user.client, R_ADMIN|R_DEBUG, FALSE))
		return UI_CLOSE
	return UI_INTERACTIVE

/datum/STUI/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "STUI", "STUI")
		ui.set_autoupdate(FALSE)
		ui.open()

/datum/STUI/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("update")
			return TRUE
	return FALSE

/datum/STUI/ui_static_data(mob/user)
	. = list()
	.["tabs"] = list()

	if(!check_other_rights(user.client, R_ADMIN|R_DEBUG, FALSE))
		return

	.["tabs"] += STUI_TEXT_ATTACK
	.["tabs"] += STUI_TEXT_STAFF
	.["tabs"] += STUI_TEXT_STAFF_CHAT
	.["tabs"] += STUI_TEXT_OOC
	.["tabs"] += STUI_TEXT_GAME
	.["tabs"] += STUI_TEXT_DEBUG
	.["tabs"] += STUI_TEXT_RUNTIME
	.["tabs"] += STUI_TEXT_TGUI

/datum/STUI/ui_data(mob/user)
	var/stui_length = CONFIG_GET(number/STUI_length)
	. = list()
	.["logs"] = list()

	if(!check_other_rights(user.client, R_ADMIN|R_DEBUG, FALSE))
		return

	if(length(attack) > stui_length + 1)
		attack.Cut(1, length(attack) - stui_length)
	.["logs"][STUI_TEXT_ATTACK] = attack
	if(length(admin) > stui_length + 1)
		admin.Cut(1, length(admin) - stui_length)
	.["logs"][STUI_TEXT_STAFF] = admin
	if(length(staff) > stui_length + 1)
		staff.Cut(1, length(staff) - stui_length)
	.["logs"][STUI_TEXT_STAFF_CHAT] = staff
	if(length(ooc) > stui_length + 1)
		ooc.Cut(1, length(ooc) - stui_length)
	.["logs"][STUI_TEXT_OOC] = ooc
	if(length(game) > stui_length + 1)
		game.Cut(1, length(game) - stui_length)
	.["logs"][STUI_TEXT_GAME] = game
	if(length(debug) > stui_length + 1)
		debug.Cut(1, length(debug) - stui_length)
	.["logs"][STUI_TEXT_DEBUG] = debug
	if(length(runtime) > stui_length + 1)
		runtime.Cut(1, length(runtime) - stui_length)
	.["logs"][STUI_TEXT_RUNTIME] = runtime
	if(length(tgui) > stui_length + 1)
		tgui.Cut(1, length(tgui) - stui_length)
	.["logs"][STUI_TEXT_TGUI] = tgui

ADMIN_VERB(open_STUI, R_ADMIN|R_DEBUG, "S: Open STUI", "Open the System Tabbed User Interface log browser.", ADMIN_CATEGORY_MAIN)
	GLOB.STUI.ui_interact(user.mob)
