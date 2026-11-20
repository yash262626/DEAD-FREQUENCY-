# DEAD FREQUENCY — Enemy AI: The Listener

Implementation: `game/scripts/listener.gd` (state machine, senses, learning), noise sources in `player.gd`, `radio.gd`, `level.gd`. All numbers below are the values in the shipped code. Tested by `tools/test.sh ai` (12 checks) plus the per-chapter playthroughs.

## Design goals
1. **Sound is the threat.** It finds you by what you do, not by cheating.
2. **Never omniscient.** It never reads the player's position. It only knows what it heard (blurred by distance) and what it saw (short range, needs light and line of sight).
3. **Learns, within limits.** Habits make you more findable; nothing makes you unfindable or doomed.
4. **Readable and fair.** Every state has audio tells (click rate and pitch, screech on commit), the 94.6 band shows distance and direction, the first catch from full health is survivable, chases are capped.

## States
| State | Speed (m/s) | Behaviour | Leaves when |
|---|---|---|---|
| DORMANT | 0 | Still, dish slowly scanning | alert > 0.5, or 25 s pass → PATROL |
| PATROL | 1.5 | Walks between `P` points, weighted toward places it has heard you | alert ≥ 1 → HUNT · sees you with alert > 0.35 → STALK · route ends → 25 % AMBUSH (after 2+ hunts) / 30 % DORMANT / next point |
| INVESTIGATE | 2.3 | Goes to its *guess* of a heard noise | sees you with alert ≥ 1 → HUNT · arrives → SEARCH |
| SEARCH | 1.8 | Checks 3–4 spots near the last known position, including lockers it suspects | sees you with alert ≥ 1 → HUNT · finds you in a checked locker → drag-out · done → STALK (alert > 0.4) or PATROL |
| STALK | 2.0 | Follows your last known position at a distance; **freezes while you look straight at it** (> 2.5 m away); mimics voices every 22–40 s within 16 m | alert ≥ 1, sees you, and (< 7 m or your flashlight is on) → HUNT · after 22 s → AMBUSH (40 %) or RETREAT |
| HUNT | 4.4 | Chases (repaths every 0.35 s), screech on entry | catch at < 1.25 m with line of sight → attack → RETREAT · out of sight 4.5 s → SEARCH · 40 s → RETREAT (fairness cap) |
| AMBUSH | 3.0 → 0 | Moves to a spot ~12 m ahead of your heading and waits silently | you come within 3.6 m with line of sight → HUNT · 26 s → PATROL |
| RETREAT | 3.2 | Goes to the patrol point farthest from you; alert reset | arrives → DORMANT |

Player speeds for comparison: walk 2.7, sprint 5.3 (stamina-limited), crouch 1.3; ×0.72 in water, ×0.85 when badly hurt. A sprinting player outruns a hunt until stamina runs out (≈ 6 s), then must break line of sight or hide.

## Hearing
Every sound has a loudness = radius in metres. If the Listener is farther away than `loudness × learned multiplier`, it hears nothing.

| Source | Radius (m) |
|---|---|
| Footstep — crouch / walk / sprint | 1.3 / 5 / 12.5 |
| … in water | ×1.5 |
| … next to running machinery (Ch 5 after power) | ×0.45 |
| Door opening | 9 |
| Locked door rattle / failed code | 5–6 |
| Wrong breaker/switch sequence | 9 |
| Getting in/out of a locker | 4 |
| Flashlight click | 2 |
| Thrown bottle impact | 16 (at the impact point — a lure) |
| Playing a tape | 7 |
| **Radio on** (every 1.2 s) | 8 · 94.6: 10 · locked on a transmission: 11 · **107.9: 15** |

Rules: it ignores new sounds while hunting or retreating; in AMBUSH it ignores anything beyond 6 m; in DORMANT it ignores quiet sounds (< 4) beyond 3 m. The position it walks to is **blurred**: error = distance × 0.18 (max 5 m), snapped to a random reachable cell near the true source. Each heard step adds 0.12 alert; other sounds 0.2.

## Sight
- Range 8 m · +7 m if your flashlight is on · ×0.55 if you are crouched · +4 m while hunting · ×0.7 in an unpowered area without your light.
- Forward cone (it can't see behind itself beyond 2 m, except while hunting).
- Needs a clear line through the level grid (walls and closed doors block it). Never sees a hidden player.
- Alert from sight builds over time: `dt × clamp(1.5 − d/9, 0.25, 1.4)`, ×1.6 if you are sprinting. It decays at 0.05/s.
- Variants: **cloaked** (Ch 10, containment) — its body is only visible on 107.9 or within 2.2 m; **blind** (Ch 12 climax) — it sees only within 1.2 m and must hunt by ear.

## Learning (bounded)
| What it learns | Effect | Bound |
|---|---|---|
| How much you use the radio | Hears the carrier from further away (+0.4 % per transmission) | max +50 % |
| Which lockers you use | Chance it checks a locker near your last known position: 8 % + 18 % per repeat use | max 70 % (100 % if it watched you get in) |
| Where it hears you | Patrol picks are weighted toward those areas | weight ×1 → ×5 |
| How often it hunts you | After 2 hunts, sometimes ambushes ahead of your heading instead of patrolling | 25 % of patrol decisions |

Learning is stored in story flags (`m_radio`, `m_hide_*`, `m_hunts`) and persists in the save, so it remembers across chapters.

## Psychological deception (scripted + systemic)
- **Systemic mimicry** while stalking: "MIRA?: Daniel? I'm right here. Just follow my voice." etc. — only voices and lines that have been heard on air.
- **Scripted**: repeats Daniel's own words (Ch 2), Kessler on a loop (Ch 2, 7), Evelyn calling him "sweetheart" (Ch 3), a cassette left playing behind a knocking door (Ch 4), the radio "Hale" for six chapters, two Miras at the bulkhead (Ch 10), the Harrow Pass line, every voice at once (Ch 12), Evelyn's voice at the Door (Ch 13).
- **Environmental**: power failures (`pulse`), doors cycling, footsteps behind you, a PA that knows your name, clocks frozen at 02:43.

## Attacks and fairness
- Catch = 55 damage, then it **retreats** (alert reset). From full health the first catch never kills. Medkits heal 60. Below 35 HP you move slower and hear your heartbeat.
- Drag-out from a locker only if it saw you get in, or its habit-weighted search picked that locker.
- No instant deaths except falling out of the world; death → "SIGNAL LOST" → reload last checkpoint.

## Counterplay summary
| Threat | Counter |
|---|---|
| Patrol | Crouch, read 94.6, go around; throw a bottle to pull it away |
| Investigate/search | Stay out of sight; don't reuse the same locker; it searches where it *thinks* the sound was |
| Stalk | Look at it — it freezes; back away; break line of sight |
| Hunt | Sprint, break line of sight, close doors behind you, hide **out of its sight** |
| Ambush | Vary your routes; 94.6 shows it's near even when silent |
| Cloaked | 107.9 shows it — at the cost of being loud |
| Blind (finale) | Radio off, crouch, no doors, no bottles |

## Tuning constants (listener.gd / player.gd)
`SPEED = [0, 1.5, 2.3, 1.8, 2.0, 4.4, 3.0, 3.2]` · sight 8 m (+7 light, ×0.55 crouch, +4 hunt) · lost-sight timeout 4.5 s · hunt cap 40 s · stalk timeout 22 s · ambush timeout 26 s · dormant wake 25 s · attack 55 dmg at 1.25 m · mimic interval 22–40 s.
