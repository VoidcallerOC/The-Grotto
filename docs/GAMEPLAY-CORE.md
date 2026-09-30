# Gameplay Core — Warden Counterplay and First Echo

**Scope:** gameplay systems only. No model, environment, Blender, Scenario, or visual-direction work is included.

## Warden encounter

The Resonant Warden has two phases and exactly three encounter behaviors. The existing HUD communicates phase and current threat state; it does not depend on new visual assets.

| Behavior | Telegraph and effect | Player counter | Failure consequence |
|---|---|---|---|
| **1. Lunge** | The Warden enters `lunge_telegraph` for 0.85 seconds and marks the player’s current position, then lunges toward that point. | Dodge during the windup or move more than 1.35 m from the marked point. | A player still at the marked point takes the Warden’s 18 damage. |
| **2. Resonance pulse** | The Warden enters `pulse_telegraph` for 0.95 seconds, then resolves a 4.2 m radius pulse. | Move beyond the radius or use the existing dodge. | A player inside the radius who is not dodging takes 18 damage. |
| **3. Guarded-core cycle** | At half health, the Warden enters phase two. Its core is guarded during the attack sequence, then exposed for 1.35 seconds before another telegraphed lunge or pulse. | Do not spend an attack into the guard; wait for `core_exposed` and attack during that window. | Attacks into the guard do no damage and consume the player’s ordinary attack cooldown/opening. The guarded phase-two lunge and pulse remain counterable by the same movement/dodge rules as phase one. |

Lunge and pulse alternate. Phase two begins at or below 50% health, announces `warden_phase_2`, and starts with a guarded interval. The core opens for a short, explicit damage window, then closes before the next telegraphed attack. The encounter intentionally uses timing, movement, the existing dodge, and the existing attack only; no stamina, combo, skill-tree, arena, or animation system was added.

The encounter is more decision-driven than the prior contact-damage-only behavior: the player can read the windup, choose to dodge or reposition, and time attacks against a protected/unprotected core. The prototype still has no authored audiovisual tells beyond the HUD state and timing, so it is a readable first pass rather than a finished combat encounter.

## First Echo effect

The first collected Echo is stored as a small structured record:

```json
{
  "id": "first_echo",
  "name": "The First Resonance",
  "effect": "resonance_guard",
  "value": 1
}
```

**Resonance Guard** automatically negates one damaging Warden hit per encounter. It is consumed only when an attack would otherwise damage the player; dodged/evaded attacks do not consume it. The Echo discovery and its effect persist in the existing local save. Each new Warden encounter begins with one charge when that Echo is owned. Earlier ID-only `first_echo` saves migrate to this record on load. No inventory, extra Echo slots, upgrade tree, rarity, or generalized item database was introduced.

## Music/world state

The existing AudioManager and EventBus are reused. Warden phase transitions publish the current track, section, intensity, and world state. The phase-two transition is `WARDEN_PHASE_2` / `warden_phase_2`; existing climax and defeat events remain intact. The audio stream itself is still a placeholder.

## UI and implementation limits

- The existing placeholder HUD states the lunge/pulse counter, phase, core guard/exposure, and Echo Guard readiness/spent status.
- Warden-specific behavior replaces contact damage only for the Warden; the Hollow Echo retains its existing chase/contact behavior.
- Warden visuals, collision shape, arena, player model, and existing gameplay routes are unchanged.
- The pulse, telegraph, and timing values are intentionally simple and remain candidates for playtesting/balance.
- Save data remains local JSON; there is no account or cloud persistence.

## Verification

- Godot 4.7.2 import validation: pass.
- Deterministic Warden/Echo/save checks: **19/19** (telegraphs, failed/successful counters, Guard consumption, phase threshold, music state, core guard/exposure, defeat, malformed-save fallback, legacy migration, same-process save reload).
- Run the deterministic checks with `godot --headless --path . res://tests/gameplay_regression.tscn`.
- The gameplay regression writes a test Echo record; verify it in a new process with `godot --headless --path . res://tests/save_reload_regression.tscn`.
- Integrated runtime path: **15/15** through main menu → Grotto → Descent → music event → Echo → Warden phase one/two → defeat → Grotto → death → retry → Grotto.
- Re-run the integrated path with `bash tests/run_full_path_regression.sh`; the wrapper temporarily registers the driver and restores `project.godot` on exit.
- Import/parse validation and the new combat sequence used no changes outside gameplay scripts, tests, and this documentation.

## Art status

**PLACEHOLDER / FROZEN / NOT APPROVED.** The separate art-direction reset remains out of scope.
