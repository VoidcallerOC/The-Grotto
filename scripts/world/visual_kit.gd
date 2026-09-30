class_name GrottoVisualKit
extends RefCounted

static func material(color: Color, roughness: float = 0.82, metallic: float = 0.0, emission: Color = Color(0, 0, 0, 0), emission_energy: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	return mat

static func add_box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, mat: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	mesh.rotation = rotation
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh

static func add_cylinder(parent: Node3D, node_name: String, pos: Vector3, radius: float, height: float, mat: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius * 1.08
	cylinder.height = height
	mesh.mesh = cylinder
	mesh.position = pos
	mesh.rotation = rotation
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh

static func add_arch(parent: Node3D, node_name: String, center: Vector3, width: float, height: float, depth: float, mat: Material) -> void:
	add_box(parent, node_name + "_Left", center + Vector3(-width * 0.5, height * 0.5, 0), Vector3(0.7, height, depth), mat)
	add_box(parent, node_name + "_Right", center + Vector3(width * 0.5, height * 0.5, 0), Vector3(0.7, height, depth), mat)
	add_box(parent, node_name + "_Header", center + Vector3(0, height, 0), Vector3(width + 0.7, 0.7, depth), mat)

static func add_light(parent: Node3D, node_name: String, pos: Vector3, color: Color, energy: float, range: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.name = node_name
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range
	parent.add_child(light)
	return light

static func add_dust(parent: Node3D, node_name: String, pos: Vector3, tint: Color, amount: int = 40) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = node_name
	particles.position = pos
	particles.amount = amount
	particles.lifetime = 5.0
	particles.randomness = 0.8
	particles.visibility_aabb = AABB(Vector3(-8, -2, -8), Vector3(16, 8, 16))
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0, 1, 0)
	process.spread = 180.0
	process.gravity = Vector3(0, 0.04, 0)
	process.initial_velocity_min = 0.04
	process.initial_velocity_max = 0.18
	process.scale_min = 0.35
	process.scale_max = 0.9
	process.color = tint
	particles.process_material = process
	var dot := SphereMesh.new()
	dot.radius = 0.025
	dot.height = 0.05
	dot.material = material(tint, 1.0, 0.0, tint, 0.6)
	particles.draw_pass_1 = dot
	parent.add_child(particles)
	return particles

static func add_resonance_shard(parent: Node3D, node_name: String, pos: Vector3, color: Color, scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var shard := MeshInstance3D.new()
	shard.name = node_name
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.16
	cone.height = 1.3
	shard.mesh = cone
	shard.position = pos
	shard.scale = scale
	shard.rotation = Vector3(0.0, 0.0, 0.35)
	shard.material_override = material(color, 0.32, 0.15, color, 3.0)
	parent.add_child(shard)
	return shard
