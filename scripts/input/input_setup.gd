extends Node
## Keeps project.godot readable while defining the tiny prototype input map.

func _ready() -> void:
	_add_key_action("move_forward", [KEY_W, KEY_UP])
	_add_key_action("move_back", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("attack", [KEY_SPACE])
	_add_key_action("dodge", [KEY_C, KEY_SHIFT])
	_add_key_action("interact", [KEY_E])
	_add_key_action("pause", [KEY_ESCAPE])
	if not InputMap.has_action("attack_mouse"):
		InputMap.add_action("attack_mouse")
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack_mouse", mouse)

func _add_key_action(action_name: String, keys: Array) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action_name, event)
