extends Node
## Audio abstraction. Production audio can be assigned later without changing callers.

var current_track_id := "placeholder_ambient"
var current_track_path := ""
var is_playing := false

func play_track(track_id: String, audio_path: String = "") -> void:
	current_track_id = track_id
	current_track_path = audio_path
	is_playing = true
	print("AudioManager: playing ", track_id, " (placeholder if no resource is configured)")

func stop_track() -> void:
	is_playing = false

func trigger_music_event(event_id: String, intensity: float = 1.0, payload: Dictionary = {}) -> void:
	EventBus.emit_world_event(event_id, {"intensity": intensity, "payload": payload})
