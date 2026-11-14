# DEAD FREQUENCY — Steam Release Package

Prepared for the project owner. **Nothing has been published.** No Steam App ID exists in the project and none has been invented; integration steps below start from the App ID the owner obtains in Steamworks.

## Store text
**Name:** DEAD FREQUENCY
**Short description (≤300 characters):** A research station in the mountains went silent in 1998. Your job is to fix its radio. Your receiver hears the past, the future and things that hide — and every second it's on, something in the dark hears you.

**About this game** — see 14_RELEASE_PLAN.md for the long copy. Add for this build: *Play it again: New Game+ "Second Signal" — the Listener remembers how you played, and a channel it cannot hear tells a story the first run never did.*

## Feature list
- A hand-tuned radio as your only tool: four bands (past, movement, forecast, hidden), secret carriers, a directional antenna, a battery — and every transmission gives away where you are.
- The Listener: a sound-hunting creature that learns where you hide and how loud you are, and speaks in the voices of people you trust. It never cheats: it only knows what it hears and sees.
- Thirteen chapters through a buried Cold-War-era research facility, with optional wings, hidden recordings, a secret Directorate annex and a story told across time.
- Four endings shaped by what you find, who you believe, and what you do at the Door.
- New Game+ "Second Signal": a Listener that remembers you, new transmissions, changed encounters.
- No combat, no microtransactions. Headphones strongly recommended.

## Achievements (stable IDs, ready for Steamworks)
| API name | Display name | Description |
|---|---|---|
| `first_signal` | First Contact | receive your first transmission |
| `title2` | Already Inside | reach the communications annex |
| `seen` | It Has No Face | survive the first sighting |
| `door_closed` | Good Listener | leave the door in the quarters shut |
| `all_tapes` | Her Voice | find every recording by Dr. Voss |
| `hale` | The Man at the Door | hear Marcus Hale's last tape |
| `unseen` | 107.9 | reveal ten hidden things *(hidden)* |
| `no_hunt` | Quiet Feet | finish a chapter without being hunted |
| `pell` | The Forty-Second | follow Jonah Pell's calls to the end *(hidden)* |
| `end_A` | Ending | Silence |
| `end_B` | Ending | The Open Door |
| `end_C` | Ending | The Loop |
| `end_D` | Ending | The Last Transmission |
| `all_endings` | The Signal Never Ends | see all four endings |
| `second_signal` | Second Signal | finish New Game+ *(hidden)* |
| `long_ear` | Long Ear | find the Directorate annex *(hidden)* |
| `notebook` | Eleven Thousand Nights | find every page of Mira's notebook *(hidden)* |
| `static_between` | Static Between | hear every transmission on 88.0 *(hidden)* |

## Capsule and store art specifications (Steamworks)
| Asset | Size (px) | Brief |
|---|---|---|
| Header capsule | 920 × 430 | Corridor in sodium light, receiver in the foreground at 107.9, the dish-faced silhouette at the end; logo top-left |
| Small capsule | 462 × 174 | Logo + the dish silhouette only (must read at thumbnail size) |
| Main capsule | 1232 × 706 | As header, wider; tagline "Something in the dark hears you." |
| Vertical capsule | 748 × 896 | The silhouette framed in a doorway, "DO NOT OPEN THE DOOR" small at the bottom |
| Page background | 1438 × 810 | Static-noise texture over the mountain portal at night, low contrast |
| Library capsule | 600 × 900 | As vertical capsule |
| Library hero | 3840 × 1240 | The portal in rain, red mast beacon; no text |
| Library logo | 1280 × 720 (transparent PNG) | The metal-glitch logo |
| Screenshots | ≥ 5 at 1920 × 1080 | See screenshot plan in 14_RELEASE_PLAN.md; current references in docs/screenshots |

## Controller support
Full gamepad support (Xbox layout; works with XInput and most DirectInput pads). Recommended Steam declaration: **Partial Controller Support** until a full play-through on gamepad has been verified on Windows, then **Full**. Ship a Steam Input template that mirrors the in-game bindings (see README controls table).

## System requirements (proposed — confirm on real hardware before publishing)
| | Minimum | Recommended |
|---|---|---|
| OS | Windows 10 64-bit | Windows 10/11 64-bit |
| CPU | 4-core, 2.5 GHz | 6-core, 3.5 GHz |
| RAM | 4 GB | 8 GB |
| GPU | OpenGL 3.3 capable, 2 GB (GTX 750 Ti / RX 460 class), **Low/Medium preset** | GTX 1060 / RX 580 class, **High preset** |
| Storage | 300 MB | 300 MB |
| Audio | Stereo headphones strongly recommended | |
These numbers are estimates: GPU performance has **not** been measured yet (only CPU-side cost on a software renderer — see 12_TECHNICAL_DOCUMENTATION.md).

## Accessibility (implemented)
Subtitles (on by default, speaker names, three sizes) · reduce flashing · FOV · brightness · head-bob toggle · toggle/hold crouch · invert Y · sensitivity · separate music and effects/voice volumes · window resolution presets · hold-to-skip cinematics · no timed button prompts · information never conveyed by colour alone. Planned: input remapping UI, captions for important sound cues.

## Privacy and licensing
- **Privacy:** the game collects no personal data, has no telemetry, no accounts and makes no network connections. Saves and settings stay on the player's computer. See docs/PRIVACY.md.
- **Third-party licences:** Godot Engine (MIT), Liberation fonts (SIL OFL 1.1), ambientCG materials (CC0). See docs/THIRD_PARTY_NOTICES.md; include it and Godot's licence text in the release package.
- **EULA:** use Steam's default Subscriber Agreement unless the owner wants a custom EULA.

## Steam integration (investigated, not implemented)
- **Library:** GodotSteam for Godot 3.5 (module build of the editor + export templates, or the GDNative plugin). Requires replacing the export templates with GodotSteam's and adding `steam_appid.txt` for local testing.
- **Achievements:** call `Steam.setAchievement(id)` + `Steam.storeStats()` where `G.achieve(id)` is called today — the IDs above are already stable. Hidden achievements are a Steamworks setting.
- **Cloud saves:** Steam Auto-Cloud, no code — root `WinAppDataRoaming`, subdirectory `Godot/app_userdata/DEAD FREQUENCY`, patterns `save.json`, `save.json.bak`, `profile.json`.
- **Blockers:** needs the owner's Steamworks account, the $100 Steam Direct fee, and the resulting App ID. Steam's waiting periods (store page visible as "Coming Soon" for at least two weeks; 30 days after paying the fee) should be verified in current Steamworks documentation.

## Release checklist
See 14_RELEASE_PLAN.md → Release checklist, plus:
- [ ] Windows launch test on real hardware (the `--smoketest` option writes a log and screenshots)
- [ ] GPU performance measured; system requirements confirmed
- [ ] Human playtests confirm campaign length before quoting hours on the store page
- [ ] Voice-over recorded (or store page states "subtitled, no voice acting")
- [ ] Steamworks: App ID, achievements configured (IDs above), Auto-Cloud configured, depots uploaded to a beta branch
