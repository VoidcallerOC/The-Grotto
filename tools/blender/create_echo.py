"""The Grotto - Echo hero asset authoring script (revision 2).

Pipeline is unchanged: Blender -> glTF 2.0 (GLB) -> Godot 4.7.2.

Revision intent
---------------
The first production pass (stretched icosphere + torus + three cones) still read
as "primitive shapes". This pass rebuilds the Echo from authored geometry:

* Core   - irregular convex-hull mineral mass built from a handful of widely
           spaced points, so it produces a few large planar facets instead of a
           rounded blob. Asymmetric, darker internal material, shallow dark
           seams, and cut fracture pockets where restrained resonance shows
           through the shell.
* Frame  - hand-authored claw arms swept along Catmull-Rom paths, a diagonal
           strap crossing the front, a back spine, and a detached fragment of a
           former hoop with jagged snapped ends. The arms cradle the core and
           visibly stabilise it. Nothing encircles the core as a clean ring.
* Shards - tapered resonance blades that grow out of the frame junctions, with
           varied size and deliberate orientation, dark bodies and a single
           restrained emissive seam each. No floating white cones.

Run:
    blender --background --python tools/blender/create_echo.py
"""

import math
import os

import bmesh
import bpy
from mathutils import Matrix, Vector

EXPORT_GLB = "/home/ubuntu/The-Grotto/assets/models/echo_production.glb"
SOURCE_BLEND = "/home/ubuntu/build/echo_production.blend"

# The artifact is authored in convenient local units and then baked to its
# gameplay size, so the Godot integration keeps its existing instance transform.
ASSET_SCALE = 1.30


# ---------------------------------------------------------------------------
# scene / material helpers
# ---------------------------------------------------------------------------
def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in (
        bpy.data.meshes,
        bpy.data.curves,
        bpy.data.materials,
        bpy.data.cameras,
        bpy.data.lights,
    ):
        for datablock in list(collection):
            collection.remove(datablock)


def make_material(name, base, metallic=0.0, roughness=0.7, emission=None, emission_strength=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*base, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*base, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    return mat


def object_from_bmesh(name, bm, materials, parent):
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    for mat in materials:
        obj.data.materials.append(mat)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    return obj


def plane_basis(normal, up=Vector((0.0, 0.0, 1.0))):
    n = Vector(normal).normalized()
    u = Vector(up).cross(n)
    if u.length < 1e-5:
        u = Vector((1.0, 0.0, 0.0)).cross(n)
    u.normalize()
    v = n.cross(u).normalized()
    return u, v, n


# ---------------------------------------------------------------------------
# swept path helpers (Catmull-Rom + parallel transport frames)
# ---------------------------------------------------------------------------
def catmull_rom_point(p0, p1, p2, p3, t):
    t2 = t * t
    t3 = t2 * t
    return 0.5 * (
        (2.0 * p1)
        + (-p0 + p2) * t
        + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
        + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
    )


def resample_path(control_points, per_segment=5):
    pts = [Vector(p) for p in control_points]
    padded = [pts[0]] + pts + [pts[-1]]
    path = []
    for i in range(1, len(padded) - 2):
        p0, p1, p2, p3 = padded[i - 1], padded[i], padded[i + 1], padded[i + 2]
        for j in range(per_segment):
            path.append(catmull_rom_point(p0, p1, p2, p3, j / per_segment))
    path.append(pts[-1])
    return path


def transport_frames(path, up_hint):
    up_hint = Vector(up_hint).normalized()
    frames = []
    tangent = (path[1] - path[0]).normalized()
    normal = up_hint - tangent * up_hint.dot(tangent)
    if normal.length < 1e-5:
        normal = Vector((1.0, 0.0, 0.0)) - tangent * tangent.x
    normal.normalize()
    frames.append((tangent, normal, tangent.cross(normal).normalized()))
    for i in range(1, len(path)):
        previous = frames[-1]
        tangent = (path[i] - path[i - 1]).normalized()
        rotation = previous[0].rotation_difference(tangent)
        normal = (rotation @ previous[1]).normalized()
        frames.append((tangent, normal, tangent.cross(normal).normalized()))
    return frames


def build_arm(
    name,
    parent,
    materials,
    control_points,
    half_w,
    half_h,
    up_hint,
    width_fn=None,
    per_segment=5,
    taper=0.14,
    broken_start=False,
    broken_end=False,
    material_index=0,
):
    """Sweep a rectangular section along an authored path.

    half_w is the section thickness along `up_hint`; half_h is the width across
    it, so the result reads as a bent strap of metal rather than a round tube.
    """
    path = resample_path(control_points, per_segment)
    frames = transport_frames(path, up_hint)
    segments = len(path) - 1

    bm = bmesh.new()
    rings = []
    for i in range(len(path)):
        t = i / segments
        tangent, normal, binormal = frames[i]
        scale = width_fn(t) if width_fn else 1.0
        edge = min(t, 1.0 - t)
        if edge < taper:
            k = edge / taper
            scale *= 0.36 + 0.64 * (k ** 0.55)
        hw = half_w * scale
        hh = half_h * scale
        ring = []
        for a, b in ((-hw, -hh), (hw, -hh), (hw, hh), (-hw, hh)):
            ring.append(bm.verts.new(path[i] + normal * a + binormal * b))
        rings.append(ring)
    bm.verts.ensure_lookup_table()

    for i in range(segments):
        for j in range(4):
            bm.faces.new(
                (
                    rings[i][j],
                    rings[i][(j + 1) % 4],
                    rings[i + 1][(j + 1) % 4],
                    rings[i + 1][j],
                )
            )

    def cap(ring, index, at_start):
        broken = broken_start if at_start else broken_end
        if broken:
            tangent = frames[index][0]
            binormal = frames[index][2]
            direction = -tangent if at_start else tangent
            tip = path[index] + direction * (half_h * 1.5) + binormal * (half_h * 0.55 * (1.0 if at_start else -1.0))
            tip_vert = bm.verts.new(tip)
            for j in range(4):
                bm.faces.new((ring[j], ring[(j + 1) % 4], tip_vert))
        else:
            bm.faces.new(tuple(ring))

    cap(rings[0], 0, True)
    cap(rings[-1], len(path) - 1, False)

    for face in bm.faces:
        face.material_index = material_index
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return object_from_bmesh(name, bm, materials, parent)


def build_arc(
    name,
    parent,
    materials,
    center,
    normal,
    radius,
    arc_start,
    arc_span,
    segments,
    half_w,
    half_h,
    width_fn=None,
    twist=0.0,
    taper=0.16,
    broken_start=True,
    broken_end=True,
    up=Vector((0.0, 0.0, 1.0)),
):
    """Partial circular arc band, used for the snapped hoop remnant."""
    u, v, n = plane_basis(normal, up)
    center = Vector(center)
    control = []
    for i in range(5):
        ang = arc_start + arc_span * (i / 4.0)
        control.append(center + (u * math.cos(ang) + v * math.sin(ang)) * radius)
    return build_arm(
        name,
        parent,
        materials,
        control,
        half_w,
        half_h,
        up_hint=n,
        width_fn=width_fn,
        per_segment=max(2, segments // 4),
        taper=taper,
        broken_start=broken_start,
        broken_end=broken_end,
    )


# ---------------------------------------------------------------------------
# core
# ---------------------------------------------------------------------------
# Few, widely spaced points: the convex hull then produces a small number of
# large planar facets instead of a rounded potato. The profile is a tall,
# splintered crystal rather than a symmetric gem.
CORE_POINTS = [
    (0.06, 0.58, 0.04),     # crown
    (0.28, 0.32, 0.18),     # upper right, front
    (0.30, 0.30, -0.20),    # upper right, back
    (0.18, 0.08, 0.28),     # right mid facet, pushed forward
    (0.36, -0.18, -0.06),   # lower right
    (0.12, -0.42, 0.18),    # bottom right, front
    (-0.10, -0.58, -0.06),  # root apex
    (-0.30, -0.28, 0.14),   # bottom left
    (-0.16, 0.04, -0.28),   # left mid, recessed back
    (-0.34, 0.26, 0.02),    # upper left
    (-0.04, 0.20, 0.32),    # front facet push
    (0.02, 0.12, -0.32),    # back facet push
]


def build_core(parent, materials, scale=Vector((1.0, 1.0, 1.0)), tilt=(0.10, -0.16, 0.24)):
    bm = bmesh.new()
    for p in CORE_POINTS:
        bm.verts.new(p)
    bm.verts.ensure_lookup_table()
    result = bmesh.ops.convex_hull(bm, input=bm.verts)
    interior = [g for g in result["geom_interior"] if isinstance(g, bmesh.types.BMVert)]
    if interior:
        bmesh.ops.delete(bm, geom=interior, context="VERTS")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    # Deliberate asymmetry: push a few directions out so the mass is not a clean
    # ellipsoid, while keeping the facet count low.
    for vert in bm.verts:
        d = vert.co.normalized()
        bulge = (
            0.055 * max(0.0, d.dot(Vector((0.55, 0.30, -0.78))))
            + 0.042 * max(0.0, d.dot(Vector((-0.72, -0.15, 0.68))))
            + 0.028 * max(0.0, d.dot(Vector((0.10, 0.96, 0.25))))
        )
        vert.co += d * bulge
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    bm.faces.ensure_lookup_table()
    faces = list(bm.faces)

    # Shallow dark seams across the broadest facets.
    seam_faces = sorted(faces, key=lambda f: f.calc_area(), reverse=True)[:3]
    seam_result = bmesh.ops.inset_individual(
        bm, faces=seam_faces, thickness=0.024, depth=-0.010, use_even_offset=True
    )
    for face in seam_result["faces"]:
        face.material_index = 2

    # Fracture pockets: restrained resonance shows through the mineral shell.
    bm.faces.ensure_lookup_table()
    candidates = [f for f in bm.faces if f.material_index == 0 and f.calc_area() > 0.022]
    candidates.sort(key=lambda f: f.calc_area(), reverse=True)
    front = [f for f in candidates if f.normal.z > -0.1]
    back = [f for f in candidates if f.normal.z <= -0.1]
    pocket_faces = (front[:3] + back[:3])[:6]
    pocket_result = bmesh.ops.inset_individual(
        bm, faces=pocket_faces, thickness=0.030, depth=-0.070, use_even_offset=True
    )
    for face in pocket_result["faces"]:
        face.material_index = 2
    for face in pocket_faces:
        face.material_index = 1

    obj = object_from_bmesh("Echo_Core", bm, materials, parent)
    obj.scale = scale
    obj.rotation_euler = tilt
    return obj


# ---------------------------------------------------------------------------
# shard
# ---------------------------------------------------------------------------
def build_shard(name, parent, materials, base, direction, length, radius, roll=0.0, sides=5):
    direction = Vector(direction).normalized()
    up = Vector((0.0, 0.0, 1.0))
    if abs(direction.dot(up)) > 0.94:
        up = Vector((1.0, 0.0, 0.0))
    side = direction.cross(up).normalized()
    side = Matrix.Rotation(roll, 3, direction) @ side
    other = direction.cross(side).normalized()

    bm = bmesh.new()
    rings = []
    for t, s in zip([0.0, 0.34, 0.66, 0.88], [1.0, 0.82, 0.52, 0.24]):
        point = Vector(base) + direction * (length * t)
        ring = []
        for i in range(sides):
            ang = (2.0 * math.pi * i / sides) + roll
            r = radius * s
            ring.append(
                bm.verts.new(point + side * (math.cos(ang) * r * 1.35) + other * (math.sin(ang) * r * 0.55))
            )
        rings.append(ring)
    tip = bm.verts.new(Vector(base) + direction * length)
    bm.verts.ensure_lookup_table()

    for i in range(len(rings) - 1):
        for j in range(sides):
            bm.faces.new(
                (
                    rings[i][j],
                    rings[i][(j + 1) % sides],
                    rings[i + 1][(j + 1) % sides],
                    rings[i + 1][j],
                )
            )
    for j in range(sides):
        bm.faces.new((rings[-1][j], rings[-1][(j + 1) % sides], tip))
    bm.faces.new(tuple(reversed(rings[0])))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    # The blade body stays dark mineral; only the outer section carries
    # resonance, so emission is restrained and reads as flow out of the frame.
    for face in bm.faces:
        centre = face.calc_center_median()
        t = (centre - Vector(base)).dot(direction) / length
        face.material_index = 1 if t > 0.30 else 0
    return object_from_bmesh(name, bm, materials, parent)


FRAGMENT_POINTS = [
    (1.00, 0.10, 0.16),
    (0.10, 0.92, 0.30),
    (-0.62, 0.46, -0.34),
    (-0.34, -0.78, 0.42),
    (0.18, -0.52, -0.66),
    (0.44, 0.58, 0.50),
]


def build_fragment(name, parent, materials, location, scale, rotation=(0.0, 0.0, 0.0)):
    """Small angular chip of the same mineral, partly embedded in the body."""
    bm = bmesh.new()
    for p in FRAGMENT_POINTS:
        bm.verts.new(p)
    bm.verts.ensure_lookup_table()
    result = bmesh.ops.convex_hull(bm, input=bm.verts)
    interior = [g for g in result["geom_interior"] if isinstance(g, bmesh.types.BMVert)]
    if interior:
        bmesh.ops.delete(bm, geom=interior, context="VERTS")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = object_from_bmesh(name, bm, materials, parent)
    obj.location = location
    obj.scale = (scale, scale * 0.78, scale * 0.62)
    obj.rotation_euler = rotation
    return obj


def build_bracket(name, parent, materials, position, size, rotation=(0.0, 0.0, 0.0)):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for vert in bm.verts:
        vert.co.x *= size[0]
        vert.co.y *= size[1]
        vert.co.z *= size[2]
    bmesh.ops.bevel(
        bm,
        geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
        offset=min(size) * 0.28,
        segments=1,
        affect="EDGES",
    )
    obj = object_from_bmesh(name, bm, materials, parent)
    obj.location = position
    obj.rotation_euler = rotation
    return obj


# ---------------------------------------------------------------------------
# assembly
# ---------------------------------------------------------------------------
def build():
    clear_scene()

    core_mat = make_material(
        "Echo_Core_Mineral", (0.222, 0.168, 0.226), metallic=0.14, roughness=0.42
    )
    frame_mat = make_material(
        "Echo_Frame_Oxidized", (0.176, 0.224, 0.202), metallic=0.48, roughness=0.54
    )
    resonance_mat = make_material(
        "Echo_Resonance_Violet",
        (0.300, 0.092, 0.190),
        metallic=0.15,
        roughness=0.30,
        emission=(0.520, 0.140, 0.300),
        emission_strength=1.90,
    )
    gold_mat = make_material(
        "Echo_Gold_Tarnish",
        (0.300, 0.216, 0.098),
        metallic=0.66,
        roughness=0.44,
        emission=(0.400, 0.262, 0.095),
        emission_strength=0.22,
    )

    core_mats = [core_mat, resonance_mat, frame_mat]
    frame_mats = [frame_mat]
    gold_mats = [gold_mat]
    shard_mats = [core_mat, resonance_mat]

    root = bpy.data.objects.new("Echo_Production", None)
    bpy.context.collection.objects.link(root)

    build_core(root, core_mats)


    # --- lower collar: an interrupted band clamping the body ---------------
    build_arc(
        "Echo_Frame_Collar",
        root,
        frame_mats,
        center=(0.00, -0.12, 0.00),
        normal=(0.14, 0.12, 0.98),
        radius=0.415,
        arc_start=math.radians(112),
        arc_span=math.radians(236),
        segments=18,
        half_w=0.036,
        half_h=0.088,
        width_fn=lambda t: 1.0 + 0.26 * math.sin(math.pi * t) - 0.20 * max(0.0, math.cos(3.2 * t)),
        twist=0.18,
    )

    # --- upper collar, tilted the other way so the bind reads as layered ----
    build_arc(
        "Echo_Frame_Upper_Collar",
        root,
        frame_mats,
        center=(-0.02, 0.24, 0.02),
        normal=(0.32, 0.16, 0.93),
        radius=0.375,
        arc_start=math.radians(38),
        arc_span=math.radians(178),
        segments=12,
        half_w=0.030,
        half_h=0.074,
        width_fn=lambda t: 1.0 - 0.22 * t,
        twist=-0.24,
    )

    # --- diagonal strap crossing the front of the body ---------------------
    build_arm(
        "Echo_Frame_Strap",
        root,
        frame_mats,
        [
            (-0.46, 0.30, 0.16),
            (-0.14, 0.08, 0.34),
            (0.22, -0.16, 0.26),
            (0.46, -0.36, 0.06),
        ],
        half_w=0.026,
        half_h=0.060,
        up_hint=(0.16, 0.20, 0.96),
        width_fn=lambda t: 0.78 + 0.48 * math.sin(math.pi * t) ** 0.8,
        per_segment=4,
        broken_start=True,
        broken_end=True,
    )

    # --- snapped arm jutting away from the lower right ---------------------
    build_arm(
        "Echo_Frame_Snapped_Arm",
        root,
        frame_mats,
        [
            (0.24, -0.26, 0.06),
            (0.44, -0.42, 0.02),
            (0.54, -0.54, -0.04),
        ],
        half_w=0.046,
        half_h=0.090,
        up_hint=(0.50, -0.60, 0.62),
        width_fn=lambda t: 1.0 - 0.18 * t,
        per_segment=4,
        broken_end=True,
    )

    # --- fracture chips: mineral that split but has not fallen away --------
    build_fragment("Echo_Core_Chip_A", root, core_mats, (-0.26, 0.30, 0.10), 0.20, (0.4, 0.2, 0.9))
    build_fragment("Echo_Core_Chip_B", root, core_mats, (0.28, -0.32, 0.04), 0.17, (-0.3, 0.8, 0.2))

    # --- detached remnant of the former hoop, up and to the right ----------
    build_arc(
        "Echo_Frame_Hoop_Remnant",
        root,
        frame_mats,
        center=(0.16, 0.34, -0.06),
        normal=(0.34, 0.52, 0.78),
        radius=0.80,
        arc_start=math.radians(212),
        arc_span=math.radians(88),
        segments=10,
        half_w=0.032,
        half_h=0.086,
        width_fn=lambda t: 1.0 - 0.28 * t,
    )

    # --- mechanical brackets at the junctions ------------------------------
    build_bracket("Echo_Bracket_01", root, gold_mats, (0.30, -0.20, 0.24), (0.076, 0.066, 0.062), (0.3, 0.4, 0.5))
    build_bracket("Echo_Bracket_02", root, gold_mats, (-0.30, 0.20, 0.20), (0.068, 0.062, 0.056), (0.5, -0.2, 0.9))
    build_bracket("Echo_Bracket_03", root, gold_mats, (-0.26, -0.24, -0.22), (0.064, 0.058, 0.052), (-0.4, 0.7, 0.2))
    build_bracket("Echo_Bracket_04", root, frame_mats, (0.24, 0.34, -0.26), (0.054, 0.050, 0.046), (0.7, 0.3, -0.3))

    # --- resonance shards growing out of the frame junctions ---------------
    build_shard(
        "Echo_Resonance_Shard_01",
        root,
        shard_mats,
        base=(0.34, -0.14, 0.14),
        direction=(0.74, -0.28, 0.61),
        length=0.66,
        radius=0.086,
        roll=0.5,
    )
    build_shard(
        "Echo_Resonance_Shard_02",
        root,
        shard_mats,
        base=(-0.32, 0.26, 0.14),
        direction=(-0.66, 0.30, 0.69),
        length=0.50,
        radius=0.068,
        roll=-0.4,
    )
    build_shard(
        "Echo_Resonance_Shard_03",
        root,
        shard_mats,
        base=(0.02, 0.22, -0.26),
        direction=(0.14, 0.58, -0.80),
        length=0.42,
        radius=0.056,
        roll=0.9,
    )


    root["asset_role"] = "single production hero asset"
    root["pipeline"] = "Blender 4.3.2 -> glTF 2.0 -> Godot 4.7.2"
    root["design_language"] = "dark mineral, oxidized metal, restrained resonance"
    root["revision"] = "echo-hero-revision-2"

    # Bake the gameplay scale into the geometry about the assembly pivot.
    for obj in root.children:
        if obj.type == "MESH":
            for vert in obj.data.vertices:
                vert.co *= ASSET_SCALE
            obj.location = obj.location * ASSET_SCALE

    bpy.context.view_layer.objects.active = root
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for obj in root.children:
        obj.select_set(True)

    os.makedirs(os.path.dirname(SOURCE_BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=SOURCE_BLEND)
    bpy.ops.export_scene.gltf(
        filepath=EXPORT_GLB,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_materials="EXPORT",
        export_cameras=False,
        export_lights=False,
    )

    triangles = 0
    for obj in root.children:
        if obj.type == "MESH":
            obj.data.calc_loop_triangles()
            triangles += len(obj.data.loop_triangles)
    print(
        "ECHO_EXPORT_COMPLETE objects=%d triangles=%d materials=%d"
        % (len(root.children), triangles, len(bpy.data.materials))
    )


if __name__ == "__main__":
    build()
