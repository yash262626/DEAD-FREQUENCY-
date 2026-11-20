"""Vertical slice — dressing: equipment racks, operator consoles, CRT monitors, the main receiver, chairs,
chart, clock, signage, papers and floor cables. Godot coordinates (see slice_shell.py)."""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dflib import *

OUT = sys.argv[-1]
random.seed(21)
reset()
X = collection("dress")
objs = []
def add(o):
    objs.append(o); return o

# ------------------------------------------------------------------ equipment racks along the north wall
FZ = 2.9    # rack fronts
def knob(x, y, z, r, mat="M_KnobBlack"):
    add(cyl("knob", r, 0.018, (x, y, z + 0.009), mat, axis='z', seg=20, bevel=0.003, coll=X))
    add(cyl("knob_cap", r * 0.55, 0.006, (x, y, z + 0.021), "M_KnobAlu", axis='z', seg=16, coll=X))
def led(x, y, z, col):
    add(cyl("led", 0.0035, 0.006, (x, y, z + 0.003), "M_LED_" + col, axis='z', seg=8, coll=X))
def toggle(x, y, z):
    add(cyl("tog_base", 0.006, 0.008, (x, y, z + 0.004), "M_KnobAlu", axis='z', seg=10, coll=X))
    t = add(cyl("tog_lever", 0.0022, 0.022, (x, y + 0.004, z + 0.016), "M_KnobAlu", axis='z', seg=6, coll=X))
    t.rotation_euler = Euler((math.radians(70 + random.choice((0, 40))), 0, 0))
def unit(kind, cx, y0, h, z):
    w = 0.482
    add(box("unit_face", (w, h - 0.004, 0.012), (cx, y0 + h / 2, z + 0.006), random.choice(["M_RackFront", "M_RackFront", "M_BeigePlastic"]) if kind != "blank" else "M_RackPaint", 0.002, 1, coll=X))
    for sx in (-1, 1):
        for sy in ((-1, 1) if h > 0.06 else (0,)):
            add(cyl("screw", 0.004, 0.004, (cx + sx * 0.225, y0 + h / 2 + sy * (h / 2 - 0.012), z + 0.014), "M_KnobAlu", axis='z', seg=8, coll=X))
    if kind == "receiver":
        add(quad("meter", 0.11, 0.065, (cx - 0.13, y0 + h * 0.6, z + 0.0125), (0, 0, 1), "M_Meter", coll=X))
        add(box("meter_bezel", (0.122, 0.077, 0.006), (cx - 0.13, y0 + h * 0.6, z + 0.009), "M_BlackPlastic", 0.002, 1, coll=X))
        knob(cx + 0.05, y0 + h * 0.55, z + 0.012, 0.024); knob(cx + 0.14, y0 + h * 0.55, z + 0.012, 0.024)
        for k in range(4): knob(cx - 0.18 + k * 0.05, y0 + h * 0.2, z + 0.012, 0.011)
        for k in range(3): led(cx + 0.03 + k * 0.025, y0 + h * 0.2, z + 0.012, random.choice(["Green", "Amber", "Off", "Red"]))
        add(quad("label", 0.2, 0.02, (cx + 0.08, y0 + h * 0.85, z + 0.0125), (0, 0, 1), "M_Label", coll=X))
        for sx in (-1, 1):
            add(tube_path("handle", [(cx + sx * 0.215, y0 + h * 0.2, z + 0.012), (cx + sx * 0.215, y0 + h * 0.2, z + 0.04), (cx + sx * 0.215, y0 + h * 0.8, z + 0.04), (cx + sx * 0.215, y0 + h * 0.8, z + 0.012)], 0.005, "M_KnobAlu", coll=X))
    elif kind == "patch":
        jacks = []
        for row in range(2):
            for k in range(16):
                jx = cx - 0.2 + k * 0.0267; jy = y0 + h * (0.3 + row * 0.4)
                add(cyl("jack", 0.0045, 0.004, (jx, jy, z + 0.0125), "M_JackHole", axis='z', seg=8, coll=X)); jacks.append((jx, jy))
        for k in range(random.randint(2, 5)):
            a, b = random.sample(jacks, 2)
            sag = random.uniform(0.04, 0.12)
            add(tube_path("patchcord", [(a[0], a[1], z + 0.015), (a[0], a[1] - 0.02, z + 0.05), ((a[0] + b[0]) / 2, min(a[1], b[1]) - sag, z + 0.07), (b[0], b[1] - 0.02, z + 0.05), (b[0], b[1], z + 0.015)], 0.0028, random.choice(["M_CableRed", "M_CableBlue", "M_CableYellow", "M_CableBlack"]), coll=X, res=6))
    elif kind == "switch":
        for k in range(10):
            toggle(cx - 0.19 + k * 0.042, y0 + h * 0.35, z + 0.012)
            led(cx - 0.19 + k * 0.042, y0 + h * 0.75, z + 0.012, random.choice(["Green", "Green", "Off", "Red", "Amber"]))
    elif kind == "meters":
        for k in range(3):
            add(quad("meter", 0.1, 0.06, (cx - 0.15 + k * 0.15, y0 + h * 0.58, z + 0.0125), (0, 0, 1), "M_Meter", coll=X))
            add(box("meter_bezel", (0.112, 0.072, 0.006), (cx - 0.15 + k * 0.15, y0 + h * 0.58, z + 0.009), "M_BlackPlastic", 0.002, 1, coll=X))
            knob(cx - 0.15 + k * 0.15, y0 + h * 0.18, z + 0.012, 0.012)
    elif kind == "psu":
        add(box("rocker", (0.03, 0.02, 0.012), (cx - 0.18, y0 + h / 2, z + 0.018), "M_LED_Red", 0.002, 1, coll=X))
        for k in range(8): add(box("slot", (0.12, 0.004, 0.004), (cx + 0.1, y0 + 0.03 + k * (h - 0.06) / 7, z + 0.0125), "M_JackHole", coll=X))
        add(quad("meter", 0.09, 0.055, (cx - 0.06, y0 + h / 2, z + 0.0125), (0, 0, 1), "M_Meter", coll=X))
    elif kind == "reel":
        for sx in (-1, 1):
            rx, ry = cx + sx * 0.115, y0 + h * 0.62
            add(disc("reel_flange", 0.105, 0.003, (rx, ry, z + 0.03), (0, 0, 1), "M_ReelMetal", seg=40, coll=X))
            add(disc("reel_tape", 0.085 if sx < 0 else 0.055, 0.012, (rx, ry, z + 0.022), (0, 0, 1), "M_TapePack", seg=40, coll=X))
            add(disc("reel_hub", 0.02, 0.02, (rx, ry, z + 0.04), (0, 0, 1), "M_KnobAlu", seg=16, coll=X))
            for k in range(3):
                a = k * 2 * math.pi / 3 + sx
                add(cyl("reel_hole", 0.022, 0.004, (rx + math.cos(a) * 0.06, ry + math.sin(a) * 0.06, z + 0.032), "M_JackHole", axis='z', seg=12, coll=X))
        add(box("head_block", (0.1, 0.05, 0.03), (cx, y0 + h * 0.3, z + 0.02), "M_KnobAlu", 0.004, 1, coll=X))
        add(tube_path("tape", [(cx - 0.2, y0 + h * 0.62 - 0.08, z + 0.024), (cx - 0.05, y0 + h * 0.3, z + 0.024), (cx + 0.05, y0 + h * 0.3, z + 0.024), (cx + 0.17, y0 + h * 0.62 - 0.05, z + 0.024)], 0.0025, "M_TapePack", coll=X))
        for k in range(5): add(box("btn", (0.03, 0.018, 0.012), (cx - 0.1 + k * 0.05, y0 + h * 0.1, z + 0.016), "M_BlackPlastic", 0.002, 1, coll=X))
    elif kind == "vent":
        for k in range(4): add(box("slot", (0.4, 0.005, 0.004), (cx, y0 + 0.015 + k * 0.016, z + 0.0125), "M_JackHole", coll=X))

layouts = [["psu", "receiver", "receiver", "patch", "patch", "meters", "blank", "vent", "switch"],
           ["blank", "reel", "switch", "receiver", "vent"],
           ["psu", "receiver", "meters", "receiver", "patch", "switch", "blank"],
           ["blank", "switch", "receiver", "receiver", "receiver", "vent", "patch"],
           ["psu", "reel", "meters", "blank"],
           ["receiver", "patch", "patch", "switch", "receiver", "meters", "vent"]]
heights = {"psu": 0.133, "receiver": 0.178, "patch": 0.089, "meters": 0.133, "blank": 0.089, "vent": 0.089, "switch": 0.089, "reel": 0.62}
for i, lay in enumerate(layouts):
    cx = 21.6 + i * 0.62
    add(box("rack_body", (0.6, 2.0, 0.86), (cx, 1.0, 2.45), "M_RackPaint", 0.01, 2, coll=X))
    add(box("rack_plinth", (0.58, 0.1, 0.84), (cx, 0.05, 2.46), "M_BlackPlastic", 0.004, 1, coll=X))
    add(box("rack_top", (0.6, 0.02, 0.86), (cx, 2.0, 2.45), "M_RackFront", 0.004, 1, coll=X))
    for sx in (-1, 1): add(box("rack_rail", (0.03, 1.82, 0.02), (cx + sx * 0.255, 1.03, FZ - 0.02), "M_KnobAlu", 0.003, 1, coll=X))
    y = 0.16
    for kind in lay:
        h = heights[kind]
        if y + h > 1.9: break
        unit(kind, cx, y, h, FZ - 0.03); y += h + 0.004
# floor cables from the racks across the room to the console
for k in range(5):
    x0 = 21.6 + k * 0.7
    pts = [(x0, 0.0, 2.92), (x0 + 0.3, 0.012, 3.6 + k * 0.1), (x0 + 2.5 + k * 0.6, 0.012, 4.4 + k * 0.25), (29.5 + k * 0.4, 0.012, 5.2 + k * 0.4), (33.1, 0.012, 6.0 + k * 0.6)]
    add(tube_path("floor_cable", pts, 0.011 + 0.003 * (k % 2), "M_CableBlack" if k % 3 else "M_CableGrey", coll=X, res=12))

# ------------------------------------------------------------------ operator console along the east wall
def crt(name, cx, cz, face=(-1, 0, 0), screen="M_CRT_Log"):
    y = 0.765
    add(box(name + "_case", (0.42, 0.36, 0.4), (cx, y + 0.18, cz), "M_BeigePlastic", 0.02, 3, coll=X))
    add(box(name + "_back", (0.26, 0.26, 0.3), (cx + 0.3, y + 0.17, cz), "M_BeigePlastic", 0.03, 3, coll=X))
    add(box(name + "_bezel", (0.02, 0.3, 0.36), (cx - 0.21, y + 0.19, cz), "M_BeigeDark", 0.01, 2, coll=X))
    add(quad(name + "_screen", 0.3, 0.225, (cx - 0.222, y + 0.195, cz), face, screen, coll=X))
    add(quad(name + "_glass", 0.31, 0.235, (cx - 0.226, y + 0.195, cz), face, "M_CRTGlass", coll=X))
    add(box(name + "_stand", (0.22, 0.03, 0.22), (cx, y + 0.005, cz), "M_BeigeDark", 0.01, 2, coll=X))
    for k in range(3): add(box(name + "_btn", (0.012, 0.012, 0.018), (cx - 0.215, y + 0.03, cz + 0.08 + k * 0.03), "M_BeigeDark", 0.002, 1, coll=X))
    led(cx - 0.214, y + 0.03, cz - 0.12, "Green") if False else add(cyl("pled", 0.0035, 0.006, (cx - 0.214, y + 0.03, cz - 0.12), "M_LED_Green", axis='x', seg=8, coll=X))
def keyboard(cx, cz):
    k = add(box("kb", (0.17, 0.03, 0.46), (cx, 0.775, cz), "M_BeigePlastic", 0.006, 2, rot=(0, 0, -5), coll=X))
    add(quad("kb_keys", 0.42, 0.14, (cx + 0.005, 0.7925, cz), (0, 1, 0), "M_Keys", coll=X, up=(-1, 0, 0)))
# console body
add(box("con_top", (0.86, 0.04, 8.0), (33.57, 0.745, 7.0), "M_DeskTop", 0.008, 2, coll=X))
add(box("con_body", (0.8, 0.7, 8.0), (33.6, 0.36, 7.0), "M_RackPaint", 0.01, 2, coll=X))
add(box("con_kick", (0.04, 0.09, 8.0), (33.19, 0.045, 7.0), "M_BlackPlastic", coll=X))
for k in range(8): add(box("con_door_line", (0.005, 0.6, 0.004), (33.195, 0.4, 3.1 + k * 1.0), "M_JackHole", coll=X))
# sloped instrument panel at the back of the console, between the monitors
for (z0, z1) in [(3.1, 4.25), (5.0, 6.45), (7.35, 8.75), (9.6, 10.9)]:
    p0 = (33.55, 0.77, z0); p1 = (33.97, 1.3, z0); p3 = (33.55, 0.77, z1)
    add(prism("con_slope", p0, p1, p3, 0.04, (-0.78, 0.62, 0), "M_RackFront", coll=X))
    nrm = Vector((-0.78, 0.62, 0)).normalized()
    for u in range(int((z1 - z0) / 0.12)):
        for v in range(3):
            zz = z0 + 0.08 + u * 0.12; t = 0.18 + v * 0.27
            px = 33.55 + (33.97 - 33.55) * t - 0.004; py = 0.77 + (1.3 - 0.77) * t + 0.004
            r = random.random()
            if v == 2 and u % 3 == 1:
                q = add(quad("cmeter", 0.09, 0.055, (px - 0.01, py + 0.008, zz), tuple(nrm), "M_Meter", coll=X))
            elif r < 0.45:
                o = add(cyl("cknob", 0.016, 0.02, (px - 0.012, py + 0.01, zz), "M_KnobBlack", seg=16, coll=X)); orient(o, tuple(nrm))
            elif r < 0.8:
                o = add(cyl("cled", 0.004, 0.008, (px - 0.004, py + 0.004, zz), random.choice(["M_LED_Green", "M_LED_Red", "M_LED_Amber", "M_LED_Off"]), seg=8, coll=X)); orient(o, tuple(nrm))
            else:
                o = add(box("cbtn", (0.022, 0.022, 0.03), (px - 0.006, py + 0.006, zz), random.choice(["M_BtnRed", "M_BtnGrey", "M_BtnGrey"]), 0.003, 1, coll=X)); orient(o, tuple(nrm))
crt("crt1", 33.55, 4.6, screen="M_CRT_Log"); keyboard(33.25, 4.6)
crt("crt2", 33.55, 6.9, screen="M_CRT_Wave"); keyboard(33.25, 6.9)
crt("crt3", 33.55, 9.2, screen="M_CRT_Log")

# ------------------------------------------------------------------ the main receiver island (player interaction)
add(box("isl_top", (0.95, 0.04, 2.5), (27.05, 0.76, 7.0), "M_DeskTop", 0.008, 2, coll=X))
add(box("isl_body_e", (0.45, 0.72, 2.4), (27.28, 0.37, 7.0), "M_RackPaint", 0.01, 2, coll=X))
add(box("isl_modesty", (0.03, 0.55, 2.4), (26.75, 0.45, 7.0), "M_RackPaint", 0.006, 1, coll=X))
for sz in (-1, 1): add(box("isl_leg", (0.9, 0.72, 0.04), (27.05, 0.37, 7.0 + sz * 1.2), "M_RackPaint", 0.006, 1, coll=X))
# receiver bank: sloped front facing the operator (west)
rb0 = (27.1, 0.78, 6.05); rb1 = (27.45, 1.3, 6.05); rb3 = (27.1, 0.78, 7.95)
add(prism("rx_face", rb0, rb1, rb3, 0.05, (-0.83, 0.56, 0), "M_RackFront", coll=X))
add(box("rx_back", (0.37, 0.52, 1.9), (27.49, 1.04, 7.0), "M_RackPaint", 0.01, 2, coll=X))
nrm = Vector((-0.83, 0.56, 0)).normalized()
def on_rx(t, z, off=0.004):
    return (27.1 + 0.35 * t - nrm.x * off * -1 - 0.004, 0.78 + 0.52 * t + 0.004, z)
p = on_rx(0.62, 7.0); add(quad("rx_dial", 1.05, 0.2, (p[0] - 0.003, p[1] + 0.002, 7.0), tuple(nrm), "M_DialGlass", coll=X))
add(box("rx_dial_frame", (0.02, 0.23, 1.1), (p[0] + 0.01, p[1] - 0.005, 7.0), "M_KnobAlu", 0.004, 1, rot=(0, 0, -34), coll=X))
o = add(cyl("rx_tuner", 0.055, 0.04, (p[0] - 0.09, p[1] - 0.16, 7.0), "M_KnobBlack", seg=32, bevel=0.006, coll=X)); orient(o, tuple(nrm))
o = add(cyl("rx_tuner_skirt", 0.07, 0.008, (p[0] - 0.07, p[1] - 0.15, 7.0), "M_KnobAlu", seg=32, coll=X)); orient(o, tuple(nrm))
for k, zz in enumerate((6.35, 6.6, 7.4, 7.65)):
    o = add(cyl("rx_knob", 0.022, 0.025, (p[0] - 0.08, p[1] - 0.14, zz), "M_KnobBlack", seg=20, bevel=0.003, coll=X)); orient(o, tuple(nrm))
for k, zz in enumerate((6.25, 7.75)):
    q = add(quad("rx_meter", 0.13, 0.08, (p[0] + 0.05, p[1] + 0.2, zz), tuple(nrm), "M_Meter", coll=X))
for k in range(8):
    o = add(box("rx_btn", (0.024, 0.024, 0.04), (p[0] + 0.07, p[1] + 0.21, 6.6 + k * 0.1), random.choice(["M_BtnGrey", "M_BtnGrey", "M_BtnRed"]), 0.004, 1, coll=X)); orient(o, tuple(nrm))
add(box("rx_grille", (0.012, 0.2, 0.3), (27.43, 1.06, 6.25), "M_Grille", 0.003, 1, coll=X))
# headphones on the desk
add(tube_path("hp_band", [(26.75, 0.8, 7.75), (26.72, 0.9, 7.85), (26.75, 0.8, 7.95)], 0.008, "M_BlackPlastic", coll=X))
for zz in (7.74, 7.96): add(disc("hp_cup", 0.045, 0.035, (26.75, 0.8, zz), (0, 0, 1), "M_BlackPlastic", seg=24, bevel=0.008, coll=X))
add(tube_path("hp_cable", [(26.75, 0.78, 7.95), (26.8, 0.785, 8.1), (27.0, 0.785, 7.9), (27.1, 0.79, 7.6)], 0.003, "M_CableBlack", coll=X))

# ------------------------------------------------------------------ office chairs (one knocked over)
def chair(cx, cz, yaw, tipped=False):
    parts = []
    parts.append(cyl("ch_col", 0.025, 0.3, (0, 0.27, 0), "M_KnobAlu", seg=12, coll=X))
    for k in range(5):
        a = k * 2 * math.pi / 5
        leg = box("ch_leg", (0.3, 0.03, 0.04), (math.cos(a) * 0.15, 0.08, math.sin(a) * 0.15), "M_BlackPlastic", 0.008, 2, rot=(0, -math.degrees(a), 0), coll=X)
        parts.append(leg)
        parts.append(cyl("ch_wheel", 0.025, 0.02, (math.cos(a) * 0.29, 0.03, math.sin(a) * 0.29), "M_BlackPlastic", axis='x', seg=12, coll=X))
    parts.append(box("ch_seat", (0.48, 0.08, 0.46), (0, 0.46, 0), "M_ChairFabric", 0.03, 3, coll=X))
    parts.append(box("ch_back", (0.44, 0.5, 0.07), (0, 0.85, 0.22), "M_ChairFabric", 0.03, 3, rot=(-8, 0, 0), coll=X))
    parts.append(box("ch_spine", (0.06, 0.4, 0.03), (0, 0.6, 0.25), "M_BlackPlastic", 0.008, 1, coll=X))
    for sx in (-1, 1): parts.append(box("ch_arm", (0.05, 0.03, 0.3), (sx * 0.27, 0.64, 0.0), "M_BlackPlastic", 0.01, 2, coll=X))
    for o in parts:
        o.select_set(False)
    ms = [realize(o) for o in parts]
    ch = join("chair", ms)
    ch.location = G(cx, 0, cz)
    ch.rotation_euler = Euler((math.radians(-82) if tipped else 0, 0, math.radians(yaw)), 'XYZ')
    if tipped: ch.location = G(cx, 0.28, cz)
    objs.append(ch)
chair(26.15, 7.35, -90)
chair(32.6, 6.2, 60, tipped=True)
chair(28.0, 10.55, 180)

# ------------------------------------------------------------------ chart, clock, signage, beacon, papers
add(box("chart_board", (3.9, 1.7, 0.03), (30.4, 1.85, 2.02), "M_FrameAlu", 0.006, 1, coll=X))
add(quad("chart", 3.8, 1.6, (30.4, 1.85, 2.037), (0, 0, 1), "M_Chart", coll=X))
add(disc("clock_body", 0.19, 0.05, (28.6, 2.35, 11.97), (0, 0, -1), "M_BlackPlastic", seg=48, bevel=0.01, coll=X))
add(quad("clock_face", 0.34, 0.34, (28.6, 2.35, 11.94), (0, 0, -1), "M_Clock", coll=X))
for (ang, ln, w) in [(81.5, 0.09, 0.012), (258.0, 0.14, 0.008)]:
    a = math.radians(ang)
    hx, hy = math.sin(a), math.cos(a)
    hb = box("clock_hand", (w, ln, 0.003), (28.6 - hx * ln / 2, 2.35 + hy * ln / 2, 11.935), "M_ClockHand", coll=X)
    hb.rotation_euler = Euler((0, math.radians(-ang), 0))
    add(hb)
def sign(name, w, h, c, n, matname):
    add(box(name + "_plate", (w + 0.02, h + 0.02, 0.01) if n[2] != 0 else (0.01, h + 0.02, w + 0.02), (c[0] - n[0] * 0.005, c[1], c[2] - n[2] * 0.005), "M_FrameAlu", 0.003, 1, coll=X))
    add(quad(name, w, h, c, n, matname, coll=X))
sign("s_comms", 0.9, 0.32, (7.2, 2.0, 6.015), (0, 0, 1), "M_SignComms")
sign("s_storage", 0.5, 0.25, (4.012, 2.45, 12.0), (1, 0, 0), "M_SignStorage")
sign("s_battery", 0.5, 0.25, (14.0, 2.45, 7.988), (0, 0, -1), "M_SignBattery")
sign("s_stair", 0.75, 0.28, (5.0, 2.5, 21.97), (0, 0, -1), "M_SignStair")
sign("s_commsdoor", 1.05, 0.39, (19.685, 2.7, 7.0), (-1, 0, 0), "M_SignCommsDoor")
sign("s_rf", 0.32, 0.32, (18.9, 1.7, 6.012), (0, 0, 1), "M_SignRF")
add(cyl("beacon_base", 0.07, 0.05, (20.06, 2.62, 7.0), "M_BlackPlastic", axis='x', seg=20, coll=X))
add(cyl("beacon_dome", 0.06, 0.09, (20.13, 2.62, 7.0), "M_BeaconRed", axis='x', seg=20, coll=X))
for k, (x, z, rot) in enumerate([(26.9, 6.3, 14), (27.0, 7.7, -30), (28.4, 11.35, 5), (24.6, 8.1, 40), (30.8, 4.2, -65), (23.2, 5.9, 120), (12.4, 7.3, 75), (5.3, 13.2, 15)]):
    y = 0.785 if k < 2 else (0.795 if k == 2 else 0.003)
    q = quad("paper", 0.21, 0.297, (x, y, z), (0, 1, 0), "M_Paper%d" % (k % 3), coll=X, up=(math.sin(math.radians(rot)), 0, -math.cos(math.radians(rot))))
    add(q)

ms = [realize(o) if o.type in ('MESH', 'CURVE') else o for o in objs]
for o in ms:
    if o.data.uv_layers and o.name.split(".")[0] in ("meter", "label", "chart", "clock_face", "paper", "kb_keys", "rx_dial", "rx_meter", "cmeter") or o.name.startswith(("s_", "crt1_screen", "crt2_screen", "crt3_screen", "crt1_glass", "crt2_glass", "crt3_glass")) and not o.name.endswith("_plate"):
        continue
    world_uv(o, 1.0)
textured = [o for o in ms if o.data.uv_layers and any(o.name.startswith(p) for p in ("meter", "label", "chart", "clock_face", "paper", "kb_keys", "rx_dial", "rx_meter", "cmeter", "s_", "crt1_s", "crt2_s", "crt3_s", "crt1_g", "crt2_g", "crt3_g")) and not o.name.endswith("_plate")]
rest = [o for o in ms if o not in textured]
racks = [o for o in rest if o.matrix_world.translation.y > 2.0 and o.matrix_world.translation.x < 25.6 and o.matrix_world.translation.x > 21.0 and -o.matrix_world.translation.y < 3.2]
join("dress_racks", racks)
join("dress_misc", [o for o in rest if o not in racks])
join("dress_textured", textured)
export(os.path.join(OUT, "slice_dress.gltf"))
