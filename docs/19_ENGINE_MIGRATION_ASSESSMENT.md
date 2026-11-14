# DEAD FREQUENCY — Engine Migration Assessment (Godot 4 / Unreal Engine 5)

> **Superseded (2026-11-14) by [21_VISUAL_AUDIT_AND_VERTICAL_SLICE.md](21_VISUAL_AUDIT_AND_VERTICAL_SLICE.md).** The owner has since set a modern, near-photorealistic visual target. The vertical slice built for it shows that, once authored assets exist, Godot 3.5's renderer becomes the limit (no shadowed volumetric fog, no real-time GI for the torch, no TAA, no decals, no LOD). **New recommendation: migrate to Godot 4.x (Forward+)**, or UE5 if the owner can fund GPU hardware, artists and a full rebuild. Still no migration has been started; it needs the owner's explicit approval. The analysis below is kept for the record.

*Original recommendation:* do not migrate now. Finish content, art, audio and Windows QA on Godot 3.5; reassess a Godot 4 port after the first Windows playtest.

## Where we are
- Engine: Godot 3.5.2 (GLES3), GDScript. ~4,500 lines of engine code (`game/scripts`), ~3,000 lines of data-driven chapter content (`game/data`), 11 automated test suites.
- Rendering in use: PBR (SpatialMaterial + CC0 texture sets), dynamic omni/spot shadows, SSAO, glow, depth fog, screen-space reflections (Ultra), custom shaders (light shafts, water, creature rim, title glitch, post-processing).
- What limits visual quality today is **art assets** (procedural geometry, no sculpted characters, no authored lighting), not the renderer. A better engine without better assets would look only marginally better.

## Option A — stay on Godot 3.5 (recommended for now)
| | |
|---|---|
| Visual ceiling | Good PBR, baked GI possible (BakedLightmap/GIProbe), SSR, volumetric look via fog + shafts. No real-time GI comparable to Lumen. |
| Cost | None. |
| Risk | Godot 3.x is in maintenance (3.6 is the last minor). Fine for one shipped game. |
| Next steps | GIProbe or BakedLightmap per chapter for bounced light; authored meshes via glTF import; Steamworks via GodotSteam 3.x. |

## Option B — port to Godot 4.x (best long-term path if a port is wanted)
| Area | Compatibility | Work |
|---|---|---|
| GDScript | Syntax changes: `yield` → `await`, `onready` → `@onready`, `export` → `@export`, `tool` → `@tool`, typed signals, `Spatial` → `Node3D`, `KinematicBody` → `CharacterBody3D` (`move_and_slide` signature changes), `OS.window_*` → `DisplayServer`, `File`/`Directory` → `FileAccess`/`DirAccess`, `JSON` API, `PoolRealArray` → `PackedFloat32Array`, `Tween` node → `create_tween()` | Godot's converter handles ~60–70 %; the event runner's heavy `yield` use needs careful manual review. Estimate 1–2 weeks incl. test fixes. |
| Shaders | `hint_color` → `source_color`; `SCREEN_TEXTURE`/`DEPTH_TEXTURE` → explicit `uniform sampler2D ... : hint_screen_texture`; `CAMERA_MATRIX` → `INV_VIEW_MATRIX`; `WORLD_MATRIX` → `MODEL_MATRIX` | 6 shaders, ~1 day. |
| Materials / textures | SpatialMaterial → StandardMaterial3D (mostly automatic); re-import textures | ~1 day. |
| Audio | AudioStreamSample → AudioStreamWAV; mostly 1:1 | <1 day. |
| Data (`game/data`) | Plain dictionaries — unchanged | none |
| Tests | Harness relies on `yield`; port alongside the code | part of the 1–2 weeks |
| Gains | Vulkan renderer, SDFGI/VoxelGI real-time GI, volumetric fog, better shadows, glow, SSIL, TAA/FSR — a substantial lighting upgrade with the same assets. | |
| Risks | Behaviour regressions in the coroutine event runner and physics (CharacterBody3D); performance on low-end GPUs (Forward+ is heavier; the Compatibility renderer lacks the gains). | |
| Environment blocker | In the development container a downloaded Godot 4 binary could not be executed (policy), so the port cannot be built or tested here without that permission or a CI runner. | |

## Option C — migrate to Unreal Engine 5
| | |
|---|---|
| Gains | Lumen/Nanite, MetaHumans for characters, marketplace assets, industry tooling. Highest visual ceiling. |
| Cost | A **rewrite**, not a port: every system (player, radio, AI, event runner, UI, saves) re-implemented in C++/Blueprints; content data can be re-used via a JSON importer. Realistically 3–6 months for a small team, plus UE5's higher minimum GPU requirements. |
| Environment blocker | UE5 cannot run in this container (no GPU, ~100 GB install, Epic account). Requires a Windows/Linux workstation with a modern GPU. |
| Risk | Highest: long feature freeze, new bugs in every system, team needs UE5 skills. |

## Migration plan (if Option B is approved)
1. Freeze content on Godot 3.5; tag `v0.9-godot3` (rollback point).
2. Branch `port/godot4`; run Godot 4's project converter.
3. Port the event runner and test harness first; get `validate` + `flags` + `layout` green.
4. Port player, radio, Listener; get `systems` + `ai` green; then `flow`, `endings`, `play`, `ngplus`.
5. Port shaders and materials; enable SDFGI + volumetric fog on High/Ultra; compare screenshots chapter by chapter.
6. Windows performance check on min-spec; decide renderer per preset (Forward+ for High/Ultra, Compatibility for Low).
7. Merge only when every suite is green and a human has played chapters 1–3 on Windows.

## Rollback strategy
The Godot 3.5 build stays releasable at the tag from step 1; the port lives on its own branch until it passes the full suite. Saves are JSON with a version field, so the save format can stay identical across engines (a migration step is only needed if fields change). If the port stalls, abandon the branch — nothing on the main line depends on it.
