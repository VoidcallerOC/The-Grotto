extends Node
## Local-only persistence. No accounts, cloud sync, or backend.

const SAVE_PATH := "user://grotto_save.json"
var state: Dictionary = {
	"discovered_echoes": [],
	"last_location": "grotto",
	"world_event_seen": false,
}

func _ready() -> void:
	load_game()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		state.merge(parsed, true)

func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: could not open save path")
		return false
	file.store_string(JSON.stringify(state, "  "))
	return true

func discover_echo(echo_id: String) -> void:
	var echoes: Array = state.get("discovered_echoes", [])
	if echo_id not in echoes:
		echoes.append(echo_id)
		state["discovered_echoes"] = echoes
		save_game()
		EventBus.echo_discovered.emit(echo_id)

func has_echo(echo_id: String) -> bool:
	return echo_id in state.get("discovered_echoes", [])

func set_location(location: String) -> void:
	state["last_location"] = location
	save_game()
