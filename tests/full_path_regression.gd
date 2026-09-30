extends Node

var checks := 0
var failures := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _run() -> void:
	await _wait_for_scene("MainMenu")
	_check(get_tree().current_scene != null and get_tree().current_scene.name == "MainMenu", "main menu starts")
	get_tree().current_scene.call("_enter_grotto")
	await _wait_for_scene("Grotto")
	_check(get_tree().current_scene != null and get_tree().current_scene.name == "Grotto", "menu enters Grotto")

	var grotto = get_tree().current_scene
	grotto.player.global_position = grotto.gate_position
	Input.action_press("interact")
	grotto.call("_process", 0.016)
	Input.action_release("interact")
	await _wait_for_scene("Descent")
	_check(get_tree().current_scene != null and get_tree().current_scene.name == "Descent", "Grotto gate enters Descent")

	var descent = get_tree().current_scene
	_check(is_instance_valid(descent.player) and is_instance_valid(descent.enemy), "Descent spawns player and first encounter")
	descent.call("_trigger_music_event")
	_check(descent.event_triggered and AudioManager.world_state == "awakened", "music event updates world state")
	descent.call("_collect_echo")
	_check(SaveSystem.has_echo_effect("resonance_guard"), "Echo collection persists its structured gameplay effect")
	descent.enemy.take_damage(1000)
	_check(descent.enemy_defeated, "first encounter can be cleared")
	descent.player.global_position = Vector3(0, 0, -30)
	descent.call("_start_climax")
	_check(descent.climax_started and descent.climax_enemy.resonance_guard_charges == 1, "Warden starts with the collected Echo effect")
	descent.climax_enemy.take_damage(65)
	_check(descent.climax_enemy.warden_phase == 2 and AudioManager.world_state == "warden_phase_2", "Warden phase transition publishes music state")
	descent.climax_enemy._set_warden_state("core_exposed", 1.0)
	descent.climax_enemy.take_damage(1000)
	_check(descent.climax_defeated, "Warden defeat opens the return gate")
	descent.player.global_position = descent.climax_position
	Input.action_press("interact")
	descent.call("_process", 0.016)
	Input.action_release("interact")
	await _wait_for_scene("Grotto")
	_check(get_tree().current_scene != null and get_tree().current_scene.name == "Grotto", "Warden return gate reaches Grotto")
	_check(SaveSystem.has_echo("first_echo") and SaveSystem.state.get("last_location", "") == "grotto", "Echo and return location persist")

	var hub = get_tree().current_scene
	hub.player.global_position = hub.gate_position
	Input.action_press("interact")
	hub.call("_process", 0.016)
	Input.action_release("interact")
	await _wait_for_scene("Descent")
	var death_run = get_tree().current_scene
	death_run.player.receive_damage(death_run.player.health)
	_check(death_run.death_pending and get_tree().paused, "death state pauses the run")
	Input.action_press("restart")
	death_run.call("_process", 0.016)
	Input.action_release("restart")
	await _wait_for_scene("Descent")
	var retry_run = get_tree().current_scene
	_check(is_instance_valid(retry_run.player) and retry_run.player.health == retry_run.player.max_health and not get_tree().paused, "retry starts a fresh Descent with full health")
	retry_run.player.receive_damage(retry_run.player.health)
	retry_run.call("_return_to_grotto_after_death")
	await _wait_for_scene("Grotto")
	_check(get_tree().current_scene != null and get_tree().current_scene.name == "Grotto", "death return reaches Grotto")

	print("FULL_PATH_REGRESSION_SUMMARY checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)

func _wait_for_scene(expected_name: String) -> void:
	for _frame in range(120):
		await get_tree().process_frame
		if get_tree().current_scene != null and get_tree().current_scene.name == expected_name:
			return
	printerr("FULL_PATH_REGRESSION timed out waiting for scene ", expected_name)

func _check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("FULL_PATH_REGRESSION PASS ", description)
	else:
		failures += 1
		printerr("FULL_PATH_REGRESSION FAIL ", description)
