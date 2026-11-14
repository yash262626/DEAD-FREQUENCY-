# DEAD FREQUENCY — Bug Reports

Every defect found during development, with severity, how it showed up, the fix, and the test that now guards it. Severity: **S1** blocks progress/crash/data loss · **S2** major function broken · **S3** minor/visual · **S4** cosmetic.

| ID | Sev | Summary | Reproduction | Resolution | Regression guard |
|---|---|---|---|---|---|
| B-001 | S1 | The Listener froze forever in HUNT | Get hunted, break line of sight: it never searches | GDScript 3 runs `b` unconditionally in `if c: a; b`. All such one-liners expanded (`tools/fix_oneliners.py`) | `ai` — "loses a player it can no longer see" |
| B-002 | S1 | Listener script failed to load | Any chapter with the Listener | Method `_set` collided with `Object._set`; renamed | every suite fails on SCRIPT ERROR |
| B-003 | S2 | Walls invisible / black from inside rooms | Load any level | Triangle winding now derived from the face normal | `gallery` visual review |
| B-004 | S2 | Crash adding a tape to the journal | Play Evelyn's first tape (Ch 3) | Transcripts include only speaker lines, not camera/command events | `play` Ch 3 |
| B-005 | S1 | Props sealed off floor areas (possible softlocks) — Ch 2, 4, 5 (×3), 10, 11 | Walk the affected rooms | Props moved; new BFS layout test | `layout` |
| B-006 | S3 | Chapter card: red block, clipped title | Start Ch 2 | Container layout + automatic title sizing | `gallery` |
| B-007 | S3 | Subtitles overlapped the receiver face | Dialogue with the radio on | Subtitle band narrows while the receiver is visible | `gallery` |
| B-008 | S3 | Containment glass opaque white; Ch 12–13 nearly black | Visual review | Glass material, extra lights, palette ambient | `gallery` |
| B-009 | S2 | Esc / Tab / F immediately re-opened the menu or note they had just closed | Open the pause menu, press Esc | Same-frame close guard (`closed_this_frame`) | manual + `systems` |
| B-010 | S2 | Engine errors when a level was torn down during dialogue | Quit to menu mid-transmission | Levels are detached at once and freed later, so scripts exit cleanly | `endings`, `flow` (no ERROR lines) |
| B-011 | S1 | Automated tests overwrote the player's save and profile | Run any test on a machine that has a save | Tests use separate files and never touch user data | all suites |
| B-012 | S2 | Ch 1 warning on 101.3 never triggered | Pick up the receiver, walk the corridor | Condition referenced a non-existent entity id; the `flags` test now rejects unknown references | `flags` |
| B-013 | S3 | Story continuity: Okafor in two places during Run 19 | Read Ch 6 tape vs prologue | Tape line rewritten | `docs/02_STORY_BIBLE.md` |
| B-014 | S2 | Division by zero in the exposure lamp on 88.0 | Tune 88.0 in New Game+ | Silent band excluded from the exposure calculation | `ngplus` |
| B-015 | S1 | A damaged save was silently ignored: Continue did nothing, "reload checkpoint" started a new game | Corrupt `save.json`, press Continue | Atomic save (temp file → verify → swap), previous save kept as `.bak` and used as fallback, clear on-screen messages, schema checks | `save` (3 corruption cases) |
| B-016 | S3 | No window resolution option | Settings | 1280×720 … 2560×1440 windowed presets | `systems` (settings apply) |
| B-017 | S3 | Scripted transmissions switched the player's receiver off / retuned it | Have the radio on when a story transmission plays | The receiver is handed back exactly as the player left it | `systems` |
| B-018 | S2 | Resolution setting resized the test window before test mode was flagged (inputs dropped) | Run `systems` | Test mode is detected before settings are applied | `systems` |
| B-019 | S2 | Ch 11 voiceprint reel stand sealed a floor cell | Walk Stack A | Stand moved into the aisle | `layout` |
| B-020 | S3 | Test runner: `continue` inside `match` falls through in GDScript 3 | Walkthrough steps "choice"/"crate" | Rewritten with if/elif | `play` |
| B-021 | S3 | Settings: the controls footer overlapped the last settings rows at 720p | Open Settings at 1280×720 | Controls moved into a three-column table inside the scrolling list | `gallery` (98_settings.png) |
| B-022 | S2 | Fresh checkout: textures not imported, so tests and CI logged engine errors; `godot --editor --quit` exits before importing | Clone, run any suite | `tools/import_assets.sh` runs the editor until every source has its cache entry; CI step added | CI `test` job |
| B-023 | S2 | Alt-tabbing during play left the game running — the Listener could catch an absent player | Alt-tab near the Listener | Focus loss opens the pause menu (not during cinematics) | `flow` (2 checks) |
| B-024 | S2 | Release builds did not carry the licence texts of Godot's bundled third-party libraries (FreeType, etc.) | Inspect the build folder | `licenses/` generated from the engine's copyright data and shipped by `package_release.sh`; FreeType credit line in notices and README | `licenses` utility |
| B-025 | S3 | The smoke test would have written its run into the player's play-time log | Run `--smoketest` | Smoke test uses its own log file | smoke test |

## Open issues (not defects in code, but release blockers)
| ID | Sev | Issue | Status |
|---|---|---|---|
| K1 | S1 | Campaign length unmeasured (model 3.9–10.1 h main path, 5.4–14.0 h with optional content); no human playtests yet | play-time log + report tool ready; awaiting playtesters |
| K2 | S2 | No recorded voice acting | recording package prepared; awaiting cast |
| K3 | S2 | Stylised real-time 3D with CC0 PBR materials; not photoreal | by design for this engine; see 19 |
| K4 | S2 | Windows build passed the smoke test under Wine only; never launched on Windows hardware | checklist in 13_TESTING_PLAN.md §9.2 |
| K5 | S3 | Steamworks not integrated | needs Steam App ID + GodotSteam build |
| K6 | S3 | Exe has no embedded icon/version resource and is not code-signed | rcedit + certificate at release time |
| K7 | S2 | GPU performance unmeasured | needs real hardware |
