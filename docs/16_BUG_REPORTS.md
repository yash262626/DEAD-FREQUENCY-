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
| B-026 | S2 | Godot's shader translator turned `a - (-b)` into `a--b` (decrement) and the light-shaft shader failed to compile | Build the slice | Rewritten without a double minus | `slice` (no engine errors) |
| B-027 | S2 | Blender's Cycles bakes came out black: this Blender build has no OpenImageDenoise and the bake silently failed while denoising was on | Bake the creature maps | Denoising disabled for bakes | creature maps checked |
| B-028 | S3 | `import_assets.sh` compared counts, so new or changed files could stay un-imported (stale models) | Add a model, re-run | Checks each source's cache entry and content hash | manual |
| B-029 | S2 | Hiding under a desk showed the locker-slat overlay | Hide in the slice | Low hiding places have no slats | `sliceshots` s08 |
| B-030 | S3 | Preview cameras inside the art scene could take over the player's view | Load the slice | Preview cameras are stripped when a level loads its art | `slice` |
| B-031 | S3 | GDScript 3 one-line `if x: a; continue` in new dev scripts skipped every iteration | Dev tools | Rewritten on separate lines | dev tools |
| B-032 | S2 | Godot 3.5's built-in texture downscaling (`texture_set_shrink_all_x2_on_set_data`) crashes the engine on VRAM-compressed textures | Load the creature's 4K skin with it enabled | Not used: *Half* texture quality rebuilds each texture from its own mip chain (`scripts/texq.gd`) | `texq` |
| B-033 | S3 | `level.gd` stripped preview cameras with a one-line `if cams: a; b` — the second call ran even with no cameras (crash for art scenes without a `Cams` node) | Load an art scene without cameras | Split onto separate lines | `slice` |
| B-034 | S3 | `tools/test.sh` took `DF_RES=…` arguments for the game but not for its own window size, so "4K" captures came out at 256×144 | `tools/test.sh sliceshots DF_RES=3840x2160` | VAR=VAL arguments are exported to the script too; `DF_SCREEN` sets the virtual screen | `sliceshots` at 3840×2160 |
| B-035 | S3 | A test edit meant for the slice shots also marked the radio transmissions done in `systems`, so its reception check failed | Run `systems` | Restored the original line | `systems` |
| B-036 | S2 | The Listener v2's `crawl` animation put its legs in the air: pitching the hips forward also swings the thighs back, and the thighs were rotated further back instead of forward | Spawn the Listener in AMBUSH (crawl) or `sliceshots` s13 | Crawl redesigned with a forward-kinematics check of the rig (knees and planted hands on the floor through the cycle), re-keyed on the saved rig without rebuilding the meshes (`listener_v2.py … anim`); meshes verified unchanged | `sliceshots` s13, crawl turntable |
| B-037 | S3 | `systems` "dial tunes in 0.1 MHz steps" failed on a heavily loaded machine: the test held the key across a slow frame, so the 0.35 s auto-repeat fired | Run `systems` while the machine renders something else | The test's tap now lasts exactly one rendered frame | `systems` |
| B-038 | S2 | Parts of the Listener (skull nodules, 942 vertices) floated in the air when it hunched: bone-heat weighting had left those detached islands unweighted, so they stayed at their rest position | Any pose that moves the head (the v3 stalking idle) | Unweighted vertices are given to their nearest bone after bone heat | turntable, `sliceshots` |
| B-039 | S3 | The creature's skin scattering bled onto the floor behind it in rectangular blocks | Pale skin in front of a lit floor | Depth-aware subsurface scattering (`follow_surface`, high quality) | turntable |
| B-040 | S3 | Re-packing the creature textures also rewrote the Godot 4 benchmark's copies (the files were hardlinks) | Run `tools/pack_creature_maps.py` | Benchmark copies restored from Git as independent files; the pack tool writes new files only into `game/` | `git status` |

## Open issues (not defects in code, but release blockers)
| ID | Sev | Issue | Status |
|---|---|---|---|
| K1 | S1 | Campaign length unmeasured (model 3.9–10.1 h main path, 5.4–14.0 h with optional content); no human playtests yet | play-time log + report tool ready; awaiting playtesters |
| K2 | S2 | No recorded voice acting | recording package prepared; awaiting cast |
| K3 | S2 | Campaign chapters still use the older procedural art; only the vertical slice is at the new standard; nothing is photoreal | rebuild awaiting approval of the slice and the engine path (docs/21, 22) |
| K4 | S2 | Windows build passed the smoke test under Wine only; never launched on Windows hardware | checklist in 13_TESTING_PLAN.md §9.2 |
| K5 | S3 | Steamworks not integrated | needs Steam App ID + GodotSteam build |
| K6 | S3 | Exe has no embedded icon/version resource and is not code-signed | rcedit + certificate at release time |
| K7 | S2 | GPU performance unmeasured | needs real hardware; `DeadFrequency.exe --benchmark [--4k]` writes the measurements |
| K8 | S3 | The Listener's membrane has a single level of detail (85,908 triangles at every distance) | membrane LODs to add in `tools/blender/listener_v2.py` |
