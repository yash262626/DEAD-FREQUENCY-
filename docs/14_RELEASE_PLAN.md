# DEAD FREQUENCY — Release Plan (Steam, Windows PC)

No sales, awards or reception claims are made anywhere in this plan or the store copy.

## Store copy

**Short description (≤ 300 chars)**
> A research station in the mountains went silent in 1998. Your job is to fix its radio. Your receiver hears the past, the future and things that hide — and every second it's on, something in the dark hears you.

**About this game**
> **October 17, 1998, 02:43.** HELIX-9, a classified research facility beneath the Varn mountains, drops off every communications network on Earth. Forty-one people vanish.
>
> **Twenty-eight years later,** emergency-communications engineer Daniel Arlen is sent to restore its radio. The site's beacon has been calling for help for three weeks. It asked for him by name.
>
> Inside, every clock says 02:43. His field receiver picks up conversations from 1998, warnings that haven't happened yet — and his own voice, telling him: *whatever happens, do not open the door.*
>
> **THE RECEIVER** — Tune by hand. 89.1 hears the past. 94.6 hears movement. 101.3 hears what's about to happen. 107.9 shows what hides. Every transmission tells something exactly where you are.
>
> **THE LISTENER** — It hunts by sound. It learns where you hide. It speaks in the voices of the people you trust. It cannot make words — only take them.
>
> **THE MYSTERY** — Thirteen chapters through a facility built to listen to time. Tapes, logs, echoes and a lullaby that was never meant to be heard over the air.
>
> **FOUR ENDINGS** — shaped by what you discover, who you believe, and what you do at the Door.
>
> No combat. No microtransactions. Headphones strongly recommended.

**Tags**: Psychological Horror, Horror, Atmospheric, First-Person, Story Rich, Mystery, Stealth, Multiple Endings, Singleplayer, Indie.

## Pricing
Target **₹799–₹999** (premium indie horror). Recommendation: decide after (1) human playtests measure real campaign length and (2) the art and voice passes land. If the campaign remains under ~6 hours at launch, price at the bottom of the band or below; the 10–15 h target supports the top of the band. Regional pricing via Steam's recommended matrix.

## Logo brief
"DEAD FREQUENCY" in a heavy condensed grotesk, all caps, distressed brushed-metal fill with paint chips, faint red/cyan channel split, one horizontal scanline glitch slice. Lock-up variant with a thin oscilloscope trace running through the counters. Must read at 120 px wide on white and black. (The in-game title shader is the reference.)

## Capsule art brief
Main capsule (1232×706) and header (920×430): first-person view down a dark facility corridor; the hand-held receiver in the foreground, dial glowing green at 107.9; at the far end, half in fog, the tall thin silhouette with a dish where its face should be, turned toward the viewer. Logo upper-left. Palette: near-black, sodium amber, one red emergency lamp. No gore. Vertical capsule (748×896): the same silhouette framed in a doorway, the warning line "DO NOT OPEN THE DOOR" small at the bottom. Library hero: the mountain portal in rain at night, red mast beacon.

## Trailer storyboard (≈ 1:30)
| # | Time | Shot | Audio |
|---|---|---|---|
| 1 | 0:00 | Black. | Rain, distant thunder, radio hiss |
| 2 | 0:05 | Card: OCTOBER 17, 1998 — 02:43 AM | A woman's voice: "We built this place to listen." |
| 3 | 0:10 | Aerial push on the mountain portal in rain (prologue) | Low drone |
| 4 | 0:16 | Monitor types: TIMESTAMP 17 OCT 2026 | "That's not a fault. That's a date." |
| 5 | 0:22 | Power dies; red emergency lamps | Bass hit |
| 6 | 0:25 | Black. Whisper: "Can anyone hear me?" — title glitch reveal | Impact |
| 7 | 0:32 | 2026: Daniel's truck at the gate | Dispatch: "It asked for you by name." |
| 8 | 0:38 | Receiver close-up, dial sweeps 89.1 → 107.9; writing appears on a wall | Static clearing into voices |
| 9 | 0:46 | Corridor; the silhouette at the end; lights out | Clicking |
| 10 | 0:52 | Hiding in a locker, the dish passes the vent slits | Breath held |
| 11 | 0:58 | Supervisor's office: it repeats Daniel's words in his voice | "Hello? Are you hurt?" ×2 |
| 12 | 1:05 | Quick cuts: flooded tunnels, turbine hall chase, archive stacks, tram | Rising pulse |
| 13 | 1:15 | Monitor: SIGNAL IDENTIFIED / SUBJECT: DANIEL ARLEN / STATUS: ALREADY INSIDE | Silence |
| 14 | 1:20 | Daniel's own voice: "Whatever happens. Do not open the door." Hard cut to the Door | — |
| 15 | 1:25 | Logo, "Wishlist on Steam", platform line | Final hit |
All shots exist in-engine today (prologue, Ch 1, 2, 5, 6, 9, 11, 13); recapture after the art pass.

## Screenshot plan
Minimum 5, target 8, 1920×1080, no HUD except where the receiver is the subject: (1) corridor + silhouette, (2) receiver UI at 107.9 revealing writing, (3) the supervisor's office through glass, (4) flooded tunnels with the creature on 94.6, (5) research lab tanks, (6) archive stacks, (7) the Door, (8) the title card. Current reference renders: `docs/screenshots/`.

## Achievements (implemented locally with stable IDs → map 1:1 to Steamworks)
| ID | Name |
|---|---|
| first_signal | First Contact — receive your first transmission |
| title2 | Already Inside — reach the communications annex |
| seen | It Has No Face — survive the first sighting |
| door_closed | Good Listener — leave the door in the quarters shut |
| no_hunt | Quiet Feet — finish a chapter without being hunted |
| unseen | 107.9 — reveal ten hidden things |
| hale | The Man at the Door — hear Marcus Hale's last tape |
| all_tapes | Her Voice — find every recording by Dr. Voss |
| end_A / end_B / end_C / end_D | the four endings |
| all_endings | The Signal Never Ends — see all four endings |

## Accessibility (implemented)
Subtitles on by default with speaker names and three sizes · reduce-flashing option (removes title flicker and lightning) · FOV 60–100 · brightness · head-bob off · toggle/hold crouch · invert Y · sensitivity · separate music and effects/voice volumes · hold-to-skip cinematics · no timed button prompts · no colour-only information (bands are named on the receiver). Planned: control remapping UI, audio cue captions for important SFX ("[clicking, close]"), colour-blind check of the receiver UI.

## Controller support
Full Xbox-layout gamepad support through Godot's joypad mapping (works with XInput and most DirectInput pads via SDL mappings). Steam Input: ship an official configuration that maps to the same actions. Steam Deck: target "Playable" (verify text size).

## Graphics presets
Low / Medium / High / Ultra (see 12_TECHNICAL_DOCUMENTATION.md) + fullscreen, V-Sync, brightness, FOV.

## Save compatibility
Saves are versioned JSON (`v`). Patches must only add fields; a migration step is required before any field changes meaning. Profile (settings, endings, achievements, chapter unlocks) is separate from the campaign save. Steam Cloud: sync the `app_userdata/DEAD FREQUENCY/` folder (`save.json`, `profile.json`).

## Build & deployment
1. `tools/test.sh` — all suites green.
2. Export Windows (`game/export_presets.cfg` → "Windows Desktop") — locally or via GitHub Actions (`build` workflow, manual or `v*` tag).
3. Smoke-test the `.exe` on Windows 10 and 11 (fresh user, controller and KB/M).
4. Upload with SteamPipe (`steamcmd +run_app_build app_build.vdf`) to a beta branch; promote after QA.

## Release checklist
- [ ] Measure GPU performance on min-spec and recommended hardware; tune presets.
- [ ] Launch-test the Windows build on real hardware (exported, not yet launched).
- [ ] Human playtests (13_TESTING_PLAN.md) and tuning.
- [ ] Content expansion toward the 10–15 h campaign target (15_DEVELOPMENT_PROGRESS_TRACKER.md).
- [ ] Art pass (characters, creature, environment kits) and voice-over recording.
- [ ] Music score.
- [ ] Integrate Steamworks (achievements, cloud saves, overlay) — GodotSteam for Godot 3.5.
- [ ] Steam page: capsules, trailer, screenshots, store copy, age rating questionnaire (IARC), content descriptors (horror themes, no gore).
- [ ] EULA / privacy (no data collection), third-party notices (Godot MIT licence, Liberation fonts SIL OFL).
- [ ] Release-candidate build on beta branch; final regression run; launch.
