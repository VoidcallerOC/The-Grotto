# Technical

## Project layout

- `scenes/`: main menu, hub, descent, player scenes
- `scripts/`: player, enemy, menu, input, and world behavior
- `systems/events/`: explicit signal/event bus
- `systems/save/`: local JSON persistence at `user://grotto_save.json`
- `systems/music/`: audio manager abstraction and manually triggered events
- `data/`, `assets/`: reserved for authored content; only one generated placeholder WAV is included

## Current gameplay-state additions

The Descent consumes `GrottoPlayer.player_died` and presents a paused death state with `R` retry and `Esc` return-to-Grotto. The `restart` action is defined at runtime by `InputSetup` so `project.godot` remains readable. Save loading resets to a default state and warns when JSON is malformed instead of allowing invalid field types to leak into gameplay.

`AudioManager` remains intentionally small but now tracks `current_track_id`, `current_section`, normalized `intensity`, and `world_state`. `trigger_music_event()` publishes those values through `EventBus.world_event`; the existing Breakdown, Echo Collected, Warden Climax, and Warden Defeated beats are the first consumers. This is an abstraction boundary for future authored markers, not a new middleware system.

## Conventions

Scenes own their local composition. Autoloads are limited to `InputSetup`, `EventBus`, `SaveSystem`, and `AudioManager`. Systems expose small methods and signals rather than introducing a framework.

## Testing

Use Godot 4.7.2. Automated import and startup validation:

```bash
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 8
```

The first playable path was also exercised in a Godot window under Xvfb with synthesized input: main menu Play, hub traversal, descent entry, enemy damage/death, music chamber event, Echo interaction, climax enemy defeat, return gate, fresh-process Echo persistence, and death/retry.

The sandbox reports an ALSA dummy-audio fallback because it has no physical audio device. This is an environment warning, not a project script error.
