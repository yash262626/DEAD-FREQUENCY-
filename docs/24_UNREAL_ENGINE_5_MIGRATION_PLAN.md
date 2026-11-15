# DEAD FREQUENCY — Unreal Engine 5 Migration Plan

Owner decision, 2026-11-15: **Unreal Engine 5 becomes the primary engine.** This document is the roadmap, the
project architecture, the asset pipeline and the timeline for the migration, from the first Unreal build to a
commercial Steam release. It is a plan: dates are estimates, and nothing in it is "done" until it has run on the
target hardware and been shown with in-engine captures.

## 0. Summary

| Item | Decision |
|---|---|
| Engine | **Unreal Engine 5.8** (released June 2026; Epic calls it the last planned major UE5 release). Pinned for the whole production; Unreal Engine 6 (early access announced for 2027) is reconsidered only after launch. |
| Backup | The Godot 3.5 game in `game/` is frozen at commit `75ed3d2` and is not modified by the migration. It stays playable, testable and releasable, and it remains the gameplay reference. |
| New project | `unreal/DeadFrequency/` — a separate Unreal project (C++ core, Blueprints for content). Story data is converted from the Godot game by a tool, with a parity check (§2). |
| Where it is built | **Not in the cloud container used so far** (no GPU, no Unreal Engine install, too little disk). Unreal builds, play sessions and captures happen on a Windows PC with an RTX-class GPU: the owner's PC connected to these sessions, or a rented cloud GPU workstation (§8, decision 1). |
| Order | Environment → core framework port → greybox → **vertical slice (approval gate)** → chapters → cinematics and polish → Steam release. |
| Target hardware | RTX 3060-class PC: 60 fps at 1440p on High with upscaling; scalable down to GTX 1660-class on Low (§6). |
| Licence | Unreal Engine: free to develop; **5 % royalty on a product's lifetime gross revenue above US$1 million** (3.5 % if the game also launches on the Epic Games Store first or at the same time). Steam: one app fee per title. Every third-party asset is logged with its licence (§4.1). |
| Realistic timeline | Vertical slice: **10–14 weeks** after the build machine is ready. Full game: **12–18 months** with the staffing in §7; longer if every hero asset is made in-house. |

## 1. What must carry over (inventory, counted from the shipped data)

| Content | Count | Source in the Godot game |
|---|---|---|
| Story scripts | 13 chapters + prologue + 4 endings (18), plus New Game+ "Second Signal" | `game/data/ch00–ch13.gd`, `endings.gd` |
| Spoken / radio lines | **640** lines, 24 characters (voice-over ids already assigned) | `docs/vo/vo_script.csv` |
| Documents and notes | 48 | legend kind `note` |
| Tapes (incl. 7 Evelyn tapes) | 14 | kind `tape` |
| Radio transmissions | 24, on 8 frequencies (88.0 silent band, 89.1, 92.3, 93.3, 96.1, 99.7, 101.3, 104.4) and 4 bands (89.1 ECHO, 94.6 PROXIMITY, 101.3 FORECAST, 107.9 UNSEEN) | kind `radio`, `scripts/radio.gd` |
| Items | 18 item types, 33 placed | `story.gd` ITEMS, kind `item` |
| Interactive devices and puzzles | 44 devices; 13 keypad locks; 10 puzzle groups (ordered switches, rotation arrays, pressure plates and crates, two-person release, voiceprint) | kinds `use`, `door`, `plate`, `pcrate` |
| Doors | 42 (plain, keycard, code, power-gated, sealed, hidden) | kind `door` |
| Echo events (past replays) | 29 | kind `ghost` |
| Achievements | 18 (6 hidden) | `story.gd` ACH |
| Credits | 29 entries, exact names and roles | `story.gd` CREDITS |
| Systems | Radio (tuning, bands, directional antenna, battery, exposure → the Listener hears the carrier), flashlight with cells, stamina/sprint, crouch, lean, hiding (lockers, under desks), throwable lures, medkits, injuries, journal, objectives, subtitles, checkpoints and saves with backup, settings and accessibility, gamepad, local play-time log | `scripts/*.gd` (5,214 lines) |
| The Listener's AI | 8 states (dormant, patrol, investigate, search, stalk, hunt, ambush, retreat), hearing with blurred localisation, sight affected by the torch and crouching, learning (lockers used, radio use, lures, sprint escapes), mimicry of voices, cloaked variant visible only on 107.9, New Game+ memory, a fairness cap on chases | `scripts/listener.gd` |
| QA walkthroughs | 179 critical-path steps across the chapters | `walk` data, used by the automated full-campaign test |

The conversion is already done and verified: `tools/ue/godot_to_ue.py` turns the exported Godot data into
`unreal/DeadFrequency/Content/Data/Story/*.json` and writes `PARITY.md` — **640 of 640 voice lines found again with
the same ids, speakers and text, nothing missing, nothing extra**, all documents, tapes, transmissions, devices,
doors, puzzle groups and walkthroughs carried per chapter. Level layouts carry over as the original 2 m grids
(greybox reference only; every level is re-authored in Unreal).

## 2. Project architecture (Unreal Engine 5.8)

### 2.1 Layout

```
unreal/DeadFrequency/
├─ DeadFrequency.uproject          engine 5.8; plugins: Enhanced Input, CommonUI, StateTree, Python editor scripting
├─ Config/                         renderer (Lumen, Nanite, virtual shadow maps), game, input, scalability
├─ Source/DeadFrequency/           the C++ game module
│  ├─ Story/     chapter data types, the story runtime (flags, objectives, sequence runner)
│  ├─ Radio/     HX-7 radio component, transmitters
│  ├─ Player/    first-person character, interaction and hiding interfaces
│  ├─ AI/        the Listener: pawn, AI controller (perception + state machine), learning memory
│  ├─ Core/      game mode, game instance, save games
│  └─ Settings/  graphics presets and options
├─ Content/
│  ├─ Data/Story/*.json            converted story data (text, diffable, staged with the build)
│  └─ DeadFrequency/...            Unreal assets (binary): Art, Audio, Blueprints, Cinematics, Maps, UI, FX
└─ Scripts/                        Unreal editor Python: asset import, material instances, data validation
```

Binary Unreal content (`.uasset`, `.umap`) does not belong in plain Git: `unreal/.gitattributes` routes it to
**Git LFS** (decision 3 in §8 chooses between Git LFS and Perforce).

### 2.2 From the Godot code to Unreal classes

| Godot | Unreal | Notes |
|---|---|---|
| `main.gd` (flow, menus, chapters) | `UDFGameInstance`, `ADFGameMode`, front-end map | Chapter loading becomes level streaming per chapter |
| `g.gd` (global state, profile) | `UDFGameInstance` + `UDFSaveGame` / `UDFProfileSave` | Same data; saves become `USaveGame` slots with a backup slot |
| `level.gd` event runner | `UDFStorySubsystem` (game-instance subsystem) | The 50 event commands (46 used by the story, plus spoken lines) port 1:1 onto the converted sequences; cinematics become Level Sequences started by a `sequence` command |
| `level.gd` grid level builder | — | Replaced by authored levels; the grid stays as greybox reference and for automated reachability checks |
| `player.gd` | `ADFPlayerCharacter` + components | Enhanced Input (keyboard/mouse and gamepad), first-person arms rig |
| `radio.gd` | `UDFRadioComponent` + `ADFTransmitter` | Same tuning, bands, signal and exposure rules; exposure reports noise to the AI perception system |
| `listener.gd` | `ADFListenerCharacter` + `ADFListenerController` | AI Perception (hearing, sight), navigation mesh, the 8-state machine (later a StateTree asset), EQS for search spots, Smart Objects for vents and hiding places, learning memory saved with the run |
| `ui.gd`, `hud_draw.gd`, `menu.gd` | CommonUI + UMG widgets | Menus, pause, settings, journal, keypad, chapter select, subtitles, chapter cards, credits |
| `snd.gd` (synthesised placeholders) | MetaSounds, Quartz, Audio Modulation | Designed and recorded sound replaces the synthesised placeholders; the radio DSP chain becomes a MetaSound patch |
| `fx.gd` | Niagara | Steam, drips, dust, sparks, rain |
| `tests/test.gd` (11 suites) | Automation tests, Functional Tests, Gauntlet | §2.5 |

### 2.3 Data model

Story data stays text: each chapter is an `FDFChapterData` loaded from JSON at startup (`FJsonObjectConverter`),
so story fixes are reviewable diffs and the converter can be re-run safely. A chapter holds its title, subtitle,
level properties, the legend of interactive things (kind, properties, script and radio lines), their placements on
the original grid, flat **sequences** of steps (nested `if`/`choice` blocks are referenced by index), the
pre/start/resume sequences, puzzle groups and the QA walkthrough. In the levels, designers place Unreal actors
(transmitters, notes, doors, devices, hiding spots) that refer to the legend by symbol; a validation script checks
that every legend entry is placed in its level and every placed actor exists in the data.

### 2.4 Systems in Unreal terms

- **Rendering:** Lumen global illumination and reflections (software ray tracing by default, hardware ray tracing
  on Epic/Cinematic for RTX cards; Unreal 5.8's lighter Lumen option on Low/Medium), Nanite for static meshes,
  virtual shadow maps, exponential height fog with volumetric fog (the torch and lamps scatter light in it),
  deferred and mesh decals, Niagara, Temporal Super Resolution plus NVIDIA DLSS / AMD FSR / Intel XeSS through
  their official plugins (each under its vendor licence), post-process volumes per area, Movie Render Queue for
  trailers.
- **The Listener:** skeletal mesh with LODs, physics asset, Control Rig (foot IK on uneven floors, look-at, membrane
  "breathing" driven by listening intensity), Animation Blueprint state machine (motion matching evaluated for
  locomotion), skin through a subsurface profile (or Substrate if production-ready in 5.8), wet sheen layer,
  translucent membrane with back-lit transmission.
- **First person:** gloved arms skeletal mesh with a full animation set (idle, walk/run sway, raise/lower radio,
  turn the tuning knob, switch the torch, interact, hide, injured), the HX-7 with a live display (material driven
  by the radio component), the torch with an IES profile and volumetric scattering. First-person rendering is set
  up so the arms do not clip into walls and keep their own field of view.
- **Audio:** MetaSounds; Quartz-synced adaptive music (tension and chase layers, silence when it is close); Audio
  Modulation for ducking; convolution reverb per area; radio processing chain; recorded voice-over mapped by the
  existing voice-over ids, subtitles from the same data.
- **UI:** CommonUI for gamepad-correct navigation; UMG for the minimal HUD, chapter cards and credits; String
  Tables for localisation.
- **Saves and settings:** `USaveGame` slots (checkpoint autosaves plus a backup slot), profile with unlocked
  chapters, endings, achievements and New Game+ memory; `UDFGameUserSettings` (§6).
- **Steam:** Steamworks through Unreal's Steam online subsystem: achievements (18, same ids), stats, Steam Cloud.
  The App ID comes from the owner's Steamworks account; Valve's public test app id is used for development only.

### 2.5 Testing and builds

- **Automation tests (C++):** story data parity, every flag read is set somewhere, every legend entry is placed,
  save/load round trips, radio maths, settings presets.
- **Functional tests (test maps):** movement, hiding, radio reception and exposure, the Listener's senses and
  state changes, doors and puzzles.
- **Gauntlet full playthrough:** a bot follows the 179 walkthrough steps through all 13 chapters and every ending,
  as the Godot `play` suite does today.
- **Performance:** Unreal Insights, `stat unit`/`stat gpu`, CSV profiler captures on the RTX 3060 for each
  milestone; budgets per area.
- **Builds:** `RunUAT BuildCookRun` on the build machine (Windows, Development and Shipping), a self-hosted CI
  runner for nightly builds once the project compiles, packaged builds handed to the owner with screenshots.

## 3. Development environment

| Need | Status | Who |
|---|---|---|
| Unreal Engine 5.8 (Epic Games Launcher) and Visual Studio 2022 with the C++ game workload | Not installed anywhere yet. Installing Unreal requires the owner's Epic account and accepting the Unreal EULA. | Owner |
| A Windows PC with an RTX-class GPU to compile, run, profile and capture | The owner's RTX 3060-class PC, connected to the Claude Code sessions (Claude desktop app → Settings → Claude Code → Remote Control, sharing the project folder), or a rented cloud GPU workstation | Owner decides (§8) |
| Blender 4.x | Available in the cloud sessions (scripted, headless) and installable on the owner's PC | — |
| Source control for binary assets | Git LFS (GitHub data packs) or Perforce Helix Core | Owner decides (§8) |

This cloud container can do everything that does not need the engine: C++ and data authoring, the story
converter and its checks, Blender modelling scripts and bakes, texture work, documentation. It **cannot** compile or
run Unreal, so code written here is marked "not yet compiled" until it has been built on the build machine.

## 4. Asset pipeline

### 4.1 Sources and licences

| Source | Licence | Use |
|---|---|---|
| Original work (Blender, Substance or Blender painting, scripts) | Owned by the project | All hero assets: the Listener, HX-7, torch, arms, signature props, modular kits |
| Poly Haven, ambientCG | CC0 | Surfaces, HDRIs, props (already used) |
| Fab (Epic's marketplace, includes Quixel Megascans) | Fab licence of each listing (check per asset; some free, some paid) | Surfaces, decals, debris, set dressing |
| MetaHuman | MetaHuman licence (Unreal-only use) | Daniel and the human characters in cinematics |
| Motion-capture libraries | Per-pack licence (bought only with the owner's approval) | Base locomotion for arms and humans, edited by hand |
| Sound | CC0, licensed libraries, commissioned work | Replaces the synthesised placeholders |

Every imported asset gets an entry (source, author, licence, link, date) in `docs/THIRD_PARTY_NOTICES.md`;
nothing is bought without the owner's approval; nothing generated to imitate another game's assets is used.

### 4.2 Blender → Unreal conventions

- **Scale and axes:** metres in Blender, exported to centimetres (1 Unreal unit = 1 cm); Z up, X forward in
  Unreal. FBX for skeletal meshes and animation (no leaf bones, deform bones only), FBX or glTF through Interchange
  for static meshes.
- **Names (Unreal style guide):** `SM_` static mesh, `SK_` skeletal mesh, `SKEL_`, `PHYS_`, `ABP_`, `A_`
  animation, `CR_` control rig, `T_<name>_BC/_N/_ORM` textures, `M_` master materials, `MI_` instances, `BP_`,
  `WBP_`, `NS_` Niagara, `MS_` MetaSound, `LS_` level sequence, `L_` levels, `DA_`/`DT_` data.
- **Textures:** base colour (sRGB), normal (**DirectX convention: the green channel is flipped from the OpenGL maps
  used in Godot**), ORM packed (R occlusion, G roughness, B metal), 4K for hero assets, 2K for kits, trim sheets for
  architectural detail; texel density 1,024 px/m on surfaces the player can touch, 512 px/m elsewhere.
- **Meshes:** Nanite for static environment meshes (no hand LODs needed), hand LODs for skeletal meshes; simple
  collision (`UCX_`) for gameplay, complex collision only where needed; sockets for attachments (torch beam, radio
  antenna, the Listener's claws).
- **Materials:** a small set of master materials (opaque PBR with wetness and grime layers, decal, glass, emissive
  screen, skin, membrane) and instances per asset.
- **Automation:** `unreal/DeadFrequency/Scripts/` holds editor Python scripts that import a Blender export folder,
  create material instances from texture sets and check names, budgets and licence entries.

### 4.3 The Listener (production quality)

1. Concept and proportions locked against the owner's references (original design, not a copy).
2. High-resolution sculpt (Blender sculpt or ZBrush): anatomy, ribcage, tendons, pores, veins, the trumpet membrane
   with pores and tissue folds.
3. Retopology to a game mesh (about 80–120k triangles for LOD0 with the membrane), clean UVs (UDIMs or 2–3 4K sets).
4. Bakes (normal, cavity, curvature, thickness for subsurface), hand-painted textures (skin, veins, blood, wet layer).
5. Rig in Blender (Unreal-compatible skeleton, membrane bones, corrective shapes) → Control Rig in Unreal.
6. Animation: hand-keyed signature motions (listening, the breathing, crawling through vents, the drop from the
   vent, searching, the lunge, death-grip on the player) plus licensed motion capture as a base for locomotion,
   cleaned and exaggerated by hand.
7. Unreal: skin material, membrane transmission, wet strands as Niagara/ribbons, sound attached to animation notifies.

The procedural sculpt of the Godot slice (Listener v3) is the blockout for step 2; a human character artist and
an animator are strongly recommended for steps 2–6 (§7).

### 4.4 Environments

The 13 chapters map onto area kits: entrance and checkpoint, administration, medical, quarters, power and
generators, flooded sublevel, signal and communications rooms, laboratories, transport and rail, containment,
archive, the ring, the door; plus the exterior (HELIX-9 portal in the rain). Each kit: modular architecture
(Nanite), trim sheets and tiling materials with wetness and grime, decal sets, signature props, a lighting recipe.
Kits are built once and dressed per chapter so no two corridors repeat.

### 4.5 Cinematics, UI, audio

Cinematics in Sequencer (opening, both title reveals, creature introductions, major encounters, chapter
transitions, the final confrontation, the four endings, credits) with MetaHuman performances where faces are seen.
Menus, HUD, chapter cards and credits are rebuilt in UMG in the style established by the Godot slice (signal red,
horizon cards, minimal HUD). Voice-over is recorded from the existing script (`docs/vo/`).

## 5. The Unreal vertical slice (approval gate)

**Scope:** the same moment as the Godot slice — Sublevel 3: the service corridor and communications room C3-14,
the forecast and echo transmissions, powering the main receiver, the lights failing, the Listener coming down the
vent, hiding under the desk — rebuilt at production quality in Unreal.

**Acceptance criteria (all shown with in-engine evidence):**
1. Playable from the main menu in a packaged Windows build; the full encounter works with the real AI.
2. Environment at final quality: Nanite kit, Lumen lighting, volumetric fog and light shafts, wet surfaces, decals.
3. The Listener at production quality (sculpted, textured, rigged, animated), convincing under full torch light.
4. First person: arms, torch and HX-7 with animations and the live display.
5. Menu, HUD, chapter card, subtitles, settings with all presets.
6. Audio: designed ambience, radio processing, creature sound, music layers (voice-over recorded or placeholder,
   stated).
7. Performance measured on the RTX 3060: frame times per preset at 1080p/1440p/4K, with captures.
8. Evidence: native 1440p and 4K screenshots, a gameplay video with sound, the measured numbers, asset and
   licence list.

## 6. Performance targets and scalability

| Preset | Unreal scalability | Target on RTX 3060 (to be measured) |
|---|---|---|
| Low | 0 (light Lumen, no volumetric fog, reduced shadows) | GTX 1660-class at 1080p, 60 fps |
| Medium | 1 | 1080p, 60+ fps |
| High | 2 | 1440p with TSR/DLSS Quality, 60 fps |
| Ultra | 3 (Epic) | 1440p with DLSS/TSR Balanced, 60 fps |
| Cinematic | 4 (hardware ray tracing on RTX) | 4K with DLSS Performance, 30–60 fps; trailers |

Options carried over from the Godot game: resolution (to 3840 × 2160), render scale, upscaler (TSR, DLSS, FSR,
XeSS), texture quality (texture pool), shadows, reflections, global illumination, ambient occlusion,
anti-aliasing, view distance, effects, post-processing, V-Sync, frame-rate limit, field of view, brightness,
motion blur and film grain toggles, subtitles and accessibility. Shader pre-compilation (PSO caching) is part of
the build so the first play-through does not hitch.

## 7. Timeline, team and budget (estimates)

| Phase | Duration | Delivers | Depends on |
|---|---|---|---|
| 0. Environment | 1–2 weeks | Unreal 5.8 and Visual Studio on the build machine, project compiling, source control with LFS or Perforce, first captures | Owner decisions 1–3 |
| 1. Core port | 3–5 weeks | Story runtime with all 18 scripts, radio, player, the Listener's AI, saves, settings, UI shell, automated tests green; greybox of the slice from the Godot layout; first playable greybox build | Phase 0 |
| 2. Vertical slice | 6–10 weeks (overlaps 1) | Everything in §5 | Character artist/animator for the Listener (recommended) |
| **Approval gate** | — | Owner approves or redirects | — |
| 3. Production | 8–11 months | 13 chapters and the exterior at slice quality; all cinematics; New Game+; achievements; recorded voice-over | Kits, artists, voice cast |
| 4. Polish and optimisation | 2–3 months | Performance on target hardware, bug fixing, playtests (measured length), accessibility, localisation pass, Steam integration | Playtesters |
| 5. Release | 1–2 months | Steam page and trailer from in-engine captures, demo (the slice), launch build | Steam App ID, store assets |

**Team assumed:** the owner (direction, design, testing, Unreal operation on the build machine); Claude (C++ and
Blueprint systems, data and tools, Blender modelling and procedural assets, environment kits, lighting setups,
documentation, test automation); contracted specialists for what software alone does not reach at this level: a
character artist and an animator (the Listener, arms, hero props), an environment artist part-time (kits),
a sound designer and composer, voice actors. Without contractors the plan still works but slows to roughly
18–24 months and the creature and animation ceiling drops.

**Costs to expect (owner approval required for each):** Steam app fee; Fab/Megascans assets beyond the free ones;
motion-capture packs; Git LFS data packs or Perforce hosting; a cloud GPU workstation if the owner's PC is not
used; contractor fees; voice actors; the Unreal royalty after launch (above US$1 million lifetime gross).

## 8. Decisions needed from the owner now

1. **Build machine:** connect your RTX 3060-class Windows PC to these sessions (Claude desktop app → Settings →
   Claude Code → Remote Control, sharing the `DEAD-FREQUENCY-` folder), or approve a rented cloud GPU workstation.
2. **Install** Unreal Engine 5.8 from the Epic Games Launcher (your Epic account accepts the EULA) and Visual Studio
   2022 with "Game development with C++".
3. **Binary asset storage:** Git LFS on GitHub (simple; paid data packs as the project grows) or Perforce Helix Core
   (the industry standard for Unreal; separate server).
4. **Art budget:** whether to contract a character artist/animator for the Listener and the arms, and which asset
   libraries may be bought.
5. **Steam:** the Steamworks account and App ID when the store page is due.

## 9. Risks and how they are handled

| Risk | Handling |
|---|---|
| Scope: 13 chapters at premium quality is a large production | Area kits reused across chapters; the slice sets the bar and the cost per chapter before production starts |
| Code written here cannot be compiled here | Every change is compiled and tested on the build machine before it counts; no feature is reported complete without a run and a capture |
| The creature's quality depends on sculpting and animation skill | Professional character artist/animator; procedural blockout from the Godot slice as the brief |
| Performance on the RTX 3060 with Lumen and volumetric fog | Measured from the greybox onwards; light Lumen and upscalers in the presets; budgets per area |
| Story regressions while porting | Converted data with parity checks; the Godot game stays as the reference; automated full playthrough |
| Unreal Engine 6 arriving during production | Stay on 5.8 to launch; evaluate an upgrade afterwards |
| Repository size | Binary content in LFS or Perforce, never in plain Git |
