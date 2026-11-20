"""First-person hero props: the flashlight in a gloved right hand, the HX-7 receiver in a gloved left hand,
with jacket sleeves. Godot camera-space metres; each prop is modelled in its own frame (torch axis = Z, lens at -Z;
receiver front face at +Z, facing the camera)."""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dflib import *
import bmesh

OUT = sys.argv[-1]
reset()

def skin_graph(name, pts, edges, radii, root, matname, sub=2):
    names = list(pts.keys()); idx = {n: i for i, n in enumerate(names)}
    me = bpy.data.meshes.new(name); me.from_pydata([G(*pts[n]) for n in names], [(idx[a], idx[b]) for a, b in edges], [])
    ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob)
    ob.modifiers.new("skin", 'SKIN')
    for n in names:
        r = radii[n]; d = me.skin_vertices[0].data[idx[n]]; d.radius = (r, r) if not isinstance(r, tuple) else r
    me.skin_vertices[0].data[idx[root]].use_root = True
    s = ob.modifiers.new("sub", 'SUBSURF'); s.levels = sub; s.render_levels = sub
    me.materials.append(mat(matname))
    ob = realize(ob)
    for p in ob.data.polygons: p.use_smooth = True
    return ob

def ring_pt(theta_deg, r, z):
    a = math.radians(theta_deg); return (r * math.cos(a), r * math.sin(a), z)

# ================================================================== flashlight (right hand)
T = collection("torch"); objs = []
def T_(o): objs.append(o); return o
T_(cyl("tail", 0.0138, 0.02, (0, 0, 0.075), "M_TorchAlu", axis='z', seg=32, bevel=0.0015, coll=T))
T_(cyl("tail_btn", 0.0075, 0.006, (0, 0, 0.087), "M_RubberDark", axis='z', seg=24, bevel=0.0015, coll=T))
for k in range(3): T_(cyl("tail_ring", 0.0141, 0.0016, (0, 0, 0.068 + k * 0.004), "M_TorchAlu", axis='z', seg=32, coll=T))
T_(cyl("body", 0.0128, 0.098, (0, 0, 0.016), "M_TorchKnurl", axis='z', seg=40, coll=T))
T_(cyl("body_band", 0.0133, 0.012, (0, 0, -0.03), "M_TorchAlu", axis='z', seg=40, bevel=0.001, coll=T))
T_(cyl("head_cone", 0.0135, 0.026, (0, 0, -0.049), "M_TorchAlu", axis='z', seg=40, r2=0.0178, coll=T))
T_(cyl("bezel", 0.0182, 0.01, (0, 0, -0.067), "M_TorchAlu", axis='z', seg=40, bevel=0.0012, coll=T))
for k in range(6):
    a = k * math.pi / 3
    T_(box("crenel", (0.006, 0.004, 0.004), (math.cos(a) * 0.0176, math.sin(a) * 0.0176, -0.0735), "M_TorchAlu", 0.0008, 1, rot=(0, 0, math.degrees(a)), coll=T))
refl = cyl("reflector", 0.0165, 0.012, (0, 0, -0.064), "M_Chrome", axis='z', seg=40, r2=0.004, caps=False, coll=T); T_(refl)
T_(cyl("led", 0.0028, 0.002, (0, 0, -0.0585), "M_LEDEmit", axis='z', seg=12, coll=T))
T_(disc("lens", 0.0162, 0.0012, (0, 0, -0.0718), (0, 0, -1), "M_Lens", seg=40, coll=T))
T_(box("clip", (0.004, 0.0016, 0.05), (0.0, 0.0136, 0.045), "M_Steel", 0.0006, 1, coll=T))
T_(box("clip_tab", (0.0045, 0.004, 0.006), (0.0, 0.0128, 0.068), "M_Steel", 0.0006, 1, coll=T))
# right glove: palm on the right, fingers wrapping under to the left, thumb over the top
P = {"wrist": (0.03, -0.034, 0.112), "palm_b": (0.036, -0.03, 0.08), "palm_m": (0.038, -0.022, 0.046), "palm_f": (0.034, -0.016, 0.012)}
E = [("wrist", "palm_b"), ("palm_b", "palm_m"), ("palm_m", "palm_f")]
Rr = {"wrist": 0.026, "palm_b": 0.024, "palm_m": 0.022, "palm_f": 0.019}
for i in range(4):
    z = -0.004 + 0.0185 * i
    sc = 1.0 - 0.06 * i
    P[f"m{i}"] = ring_pt(-30, 0.037, z); P[f"p{i}"] = ring_pt(-100, 0.029, z + 0.002)
    P[f"d{i}"] = ring_pt(-155, 0.0255, z + 0.003); P[f"t{i}"] = ring_pt(-200 + 10 * (i == 3), 0.0235 - 0.001 * i, z + 0.003)
    E += [("palm_m" if i in (1, 2) else ("palm_f" if i == 0 else "palm_b"), f"m{i}"), (f"m{i}", f"p{i}"), (f"p{i}", f"d{i}"), (f"d{i}", f"t{i}")]
    Rr.update({f"m{i}": 0.0108 * sc, f"p{i}": 0.0098 * sc, f"d{i}": 0.0088 * sc, f"t{i}": 0.0078 * sc})
P.update({"th0": (0.038, -0.006, 0.075), "th1": ring_pt(28, 0.034, 0.05), "th2": ring_pt(75, 0.027, 0.026), "th3": ring_pt(98, 0.024, 0.008)})
E += [("palm_b", "th0"), ("th0", "th1"), ("th1", "th2"), ("th2", "th3")]
Rr.update({"th0": 0.015, "th1": 0.0125, "th2": 0.011, "th3": 0.0095})
glove_r = skin_graph("glove_r", P, E, Rr, "wrist", "M_Glove")
objs.append(glove_r)
T_(cyl("cuff_r", 0.03, 0.04, (0.034, -0.045, 0.14), "M_Cuff", axis='z', seg=28, bevel=0.004, coll=T)).rotation_euler = Euler((math.radians(-14), math.radians(-6), 0))
sl = tube_path("sleeve_r", [(0.035, -0.048, 0.15), (0.045, -0.07, 0.3), (0.06, -0.1, 0.5)], 0.043, "M_Sleeve", coll=T, res=8); objs.append(sl)
sl2 = tube_path("sleeve_r_strip", [(0.035, -0.049, 0.19), (0.04, -0.056, 0.215)], 0.0442, "M_Reflective", coll=T, res=4); objs.append(sl2)
ms = [realize(o) if (o.type == 'CURVE' or o.modifiers) else o for o in objs]
for o in ms:
    if o.name not in ("lens",): world_uv(o, 1.0)
join("fp_torch", ms)
export(os.path.join(OUT, "fp_torch.gltf"), T)

# ================================================================== HX-7 receiver (left hand)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete()
R = collection("radio"); objs = []
def R_(o): objs.append(o); return o
R_(box("rx_body", (0.076, 0.162, 0.036), (0, 0, 0), "M_RxRubber", 0.008, 3, coll=R))
R_(box("rx_plate", (0.064, 0.096, 0.004), (0, 0.024, 0.0175), "M_RxPlate", 0.0015, 2, coll=R))
R_(quad("rx_lcd", 0.05, 0.022, (0, 0.05, 0.0198), (0, 0, 1), "M_RxLCD", coll=R))
R_(box("rx_lcd_frame", (0.055, 0.027, 0.0012), (0, 0.05, 0.0188), "M_RubberDark", 0.0005, 1, coll=R))
R_(quad("rx_label", 0.056, 0.014, (0, 0.024, 0.0198), (0, 0, 1), "M_RxLabel", coll=R))
for k in range(3):
    R_(box("rx_btn", (0.012, 0.008, 0.004), (-0.02 + k * 0.02, 0.008, 0.0198), "M_RubberDark", 0.0015, 2, coll=R))
R_(quad("rx_grille", 0.058, 0.04, (0, -0.048, 0.0187), (0, 0, 1), "M_RxGrille", coll=R))
R_(box("rx_grille_rim", (0.062, 0.044, 0.001), (0, -0.048, 0.0176), "M_RxPlate", 0.0004, 1, coll=R))
R_(cyl("rx_tune", 0.0125, 0.014, (0.022, 0.088, 0.0), "M_KnobKnurl", axis='y', seg=32, bevel=0.0012, coll=R))
R_(cyl("rx_tune_cap", 0.0085, 0.003, (0.022, 0.0965, 0.0), "M_RxPlate", axis='y', seg=24, coll=R))
R_(cyl("rx_vol", 0.0082, 0.011, (-0.022, 0.087, 0.0), "M_KnobKnurl", axis='y', seg=24, bevel=0.001, coll=R))
R_(cyl("rx_ant_base", 0.0065, 0.012, (0.0, 0.087, -0.008), "M_RubberDark", axis='y', seg=20, bevel=0.0015, coll=R))
for k, (r, L) in enumerate([(0.0042, 0.11), (0.0033, 0.11), (0.0024, 0.1)]):
    y0 = 0.093 + sum([0.11, 0.11, 0.1][:k]) - 0.006 * k
    R_(cyl("rx_ant", r, L, (0.0, y0 + L / 2, -0.008), "M_Chrome", axis='y', seg=14, coll=R))
R_(cyl("rx_ant_tip", 0.0034, 0.006, (0.0, 0.093 + 0.32 - 0.012, -0.008), "M_RubberDark", axis='y', seg=12, coll=R))
R_(quad("rx_meter", 0.024, 0.012, (0.0, 0.071, 0.0198), (0, 0, 1), "M_RxMeter", coll=R))
for sx in (-1, 1):
    R_(box("rx_side_btn", (0.004, 0.018, 0.01), (sx * 0.039, 0.03, 0.0), "M_RubberDark", 0.0015, 2, coll=R))
R_(box("rx_belt", (0.03, 0.06, 0.006), (0.0, 0.01, -0.021), "M_RubberDark", 0.002, 2, coll=R))
# left glove gripping the lower half from the left/back, thumb on the front edge
P = {"wrist": (-0.064, -0.112, -0.022), "palm_b": (-0.06, -0.082, -0.02), "palm_m": (-0.056, -0.05, -0.02), "palm_f": (-0.052, -0.02, -0.02)}
E = [("wrist", "palm_b"), ("palm_b", "palm_m"), ("palm_m", "palm_f")]
Rr = {"wrist": 0.026, "palm_b": 0.024, "palm_m": 0.022, "palm_f": 0.019}
for i in range(4):
    y = -0.006 - 0.0185 * i; sc = 1.0 - 0.06 * i
    P[f"m{i}"] = (-0.048, y, -0.022); P[f"p{i}"] = (-0.022, y - 0.002, -0.031)
    P[f"d{i}"] = (0.014, y - 0.003, -0.03); P[f"t{i}"] = (0.042, y - 0.004, -0.014)
    E += [("palm_f" if i == 0 else ("palm_m" if i in (1, 2) else "palm_b"), f"m{i}"), (f"m{i}", f"p{i}"), (f"p{i}", f"d{i}"), (f"d{i}", f"t{i}")]
    Rr.update({f"m{i}": 0.0108 * sc, f"p{i}": 0.0098 * sc, f"d{i}": 0.0088 * sc, f"t{i}": 0.0078 * sc})
P.update({"th0": (-0.062, -0.07, 0.004), "th1": (-0.052, -0.048, 0.022), "th2": (-0.043, -0.03, 0.028), "th3": (-0.036, -0.014, 0.027)})
E += [("palm_b", "th0"), ("th0", "th1"), ("th1", "th2"), ("th2", "th3")]
Rr.update({"th0": 0.015, "th1": 0.0125, "th2": 0.011, "th3": 0.0095})
objs.append(skin_graph("glove_l", P, E, Rr, "wrist", "M_Glove"))
R_(cyl("cuff_l", 0.03, 0.04, (-0.068, -0.136, -0.016), "M_Cuff", axis='y', seg=28, bevel=0.004, coll=R)).rotation_euler = Euler((math.radians(-20), 0, math.radians(-12)))
objs.append(tube_path("sleeve_l", [(-0.07, -0.15, -0.012), (-0.09, -0.28, 0.08), (-0.12, -0.45, 0.25)], 0.043, "M_Sleeve", coll=R, res=8))
objs.append(tube_path("sleeve_l_strip", [(-0.074, -0.18, 0.002), (-0.08, -0.205, 0.018)], 0.0442, "M_Reflective", coll=R, res=4))
ms = [realize(o) if (o.type == 'CURVE' or o.modifiers) else o for o in objs]
for o in ms:
    if not o.name.startswith(("rx_lcd", "rx_label", "rx_grille", "rx_meter")) or o.name.endswith(("_frame", "_rim")):
        world_uv(o, 1.0)
tex = [o for o in ms if o.name.startswith(("rx_lcd", "rx_label", "rx_grille", "rx_meter")) and not o.name.endswith(("_frame", "_rim"))]
# the knobs stay separate so the game can turn them: origin on the knob axis
knobs = {}
for nm in ("rx_tune", "rx_tune_cap", "rx_vol"):
    o = [x for x in ms if x.name == nm]
    if o: knobs[nm] = o[0]
join("fp_radio_screens", tex)
if "rx_tune" in knobs and "rx_tune_cap" in knobs:
    t = join("rx_tune_knob", [knobs["rx_tune"], knobs["rx_tune_cap"]])
    knobs = {"rx_tune_knob": t, "rx_vol": knobs.get("rx_vol")}
for nm, o in knobs.items():
    if o is None: continue
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active = o
    c = sum((o.matrix_world @ v.co for v in o.data.vertices), Vector()) / len(o.data.vertices)
    bpy.context.scene.cursor.location = c
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    o.name = "TuneKnob" if nm == "rx_tune_knob" else "VolKnob"
join("fp_radio", [o for o in R.all_objects if o.type == 'MESH' and o.name not in ("fp_radio_screens", "TuneKnob", "VolKnob")])
export(os.path.join(OUT, "fp_radio.gltf"), R)
