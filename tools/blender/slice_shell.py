"""Vertical slice — architecture: the service corridor (L-shape) and the communications room.
Run:  blender -b --factory-startup --python tools/blender/slice_shell.py -- <out_dir>
Godot coordinates; the gameplay grid has 2 m cells (see game/data/slice.gd)."""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dflib import *

OUT = sys.argv[-1]
random.seed(7)
reset()
H = 3.2          # corridor clear height
RH = 3.8         # room slab height
CH = 3.0         # room suspended ceiling

# ------------------------------------------------------------------ walls with a painted lower band
def band_wall(name, x0, z0, x1, z1, inward, h, coll, lower="M_CorrLower", stripe="M_CorrStripe", upper="M_CorrUpper", t=0.3, y0=0.0, lh=1.1):
    """Wall whose inner face runs from (x0,z0) to (x1,z1); inward = unit (dx,dz) pointing into the room."""
    cx, cz = (x0 + x1) / 2 - inward[0] * t / 2, (z0 + z1) / 2 - inward[1] * t / 2
    L = math.hypot(x1 - x0, z1 - z0)
    along_x = abs(x1 - x0) > abs(z1 - z0)
    def piece(sfx, ya, yb, m):
        sx, sz = (L, t) if along_x else (t, L)
        return box(f"{name}_{sfx}", (sx, yb - ya, sz), (cx, (ya + yb) / 2, cz), m, coll=coll)
    out = [piece("lo", y0, lh, lower), piece("st", lh, lh + 0.1, stripe), piece("up", lh + 0.1, h, upper)]
    return out

def opening_wall(name, x, z0, z1, oz0, oz1, oh, inward, h, coll, **kw):
    """Wall along z (at x) with a door opening oz0..oz1 of height oh."""
    out = []
    out += band_wall(name + "_a", x, z0, x, oz0, inward, h, coll, **kw)
    out += band_wall(name + "_b", x, oz1, x, z1, inward, h, coll, **kw)
    t = 0.3
    out.append(box(name + "_lintel", (t, h - oh, oz1 - oz0), (x - inward[0] * t / 2, (oh + h) / 2, (oz0 + oz1) / 2), kw.get("upper", "M_CorrUpper"), coll=coll))
    return out

def pilaster(name, x, z, inward, h, coll, w=0.42, d=0.14, mat_lo="M_CorrLower", mat_up="M_CorrUpper", mat_st="M_CorrStripe"):
    px, pz = x + inward[0] * d / 2, z + inward[1] * d / 2
    sx, sz = (d, w) if inward[0] != 0 else (w, d)
    obs = [box(name + "_lo", (sx, 1.1, sz), (px, 0.55, pz), mat_lo, 0.012, 2, coll=coll),
           box(name + "_st", (sx + 0.004, 0.1, sz + 0.004), (px, 1.15, pz), mat_st, 0.006, 1, coll=coll),
           box(name + "_up", (sx, h - 1.2, sz), (px, 1.2 + (h - 1.2) / 2, pz), mat_up, 0.012, 2, coll=coll)]
    return obs

# ------------------------------------------------------------------ corridor
C = collection("corridor")
arch = []
# floor: N-S part has a drain channel down the middle (x = 5)
arch.append(box("floor_ns_w", (0.85, 0.3, 13.4), (4.425, -0.15, 15.3), "M_CorrFloor", coll=C))
arch.append(box("floor_ns_e", (0.85, 0.3, 13.4), (5.575, -0.15, 15.3), "M_CorrFloor", coll=C))
arch.append(box("floor_ns_end", (2.0, 0.3, 0.6), (5.0, -0.15, 21.7), "M_CorrFloor", coll=C))
arch.append(box("chan_bottom", (0.3, 0.2, 13.4), (5.0, -0.18, 15.3), "M_ChannelBottom", coll=C))
arch.append(box("floor_ew", (14.0, 0.3, 2.0), (11.0, -0.15, 7.0), "M_CorrFloor", coll=C))
arch.append(box("floor_corner", (2.0, 0.3, 0.6), (5.0, -0.15, 8.3), "M_CorrFloor", coll=C))
arch.append(box("floor_vest", (2.0, 0.3, 2.0), (19.0, -0.15, 7.0), "M_CorrFloor", coll=C))
# ceiling slabs
arch.append(box("ceil_ns", (2.0, 0.3, 14.0), (5.0, H + 0.15, 15.0), "M_CorrCeil", coll=C))
arch.append(box("ceil_ew_a", (5.6, 0.3, 2.0), (7.8, H + 0.15, 7.0), "M_CorrCeil", coll=C))
arch.append(box("ceil_ew_b", (8.6, 0.3, 2.0), (15.7, H + 0.15, 7.0), "M_CorrCeil", coll=C))
arch.append(box("ceil_ew_v1", (0.8, 0.3, 0.6), (11.0, H + 0.15, 6.3), "M_CorrCeil", coll=C))   # around the vent hole
arch.append(box("ceil_ew_v2", (0.8, 0.3, 0.7), (11.0, H + 0.15, 7.65), "M_CorrCeil", coll=C))
arch.append(box("ceil_vest", (2.0, 0.3, 2.0), (19.0, H + 0.15, 7.0), "M_CorrCeil", coll=C))
# vent shaft above the hole (x 10.6..11.4, z 6.6..7.3)
for nm, sz, ps in [("vent_n", (0.8, 0.9, 0.04), (11.0, H + 0.45, 6.58)), ("vent_s", (0.8, 0.9, 0.04), (11.0, H + 0.45, 7.32)),
                   ("vent_w", (0.04, 0.9, 0.74), (10.58, H + 0.45, 6.95)), ("vent_e", (0.04, 0.9, 0.74), (11.42, H + 0.45, 6.95)),
                   ("vent_top", (0.8, 0.04, 0.74), (11.0, H + 0.88, 6.95))]:
    arch.append(box(nm, sz, ps, "M_DuctInside", coll=C))
arch.append(box("vent_lip", (0.9, 0.05, 0.84), (11.0, H - 0.01, 6.95), "M_Steel", 0.01, 1, coll=C))
# walls
arch += band_wall("w_ns_west", 4, 6, 4, 22, (1, 0), H, C)
arch += band_wall("w_ns_east", 6, 8, 6, 22, (-1, 0), H, C)
arch += band_wall("w_ew_north", 4, 6, 19.7, 6, (0, 1), H, C)
arch += band_wall("w_ew_south", 6, 8, 19.7, 8, (0, -1), H, C)
arch += band_wall("w_ns_end", 3.7, 22, 6.3, 22, (0, -1), H, C)
arch += band_wall("w_corner_west", 3.7, 5.7, 4.0, 5.7, (0, 1), H, C)
# pilasters + ceiling beams every 4 m
beams = []
for z in (10.0, 14.0, 18.0):
    arch += pilaster(f"pil_w{int(z)}", 4.0, z, (1, 0), H, C)
    arch += pilaster(f"pil_e{int(z)}", 6.0, z, (-1, 0), H, C)
    beams.append(box(f"beam_ns{int(z)}", (2.0, 0.28, 0.42), (5.0, H - 0.14, z), "M_Beam", 0.015, 2, coll=C))
for x in (8.0, 12.0, 16.0):
    arch += pilaster(f"pil_n{int(x)}", x, 6.0, (0, 1), H, C)
    arch += pilaster(f"pil_s{int(x)}", x, 8.0, (0, -1), H, C)
    beams.append(box(f"beam_ew{int(x)}", (0.42, 0.28, 2.0), (x, H - 0.14, 7.0), "M_Beam", 0.015, 2, coll=C))
arch += beams
# drain grate over the channel: bars across a frame
gr = []
gr.append(box("grate_rail_w", (0.03, 0.03, 13.4), (4.865, -0.015, 15.3), "M_Grate", 0.004, 1, coll=C))
gr.append(box("grate_rail_e", (0.03, 0.03, 13.4), (5.135, -0.015, 15.3), "M_Grate", 0.004, 1, coll=C))
z = 8.62
while z < 21.98:
    gr.append(box("grate_bar", (0.25, 0.025, 0.012), (5.0, -0.0135, z), "M_Grate", coll=C)); z += 0.045
grate = join("drain_grate", gr)
# hazard threshold + floor safety lines
arch.append(box("hazard_vest", (0.25, 0.006, 1.9), (18.3, 0.003, 7.0), "M_Hazard", coll=C))
arch.append(box("line_ns_w", (0.08, 0.004, 13.2), (4.35, 0.002, 15.4), "M_FloorPaint", coll=C))
arch.append(box("line_ns_e", (0.08, 0.004, 13.2), (5.65, 0.002, 15.4), "M_FloorPaint", coll=C))
arch.append(box("line_ew_n", (13.0, 0.004, 0.08), (11.5, 0.002, 6.35), "M_FloorPaint", coll=C))
arch.append(box("line_ew_s", (12.6, 0.004, 0.08), (12.3, 0.002, 7.65), "M_FloorPaint", coll=C))
for o in arch: world_uv(realize(o) if False else o)
corr = [realize(o) for o in list(C.all_objects)]
for o in corr: world_uv(o, 1.0)
join("corridor_arch", [o for o in corr if o.name != "drain_grate"])

# ------------------------------------------------------------------ corridor services: pipes, hangers, tray, cables, conduits
S = collection("services")
pipes = []
for i, (off, r, m, y) in enumerate([(0.24, 0.085, "M_PipeGreen", 2.72), (0.46, 0.06, "M_PipeRed", 2.78), (0.64, 0.045, "M_PipeGrey", 2.84)]):
    x = 4.0 + off; zz = 6.0 + off
    pts = [(x, y, 22.3)]
    pts += [(x, y, zz + 0.35), (x + 0.12, y, zz + 0.06), (x + 0.35, y, zz)]
    pts += [(20.0, y, zz)]
    p = poly_tube(f"pipe{i}", [pts[0], pts[1]], r, m, coll=S); pipes.append(p)
    pipes.append(tube_path(f"pipe{i}_bend", [pts[1], (x + 0.02, y, zz + 0.12), pts[3]], r, m, coll=S))
    pipes.append(poly_tube(f"pipe{i}_b", [pts[3], pts[4]], r, m, coll=S))
    # flanges every 3 m and at the bend
    for zf in (19.0, 16.0, 13.0, 10.0, 7.2):
        pipes.append(cyl(f"fl{i}_{zf}", r + 0.022, 0.03, (x, y, zf), "M_PipeFlange", axis='z', seg=20, bevel=0.004, coll=S))
    for xf in (7.5, 10.5, 13.5, 16.5, 19.4):
        pipes.append(cyl(f"flx{i}_{xf}", r + 0.022, 0.03, (xf, y, zz), "M_PipeFlange", axis='x', seg=20, bevel=0.004, coll=S))
# a valve with a hand wheel on the green pipe
pipes.append(cyl("valve_body", 0.11, 0.18, (4.24, 2.72, 12.6), "M_PipeFlange", axis='z', seg=20, bevel=0.01, coll=S))
pipes.append(cyl("valve_stem", 0.015, 0.22, (4.24 + 0.15, 2.72, 12.6), "M_Steel", axis='x', seg=10, coll=S))
wheel = bpy.data.objects.new("valve_wheel", None)
import bmesh as _bm
bmw = _bm.new(); _bm.ops.create_circle(bmw, cap_ends=False, segments=24, radius=0.13)
me = bpy.data.meshes.new("valve_wheel_ring"); bmw.to_mesh(me); bmw.free()
ring = bpy.data.objects.new("valve_wheel_ring", me); S.objects.link(ring)
ring.location = G(4.24 + 0.27, 2.72, 12.6); ring.rotation_euler = Euler((0, math.radians(90), 0))
sk = ring.modifiers.new("skin", 'SKIN'); ring.data.materials.append(mat("M_ValveRed"))
for v in ring.data.skin_vertices[0].data: v.radius = (0.012, 0.012)
ring.modifiers.new("sub", 'SUBSURF').levels = 1
for k in range(4):
    a = k * math.pi / 2
    pipes.append(cyl(f"spoke{k}", 0.008, 0.13, (4.24 + 0.27, 2.72 + math.sin(a) * 0.065, 12.6 + math.cos(a) * 0.065), "M_ValveRed", axis='y', seg=8, coll=S))
    pipes[-1].rotation_euler = Euler((a, 0, 0))
# hangers: steel straps from the beams around the pipe bundle
for z in (10.0, 14.0, 18.0):
    pipes.append(box(f"hanger_rod{z}", (0.75, 0.04, 0.04), (4.45, 2.92, z + 0.25), "M_Steel", 0.004, 1, coll=S))
    for k, xo in enumerate((4.24, 4.46, 4.64)):
        pipes.append(box(f"hanger_v{z}_{k}", (0.012, 0.22, 0.03), (xo + 0.1, 2.82, z + 0.25), "M_Steel", coll=S))
for x in (8.0, 12.0, 16.0):
    pipes.append(box(f"hanger_rx{x}", (0.04, 0.04, 0.75), (x + 0.25, 2.92, 6.45), "M_Steel", 0.004, 1, coll=S))
# cable tray: east wall of N-S, south wall of E-W
def tray_run(name, a, b, along):
    out = []
    L = abs(b - a); c = (a + b) / 2
    if along == 'z':
        out.append(box(name + "_bot", (0.3, 0.008, L), (5.75, 2.52, c), "M_TrayGalv", coll=S))
        out.append(box(name + "_l", (0.006, 0.08, L), (5.6, 2.56, c), "M_TrayGalv", coll=S))
        out.append(box(name + "_r", (0.006, 0.08, L), (5.9, 2.56, c), "M_TrayGalv", coll=S))
        z = min(a, b) + 0.6
        while z < max(a, b):
            out.append(box(name + "_br", (0.34, 0.03, 0.03), (5.78, 2.5, z), "M_Steel", 0.003, 1, coll=S))
            out.append(box(name + "_bw", (0.03, 0.25, 0.03), (5.96, 2.62, z), "M_Steel", 0.003, 1, coll=S)); z += 1.5
    else:
        out.append(box(name + "_bot", (L, 0.008, 0.3), (c, 2.52, 7.75), "M_TrayGalv", coll=S))
        out.append(box(name + "_l", (L, 0.08, 0.006), (c, 2.56, 7.6), "M_TrayGalv", coll=S))
        out.append(box(name + "_r", (L, 0.08, 0.006), (c, 2.56, 7.9), "M_TrayGalv", coll=S))
        x = min(a, b) + 0.6
        while x < max(a, b):
            out.append(box(name + "_br", (0.03, 0.03, 0.34), (x, 2.5, 7.78), "M_Steel", 0.003, 1, coll=S))
            out.append(box(name + "_bw", (0.03, 0.25, 0.03), (x, 2.62, 7.96), "M_Steel", 0.003, 1, coll=S)); x += 1.5
    return out
tray = tray_run("tray_ns", 8.3, 21.8, 'z') + tray_run("tray_ew", 6.3, 19.7, 'x')
cables = []
for k in range(6):
    xo = 5.66 + k * 0.042; yo = 2.545 + (k % 2) * 0.02
    pts = [(xo, yo, 21.9)]
    z = 21.0
    while z > 8.8:
        pts.append((xo + random.uniform(-0.01, 0.01), yo, z)); z -= 2.5
    pts += [(xo, yo, 8.2 - k * 0.04), (6.2 + k * 0.03, yo, 7.66 + k * 0.042)]
    x = 8.0
    while x < 19.5:
        pts.append((x, yo, 7.66 + k * 0.042 + random.uniform(-0.008, 0.008))); x += 2.5
    pts.append((19.9, yo, 7.66 + k * 0.042))
    cables.append(tube_path(f"cable{k}", pts, 0.011 + 0.004 * (k % 3), "M_CableBlack" if k % 3 else "M_CableGrey", coll=S, res=8))
# a cable that has slipped out of the tray and hangs in a loop
cables.append(tube_path("cable_loop", [(5.62, 2.56, 16.4), (5.55, 2.2, 15.9), (5.5, 1.75, 15.2), (5.56, 2.15, 14.5), (5.63, 2.56, 14.0)], 0.014, "M_CableBlack", coll=S, res=10))
# conduits down to junction boxes
for (x, z, face) in [(5.98, 12.0, 'e'), (5.98, 19.6, 'e'), (14.5, 7.98, 's')]:
    if face == 'e':
        cables.append(poly_tube("conduit", [(x - 0.03, 2.5, z), (x - 0.03, 1.62, z)], 0.016, "M_Steel", coll=S))
        cables.append(box("jbox", (0.12, 0.3, 0.24), (x - 0.06, 1.45, z), "M_PaintGrey", 0.01, 2, coll=S))
        cables.append(box("jbox_lid", (0.01, 0.27, 0.21), (x - 0.125, 1.45, z), "M_PaintGrey", 0.003, 1, coll=S))
    else:
        cables.append(poly_tube("conduit", [(x, 2.5, z - 0.03), (x, 1.62, z - 0.03)], 0.016, "M_Steel", coll=S))
        cables.append(box("jbox", (0.24, 0.3, 0.12), (x, 1.45, z - 0.06), "M_PaintGrey", 0.01, 2, coll=S))
svc = [realize(o) for o in list(S.all_objects)]
for o in svc: world_uv(o, 1.0)
join("corridor_services", svc)

# ------------------------------------------------------------------ doors
D = collection("doors")
def steel_door(name, center, facing, w=1.0, h=2.15, window=True, coll=D, frame_mat="M_DoorFrame", leaf_mat="M_DoorSteel"):
    """Door + frame on a wall face. facing = direction the door faces (into the corridor)."""
    cx, cz = center; fx, fz = facing
    out = []
    along_x = fz != 0
    def P(a, y, d):   # a = along wall, d = out from wall
        return (cx + (a if along_x else 0) + fx * d, y, cz + (0 if along_x else a) + fz * d)
    def S(sa, sy, sd):
        return (sa, sy, sd) if along_x else (sd, sy, sa)
    out.append(box(name + "_jamb_l", S(0.1, h + 0.1, 0.16), P(-w / 2 - 0.05, (h + 0.1) / 2, 0.06), frame_mat, 0.012, 2, coll=coll))
    out.append(box(name + "_jamb_r", S(0.1, h + 0.1, 0.16), P(w / 2 + 0.05, (h + 0.1) / 2, 0.06), frame_mat, 0.012, 2, coll=coll))
    out.append(box(name + "_head", S(w + 0.2, 0.1, 0.16), P(0, h + 0.05, 0.06), frame_mat, 0.012, 2, coll=coll))
    out.append(box(name + "_leaf", S(w, h, 0.05), P(0, h / 2, 0.03), leaf_mat, 0.008, 2, coll=coll))
    # kick plate and push plate, hinges, handle
    out.append(box(name + "_kick", S(w - 0.08, 0.25, 0.006), P(0, 0.16, 0.058), "M_Steel", 0.002, 1, coll=coll))
    for y in (0.35, 1.1, 1.85):
        out.append(cyl(name + "_hinge", 0.018, 0.12, P(-w / 2 + 0.01, y, 0.06), "M_Steel", axis='y', seg=12, coll=coll))
    out.append(box(name + "_handle_base", S(0.05, 0.2, 0.02), P(w / 2 - 0.1, 1.0, 0.065), "M_Steel", 0.004, 1, coll=coll))
    out.append(box(name + "_handle", S(0.14, 0.022, 0.022), P(w / 2 - 0.15, 1.04, 0.1), "M_Steel", 0.008, 2, coll=coll))
    if window:
        out.append(box(name + "_win_frame", S(0.32, 0.48, 0.02), P(0, 1.55, 0.065), "M_Steel", 0.006, 1, coll=coll))
        out.append(box(name + "_win", S(0.26, 0.42, 0.012), P(0, 1.55, 0.07), "M_WiredGlass", coll=coll))
    return out
steel_door("door_start", (5.0, 21.97), (0, -1), w=1.1)
steel_door("door_storage", (4.0, 12.0), (1, 0), w=0.95, window=False)
steel_door("door_battery", (14.0, 8.0), (0, -1), w=0.95, window=True)
dr = [realize(o) for o in list(D.all_objects)]
for o in dr: world_uv(o, 1.0)
join("corridor_doors", dr)

# ------------------------------------------------------------------ the communications room
R = collection("room")
room = []
# structural floor slab (void below the raised floor) and walls
room.append(box("room_slab", (14.0, 0.2, 10.0), (27.0, -0.5, 7.0), "M_VoidFloor", coll=R))
room.append(box("room_ceiling_slab", (14.0, 0.3, 10.0), (27.0, RH + 0.15, 7.0), "M_CorrCeil", coll=R))
kw = dict(lower="M_RoomLower", stripe="M_RoomStripe", upper="M_RoomUpper", y0=-0.4, lh=1.0)
room += band_wall("rw_north", 20, 2, 34, 2, (0, 1), RH, R, **kw)
room += band_wall("rw_south", 20, 12, 34, 12, (0, -1), RH, R, **kw)
room += band_wall("rw_east", 34, 2, 34, 12, (-1, 0), RH, R, **kw)
room += opening_wall("rw_west", 20.0, 2, 12, 6.3, 7.7, 2.3, (1, 0), RH, R, **kw)
# heavy door frame with hazard striping in the opening, door leaf swung open against the wall
for nm, sz, ps in [("dframe_l", (0.42, 2.42, 0.14), (19.85, 1.21, 6.23)), ("dframe_r", (0.42, 2.42, 0.14), (19.85, 1.21, 7.77)),
                   ("dframe_t", (0.42, 0.14, 1.68), (19.85, 2.37, 7.0))]:
    room.append(box(nm, sz, ps, "M_HazardFrame", 0.015, 2, coll=R))
leaf = box("dleaf", (1.38, 2.26, 0.09), (20.75, 1.13, 5.62), "M_DoorSteel", 0.01, 2, rot=(0, -8, 0), coll=R)
room.append(leaf)
for y in (0.4, 1.13, 1.86):
    room.append(box("dleaf_bar", (1.2, 0.05, 0.03), (20.75, y, 5.68), "M_Steel", 0.006, 1, rot=(0, -8, 0), coll=R))
room.append(box("dleaf_wheel_hub", (0.12, 0.12, 0.06), (20.75, 1.2, 5.70), "M_Steel", 0.02, 2, rot=(0, -8, 0), coll=R))
# raised access floor: 0.6 m tiles, a few lifted out
tiles = []; holes = {(4, 2), (5, 2), (19, 11), (19, 12)}
nx, nz = int(14 / 0.6) + 1, int(10 / 0.6) + 1
for ix in range(nx):
    for iz in range(nz):
        x0 = 20.0 + ix * 0.6; z0 = 2.0 + iz * 0.6
        x1 = min(x0 + 0.6, 34.0); z1 = min(z0 + 0.6, 12.0)
        if x1 - x0 < 0.05 or z1 - z0 < 0.05: continue
        if (ix, iz) in holes:
            tiles.append(box("ped", (0.05, 0.37, 0.05), (x0 + 0.3, -0.215, z0 + 0.3), "M_Pedestal", coll=R))
            continue
        dy = random.uniform(-0.002, 0.002)
        tiles.append(box("tile", (x1 - x0 - 0.004, 0.035, z1 - z0 - 0.004), ((x0 + x1) / 2, -0.0175 + dy, (z0 + z1) / 2), "M_RaisedTile", 0.003, 1, coll=R))
# cables lying in the void under the lifted tiles
for k in range(4):
    tiles.append(tube_path("void_cable", [(22.0, -0.37, 3.0 + k * 0.06), (23.0, -0.36, 3.5 + k * 0.05), (24.5, -0.37, 3.2 + k * 0.07)], 0.018, "M_CableGrey" if k % 2 else "M_CableBlack", coll=R))
# suspended ceiling: T-bar grid, tiles, troffers, gaps showing the plenum
lights_on = [(23.0, 5.0), (31.0, 9.0), (27.0, 9.0)]
lights_off = [(27.0, 5.0), (31.0, 5.0), (23.0, 9.0)]
troffers = lights_on + lights_off
def in_troffer(x, z):
    for (tx, tz) in troffers:
        if abs(x - tx) < 0.61 and abs(z - tz) < 0.31: return True
    return False
missing = {(18, 1), (19, 1), (18, 2), (6, 12)}
ceil = []
for ix in range(nx):
    for iz in range(nz):
        x0 = 20.0 + ix * 0.6; z0 = 2.0 + iz * 0.6
        x1 = min(x0 + 0.6, 34.0); z1 = min(z0 + 0.6, 12.0)
        if x1 - x0 < 0.05 or z1 - z0 < 0.05: continue
        cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
        if in_troffer(cx, cz) or (ix, iz) in missing: continue
        ceil.append(box("ctile", (x1 - x0 - 0.024, 0.016, z1 - z0 - 0.024), (cx, CH + 0.012, cz), "M_CeilTile", 0.003, 1, coll=R))
# one tile hanging down from a corner
ceil.append(box("ctile_hang", (0.576, 0.016, 0.576), (31.3, CH - 0.22, 2.95), "M_CeilTile", 0.003, 1, rot=(48, 12, 0), coll=R))
for ix in range(nx + 1):
    x = min(20.0 + ix * 0.6, 33.99)
    ceil.append(box("tbar_x", (0.024, 0.03, 10.0), (x, CH + 0.005, 7.0), "M_TBar", coll=R))
for iz in range(nz + 1):
    z = min(2.0 + iz * 0.6, 11.99)
    ceil.append(box("tbar_z", (14.0, 0.03, 0.024), (27.0, CH + 0.005, z), "M_TBar", coll=R))
for (tx, tz) in troffers:
    on = (tx, tz) in lights_on
    ceil.append(box("troffer_house", (1.2, 0.12, 0.6), (tx, CH + 0.07, tz), "M_TrofferHousing", 0.008, 1, coll=R))
    ceil.append(box("troffer_diff", (1.14, 0.01, 0.54), (tx, CH + 0.004, tz), "M_TrofferOn" if on else "M_TrofferOff", coll=R))
    for k in range(-2, 3):
        ceil.append(box("troffer_louver", (0.012, 0.03, 0.52), (tx + k * 0.22, CH - 0.01, tz), "M_TBar", coll=R))
# plenum: cable tray and hanger wires visible through the gaps
ceil.append(box("plenum_tray", (12.0, 0.06, 0.3), (27.0, 3.45, 3.4), "M_TrayGalv", 0.004, 1, coll=R))
for x in range(21, 34, 2):
    ceil.append(box("hanger_wire", (0.004, 0.75, 0.004), (x + 0.3, 3.4, 4.4), "M_Steel", coll=R))
rm = [realize(o) for o in list(R.all_objects)]
for o in rm: world_uv(o, 1.0)
tiles_o = [o for o in rm if o.name.startswith(("tile", "ped", "void_cable"))]
ceil_o = [o for o in rm if o.name.startswith(("ctile", "tbar", "troffer", "plenum", "hanger_wire"))]
rest = [o for o in rm if o not in tiles_o and o not in ceil_o]
join("room_floor", tiles_o); join("room_ceiling", ceil_o); join("room_arch", rest)

export(os.path.join(OUT, "slice_shell.gltf"))
