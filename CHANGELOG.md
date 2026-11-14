# Changelog

## 0.9.x — production upgrade (in progress)

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
