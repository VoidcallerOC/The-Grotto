extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const ENEMY_SCRIPT := preload("res://scripts/enemies/enemy.gd")
var player: GrottoPlayer
var enemy: GrottoEnemy
var prompt: Label
var status: Label
var event_light: OmniLight3D
var echo_position := Vector3(5, 0, -12)
var climax_position := Vector3(0, 0, -20)
var echo_collected := false
var event_triggered := false
var enemy_defeated := false

func _ready() -> void:
	SaveSystem.set_location("descent")
	_build_environment()
	player = PLAYER_SCENE.instantiate()
	player.position = Vector3(0, 0, 6)
	add_child(player)
	enemy = ENEMY_SCRIPT.new()
	enemy.position = Vector3(0, 0, -6)
	enemy.setup(player)
	enemy.defeated.connect(_on_enemy_defeated)
	add_child(enemy)
	player.target_enemy = enemy
	_build_echo()
	_build_ui()
	AudioManager.play_track("placeholder_descent")

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	if not event_triggered and player.global_position.distance_to(Vector3(0, 0, -10)) < 3.0:
		event_triggered = true
		SaveSystem.state["world_event_seen"] = true
		SaveSystem.save_game()
		AudioManager.trigger_music_event("BREAKDOWN", 1.0, {"lighting": "violet", "world_state": "awakened"})
		event_light.light_color = Color("#b652c4")
		event_light.light_energy = 9.0
		status.text = "MUSIC EVENT: BREAKDOWN — the Grotto wakes."
	if not echo_collected and player.global_position.distance_to(echo_position) < 2.0:
		echo_collected = true
		SaveSystem.discover_echo("first_echo")
		status.text = "ECHO DISCOVERED: The First Resonance"
	if enemy_defeated and echo_collected and player.global_position.distance_to(climax_position) < 3.0:
		prompt.text = "E  Return to the Grotto"
		if Input.is_action_just_pressed("interact"):
			SaveSystem.set_location("grotto")
			get_tree().change_scene_to_file("res://scenes/grotto/grotto.tscn")
	elif not enemy_defeated:
		prompt.text = "Defeat the Hollow Echo"
	elif not echo_collected:
		prompt.text = "Find the glowing Echo at the side path"
	else:
		prompt.text = "Reach the climax gate"
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = not get_tree().paused

func _on_enemy_defeated() -> void:
	enemy_defeated = true
	status.text = "ENCOUNTER CLEARED — the path beyond the music opens."

func _build_environment() -> void:
	var world_env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#100b18")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#302441")
	environment.ambient_light_energy = 0.7
	world_env.environment = environment
	add_child(world_env)
	event_light = OmniLight3D.new()
	event_light.position = Vector3(0, 4, -10)
	event_light.light_color = Color("#426d88")
	event_light.light_energy = 4.0
	event_light.omni_range = 22.0
	add_child(event_light)
	_add_box("TraversalFloor", Vector3(0, -0.35, -6), Vector3(12, 0.5, 28), Color("#202333"))
	_add_box("LeftWall", Vector3(-6, 2, -6), Vector3(0.6, 4, 28), Color("#293849"))
	_add_box("RightWall", Vector3(6, 2, -6), Vector3(0.6, 4, 28), Color("#293849"))
	_add_box("ClimaxGate", climax_position + Vector3(0, 2, 0), Vector3(5, 4, 0.7), Color("#522c61"))
	_add_box("SideLedge", echo_position + Vector3(0, 0.4, 0), Vector3(3, 0.8, 3), Color("#40533e"))

func _build_echo() -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = "Echo"
	var sphere := SphereMesh.new()
	sphere.radius = 0.55
	sphere.height = 1.1
	mesh.mesh = sphere
	mesh.position = echo_position + Vector3(0, 1.0, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#e1c77b")
	mat.emission_enabled = true
	mat.emission = Color("#9d6f20")
	mat.emission_energy_multiplier = 3.0
	mesh.material_override = mat
	add_child(mesh)

func _add_box(node_name: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := Label.new()
	title.text = "FIRST DESCENT"
	title.position = Vector2(32, 28)
	title.add_theme_font_size_override("font_size", 26)
	layer.add_child(title)
	status = Label.new()
	status.text = "ENCOUNTER: THE HOLLOW ECHO"
	status.position = Vector2(34, 68)
	status.add_theme_color_override("font_color", Color("#d78ca8"))
	layer.add_child(status)
	prompt = Label.new()
	prompt.position = Vector2(34, 650)
	prompt.add_theme_font_size_override("font_size", 18)
	prompt.add_theme_color_override("font_color", Color("#d4c48c"))
	layer.add_child(prompt)
	var health := Label.new()
	health.position = Vector2(1060, 28)
	health.add_theme_color_override("font_color", Color("#9ad9d1"))
	layer.add_child(health)
	player.health_changed.connect(func(current: int, maximum: int) -> void: health.text = "HEALTH %d / %d" % [current, maximum])
	var controls := Label.new()
	controls.text = "WASD / arrows move  •  Space / click attack  •  Esc pause"
	controls.position = Vector2(32, 690)
	controls.add_theme_color_override("font_color", Color("#6e7b91"))
	layer.add_child(controls)
