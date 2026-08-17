// Rendery types for the 3D webclient. These are trailing whitespace tags on screen_loc.
// Characters 9-13 are whitespace and can be used in screen_loc without breaking BYOND HUD.
// Turfs cannot use screen_loc; they are handled via plane (WALL_PLANE vs FLOOR_PLANE).

// E3D_TYPE_BILLBOARD is the default type.

#define E3D_TYPE_BILLBOARD "\x09"
#define E3D_TYPE_FLOOR "\x0A"
#define E3D_TYPE_WALLMOUNT "\x0B"
#define E3D_TYPE_WALLMOUNT_SIGN "\x0C"
#define E3D_TYPE_SMOOTHWALL "\x0D"
#define E3D_TYPE_FALSEWALL "\x09\x09"
#define E3D_TYPE_ITEM "\x09\x0A"
#define E3D_TYPE_DOOR "\x09\x0B"
#define E3D_TYPE_LIGHTFIXTURE "\x09\x0C"
#define E3D_TYPE_TABLE "\x09\x0D"
#define E3D_TYPE_BASICWALL "\x0A\x09"
#define E3D_TYPE_EDGE "\x0A\x0A"
#define E3D_TYPE_EDGEFIREDOOR "\x0A\x0B"
#define E3D_TYPE_EDGEWINDOOR "\x0A\x0C"
#define E3D_TYPE_GAS_OVERLAY "\x0A\x0D"

/// Sight flag consumed by the 3D webclient to enable zoomed-out viewing (AI/ghosts).
#define E3D_SEE_ZOOM 0x8000

#define SET_SCREEN_LOC(thing, new_screen_loc) thing.screen_loc = "[new_screen_loc][extract_e3d_tag(thing.screen_loc)]"
#define CLEAR_SCREEN_LOC(thing) thing.screen_loc = extract_e3d_tag(thing.screen_loc)

#define WEBCLIENT_PATCHES (world.system_type == MS_WINDOWS ? "webclient_patches.dll" : "libwebclient_patches.so")
