import bpy
import math
from mathutils import Vector

# Clear the file.
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
    pass

# Materials: compact, deliberately restrained production palette.
def make_material(name, base, metallic=0.0, roughness=0.7, emission=None, emission_strength=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*base, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*base, 1.0)
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = roughness
    if emission:
        bsdf.inputs['Emission Color'].default_value = (*emission, 1.0)
        bsdf.inputs['Emission Strength'].default_value = emission_strength
    return mat

core_mat = make_material('Echo_Core_Mineral', (0.22, 0.12, 0.16), metallic=0.12, roughness=0.34, emission=(0.72, 0.22, 0.40), emission_strength=1.7)
ring_mat = make_material('Echo_Ring_OxidizedMetal', (0.08, 0.16, 0.15), metallic=0.72, roughness=0.48, emission=(0.10, 0.38, 0.32), emission_strength=0.35)
shard_mat = make_material('Echo_Shard_Resonance', (0.52, 0.30, 0.12), metallic=0.18, roughness=0.24, emission=(0.90, 0.50, 0.16), emission_strength=2.2)

root = bpy.data.objects.new('Echo_Production', None)
bpy.context.collection.objects.link(root)

# Asymmetrical faceted mineral core.
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.72, location=(0, 0.0, 0))
core = bpy.context.object
core.name = 'Echo_Core'
core.scale = (0.72, 1.18, 0.60)
core.rotation_euler = (math.radians(8), math.radians(-12), math.radians(18))
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
bevel = core.modifiers.new('Tiny_Edge_Soften', 'BEVEL')
bevel.width = 0.035
bevel.segments = 2
core.data.materials.append(core_mat)
core.parent = root

# Broken metallic resonance ring, intentionally offset from the core.
bpy.ops.mesh.primitive_torus_add(major_radius=0.88, minor_radius=0.055, major_segments=24, minor_segments=6, location=(0.0, 0.0, 0.04), rotation=(math.radians(68), math.radians(-8), math.radians(18)))
ring = bpy.context.object
ring.name = 'Echo_Broken_Ring'
ring.data.materials.append(ring_mat)
ring.parent = root

# Three pointed shards, unevenly spaced for a non-symmetrical ancient/organic feel.
shard_specs = [
    ((-0.92, 0.05, 0.20), (math.radians(18), math.radians(-22), math.radians(-28)), 0.72),
    ((0.70, 0.14, 0.40), (math.radians(-24), math.radians(18), math.radians(34)), 0.54),
    ((0.08, -0.78, -0.10), (math.radians(74), math.radians(10), math.radians(4)), 0.46),
]
for i, (loc, rot, scale) in enumerate(shard_specs, start=1):
    bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.13 * scale, radius2=0.0, depth=0.78 * scale, location=loc, rotation=rot)
    shard = bpy.context.object
    shard.name = f'Echo_Resonance_Shard_{i:02d}'
    shard.data.materials.append(shard_mat)
    shard.parent = root

# Keep the authored asset centered at the gameplay pivot and give it a clean export scale.
root['asset_role'] = 'single production hero asset'
root['pipeline'] = 'Blender 4.3.2 -> glTF 2.0 -> Godot 4.7.2'
root['design_language'] = 'dark mineral, oxidized metal, restrained resonance'

# Select the root for export.
bpy.context.view_layer.objects.active = root
bpy.ops.object.select_all(action='DESELECT')
root.select_set(True)
for obj in root.children:
	obj.select_set(True)

bpy.ops.wm.save_as_mainfile(filepath='/home/ubuntu/The-Grotto/assets/models/echo_production.blend')
bpy.ops.export_scene.gltf(
    filepath='/home/ubuntu/The-Grotto/assets/models/echo_production.glb',
    export_format='GLB',
    use_selection=True,
    export_apply=True,
    export_materials='EXPORT',
    export_cameras=False,
    export_lights=False,
)
print('ECHO_EXPORT_COMPLETE objects=', len(root.children), 'materials=', len(bpy.data.materials))
