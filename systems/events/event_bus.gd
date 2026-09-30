extends Node
## Small, explicit cross-scene event bus. Keep gameplay events here, not in a global framework.

signal world_event(event_id: String, payload: Dictionary)
signal echo_discovered(echo_id: String)
signal run_reset()

func emit_world_event(event_id: String, payload: Dictionary = {}) -> void:
	world_event.emit(event_id, payload)
