# DEAD FREQUENCY — Testing Plan & Results

## Automated suites (all run in a real Godot 3.5.2 instance under Xvfb)
Run with `tools/test.sh <suite>`. A suite fails if any check fails **or** the engine logs any `SCRIPT ERROR` / `ERROR` line.

| Suite | What it proves | Result (latest run) |
|---|---|---|
| `validate` | Every chapter/ending: map rows equal width, start present, every map char has a legend and vice-versa, every event command known, every marker/sound referenced exists; exact credit names and order | 253 checks, 0 failures |
| `flags` | Every story flag that is read anywhere is set somewhere; ending flags settable; 7 Evelyn tapes exist | 56 / 0 |
| `layout` | No prop or blocking object cuts off any floor area (BFS with props as walls) | 18 / 0 |
| `save` | Save → reset → load round-trip; version handling; ending logic for every flag combination; checkpoint respawn position; power state restore | 12 / 0 |
| `systems` | Walk/sprint speeds, stamina drain and winded state, crouch, lean, flashlight toggle/drain/auto-reload, radio toggle, 0.1 MHz tuning, battery drain, 107.9 reveal, 94.6 band, directional transmission reception, lockers, doors (powered, key-locked), damage, medkit, pause menu, settings apply, journal | 28 / 0 |
| `ai` | Dormant ignores out-of-range noise; loud noise → investigate → search; doesn't home in on a silent player; sight escalates to hunt; loses a hidden/silent player; catch wounds then retreats; habitual lockers searched more; fresh lockers mostly safe; learning bounded | 12 / 0 |
| `flow` | Opening cinematic → menu; menu items and lock states; New Game writes a save; pause → main menu; Continue; chapter select unlocks; death → game over → reload checkpoint | 13 / 0 |
| `endings` | Each flag combination produces the right ending (A, B, C×2, D), reaches the credits, credits contain every contributor and the final card, credits finish with return-to-menu, completion saved | 26 / 0 |
| `play` | **Full campaign**: plays chapters 1→13 on the critical path (teleporting between steps but verifying A* reachability of every step), receives every required transmission, solves every puzzle, makes the choices, reaches ending D and the credits; includes every optional wing | 188 / 0 (all 7 tapes, ending D) |
| `introtime` | Opening cinematic + title reveal real-time length | 135 s (target 120–180 s) |
| `gallery` | Renders 18 reference images (`docs/screenshots/`) for visual QA | images reviewed |

What the automated tests do **not** prove: that it is fun or frightening, that difficulty is right for humans, frame-rate on real GPUs, that the Windows `.exe` runs on Windows (exported, not launched), audio mix quality, or that a human can always physically push a crate along the intended route.

## Manual QA checklist (per build)
- [ ] Fresh install on Windows 10 and 11: launch, opening plays, title reveal, menu.
- [ ] Keyboard+mouse and Xbox controller full session; rebinding not required to play.
- [ ] Each chapter start-to-end by a human at least once; note deaths, confusion, softlocks.
- [ ] Every keypad code accepted only when correct; wrong codes make noise.
- [ ] Every transmission receivable with antenna facing; none receivable through walls from implausible distances.
- [ ] Listener: never attacks while you are hidden and unseen; chase cap works; no stuck-in-wall cases.
- [ ] Quit to menu during dialogue and during a chase → no errors, Continue resumes at last checkpoint.
- [ ] Settings persist across restarts; subtitles off/on and sizes; reduce flashing removes title flicker and lightning.
- [ ] All four endings reachable from Continue at the final console; credits skippable; return to menu.
- [ ] 1080p/1440p/ultrawide UI layout; fullscreen toggle; V-Sync.
- [ ] Performance: 60 fps at 1080p High on a GTX 1060-class GPU; Low preset on integrated graphics.

## Human playtest plan
Three rounds of 5 players (genre fans / non-fans / streamers): record session length per chapter, deaths, where they got lost, which band they used, scare reactions, ending reached and whether they understood why. Use the data to tune AI hearing radii, puzzle signposting and to plan the content expansion needed for the 10–15 h target.

## Bug tracking
GitHub Issues with labels `bug`, `softlock`, `ai`, `audio`, `ui`, `story-continuity`, `perf`, severity `S1`–`S4`; every fixed bug that a test could have caught gets a regression check in `tests/test.gd`.

## Known issues
| ID | Issue | Severity | Status |
|---|---|---|---|
| K1 | Campaign length estimate ≈ 4.5–7 h, below 10–15 h target | S1 (scope) | in progress — expansion passes in tracker |
| K2 | No recorded voice-over; procedural voice texture + subtitles only | S2 | open |
| K3 | Stand-in procedural art; not photoreal | S2 | open |
| K4 | Windows `.exe` exported but not yet launched on Windows hardware | S2 | open |
| K5 | Steamworks not integrated (achievements local only) | S3 | open |
