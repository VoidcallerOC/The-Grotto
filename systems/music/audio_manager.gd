extends Node
## Audio abstraction. Production audio can be assigned later without changing callers.

const PLACEHOLDER_TRACK := "res://assets/audio/placeholder/grotto_placeholder.wav"
var current_track_id := "placeholder_ambient"
var current_track_path := PLACEHOLDER_TRACK
var current_section := "intro"
var intensity := 0.0
var world_state := "dormant"
var is_playing := false
var player: AudioStreamPlayer

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.name = "MusicPlayer"
	player.autoplay = false
	add_child(player)

func play_track(track_id: String, audio_path: String = "") -> void:
	current_track_id = track_id
	current_track_path = audio_path if audio_path != "" else PLACEHOLDER_TRACK
	current_section = "intro"
	intensity = 0.0
	world_state = "dormant"
	var stream := load(current_track_path) as AudioStream
	if stream != null:
		player.stream = stream
		player.play()
	is_playing = true
	print("AudioManager: playing ", track_id, " from ", current_track_path)

func stop_track() -> void:
	is_playing = false
	if is_instance_valid(player):
		player.stop()

func set_section(section_id: String) -> void:
	current_section = section_id

func set_intensity(value: float) -> void:
	intensity = clampf(value, 0.0, 1.0)

func set_world_state(state_id: String) -> void:
	world_state = state_id

func trigger_music_event(event_id: String, intensity: float = 1.0, payload: Dictionary = {}) -> void:
	set_intensity(intensity)
	if payload.has("section"):
		set_section(str(payload["section"]))
	if payload.has("world_state"):
		set_world_state(str(payload["world_state"]))
	var event_state := {
		"track_id": current_track_id,
		"section": current_section,
		"intensity": self.intensity,
		"world_state": world_state,
		"payload": payload,
	}
	print("PLAYTEST MUSIC_EVENT ", event_id, " state=", event_state)
	EventBus.emit_world_event(event_id, event_state)
