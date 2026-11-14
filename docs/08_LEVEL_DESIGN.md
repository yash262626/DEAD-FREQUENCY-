# DEAD FREQUENCY — Level Design

Every level is authored as an ASCII grid (one character = 2 × 2 m cell) plus a legend, in `game/data/chNN.gd`. At load the engine builds walls/floors/ceilings with triplanar PBR materials, places props and lights, bakes an A* navigation grid for the Listener (locked doors and blocking props disabled), and auto-dresses corridors with pipe runs and debris. The layout test (`tools/test.sh layout`) proves no prop ever blocks a passage; the walkthrough test proves every step is reachable.

Built-in symbols: `S` player start, `L` ceiling light, `F` flickering light, `R` red emergency light, `P` Listener patrol point, `H` hiding locker, `V` emergency-log terminal (save), `D` door, `#` wall, `.` floor.


---

## PROLOGUE — OCTOBER 17, 1998

Palette: **comms** · ceiling height palette default · grid 22×6 cells (44×12 m)

```
######################
#S.L.m..1.#4...R...5.#
#.n.c.o...D..........#
#.....e...#.k.k....g.#
#.3..L..2.#........x.#
######################
```
Legend: `1` marker (camera / spawn point) · `2` marker (camera / spawn point) · `3` marker (camera / spawn point) · `4` marker (camera / spawn point) · `5` marker (camera / spawn point) · `c` prop: console · `e` npc · `g` prop: glass · `k` npc · `m` prop: monitor · `n` npc · `o` npc · `x` prop: shade


---

## CHAPTER 01 — THE ARRIVAL

Palette: **entrance** · ceiling height palette default · grid 30×18 cells (60×36 m) · starts unpowered (emergency lighting only)

```
##############################
#S...t#a.c.V#H.H.b#....o######
#.....D.....D.....D.....######
#..A..#..R..#..i..#..R..######
#.....#.....#...x.#.....######
###D######E###################
#....#..........F.........w..#
#.j..#......1.........y...2..#
#.A..########K########C#######
#.k..#######...n.#####....m.##
############.L...#####.L..3.##
############..T.h#####.r....##
############.....#####......##
##############W###############
##########..f..f..f.#.L.######
##########.L...q....Q.u.######
##########.H......e.#.b.######
##############################
```
Legend: `1` Trigger `1` · `2` marker (camera / spawn point) · `3` marker (camera / spawn point) · `A` light (always on) · `C` Door · `E` Door · `K` Door · `Q` Door · `T` Tape — “Security log — Hale, Oct 12 1998” · `W` Door · `a` Document — “Gate Log — Oct 16, 1998” · `b` Pickup — Power cell · `c` prop: console · `e` Pickup — Medkit · `f` prop: coat · `h` Pickup — Comms annex keycard · `i` Pickup — HX-7 field receiver · `j` Pickup — Ceramic fuse · `k` Pickup — Glass bottle · `m` prop: monitor · `n` Document — “Memo — M. Hale, Chief of Security” · `o` Interaction — “Fit fuse and start generator” · `q` Document — “Lost property — security” · `r` Interaction — “Press PLAY” · `t` Document — “Work Order NR-2026-1017” · `u` Document — “A child's mitten” · `w` Trigger `w` · `x` Radio 89.1 MHz — “Gate post, 1998” · `y` marker (camera / spawn point)


---

## CHAPTER 02 — THE SILENT WING

Palette: **security** · ceiling height palette default · grid 30×22 cells (60×44 m)

```
##############################
#....#.......................#
#.S..D..d...d...d...d....L...#
#....#.......................#
#.L..#..c.......c.........H..#
#.t..#...L.......L.......1...#
#....#.......................#
###########.#######gggg#######
###########.#######.z..#######
###########.#######..k.#######
#.........#w#######.L..#######
#..r..L...D.D.....G....#######
#.....y...#.#######....#######
#...H.....#.#######V...#######
######.####.##################
#.e...P.....L.....P....H.....#
#.......b.Z.......F......m...M
#####K########################
#....L....d.##################
#.q.......U.##################
#.H.....n...##################
##############################
```
Legend: `1` Trigger `1` · `G` Door · `K` Door · `M` Door · `U` Interaction — “Okafor's desk drawer” · `Z` marker (camera / spawn point) · `b` Pickup — Glass bottle · `c` prop: coat · `d` prop: desk · `e` Pickup — Power cell · `g` prop: glass (blocks navigation) · `k` Pickup — Medical wing keycard · `m` Pickup — Medkit · `n` Document — “Photo on Okafor's desk” · `q` Radio 89.1 MHz — “Okafor's office, 1998” · `r` Document — “Night shift roster” · `t` Document — “Annex duty sheet” · `w` Trigger `w` · `y` Radio 89.1 MHz — “Records, 1998” · `z` marker (camera / spawn point)


---

## CHAPTER 03 — WHAT REMAINS

Palette: **medical** · ceiling height palette default · grid 34×22 cells (68×44 m)

```
##################################
#......#.........#.......#.......#
#..S...#.b..b..b.#..f....#..T....#
#......#.........#.......#......j#
#..a...#.b..b..b.#..L..H.#....L..#
#...L..#.....L...#.......#..t....#
#......#.........#....q..#.......#
###D#######D#########D#######D####
#....L......P.....1......L.....PY#
#......g....w....x.....p.........#
######C######E#########Q##########
#.......#.........#..........#####
#..L....#..u.Z.u..#....z.....#####
#...m...#....L....#..........#####
#..m..H.#..s......#..L.....n.#####
#.......#.......V.#..........#####
#.....e.#...h.J...#..o.......#####
#############X####################
#########.b..L..H.################
#########.......N.################
#########.m.......################
##################################
```
Legend: `1` Trigger `1` · `C` Door · `E` Door · `J` 107.9 writing · `N` Tape — “Brandt — quarantine” · `Q` Door · `T` Tape — “Dr. Voss — hearing assessment” · `X` Door · `Y` Interaction — “Fit fuse and call the service lift” · `Z` marker (camera / spawn point) · `a` Document — “Reception — night log” · `b` prop: bed · `e` Pickup — Power cell · `f` Document — “Patient file — VOSS, D.” · `g` 107.9 writing · `h` Pickup — Glass bottle · `j` 107.9 writing · `m` Pickup — Medkit · `n` Document — “Morgue register” · `o` prop: coat · `p` Pressure plate · `q` Document — “Staff hearing survey” · `s` Document — “Treatment log — Okafor, T.” · `t` Document — “Memo — S. Lind” · `u` prop: gurney · `w` Trigger `w` · `x` physics crate · `z` Pickup — Ceramic fuse


---

## CHAPTER 04 — BELOW THE SURFACE

Palette: **residential** · ceiling height palette default · grid 32×21 cells (64×42 m)

```
################################
#.....#......#.......#.........#
#..S..#..b...#..b..c.#..b......#
#.....#......#.......#.....Z...#
#..L..#...L..#...L...#...L.....#
#..d..#..t...#.f..T..#.h....q..#
##D#####A#######B#######E#######
#..............................#
#..L.....P.......L........P..L.#
#...........2.....y............#
####K#######O######W#######M####
#......#.........#......#......#
#..X...#..k..L...#..p...#..L...#
#......#.........#......#......#
#..o...#...V.....#..L...#..H...#
#......#..e......#....H.#....Y.#
####################G###########
#################...L....#######
#################.x.....U#######
#################.n...r..#######
################################
```
Legend: `2` Trigger `2` · `A` Door · `B` Door · `E` Door · `G` Door · `K` Door · `M` Door · `O` Door · `T` Tape — “Dr. Voss — personal log (lullaby)” · `U` Interaction — “Club cabinet” · `W` Door · `X` prop: recorder · `Y` Interaction — “Climb down the maintenance shaft” · `Z` marker (camera / spawn point) · `b` prop: bed · `c` prop: crib · `d` Document — “Residents' directory” · `e` Pickup — Power cell · `f` Document — “Photograph” · `h` Document — “Unsent letter — M. Hale” · `k` Pickup — Quarters master key · `n` Document — “Radio club — station log” · `o` prop: coat · `p` Document — “Photo on the canteen wall” · `q` Pickup — Glass bottle · `r` Radio 92.3 MHz — “92.3 — Bram's request show” · `t` Document — “Note on Mira's mirror” · `x` prop: console · `y` Radio 96.1 MHz — “Mira Solace — first contact”


---

## CHAPTER 05 — THE VOICES

Palette: **power** · ceiling height palette default · grid 30×19 cells (60×38 m) · starts unpowered (emergency lighting only)

```
##############################
#....#.......................#
#.S..D...u.....u.....u.......#
#....#.g....L...........L....#
#.A..#..A....P....A....P..A..M
#....#.......................#
#...a#...u.....u..y..u.......#
##.###.......w...............#
#....########D################
#.e..#.........#.H...........#
#....#..1..A...#..q..A...r...#
#..H.#.........D.............#
#c...#..T..V...#.............#
#.F..#.........#..i..j..k..l.#
##########O###################
######...U.....###############
######.b...L.n.###############
######.x.....m.###############
##############################
```
Legend: `1` Trigger `1` · `A` light (always on) · `M` Door · `O` Door · `T` Tape — “Dr. Voss — Run 7” · `U` Interaction — “Refill and prime the accumulator” · `a` Document — “Shaft maintenance log” · `b` prop: table · `c` Pickup — Hand crank · `e` Pickup — Power cell · `g` marker (camera / spawn point) · `i` Interaction — “Close breaker A” · `j` Interaction — “Close breaker B” · `k` Interaction — “Close breaker C” · `l` Interaction — “Close breaker D” · `m` Pickup — Medkit · `n` Document — “Turbine fault board” · `q` Document — “Main bus restart card” · `r` Radio 89.1 MHz — “Breaker gallery, 1998” · `u` prop: turbine · `w` Trigger `w` · `x` Tape — “Ruiz — workshop” · `y` Pickup — Hydraulic fluid


---

## CHAPTER 06 — NO WAY BACK

Palette: **flooded** · ceiling height palette default · grid 30×15 cells (60×30 m)

```
##############################
#...#.........#######.......Y#
B.S.D....A....#.....#..T..L..#
#...#.........#..m..#........#
#####........n#..P..#....H...#
#...#####.#####.....#........#
#.e.#####.#####..A..##.#######
#.H.D.....D.........#..q.....#
#...#####.#####.....G..h..P..#
#####.....###########........#
#H.......V#........###########
#....A....#..L...g.###########
#.x..y..z.W.......b###########
#.u..v..w.#..k.....###########
##############################
```
Legend: `A` light (always on) · `B` Door · `G` Door · `T` Tape — “Okafor — personal” · `W` Door · `Y` Interaction — “Climb toward the Communications Centre” · `b` Document — “Directorate memo — liaison's briefcase” · `e` Pickup — Power cell · `g` 107.9 writing · `h` Document — “Containment order — 02:47” · `k` Pickup — Medkit · `m` Radio 96.1 MHz — “Mira — the bulkhead” · `n` Document — “Pump room procedure” · `q` Trigger `q` · `u` Interaction — “Turn the west valve” · `v` Interaction — “Turn the centre valve” · `w` Interaction — “Turn the east valve” · `x` 107.9 writing · `y` 107.9 writing · `z` 107.9 writing


---

## CHAPTER 07 — THE SIGNAL ROOM

Palette: **comms** · ceiling height palette default · grid 30×15 cells (60×30 m)

```
##############################
#....#.............#.........#
#.S..#..c...c...c..#..T...L..#
#....#.....L.......#.........#
#.L..#..x...U...c..#..n......#
##D#######D#############D#####
#....L......P.......L....P...M
######D#########K#######D#####
#............#......#........#
#..a....b....#..k...#..h.....#
#............#......#....r...#
#.....g......#..V...#..L.....#
#..L.........#.e..N.#.....H..#
#............#......#...w....#
##############################
```
Legend: `K` Door · `M` Door · `N` Document — “Sticky note on the storeroom shelf” · `T` Tape — “Dr. Voss — Run 18” · `U` Interaction — “Bring the uplink online” · `a` Interaction — “Turn the north feed horn” · `b` Interaction — “Turn the east feed horn” · `c` prop: console · `e` Pickup — Power cell · `g` Interaction — “Turn the south feed horn” · `h` Document — “Taped to Haddad's monitor” · `k` Pickup — Tuning crystal · `n` Document — “Alignment card” · `r` Radio 99.7 MHz — “99.7 — numbers” · `w` Radio 104.4 MHz — “104.4 — Rami's last broadcast” · `x` Radio 89.1 MHz — “Signal Room, 1998”


---

## CHAPTER 08 — THE ECHO PROJECT

Palette: **lab** · ceiling height palette default · grid 32×19 cells (64×38 m)

```
################################
#....#.................#.......#
#.S..D..u...u...u...L..D..T..L.#
#.L..#.................#..n....#
######..u...u...u...H..#.......#
#....#.........1.......#########
#.m..#..u...u...u...f..#.......#
#....D...........L.....D..d....#
#.L..#..H..............#.c.....#
#v...#.................#.......#
##########D#####################
#....C.....g..........Z...P....M
#.k..#######################.###
#..V.#######################.###
############################Q###
##################.....L.....###
##################.a..o..b..e###
##################.p.........###
################################
```
Legend: `1` Trigger `1` · `C` Door · `M` Door · `Q` Door · `T` Tape — “Dr. Voss — the night before Run 19” · `Z` marker (camera / spawn point) · `a` Interaction — “Turn tap I” · `b` Interaction — “Turn tap II” · `c` prop: crib · `d` Document — “Lab 2 — response trials, Subject D” · `e` Interaction — “Turn tap III” · `f` Radio 101.3 MHz — “Forecast — the lights” · `g` 107.9 writing · `k` Pickup — Research keycard · `m` Interaction — “Play the briefing reel” · `n` Document — “Evelyn's desk calendar” · `o` prop: dish · `p` Document — “Prototype calibration card” · `u` prop: tank · `v` marker (camera / spawn point)


---

## CHAPTER 09 — DEAD LINE

Palette: **transport** · ceiling height palette default · grid 32×17 cells (64×34 m)

```
################################
#n..V#.......L.......L..q...p..#
#.S..D...........R...m.........#
#b...#.........................#
#....#.........Y...............#
###D#######################D####
#..............................#
#..x...x......L.......x......o.#
#H...............Z.............#
#..e...x..............x...L....#
#..............................#
#........P...y.............P...#
################O###############
##############..L.....##########
##############.a...T..##########
##############.f...k..##########
################################
```
Legend: `O` Door · `R` Trigger `R` · `T` Tape — “Cross — transport” · `Y` Interaction — “Start the tram” · `Z` marker (camera / spawn point) · `a` Document — “Last service manifest” · `b` Interaction — “Throw the booth traction switch” · `e` Pickup — Power cell · `f` Pickup — Traction fuse · `k` Pickup — Medkit · `m` 107.9 writing · `n` Document — “Transport booth — procedures” · `o` Radio 89.1 MHz — “Transport, 1998” · `p` Interaction — “Throw the platform traction switch” · `q` Interaction — “Fit the traction fuse” · `x` prop: crate · `y` Interaction — “Throw the yard traction switch”


---

## CHAPTER 10 — WHAT LISTENS

Palette: **containment** · ceiling height palette default · grid 32×13 cells (64×26 m)

```
################################
#.....#......#.........g.......#
#.S...D.o.o..D.1.L.....K...x...#
#..L..#o..o..#.........g..o....#
#.....##D#####..Q.U....#.......#
#######......#.........#....R..#
#######..T...#......R..#...o...#
#######.L..H.#.........#.......#
#######......#####D#############
#########N####b.......n#########
##.h.h.h.L..##V...Z....W.......M
##.r.h.h.h..##.....L...#########
################################
```
Legend: `1` Trigger `1` · `K` Door · `M` Door · `N` Door · `Q` Interaction — “Bulkhead release” · `T` Tape — “Dr. Voss — the rule” · `U` Interaction — “Bulkhead intercom” · `W` Door · `Z` marker (camera / spawn point) · `b` Pickup — Hale's security badge · `g` prop: glass (blocks navigation) · `h` 107.9 writing · `n` Document — “Bulkhead log” · `o` prop: coat · `r` Document — “Containment roll call — 02:49” · `x` marker (camera / spawn point)


---

## CHAPTER 11 — EVERY VOICE EVER LOST

Palette: **archive** · ceiling height palette default · grid 32×15 cells (64×30 m)

```
################################
#....#........G#......#........#
#.S..D...n.....#..h...#..T..s..#
#....#....L....#..L...#...L....#
#.L..#.......V.#......#........#
#....#..d...e..#......#........#
######D###########Y#######Q#####
#................g.............#
#.zzzz.zzzz.zzzz.zzzz.zzzz..H..#
#....P.........Z........P......#
#.zzzz.zzzz.zzzz.zzzz.zzzz..L..M
#..............................#
#.zzzz.zzzz.zzzz.zzzz.zBzz.k...#
#H.......L..........L..........#
################################
```
Legend: `B` Interaction — “Search the shelf — Box 19” · `G` 107.9 writing · `M` Door · `Q` Door · `T` Tape — “Dr. Voss — for Daniel” · `Y` Door · `Z` marker (camera / spawn point) · `d` Document — “Sealed statement — Cpl. I. Duarte” · `e` Document — “Taped to the Director's vault” · `g` 107.9 writing · `h` Tape — “Marcus Hale — last report” · `k` Pickup — Archive keycard · `n` Document — “Archive index card” · `s` Pickup — Dr. Voss's shutdown key · `z` prop: shelf (blocks navigation)


---

## CHAPTER 12 — 02:43

Palette: **chamber** · ceiling height palette default · grid 32×17 cells (64×34 m)

```
################################
#a......L......L.......L......b#
#..............................#
#..##########################..#
#..#...........M............#..#
#..#.....L..........L.......#..#
#L.#.........x..............#.L#
#..#....h.............h.....#..#
#..#.....R..........R.......#..#
#w.#...........f............#..#
#..#.......h.......h........#..#
#..############G#############..#
#..............................#
#.......L......R.......L.......#
#.......P......S.......H......c#
#V.............................#
################################
```
Legend: `G` Door · `M` Interaction — “Release the inner seal” · `a` Interaction — “Start the west emitter” · `b` Interaction — “Start the east emitter” · `c` Interaction — “Start the south emitter” · `f` Trigger `f` · `h` 107.9 writing · `w` Interaction — “Operator's log terminal” · `x` marker (camera / spawn point)


---

## CHAPTER 13 — THE LAST TRANSMISSION

Palette: **chamber** · ceiling height 7.5 · grid 24×14 cells (48×28 m)

```
########################
#......................#
#..........A...........#
#..o..............o....#
#.....x....B...........#
#..R................R..#
#..o.......L.......o...#
#........m...e.........#
#..........U...........#
#......................#
#..o................o..#
#..........S...........#
#......................#
########################
```
Legend: `A` prop: aperture · `B` light (always on) · `R` light red · `U` Interaction — “The Aperture console” · `e` 107.9 writing · `m` 107.9 writing · `o` 107.9 writing · `x` marker (camera / spawn point)

