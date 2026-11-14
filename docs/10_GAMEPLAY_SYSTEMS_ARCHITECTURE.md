# DEAD FREQUENCY — Gameplay Systems Architecture

## Runtime structure
```
Main (scenes/Main.tscn → scripts/main.gd)       flow: intro → menu → chapters → ending → credits
 ├─ UI (scripts/ui.gd, CanvasLayer)              HUD, subtitles, menus, cards, title reveal, journal, settings, post-FX
 │   └─ HUD painter (scripts/hud_draw.gd)        health / battery / stamina bars, the receiver face
 ├─ Menu (scripts/menu.gd)                       3D main menu over the live exterior set
 ├─ Credits (scripts/credits.gd)                 skippable scrolling credits → return to menu
 └─ Level (scripts/level.gd)                     one per chapter / ending, built from data
     ├─ geometry, materials, lights, props (scripts/props.gd), exterior set (scripts/exterior.gd)
     ├─ A* navigation grid, entities, triggers, event runner, cinematic camera
     ├─ Player (scripts/player.gd)               KinematicBody first-person controller
     ├─ Radio (scripts/radio.gd)                 the HX-7 receiver
     └─ Listener (scripts/listener.gd)           the enemy, when spawned

Autoloads: G (scripts/g.gd: state, settings, input map, save/load, achievements, ending logic)
           Snd (scripts/snd.gd: procedural audio synthesis, pools, loops, music)
           Story (data/story.gd: chapter registry, titles, items, achievements, credits)
```

## Data-driven chapters
Each chapter (`game/data/chNN.gd`) is a dictionary: palette, map (ASCII grid), legend (entity definitions), AI spawn specs, puzzle groups, opening events and a QA walkthrough. The engine never contains chapter-specific code.

**Entity types** (`"t"`): `light`, `prop`, `npc`, `note`, `tape`, `item`, `use` (incl. `seq` ordered switches and `cycle` rotation puzzles), `save`, `hide`, `door` (plain / `code` / `lock` item / `needflag` / `sealed`), `trig` (proximity trigger with optional `if`/`ifnot`), `radio` (transmission on a frequency, with range and directionality), `ghost` (visible only on 107.9), `plate` + `pcrate` (physics), `mark` (camera/spawn point).

**Event commands** (run by `level.run()`, sequential coroutines): dialogue lines (`["SPEAKER", "text"]`), `wait`, `obj`, `flag`, `if`/`ifnot`, `choice`, `sfx`, `loop`/`unloop`, `loop3d`/`unloop3d`, `music`, `lights`, `pulse`, `card`, `title`, `text`, `monitor`, `fade`, `cine`, `cam`/`camoff`, `look`, `move` (NPCs), `tp`, `shake`, `give`/`take`, `checkpoint`/`save`, `unlock`/`lock`/`close`, `listener` (spawn/despawn/patrol/hunt/stalk/seek/face/blind/…), `hurt`, `toast`, `journal`, `ach`, `radio_on`, `reveal`, `hide_ent`/`show_ent`, `ext`, `noise_mult`, `group`, `next`, `ending`, `credits`, `menu`. All commands and marker references are validated by `tools/test.sh validate`.

## Core systems
| System | Where | Notes |
|---|---|---|
| Movement | player.gd | walk 2.7 / sprint 5.3 / crouch 1.3 m/s, stamina 100 (−16/s sprinting; winded below 0 until 30), lean ±0.42 m with roll, head-bob (toggle), water slowdown |
| Flashlight | player.gd | spotlight with shadows; battery drains 100 % per 260 s; spare power cells auto-load; flickers below 12 % |
| Receiver | radio.gd | 87.5–108.0 MHz in 0.1 steps (wheel, arrows, D-pad, hold to sweep); own cell (100 % per 170 s); band identification; directional reception (facing × distance); 1 s lock to receive; noise emission every 1.2 s; exposure lamp |
| Health | player.gd | 100 HP, medkit +60, < 35 HP: slower + heartbeat; red vignette below 60; death → game over |
| Inventory | g.gd | counted items; keys/fuses/crystal/key cards consumed or kept per door; shown in the journal |
| Interaction | player.gd + level.gd | 2.7 m ray on layer 2; prompts; doors, notes, tapes, items, consoles, lockers, saves |
| Hiding | player.gd | lockers: player view through vents (post-FX slits); the Listener can learn your favourites |
| Physics | level.gd | rigid crates pushed by the player; pressure plates set flags |
| Throwing | player.gd | bottles (G) → impact noise 16 m at the landing point |
| Objectives & journal | ui.gd | objective line fades after 6 s; journal (Tab) keeps every note, tape and transmission transcript |
| Save / load | g.gd | JSON, versioned (`v`), story flags + inventory + journal + vitals + checkpoint marker; profile separate (settings, unlocked chapters, endings, achievements) |
| Checkpoints | level.gd | automatic at chapter start and story beats; manual at emergency-log terminals |
| Menus | menu.gd, ui.gd | New Game / Continue / Chapter Selection (unlocks with progress) / Settings / Credits / Exit; pause menu with journal, settings, reload, quit to menu |
| Settings | ui.gd + g.gd | volumes (master/music/effects+voice), sensitivity, invert Y, FOV 60–100, brightness, graphics preset Low/Medium/High/Ultra, subtitles on/off + size, fullscreen, V-Sync, head-bob, toggle crouch, reduce flashing |
| Cinematics | level.gd + ui.gd | marker-to-marker camera dollies, NPC movement, lighting/sound cues, subtitles, hold-to-skip |
| Endings | g.gd `ending_id()` | B open · D answer + trust + Hale + ≥5 tapes + key · A silence + key · C otherwise |
| Achievements | g.gd + story.gd | 13 achievements, profile-persistent; Steamworks mapping planned (see release plan) |
| Audio | snd.gd | every sound synthesised at first launch (cached): drones, static, hum, rain, thunder, steps, doors, clicks, screech, voices, knock, alarm… 3D positional players, reverb on the effects bus |

## Input map (keyboard / mouse / gamepad)
Move WASD / left stick · look mouse / right stick · sprint Shift / L3 · crouch Ctrl or C / B · lean Q,E / LB,RB · interact F or LMB / A · flashlight T or MMB / Y · radio R or RMB / X · tune wheel or ←/→ / D-pad ←/→ · throw G / D-pad ↓ · medkit H / D-pad ↑ · journal Tab / Back · pause Esc / Start · skip cinematic: hold Space or Enter / A.

## Save format (v1)
```json
{"v": 1, "chapter": 5, "checkpoint": "V", "health": 72.0, "battery": 54.1, "radio_batt": 80.0,
 "has_radio": true, "has_light": true, "inv": {"battery": 1, "medkit": 1},
 "flags": {"started5": true, "power5": true, "u:c5_k1": true, "m_radio": 42, ...},
 "journal": [{"t": "...", "x": "...", "k": "tape"}]}
```
Forward compatibility: saves with a newer `v` are refused rather than misread; older versions load with defaults.
