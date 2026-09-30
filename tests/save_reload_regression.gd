extends Node

func _ready() -> void:
	call_deferred("_check_persisted_echo")

func _check_persisted_echo() -> void:
	var record := SaveSystem.get_echo_record("first_echo")
	var valid: bool = SaveSystem.has_echo_effect("resonance_guard") and record.get("effect", "") == "resonance_guard" and int(record.get("value", 0)) == 1
	if valid:
		print("SAVE_RELOAD_REGRESSION PASS fresh process loaded structured Resonance Guard")
	else:
		printerr("SAVE_RELOAD_REGRESSION FAIL structured Echo record missing or invalid: ", record)
	get_tree().quit(0 if valid else 1)
