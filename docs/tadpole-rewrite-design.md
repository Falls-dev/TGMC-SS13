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

## Spatial blocks and walking update timing

The next client capture still showed walking lag: 0.606137 seconds / 108
SendMaps calls (5.61 ms per call), with 923,565 movables examined (about 8,552
per call). This is not a matched same-scene benchmark against the earlier
capture and cannot establish a percentage regression/improvement. Removing
helper movables alone did not eliminate the reported symptom.

Blocks now occupy their projected transit-world coordinates rather than all
living on the helm turf with large pixel offsets. The total world-pixel
position is conserved, including clamping near world edges. This lets world
visibility operate on spatially distributed blocks. Relocation uses
abstract_move to avoid Entered/airdrop hooks; NO_STEPS prevents a second glide
animation when the chunk bucket rebases. Pixel offsets are retained only for
world-edge clamping. No TILE_BOUND is applied to an 8x8 block, since its
southwest tile alone does not represent visibility of the whole block.

Previously passenger position was sampled only by the five-Hz flight loop,
up to 0.2 seconds after the actual step. A scene view now subscribes to the
current movable eye's movement signal. It updates that passenger's plate in
the movement tick and uses the eye's glide duration; forced relocations snap.
It does not discover players, poll source appearances or update chunks.
Eye replacement and view deletion unregister the movement subscription.
The original camera follows the character; client.eye and perspective are
never changed by this system.

Regression checks exercise the real mob Move signal before any flight update,
glide timing, old-eye disconnection, spatial block distribution and conserved
projection, world-edge placement and absence of Entered side effects. These
are structural/behavioral checks; actual SendMaps cost, client frame time,
black regions and rotated lighting still require in-client verification.

Final validation: focused `tadpole_flight` PASS (1 second), no runtime errors,
`Success!` at `data/logs/tadpole-spatial-walk-final/clean_run.lk`. Normal
BYOND 516.1659 build: 0 errors, 0 warnings. The isolated test build has the
existing `loop_checks` warning.

## Translate source geometry before viewport cropping

The final-composition mask experiment was reverted in 3699a2e7591 after client
testing showed that its upper floor/wall mask cut off hull overhangs. The
user also observed the visible ground window following passenger coordinates.
The native upper rendering graph is restored; no hull mask remains.

An additional source of missing strips was the post-composition translation
`origin - flight_position`: it moved an already screen-cropped render target
by up to eight tiles. Source blocks now move by the actual continuous flight
position before native plane composition. The final plate only rotates about
the ship's docking origin relative to the passenger eye. Cache-origin changes
only add/remove blocks and never translate or rebase the completed plate.

All blocks share one flight-position interpolation timeline. Retained blocks
continue it across bucket changes; newly loaded blocks join its remaining
duration. Reanchoring a block's whole-tile loc preserves the current displayed
pixel position before animating the remaining displacement. Walking does not
change this timeline or update source blocks. The camera still follows the
passenger, with the existing movement signal and glide handling.

Regressions check source projection against continuous flight coordinates,
no shared source animation restart on walking, timeline continuity and block
reuse at a cache seam, and no completed-plate translation on flight movement
or bucket changes. This addresses the eight-tile translation strips; the
separate limitation of rotating a finite viewport still needs client QA.
Moving source blocks may change SendMaps/network cost during flight; no load
improvement is claimed without a fresh client measurement.

Validation: focused `tadpole_flight` PASS (0.8 seconds), no runtime errors,
`Success!` at `data/logs/tadpole-source-translation/clean_run.lk`. Normal
BYOND 516.1659 build: 0 errors, 0 warnings. The isolated test build has the
existing `loop_checks` warning. No in-client visual verification was performed.

## Passenger native visibility

The user compared an observer and a living passenger at the same aircraft:
the observer sees the ground apart from small rotated viewport edges, while
the living passenger still has large black regions. The user requested
disabling scene visibility restrictions while aboard.

Each active scene view now grants its viewer SEE_SELF, SEE_TURFS, SEE_OBJS
and SEE_MOBS, matching the observer's native visibility flags. The modifier
bypasses native occlusion for the displayed scene without changing client.eye,
perspective, plane routing, lighting cutoff or see_invisible. It does not
remove the renderer's finite viewport and its small rotation-edge cuts.

Temporary sight flags are tracked by owner separately from the mob's requested
base sight. Equipment can continue calling set_sight/add_sight/clear_sight;
removing a modifier restores the latest base state and preserves other owners.
The view releases its modifier on deletion, Logout, or the camera-owning mob's
movement out of the Tadpole region; quick reentry reattaches it. No global
visibility override is installed for other mobs or other scenes.

Regression coverage checks equipment recalculation, independently owned flags,
an effective sight value equal to a new base request, view activation, another
HUD's isolation, unchanged invisibility visibility, Logout cleanup, ordinary
Move exit/reentry and final view cleanup. Headless tests deliver the Logout
signal without a real client; actual visual output remains a client check.

Validation: focused `tadpole_flight` PASS (0.8 seconds), no runtime errors,
`Success!` at `data/logs/tadpole-native-visibility-final/clean_run.lk`. Normal
BYOND 516.1659 build: 0 errors, 0 warnings. The test build has the existing
`loop_checks` warning. Client visuals have not been independently verified.

## Fixed native eye with final-world follow (option 1)

This experiment uses a native invisible eye anchored at the hull center. An
ordinary passenger camera temporarily owns client.eye and EYE_PERSPECTIVE;
the original character remains the logical eye tracked by movement signals,
viewer discovery and dark-tile click-coordinate conversion. Remote cameras
are left alone. Client.view, pixel zoom, HUD coordinates and source block
membership do not change on passenger movement.

The source blocks retain native world positions and translation-only flight
animation. Their shared source translation is recentered using the inverse
heading so ground/landing coordinates remain P + R*(S-F). The lower completed
plane rotates about the fixed eye. It does not receive passenger compensation.
Source multiz parallax scaling is disabled while the scene owns these planes
and restored on cleanup.

Character following is applied to final render copies of the game, masked and
unmasked FOV passes, ghosts, runechat and balloon text. Those copies move by
anchor - logical_eye after lighting/FOV composition. HUD and fullscreen copies
remain unchanged. World-follow interpolation matches ordinary mob glide; FOV
changes attach newly enabled copies to the current interpolation. Initial
offset and capture rotation are set before changing the native eye.

Leaving the scene, Logout, deletion of the capture anchor or scene releases
the camera and owned world-copy transforms. Restoration checks ownership and
does not replace another system's newly assigned eye/perspective. The ordinary
ground projection is restored immediately when fixed mode ends. Dead living
bodies are not repinned after their death camera reset. The native eye stays
stationary during ordinary passenger walking, avoiding eye-range movement over
the shared terrain tree.

Headless regressions exercise ground projection at 0/37/90/180/270 degrees,
unchanged capture during a southward step after a half turn, final-world glide,
HUD isolation, FOV relay changes, click-origin selection and transform cleanup.
Actual connected-client eye ownership/restoration, mouse-hit rasterization,
appearance and SendMaps load are not verified by these tests.

The source buffer is still the native viewport's finite rectangle. This first
experiment checks camera anchoring and walking cost; it does not guarantee
full-window coverage when the virtual view extends past the captured world.
No HUD source canvas, expanded client.view or per-tile rotation is used.

Validation: focused tadpole_flight PASS (0.9 seconds), no runtime errors,
Success! at data/logs/tadpole-fixed-eye-final/clean_run.lk. Normal BYOND
516.1659 compilation: 0 errors and 0 warnings. The isolated test build has
the existing loop_checks warning. No connected-client visual/load test ran.

## Fixed 25x25 capture and uninterrupted passenger glide

Native capture is now 25x25, independent of the passenger's logical view or
observer zoom. A scoped viewport adapter preserves logical HUD placement and
pixel zoom, caches coordinate mappings, and restores its changes on release.
HUD synchronization runs on scene updates, not on passenger movement signals.
Ghost zoom no longer increases the shared terrain cache radius. The cache still
includes the hull footprint and chunk padding beyond the displayed capture.

The lower completed master is cropped to 25x25 before its output relay rotates.
Terrain remains in shared world-space chunks; no tile is independently rotated
and no terrain references are attached to HUD widgets. A transparent symmetric
UI bounds object keeps the larger logical HUD centered when zoomed out.

Final world relays use point sampling and continue their existing client glide
without snapping to a server estimate at every step. Glide duration includes
unfinished displacement when another step or reversal arrives. Release cancels
unfinished animations and restores the owned world transforms and sample flags.
The single-tile lighting backdrop now scales to the actual view dimensions.

The ground searchlight remains HYBRID_LIGHT (radius 9, power 8). It moves on
the real ground map and queues polygon shadow-mask calculation when its turf
changes. This is separate from the simple MOVABLE_LIGHT used by marine suits.
These changes do not replace that lighting algorithm.

Validation: focused tadpole_flight PASS (1 second), no runtime errors, Success!
at data/logs/tadpole-glide25-final/clean_run.lk. Normal BYOND 516.1659 build:
0 errors, 0 warnings. The isolated test build has the existing loop_checks
warning. Connected-client smoothness, clipping and load remain unverified.

## Movable ground searchlight

The searchlight now uses MOVABLE_LIGHT, retaining radius 9, power 8 and white
color. The standard overlay_lighting component supplies the mask and movement
updates; no hybrid light source or polygon shadow calculation is created for
this lamp. Its empty holder is visible (invisibility 0), since invisibility
would also hide the movable light underlay from living passengers. Flight still
reuses one ground source and clear_ground_view deletes it on departure.
The movable lamp is explicitly enabled with light_on = TRUE.

Validation: normal build 0 errors/0 warnings; focused tadpole_flight PASS (1.9s),
including real source creation, deferred mask attachment, ground plane,
movement reuse and source/component cleanup. No runtime errors; clean marker
Success! at data/logs/tadpole-movable-light-on/clean_run.lk. The isolated test
build retains the existing loop_checks warning. Client visuals and performance
have not been measured.

## Landing validation on demand

Continuous flight no longer calls checkLandingSpot when crossing a tile or
rotating the cardinal docking footprint. Tadpole eye relocation also skips
the camera preview validation. Ordinary navigation consoles keep their live
preview checks. The Land action still calls placeLandingSpot, which validates
the current footprint before creating a destination (and after designation
delay, if configured). Blocked and hidden-port restrictions remain in place.

Validation: normal build 0 errors/0 warnings; focused tadpole_flight PASS (1.9s),
including no validation during flight/turns and the actual Land action rejecting
a blocked result. No runtime errors; Success! at
data/logs/tadpole-landing-demand/clean_run.lk. The isolated test build retains
the existing loop_checks warning. In-client CPU savings were not measured.
