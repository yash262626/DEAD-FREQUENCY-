# Changelog

## 0.11 — 4K graphics pass on the vertical slice (awaiting approval)
- **The Listener v2**, rebuilt toward the owner's reference sheet (original design): 2.27 m emaciated, asymmetric body with an uneven ribcage, long four-joint clawed fingers, translucent skin; a pleated, veined acoustic membrane head with slits, pores and cartilage rods; 4K skin maps, 2K membrane, 1K claws; subsurface scattering, transmission and a wet clearcoat; 78-bone rig; idle, listen, walk, run, search, crawl and attack animations chosen by the AI state; three body LODs switched by distance.
- **First person:** worn leather gloves; the HX-7 shows a live seven-segment display (frequency, band, signal bars) and its tuning knob turns as you tune; the torch hand clicks when the light toggles.
- **Environment:** red emergency lamps along the corridor, a wet-floor shader (world-space puddles and streaks: darker, glossier, flatter), leak, rust, grime and creature-smear decals, 4K Poly Haven surfaces for the corridor walls and floor.
- **Graphics settings:** presets Low, Medium, High, Ultra and Cinematic; 3840 × 2160 window resolution; 3D render scale 50–150 % (the 3D world renders in its own viewport); texture quality Full/Half; shadow quality; reflections; ambient occlusion; anti-aliasing (FXAA, MSAA 2×/4×/8×); view distance; V-Sync; frame-rate limit.
- **Benchmark mode:** `--benchmark` (and `--benchmark --4k`) flies the slice per preset and writes average fps, 1 % low and worst frame to `benchmark.txt`, for measuring on real GPUs.
- **Godot 4 isolated visual benchmark** (`benchmark_godot4/`, docs/22): the slice rebuilt from the same assets in Godot 4.7 with SDFGI, shadowed volumetric fog, decals, TAA and skin SSS; side-by-side evidence and an engine evaluation. No migration started.
- **Evidence:** native 3840 × 2160 in-game captures (`docs/screenshots/slice4k/`), a silent 720p gameplay recording of the slice (`docs/media/slice_gameplay.mp4`, `tools/record_slice.sh`), asset and texture specifications (docs/23).
- Tests: new `texq` suite; `sliceshots` gains creature close-ups (membrane, crawl, searching while you hide) and native-4K options; `slicerec` recording controller.

## 0.10 — vertical slice (visual target, awaiting approval)
- Sublevel 3 service corridor and communications room rebuilt as an authored scene: bevelled architecture, pipes, trays, doors, raised floor, suspended ceiling, equipment racks, operator console with CRTs, main receiver, signage, chart, clock (02:43), papers, cables.
- 27 CC0 Poly Haven models and 14 2K Poly Haven surfaces (fetched by `tools/fetch_polyhaven.py`, listed in THIRD_PARTY_NOTICES).
- Baked global illumination (Godot CPU lightmapper via `addons/df_tools`), reflection probes, flickering and rotating lights, light shafts with depth fade, puddles, steam, drips, colour grade.
- New first-person models: gloved hands, knurled torch (hot spot + spill + beam), HX-7 receiver with a live frequency/band/signal display (the HUD receiver panel is hidden in the slice).
- New Listener: original sculpted creature with a membrane "ear", baked skin maps, 42-bone rig, idle/walk/run/listen/attack animations driven by the existing AI.
- Playable: menu entry and `--slice`; scripted encounter (hide under the desk); new `slice` test suite (13 checks) and `sliceshots` / `sliceperf` utilities.
- Docs: 21 (visual audit, engine decision, migration plan, evidence).

## 0.9.x — production upgrade

### Windows release work
- Built-in self-check: `DeadFrequency.exe --smoketest` (15 checks, log + screenshots, exit code).
- The exported Windows exe was run under Wine 9.0 (virtual display, software OpenGL) and passed all 15 checks. Not yet run on real Windows hardware.
- Clean release package (`tools/package_release.sh`): exe, player README, credits generated from the in-game list, privacy, third-party notices, Godot and font licence texts, SHA-256 checksums.
- CI: imports textures on a fresh checkout, runs every suite including New Game+, exports, runs the Wine smoke test and uploads the release zip (defined, not yet run).
- Local play-time log (`playtest.json`: unpaused time, deaths, completion per chapter) and `tools/playtest_report.py`, so campaign length can be measured instead of estimated.
- The pause menu opens when the window loses focus during play; it shows time played.

### Presentation
- Second reveal rebuilt as a CRT terminal (scanlines, glow, live carrier trace; STATUS: ALREADY INSIDE turns red and glitches before the title). Text unchanged.
- SIGNAL LOST screen with red static; settings show a readable controls table (the old footer overlapped the list); compact pause menu.
- Visual upgrade: 20 CC0 PBR material sets from ambientCG (triplanar walls, floors, ceilings, props), light fixtures with volumetric shafts, dust, sparks, steam, drips, water shader, rock/snow/gravel exterior, new Listener model with animated limbs and sound-tracking dish, better human figures, first-person hands with torch and receiver.
- Audio upgrade: adaptive music (tension and chase layers, silence when it is close), footsteps per surface, the Listener's rasp and dish snaps, fear breathing; recorded voice-over is picked up automatically by file name (recording package in `docs/vo/`: 640 lines, 24 characters).

### Gameplay
- New Game+ "Second Signal": the Listener remembers the previous run's habits at half strength (lockers, radio use, lures, sprint escapes), 88.0 MHz transmissions, the Kessler thread, encounter variants, an achievement.
- Two-part objectives in Ch 8 (two-person lockdown release held with a crate; Directorate Annex relays) and Ch 11 (deep lift: keycard + Evelyn's voiceprint reel).
- Atomic saves with `.bak` fallback and clear messages; resolution setting; the receiver returns to the player's own frequency after scripted transmissions.
- Content: 640 spoken, subtitled lines (7,673 words) across 24 characters, plus documents and tapes.

## 0.9.x — expansion passes
- **Pass 1 — optional wings (Ch 1–12).** Each chapter gains a side area with its own puzzle and story payoff: lost property (the count is 42, not 41), Okafor's office and unsent letter, Brandt's quarantine (tape + hide set-piece), the residents' radio club (a 1998 log of a caller named Arlen), Ruiz's workshop, the Directorate's "Subject D" memo, Rami Haddad's last broadcast on 104.4 ("Hale is on every channel at once"), the 1:20 Aperture prototype, the 02:30 tram manifest and Cross's tape, the containment roll call (badge-locked; the 23 appear on 107.9), Box 19, and the Run 19 operator log.
- **Pass 2 — Listener set-pieces** on key pickups and loud puzzle solutions (Ch 1, 2, 3, 4, 6, 7, 11).
- **Pass 3 — second objective chains**: Ch 5 tunnel door needs main power *and* primed hydraulics; Ch 9 traction needs the switch order *and* a traction fuse. Either order.
- **Pass 4 — The Forty-Second.** Jonah Pell's 1998 calls about a stranger in an orange jacket (Ch 2, 3, 7, 11); hearing all four unlocks a fifth in the Archive and a new achievement.
- Keypad codes on interactable objects (drawers, cabinets).
- Content at the end of the passes: 538 subtitled lines.

## 0.9.0 — complete campaign build
- Opening cinematic (2:15) and title reveal; 13 chapters; second title reveal; chapter cards; four endings; end credits.
- Systems: first-person controller, flashlight, inventory, health, interaction, doors/keys/codes, physics puzzle, ordered-switch and rotation puzzles, hiding, throwing, receiver with four bands + hidden carriers, journal, objectives, subtitles, saves/checkpoints, menus, settings, gamepad.
- The Listener: eight-state AI with hearing, short-range sight, bounded learning, mimicry, cloaked and blind variants.
- Procedural audio, procedural art, Windows/Linux export presets, automated test suite, 15 production documents.
