extends CharacterBody3D
class_name GrottoEnemy

signal defeated
signal health_changed(current: int, maximum: int)
signal hit_feedback
signal warden_state_changed(phase: int, state_id: String)
signal resonance_guard_used

@export var max_health := 75
@export var move_speed := 1.8
@export var contact_damage := 12
@export var visual_style := "hollow"
const WARDEN_SCENE := preload("res://assets/models/warden_production.glb")
const WARDEN_LUNGE_WINDUP := 0.85
const WARDEN_PULSE_WINDUP := 0.95
const WARDEN_PULSE_RADIUS := 4.2
const WARDEN_PHASE_TWO_THRESHOLD := 0.5
const RESONANCE_GUARD_EFFECT := "resonance_guard"

var health := 75
var player: GrottoPlayer
var attack_timer := 0.0
var hit_timer := 0.0
var active := true
var body_material: StandardMaterial3D
var is_warden := false
var warden_phase := 1
var warden_state := "idle"
var warden_state_timer := 0.65
var next_attack := "lunge"
var attack_target_position := Vector3.ZERO
var resonance_guard_charges := 0
var core_guarded := false

func setup(target: GrottoPlayer) -> void:
	player = target
	health = max_health
	is_warden = visual_style == "warden"
	if is_warden and SaveSystem.has_echo_effect(RESONANCE_GUARD_EFFECT):
		resonance_guard_charges = SaveSystem.get_echo_effect_value(RESONANCE_GUARD_EFFECT)
	print("PLAYTEST ENEMY_SPAWN health=", max_health)
	_create_placeholder_body()
	health_changed.emit(health, max_health)
	if is_warden:
		warden_state_changed.emit(warden_phase, warden_state)
		print("PLAYTEST WARDEN_PHASE_1")
		print("PLAYTEST RESONANCE_GUARD charges=", resonance_guard_charges)

func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(player):
		return
	hit_timer = maxf(hit_timer - delta, 0.0)
	if hit_timer == 0.0 and body_material != null:
		body_material.albedo_color = Color("#9a4765")
	if is_warden:
		_process_warden(delta)
		return
	attack_timer = maxf(attack_timer - delta, 0.0)
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

func _process_warden(delta: float) -> void:
	warden_state_timer = maxf(warden_state_timer - delta, 0.0)
	if warden_state == "idle":
		velocity = Vector3.ZERO
		if warden_state_timer <= 0.0:
			_begin_next_warden_attack()
	elif warden_state == "lunge_telegraph":
		velocity = Vector3.ZERO
		if warden_state_timer <= 0.0:
			_set_warden_state("lunge_attack", 0.22)
			print("PLAYTEST WARDEN_LUNGE_HIT")
	elif warden_state == "lunge_attack":
		var direction := attack_target_position - global_position
		direction.y = 0.0
		velocity = direction.normalized() * move_speed * 4.0
		if warden_state_timer <= 0.0:
			_resolve_lunge_attack()
			_finish_warden_attack()
	elif warden_state == "pulse_telegraph":
		velocity = Vector3.ZERO
		if warden_state_timer <= 0.0:
			_set_warden_state("pulse_attack", 0.18)
			print("PLAYTEST WARDEN_PULSE_HIT")
	elif warden_state == "pulse_attack":
		velocity = Vector3.ZERO
		if warden_state_timer <= 0.0:
			_resolve_pulse_attack()
			_finish_warden_attack()
	elif warden_state == "core_guarded":
		velocity = Vector3.ZERO
		if warden_state_timer <= 0.0:
			_set_warden_state("core_exposed", 1.35)
	elif warden_state == "core_exposed":
		velocity = Vector3.ZERO
		if warden_state_timer <= 0.0:
			_begin_next_warden_attack()
	elif warden_state == "recovery":
		velocity = Vector3.ZERO
		if warden_state_timer <= 0.0:
			if warden_phase == 2:
				_set_warden_state("core_guarded", 0.75)
			else:
				_set_warden_state("idle", 0.32)
	move_and_slide()

func _begin_next_warden_attack() -> void:
	if next_attack == "lunge":
		next_attack = "pulse"
		_begin_lunge_telegraph()
	else:
		next_attack = "lunge"
		_begin_pulse_telegraph()

func _begin_lunge_telegraph() -> void:
	attack_target_position = player.global_position
	_set_warden_state("lunge_telegraph", WARDEN_LUNGE_WINDUP)
	print("PLAYTEST WARDEN_TELEGRAPH lunge")

func _begin_pulse_telegraph() -> void:
	_set_warden_state("pulse_telegraph", WARDEN_PULSE_WINDUP)
	print("PLAYTEST WARDEN_TELEGRAPH pulse")

func _resolve_lunge_attack() -> void:
	if player.is_dodging() or player.global_position.distance_to(attack_target_position) > 1.35:
		print("PLAYTEST WARDEN_LUNGE_EVADED")
		return
	_apply_warden_damage()

func _resolve_pulse_attack() -> void:
	if player.is_dodging() or global_position.distance_to(player.global_position) > WARDEN_PULSE_RADIUS:
		print("PLAYTEST WARDEN_PULSE_EVADED")
		return
	_apply_warden_damage()

func _apply_warden_damage() -> void:
	if resonance_guard_charges > 0:
		resonance_guard_charges -= 1
		print("PLAYTEST RESONANCE_GUARD_BLOCKED remaining=", resonance_guard_charges)
		resonance_guard_used.emit()
		return
	player.receive_damage(contact_damage)

func _finish_warden_attack() -> void:
	if active:
		_set_warden_state("recovery", 0.38)

func _set_warden_state(state_id: String, duration: float = 0.0) -> void:
	warden_state = state_id
	warden_state_timer = duration
	core_guarded = warden_phase == 2 and state_id != "core_exposed"
	warden_state_changed.emit(warden_phase, warden_state)

func take_damage(amount: int) -> bool:
	if not active:
		return false
	if is_warden and core_guarded:
		print("PLAYTEST WARDEN_GUARDED attack_blocked")
		hit_feedback.emit()
		return false
	health = maxi(health - amount, 0)
	print("PLAYTEST ENEMY_HIT health=", health, "/", max_health)
	hit_timer = 0.15
	if body_material != null:
		body_material.albedo_color = Color("#f4d88f")
	health_changed.emit(health, max_health)
	hit_feedback.emit()
	if health == 0:
		print("PLAYTEST ENEMY_DEFEATED")
		active = false
		set_physics_process(false)
		if body_material != null:
			body_material.albedo_color = Color("#3f2536")
		defeated.emit()
		queue_free()
		return true
	if is_warden and warden_phase == 1 and float(health) <= float(max_health) * WARDEN_PHASE_TWO_THRESHOLD:
		_enter_warden_phase_two()
	return true

func _enter_warden_phase_two() -> void:
	warden_phase = 2
	next_attack = "lunge"
	_set_warden_state("core_guarded", 0.85)
	print("PLAYTEST WARDEN_PHASE_2")
	AudioManager.trigger_music_event("WARDEN_PHASE_2", 0.9, {"section": "phase_2", "world_state": "warden_phase_2"})

func _create_placeholder_body() -> void:
	if visual_style == "warden":
		# The authored GLB is visual-only. The existing CharacterBody3D and
		# sphere collider remain the gameplay authority; gameplay states are UI-only.
		var warden_visual := WARDEN_SCENE.instantiate()
		warden_visual.name = "Warden_Production"
		warden_visual.position = Vector3(0.0, -0.08, 0.0)
		add_child(warden_visual)
		body_material = GrottoVisualKit.material(Color("#541e4d"), 0.25, 0.72, Color("#b83f8b"), 1.8)
		GrottoVisualKit.add_light(self, "WardenCoreLight", Vector3(0, 1.25, 0), Color("#d74b91"), 0.7, 4.5)
	else:
		_create_hollow_body()
		return

	var collider := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.75
	collider.shape = shape
	collider.position.y = 0.75
	add_child(collider)

func _create_hollow_body() -> void:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.height = 1.5
	sphere.radius = 0.75
	mesh.mesh = sphere
	body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color("#9a4765")
	body_material.emission_enabled = true
	body_material.emission = Color("#321326")
	body_material.emission_energy_multiplier = 1.8
	mesh.material_override = body_material
	mesh.position.y = 0.75
	add_child(mesh)
	var collider := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.75
	collider.shape = shape
	collider.position.y = 0.75
	add_child(collider)
