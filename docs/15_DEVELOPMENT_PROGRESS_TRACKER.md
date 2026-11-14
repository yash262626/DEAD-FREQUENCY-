# DEAD FREQUENCY — Development Progress Tracker

Status key: **Tested** = implemented and covered by an automated test that passes · **Implemented** = in the game, exercised by playthrough tests or manual checks but without a dedicated assertion · **Partial** = present in reduced form · **Planned** = designed, not built · **Blocked** = cannot be done in this environment.

Last full test run: validate 225/0 · flags 49/0 · layout 18/0 · save 12/0 · systems 28/0 · ai 12/0 · flow 13/0 · endings 26/0 · play 146/0 · introtime 135 s.

## Milestones
| Phase | Scope | Status |
|---|---|---|
| 1 Pre-production | GDD, story & character bibles, campaign, architecture, asset list, roadmap | **Done** (docs 01–15) |
| 2 Core development | controller, interaction, flashlight, inventory, radio, UI, save | **Done — Tested** |
| 3 Horror systems | Listener AI, sound detection, stalking, hiding, environmental horror | **Done — Tested** |
| 4 World development | 13 chapters + prologue + ending sets, puzzles, exploration | **Done (procedural art)** — length below target |
| 5 Story & cinematics | dialogue, tapes, cutscenes, title reveals, chapter cards, endings, credits | **Done — Tested** (no recorded VO) |
| 6 Polish & testing | optimisation, bug fixing, balancing, release builds | **Partial** — automated QA done; human playtests, GPU profiling, Windows launch test outstanding |

## Feature status
| Feature | Status | Notes |
|---|---|---|
| First-person walk / sprint / crouch / lean / stamina | Tested | `systems` |
| Flashlight + battery + spare cells | Tested | |
| Inventory, keys, items | Tested | `systems`, `play` |
| Health, injuries (slow + heartbeat + vignette), medkits | Tested | |
| Interaction, doors, keycards, code locks, power-gated doors | Tested | |
| Physics puzzle (crate + plate) | Tested | Ch 3 |
| Ordered-switch puzzles, rotation puzzles | Tested | Ch 5, 6, 7, 9 |
| Hiding (lockers) with learned searching | Tested | `ai` |
| Throwing distractions | Implemented | |
| Radio: dial, bands, directional antenna, battery, static, signal bars, exposure | Tested | |
| 89.1 / 94.6 / 101.3 / 107.9 + hidden carriers | Tested | every chapter |
| Listener: 8 states, hearing, sight, learning, mimicry, cloaked, blind | Tested | `ai` + playthrough |
| Objectives, journal, subtitles, prompts, HUD | Implemented | |
| Save / load / checkpoints / emergency terminals / death & reload | Tested | `save`, `flow` |
| Main menu (3D), Continue, Chapter Selection (unlocking), Settings, Credits, Exit | Tested | `flow` |
| Pause menu, settings (audio, video, controls, accessibility) | Tested | `systems` |
| Keyboard + mouse, gamepad | Implemented | gamepad not tested with hardware |
| Opening cinematic (2:15) + first title reveal | Tested | `flow`, `introtime` |
| Second title reveal (~25 min, "ALREADY INSIDE") | Tested | `play` |
| Chapter cards (13) | Implemented | reviewed visually |
| Cinematics (12 required beats) | Implemented | see 07_CINEMATIC_SCRIPT.md |
| Four endings with distinct staging | Tested | `endings` |
| End credits (exact names, skip, return to menu, completion saved) | Tested | `endings` |
| Achievements (13) | Implemented | local; Steamworks planned |
| Procedural audio (33 sounds), 3D positional audio, reverb | Implemented | |
| Windows export | Implemented | 39.6 MB `.exe` exported; **not launched on Windows yet** |
| Linux export | Implemented | booted headless OK |
| CI (tests + exports) | Implemented | workflow written; not yet run on GitHub |

## Against the original brief — gaps, stated plainly
| Brief | Reality | Why / plan |
|---|---|---|
| Unreal Engine 5, C++, Lumen, Nanite | **Blocked here** → Godot 3.5, GDScript | No GPU, no UE5 available; Godot 4 binary blocked by environment policy. Data and design are portable. |
| Highly realistic 3D, detailed characters | **Partial** — stylised procedural stand-ins | Needs the art pipeline in 11_ASSET_PRODUCTION_LIST.md (Blender/Substance not available here). |
| 10–15 h main campaign | **Not met** — estimated **3–5 h** (≈ 51 min scripted content), unmeasured with players | See expansion plan below. Target unchanged. |
| Voice-acted cinematic dialogue | **Partial** — all 490 lines written and subtitled; procedural voice texture only | Casting/recording needed. |
| Original music score | **Partial** — procedural drones and stingers | Composer needed. |
| Steam release | **Partial** — store copy, briefs, achievements, build pipeline ready | Steamworks integration, page assets, playtests outstanding. |

## Expansion plan toward 10–15 hours (no padding)
Measured priority after the first playtests; each item adds real content, not corridors:
1. **Optional wing per chapter** (13 × 10–15 min): side rooms with their own small puzzle and a story payoff — e.g. Okafor's office and family letters (Ch 2), Lind's quarantine ward (Ch 3), Haddad's numbers-station archive (Ch 7), the Directorate liaison's office (Ch 8).
2. **Second objective chain in larger chapters** (Ch 5, 7, 8, 11): two independent power/route problems the player can do in either order while the Listener adapts.
3. **Echo investigations**: multi-part 89.1 mysteries spanning chapters (find all of Pell's records-room calls to reconstruct what happened in the archive at 02:47).
4. **Encounter design pass**: 2–3 authored Listener set-pieces per chapter using forecast, mimicry and ambush.
5. **New Game+ "Second Signal"**: the Listener starts with the learned habits of the first run; new 101.3 forecasts reveal a few alternative scenes.

## Roadmap
| Next | Work |
|---|---|
| 1 | Windows launch test on real hardware; GPU profiling; fix anything found |
| 2 | Human playtest round 1; tune AI hearing radii and puzzle signposting |
| 3 | Content expansion items 1–2 |
| 4 | Art pass (creature first, then kits), VO recording, score |
| 5 | Steamworks, store page, trailer recapture, beta branch |
| 6 | Playtest rounds 2–3, polish, release candidate |
