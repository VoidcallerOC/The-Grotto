extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const VISUAL_KIT := preload("res://scripts/world/visual_kit.gd")
var player: GrottoPlayer
var prompt: Label
var status: Label
var gate_position := Vector3(0, 0, -8)
var archive_position := Vector3(6, 0, 2)
var gate_logged := false
var movement_logged := false
var debug_elapsed := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("PLAYTEST SCENE_GROTTO")
	print("PLAYTEST ECHO_PERSISTED ", SaveSystem.has_echo("first_echo"))
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
	debug_elapsed += _delta
	if not movement_logged and debug_elapsed > 3.0:
		movement_logged = true
		print("PLAYTEST HUB_PLAYER_POSITION player=", player.global_position)
	var distance := player.global_position.distance_to(gate_position)
	if not gate_logged and distance < 5.0:
		gate_logged = true
		print("PLAYTEST HUB_NEAR_GATE player=", player.global_position, " gate=", gate_position, " distance=", distance)
	if distance < 3.0:
		prompt.text = "E  Enter the descent"
		if Input.is_action_just_pressed("interact"):
			print("PLAYTEST ENTER_DESCENT")
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
	environment.fog_enabled = true
	environment.fog_light_color = Color("#111b2a")
	environment.fog_density = 0.018
	world_env.environment = environment
	add_child(world_env)
	var light := OmniLight3D.new()
	light.position = Vector3(0, 5, 0)
	light.light_color = Color("#55b8b0")
	light.light_energy = 5.0
	light.omni_range = 18.0
	add_child(light)
	_add_box("Floor", Vector3(0, -0.35, 0), Vector3(18, 0.5, 18), Color("#1b2530"))
	_add_box("FocalStone", Vector3(3.2, 1.2, 0), Vector3(2.4, 2.4, 2.4), Color("#36515a"))
	_add_box("DescentFrame", gate_position + Vector3(0, 2, 0), Vector3(4, 4, 0.8), Color("#512f4c"))
	_add_box("Archive", archive_position + Vector3(0, 1, 0), Vector3(2, 2, 2), Color("#9b7b45"))
	var stone := VISUAL_KIT.material(Color("#182530"), 0.94)
	var metal := VISUAL_KIT.material(Color("#26333a"), 0.7, 0.7)
	var oxidized := VISUAL_KIT.material(Color("#31534f"), 0.86, 0.25)
	var teal := VISUAL_KIT.material(Color("#2b7775"), 0.45, 0.1, Color("#54c8bd"), 2.4)
	var gold := VISUAL_KIT.material(Color("#6b5230"), 0.45, 0.25, Color("#d2a85b"), 2.0)
	for z in [-6.0, -1.5, 3.0]:
		VISUAL_KIT.add_arch(self, "GrottoRib", Vector3(-5.2, 0, z), 3.0, 4.0, 0.8, stone)
		VISUAL_KIT.add_arch(self, "GrottoRib", Vector3(5.2, 0, z), 3.0, 4.0, 0.8, stone)
	for z in [-5.5, -1.0, 3.5]:
		VISUAL_KIT.add_cylinder(self, "BuriedColumn", Vector3(-3.3, 1.5, z), 0.42, 3.0, metal)
		VISUAL_KIT.add_cylinder(self, "BuriedColumn", Vector3(3.3, 1.5, z), 0.42, 3.0, oxidized)
	VISUAL_KIT.add_arch(self, "DescentArch", gate_position + Vector3(0, 0, 0), 5.0, 4.8, 1.2, metal)
	for x in [-1.6, -0.8, 0.8, 1.6]:
		VISUAL_KIT.add_resonance_shard(self, "EntranceShard", gate_position + Vector3(x, 2.0, 0.5), Color("#54c8bd"), Vector3(0.7, 1.0, 0.7))
	VISUAL_KIT.add_light(self, "EntranceLight", gate_position + Vector3(0, 2.0, 1.1), Color("#4db8b0"), 2.8, 7.0)
	VISUAL_KIT.add_light(self, "ArchiveLight", archive_position + Vector3(0, 2.5, 0), Color("#c8924b"), 2.2, 5.0)
	for x in [-1.4, 0.0, 1.4]:
		VISUAL_KIT.add_resonance_shard(self, "ArchiveShard", archive_position + Vector3(x, 2.2, -0.8), Color("#d2a85b"), Vector3(0.65, 0.8, 0.65))
	VISUAL_KIT.add_dust(self, "GrottoDust", Vector3(0, 2.0, 0), Color(0.45, 0.62, 0.65, 0.3), 55)
	for pos in [Vector3(-4.4, 0.35, 1.5), Vector3(-2.0, 0.2, -3.0), Vector3(4.5, 0.25, -4.0), Vector3(2.2, 0.18, 4.0)]:
		var growth := VISUAL_KIT.add_resonance_shard(self, "VoidGrowth", pos, Color("#4f9b85"), Vector3(0.9, 0.7, 0.9))
		growth.rotation = Vector3(0.25, 0.4, -0.5)

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
