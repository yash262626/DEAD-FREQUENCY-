# DEAD FREQUENCY — Chapter-by-Chapter Campaign

*Story summaries are authored; objectives, puzzles, collectibles and checkpoints are generated from the shipped chapter data by `tools/gen_docs.py`.*

| # | Chapter | Location | Main threat | Signature mechanic |
|---|---|---|---|---|
| 00 | Prologue | 1998 facility (cinematic) | — | Opening cinematic + first title reveal |
| 01 | THE ARRIVAL | Mountain entrance, security checkpoint | Glimpse only | Receiver tutorial (89.1, 101.3), second title reveal |
| 02 | THE SILENT WING | Administration | Patrol | 94.6 proximity, lockers, mimicry rule |
| 03 | WHAT REMAINS | Medical wing | Stalker (freezes when watched) | 107.9 reveal, crate & plate |
| 04 | BELOW THE SURFACE | Residential quarters | Patrol / hunt if the door is opened | 96.1 Mira, knocking-door choice |
| 05 | THE VOICES | Power station | Patrol → first chase | Breaker order from a 1998 echo, noise masking |
| 06 | NO WAY BACK | Flood tunnels | Patrol in water (louder steps) | Valves readable only on 107.9 |
| 07 | THE SIGNAL ROOM | Communications centre | Patrol | Numbers station 99.7, feed-horn alignment, uplink |
| 08 | THE ECHO PROJECT | Research labs | Scripted forecasts | 101.3 forecasts that come true |
| 09 | DEAD LINE | Transport line | Patrol → chase to the tram | Switch order, the Mira revelation |
| 10 | WHAT LISTENS | Containment | Invisible stalker (107.9 only) | Bulkhead choice (trust) |
| 11 | EVERY VOICE EVER LOST | Archive | Ambush (uses learned habits) | Vault codes, Hale's last tape, shutdown key |
| 12 | 02:43 | Aperture ring | Patrol → blind listener | Three emitters, silent approach |
| 13 | THE LAST TRANSMISSION | The Door | — | Final choice → four endings |

---

## PROLOGUE — OCTOBER 17, 1998

**

October 17, 1998, 02:43. A storm over the mountain. Inside HELIX-9, Dr. Evelyn Voss's team watches the 107.9 carrier answer a message nobody sent, stamped with a date twenty-eight years in the future. Security chief Marcus Hale orders the lower levels sealed. Evelyn sends Mira Solace up the lift with a child. A voice on the channel — Daniel's — warns: do not open the door. The power dies. *Can anyone hear me?* Title.

**The Listener** — scripted appearances only

**Saves** — automatic at chapter start and at story checkpoints; 0 emergency-log terminal(s) for manual saves.


---

## CHAPTER 01 — THE ARRIVAL

*OCTOBER 17, 2026*

2026. Daniel Arlen arrives at the gate in the rain; dispatch reads him the beacon's message: his own name. He restores auxiliary power, finds the HX-7 receiver, hears 1998 on 89.1, glimpses something tall at the end of a corridor and hears his own voice on 101.3: *do not open the door*. In the comms annex a tape addressed to him plays; the monitor identifies him: ALREADY INSIDE. Second title reveal (~25 min).

**Objectives (in order shown to the player)**

1. Restore auxiliary power. The generator is past the checkpoint.
1. Try the receiver. The dial is marked at 89.1 MHz.
1. The checkpoint's inner door has power now. Go deeper.
1. Find a way into the communications annex.
1. Enter the communications annex at the end of the corridor.

**Puzzles & gates**

- Door locked by item — needs **Comms annex keycard**
- Door gated by story state `power1` — “Mag-lock. Dead without power. I need the generator running first.”
- Keypad `LOST PROPERTY CABINET — CODE` — code **0042**
- “Fit fuse and start generator” — needs **Ceramic fuse**

**Discoveries**

- Tape — Security log — Hale, Oct 12 1998
- Document — Gate Log — Oct 16, 1998
- Item — Power cell
- Item — Medkit
- Item — Comms annex keycard
- Item — HX-7 field receiver
- Item — Ceramic fuse
- Item — Glass bottle
- Document — Memo — M. Hale, Chief of Security
- Document — Lost property — security
- Document — Work Order NR-2026-1017
- Document — A child's mitten
- Transmission 89.1 MHz — Gate post, 1998

**The Listener** — scripted appearances only

**Saves** — automatic at chapter start and at story checkpoints; 1 emergency-log terminal(s) for manual saves.


---

## CHAPTER 02 — THE SILENT WING

*SUBLEVEL 1 — ADMINISTRATION*

The administration wing, where the night shift stopped mid-sentence. First full sighting: the Listener stands in the supervisor's office and repeats Daniel's words back in Daniel's voice. It hunts the wing from then on. A 1998 echo gives the supervisor's code; a dispatcher's voice that only repeats teaches the core rule: it can only say what has already been said over the air.

**Objectives (in order shown to the player)**

1. Cross the administration wing to the medical gate.
1. Get into the supervisor's office. The records room might know the door code.
1. The medical gate is at the east end of the lower hall.

**Puzzles & gates**

- Keypad `SUPERVISOR'S OFFICE — CODE` — code **4406**
- Door locked by item — needs **Medical wing keycard**

**Discoveries**

- Item — Glass bottle
- Item — Power cell
- Transmission 89.1 MHz — Pell — the stranger (1 of 4)
- Item — Medical wing keycard
- Item — Medkit
- Document — Photo on Okafor's desk
- Transmission 89.1 MHz — Okafor's office, 1998
- Document — Night shift roster
- Document — Annex duty sheet
- Transmission 89.1 MHz — Records, 1998

**The Listener** — patrol from `Z` once `c2_loose`

**Saves** — automatic at chapter start and at story checkpoints; 1 emergency-log terminal(s) for manual saves.


---

## CHAPTER 03 — WHAT REMAINS

*SUBLEVEL 2 — MEDICAL*

The medical wing. A patient file with Daniel's birthday. Evelyn's first recording — about her son, who hears the carrier without a receiver. 107.9 reveals writing on the walls. The Listener begins to stalk in Evelyn's voice. A crate on a treadle plate opens the morgue for the lift fuse.

**Objectives (in order shown to the player)**

1. Search the medical wing. The service lift is somewhere along the main corridor.
1. Find a way down. The service lift is at the east end of the corridor.
1. Fit the fuse in the service lift panel at the east end of the corridor.
1. Something heard the tape. Hide, and wait for it to leave.

**Puzzles & gates**

- Keypad `PHARMACY — CODE` — code **3118**
- 107.9-only writing: “LET ME OUT / 2 7 1 1”
- Door gated by story state `c3_plate` — “Pneumatics are dead. It won't hold open. Lind's memo — weight on the treadle plate.”
- Keypad `QUARANTINE — CODE` — code **2711**
- “Fit fuse and call the service lift” — needs **Ceramic fuse**
- 107.9-only writing: “PHARMACY / 3 1 1 8”
- 107.9-only writing: “IT ONLY KNOWS WHAT IT HEARS. / SO DON'T LET IT HEAR YOU.”
- Physics: push the crate onto the treadle plate

**Discoveries**

- Tape — Brandt — quarantine
- Tape — Dr. Voss — hearing assessment **(Evelyn — counts toward ending D)**
- Document — Reception — night log
- Item — Power cell
- Document — Patient file — VOSS, D.
- Item — Glass bottle
- Transmission 89.1 MHz — Pell — the stranger (2 of 4)
- Item — Medkit
- Document — Morgue register
- Document — Staff hearing survey
- Document — Treatment log — Okafor, T.
- Document — Memo — S. Lind
- Item — Ceramic fuse

**The Listener** — stalk from `Z` once `c3_stalk`

**Saves** — automatic at chapter start and at story checkpoints; 1 emergency-log terminal(s) for manual saves.


---

## CHAPTER 04 — BELOW THE SURFACE

*SUBLEVEL 3 — RESIDENTIAL*

Residential quarters. Mira's note says 96.1. Something knocks on the laundry door in Mira's voice — the real Mira, on the radio, says it isn't her. She is in 1998, always at 02:43. Evelyn's apartment (the birthday code) holds the lullaby Evelyn never sang over the air. Mira gives the caretaker's code; the master key opens the shaft down.

**Objectives (in order shown to the player)**

1. Search the residential level for a way down to the power station.
1. Someone is knocking on the laundry door. Her note said: 96.1.
1. Caretaker's office — code 0309. Take the master key to the maintenance shaft at the east end.
1. Open the maintenance shaft at the east end of the corridor.
1. It's here. Hide, or run.

**Puzzles & gates**

- Keypad `QUARTERS 2 — VOSS — CODE` — code **0814**
- Door locked by item — needs **Quarters master key**
- Keypad `CARETAKER — CODE` — code **0309**
- Hidden carrier **92.3 MHz** — “92.3 — Bram's request show”
- Hidden carrier **96.1 MHz** — “Mira Solace — first contact”

**Discoveries**

- Tape — Dr. Voss — personal log (lullaby) **(Evelyn — counts toward ending D)**
- Document — Residents' directory
- Item — Power cell
- Document — Photograph
- Document — Unsent letter — M. Hale
- Item — Quarters master key
- Document — Radio club — station log
- Document — Photo on the canteen wall
- Item — Glass bottle
- Transmission 92.3 MHz — 92.3 — Bram's request show
- Document — Note on Mira's mirror
- Transmission 96.1 MHz — Mira Solace — first contact

**The Listener** — patrol from `Z` once `c4_mira`; patrol from `Z` once `c4_opened`

**Saves** — automatic at chapter start and at story checkpoints; 1 emergency-log terminal(s) for manual saves.


---

## CHAPTER 05 — THE VOICES

*SUBLEVEL 4 — POWER STATION*

The power station. A man who calls himself Marcus Hale answers on 103.7 and directs Daniel toward the uplink. A 1998 engineer's echo gives the breaker order. Main power returns and with it every voice in the wires. The Listener sees Daniel from the turbine hall gantry: first chase.

**Objectives (in order shown to the player)**

1. Cross the turbine hall to the power station control room. Stay away from the clicking.
1. Restore main power (breaker gallery) and prime the tunnel door's hydraulics (Ruiz's workshop) — in either order.
1. Power's up and the door is primed. The tunnel door is at the east end of the turbine hall.
1. Door's primed. Now the main bus — the breaker gallery is east of the control room.
1. RUN. The tunnel door — east end of the turbine hall.
1. Main power is up and the door is primed. The tunnel door is at the east end of the turbine hall.
1. Main power is up. The tunnel door's hydraulics still need priming — Ruiz's workshop, under the control room.

**Puzzles & gates**

- Door gated by story state `c5_ready` — “Tunnel door. It needs main power and primed hydraulics. It won't budge.”
- Door locked by item — needs **Hand crank**
- “Refill and prime the accumulator” — needs **Hydraulic fluid**
- Ordered switches `brk` — correct order: Close breaker C → Close breaker A → Close breaker D → Close breaker B (a mistake resets the board and makes noise)

**Discoveries**

- Tape — Dr. Voss — Run 7 **(Evelyn — counts toward ending D)**
- Document — Shaft maintenance log
- Item — Hand crank
- Item — Power cell
- Item — Medkit
- Document — Turbine fault board
- Document — Main bus restart card
- Transmission 89.1 MHz — Breaker gallery, 1998
- Tape — Ruiz — workshop
- Item — Hydraulic fluid

**The Listener** — patrol from `P` until `solved_brk`; patrol from `g` once `solved_brk`

**Saves** — automatic at chapter start and at story checkpoints; 1 emergency-log terminal(s) for manual saves.


---

## CHAPTER 06 — NO WAY BACK

*SUBLEVEL 4 — FLOOD TUNNELS*

The stairwell collapses: no way back. Flood tunnels where water doubles every footstep. Mira says Hale sealed twenty-three people behind the containment bulkhead, including her; Hale says the thing wears Mira. Valve settings painted in luminous paint are only readable on 107.9.

**Objectives (in order shown to the player)**

1. Find a way through the flood tunnels toward the Communications Centre.
1. Drain the section. The pump room is down the west passage, past the bulkhead door.
1. The floodgate in the pool room should give now.

**Puzzles & gates**

- Door gated by story state `solved_valves` — “Floodgate. The water on the far side is holding it shut. Drain the section first.”
- Door gated by story state `solved_valves` — “Office door. There's a wall of water behind it. Drain the section first.”
- 107.9-only writing: “SHE SAID NO”
- Hidden carrier **96.1 MHz** — “Mira — the bulkhead”
- 107.9-only writing: “III”
- 107.9-only writing: “I”
- 107.9-only writing: “II”
- Rotation puzzle `valves` — Turn the west valve: position 3 of 4; Turn the centre valve: position 1 of 4; Turn the east valve: position 2 of 4

**Discoveries**

- Tape — Okafor — personal
- Document — Directorate memo — liaison's briefcase
- Item — Power cell
- Document — Containment order — 02:47
- Item — Medkit
- Transmission 96.1 MHz — Mira — the bulkhead
- Document — Pump room procedure

**The Listener** — patrol from `P`

**Saves** — automatic at chapter start and at story checkpoints; 1 emergency-log terminal(s) for manual saves.


---

## CHAPTER 07 — THE SIGNAL ROOM

*SUBLEVEL 4 — COMMUNICATIONS CENTRE*

The Communications Centre. A numbers station on 99.7 and a 1998 echo give the storeroom code and the feed-horn headings. The uplink connects: Northline says Daniel has been gone nine days and the blast door is rusted shut. The Listener rides the line into Kessler's radio. 'Hale' wants the Final Experiment chamber; Mira begs him not to go.

**Objectives (in order shown to the player)**

1. Bring the uplink online: align the feed horns and find a tuning crystal.
1. The research labs are through the door at the east end of the corridor.
1. Fit a tuning crystal and bring the uplink online in the Signal Room.

**Puzzles & gates**

- Keypad `STOREROOM — CODE` — code **7225**
- Door gated by story state `c7_uplink` — “Research labs. Locked down until comms report in. Fine. Comms will report in.”
- “Bring the uplink online” — needs **Tuning crystal**
- Hidden carrier **99.7 MHz** — “99.7 — numbers”
- Hidden carrier **104.4 MHz** — “104.4 — Rami's last broadcast”
- Rotation puzzle `arr` — Turn the north feed horn: position 2 of 4; Turn the east feed horn: position 3 of 4; Turn the south feed horn: position 1 of 4

**Discoveries**

- Document — Sticky note on the storeroom shelf
- Tape — Dr. Voss — Run 18 **(Evelyn — counts toward ending D)**
- Item — Power cell
- Document — Taped to Haddad's monitor
- Transmission 89.1 MHz — Pell — the stranger (3 of 4)
- Item — Tuning crystal
- Document — Alignment card
- Transmission 99.7 MHz — 99.7 — numbers
- Transmission 104.4 MHz — 104.4 — Rami's last broadcast
- Transmission 89.1 MHz — Signal Room, 1998

**The Listener** — patrol from `P`

**Saves** — automatic at chapter start and at story checkpoints; 1 emergency-log terminal(s) for manual saves.


---

## CHAPTER 08 — THE ECHO PROJECT

*SUBLEVEL 5 — RESEARCH*

The research labs. The 1996 Project ECHO briefing: the Aperture was never a receiver. It's a door. 101.3 forecasts the Listener's next move — and is always right. Lab notes on 'Subject D', fourteen months old: it doesn't want us. It wants him.

**Objectives (in order shown to the player)**

1. Find out what HELIX-9 was for. Then find a way through to the transport line.
1. Hide. Now.
1. Find a way out of the labs. The south corridor exit needs a research keycard.
1. The transport line is through the door at the east end of the south corridor.

**Puzzles & gates**

- Keypad `COLD ROOM — CODE` — code **6024**
- Door locked by item — needs **Research keycard**
- 107.9-only writing: “COLD ROOM / 6 0 2 4”
- Rotation puzzle `proto` — Turn tap I: position 1 of 4; Turn tap II: position 3 of 4; Turn tap III: position 2 of 4

**Discoveries**

- Tape — Dr. Voss — the night before Run 19 **(Evelyn — counts toward ending D)**
- Document — Lab 2 — response trials, Subject D
- Transmission 101.3 MHz — Forecast — the lights
- Item — Research keycard
- Document — Evelyn's desk calendar
- Document — Prototype calibration card

**The Listener** — patrol from `Z` once `c8_loose`

**Saves** — automatic at chapter start and at story checkpoints; 1 emergency-log terminal(s) for manual saves.


---

## CHAPTER 09 — DEAD LINE

*SUBLEVEL 5 — TRANSPORT LINE*

The transport line. Mira sings the first line of the lullaby; Daniel finishes it without knowing how. She asks his birthday. She carried him up the lift in 1998. He is Evelyn's son. The song has now gone out over the air. 'Hale' orders him onto the tram; the chase begins.

**Objectives (in order shown to the player)**

1. Restore traction power: three switches in the right order, and a traction fuse on the platform.
1. Fuse is in. Now the traction switches: the order is on the operator's channel.
1. Get on the tram!
1. Board the tram on the platform.
1. Find a traction fuse. The depot office is off the yard.

**Puzzles & gates**

- “Fit the traction fuse” — needs **Traction fuse**
- Ordered switches `trac` — correct order: Throw the yard traction switch → Throw the booth traction switch → Throw the platform traction switch (a mistake resets the board and makes noise)

**Discoveries**

- Tape — Cross — transport
- Document — Last service manifest
- Item — Power cell
- Item — Traction fuse
- Item — Medkit
- Document — Transport booth — procedures
- Transmission 89.1 MHz — Transport, 1998

**The Listener** — patrol from `Z`

**Saves** — automatic at chapter start and at story checkpoints; 1 emergency-log terminal(s) for manual saves.


---

## CHAPTER 10 — WHAT LISTENS

*SUBLEVEL 6 — CONTAINMENT*

Containment. The Listener is invisible here except on 107.9. At the bulkhead, two Miras — one through the steel, one on 96.1 — both know the song now. 'Hale' urges Daniel to open it. Whatever Daniel chooses, the Listener speaks the words he heard on Harrow Pass three years ago: *Hold them. Don't send them up yet.* It has been talking to him all his life.

**Objectives (in order shown to the player)**

1. Find the containment bulkhead.
1. The bulkhead. Someone is behind it. The console is in the middle of the hall.
1. Decide. The bulkhead release is beside the intercom.
1. The archive lift is past the security post, south of the hall.

**Puzzles & gates**

- Door locked by item — needs **Hale's security badge**
- Door gated by story state `c10_choice` — “Archive lift corridor. Interlocked until the bulkhead cycle completes.”

**Discoveries**

- Tape — Dr. Voss — the rule **(Evelyn — counts toward ending D)**
- Item — Hale's security badge
- Document — Bulkhead log
- Document — Containment roll call — 02:49

**The Listener** — patrol from `Z` once `c10_choice`. **Cloaked**: visible only on 107.9 or at arm's length.

**Saves** — automatic at chapter start and at story checkpoints; 1 emergency-log terminal(s) for manual saves.


---

## CHAPTER 11 — EVERY VOICE EVER LOST

*SUBLEVEL 7 — THE ARCHIVE*

The Archive. Ines Duarte's sealed statement explains how a baby called Daniel left the mountain. Hale's real last tape: if you hear me on the radio after tonight, it isn't me — do the opposite. The 'Hale' on 103.7 answers in Daniel's voice. In the Director's vault: Evelyn's goodbye to her son, and the shutdown key.

**Objectives (in order shown to the player)**

1. Find the archive keycard for the deep lift. Look for the vaults.
1. Take the deep lift at the east end of the stacks.

**Puzzles & gates**

- 107.9-only writing: “BOX 19 / STACK E — ROW 3”
- Door locked by item — needs **Archive keycard**
- Keypad `VAULT D — DIRECTOR — CODE` — code **0243**
- Keypad `VAULT S — SECURITY — CODE` — code **5119**
- 107.9-only writing: “VAULT S / HALE, M.  —  5 1 1 9”

**Discoveries**

- Transmission 89.1 MHz — Pell — the forty-second
- Tape — Dr. Voss — for Daniel **(Evelyn — counts toward ending D)**
- Document — Sealed statement — Cpl. I. Duarte
- Document — Taped to the Director's vault
- Tape — Marcus Hale — last report
- Transmission 89.1 MHz — Pell — the stranger (4 of 4)
- Item — Archive keycard
- Document — Archive index card
- Item — Dr. Voss's shutdown key

**The Listener** — ambush from `Z`

**Saves** — automatic at chapter start and at story checkpoints; 1 emergency-log terminal(s) for manual saves.


---

## CHAPTER 12 — 02:43

*THE APERTURE LEVEL*

The Aperture ring. Three emitters replay the last eight minutes of 1998. At the chamber the Listener speaks with every voice it owns — and with Daniel's warning. Daniel switches off the radio: it can only hear now. He walks past it in silence.

**Objectives (in order shown to the player)**

1. Start the three emitters around the ring.
1. Get past it to the inner seal at the north wall. Silently.
1. The chamber door on the south side of the ring is open.

**Puzzles & gates**

- Door gated by story state `c12_all` — “The chamber seal. All three emitters have to be live.”

**The Listener** — patrol from `P` until `c12_all`

**Saves** — automatic at chapter start and at story checkpoints; 1 emergency-log terminal(s) for manual saves.


---

## CHAPTER 13 — THE LAST TRANSMISSION

*OCTOBER 17 — 02:43*

The Door. Mira beside him, twenty-eight years to the left. Evelyn at the seal in 1998. The Listener in his mother's voice. One switch, three positions: open, silence, answer.

**Objectives (in order shown to the player)**

1. The Aperture console.

**The Listener** — scripted appearances only

**Saves** — automatic at chapter start and at story checkpoints; 0 emergency-log terminal(s) for manual saves.

