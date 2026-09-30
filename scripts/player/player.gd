extends CharacterBody3D
class_name GrottoPlayer

signal health_changed(current: int, maximum: int)
signal attack_landed
signal player_died

@export var move_speed := 5.0
@export var max_health := 100
var health := 100
var gravity := 18.0
var dodge_timer := 0.0
var attack_cooldown := 0.0
var facing := Vector3.FORWARD
var target_enemy: Node3D

func _ready() -> void:
	health = max_health
	_create_placeholder_body()
	_create_camera()
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if dodge_timer > 0.0:
		dodge_timer -= delta
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_vec.x, 0.0, input_vec.y)
	if direction.length() > 0.1:
		direction = direction.normalized()
		facing = direction
		rotation.y = lerp_angle(rotation.y, atan2(-facing.x, -facing.z), delta * 10.0)
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.2
	if Input.is_action_just_pressed("dodge") and dodge_timer <= 0.0:
		velocity = facing * 11.0
		dodge_timer = 0.65
	if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("attack_mouse"):
		attack()
	move_and_slide()

func attack() -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = 0.55
	attack_landed.emit()
	if is_instance_valid(target_enemy) and global_position.distance_to(target_enemy.global_position) < 2.6:
		target_enemy.take_damage(25)

func receive_damage(amount: int) -> void:
	if dodge_timer > 0.0:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health == 0:
		player_died.emit()
		set_physics_process(false)

func reset_health() -> void:
	health = max_health
	set_physics_process(true)
	health_changed.emit(health, max_health)

func _create_placeholder_body() -> void:
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.height = 1.8
	capsule.radius = 0.38
	mesh.mesh = capsule
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#7ec8c7")
	material.emission_enabled = true
	material.emission = Color("#143a42")
	mesh.material_override = material
	mesh.position.y = 0.9
	add_child(mesh)
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = 1.8
	shape.radius = 0.38
	collider.shape = shape
	collider.position.y = 0.9
	add_child(collider)

func _create_camera() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 5.8, 8.5)
	camera.rotation_degrees = Vector3(-28.0, 0.0, 0.0)
	camera.current = true
	add_child(camera)
