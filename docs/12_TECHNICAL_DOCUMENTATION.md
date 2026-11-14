# DEAD FREQUENCY — Technical Documentation

## Engine decision
The brief preferred Unreal Engine 5 (C++/Blueprints, Lumen, Nanite). The development environment was inspected first:

| Checked | Result |
|---|---|
| OS / hardware | Ubuntu 24.04 container, 4 CPU cores, 15 GB RAM, **no GPU** (software rendering via Mesa llvmpipe) |
| Unreal Engine, Unity, Blender | not installed; UE5 needs an Epic account, ~100 GB and a GPU — not possible here |
| Godot 4 | official binary downloaded and checksum-verified, but **running a downloaded binary was blocked** by the environment's safety policy |
| Godot 3.5.2 | available from the Ubuntu archive (`apt install godot3`) — **used** |
| Other | g++, clang, cmake, Python 3, Node, ffmpeg, Xvfb |

Godot 3.5 was the only engine that could be installed, run, rendered (GLES3 through llvmpipe under Xvfb) and tested here. It provides PBR materials, dynamic shadows, SSAO, glow, fog, positional audio, physics, gamepad input and Windows export — enough to build and verify a complete game. The cost: no Lumen/Nanite-class realism. The game's code is engine-agnostic in its data (chapters are plain dictionaries), so a later port to Godot 4 is mechanical; a UE5 port would reuse all story data and design.

**Language**: GDScript (Godot's Python-like scripting). No C++ was needed: levels build in under 70 ms and the AI is a single agent on a grid. C++ (GDNative) remains available if GPU profiling finds a CPU hotspot.

## Requirements
- Run from source: Godot **3.5.x** (standard, not Mono). Windows, Linux or macOS.
- Play the exported build: Windows 10/11 64-bit, any GPU with OpenGL ES 3.0 / OpenGL 3.3 (integrated GPUs are fine), 4 GB RAM, ~120 MB disk.

## Repository layout
```
DEAD-FREQUENCY-/
├─ game/                      the Godot project (open game/project.godot)
│  ├─ project.godot           engine config, autoloads, display settings
│  ├─ export_presets.cfg      Windows Desktop + Linux/X11 export presets
│  ├─ icon.png                application icon (generated)
│  ├─ scenes/Main.tscn        the only scene; everything else is built in code
│  ├─ scripts/                engine-level game code (see 10_GAMEPLAY_SYSTEMS_ARCHITECTURE.md)
│  ├─ data/                   story: story.gd (registry), ch00–ch13.gd, endings.gd
│  ├─ fonts/                  Liberation fonts (SIL OFL)
│  └─ tests/                  automated test harness (Test.tscn, test.gd)
├─ tools/
│  ├─ test.sh                 runs a test suite headless under Xvfb
│  ├─ gen_docs.py             regenerates docs 04–08 from the story data
│  └─ fix_oneliners.py        guards against a GDScript 3 one-line `if` pitfall
├─ docs/                      the 15 production documents + screenshots
└─ .github/workflows/build.yml  tests + Windows/Linux export on demand or on v* tags
```

## Running
- **Editor**: open `game/project.godot` in Godot 3.5 → F5.
- **Command line**: `godot3 --path game` (add `--menu` to skip the opening cinematic).
- First launch synthesises and caches all audio in the user data folder (`%APPDATA%/Godot/app_userdata/DEAD FREQUENCY/` on Windows) — a second or two.

## Building the Windows executable
1. Install the Godot **3.5.2** export templates (Editor → Manage Export Templates, or extract `Godot_v3.5.2-stable_export_templates.tpz` into `~/.local/share/godot/templates/3.5.2.stable/`).
2. `cd game && godot3 --no-window --export "Windows Desktop" ../build/windows/DeadFrequency.exe`
3. The result is a single self-contained `DeadFrequency.exe` (data embedded). This exact command was run in development and produced a 39.6 MB PE32+ x86-64 executable; the equivalent Linux export was booted headless without errors. *The Windows executable itself has not been launched on Windows yet* (no Windows machine available) — first item on the release checklist.
4. Or use GitHub Actions: **Actions → build → Run workflow** produces Windows and Linux artifacts after the tests pass.

## Testing
`tools/test.sh <suite>` runs a suite in a real engine instance (Xvfb + software GL). Suites and results: 13_TESTING_PLAN.md. Tests write to separate `test_save.json` / `test_profile.json` files and never touch player saves.

## Chapter data format (abridged)
```gdscript
const DATA = {
  "pal": "medical",            # area palette: colours, fog, light colour, ceiling height
  "sub": "SUBLEVEL 2 — MEDICAL",  # chapter-card subtitle
  "dark": true,                # starts unpowered (emergency lights only) until power<n> flag
  "cloaked": false,            # Listener visible only on 107.9 in this chapter
  "map": ["####", "#S.#", ...], # 2 m cells; built-in: # . S L F R P H V D
  "leg": {"T": {"t": "tape", "title": "...", "flag": "tape_ev1", "lines": [["EVELYN (TAPE)", "..."]]}, ...},
  "ai": [{"if": "c3_stalk", "at": "Z", "mode": "stalk"}],
  "groups": {"brk": [...events when the puzzle group is solved...]},
  "start_ev": [...], "pre_ev": [...],
  "walk": [...the QA critical path...],
}
```
Validation (`tools/test.sh validate|flags|layout`) checks every map character, command, marker, sound, flag reference and that no prop blocks a passage.

## Performance
- Levels: 1 merged mesh per surface type + props; 6–20 lights per level, shadows on High+; fog and post-processing per preset.
- Graphics presets: **Low** (no glow/SSAO/light shadows), **Medium** (glow, flashlight shadows), **High** (+ SSAO, light shadows), **Ultra** (+ screen-space reflections). MSAA 2×.
- Measured here (`tools/test.sh perf`, **no GPU — Mesa llvmpipe software rasteriser on 4 CPU cores**, 1280×720): level build 20–70 ms; 10–15 fps on Low, 4–5 fps on High. These numbers only show the CPU-side cost is small; they say nothing about GPU performance, which has **not been measured** and is the first item of the release checklist (target 60 fps at 1080p High on a GTX 1060-class GPU).

## Known technical limitations
- GDScript 3 pitfalls guarded by tooling: `if x: a; b` runs `b` unconditionally (fixed project-wide by `tools/fix_oneliners.py`); `continue` inside `match` falls through rather than continuing the loop (avoided).
- Levels freed while an event script is suspended are detached first and freed 45 s later, so scripts exit cleanly.
- Steamworks (achievements, cloud saves) not integrated yet: achievements are tracked locally with stable IDs ready for mapping (GodotSteam for Godot 3.5 is the intended route).
