extends CharacterBody3D
class_name GrottoEnemy

signal defeated
signal health_changed(current: int, maximum: int)
signal hit_feedback

@export var max_health := 75
@export var move_speed := 1.8
@export var contact_damage := 12
@export var visual_style := "hollow"
var health := 75
var player: GrottoPlayer
var attack_timer := 0.0
var hit_timer := 0.0
var active := true
var body_material: StandardMaterial3D

func setup(target: GrottoPlayer) -> void:
	player = target
	health = max_health
	print("PLAYTEST ENEMY_SPAWN health=", max_health)
	_create_placeholder_body()
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(player):
		return
	attack_timer = maxf(attack_timer - delta, 0.0)
	hit_timer = maxf(hit_timer - delta, 0.0)
	if hit_timer == 0.0:
		body_material.albedo_color = Color("#9a4765")
	var distance := global_position.distance_to(player.global_position)
	if distance > 2.0 and distance < 18.0:
		var direction := (player.global_position - global_position).normalized()
		velocity = direction * move_speed
		look_at(global_position + Vector3(direction.x, 0.0, direction.z), Vector3.UP)
	else:
		velocity = Vector3.ZERO
	if distance <= 2.0 and attack_timer <= 0.0:
		attack_timer = 1.4
		player.receive_damage(contact_damage)
	move_and_slide()

func take_damage(amount: int) -> void:
	if not active:
		return
	health = maxi(health - amount, 0)
	print("PLAYTEST ENEMY_HIT health=", health, "/", max_health)
	hit_timer = 0.15
	body_material.albedo_color = Color("#f4d88f")
	health_changed.emit(health, max_health)
	hit_feedback.emit()
	if health == 0:
		print("PLAYTEST ENEMY_DEFEATED")
		active = false
		set_physics_process(false)
		body_material.albedo_color = Color("#3f2536")
		defeated.emit()
		queue_free()

func _create_placeholder_body() -> void:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.height = 1.5 if visual_style == "hollow" else 1.15
	sphere.radius = 0.75 if visual_style == "hollow" else 0.52
	mesh.mesh = sphere
	body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color("#9a4765") if visual_style == "hollow" else Color("#541e4d")
	body_material.emission_enabled = true
	body_material.emission = Color("#321326") if visual_style == "hollow" else Color("#b83f8b")
	body_material.emission_energy_multiplier = 1.8 if visual_style == "hollow" else 1.8
	mesh.material_override = body_material
	mesh.position.y = 0.75
	add_child(mesh)
	if visual_style == "warden":
		for ring_y in [0.35, 0.85, 1.35]:
			var ring := CylinderMesh.new()
			ring.top_radius = 0.95
			ring.bottom_radius = 0.95
			ring.height = 0.08
			var ring_mesh := MeshInstance3D.new()
			ring_mesh.mesh = ring
			ring_mesh.position.y = ring_y
			ring_mesh.rotation.z = 0.18 * (ring_y - 0.85)
			ring_mesh.material_override = GrottoVisualKit.material(Color("#64235f"), 0.35, 0.65, Color("#e04da3"), 1.8)
			add_child(ring_mesh)
		for shard_x in [-0.75, 0.75]:
			GrottoVisualKit.add_resonance_shard(self, "WardenShard", Vector3(shard_x, 0.9, 0), Color("#ea6b9a"), Vector3(0.55, 1.2, 0.55))
		GrottoVisualKit.add_light(self, "WardenCoreLight", Vector3(0, 1.0, 0), Color("#d74b91"), 1.2, 5.0)
	var collider := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.75
	collider.shape = shape
	collider.position.y = 0.75
	add_child(collider)
