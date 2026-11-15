# DEAD FREQUENCY — Testing Plan & Results

Latest full run: **2026-11-15**, build 0.12 (vertical slice, second reference pass), Godot 3.5.2 on Ubuntu 24.04 under Xvfb with Mesa llvmpipe (software OpenGL, no GPU): 12 suites, 798 checks, 0 failures.

## 1. Automated suites (each runs in a real Godot 3.5.2 instance)
Run with `tools/test.sh <suite>`. A suite fails if any check fails **or** the engine logs any `SCRIPT ERROR` / `ERROR` line. CI runs every suite except `vo` (which needs a test recording).

| Suite | What it proves | Latest result |
|---|---|---|
| `validate` | Every chapter/ending: map rows equal width, start present, every map char has a legend and vice-versa, every event command known, every marker/sound/group referenced exists; exact credit names and order | 257 checks, 0 failures |
| `flags` | Every story flag that is read anywhere is set somewhere; ending flags settable; 7 Evelyn tapes exist | 161 / 0 |
| `layout` | No prop or blocking object cuts off any floor area (BFS with props as walls) | 18 / 0 |
| `save` | Save → reset → load round-trip; damaged save falls back to `.bak` with a message; two damaged saves refused cleanly; ending logic for every flag combination; checkpoint respawn; power state restore; play-time log (time, deaths, completion, ending) survives save/load | 22 / 0 |
| `systems` | Walk/sprint speeds, stamina, crouch, lean, flashlight toggle/drain/auto-reload, radio toggle, 0.1 MHz tuning, battery drain, 107.9 reveal, 94.6 band, directional reception, receiver restored after scripted transmissions, lockers, doors, damage, medkit, pause, settings, journal | 29 / 0 |
| `ai` | Dormant ignores out-of-range noise; investigate → search; no homing on a silent player; sight → hunt; loses a hidden player; catch wounds then retreats; habitual lockers searched more; learning bounded | 12 / 0 |
| `flow` | Opening → menu; menu items and lock states; New Game writes a save; focus loss opens the pause menu (not during cinematics); pause → main menu; Continue; chapter select; death → game over → reload | 15 / 0 |
| `endings` | Each flag combination produces the right ending (A, B, C×2, D), reaches the credits, credits contain every contributor and the final card, return to menu, completion saved | 26 / 0 |
| `ngplus` | New Game+ unlocks after an ending and appears in the menu; habits carried at half strength; NG+-only content (dispatch slip, 88.0 transmissions) exists only in NG+ and 88.0 makes no radio noise; Listener adaptations (faster but still slower than a sprint, chase cap, lure-wise, learning cap, remembered lockers checked more but never certainly); NG+ reaches an ending and awards Second Signal | 15 / 0 |
| `play` | **Full campaign**: chapters 1→13 on the critical path (teleporting between steps but verifying A* reachability of every step), every required transmission, every puzzle, the choices, all optional wings and Pell's calls, ending D and the credits | 225 / 0 (all 7 tapes, ending D) |
| `slice` | Vertical slice: data valid, authored art scene and its environment loaded, baked lightmap present, modelled hands/torch/receiver with live display and tuning knob, no campaign save written, 101.3 forecast received and shown on the receiver display, main receiver starts the encounter, cinematic depth of field during it and released after, the new Listener arrives, beacon on, hiding under the desk lowers the view, creature animation playing, hidden player not found, slice ends and returns to the menu | 15 / 0 |
| `texq` | Texture quality *Half*: every large texture in the slice is rebuilt at half resolution from its own mip chain, texture memory drops, the Listener's 4K skin loads at 2K | 3 / 0 |
| `vo` | A recording named by `vo_id` is played instead of the placeholder voice and holds the subtitle for its length; unrecorded lines fall back | 4 / 0 with a fixture recording (fixture not committed) |

## 2. Utilities
| Mode | Output |
|---|---|
| `introtime` | Opening cinematic + title reveal real-time length: 135 s (target 120–180 s) |
| `gallery` | Reference images in `docs/screenshots/` (chapters, menu, title, chapter card, second reveal, pause, settings, game over, credits) for visual QA |
| `perf` | Level build time and fps per quality preset (12_TECHNICAL_DOCUMENTATION.md, Performance) |
| `export` | Story data as JSON for `tools/gen_docs.py` and `tools/time_budget.py` |
| `licenses` | `licenses/GODOT_ENGINE_LICENSE.txt` from the engine's own copyright data |
| `sliceshots` | In-game evidence images of the vertical slice, 14 views (`DF_RES`/`DF_SCREEN`=3840x2160 for native 4K → `docs/screenshots/slice4k/`; `DF_PRESET` 0–4; `DF_ONLY`; `DF_SETTLE`) |
| `slicerec` | Scripted gameplay recording of the slice (real movement, radio, encounter and AI); `tools/record_slice.sh` runs it at a fixed 30 fps game time and encodes `docs/media/slice_gameplay.mp4` |
| `sliceperf` | Frame cost of the slice per graphics preset (fps, vertices, draw calls, video memory) |

## 3. Built-in smoke test (`--smoketest`)
Shipped inside every build. `DeadFrequency.exe --smoketest` checks: audio bank built (39 sounds) · main menu shown · new game loads chapter 1 · flashlight on · radio on and draining · rendering fps measured · save/load round-trip · chapters 5 and 12 load and run · ending A plays through to the credits · five screenshots written. It writes `smoketest.log` and `smoke_*.png` to the user data folder and exits with code 0 only if all 15 checks pass. Testers attach the log to bug reports.

## 4. What the automated tests do not prove
That it is fun or frightening; that difficulty suits humans; frame rate on real GPUs; behaviour on real Windows PCs (see §9); audio mix quality on real speakers/headphones; that a human can always physically push a crate along the intended route; campaign length (see §6).

## 5. Manual QA checklist (per build)
- [ ] Fresh unzip on Windows 10 and 11: launch, opening plays, title reveal, menu (full list in §9).
- [ ] Keyboard+mouse and Xbox controller full session; every action reachable on both.
- [ ] Each chapter start-to-end by a human at least once; note deaths, confusion, softlocks.
- [ ] Every keypad code accepted only when correct; wrong codes make noise.
- [ ] Every transmission receivable with antenna facing; none receivable through walls from implausible distances.
- [ ] Listener: never attacks while you are hidden and unseen; chase cap works; no stuck-in-wall cases.
- [ ] Quit to menu during dialogue and during a chase → no errors, Continue resumes at last checkpoint.
- [ ] Alt-tab during play opens the pause menu; alt-tab during a cinematic does not break it.
- [ ] Settings persist across restarts; subtitles off/on and sizes; reduce flashing removes title flicker, lightning, the second-reveal glitch.
- [ ] All four endings reachable from Continue at the final console; credits skippable; return to menu; New Game+ appears after an ending.
- [ ] 1080p/1440p/ultrawide UI layout; fullscreen toggle; V-Sync.
- [ ] Performance: 60 fps at 1080p High on a GTX 1060-class GPU; Low preset playable on integrated graphics.

## 6. Human playtest plan and the length claim
Three rounds of at least 5 players each (genre fans / non-fans / streamers). Each tester plays from NEW GAME on their own PC and sends `%APPDATA%\Godot\app_userdata\DEAD FREQUENCY\playtest.json` (written by the game: seconds of unpaused play, deaths and completion per chapter) plus `smoketest.log`. `python3 tools/playtest_report.py playtests/*.json` produces per-chapter medians, ranges, deaths and complete-campaign totals.

The campaign length may be quoted publicly only when at least 5 first-time players have completed the campaign and the median complete-run time falls in the quoted range. Until then the only number is the model in 17_TIME_BUDGET.md (main path 3.9–10.1 h, with optional content 5.4–14.0 h), which is labelled as a model. Also record: where players got lost, which band they used, scare reactions, which ending they reached and whether they understood why. Use the data to tune hearing radii, puzzle signposting and the expansion plan.

## 7. Bug tracking
Bugs found during development are logged in 16_BUG_REPORTS.md. For the public test phase: GitHub Issues with labels `bug`, `softlock`, `ai`, `audio`, `ui`, `story-continuity`, `perf`, `windows`, severity `S1`–`S4`; every fixed bug that a test could have caught gets a regression check in `tests/test.gd`.

## 8. Known issues
| ID | Issue | Severity | Status |
|---|---|---|---|
| K1 | Campaign length not measured; model says 3.9–10.1 h main path, 5.4–14.0 h with optional content, against a 10–15 h target | S1 (scope) | open — needs playtests (§6) |
| K2 | No recorded voice-over; processed radio-voice placeholder + full subtitles; recording package ready in `docs/vo/` | S2 | open — needs actors |
| K3 | Stylised real-time 3D with CC0 PBR materials; not photoreal | S2 | open by design (19_ENGINE_MIGRATION_ASSESSMENT.md) |
| K4 | Windows build verified under Wine only, not on real Windows hardware | S2 | open — §9 |
| K5 | Steamworks not integrated (achievements local only) | S3 | open — needs Steam App ID and approval |
| K6 | Exe has no embedded icon/version resource; not code-signed (SmartScreen warning) | S3 | open — release task |
| K7 | GPU performance unmeasured (only software rendering measured) | S2 | open — §9 |

## 9. Windows compatibility

### 9.1 What has been verified
On 2026-11-14 the exported `DeadFrequency.exe` (Godot 3.5.2 official Windows template, embedded data) was run with `--smoketest` under **Wine 9.0** on Ubuntu 24.04, Xvfb virtual display, Mesa llvmpipe software OpenGL 4.5:

```
DEAD FREQUENCY smoke test — Windows — 3.5.2-stable (official) — video adapter: llvmpipe (LLVM 20.1.2, 256 bits)
PASS  procedural audio bank built (39 sounds)
PASS  main menu shown
PASS  screenshot user://smoke_menu.png
PASS  new game loads chapter 1
PASS  flashlight on
PASS  radio on and draining
PASS  screenshot user://smoke_chapter01.png
PASS  rendering: 1.7 fps average over 5 s at (1280, 698), preset 2
PASS  save and load round-trip
PASS  chapter 5 loads and runs
PASS  screenshot user://smoke_chapter05.png
PASS  chapter 12 loads and runs
PASS  screenshot user://smoke_chapter12.png
PASS  ending A plays through to the credits
PASS  screenshot user://smoke_credits.png
RESULT: 0 failures, 203.4 s
```
Re-run on the final export of this build (code of commit 3ad9ce9, exe SHA-256 starting `3673cfd972aba939`): again 15/15 passed, 200.1 s, 1.6 fps on High. The release zip `build/DeadFrequency-0.9.0-Windows-x64.zip` (48 MB) was packaged from that exe.

The screenshots show textured, lit scenes, the HUD and the radio as on Linux. Wine reported no audio device (`WASAPI: init_render_device error`), as expected in a container without sound hardware; the game continued silently. Save files were written to `C:\users\<user>\AppData\Roaming\Godot\app_userdata\DEAD FREQUENCY\`.

This proves the Windows executable starts, renders through WGL/OpenGL, runs its scripts, reads its embedded data and writes saves through the Windows file APIs as implemented by Wine. **It is not verification on Windows**: real GPU drivers, Windows audio devices, DPI scaling, Defender/SmartScreen and real performance are untested.

### 9.2 Real-Windows test checklist (to be run by a human before any release)
Record for every machine: Windows edition and build (`winver`), CPU, GPU and driver version, RAM, display resolution and scaling, audio device.

Machines: Windows 10 22H2 and Windows 11 23H2/24H2; at least one each of NVIDIA, AMD and Intel integrated graphics; one laptop with hybrid graphics.

- [ ] Download the release zip, verify `SHA256SUMS.txt` (`certutil -hashfile DeadFrequency.exe SHA256`), unzip to a path with spaces and to a path with non-ASCII characters.
- [ ] SmartScreen: note the exact prompt; "Run anyway" works. Windows Defender full scan of the folder: no detections.
- [ ] `DeadFrequency.exe --smoketest` passes (attach `smoketest.log`); note the fps line.
- [ ] Normal launch: opening cinematic with sound, title reveal, menu; mouse cursor and focus correct.
- [ ] Display: windowed 1280×720 → each resolution option; fullscreen toggle; 125/150/200 % scaling; ultrawide 21:9; second monitor; V-Sync on/off; no tearing or black frames.
- [ ] Input: keyboard+mouse; Xbox controller wired and Bluetooth, hot-plugged mid-game; DualSense via Steam Input later.
- [ ] Audio: headphones and speakers; unplug/replug the device mid-game; Bluetooth headset; volume sliders; the Listener is locatable by ear.
- [ ] Alt-tab, Win key, minimise/restore, sleep/resume, lock screen: the game pauses and resumes without a black screen or lost audio.
- [ ] Saves: New Game, quit, relaunch, Continue; saves in `%APPDATA%\Godot\app_userdata\DEAD FREQUENCY\`; with OneDrive-redirected folders; with Controlled Folder Access on.
- [ ] A user account whose name contains spaces or non-ASCII characters.
- [ ] Play chapter 1 to the second reveal, one chase in chapter 5, the ring in chapter 12, and one ending.
- [ ] Performance with `tools/test.sh perf`-equivalent observations: fps on Low/Medium/High/Ultra at 1080p; target 60 fps at 1080p High on a GTX 1060-class GPU, 30+ fps on Low on Intel UHD 620.
- [ ] Exit from the menu and with Alt-F4: no hang, no crash dialog; `playtest.json` updated.
- [ ] Offline (network disabled): identical behaviour.
