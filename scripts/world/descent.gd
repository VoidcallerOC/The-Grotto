extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const ENEMY_SCRIPT := preload("res://scripts/enemies/enemy.gd")
const VISUAL_KIT := preload("res://scripts/world/visual_kit.gd")
const ECHO_SCENE := preload("res://assets/models/echo_production.glb")
var player: GrottoPlayer
var enemy: GrottoEnemy
var climax_enemy: GrottoEnemy
var prompt: Label
var status: Label
var health_label: Label
var enemy_health_label: Label
var event_light: OmniLight3D
var echo_mesh: Node3D
var echo_position := Vector3(0, 0, -12)
var climax_position := Vector3(0, 0, -20)
var echo_collected := false
var event_triggered := false
var enemy_defeated := false
var climax_started := false
var climax_defeated := false
var event_meshes: Array[Node3D] = []
var death_pending := false
var death_layer: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("PLAYTEST SCENE_DESCENT")
	SaveSystem.set_location("descent")
	_build_environment()
	player = PLAYER_SCENE.instantiate()
	player.position = Vector3(0, 0, 6)
	add_child(player)
	player.player_died.connect(_on_player_died)
	enemy = _spawn_enemy(Vector3(0, 0, -6), 75, 1.8, 12)
	_build_echo()
	_build_ui()
	AudioManager.play_track("placeholder_descent")

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	if death_pending:
		if Input.is_action_just_pressed("restart"):
			_restart_descent()
		elif Input.is_action_just_pressed("pause"):
			_return_to_grotto_after_death()
		return
	if not event_triggered and player.global_position.distance_to(Vector3(0, 0, -10)) < 3.0:
		_trigger_music_event()
	if event_triggered and not echo_collected and player.global_position.distance_to(echo_position) < 2.2:
		prompt.text = "E  Collect the Echo"
		if Input.is_action_just_pressed("interact"):
			_collect_echo()
	elif enemy_defeated and not echo_collected:
		prompt.text = "Explore the side chamber for the Echo"
	if echo_collected and not climax_started and player.global_position.distance_to(climax_position) < 5.0:
		_start_climax()
	if climax_started and not climax_defeated:
		prompt.text = "Defeat the Resonant Warden"
	elif climax_defeated and player.global_position.distance_to(climax_position) < 4.0:
		prompt.text = "E  Return to the Grotto"
		if Input.is_action_just_pressed("interact"):
			print("PLAYTEST RETURN_TO_GROTTO")
			SaveSystem.set_location("grotto")
			get_tree().change_scene_to_file("res://scenes/grotto/grotto.tscn")
	if Input.is_action_just_pressed("pause"):
		_toggle_pause()

func _trigger_music_event() -> void:
	event_triggered = true
	print("PLAYTEST MUSIC_CHAMBER_REACHED")
	SaveSystem.state["world_event_seen"] = true
	SaveSystem.save_game()
	AudioManager.trigger_music_event("BREAKDOWN", 1.0, {"section": "breakdown", "lighting": "violet", "world_state": "awakened"})
	event_light.light_color = Color("#b652c4")
	event_light.light_energy = 9.0
	for node in event_meshes:
		node.visible = true
	status.text = "MUSIC EVENT: BREAKDOWN — the Grotto wakes."

func _collect_echo() -> void:
	echo_collected = true
	print("PLAYTEST ECHO_COLLECTED")
	if is_instance_valid(echo_mesh):
		echo_mesh.visible = false
	SaveSystem.discover_echo("first_echo")
	status.text = "ECHO DISCOVERED: The First Resonance"
	AudioManager.trigger_music_event("ECHO_COLLECTED", 0.4, {"section": "resonance", "world_state": "echo_found"})

func _start_climax() -> void:
	climax_started = true
	print("PLAYTEST CLIMAX_STARTED")
	status.text = "CLIMAX: THE RESONANT WARDEN AWAKENS"
	for node in event_meshes:
		node.visible = false
	climax_enemy = _spawn_enemy(Vector3(0, 0, -17), 125, 2.4, 18, "warden")
	player.target_enemy = climax_enemy
	climax_enemy.defeated.connect(_on_climax_defeated)
	_update_enemy_health(climax_enemy.health, climax_enemy.max_health)
	event_light.light_color = Color("#dd5b71")
	event_light.light_energy = 13.0
	AudioManager.trigger_music_event("WARDEN_CLIMAX", 1.0, {"section": "climax", "world_state": "warden_active"})

func _on_enemy_defeated() -> void:
	enemy_defeated = true
	status.text = "ENCOUNTER CLEARED — the side chamber is open."
	if is_instance_valid(enemy_health_label):
		enemy_health_label.text = "HOLLOW ECHO DEFEATED"

func _on_climax_defeated() -> void:
	climax_defeated = true
	print("PLAYTEST CLIMAX_DEFEATED player=", player.global_position)
	status.text = "CLIMAX SURVIVED — the return gate is open."
	prompt.text = "E  Return to the Grotto"
	get_node("ClimaxGate/ClimaxGate_Visual").visible = true
	if is_instance_valid(enemy_health_label):
		enemy_health_label.text = "RESONANT WARDEN DEFEATED"
	player.target_enemy = null
	AudioManager.trigger_music_event("WARDEN_DEFEATED", 0.2, {"section": "return", "world_state": "climax_cleared"})

func _on_player_died() -> void:
	if death_pending:
		return
	death_pending = true
	print("PLAYTEST PLAYER_DEATH_STATE")
	status.text = "YOU DIED — THE DESCENT REJECTS YOU"
	prompt.text = "R  Retry the Descent    •    Esc  Return to the Grotto"
	if is_instance_valid(enemy_health_label):
		enemy_health_label.text = "RUN ENDED"
	_show_death_overlay()
	get_tree().paused = true

func _restart_descent() -> void:
	print("PLAYTEST RETRY_DESCENT")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/descent/descent.tscn")

func _return_to_grotto_after_death() -> void:
	print("PLAYTEST DEATH_RETURN_TO_GROTTO")
	get_tree().paused = false
	SaveSystem.set_location("grotto")
	get_tree().change_scene_to_file("res://scenes/grotto/grotto.tscn")

func _show_death_overlay() -> void:
	death_layer = CanvasLayer.new()
	death_layer.layer = 10
	add_child(death_layer)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.01, 0.04, 0.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_layer.add_child(shade)
	var title := Label.new()
	title.text = "YOU DIED"
	title.position = Vector2(520, 250)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("#e5a1b5"))
	death_layer.add_child(title)
	var help := Label.new()
	help.text = "R  RETRY DESCENT\nESC  RETURN TO GROTTO"
	help.position = Vector2(500, 325)
	help.add_theme_font_size_override("font_size", 20)
	help.add_theme_color_override("font_color", Color("#d4c48c"))
	death_layer.add_child(help)

func _spawn_enemy(pos: Vector3, health: int, speed: float, damage: int, style: String = "hollow") -> GrottoEnemy:
	var spawned: GrottoEnemy = ENEMY_SCRIPT.new()
	spawned.position = pos
	spawned.max_health = health
	spawned.move_speed = speed
	spawned.contact_damage = damage
	spawned.visual_style = style
	spawned.setup(player)
	spawned.defeated.connect(_on_enemy_defeated)
	spawned.health_changed.connect(_update_enemy_health)
	add_child(spawned)
	player.target_enemy = spawned
	_update_enemy_health(spawned.health, spawned.max_health)
	return spawned

func _update_enemy_health(current: int, maximum: int) -> void:
	if is_instance_valid(enemy_health_label):
		enemy_health_label.text = "ENEMY HEALTH  %d / %d" % [current, maximum]

func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	if get_tree().paused:
		prompt.text = "PAUSED — press Esc to resume"

func _build_environment() -> void:
	var world_env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#100b18")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#302441")
	environment.ambient_light_energy = 0.7
	environment.fog_enabled = true
	environment.fog_light_color = Color("#1b1627")
	environment.fog_density = 0.018
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
	_add_box("MusicChamber", Vector3(0, -0.15, -10), Vector3(10, 0.1, 4), Color("#3d2947"))
	_add_box("EchoChamber", echo_position + Vector3(0, -0.15, 0), Vector3(3, 0.1, 3), Color("#40533e"))
	_add_box("ClimaxGate", climax_position + Vector3(0, 2, 0), Vector3(5, 4, 0.7), Color("#522c61"))
	get_node("ClimaxGate/ClimaxGate_Visual").visible = false
	var stone := VISUAL_KIT.material(Color("#1c202d"), 0.94)
	var metal := VISUAL_KIT.material(Color("#29343b"), 0.68, 0.72)
	var oxidized := VISUAL_KIT.material(Color("#37514d"), 0.82, 0.22)
	var dormant := VISUAL_KIT.material(Color("#3b2948"), 0.5, 0.2, Color("#593a72"), 0.6)
	var resonance := VISUAL_KIT.material(Color("#492a5b"), 0.38, 0.22, Color("#ba50c7"), 2.6)
	var warden_mat := VISUAL_KIT.material(Color("#321f37"), 0.34, 0.6, Color("#d34f8e"), 2.4)
	for z in [1.5, -3.0, -7.0, -15.0]:
		VISUAL_KIT.add_arch(self, "DescentRib", Vector3(-4.8, 0, z), 2.8, 4.6, 0.65, stone)
		VISUAL_KIT.add_arch(self, "DescentRib", Vector3(4.8, 0, z), 2.8, 4.6, 0.65, stone)
	for z in [-1.0, -5.0, -14.0]:
		VISUAL_KIT.add_cylinder(self, "DescentColumn", Vector3(-3.7, 1.4, z), 0.38, 2.8, oxidized)
		VISUAL_KIT.add_cylinder(self, "DescentColumn", Vector3(3.7, 1.4, z), 0.38, 2.8, metal)
	for x in [-3.2, -1.6, 0.0, 1.6, 3.2]:
		var rib := VISUAL_KIT.add_resonance_shard(self, "DormantResonance", Vector3(x, 2.0, -10.0), Color("#79528e"), Vector3(0.6, 0.8, 0.6))
		rib.visible = false
		event_meshes.append(rib)
	var chamber_arch := VISUAL_KIT.add_box(self, "MusicChamberHeader", Vector3(0, 3.8, -10.0), Vector3(10, 0.6, 0.7), dormant)
	chamber_arch.visible = false
	event_meshes.append(chamber_arch)
	for x in [-4.0, 4.0]:
		var event_pillar := VISUAL_KIT.add_cylinder(self, "EventPillar", Vector3(x, 2.0, -10.0), 0.4, 4.0, resonance)
		event_pillar.visible = false
		event_meshes.append(event_pillar)
	for x in [-2.2, 0.0, 2.2]:
		VISUAL_KIT.add_resonance_shard(self, "WardenArenaShard", climax_position + Vector3(x, 0.0, 1.6), Color("#d34f8e"), Vector3(0.7, 1.2, 0.7))
	VISUAL_KIT.add_cylinder(self, "WardenArenaPillar", climax_position + Vector3(-3.0, 2.2, 0), 0.45, 4.4, metal)
	VISUAL_KIT.add_cylinder(self, "WardenArenaPillar", climax_position + Vector3(3.0, 2.2, 0), 0.45, 4.4, metal)
	VISUAL_KIT.add_light(self, "EchoLight", echo_position + Vector3(0, 1.0, 0), Color("#d6a454"), 2.5, 5.0)
	VISUAL_KIT.add_light(self, "WardenArenaLight", climax_position + Vector3(0, 3.0, 0), Color("#a83e73"), 3.0, 8.0)
	VISUAL_KIT.add_dust(self, "DescentDust", Vector3(0, 2.0, -8.0), Color(0.37, 0.29, 0.48, 0.26), 70)

func _build_echo() -> void:
	echo_mesh = ECHO_SCENE.instantiate()
	echo_mesh.name = "Echo_Production"
	echo_mesh.position = echo_position + Vector3(0, 1.0, 0)
	echo_mesh.rotation = Vector3(0.12, 0.35, -0.18)
	echo_mesh.scale = Vector3(1.15, 1.15, 1.15)
	add_child(echo_mesh)

func _add_box(node_name: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	var mesh := MeshInstance3D.new()
	mesh.name = node_name + "_Visual"
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
	enemy_health_label = Label.new()
	enemy_health_label.position = Vector2(34, 98)
	enemy_health_label.add_theme_color_override("font_color", Color("#efb37c"))
	layer.add_child(enemy_health_label)
	prompt = Label.new()
	prompt.position = Vector2(34, 650)
	prompt.add_theme_font_size_override("font_size", 18)
	prompt.add_theme_color_override("font_color", Color("#d4c48c"))
	layer.add_child(prompt)
	health_label = Label.new()
	health_label.position = Vector2(1060, 28)
	health_label.add_theme_color_override("font_color", Color("#9ad9d1"))
	layer.add_child(health_label)
	player.health_changed.connect(func(current: int, maximum: int) -> void: health_label.text = "HEALTH %d / %d" % [current, maximum])
	var controls := Label.new()
	controls.text = "WASD / arrows move  •  Left click / Space attack  •  C dodge  •  E interact  •  Esc pause"
	controls.position = Vector2(32, 690)
	controls.add_theme_color_override("font_color", Color("#6e7b91"))
	layer.add_child(controls)
