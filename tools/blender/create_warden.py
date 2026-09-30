"""The Grotto - authored Resonant Warden production hero asset.

Deterministic Blender 4.3.2 -> glTF 2.0 GLB authoring pass.
The Warden is an architectural guardian, not an enlarged Echo: a tall
faceted mineral/metal body with asymmetric shoulder masses, broken buttresses,
and an integrated resonance mechanism protected by interrupted structural ribs.

Run from the repository root:
    blender --background --factory-startup --python tools/blender/create_warden.py
"""
import math
import os
import bmesh
import bpy
from mathutils import Vector, Matrix

EXPORT_GLB = "/home/ubuntu/The-Grotto/assets/models/warden_production.glb"
SOURCE_BLEND = "/home/ubuntu/build/warden_production.blend"


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for coll in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for item in list(coll):
            coll.remove(item)


def mat(name, base, metallic=0.0, rough=0.75, emission=None, strength=0.0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*base, 1)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*base, 1)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = rough
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1)
        bsdf.inputs["Emission Strength"].default_value = strength
    return m


def mesh_obj(name, bm, materials, parent):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    for m in materials:
        me.materials.append(m)
    bpy.context.collection.objects.link(ob)
    ob.parent = parent
    return ob


def hull(name, points, materials, parent, material_index=0, scale=(1, 1, 1), rotation=(0, 0, 0)):
    bm = bmesh.new()
    for p in points:
        bm.verts.new(p)
    bm.verts.ensure_lookup_table()
    result = bmesh.ops.convex_hull(bm, input=bm.verts)
    interior = [g for g in result["geom_interior"] if isinstance(g, bmesh.types.BMVert)]
    if interior:
        bmesh.ops.delete(bm, geom=interior, context="VERTS")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    for f in bm.faces:
        f.material_index = material_index
    ob = mesh_obj(name, bm, materials, parent)
    ob.scale = scale
    ob.rotation_euler = rotation
    return ob


def basis(normal, up=Vector((0, 1, 0))):
    n = Vector(normal).normalized()
    u = up.cross(n)
    if u.length < 1e-5:
        u = Vector((1, 0, 0)).cross(n)
    u.normalize()
    return u, n.cross(u).normalized(), n


def catmull(p0, p1, p2, p3, t):
    return 0.5 * (2*p1 + (-p0+p2)*t + (2*p0-5*p1+4*p2-p3)*t*t + (-p0+3*p1-3*p2+p3)*t*t*t)


def path_points(control, per=4):
    pts = [Vector(p) for p in control]
    padded = [pts[0]] + pts + [pts[-1]]
    out = []
    for i in range(1, len(padded)-2):
        for j in range(per):
            out.append(catmull(padded[i-1], padded[i], padded[i+1], padded[i+2], j/per))
    out.append(pts[-1])
    return out


def swept(name, control, materials, parent, half_w, half_h, material_index=0, taper=0.18, broken_start=False, broken_end=False, per=4):
    pts = path_points(control, per)
    frames = []
    tangent = (pts[1]-pts[0]).normalized()
    normal = Vector((0, 1, 0)) - tangent * tangent.y
    if normal.length < 1e-5:
        normal = Vector((1, 0, 0))
    normal.normalize()
    frames.append((tangent, normal, tangent.cross(normal).normalized()))
    for i in range(1, len(pts)):
        tangent = (pts[i]-pts[i-1]).normalized()
        rot = frames[-1][0].rotation_difference(tangent)
        normal = (rot @ frames[-1][1]).normalized()
        frames.append((tangent, normal, tangent.cross(normal).normalized()))
    bm = bmesh.new(); rings = []
    for i, p in enumerate(pts):
        t = i/(len(pts)-1); edge = min(t, 1-t)
        s = 1.0 if edge >= taper else 0.34 + 0.66*(edge/taper)**0.55
        tangent, normal, side = frames[i]
        ring = [bm.verts.new(p + normal*a*s + side*b*s) for a,b in ((-half_w,-half_h),(half_w,-half_h),(half_w,half_h),(-half_w,half_h))]
        rings.append(ring)
    for i in range(len(rings)-1):
        for j in range(4):
            bm.faces.new((rings[i][j], rings[i][(j+1)%4], rings[i+1][(j+1)%4], rings[i+1][j]))
    for ring, idx, broken in ((rings[0],0,broken_start),(rings[-1],len(rings)-1,broken_end)):
        if broken:
            tangent, _, side = frames[idx]
            direction = -tangent if idx == 0 else tangent
            tip = pts[idx] + direction * half_h * 1.35 + side * half_h * (-0.5 if idx == 0 else 0.5)
            tv = bm.verts.new(tip)
            for j in range(4): bm.faces.new((ring[j], ring[(j+1)%4], tv))
        else:
            bm.faces.new(tuple(reversed(ring)))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    for f in bm.faces: f.material_index = material_index
    return mesh_obj(name, bm, materials, parent)


def arc(name, center, normal, radius, start, span, materials, parent, half_w, half_h, material_index=0, count=5):
    u, v, _ = basis(normal)
    c = Vector(center)
    control = [c + (u*math.cos(start+span*i/4)+v*math.sin(start+span*i/4))*radius for i in range(5)]
    return swept(name, control, materials, parent, half_w, half_h, material_index, taper=0.22, broken_start=True, broken_end=True, per=max(2,count//2))


def blade(name, base, direction, length, radius, materials, parent, material_index=3):
    d = Vector(direction).normalized(); up = Vector((0,1,0))
    if abs(d.dot(up)) > .9: up = Vector((1,0,0))
    side = d.cross(up).normalized(); other = d.cross(side).normalized()
    bm = bmesh.new(); rings=[]
    for t,s in ((0,1.0),(.30,.88),(.68,.52),(.9,.22)):
        p=Vector(base)+d*length*t; ring=[]
        for i in range(5):
            a=2*math.pi*i/5
            ring.append(bm.verts.new(p + side*math.cos(a)*radius*s*1.2 + other*math.sin(a)*radius*s*.65))
        rings.append(ring)
    tip=bm.verts.new(Vector(base)+d*length)
    for i in range(len(rings)-1):
        for j in range(5): bm.faces.new((rings[i][j],rings[i][(j+1)%5],rings[i+1][(j+1)%5],rings[i+1][j]))
    for j in range(5): bm.faces.new((rings[-1][j],rings[-1][(j+1)%5],tip))
    bm.faces.new(tuple(reversed(rings[0])))
    for f in bm.faces:
        c=f.calc_center_median(); f.material_index = material_index if (c-Vector(base)).dot(d)>length*.25 else 1
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return mesh_obj(name,bm,materials,parent)


def build():
    clear_scene()
    root=bpy.data.objects.new("Warden_Production",None); bpy.context.collection.objects.link(root)
    stone=mat("Warden_Mineral",(0.075,0.055,0.085),0.0,.9)
    oxide=mat("Warden_Oxidized_Metal",(0.12,0.18,0.18),.62,.72)
    tarnish=mat("Warden_Tarnished_Junctions",(0.34,0.25,0.12),.68,.55)
    resonance=mat("Warden_Resonance",(0.22,0.035,0.20),.08,.38,(0.78,0.12,0.55),2.1)
    seam=mat("Warden_Deep_Seams",(0.018,0.012,0.025),0.0,.95)
    mats=[stone,oxide,tarnish,resonance,seam]

    # Primary mineral body: tall, faceted and deliberately offset, with a hollow
    # negative-space channel through the front rather than a humanoid torso.
    body_pts=[(-.42,.15,.10),(.18,.05,.22),(.50,.55,.08),(.35,1.35,.12),(.18,2.10,.08),(-.20,2.42,.02),(-.52,1.74,-.05),(-.56,.82,-.22),(-.16,.58,-.48),(.08,1.22,-.42),(-.22,1.82,-.35),(.26,1.88,.36)]
    body=hull("Warden_Primary_Mineral_Mass",body_pts,mats,root,0,scale=(1.0,1.0,1.0),rotation=(0.0,-.10,.08))
    # Deep inset-like front plates leave the resonance channel visible.
    hull("Warden_Left_RibMass",[(-.44,.55,.12),(-.92,.72,.10),(-.76,1.55,.12),(-.38,1.78,.10),(-.30,1.05,-.18)],mats,root,1,rotation=(.02,.16,-.12))
    hull("Warden_Right_RibMass",[(.28,.68,.12),(.82,.62,.02),(.72,1.54,.10),(.33,1.92,.16),(.25,1.08,-.20)],mats,root,0,rotation=(-.03,-.14,.10))
    # Architectural shoulder masses are intentionally unequal.
    hull("Warden_Left_Shoulder",[(-.35,1.68,.12),(-1.15,1.76,.10),(-1.52,1.44,-.02),(-1.18,1.12,-.16),(-.48,1.30,.02),(-.62,1.93,.18)],mats,root,1,rotation=(0,.08,-.06))
    hull("Warden_Right_Shoulder",[(.34,1.72,.14),(.88,1.92,.12),(1.30,1.54,.00),(1.08,1.22,-.20),(.42,1.36,.02),(.56,2.04,.18)],mats,root,1,rotation=(0,-.08,.10))
    # Broken architectural appendages: left is long and hooked; right is snapped.
    swept("Warden_Left_Buttress",[(-.58,1.52,.02),(-1.02,1.25,.05),(-1.42,.76,.08),(-1.38,.18,-.02),(-1.08,-.05,-.12)],mats,root,.13,.25,1,broken_end=True)
    swept("Warden_Right_Buttress",[(.55,1.48,.08),(.98,1.12,.12),(1.28,.72,.08),(1.18,.38,-.06)],mats,root,.11,.22,1,broken_end=True)
    swept("Warden_Back_Spine",[(-.08,.22,-.25),(.18,.75,-.38),(.05,1.38,-.42),(.22,2.05,-.28),(.02,2.62,-.18)],mats,root,.14,.20,1,broken_end=True)

    # Resonance mechanism: three offset protective ribs around a recessed vertical
    # channel; it is a mechanism embedded in the body, not a chest gem.
    arc("Warden_Resonance_Rib_L",(-.04,1.42,.08),(0,0,1),.70,math.radians(112),math.radians(150),mats,root,.075,.16,1)
    arc("Warden_Resonance_Rib_R",(.02,1.42,.02),(0,0,1),.78,math.radians(-55),math.radians(132),mats,root,.08,.18,1)
    arc("Warden_Resonance_Rib_Lower",(.02,.86,.02),(0,0,1),.58,math.radians(205),math.radians(160),mats,root,.07,.14,2)
    # Recessed resonance blades run vertically inside the guarded channel.
    blade("Warden_Resonance_Vein",(-.05,.56,.22),(.04,.98,.02),1.45,.10,mats,root,3)
    blade("Warden_Resonance_SideVein",(.32,1.02,.16),(-.55,.72,.05),.62,.07,mats,root,3)
    # Broken crown and shoulder shards identify the guardian at distance.
    swept("Warden_Broken_Crown",[(-.52,2.03,-.02),(-.24,2.46,.02),(.18,2.64,-.04),(.62,2.28,.05)],mats,root,.10,.16,1,broken_start=True,broken_end=True)
    blade("Warden_Left_CrownShard",(-.42,2.12,.02),(-.50,.76,.12),.68,.13,mats,root,3)
    blade("Warden_Right_CrownShard",(.56,2.05,.08),(.72,.52,.10),.52,.11,mats,root,3)
    # Tarnished junction wedges make attachment believable without greebles.
    hull("Warden_Left_Junction",[(-.72,1.38,-.02),(-.98,1.47,.04),(-.86,1.68,.12),(-.58,1.58,.14),(-.70,1.46,.30)],mats,root,2)
    hull("Warden_Right_Junction",[(.54,1.42,.02),(.84,1.52,.06),(.72,1.72,.14),(.46,1.64,.12),(.58,1.50,.28)],mats,root,2)
    # Two dark seam wedges reinforce the broken, constructed read.
    hull("Warden_Dark_Fissure_A",[(-.12,1.10,.46),(.03,1.18,.48),(.12,1.76,.42),(-.02,1.67,.40)],mats,root,4)
    hull("Warden_Dark_Fissure_B",[(-.50,.42,.26),(-.35,.48,.30),(-.18,.86,.26),(-.34,.78,.22)],mats,root,4)

    # Scale is intentionally close to the existing runtime Warden visual; the
    # existing CharacterBody3D sphere collider remains authoritative.
    # Blender is Z-up while the construction coordinates above use Y as the
    # readable authoring height. Bake the axis correction into the mesh data so
    # the exported glTF/Godot asset is upright; the root remains transform-free.
    axis_fix = Matrix.Rotation(math.radians(90.0), 4, "X")
    for ob in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
        for vert in ob.data.vertices:
            vert.co = (axis_fix @ vert.co.to_4d()).to_3d()
    root.scale=(1.0,1.0,1.0)
    bpy.context.view_layer.objects.active=root; root.select_set(True)
    bpy.ops.wm.save_as_mainfile(filepath=SOURCE_BLEND)
    os.makedirs(os.path.dirname(EXPORT_GLB),exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=EXPORT_GLB,export_format="GLB",use_selection=True,export_apply=True,export_animations=False)
    tri=sum(len(p.loop_indices)//3 for ob in bpy.context.selected_objects if ob.type=='MESH' for p in ob.data.polygons)
    print(f"WARDEN_EXPORT_COMPLETE objects={len([o for o in bpy.data.objects if o.type=='MESH'])} triangles={tri} materials=5")


if __name__=="__main__":
    build()
