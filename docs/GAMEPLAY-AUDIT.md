# Gameplay Audit — First Playable Version

**Audit date:** 2026-09-30
**Scope:** gameplay and systems only. Visual assets are frozen.

## Current verdict

The Grotto is a **technical playable prototype** with a coherent first loop, but it is not yet a fully game-like first playable. The player can start, move, fight, trigger the music event, collect the Echo, defeat the Warden, return to the Grotto, and persist the Echo. The main missing game-facing behavior was death recovery: before this pass, player death stopped physics but offered no retry or return choice.

The loop is currently mostly a guided demonstration. The player's main decisions are when to attack, when to dodge, and whether to move toward the next landmark. Tension comes from contact damage and limited health; reward is the Echo archive count; run variation is minimal; persistence is the discovered Echo and world-event flag. A second run is therefore a replay of the same authored slice, not yet a materially different run. That is acceptable for this small foundation, but it defines the next gameplay—not art—work.

## Priority classification

### P0 — prevents playing

No remaining P0 blocker was found. The main menu launches, the player moves, scenes transition, combat resolves, and the return path works.

### P1 — breaks the core loop

**Fixed in this pass:** player death had no recovery path. `player_died` was emitted but never consumed. The Descent now presents a clear death state, pauses the run, and offers `R` to retry the Descent or `Esc` to return to the Grotto. Retry reloads a fresh scene and restores player health.

**Fixed in this pass:** music events were only print statements with an opaque nested payload. The music abstraction now tracks `track_id`, `section`, `intensity`, and `world_state`, and the existing Breakdown, Echo, Warden Climax, and Warden Defeated transitions publish those values through the existing EventBus.

### P2 — materially hurts gameplay or UX

- The Warden currently has one contact-damage behavior and one health bar; it has no authored attack patterns, telegraphs, phases, arena hazards, or meaningful counterplay beyond attack and dodge.
- The Echo is persisted only as an ID in an array. It has no metadata, lore/context, effect, upgrade path, or run modifier.
- The Grotto displays an archive count but has no archive interaction, run selection, upgrade choice, or meaningful hub decision.
- The descent is a fixed corridor with no optional route or recoverable exploration choice.
- Pause is functional as a global tree pause, but there is no dedicated pause menu with resume/restart/return affordances.
- Audio is still a placeholder WAV. The state abstraction is now ready for a real track and authored markers, but the actual music-driven world changes remain manually authored.

These were not expanded speculatively in this pass because they require design choices about Warden counterplay, Echo effects, hub progression, and the approved Voidcaller music.

### P3 — polish

Animation, VFX, audio mix, accessibility, control rebinding, camera feel, and broader QA remain future work. They should follow decisions about the core combat and progression loop.

### P4 — art

All current Echo, Warden, player, environment, and UI visuals are **PLACEHOLDER / NOT APPROVED**. No visual remodeling, texturing, animation-for-polish, or decorative asset work was performed in this gameplay pass.

## System audit

| System | Current state | First-playable implication |
|---|---|---|
| Player | Direct movement, one attack, dodge, health | Functional prototype; no combo, stamina, hitbox feedback, or death recovery before this pass |
| Camera | Fixed third-person camera attached to player | Readable enough for the slice; final feel remains undecided |
| Combat | Distance check against current target; 25 damage per attack | Functional but shallow; Warden counterplay is the main gameplay gap |
| Enemy | Chase plus timed contact damage | Works for Hollow Echo and Warden; no phases or telegraphs |
| Warden | Existing 125-health climax enemy | Can be damaged and defeated; currently one-phase |
| Music | Placeholder track plus explicit stateful event abstraction | Ready for authored sections and markers; no final music yet |
| Echo | Collection, hidden mesh, persistent `first_echo` ID | Reliable persistence; no gameplay effect or lore data yet |
| Grotto | Hub, archive count, descent gate | Persistent home foundation; no archive interaction yet |
| Save | Local JSON, missing-save defaults, malformed-save fallback | Reliable for current fields; no versioned migration layer needed yet |
| UI | Health, enemy health, objective, interaction, event, victory, return | Death/retry feedback added; dedicated pause menu remains |
| Input | WASD/arrows, attack, dodge, interact, pause, restart | Adequate for the prototype; rebinding is future work |
| Scene state | Scene-local run state plus autoload persistence | Works for the current linear slice; broader run-state model is future work |

## Implemented scope in this pass

Only four system-level changes were necessary and made:

1. A death overlay and retry/return state in `descent.gd`.
2. A `restart` input action bound to `R`.
3. Defensive save loading that resets to a default state when JSON is malformed and validates field types.
4. A small music state abstraction with explicit section, intensity, world-state, and climax/defeat transitions.

No asset, Blender, visual-review, or art-direction files were changed in this pass.

## Verification

- Godot import: pass, exit 0.
- Godot startup: pass, exit 0.
- Full synthesized playable path: **14/14 checks passed**.
- Death/retry validation: **4/4 checks passed**.
- Malformed save validation: process continued successfully, emitted the expected warning, and loaded a default state.
- Full path included menu → Grotto → Descent → Hollow Echo → music event → Echo → Warden → Warden defeat → return → persistence.
- Music log confirmed Breakdown, Echo Collected, Warden Climax, and Warden Defeated state payloads.

## Recommended next gameplay phase

The next decision should be a small Warden counterplay design, not an art pass. Define two or three readable Warden behaviors, the player's counter to each, and one meaningful Echo effect. Then add only the minimum data and UI needed to make those decisions legible. The hub can remain a compact home until an actual progression choice exists.
