extends Node
## Audio abstraction. Production audio can be assigned later without changing callers.

const PLACEHOLDER_TRACK := "res://assets/audio/placeholder/grotto_placeholder.wav"
var current_track_id := "placeholder_ambient"
var current_track_path := PLACEHOLDER_TRACK
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

func trigger_music_event(event_id: String, intensity: float = 1.0, payload: Dictionary = {}) -> void:
	print("PLAYTEST MUSIC_EVENT ", event_id, " intensity=", intensity, " payload=", payload)
	EventBus.emit_world_event(event_id, {"intensity": intensity, "payload": payload})
