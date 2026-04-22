/atom/movable/screen/alien/biomassdisplay
	name = "biomass stored"
	icon_state = "biomass_0"
	screen_loc = ui_alienbiomassdisplay

	alien_biomass_display = new /atom/movable/screen/alien/biomassdisplay(null, src)
	alien_biomass_display.alpha = ui_alpha
	infodisplay += alien_biomass_display
