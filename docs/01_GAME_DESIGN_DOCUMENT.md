# DEAD FREQUENCY — Game Design Document

**Genre** psychological horror / survival / mystery · **Platform** Windows PC (Steam) · **Camera** first person · **Engine** Godot 3.5 (see 12_TECHNICAL_DOCUMENTATION.md for why) · **Mode** single player · **Developer** Yash Ail

## High concept
*A radio that hears the past. Something in the signal that hears you.* Daniel Arlen restores the communications of a mountain research station that vanished in 1998, using a hand-held receiver whose four bands show him the past, nearby movement, the near future and hidden things — while every second it's switched on tells the thing in the facility exactly where he is.

## Pillars
1. **Every transmission is a decision.** Information always costs exposure.
2. **Afraid to move.** An enemy that hunts by sound, learns habits, and lies with real voices.
3. **Whose voice is real?** Story, puzzles and the final choice all turn on judging voices — including your own.
4. **A story worth finishing.** A mystery paid off clue by clue, with four endings that mean different things.

## Player fantasy
A competent, frightened professional using real technical skill — tuning, triangulating, reading logs, rewiring power — to survive and to understand.

## Core loop
Explore a sublevel → find leads (documents, tapes, 89.1 echoes) → decide when to use the receiver → solve the area's gate (code, order, alignment, physics, key) → evade or outwit the Listener → reach a story beat / checkpoint → descend.

## The receiver (signature mechanic)
| Band | Use | Cost |
|---|---|---|
| **89.1 ECHO** | Conversations from 1998: codes, orders, story | Noise 8 m, 11 m while locked on |
| **94.6 PROXIMITY** | Geiger-style beeps: rate = distance, tone = facing | Noise 10 m |
| **101.3 FORECAST** | Daniel's future voice warns what will happen; it always does | Noise 8–11 m |
| **107.9 UNSEEN** | Reveals writing, echoes of people, the cloaked Listener | Noise **15 m** — the loudest |
| Hidden carriers | 96.1 Mira · 98.5 dispatch · 99.7 numbers station · 103.7 "Hale" | as above |

Physical interaction: a dial (0.1 MHz steps, hold to sweep), a directional antenna (signal strength depends on facing the source), signal bars, static that clears as you lock on, a separate battery, and an exposure lamp that brightens as the Listener could hear you. Exposure is bounded but the Listener learns: heavy radio users are heard from further away (up to +50 %).

## Other mechanics
Walk/sprint/crouch/lean; stamina; flashlight with battery (it also makes you visible from +7 m); inventory (keys, fuses, crystal, cells, medkits, bottles); health with injury effects; lockers; throwable bottles as lures; doors (plain, keycard, code, power-gated, sealed); physics crates and pressure plates; ordered-switch puzzles; rotation/alignment puzzles; checkpoints and manual saves; journal with every document and transcript.

## Enemy
The Listener: dormant / patrol / investigate / search / stalk / hunt / ambush / retreat; hears footsteps, running, doors, objects, the radio, the flashlight click; sees only near and in light; learns hiding spots and routes; mimics voices; can be cloaked or blinded by the story. Full spec: 09_ENEMY_AI.md.

## Structure
Prologue cinematic (2 min 15 s) → 13 chapters → one of four endings → credits. Title revealed at the end of the opening and again ~25 min in (Ch 1, "SIGNAL IDENTIFIED — STATUS: ALREADY INSIDE"). Every chapter opens with a chapter card. Chapter Selection unlocks as chapters are reached. Campaign detail: 04_CAMPAIGN.md.

## Endings
Decided by the final choice *and* by what the player learned and chose earlier (keeping the bulkhead sealed, hearing Hale's last tape, collecting Evelyn's tapes, finding the shutdown key). See 05_MISSION_DESIGN.md.

## Difficulty and fairness
No combat; survival through stealth and knowledge. First catch from full health is survivable; chases are time-capped; checkpoints are frequent; the 94.6 band and audio tells always give warning. Options: reduce flashing, subtitles with size, toggle crouch, head-bob off, invert Y, FOV and brightness.

## UI / UX
Minimal HUD: centre dot, contextual interaction prompt, objective line that fades, battery/health/stamina only when relevant, receiver face only when the radio is on. Subtitles with coloured speaker names. Journal (Tab) for documents and transcripts. Paper documents shown full-screen on aged paper.

## Art direction
Industrial 1990s government facility left in the dark: painted concrete with a coloured trim band per department, pipe runs, fluorescent strips, CRT consoles. Each sublevel has its own palette (amber entrance, cold blue admin, green medical, warm brown quarters, orange power, teal flood, green-black comms, clinical white labs, yellow transport, red containment, sepia archive, deep blue chamber). Darkness is used for contrast, not as a blanket: every room has a light source, and the player's flashlight is the main sculpting light. Current build uses procedural geometry and materials; the final art plan is in 11_ASSET_PRODUCTION_LIST.md.

## Audio direction
Hear it before you see it: positional clicks and footsteps, the radio as a constant texture, silence as an event. Every sound in the current build is synthesised procedurally (no third-party or copyrighted audio). Drones per area, a bass impact for title reveals, a lullaby that is never performed with instruments.

## Business
Premium single purchase; target price ₹799–₹999 (to be confirmed by market research once the playtime and art targets are met — see 14_RELEASE_PLAN.md). No microtransactions, no pay-to-win, no ads.

## New Game+ — "Second Signal"
Unlocked by finishing any ending. The Listener keeps the previous run's *habits*, not its knowledge, at half strength: lockers it found you in are searched more often (never certainly), heavy radio use is heard from further away (still capped at +50 %), a lure-heavy run makes it ignore repeated bottles, sprint escapes make its hunts faster (still slower than a sprint; chases stay time-capped). New content: transmissions on 88.0 MHz (below the band, so listening makes no noise), the dispatcher Kessler's thread with postscripts after each ending, encounter variants. Achievement: Second Signal. Spec and tests: 09_ENEMY_AI.md, `tools/test.sh ngplus`.

## Presentation
- Real-time 3D in Godot 3.5 with CC0 PBR materials (ambientCG), light fixtures with volumetric shafts, dust, sparks, steam, drips, water; a stylised look rather than photoreal (engine assessment: 19_ENGINE_MIGRATION_ASSESSMENT.md).
- Adaptive music: tension and chase layers follow the Listener's state; everything ducks to near-silence when it is close but has not found you. Footsteps change with the floor. Recorded voice-over drops in by file name (docs/vo/), with the processed radio voice as the placeholder.
- Second reveal: a CRT terminal types SIGNAL IDENTIFIED / SUBJECT: DANIEL ARLEN / STATUS: ALREADY INSIDE, the last line turns red, then DEAD FREQUENCY.
- The pause menu opens automatically when the window loses focus.

## Current status vs. target (honest)
All systems, all 13 chapters with optional wings, the prologue, both title reveals, chapter cards, four endings, New Game+ and credits are implemented and pass automated tests (780 checks). Campaign length is **modelled, not measured**: 3.9–10.1 h main path, 5.4–14.0 h with all optional content (17_TIME_BUDGET.md). The **10–15 hour target is not claimed** until playtests (the game now logs play time per chapter locally for exactly this) show it. Visuals are stylised, not photoreal; there is no recorded voice acting yet; the Windows build passes its smoke test under Wine but has not been run on Windows hardware.
