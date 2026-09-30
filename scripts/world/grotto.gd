extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
var player: GrottoPlayer
var prompt: Label
var status: Label
var gate_position := Vector3(0, 0, -8)
var archive_position := Vector3(6, 0, 2)

func _ready() -> void:
	SaveSystem.set_location("grotto")
	_build_environment()
	player = PLAYER_SCENE.instantiate()
	player.position = Vector3(0, 0, 4)
	add_child(player)
	_build_ui()
	AudioManager.play_track("placeholder_ambient")

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	var distance := player.global_position.distance_to(gate_position)
	if distance < 3.0:
		prompt.text = "E  Enter the descent"
		if Input.is_action_just_pressed("interact"):
			get_tree().change_scene_to_file("res://scenes/descent/descent.tscn")
	else:
		prompt.text = "Explore the Grotto. The descent waits in the dark."
	status.text = "ARCHIVE ECHOES: %d" % SaveSystem.state.get("discovered_echoes", []).size()
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = not get_tree().paused

func _build_environment() -> void:
	var world_env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#080d16")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#23364a")
	environment.ambient_light_energy = 0.8
	world_env.environment = environment
	add_child(world_env)
	var light := OmniLight3D.new()
	light.position = Vector3(0, 5, 0)
	light.light_color = Color("#55b8b0")
	light.light_energy = 5.0
	light.omni_range = 18.0
	add_child(light)
	_add_box("Floor", Vector3(0, -0.35, 0), Vector3(18, 0.5, 18), Color("#1b2530"))
	_add_box("FocalStone", Vector3(0, 1.2, 0), Vector3(2.4, 2.4, 2.4), Color("#36515a"))
	_add_box("DescentFrame", gate_position + Vector3(0, 2, 0), Vector3(4, 4, 0.8), Color("#512f4c"))
	_add_box("Archive", archive_position + Vector3(0, 1, 0), Vector3(2, 2, 2), Color("#9b7b45"))

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
	title.text = "GROTTO HUB"
	title.position = Vector2(32, 28)
	title.add_theme_font_size_override("font_size", 26)
	layer.add_child(title)
	status = Label.new()
	status.position = Vector2(34, 68)
	status.add_theme_color_override("font_color", Color("#9ad9d1"))
	layer.add_child(status)
	prompt = Label.new()
	prompt.position = Vector2(34, 650)
	prompt.add_theme_font_size_override("font_size", 18)
	prompt.add_theme_color_override("font_color", Color("#d4c48c"))
	layer.add_child(prompt)
	var controls := Label.new()
	controls.text = "WASD / arrows move  •  Space / click attack  •  E interact  •  Esc pause"
	controls.position = Vector2(32, 690)
	controls.add_theme_color_override("font_color", Color("#6e7b91"))
	layer.add_child(controls)
