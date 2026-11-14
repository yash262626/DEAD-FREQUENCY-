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
- Run from source: Godot **3.5.x** (standard, not Mono). Windows, Linux or macOS. After a fresh clone run `tools/import_assets.sh` once (or open the project in the editor) so the textures are imported.
- Play the exported build: Windows 10/11 64-bit, a GPU and driver with OpenGL 3.3 (GLES3 renderer; no GLES2 fallback is enabled because the custom shaders target GLES3), 4 GB RAM, ~200 MB disk.

## Repository layout
```
DEAD-FREQUENCY-/
├─ game/                      the Godot project (open game/project.godot)
│  ├─ project.godot           engine config, autoloads (G, Snd, Story, Mats), display settings
│  ├─ export_presets.cfg      Windows Desktop + Linux/X11 export presets
│  ├─ icon.png                application icon
│  ├─ scenes/Main.tscn        the only scene; everything else is built in code
│  ├─ scripts/                game code (see 10_GAMEPLAY_SYSTEMS_ARCHITECTURE.md); mats.gd = PBR materials, fx.gd = light shafts/particles/water
│  ├─ data/                   story: story.gd (registry, credits, achievements), ch00–ch13.gd, endings.gd
│  ├─ textures/               20 CC0 PBR sets from ambientCG (albedo, normal, packed AO/rough/metal) + committed .import settings
│  ├─ fonts/                  Liberation fonts 2.1.5 (SIL OFL 1.1)
│  └─ tests/                  automated test harness (Test.tscn, test.gd)
├─ tools/
│  ├─ test.sh                 runs a test suite or utility headless under Xvfb
│  ├─ import_assets.sh        imports textures into game/.import after a fresh clone (CI uses it)
│  ├─ package_release.sh      builds the clean Windows release folder + zip (README, credits, notices, licences, checksums)
│  ├─ playtest_report.py      turns playtesters' playtest.json logs into measured chapter times
│  ├─ time_budget.py          campaign-length model → docs/17_TIME_BUDGET.md
│  ├─ gen_docs.py             regenerates docs 04–08 from the story data
│  ├─ vo_package.py           voice-over recording package → docs/vo/
│  ├─ import_cc0.py           fetches + packs ambientCG materials (needs network access to ambientcg.com)
│  └─ fix_oneliners.py        guards against a GDScript 3 one-line `if` pitfall
├─ release/                   player README.txt template and icon.ico for the release package
├─ licenses/                  Godot (+ its third-party components) and Liberation font licence texts, shipped with builds
├─ docs/                      production documents 01–20, notices, privacy, screenshots, VO package
└─ .github/workflows/build.yml  tests → Windows/Linux export → Wine smoke test + release zip (manual or v* tags)
```

## Running
- **Editor**: open `game/project.godot` in Godot 3.5 → F5.
- **Command line**: `godot3 --path game` (add `--menu` to skip the opening cinematic).
- **Self-check**: `DeadFrequency.exe --smoketest` (or `godot3 --path game -- --smoketest`) boots to the menu, starts a new game, runs chapters 1, 5 and 12, saves and loads, plays ending A into the credits, takes five screenshots and writes `smoketest.log` to the user data folder; exit code 0 means every check passed. It uses its own play-time log and leaves the player's files alone apart from the save slot.
- First launch synthesises and caches all audio in the user data folder (`%APPDATA%\Godot\app_userdata\DEAD FREQUENCY\` on Windows) — a second or two.

## User data files
| File | Contents | Safety |
|---|---|---|
| `save.json` / `save.json.bak` | current run: chapter, checkpoint, flags, inventory, journal, play-time run id | written to `.tmp`, verified, previous save kept as `.bak`; a damaged save falls back to `.bak` with a message |
| `profile.json` | settings, unlocked chapters, endings, achievements, New Game+ memory | rewritten on change |
| `playtest.json` | per run and chapter: seconds of unpaused play, deaths, completion, ending | local only; flushed every 30 s, on death, chapter end, menu and quit |
| `snd_v5/` | cached procedurally generated sounds | regenerated if missing |

## Rendering, materials and effects
- `mats.gd` (autoload `Mats`): cached `SpatialMaterial`s from the CC0 sets — albedo, normal map and a packed ORM texture (R = AO, G = roughness, B = metalness; metalness falls back to 0 when a set has none). World geometry uses world-space triplanar mapping so walls, floors and ceilings tile without UV seams; props pick a material by colour/roughness/metal. Quality preset Low uses flat colours (no textures) for weak GPUs.
- Textures are imported as VRAM-compressed (S3TC) with mipmaps and repeat; the `.import` settings are committed, the cache (`game/.import/`) is not.
- `fx.gd`: light fixtures with emissive tubes, additive volumetric light cones (custom open-cone mesh; the shader clamps before `pow` to avoid NaN artefacts), dust motes, sparks, steam, drips, and a water shader (fresnel, scrolling normals). Particles never cast shadows.
- UI shaders (`ui.gd`): glitch title, fog cards, CRT terminal for the second reveal, red static for SIGNAL LOST, damage/static/hide post-process. Every flash honours *Reduce flashing effects*.

## Audio
All sound is synthesised at first launch (`snd.gd`, cache version 5): ambience beds, footsteps per surface (concrete, metal, tile), radio static per band, the Listener's rasp and dish snaps, impacts, glitches, tones and drones. The music director in `level.gd` crossfades tension and chase layers with the Listener's state and ducks everything when it is close but not hunting. Recorded voice-over is picked up automatically: `ui.say()` plays `res://vo/<vo_id>.ogg` when it exists (`vo_id` = speaker + md5 of speaker|line, listed per line in `docs/vo/`), otherwise the processed radio-voice placeholder.

## Building the Windows executable and the release package
1. Install the Godot **3.5.2** export templates (Editor → Manage Export Templates, or extract `Godot_v3.5.2-stable_export_templates.tpz` into `~/.local/share/godot/templates/3.5.2.stable/`).
2. `tools/package_release.sh --export` — imports assets if needed, exports `build/windows/DeadFrequency.exe` (single self-contained file, ~85 MB with the textures) and builds `build/DeadFrequency-<version>-Windows-x64.zip` containing the exe, `README.txt`, `CREDITS.txt` (generated from the in-game credits), `PRIVACY.txt`, `THIRD_PARTY_NOTICES.txt`, `licenses/` and `SHA256SUMS.txt`.
3. Verified here: the exe was launched under **Wine 9.0** on a virtual display with Mesa software OpenGL and passed all 15 smoke-test checks (log and screenshots in 13_TESTING_PLAN.md §9). That is a compatibility smoke test, **not** a test on Windows — real Windows PCs remain the first release-checklist item.
4. Not done yet: embedding the icon and version information into the exe (`application/modify_resources`, needs the `rcedit` tool configured in the editor settings; the running game already shows its own window icon) and code signing (needs a certificate). Both are release tasks in 14_RELEASE_PLAN.md.
5. Or use GitHub Actions: **Actions → build → Run workflow** runs the tests, exports Windows and Linux builds, runs the Wine smoke test and uploads the release zip (the workflow is defined but has not been run in this repository yet).

## Authored art scenes (vertical slice)
A chapter can name an authored scene: `"art": "res://slice/Slice.tscn"`. The level then keeps its grid only as invisible collision and navigation, instances the art scene (meshes with lightmap UVs, baked `BakedLightmap`, reflection probes, lights, light shafts, puddles, effect markers, `WorldEnvironment`) and uses the scene's environment; entities marked `"noviz"` keep their logic and interaction volume but hide their placeholder visuals. `"hq": true` switches on the modelled first-person rig (`scripts/fp_models.gd`) and the new Listener body (`scripts/listener_model.gd`). Pipeline: `tools/fetch_polyhaven.py` (CC0 assets) → `tools/write_texture_imports.py` (import flags) → `tools/blender/*.py` (Blender 4.0 headless: architecture, dressing, first-person items, creature with bakes/rig/animations, exported as glTF) → `tools/import_assets.sh` → `slice/build_slice.gd` (assembles the scene, xatlas lightmap UVs, materials) → `DF_BAKE=res://slice/Slice.tscn godot3 --path game --editor` (bakes through the `addons/df_tools` editor plugin, which does nothing unless `DF_BAKE` is set). Design, evidence and the engine decision: docs/21.

## Testing
`tools/test.sh <suite>` runs a suite in a real engine instance (Xvfb + software GL). Suites and results: 13_TESTING_PLAN.md. Tests write to separate `test_save.json` / `test_profile.json` / `test_playtest.json` files and never touch player data. Utility modes: `introtime`, `gallery` (`DF_OUT`, `DF_ONLY`), `perf`, `export` (story data as JSON for the doc generators), `licenses` (writes `licenses/GODOT_ENGINE_LICENSE.txt` from the engine's own copyright data).

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
- Measured here (`tools/test.sh perf`, **no GPU — Mesa llvmpipe software rasteriser on 4 CPU cores**, 1280×720): level build 20–70 ms; 10–15 fps on Low, 4–5 fps on High; the Windows build under Wine with the same software rasteriser: 1.7 fps on High. These numbers only show the CPU-side cost is small; they say nothing about GPU performance, which has **not been measured** and is the first item of the release checklist (target 60 fps at 1080p High on a GTX 1060-class GPU).

## Known technical limitations
- GDScript 3 pitfalls guarded by tooling: `if x: a; b` runs `b` unconditionally (fixed project-wide by `tools/fix_oneliners.py`); `continue` inside `match` falls through rather than continuing the loop (avoided).
- Levels freed while an event script is suspended are detached first and freed 45 s later, so scripts exit cleanly.
- Losing window focus during play opens the pause menu (not during cinematics), so alt-tabbing never leaves the player exposed.
- Steamworks (achievements, cloud saves) not integrated yet: achievements are tracked locally with stable IDs ready for mapping (GodotSteam for Godot 3.5 is the intended route).
