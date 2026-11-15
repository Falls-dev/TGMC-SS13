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
mechanism already used by map_view/camera). Each block directly contains its
64 turfs, using native relative turf layout; there are no per-tile movable
anchors or per-actor appearance copies. Each block subscribes to turf replacement only. Membership
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

## Historical chunk seam correction

The first native implementation assumed bulk screen-map turf layout was
suitable for individually shifted world-space blocks. Client testing showed
8x8 black blocks. Blocks now own an explicit native turf anchor for each cell,
with contiguous 32-pixel offsets; native turf contents and light remain shared,
without appearance normalization or per-object synchronization.

Rebasing also used to move the source blocks eight tiles instantly while
animating the inverse camera displacement over the next physics interval.
This produced an apparent backward jump although flight coordinates did not
change. The camera now tracks its linear matrix timeline. At a rebase it
samples the current interpolated matrix and applies the inverse block shift
instantly to that matrix and its target, preserving unfinished animation time.
Subsequent physics movement continues from the compensated displayed frame.

## Passenger walking allocation fix

After reverting the experimental visibility and ship-image changes, the native
block renderer remains in use. Its source radius previously included the
passenger eye's distance from the docking port. A single walking tile could
change radius 24 to 25: the focused regression reproduces 32 additional blocks
(2048 native tile anchors), which were removed again on the reverse step.
This is allocation evidence, not a client frame-time benchmark.

The source radius now includes a fixed hull footprint instead of passenger
distance. It can grow for a larger viewport but stays allocated while viewers
remain. Camera rebasing only runs when the chunk origin actually moves.
Regression coverage walks the passenger repeatedly and checks that region
updates are skipped and every cached block retains its identity.

Global player discovery now runs once per second; only cached candidate
clients are checked on each flight update. Discovery connects each client's
HUD planes to the shared terrain scene. A newly arriving eye can take up to
one second to connect; existing viewers leaving the ship are detached on the
next flight update.

The render graph, lighting, and passenger-relative projection are unchanged.
The reported black regions and visual walking jitter are not considered
resolved by this allocation fix. The focused `tadpole_flight` suite passes
with a `Success!` shutdown marker in
`data/logs/tadpole-walk-radius-only/clean_run.lk`.

Regression checks cover adjacent cell positions, turf replacement through
an anchor, and conservation of screen coordinates during a rebase halfway
through a rotated camera interpolation. Client confirmation of the black
blocks and continuous flight remains necessary.

## SendMaps evidence and removal of per-tile relays

The shared world-root transform experiment was rejected after client testing
showed regular holes in rotated terrain and persistent walking lag. It was
reverted in 231a19c0d34. Headless transform tests did not establish correct
native rendering or performance; the passenger plate projection remains.

The user's subsequent SendMaps capture reports 2.08907 seconds / 590 calls:
1.91397 seconds looking for movable changes, including 1.68046 seconds looping
through turfs in range; 2,626,029 movables examined (about 4,451 per call).
These are accumulated totals, not the duration of an individual walking step.
This identifies visibility traversal as a substantial part of that capture;
it does not isolate the exact cost of this renderer from other visible objects.

Remove the intermediate movable anchor previously created for every source
turf. Blocks now directly expose the 64 real turfs through vis_contents, whose
native relative layout is documented in the BYOND reference:
https://www.byond.com/docs/ref/#/atom/var/vis_contents
Each block removes 64 helper movables from the visual tree. Turf replacement
refreshes just the affected block. Camera matrices, planes, membership margins
and source appearances are unchanged by this patch.

Regression coverage checks direct turf membership without movable children,
native source immutability, turf replacement and cleanup, along with existing
cache/physics/HUD regressions. Actual SendMaps reduction and visible black
regions require comparison in the client; no performance or visual fix is
claimed from the structural tests alone.

Validation: focused `tadpole_flight` PASS (1 second), no runtime errors and
`Success!` at `data/logs/tadpole-direct-native-blocks/clean_run.lk`. Normal
BYOND 516.1659 build: 0 errors, 0 warnings. The isolated test build reports
the existing `loop_checks` warning.
