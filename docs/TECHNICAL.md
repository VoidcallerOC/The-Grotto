# Technical

## Project layout

- `scenes/`: main menu, hub, descent, player scenes
- `scripts/`: player, enemy, menu, input, and world behavior
- `systems/events/`: explicit signal/event bus
- `systems/save/`: local JSON persistence at `user://grotto_save.json`
- `systems/music/`: audio manager abstraction and manually triggered events
- `data/`, `assets/`: reserved for authored content; only one generated placeholder WAV is included

## Conventions

Scenes own their local composition. Autoloads are limited to `InputSetup`, `EventBus`, `SaveSystem`, and `AudioManager`. Systems expose small methods and signals rather than introducing a framework.

## Testing

Use Godot 4.7.2. Automated import and startup validation:

```bash
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 8
```

The first playable path was also exercised in a Godot window under Xvfb with `xdotool`: main menu Play, hub traversal, descent entry, enemy damage/death, music chamber event, Echo interaction, climax enemy defeat, return gate, and fresh-process Echo persistence.

The sandbox reports an ALSA dummy-audio fallback because it has no physical audio device. This is an environment warning, not a project script error.
