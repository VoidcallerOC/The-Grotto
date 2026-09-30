# Visual Review

The visual slice was reviewed as a nine-state rendered sequence generated from the Godot viewport at 1280×720. The captures are stored in [`visual-review/`](../visual-review/).

## Sequence review

| State | Capture | Review |
|---|---|---|
| Main menu | `01-main-menu.png` | Quiet, readable title and controls establish the restrained palette. |
| Grotto | `02-grotto.png` | Arches, columns, teal orientation light, archive glow, and dust make the hub read as a place rather than a flat test room. |
| Descent | `03-descent.png` | The corridor narrows into darker, more threatening silhouettes while keeping the player readable. |
| Music chamber before | `04-music-chamber-before.png` | Dormant chamber is cool, sparse, and readable before the authored event. |
| Music chamber after | `05-music-chamber-after.png` | Resonance ribs and violet lighting visibly transform the chamber. |
| Echo | `06-echo.png` | The Echo reads as a gold/purple artifact with a focused interaction prompt. |
| Warden encounter | `07-warden-encounter.png` | The arena shifts red-violet and the Warden reads as a ringed resonance core rather than a larger Hollow Echo. |
| Warden defeat | `08-warden-defeat.png` | The Warden is removed, the return gate is revealed, and the return prompt is explicit. |
| Return Grotto | `09-return-grotto.png` | The hub composition remains coherent and the archive count shows persistence. |

## Review conclusion

The sequence reads as one restrained game: cool safe space, dark descent, violet awakening, warm artifact, and red-violet climax. The player path remains understandable and the player/enemy silhouettes remain readable. The work is intentionally still a procedural vertical slice; final Scenario assets, authored meshes, animation, and detailed VFX remain future work.

## Review limitations

The captures use the sandbox's software-rendered virtual display. Audio quality was not judged through physical speakers because the sandbox falls back to a dummy audio driver.

## Production asset pipeline proof

### Review findings before replacement

The existing nine-state slice was reviewed for silhouette readability, lighting, traversal readability, visual hierarchy, atmosphere, and palette continuity. The procedural foundation was sufficient as temporary scaffolding: the hub, descent, music event, Echo objective, Warden arena, and return state were all readable. The main remaining gap was hero-asset specificity: the procedural Echo was legible but generic and did not demonstrate a real authored asset path.

### Selected hero asset

**Echo** was selected instead of the Resonant Warden because it is a contained non-combat visual replacement. It provides the clearest pipeline proof while preserving enemy AI, health, damage, combat, encounter flow, and the music/event systems unchanged.

### Source pipeline

- Scenario: not used; no Scenario connector or executable was available.
- Blender: Blender 4.3.2 authored the Echo as one centered GLB assembly with a faceted mineral core, offset oxidized-metal ring, and three resonance shards.
- Godot: Godot 4.7.2 imports `assets/models/echo_production.glb`; `descent.gd` instantiates it in the existing Echo position and retains the existing visibility/interaction contract.
- Authoring source: `tools/blender/create_echo.py`; the Blender source scene is preserved as `tools/blender/source/echo_production.blend.zip` because Godot scans `.blend` files and requires a machine-specific Blender editor path.

### Asset sanity facts

- Runtime asset: 39 KB GLB.
- Blender mesh objects: 5.
- Triangle estimate: 398.
- Materials: 4 authored materials.
- Textures: none; materials are authored node materials.
- Scene complexity: one root assembly, no animation, no external texture dependencies, no collision changes.

### Before/after assessment

`06-echo-procedural-baseline.png` shows the former primitive crystal and loose shard treatment. `10-echo-production.png` shows the Blender-authored Echo: the ring creates a stable silhouette, the central core reads as a designed object, and the warm shards remain restrained within the established palette. The new asset is more specific and production-directed without overpowering the music chamber or changing traversal readability.

### Remaining visual gaps

The Echo is a first production proof, not final art completion. It has no animation, texture maps, authored collision, or hand-painted surface variation. The Warden, player, environment, and VFX remain procedural/prototype representations. Formal performance profiling and physical-audio review remain outside this sandbox pass.

## Echo hero-asset revision (shape pass)

### Review finding that triggered the revision

The first production Echo was functionally integrated, but its rendered result still read as a collection of primitive shapes: a stretched faceted core, one clean torus ring around it, and three cone shards. `06-echo-procedural-baseline.png` and `10-echo-production.png` show the same underlying read — "crystal plus ring". The object was legible but not yet an authored Voidcaller artifact.

### What changed

Only the visual asset changed. The Blender authoring script was rewritten to build the Echo from constructed geometry rather than primitives:

- **Core**: a convex hull of a handful of widely spaced points, producing a small number of large planar facets and a tall splintered profile, plus two embedded fracture chips that break the outline. Six facets are cut into fracture pockets whose floors carry the resonance material, and three broad facets receive shallow dark seams.
- **Frame**: no torus remains. The frame is a set of swept claw straps, a slipped diagonal strap, a back spine, an interrupted lower and upper collar, and a detached remnant of a former hoop. Every arc is interrupted, every strap tapers, ends are snapped rather than capped, and the straps visibly intersect and cradle the core.
- **Shards**: tapered resonance blades rooted at the frame junctions, at three different sizes and deliberate orientations. The blade body is dark mineral and only the outer section is emissive.
- **Materials**: still four, still inside the established palette — dark violet-tinted mineral, oxidized green-grey metal, tarnished gold junction hardware, and restrained violet-pink resonance. No rainbow, no cyan wash, no chrome, no saturated gem colours, no large white emission surfaces. Emission colour and strength were tuned so the resonance stays a saturated violet-pink instead of clipping to white.

The gameplay scale is baked into the geometry, so `descent.gd` keeps its existing instance transform, visibility contract, interaction range, and music-event hook unchanged.

### Silhouette test

The revision was tested against a dark background (`12-echo-revision-silhouette.png`), against the actual chamber (`17-echo-revision-chamber-silhouette.png`), at normal gameplay distance (`13-echo-revision-gameplay-distance.png`), and from an oblique angle. Unshaded, the outline is an irregular splintered mass with three asymmetric blades and one detached broken arc. It is no longer describable as an orb or crystal inside a ring.

### Captures

| State | Capture | Review |
|---|---|---|
| Isolated asset | `11-echo-revision-isolated.png` | Faceted mineral mass, broken oxidized straps crossing the body, violet blade tips, gold junction hardware. |
| Silhouette (dark background) | `12-echo-revision-silhouette.png` | Flat unshaded outline; unique asymmetric construction, no ring read. |
| Gameplay distance | `13-echo-revision-gameplay-distance.png` | Reads at normal third-person distance in the descent corridor. |
| Music chamber before | `14-echo-revision-chamber-before.png` | Echo sits in the dormant chamber without overpowering the lighting. |
| Music chamber after | `15-echo-revision-chamber-after.png` | Echo holds its identity inside the violet wake of the music event. |
| Interaction state | `16-echo-revision-interaction.png` | Interaction prompt is focused on the Echo and the artifact stays readable. |
| Chamber silhouette | `17-echo-revision-chamber-silhouette.png` | Unshaded outline against the real chamber; still a unique object. |

### Asset sanity facts (revision)

- Runtime asset: 64 KB GLB.
- Triangles: 866 (previous pass: 502; budget: under ~1,500).
- Vertices: 1,848.
- Blender mesh objects: 15.
- Materials: 4 authored node materials.
- Textures: none; no external texture dependency.
- Scene complexity: one root assembly, no animation, no collision changes.

### Verification

- Godot import validation and headless startup: clean, no script errors.
- Full first-playable path driven with synthesized input events: main menu → grotto → descent gate → Hollow Echo defeated → music event → Echo collected → Resonant Warden defeated → return gate → grotto. 18 of 18 checks passed.
- Echo collection hides the mesh, writes `first_echo` to the save state, and the hub reports `ARCHIVE ECHOES: 1`.
- Fresh-process persistence confirmed (`PLAYTEST ECHO_PERSISTED true`).

### Remaining visual gaps (revision)

The Echo still has no animation, texture maps, authored collision, or hand-painted surface variation, and the frame does not yet move or settle during the music event. The Warden, player, environment, and VFX remain procedural/prototype representations.
