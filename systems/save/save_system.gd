extends Node
## Local-only persistence. No accounts, cloud sync, or backend.

const SAVE_PATH := "user://grotto_save.json"
const FIRST_ECHO_RECORD := {
	"id": "first_echo",
	"name": "The First Resonance",
	"effect": "resonance_guard",
	"value": 1,
}
var state: Dictionary = _default_state()

func _default_state() -> Dictionary:
	return {
		"discovered_echoes": [],
		"last_location": "grotto",
		"world_event_seen": false,
	}

func _ready() -> void:
	load_game()

func load_game() -> void:
	state = _default_state()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SaveSystem: could not read save; using a new run state")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		state.merge(parsed, true)
	else:
		push_warning("SaveSystem: invalid save data; using a new run state")
	var raw_echoes = state.get("discovered_echoes", [])
	var normalized_echoes := _normalize_echo_records(raw_echoes)
	var migrated: bool = raw_echoes != normalized_echoes
	state["discovered_echoes"] = normalized_echoes
	if not state.get("last_location") is String:
		state["last_location"] = "grotto"
	if not state.get("world_event_seen") is bool:
		state["world_event_seen"] = false
	if migrated:
		save_game()

func _normalize_echo_records(raw_echoes: Variant) -> Array:
	var normalized: Array = []
	if not raw_echoes is Array:
		return normalized
	for item in raw_echoes:
		if item is String:
			var legacy_id := str(item)
			if legacy_id == "first_echo":
				normalized.append(FIRST_ECHO_RECORD.duplicate(true))
			else:
				normalized.append({"id": legacy_id, "name": legacy_id, "effect": "none", "value": 0})
		elif item is Dictionary and item.get("id", "") is String:
			normalized.append(item.duplicate(true))
	return normalized

func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: could not open save path")
		return false
	file.store_string(JSON.stringify(state, "  "))
	return true

func discover_echo(echo_id: String) -> void:
	if has_echo(echo_id):
		return
	var record: Dictionary
	if echo_id == "first_echo":
		record = FIRST_ECHO_RECORD.duplicate(true)
	else:
		record = {"id": echo_id, "name": echo_id, "effect": "none", "value": 0}
	var echoes: Array = state.get("discovered_echoes", [])
	echoes.append(record)
	state["discovered_echoes"] = echoes
	save_game()
	EventBus.echo_discovered.emit(echo_id)

func has_echo(echo_id: String) -> bool:
	for record in state.get("discovered_echoes", []):
		if record is String and record == echo_id:
			return true
		if record is Dictionary and record.get("id", "") == echo_id:
			return true
	return false

func get_echo_record(echo_id: String) -> Dictionary:
	for record in state.get("discovered_echoes", []):
		if record is Dictionary and record.get("id", "") == echo_id:
			return record.duplicate(true)
		if record is String and record == echo_id:
			if echo_id == "first_echo":
				return FIRST_ECHO_RECORD.duplicate(true)
			return {"id": echo_id, "name": echo_id, "effect": "none", "value": 0}
	return {}

func has_echo_effect(effect_id: String) -> bool:
	return get_echo_effect_value(effect_id) > 0

func get_echo_effect_value(effect_id: String) -> int:
	for record in state.get("discovered_echoes", []):
		if record is Dictionary and record.get("effect", "") == effect_id:
			return maxi(int(record.get("value", 0)), 0)
	return 0

func set_location(location: String) -> void:
	state["last_location"] = location
	save_game()
