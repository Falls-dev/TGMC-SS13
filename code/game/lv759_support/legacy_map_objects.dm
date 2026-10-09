// Legacy map objects whose original sprite states no longer exist.
/obj/structure/closet/walllocker/lv759
	icon_opened = "walllocker_opened"

/obj/structure/closet/secure_closet/warden/lv759
	icon_state = "secure_locked_police"
	icon_closed = "secure_closed_police"
	icon_locked = "secure_locked_police"
	icon_opened = "secure_open_police"
	icon_broken = "secure_broken_police"
	icon_off = "secure_closed_police"

/obj/structure/prop/mainship/brokengen/lv759
	icon_state = "off"

/obj/structure/prop/mainship/brokengen/lv759/Initialize(mapload)
	. = ..()
	update_appearance(UPDATE_OVERLAYS)

/obj/structure/prop/mainship/brokengen/lv759/update_overlays()
	. = ..()
	. += "overlay_corrupted"
