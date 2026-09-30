# Technical

## Project layout

- `scenes/`: main menu, hub, descent, player scenes
- `scripts/`: player, enemy, menu, and world behavior
- `systems/events/`: explicit signal/event bus
- `systems/save/`: local JSON persistence at `user://grotto_save.json`
- `systems/music/`: audio manager abstraction and manually triggered events
- `data/`, `assets/`: reserved for authored content; empty in this foundation pass

## Conventions

Scenes own their local composition. Autoloads are limited to `EventBus`, `SaveSystem`, and `AudioManager`. Systems expose small methods and signals rather than introducing a framework.

## Testing

Use Godot 4.7.2. Headless parse/import validation:

```bash
godot --headless --path . --editor --quit
```

Interactive quality gates still require running the game and exercising the controls in a window.
