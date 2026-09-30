extends Node

var failures := 0
var checks := 0

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := Node3D.new()
	get_tree().root.add_child(world)
	var player := GrottoPlayer.new()
	world.add_child(player)
	await get_tree().process_frame

	SaveSystem.state = SaveSystem._default_state()
	var malformed_file := FileAccess.open(SaveSystem.SAVE_PATH, FileAccess.WRITE)
	malformed_file.store_string("{ malformed save")
	malformed_file.close()
	SaveSystem.load_game()
	_check(SaveSystem.state.get("discovered_echoes", []).is_empty(), "malformed save falls back to safe defaults")
	var migrated := SaveSystem._normalize_echo_records(["first_echo"])
	_check(migrated.size() == 1 and migrated[0] is Dictionary, "legacy Echo ID migrates to structured data")
	_check(migrated[0].get("effect", "") == "resonance_guard", "legacy Echo migration grants the defined effect")
	SaveSystem.discover_echo("first_echo")
	_check(SaveSystem.get_echo_record("first_echo").get("value", 0) == 1, "Echo record stores one Guard charge")
	SaveSystem.save_game()
	SaveSystem.load_game()
	_check(SaveSystem.has_echo_effect("resonance_guard"), "Echo effect survives save reload")

	player.position = Vector3(0, 0, 1)
	var warden := GrottoEnemy.new()
	warden.visual_style = "warden"
	warden.max_health = 125
	warden.contact_damage = 18
	warden.position = Vector3.ZERO
	warden.setup(player)
	world.add_child(warden)
	player.target_enemy = warden
	await get_tree().process_frame
	_check(warden.resonance_guard_charges == 1, "collected Echo activates one encounter Guard charge")

	warden._begin_lunge_telegraph()
	_check(warden.warden_state == "lunge_telegraph", "lunge has a recognizable telegraph state")
	warden.resonance_guard_charges = 0
	player.health = 100
	player.dodge_timer = 0.0
	warden._resolve_lunge_attack()
	_check(player.health == 82, "failed lunge counter damages the player")
	player.health = 100
	player.position = warden.attack_target_position + Vector3(3, 0, 0)
	warden._resolve_lunge_attack()
	_check(player.health == 100, "moving aside evades the lunge")
	player.position = warden.attack_target_position
	player.dodge_timer = 0.2
	warden._resolve_lunge_attack()
	_check(player.health == 100, "dodge evades the lunge")
	player.dodge_timer = 0.0

	warden._begin_pulse_telegraph()
	_check(warden.warden_state == "pulse_telegraph", "resonance pulse has a telegraph state")
	player.position = warden.global_position + Vector3(0, 0, 1)
	player.health = 100
	warden._resolve_pulse_attack()
	_check(player.health == 82, "failed pulse counter damages the player")
	player.position = warden.global_position + Vector3(0, 0, 6)
	player.health = 100
	warden._resolve_pulse_attack()
	_check(player.health == 100, "repositioning beyond the pulse radius evades it")
	player.position = warden.global_position + Vector3(0, 0, 1)
	player.dodge_timer = 0.2
	warden._resolve_pulse_attack()
	_check(player.health == 100, "dodge evades the pulse")
	player.dodge_timer = 0.0

	warden.resonance_guard_charges = 1
	player.health = 100
	player.dodge_timer = 0.0
	warden.attack_target_position = player.global_position
	warden._resolve_lunge_attack()
	_check(player.health == 100 and warden.resonance_guard_charges == 0, "Echo Guard negates one Warden hit and consumes its charge")

	warden.health = 125
	warden.take_damage(65)
	_check(warden.warden_phase == 2 and warden.core_guarded, "half-health transition starts phase two with a guarded core")
	var guarded_health := warden.health
	player.attack_cooldown = 0.0
	player.attack()
	_check(warden.health == guarded_health, "attacking the guarded core has no effect")
	warden._set_warden_state("core_exposed", 1.0)
	player.attack_cooldown = 0.0
	player.attack()
	_check(warden.health == guarded_health - 25, "attacking during the exposed window damages the Warden")
	warden._set_warden_state("core_exposed", 1.0)
	warden.take_damage(1000)
	_check(warden.health == 0 and not warden.active, "Warden can be defeated during the exposed window")

	await get_tree().process_frame
	print("GAMEPLAY_REGRESSION_SUMMARY checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)

func _check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("GAMEPLAY_REGRESSION PASS ", description)
	else:
		failures += 1
		printerr("GAMEPLAY_REGRESSION FAIL ", description)
