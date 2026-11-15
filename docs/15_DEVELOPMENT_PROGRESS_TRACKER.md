# DEAD FREQUENCY — Development Progress Tracker

Status key: **Tested** = implemented and covered by a passing automated test · **Implemented** = in the game and exercised by playthrough/visual checks, no dedicated assertion · **Partial** · **Planned** · **Blocked** (cannot be done in this environment) · **Awaiting external** (needs people, money or hardware outside this project).

Latest full regression (2026-11-15, after the second reference pass): validate 257/0 · flags 161/0 · layout 18/0 · save 22/0 · systems 29/0 · ai 12/0 · flow 15/0 · endings 26/0 · ngplus 15/0 · play 225/0 · slice 17/0 · texq 3/0 — 800 checks, 0 failures · vo 4/0 (with a fixture recording) · introtime 135 s · `--smoketest` 15/15 from source (Linux) and from the exported exe under Wine 9.0.

## Unreal Engine 5 migration (current brief)
The owner chose Unreal Engine 5 as the primary engine. The Godot 3.5 game stays in `game/` as the playable backup; the
Unreal project is separate, in `unreal/DeadFrequency/`. Plan: [24](24_UNREAL_ENGINE_5_MIGRATION_PLAN.md).

| Item | Status |
|---|---|
| Migration roadmap, architecture, asset pipeline, timeline | **Done** — docs/24 |
| Separate UE 5.8 project (uproject, config, targets, LFS rules) | **Implemented** — not opened in the editor yet |
| Story data converted (13 chapters, prologue, 4 endings, slice, items, achievements, credits, mimicry) | **Tested** — parity script: 640/640 lines, 0 missing, 0 extra; +9 mimicry lines still to add to the VO package |
| C++ foundation: story runtime, radio, player, Listener AI, run/profile/saves, game mode, settings | **Partial** — written, **not compiled** (no Unreal machine connected) |
| Level director, UI (HUD, subtitles, cards, menus, credits), cinematics | **Planned** — needs the editor |
| Listener production model, skin, rig, animations | **Planned** — needs a character artist/animator decision (docs/24 §8) |
| Environments, first-person HX-7, torch and hands | **Planned** |
| Unreal vertical slice for approval | **Blocked** — needs a Windows PC with UE 5.8 and Visual Studio 2022 connected to the sessions |
| Performance on RTX 3060-class hardware | **Awaiting hardware** — nothing measured |

## AAA graphics and 4K transformation (previous brief)
| Item | Status |
|---|---|
| Visual audit + 4K vertical slice, the brief's ten items | **Done** — docs/21 §2 (item-by-item, with gaps); **not photoreal, not AAA** |
| Native 4K evidence (3840 × 2160) | **Done** — 14 in-game views + 3 creature studio views, `docs/screenshots/slice4k/` |
| The Listener to the reference (anatomy, membrane, skin, veins, asymmetry, rig, animation, SSS, LODs) | **Implemented and tested** (`slice`, `texq`) — procedural sculpt; membrane LOD still to do (K8) |
| First person: gloves, torch, HX-7 with live display and turning knob, beam falloff, interaction motion | **Implemented and tested** (`slice`) — no finger animation |
| Environment: corridor and room, 4K surfaces, wet floors, decals, red emergency lighting | **Implemented** (visual QA via `sliceshots`) |
| Graphics settings: 5 presets, 4K, render scale, texture quality, shadows, reflections, AO, AA, view distance, V-Sync, frame limit | **Implemented**; texture quality **Tested** (`texq`); others exercised by `sliceshots`/benchmark |
| GPU performance measurements | **Awaiting hardware** — `--benchmark [--4k]` ready for the owner's PC; nothing measured on a GPU |
| Gameplay recording | **Done** — `docs/media/slice_gameplay.mp4` (720p30, silent) |
| Asset and texture specifications | **Done** — docs/23 |
| Godot 4 isolated benchmark + engine evaluation | **Done** — docs/22; recommends Godot 4; **migration awaiting owner approval** |
| Second reference pass (pale veined creature, trumpet membrane, stalking stance, wet walls, haze, live CRT feed, menu, chapter card, HUD) | **Implemented** — docs/21 §0; evidence re-captured at native 4K |
| All chapters, main menu, UI, cinematics at the new standard | **Awaiting approval** (the brief forbids it before approval) |

## Final deliverables (as requested)
| # | Deliverable | Status |
|---|---|---|
| 1 | Updated playable game | **Tested** — 13 chapters, prologue, 4 endings, credits; full campaign plays end-to-end in the automated test |
| 2 | Expanded campaign | **Partial** — optional wings in every chapter, Directorate Annex, Mira's notebook, Pell's calls, two-part objectives (Ch 5, 8, 9, 11), Ch 6 narrative branch, more encounters. Modelled length 3.9–10.1 h main path, 5.4–14 h with all optional content (17_TIME_BUDGET.md) — **not measured with players; 10–15 h not claimed** |
| 3 | New Game+ | **Tested** — cross-run memory, bounded adaptations, 88.0 thread, encounter variants, postscripts |
| 4 | Improved graphics | **Partial** — CC0 PBR materials, fixtures and light shafts, particles, water, new creature, first-person hands, textured exterior, better human figures. Still procedural geometry; **not photoreal** |
| 5 | Improved audio | **Partial** — adaptive music, silence logic, surface footsteps, creature sounds, fear breathing, VO hook; all sound still synthesised placeholders. No recorded audio |
| 6 | Improved cinematics | **Partial** — new creature and figures in every cinematic; second reveal rebuilt as a CRT terminal (text unchanged, last line turns red); SIGNAL LOST, pause and settings screens polished. Camera work and timing unchanged; no motion-captured or hand-animated performances |
| 7 | Updated Windows build | **Implemented** — exported from the final code; `--smoketest` 15/15 under Wine 9.0; clean release zip with licences and checksums (`tools/package_release.sh`); **not run on real Windows**; exe icon/version resource and code signing pending |
| 8 | Automated test reports | **Tested** — 13_TESTING_PLAN.md, 16_BUG_REPORTS.md |
| 9 | Updated GDD | **Implemented** — 01 |
| 10 | Updated Story Bible | **Implemented** — 02 (incl. New Game+ canon) |
| 11 | Updated technical documentation | **Implemented** — 12, 19, 21, 22 (Godot 4 benchmark), 23 (asset specs) |
| 12 | Updated progress tracker | this document |
| 13 | Steam release package | **Implemented** — 20_STEAM_RELEASE_PACKAGE.md, PRIVACY.md, THIRD_PARTY_NOTICES.md; integration **awaiting App ID** |

## Phase status
| Phase | Status |
|---|---|
| 1 Finish incomplete gameplay | **Done** — two-part objectives Ch 8/11, save robustness, resolution setting, radio state, bug log |
| 2 Expand toward 10–15 h | **Partial** — see deliverable 2; needs playtest data before more content is scoped |
| 3 New Game+ | **Done — Tested** |
| 4 Graphics and characters | **Partial** — everything achievable with code + CC0 libraries in this environment is in; authored characters/environments need artists (11_ASSET_PRODUCTION_LIST.md) |
| 5 Sound and music | **Partial** — systems done; content needs a sound designer, composer and actors (18_AUDIO_PRODUCTION_PLAN.md, docs/vo/) |
| 6 Cinematics and UI | **Partial** — polish pass done on the second reveal, game over, pause and settings; title reveal, cards and credits reviewed (gallery); further polish needs real art/animation |
| 7 Performance and Windows | **Partial** — built-in smoke test; Windows exe passes it under Wine; release package; CI Wine job; pause on focus loss. GPU performance and real-Windows testing awaiting hardware |
| 8 Release preparation | **Done (docs)** — publishing, Steamworks and App ID **awaiting owner** |

## Feature status
| Feature | Status |
|---|---|
| Movement, sprint, crouch, lean, stamina | Tested |
| Flashlight, battery, spare cells | Tested |
| Radio: dial, 4 bands, hidden carriers (88.0, 92.3, 93.3, 96.1, 98.5, 99.7, 103.7, 104.4), antenna, battery, exposure | Tested |
| Inventory, keys, items, medkits, bottles | Tested |
| Health and injuries (slow, heartbeat, vignette) | Implemented |
| Doors: plain, keycard, code, power-gated, sealed; hidden door | Tested |
| Puzzles: codes, ordered switches, rotation, crate/plate, two-person release, voiceprint, multi-stage annex | Tested (every puzzle in the critical-path or optional walkthrough) |
| Hiding with learned searching | Tested |
| Listener AI: 8 states, hearing, sight, learning, mimicry, cloaked, blind, New Game+ adaptations | Tested |
| Objectives, journal, subtitles, prompts, HUD | Implemented |
| Save/load/checkpoints, atomic saves + backup fallback | Tested |
| Menus, chapter select, settings (incl. resolution), pause | Tested |
| Pause on window focus loss | Tested |
| Local play-time log (per chapter time, deaths, completion) + report tool | Tested (log); report tool run on sample data only |
| Built-in `--smoketest` | Tested (source on Linux; exported exe under Wine) |
| Release package (exe, README, credits, notices, licences, checksums) | Implemented |
| Gamepad | Implemented (bindings); **not tested with hardware** |
| Opening cinematic + first title reveal (2 min 15 s) | Tested |
| Second title reveal "SIGNAL IDENTIFIED / SUBJECT: DANIEL ARLEN / STATUS: ALREADY INSIDE" | Tested |
| Four endings + New Game+ postscripts | Tested |
| Credits (exact names/roles, skip, return to menu, completion saved) | Tested |
| Achievements (18, 6 hidden) | Implemented (local); Steamworks awaiting App ID |
| PBR materials, light shafts, particles, water, creature model, hands | Implemented (visual QA via `gallery`) |
| Adaptive music, silence, surface footsteps, creature sounds, VO hook | Implemented; VO hook Tested |

## Honest gaps against the brief
| Brief | Reality | Why / next step |
|---|---|---|
| Photorealistic 4K graphics | Campaign: procedural geometry with CC0 PBR textures. Vertical slice: authored 4K-capable art, not photoreal | Godot 4 benchmarked (22) and recommended; UE5 not needed; awaiting the owner's approval of the slice and the engine path |
| Professional characters and animation | Procedural rigs with code animation | Needs a character artist/animator |
| 10–15 h campaign | Modelled 5.4–14 h incl. optional content, unmeasured | Playtests first; then scope more content where players finish fastest |
| Professional audio, soundtrack, VO | Systems ready; placeholders only | Sound designer (credited: Ajay Gohil), composer, voice cast |
| Windows verification | Exported; smoke test passes under Wine only | Run the build on Windows 10/11 (`--smoketest`, checklist in 13 §9.2) |
| Steam | Package prepared | Owner's Steamworks account and App ID |

## Roadmap
1. Owner runs `DeadFrequency.exe --smoketest` on Windows and plays chapters 1–3; fix anything found.
2. Playtest round 1 (5 players): replace the time-budget model with measured data.
3. Decide engine path (22): stay on 3.5 or port to Godot 4 (recommended); run `--benchmark` on the target GPU first.
4. Commission creature + Daniel arms model, environment kit for 2 areas as a vertical slice of the final art style.
5. Audio: sound designer pass on creature/radio/footsteps; record VO for chapters 1–3; composer stems for tension/chase.
6. Steamworks: App ID, achievements, Auto-Cloud, Coming Soon page.
