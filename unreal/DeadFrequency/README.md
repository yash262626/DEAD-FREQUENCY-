# DEAD FREQUENCY — Unreal Engine 5 project

The commercial version of DEAD FREQUENCY, rebuilt in **Unreal Engine 5.8**. The Godot 3.5 game in `../../game/` is the
playable reference and backup; nothing here changes it. Plan and architecture: [docs/24](../../docs/24_UNREAL_ENGINE_5_MIGRATION_PLAN.md).

> **Status (2026-11-15): not compiled, not playable yet.** The C++ was written without access to an Unreal machine.
> Expect a first round of compile fixes. No feature in this folder counts as done until it builds, runs and passes
> its test on the build machine.

## What is here
| Path | Contents |
|---|---|
| `DeadFrequency.uproject` | Engine 5.8; plugins Enhanced Input, CommonUI, StateTree, Python (editor), Modeling Tools (editor) |
| `Config/` | Lumen GI and reflections, Nanite, virtual shadow maps, TSR, no baked lighting, DX12 SM6, custom-depth stencil; game mode, game instance and settings classes |
| `Content/Data/Story/` | The story, converted from the Godot game: `chapter_00`–`chapter_13`, `ending_A`–`D`, `slice`, items, achievements, credits, titles, the Listener's mimicry, `PARITY.md`. Generated — re-run `tools/ue/godot_to_ue.py`, never edit by hand |
| `Source/DeadFrequency/Story/` | `UDFStorySubsystem`: runs the Godot event scripts command for command; world commands go to the level's director (`IDFStoryCommandHandler`), presentation commands to the UI |
| `Source/DeadFrequency/Radio/` | `UDFRadioComponent` (the HX-7: tuning, bands, lock, battery, exposure, carrier noise) and `ADFTransmitter` |
| `Source/DeadFrequency/Player/` | `ADFPlayerCharacter` (Daniel, first person; input defined in code), `IDFInteractable`, `IDFHidingSpot` |
| `Source/DeadFrequency/AI/` | `ADFListenerController` (the Listener's mind) and `ADFListenerCharacter` (its body and presentation hooks) |
| `Source/DeadFrequency/Core/` | `UDFGameInstance` (run, chapter flow, endings, saves, profile, achievements), `ADFGameMode`, `UDFSaveGame`, `UDFProfileSave` |
| `Source/DeadFrequency/Settings/` | `UDFGameUserSettings` (presets on scalability 0–4, upscaler, ray tracing, controls, accessibility, audio) |

## Build machine
- Windows 10/11, an RTX 3060-class GPU or better, 32 GB RAM recommended, ~150 GB free on an SSD.
- **Unreal Engine 5.8** from the Epic Games Launcher (the Epic account holder accepts the EULA).
- **Visual Studio 2022** with the *Game development with C++* workload (MSVC v143, a Windows 10/11 SDK).
- **Git LFS** (`git lfs install`) before committing any `.uasset`/`.umap`, unless the project moves to Perforce.

## First build
1. Right-click `DeadFrequency.uproject` → *Generate Visual Studio project files*.
2. Open `DeadFrequency.sln`, choose **Development Editor | Win64**, build the `DeadFrequency` project.
3. Fix whatever the compiler reports (first compile of hand-written code), then open the project in the editor.
4. Check the Output Log for `Story: 19 scripts, 9 mimicry lines` — that confirms the story data loads.

## Level conventions (for the maps still to be built)
- Maps: `/Game/DeadFrequency/Maps/L_<story key>` — `L_chapter_00` … `L_chapter_13`, `L_ending_A` … `L_ending_D`,
  `L_slice`, `L_menu`, `L_credits`. Opening a story map directly in the editor plays it as a fresh chapter-select run.
- Player starts: tag `S` for the chapter start; checkpoints use the Godot marker symbol as their tag.
- Listener patrol points: any actor with the tag `ListenerPatrol`.
- Hiding places implement `IDFHidingSpot`; usable things implement `IDFInteractable`.
- Transmitters: an `ADFTransmitter` per radio legend entry, named by its symbol.
- Every map has one director actor implementing `IDFStoryCommandHandler` (lights, doors, the Listener, cameras,
  teleports, sounds) — to be written with the slice.

## Not here yet
Level director, UI widgets (HUD, subtitles, chapter cards, menus, credits), cinematics, the production Listener
(sculpt, skin, rig, animation), environments, first-person arms with the HX-7 and torch, audio, automation tests and
the Steam integration (no App ID exists yet).
