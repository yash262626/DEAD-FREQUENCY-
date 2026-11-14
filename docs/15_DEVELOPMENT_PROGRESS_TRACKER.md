# DEAD FREQUENCY — Development Progress Tracker

Status key: **Tested** = implemented and covered by a passing automated test · **Implemented** = in the game and exercised by playthrough/visual checks, no dedicated assertion · **Partial** · **Planned** · **Blocked** (cannot be done in this environment) · **Awaiting external** (needs people, money or hardware outside this project).

Latest full regression: validate 257/0 · flags 161/0 · layout 18/0 · save 17/0 · systems 29/0 · ai 12/0 · flow 13/0 · endings 26/0 · play 225/0 · ngplus 15/0 · vo 4/0 (with a fixture recording) · introtime 135 s.

## Final deliverables (as requested)
| # | Deliverable | Status |
|---|---|---|
| 1 | Updated playable game | **Tested** — 13 chapters, prologue, 4 endings, credits; full campaign plays end-to-end in the automated test |
| 2 | Expanded campaign | **Partial** — optional wings in every chapter, Directorate Annex, Mira's notebook, Pell's calls, two-part objectives (Ch 5, 8, 9, 11), Ch 6 narrative branch, more encounters. Modelled length 3.9–10.1 h main path, 5.4–14 h with all optional content (17_TIME_BUDGET.md) — **not measured with players; 10–15 h not claimed** |
| 3 | New Game+ | **Tested** — cross-run memory, bounded adaptations, 88.0 thread, encounter variants, postscripts |
| 4 | Improved graphics | **Partial** — CC0 PBR materials, fixtures and light shafts, particles, water, new creature, first-person hands, textured exterior, better human figures. Still procedural geometry; **not photoreal** |
| 5 | Improved audio | **Partial** — adaptive music, silence logic, surface footsteps, creature sounds, fear breathing, VO hook; all sound still synthesised placeholders. No recorded audio |
| 6 | Improved cinematics | **Partial** — new creature and figures appear in every cinematic; title reveal, second reveal, cards and endings unchanged in structure (see 07_CINEMATIC_SCRIPT.md) |
| 7 | Updated Windows build | **Implemented** — exported from the final code; Wine smoke test (see 13_TESTING_PLAN.md); **not run on real Windows** |
| 8 | Automated test reports | **Tested** — 13_TESTING_PLAN.md, 16_BUG_REPORTS.md |
| 9 | Updated GDD | **Implemented** — 01 |
| 10 | Updated Story Bible | **Implemented** — 02 (incl. New Game+ canon) |
| 11 | Updated technical documentation | **Implemented** — 12, 19 (engine migration assessment) |
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
| 6 Cinematics and UI | **Partial** — functional and tested; a dedicated polish pass with real assets is pending |
| 7 Performance and Windows | **Partial** — CPU-side measured; GPU and real-Windows testing awaiting hardware |
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
| Unreal Engine 5 / realistic graphics | Godot 3.5; stylised procedural geometry with CC0 PBR textures | UE5 impossible here (no GPU); migration options assessed in 19 — awaiting decision |
| Professional characters and animation | Procedural rigs with code animation | Needs a character artist/animator |
| 10–15 h campaign | Modelled 5.4–14 h incl. optional content, unmeasured | Playtests first; then scope more content where players finish fastest |
| Professional audio, soundtrack, VO | Systems ready; placeholders only | Sound designer (credited: Ajay Gohil), composer, voice cast |
| Windows verification | Exported; Wine smoke test only | Run the build on Windows 10/11 (`--smoketest`, checklist in 13) |
| Steam | Package prepared | Owner's Steamworks account and App ID |

## Roadmap
1. Owner runs `DeadFrequency.exe --smoketest` on Windows and plays chapters 1–3; fix anything found.
2. Playtest round 1 (5 players): replace the time-budget model with measured data.
3. Decide engine path (19): stay on 3.5 or port to Godot 4 for real-time GI.
4. Commission creature + Daniel arms model, environment kit for 2 areas as a vertical slice of the final art style.
5. Audio: sound designer pass on creature/radio/footsteps; record VO for chapters 1–3; composer stems for tension/chase.
6. Steamworks: App ID, achievements, Auto-Cloud, Coming Soon page.
