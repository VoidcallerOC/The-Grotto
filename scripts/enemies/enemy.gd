extends CharacterBody3D
class_name GrottoEnemy

signal defeated
signal health_changed(current: int, maximum: int)
signal hit_feedback

@export var max_health := 75
@export var move_speed := 1.8
@export var contact_damage := 12
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
	sphere.height = 1.5
	sphere.radius = 0.75
	mesh.mesh = sphere
	body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color("#9a4765")
	body_material.emission_enabled = true
	body_material.emission = Color("#321326")
	mesh.material_override = body_material
	mesh.position.y = 0.75
	add_child(mesh)
	var collider := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.75
	collider.shape = shape
	collider.position.y = 0.75
	add_child(collider)
