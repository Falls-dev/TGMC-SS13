# Procedural Frontier

`procedural_frontier` is a 199×199 all-cave ground map. Its authored `.dmm`
is only a 199×199 turf shell and a generator landmark; the map contents are
created when the round starts.

There is no city generation. Every non-boundary tile belongs to the cave
generator. A 30×40 landing zone is placed at a random valid location each
round and receives clear plating. It has a carved exit into the cave network.
The map boundary is indestructible Big Red rock.

The LZ has a reinforced perimeter, two three-tile southern exits, LZ1 docking
port, a complete outer ring of containment poddoors, room lighting, an APC, a
landing-zone button, a hangar stencil, and folding barricades just inside
the exits. The 11×21 dropship footprint is entirely clean plating; the rest of
the LZ uses asteroid floor.

The configurable variables on
`/obj/effect/landmark/procedural_frontier_generator` are:

* `map_width` / `map_height` — currently 199 each. These must agree with the
  authored `.dmm` size.
* `landing_width` / `landing_height` — currently 30×40.
* `pad_width` / `pad_height` — the docking pad remains 11×21, matching the
  marine dropship's stationary LZ1 port.
* `landing_edge_margin` — minimum distance between the pad and map edge.
* `landing_edge_opening` — exponential gradient rate (currently `4.0`).
* `landing_surface_radius` — open terrain radius around the LZ (currently 24).
* `ceiling_gradient_min` / `ceiling_gradient_max` — range used to map distance
  to ceiling levels. The default `-1..7` is clamped to `0..7`, widening the
  central `CEILING_NONE` area while preserving the deepest level.
* `cave_ridge_threshold` — base ridge-noise cutoff.
* `central_landing_complexity` — extra cutoff for a central pad; it fades out
  toward map edges, so edge pads produce more open caves.
* `excavation_site_count` — number of randomly distributed excavation sites.
* `hard_ridge_cutoff` / `deep_wall_separation` / `deep_cave_wall_type` — the
  hard ridge test selects candidate solid tiles, then only tiles separated
  from open cave by the configured radius become deep-rock (`r_wall` for
  testing). This is independent of LZ distance.
* `noise_coarse_scale` / `noise_fine_scale` / `noise_coarse_weight` — the two
  value-noise layers and their blend.
* `weed_node_spacing`, `tunnel_edge_offset`, `tunnel_minimum_spacing`,
	`miner_phoron_count`, `miner_phoron_radius`, `miner_platinum_count`, and
	`xenomorph_spawn_count` — landmark placement. Phoron miners are selected
	from open tiles near the LZ; platinum miners are selected from all caves.

`procedural_frontier_landing_threshold()` is the dedicated normalized
exponential gradient function: it returns `0` at the landing zone and rises
quickly before asymptotically slowing toward `1` at the farthest edge. The
generator first reserves an open surface ring around the landing, then raises
the ridge cutoff with distance. As a result, the LZ surroundings are open
terrain, while the remote map contains more frequent, narrow cave passages.

Weed nodes use a five-tile lattice on open cave floor. Xeno tunnels are placed
near separate map corners, platinum landmarks are distributed in caves, and
xenomorph start landmarks remain on ground cave tiles only.

The implementation is split into `create_layout`, `generate_terrain`,
`carve_landing_exit`, `retain_reachable_cave_tiles`, and landmark-placement
procs. The reachability stage flood-fills from the LZ and seals every isolated
open pocket before placing landmarks, so unreachable cave chunks cannot get
tunnels or spawns.
The shared `procedural_frontier_layout` datum contains all derived coordinates
for one run, so additional biomes or structures can consume the same map
geometry without duplicating boundary and landing calculations.

The landing zone receives compact supply, medical, engineering, and weapon
rooms, each with two lights and a free-access airlock. All rooms use a compact
6x6 footprint and are placed along the side opposite the generated exit. The
exit is selected opposite the nearest map edge (for example, a southern LZ gets
a northern exit); barricades and containment poddoors receive matching
orientation. A toilet room is created with a one-percent chance. Miner
placement uses separate near-LZ and remote-cave passes with a configurable
minimum spacing.

One `/obj/machinery/telecomms/relay/preset/telecomms/ground` is placed in a
random solid-rock pocket and completely encased in the selected biome's deep
wall type. It has no entrance or open tile, matching the sealed relay rooms on
static maps. `telecomms_relay_wall_radius` controls the surrounding wall
radius. The relay chamber is assigned `/area/storage/testroom` and is placed
after cave-sector assignment, preventing the generic cave areas from replacing
its area.

At generation start one of three biome presets is selected from the round seed:
Jungle (acid rain, smooth rock, dirt floor), Desert (sandstorm, Big Red rock,
Mars cave floor), or Taiga (snowstorm, Big Red rock, snow layer 2 floor). The
selected weather trait is applied to the current z-level at runtime, replacing
the weather flag supplied by the map JSON.

A central generator room is carved near the map centre (offset only when it
would overlap the LZ). It contains an APC on the wall and three adjacent
geothermal generators. North and south free-access airlocks are connected to
the nearest reachable cave tiles, allowing the cave route to pass through the
room instead of leaving it isolated.
