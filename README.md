# DEAD FREQUENCY

*A radio that hears the past. Something in the signal that hears you.*

First-person psychological horror for Windows PC. October 17, 1998, 02:43: the HELIX-9 research facility vanishes from every network. In 2026, communications engineer Daniel Arlen is sent to restore its radio — and his hand-held receiver starts picking up the past, the future, and his own voice: *whatever happens, do not open the door.*

**A game developed by YASH AIL.**

![Title](docs/screenshots/00_title.png)

## Vertical slice — the new visual target (4K)
![The Listener in the red emergency corridor — in-game, captured at 3840 × 2160](docs/screenshots/slice/s04_listener_corridor.jpg)

One area — the Sublevel 3 service corridor and communications room — is rebuilt to a new standard as a playable vertical slice that renders natively at **3840 × 2160**: authored geometry, CC0 Poly Haven props, 4K/2K PBR surfaces, wet floors and decals, baked global illumination, red emergency lighting, a redesigned Listener (original creature built to the owner's reference sheet: acoustic membrane head, emaciated asymmetric body, clawed fingers, 4K skin with subsurface scattering, 78-bone rig, seven animations, LODs), gloved hands with a knurled torch and an HX-7 whose display and tuning knob are live, and cinematic depth of field in scripted moments. Play it from the main menu (*VERTICAL SLICE — VISUAL TARGET*) or with `--slice`.

Evidence: native 4K captures in [`docs/screenshots/slice4k/`](docs/screenshots/slice4k/), a gameplay recording ([`docs/media/slice_gameplay.mp4`](docs/media/slice_gameplay.mp4)), the approval package ([21](docs/21_VISUAL_AUDIT_AND_VERTICAL_SLICE.md)), an isolated Godot 4 benchmark and engine evaluation ([22](docs/22_GODOT4_VISUAL_BENCHMARK.md)) and asset/texture specifications ([23](docs/23_ASSET_AND_TEXTURE_SPECIFICATIONS.md)). It is a big step up from the campaign but **not photorealism and not AAA**, and **no GPU frame rate has been measured** (this was built on a machine without a GPU) — run `DeadFrequency.exe --benchmark` on your PC for real numbers. The other chapters are unchanged until the owner approves the standard and the engine path.

**Graphics settings:** presets Low, Medium, High, Ultra, Cinematic; resolution up to 3840 × 2160; render scale 50–150 %; texture quality; shadows; reflections; ambient occlusion; anti-aliasing (FXAA, MSAA 2×/4×/8×); view distance; V-Sync; frame-rate limit.

## What's in this repository
- A complete, playable campaign in **Godot 3.5**: 2-minute opening cinematic, 13 chapters with optional wings, 4 endings, New Game+ ("Second Signal"), end credits.
- The radio system (four bands plus hidden carriers, directional antenna, battery, exposure), a sound-hunting enemy that learns (and remembers between runs), stealth, puzzles, saves, menus, settings, subtitles, controller support.
- CC0 PBR materials (ambientCG), procedural audio with adaptive music, a voice-over recording package ready for actors.
- 23 production documents in [`docs/`](docs/), an automated test suite that plays the whole campaign, and a built-in `--smoketest` for release builds.

What is **not** done, plainly: the campaign length is a model (3.9–10.1 h main path, 5.4–14.0 h with optional content) until playtests measure it — the 10–15 hour target is not claimed; there is no recorded voice acting (placeholder radio voice + full subtitles); the campaign still has the older procedural look and the slice is not photoreal; the Windows build has passed a smoke test under Wine but has **not** been run on real Windows hardware; Steamworks is not integrated. Details: [progress tracker](docs/15_DEVELOPMENT_PROGRESS_TRACKER.md).

## Play from source
1. Install **Godot 3.5.x** (standard build) from godotengine.org, or `sudo apt install godot3` on Ubuntu.
2. Open `game/project.godot` and press **F5**, or run `godot3 --path game` (`--menu` skips the opening).

## Build the Windows release
Install the Godot 3.5.2 export templates, then:
```
tools/package_release.sh --export     # → build/DeadFrequency-<version>-Windows-x64.zip
```
After a fresh clone, `tools/import_assets.sh` imports the textures (the script above does it automatically). Or run the **build** workflow from the GitHub Actions tab (tests, Windows/Linux export, Wine smoke test, release zip).

## Controls
| Action | Keyboard / mouse | Gamepad |
|---|---|---|
| Move / look | WASD / mouse | left / right stick |
| Sprint · crouch · lean | Shift · Ctrl or C · Q / E | L3 · B · LB / RB |
| Interact | F or left click | A |
| Flashlight | T or middle click | Y |
| Radio on/off · tune | R or right click · wheel or ← → | X · D-pad ← → |
| Throw bottle · medkit | G · H | D-pad ↓ · ↑ |
| Journal · pause | Tab · Esc | Back · Start |
| Skip cinematic | hold Space / Enter | hold A |

## Tests
```
tools/test.sh validate   # data integrity: maps, commands, markers, sounds, credits
tools/test.sh flags      # every story flag read is set somewhere
tools/test.sh layout     # no prop blocks a passage
tools/test.sh save       # save/load, damaged-save fallback, ending logic, checkpoints, play-time log
tools/test.sh systems    # movement, flashlight, radio, doors, health, menus
tools/test.sh ai         # the Listener's senses, states and learning
tools/test.sh flow       # intro → menu → new game → focus-loss pause → continue → chapter select → death → reload
tools/test.sh endings    # all four endings + credits
tools/test.sh ngplus     # New Game+ memory, 88.0 content, Listener adaptations
tools/test.sh play       # the full campaign, chapter 1 → ending D
tools/test.sh slice      # the vertical slice: art scene, baked light, HQ models, forecast, encounter, hiding, return to menu
tools/test.sh texq       # texture quality Half: every large texture at half resolution, memory drops
```
Requires `godot3` and `xvfb-run` (`sudo apt install godot3 xvfb`). Latest results: [13_TESTING_PLAN.md](docs/13_TESTING_PLAN.md).

## Documents
| # | Document |
|---|---|
| 01 | [Game Design Document](docs/01_GAME_DESIGN_DOCUMENT.md) |
| 02 | [Story Bible](docs/02_STORY_BIBLE.md) |
| 03 | [Character Bible](docs/03_CHARACTER_BIBLE.md) |
| 04 | [Chapter-by-Chapter Campaign](docs/04_CAMPAIGN.md) |
| 05 | [Mission Design & QA Walkthrough](docs/05_MISSION_DESIGN.md) |
| 06 | [Dialogue & Audio Script](docs/06_DIALOGUE_AND_AUDIO_SCRIPT.md) |
| 07 | [Cinematic Script](docs/07_CINEMATIC_SCRIPT.md) |
| 08 | [Level Design](docs/08_LEVEL_DESIGN.md) |
| 09 | [Enemy AI](docs/09_ENEMY_AI.md) |
| 10 | [Gameplay Systems Architecture](docs/10_GAMEPLAY_SYSTEMS_ARCHITECTURE.md) |
| 11 | [Asset Production List](docs/11_ASSET_PRODUCTION_LIST.md) |
| 12 | [Technical Documentation](docs/12_TECHNICAL_DOCUMENTATION.md) |
| 13 | [Testing Plan & Results](docs/13_TESTING_PLAN.md) |
| 14 | [Release Plan (Steam)](docs/14_RELEASE_PLAN.md) |
| 15 | [Development Progress Tracker](docs/15_DEVELOPMENT_PROGRESS_TRACKER.md) |
| 16 | [Bug Reports](docs/16_BUG_REPORTS.md) |
| 17 | [Campaign Time Budget (model)](docs/17_TIME_BUDGET.md) |
| 18 | [Audio Production Plan & VO](docs/18_AUDIO_PRODUCTION_PLAN.md) — recording script in [`docs/vo/`](docs/vo/) |
| 19 | [Engine Migration Assessment](docs/19_ENGINE_MIGRATION_ASSESSMENT.md) |
| 20 | [Steam Release Package](docs/20_STEAM_RELEASE_PACKAGE.md) |
| 21 | [Visual Audit, 4K Vertical Slice & Approval Package](docs/21_VISUAL_AUDIT_AND_VERTICAL_SLICE.md) |
| 22 | [Godot 4 Visual Benchmark & Engine Evaluation](docs/22_GODOT4_VISUAL_BENCHMARK.md) |
| 23 | [Asset & Texture Specifications](docs/23_ASSET_AND_TEXTURE_SPECIFICATIONS.md) |
|  | [Third-Party Notices](docs/THIRD_PARTY_NOTICES.md) · [Privacy](docs/PRIVACY.md) |
|  | [Changelog](CHANGELOG.md) |

Docs 04–08 are generated from the game data (`python3 tools/gen_docs.py <export.json> docs`), so they always match what ships.

## Credits
Developed by **YASH AIL** · Sound Effects by **AJAY GOHIL** · Game Design & Creative Support **ADARSH GUPTA** · Gameplay Testing & Quality Assurance **TANISH SHETTY** · Environment Design & Production Support **SHUBHAM GAONKAR**

Built with Godot Engine (MIT). Fonts: Liberation (SIL Open Font License). Textures and props: ambientCG and Poly Haven (CC0). Full notices and licence texts: [`docs/THIRD_PARTY_NOTICES.md`](docs/THIRD_PARTY_NOTICES.md), [`licenses/`](licenses/).
