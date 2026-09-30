extends CharacterBody3D
class_name GrottoEnemy

signal defeated
@export var max_health := 75
var health := 75
var player: GrottoPlayer
var attack_timer := 0.0
var active := true

func setup(target: GrottoPlayer) -> void:
	player = target
	_create_placeholder_body()

func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(player):
		return
	attack_timer = maxf(attack_timer - delta, 0.0)
	var distance := global_position.distance_to(player.global_position)
	if distance > 2.0 and distance < 16.0:
		var direction := (player.global_position - global_position).normalized()
		velocity = direction * 1.8
		look_at(global_position + Vector3(direction.x, 0.0, direction.z), Vector3.UP)
	else:
		velocity = Vector3.ZERO
	if distance <= 2.0 and attack_timer <= 0.0:
		attack_timer = 1.4
		player.receive_damage(12)
	move_and_slide()

func take_damage(amount: int) -> void:
	if not active:
		return
	health = maxi(health - amount, 0)
	if health == 0:
		active = false
		set_physics_process(false)
		defeated.emit()
		queue_free()

func _create_placeholder_body() -> void:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.height = 1.5
	sphere.radius = 0.75
	mesh.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#9a4765")
	material.emission_enabled = true
	material.emission = Color("#321326")
	mesh.material_override = material
	mesh.position.y = 0.75
	add_child(mesh)
	var collider := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.75
	collider.shape = shape
	collider.position.y = 0.75
	add_child(collider)
