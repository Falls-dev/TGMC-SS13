# Tadpole: native-scene rewrite

Status: native-scene replacement implemented; client validation pending.
Branch: codex/tadpole-rewrite. Existing uncommitted fixes were carried into the
branch without discarding or committing them.

## Upstream examined before implementation

- https://github.com/tgstation/TerraGov-Marine-Corps/blob/master/code/datums/elements/turf_transparency.dm
- https://github.com/tgstation/TerraGov-Marine-Corps/blob/master/code/_onclick/hud/rendering/plane_master_group.dm
- https://github.com/tgstation/TerraGov-Marine-Corps/blob/master/code/_onclick/hud/rendering/render_plate.dm

Native multiz shares actual lower turfs through vis_contents. z_pillar tracks
visibility owners; z_holder provides an anchor under opaque upper tiles.
The transparency element updates links on turf replacement. A client's plane
group supplies per-depth planes and namespaced render targets. Composition of
lighting and geometry precedes final display. The upstream render graph has
changed relative to this fork (including LIT_GAME_RENDER_PLATE), so its files
cannot be copied verbatim.

## Contract to preserve

- Physical transit interior and ordinary passenger movement/interactions.
- WASD thrust/steering, continuous heading, translation and angular inertia.
- Landing footprint, landing validation, cooldowns, capacity and return flight.
- Ground visible to all passengers after releasing helm controls.
- Native static/hybrid light, projected searchlight, moving actors and vehicles.
- Leaving the craft, captured drop coordinates and parachute deployment.
- Cleanup on landing, deletion, loss of pilot and passenger/client transitions.

## Replacement boundary

The renderer must stop flattening appearances, polling every source, assigning
occlusion layers and duplicating hybrid-light shadow graphs. Retain gameplay
rules while replacing the scene transport and its ownership/lifecycle.
Physics and presentation need separate datums; presentation should update
membership when a source cell/chunk changes and update camera transforms per
physics step. Clients own their render graph and visibility preferences.

## Engine proof required before selecting an implementation

Native ground planes currently overlap transit planes: both unrelated levels
can have plane offset zero. Inserting native turfs directly into the existing
composite therefore allows explicit source planes to escape above the craft.
KEEP_TOGETHER does not isolate explicit planes. Mutating real source planes
per craft is invalid with ground observers or two aircraft.

Two possible isolation mechanisms require a small BYOND prototype:

1. A dedicated remote map/plane group rendered to a texture and relayed below
   the physical interior. Verify whether render targets can cross map controls,
   including a hidden source map, before relying on that capability. The local
   map_view API alone does not establish this.
2. A genuine additional visual depth for the source map with per-viewer camera
   transforms on its completed native plate. Requires safe map-load plane
   allocation and checking shared transit levels, several ground levels,
   ordinary ground viewers and multiple independent craft. Do not change
   SSmapping.z_level_to_plane_offset live without migrating existing atoms,
   lighting appearances and HUD render groups.

Do not enable an unproved renderer or call a wrapper around the existing
snapshot pipeline a complete rewrite.

## Acceptance checks

Engine proof: native animated door, mob walking, projectile, vehicle overhang,
static and moving lights, shadows, night vision and invisible actors; camera
headings 0/45/90/359 degrees; two observers with different visibility and two
independent craft. No mutation of source appearances/planes.

Integration: real helm input, release, landing/return, z changes, passenger
movement, observer exit/deletion and parachute/drop callbacks. Headless
regressions plus user client verification (user requested to test the client).

Performance: matched BYOND code/network profiles for stationary flight,
straight travel, continuous rotation and a populated colony. Report CPU,
allocation/deletion, packet volume and client frame time separately. No
claims of FPS improvement based solely on compilation or synthetic counts.

## Implemented architecture

Selected native visual depth, not a cross-map texture. Ground stacks start at
visual offset 1 during mapping initialization, before loaded atoms initialize.
Physical z links, movement and drop destinations do not change. Ordinary
ground observers use their normal HUD offset. No source plane/appearance is
mutated when a flight starts, moves or ends.

A scene owns 8x8 blocks of real turfs in vis_contents (the same bulk-turf
mechanism already used by map_view/camera). There are no per-tile or per-actor
visual proxies. Each block subscribes to turf replacement only. Membership
covers an entire eight-cell camera bucket plus the rotation/view margin;
it changes at bucket boundaries or when the viewers/source level change.

Each passenger temporarily redirects the completed native lower master plate
below the real interior and transforms that completed plate. The native
geometry/light/emissive pipeline runs first. Matrix targets are cached so an
idle aircraft does not restart an animation. The observer's original graph
and transforms are restored on departure, HUD replacement, z change or scene
destruction. The lower emissive relay cannot illuminate the upper interior.

The original physics equations, controls, launch/landing constraints, real
interior, shutter behavior, searchlight, transit drop and parachute paths are
retained. Physics no longer calls terrain/appearance/light synchronization.
The searchlight remains one real hybrid source on the ground.

Supporting native fixes:

- Nullspace hybrid masks get the holder's source plane and depth-specific
  shadow target; that filter changes only when the mask changes visual depth.
- Popup plane groups follow source depth independently of their viewer.
  Camera switching, spy camera updates and clearing a camera refresh that
  context. Nullspace previews continue to use depth zero.

Tradeoffs and remaining verification:

- A reserved ground depth adds another plane cube to HUDs; this is map-load
  infrastructure and needs a full server restart, not a hot reload.
- The native scene rotates the actual final image, including native sprites;
  the old system's fabricated cardinal DMI/smoothing variants are removed.
- Native viewport clipping/overscan during continuous rotation, lighting,
  multiple aircraft, and actual client frame time still require the user's
  in-game check. Structural graph tests and compilation do not prove pixels.
- Old snapshot-renderer benchmark numbers in tadpole-rendering-audit.md are
  historical and do not measure this implementation. No new FPS claim is made.

## Validation of the implementation

BYOND 516.1659 normal build: 0 errors, 0 warnings. Focused integration suite:
`tadpole_flight`, `parachute`, `plane_double_transform` PASS; clean shutdown
marker `Success!` at `data/logs/tadpole-native-rewrite-final/clean_run.lk`.
The test build has the existing reference-tracking `loop_checks` warning.
Tests cover physics, native block identity/reuse/coverage, turf replacement,
source immutability, temporary HUD routing and restoration, another HUD's
isolation, ground depth allocation, hybrid mask depth, remote-view depth,
transit drop origin/timer, parachute entry path and shutter state.

Engine constraints confirmed in the BYOND reference:
https://www.byond.com/docs/ref/info.html?msg=%5Burl_encode%28M.key%29%5D
A render target cannot be consumed across different map controls. A plane
master uses a screen-sized slate; camera rotation at the viewport edges must
therefore be specifically checked in the client. This has not been visually
verified, and a headless PASS is not proof that clipping is correct.

Client check requested from the user: full server restart, ordinary ground
lighting/cameras, takeoff with multiple passengers, idle/straight/turning
flight (especially 45-degree edges), NVG, pilot release/passenger movement,
landing, return, and dropping with/without a parachute. Capture a fresh code
and network profile after startup, then compare the same flight path.
