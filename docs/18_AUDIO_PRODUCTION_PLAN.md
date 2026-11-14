# DEAD FREQUENCY — Audio Production Plan

**Status, honestly:** every sound in the current build is synthesised in code (`game/scripts/snd.gd`, 39 sounds, cached on first launch). No sound has been recorded, licensed or composed by a person yet. The systems that a professional mix will plug into are implemented and tested: positional 3D audio with reverb, adaptive music layers, per-surface footsteps, and automatic voice-over playback by filename. Sound effects are credited to **AJAY GOHIL** in the end credits as specified by the project owner.

## Pillars
1. **Hear it before you see it.** Every threat has an audio tell first (clicks, rasp, footsteps, the 94.6 beeps).
2. **Silence is an event.** The mix deliberately empties when the Listener is close but hasn't found you.
3. **The radio is the instrument.** Static, carrier whine and squelch are the game's sonic signature; music grows out of them.
4. **Voices are the horror.** Every voice can be a lie; processing tells the player *how* they are hearing it (tape, radio, through a door, in the room).

## Implemented audio systems
| System | Behaviour | Where |
|---|---|---|
| Positional audio | `AudioStreamPlayer3D` for creature, doors, steps, transmissions; inverse-square attenuation; reverb on the effects bus | `snd.gd`, `g.gd` |
| Adaptive music | Base area drone + **tension** layer (rises as the Listener nears or searches) + **chase** layer (during a hunt); swell fast, release slow | `snd.gd layer()`, `level.gd _music_director()` |
| Silence | When the Listener is within 8 m and not hunting, music ducks to zero; only the room remains | `level.gd` |
| Fear breathing | Daniel's breathing rises as it gets within 7 m (muted while hidden) | `level.gd` |
| Surface footsteps | concrete / metal grating / tile / water, chosen from the area's floor material | `player.gd _step_sound()` |
| Creature | irregular clicks (state-dependent pitch/volume), close-range rasp (7 m), dish-snap chirp, hunt screech | `listener.gd` |
| Radio | static bed that clears as you lock on, tuning ticks, glitch bursts, per-band behaviour (94.6 beeps) | `radio.gd` |
| Voice-over hook | `res://vo/<id>.ogg` plays automatically for a line when present; subtitle duration follows the file | `ui.gd say()`, verified by `tools/test.sh vo` |

## Mix targets
Integrated loudness −16 LUFS (PC), dialogue −18 LUFS short-term, true peak −1 dBTP. Music sits 6–10 dB under dialogue; the tension layer never masks the creature's clicks. Buses: Master → Music, SFX (reverb), Voice.

## Ambience beds (one per area, 2–3 layers each)
Entrance (rain on concrete, wind at the blast door, generator hum) · Administration (dead HVAC, fluorescent buzz) · Medical (drip, distant monitor tone) · Residential (pipes ticking, a fridge compressor) · Power (turbines, steam, metal stress) · Flood tunnels (water lapping, drips, pumps) · Communications (rack fans, relay clicks) · Labs (cryo hiss, tank bubbles) · Transport (rail hum, tunnel wind) · Containment (low sub rumble, alarms far off) · Archive (paper, dust, absolute quiet) · Aperture level (the carrier itself: a slow beating tone).

## Music cues
Main theme (title reveals) · menu loop · 12 area beds · tension and chase stems (currently procedural; to be composed as stems that crossfade exactly like the implemented layers) · four ending cues (Silence: solo piano in a large room; Open Door: choir that slowly detunes; Loop: the opening cue played backwards into the arrival; Last Transmission: the lullaby melody on a music box, then radio static resolving into it) · credits · **the lullaby** (Evelyn's melody; only ever sung unaccompanied in-world — never an instrumental in gameplay).

## Radio processing chain (post)
High-pass 300 Hz → low-pass 3.4 kHz → mild saturation → carrier whine (−30 dB, per band pitch) → squelch tail. Tapes: 250 Hz–5 kHz, hiss, wow 0.3 %. PA: horn IR + long concrete reverb. Through a door: low-pass 1.2 kHz, thin.

## Creature sound vocabulary (to record/design)
Clicks (5 rates × 3 intensities) · dish snap/chirp (8) · rasp loops (3) · footfalls on 4 surfaces (12 each) · hunt screech (4) · grab/impact (3) · mimic processing: same actor as the imitated character, flatter take, breath removed, 2–5 % pitch drift.

## Footsteps matrix
5 surfaces (concrete, metal grating, tile, water, carpet) × walk/run/crouch × 8 variations + scuffs and landings. Daniel's kit: work boots, waterproof jacket rustle, radio strap.

## Voice-over
Recording script: **docs/vo/VO_RECORDING_SCRIPT.md** and **docs/vo/vo_script.csv** (640 lines incl. New Game+), generated from the game data by `tools/vo_package.py` with character, chapter, scene, emotional direction, processing and the exact filename the game looks for.

| Character | Lines |
|---|---|
| DANIEL | 298 |
| MIRA | 79 |
| EVELYN | 73 |
| HALE | 33 |
| OKAFOR | 28 |
| PA | 20 |
| PELL | 14 |
| LISTENER | 13 |
| KESSLER | 12 |
| HADDAD | 9 |
| MARCUS | 8 |
| DISPATCH | 8 |
| RUIZ | 8 |
| LIND | 6 |
| CROSS | 6 |
| BRANDT | 5 |
| DIRECTORATE | 4 |
| ADA | 3 |
| OSTROWSKI | 3 |
| COLONEL | 3 |
| VOICE | 2 |
| GUARD | 2 |
| VOICES | 2 |
| DUARTE | 1 |

Casting notes per role are in 03_CHARACTER_BIBLE.md (voice direction sections). Lines spoken by the Listener in someone's voice are recorded by that character's actor as a second, flatter take.

## Deliverables tracker
| Deliverable | Status |
|---|---|
| Adaptive music system, silence logic, positional audio, surface footsteps, VO hook | **Implemented — tested** |
| Procedural placeholder SFX and music (39 sounds) | **Implemented** (stand-ins) |
| Recorded/designed SFX library | Awaiting sound designer (credited: Ajay Gohil) |
| Composed score and stems | Awaiting composer |
| Voice-over (640 lines) | Script ready; awaiting casting and recording |
| Final mix and loudness pass | Awaiting the above |
