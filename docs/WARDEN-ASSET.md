# Resonant Warden — Authored Production Hero Asset

**Status:** Authored production hero asset, integrated into the existing prototype encounter. **ART STATUS: PLACEHOLDER / FROZEN / NOT APPROVED.** It is not final game art and must not be polished or replaced until a separate art-direction reset.

## Design intent

The Resonant Warden is the guardian of the first descent: an ancient subterranean structure physically altered by resonance. It must share the Echo's mineral, oxidized-metal, bruised-violet language without becoming an enlarged Echo.

- **Echo:** compact artifact, fractured, contained, suspended.
- **Warden:** massive guardian, architectural, embodied, defensive/offensive, with resonance physically integrated into its structure.

The Warden is intentionally not a humanoid mannequin, demon, knight, robot, or clean science-fiction boss. Its identifying read is a tall offset mineral mass held by unequal shoulder/buttress structures, broken claw-like appendages, and three interrupted protective ribs around a recessed resonance mechanism.

## Visual construction

The asset is authored from constructed mesh rather than a collection of stock spheres, cylinders, and toruses:

- A tall convex-hull **primary mineral mass** provides the central body and a few large readable facets.
- Unequal **left/right shoulder masses** establish asymmetry and an architectural guardian profile.
- A long hooked left buttress, shorter snapped right buttress, and rear spine create broken structural support and negative space.
- A broken crown identifies the silhouette from the front and three-quarter views.
- The resonance mechanism is a recessed vertical vein protected by three offset, interrupted ribs. It is not a glowing chest gem.
- Two narrow resonance blades and two crown shards expose controlled energy only where the structure is damaged or active.
- Tarnished junction wedges explain how the major masses attach without adding random greebles.

The silhouette remains readable before emission: broad mineral mass, unequal shoulders, broken appendages, a crown, and a visible protected channel.

## Palette and materials

There are five authored node materials:

| Material | Role |
|---|---|
| `Warden_Mineral` | Dark violet-black faceted structural mass |
| `Warden_Oxidized_Metal` | Cool green-grey structural ribs and buttresses |
| `Warden_Tarnished_Junctions` | Muted warm metal at attachment points |
| `Warden_Resonance` | Restrained violet-pink active vein and blade tips |
| `Warden_Deep_Seams` | Near-black fissures between mineral plates |

Emission is confined to the resonance mechanism and blade tips. The asset is not made readable by making the whole body emissive.

## Blender source and reproducibility

- **Blender:** 4.3.2
- **Authoring script:** [`tools/blender/create_warden.py`](../tools/blender/create_warden.py)
- **Source scene:** [`tools/blender/source/warden_production.blend.zip`](../tools/blender/source/warden_production.blend.zip)
- **Production GLB:** [`assets/models/warden_production.glb`](../assets/models/warden_production.glb)
- **Export:** glTF 2.0 binary (`GLB`), selection export, applied transforms, no animation export, no textures

The script clears the scene, builds the full assembly deterministically, bakes the Blender-Z/Godot-Y axis correction into the mesh data, saves the Blender source scene, and exports the GLB. Re-running the script rebuilds the same authored geometry.

## Asset facts

- Approximate GLB size: **68 KB**
- Mesh objects: **20**
- Vertices: **1,912**
- Triangles: **910**
- Materials: **5**
- Textures: **0**
- Animations: **0**
- External dependencies: **none**

The asset remains comfortably within a first hero-asset budget. No real hardware performance profile was run; hardware performance is **UNVERIFIED**.

## Godot integration contract

The existing `GrottoEnemy` implementation remains the gameplay authority. In `scripts/enemies/enemy.gd`, only the `visual_style == "warden"` branch now instantiates `warden_production.glb` as a visual child named `Warden_Production`.

Preserved without changes:

- `CharacterBody3D` root
- Warden spawn position `Vector3(0, 0, -17)`
- health `125`
- move speed `2.4`
- contact damage `18`
- attack range and timer
- damage reception and health signal
- defeated signal and queue-free death state
- climax trigger, gate visibility, and return-to-Grotto logic
- separate `SphereShape3D` gameplay collider, radius `0.75`, centered at `y = 0.75`

The visual mesh is deliberately not used for collision. This keeps combat and navigation behavior independent of the authored geometry.

## Animation state

No animation was added in this pass. The asset is static and establishes a clean named assembly for future animation. Idle structural motion, resonance pulsing, attack movement, and defeat animation are **DEFERRED / UNVERIFIED**.

The existing encounter still changes the arena lighting and state. The Warden remains readable in the normal active encounter and the red-violet climax environment without a new animation system.

## Verification

- Godot 4.7.2 import validation: pass.
- Godot startup validation: pass with no Warden script errors.
- Dedicated visual capture driver: pass; isolated, dark silhouette, gameplay distance, combat distance, climax, three-quarter, and arena-wide captures were rendered and inspected.
- Full first-playable runtime regression: **13/13 checks passed**.
- Warden receives damage: verified by `ENEMY_HIT health=100/125` through `25/125`.
- Warden defeat: verified by `ENEMY_DEFEATED` and `PLAYTEST CLIMAX_DEFEATED`.
- Return gate and return-to-Grotto: verified by `PLAYTEST RETURN_TO_GROTTO`.
- Echo persistence after the Warden path: verified by `PLAYTEST ECHO_PERSISTED true`.
- No unrelated gameplay systems, player systems, save architecture, project config, Grotto, main menu, or Echo asset were changed.

## Known limitations

This is an authored production hero asset for the current vertical slice, not final game art. It has no texture maps, no rig, no animation, no custom collision, and no hand-painted surface variation. The runtime enemy hit feedback still uses the existing placeholder material reference rather than an authored hit-flash material pass. Physical-audio review and real-hardware performance profiling remain **UNVERIFIED**.
