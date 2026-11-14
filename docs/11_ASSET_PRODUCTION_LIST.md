# DEAD FREQUENCY — Asset Production List

The current build's only imported art is **20 CC0 PBR material sets from ambientCG** (listed in THIRD_PARTY_NOTICES.md); geometry, characters and every sound are generated in code. This keeps the repository original and licence-clean, but it is a stand-in for the commercial target. This list separates what exists from what a release needs. Priority: **P1** blocks a commercial release · **P2** strongly expected · **P3** polish.

## What exists now
| Area | Implementation | Quality today |
|---|---|---|
| Level geometry | grid-built walls, floors, ceilings, trim bands; auto pipe runs and debris | Functional, blocky |
| Materials | 20 CC0 PBR sets (albedo, normal, packed AO/roughness/metal), world-space triplanar on walls/floors/ceilings, per-prop material choice (`mats.gd`); flat colours on the Low preset | Convincing surfaces up close; not photoreal |
| Lighting & effects | fixtures with emissive tubes, volumetric light cones, dust, sparks, steam, drips, water shader (`fx.gd`) | Good atmosphere |
| Props (37 types) | primitive compositions in `props.gd` — desks, lockers, consoles, tanks, turbines, racks, beds, cribs, valves, dishes, tram, the Aperture… | Recognisable silhouettes |
| Characters | articulated figures with tapered limbs, coats, heads and hair; translucent "shades"; first-person hands with torch and HX-7 receiver | Stand-ins |
| The Listener | rebuilt body (ribs, jointed arms and legs, fingers, dish head with struts) with code animation: gait, torso pitch, dish snapping toward sounds, signal-stutter; rim-lit skin shader | Strong silhouette, limited detail |
| Exterior | mountains, snow caps, bunker portal, mast, truck, rain, lightning | Atmospheric, low detail |
| Audio | 39 synthesised sounds incl. per-surface footsteps (concrete, metal, tile), creature rasp and dish snaps, tension and chase music layers, fear breathing; adaptive mix with ducking | Original, serviceable; no composed score, no VO |
| Fonts | Liberation Sans / Mono (SIL Open Font License) | Fine |
| UI | code-drawn HUD, receiver face, menus, shaders (grain, vignette, damage, interference, metallic glitch title, fog) | Good |

## Required for release
### Characters (P1)
| Asset | Spec |
|---|---|
| Daniel — first-person arms | gloved hands, jacket cuffs; rig for radio, flashlight, interact, hide, stumble (≈ 25 anims) |
| Daniel — full body | cinematics/reflections; 1 outfit |
| The Listener | high-detail model per 03_CHARACTER_BIBLE.md; 2.6 m; ≈ 18 anims (scan, walk, investigate, search, stalk/freeze, hunt run, ambush, grab, drag-out, retreat, face-turn) |
| Evelyn, Mira, Hale, Okafor, Lind, Haddad, Ruiz, Cross, Duarte | 1998 models for the prologue and as translucent echo variants |
| Staff crowd | 6 generic variants for the prologue |

### Environment kits (P1) — one modular kit per sublevel
Entrance & security · administration · medical · residential · power station (turbines, gantries) · flood tunnels (water shader, drips) · communications (consoles, racks, feed horns) · research labs (tanks, benches, cold room) · transport (platform, tram, rails) · containment (bulkhead, red lighting) · archive (shelving, vaults) · Aperture level (ring corridor, emitters, the Door) · exterior mountain (terrain, snow, storm, road, mast, gate, truck).

### Props (P2)
≈ 120 unique props: CRT monitors and terminals, reel-to-reel and cassette recorders, the HX-7 receiver (hero prop, interactive dial and antenna), keycards, fuses, crystals, valve wheels, breaker panels, lockers, beds/cribs, coats and shoes (the vanished), lab equipment, filing, boxes, signage (HELIX-9 wayfinding, department colours).

### Textures & materials (P2)
PBR sets (albedo/normal/roughness/AO) per kit: painted concrete, tiled floors, rubber, brushed steel, rust, water-stained ceilings, lab tile, carpet, archive paper. Decals: water damage, scorch, signage, warning stripes, handwritten notes.

### Audio (P1)
- **Voice-over**: 640 lines, 7,673 words, 24 characters — recording script with file names, direction and processing per line in `docs/vo/` (plan: 18_AUDIO_PRODUCTION_PLAN.md).
- **Music**: main theme, menu loop, per-area ambient beds (12), chase, the four ending cues, credits theme, the lullaby (solo voice).
- **SFX**: replace/upgrade the procedural set; add per-surface footsteps (concrete, metal grate, carpet, water, tile), cloth, receiver foley (dial clicks, antenna, squelch), creature voice set.
- **Credit**: sound design credited to **Ajay Gohil** in the end credits as specified by the project owner.

### Cinematic & marketing (P2)
Logo (vector) and title animation; Steam capsules (header 920×430, small 462×174, main 1232×706, vertical 748×896, library hero 3840×1240, library logo); trailer edit; 5+ store screenshots (current renders: `docs/screenshots/`).

## Asset pipeline (planned)
Blender → glTF 2.0 → Godot import (`.glb`), PBR textures from Substance (or Material Maker, free) at 2K, audio as 48 kHz WAV → Ogg Vorbis. Replace procedural props by name in `props.gd` (`make(type)`), so level data does not change.
