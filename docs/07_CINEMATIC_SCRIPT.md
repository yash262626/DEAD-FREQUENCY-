# DEAD FREQUENCY — Cinematic Script

*Generated from the game's event data by `tools/gen_docs.py`. Every cinematic below is implemented in-engine (Godot 3.5) with the event runner in `game/scripts/level.gd`: camera dollies between map markers, positional sound, lighting cues, subtitles and hold-to-skip. Marker letters refer to the chapter maps in 08_LEVEL_DESIGN.md.*

Shared presentation rules: 55° cinematic FOV; filmic tonemapping, glow, SSAO (High+), volumetric-style depth fog per area palette; letterbox-free (subtitles bottom-centre); every cinematic is skippable by holding SPACE / (A) for 0.8 s and never longer than ~3 minutes.


---

## PROLOGUE — OCTOBER 17, 1998

### Opening sequence

*[hide_ent x]*
*EXTERIOR — storm*
*AMBIENCE — loop rain*
*(beat — 2.5s)*
*SFX — thunder*
*(beat — 3s)*
*AMBIENCE — loop static*
*(beat — 1.5s)*
*CARD — OCTOBER 17, 1998 — 02:43 AM*
*CAMERA — from `@air1` looking at `@gate` (cut)*
*FADE IN (2.5s)*
*MUSIC — drone_a*
*CAMERA — from `@air1` looking at `@gate`, dolly to `@air2` over 9s*
*SFX — thunder*
**EVELYN (RECORDING)** — Project log. Doctor Evelyn Voss, director, HELIX-9. Nineteenth consecutive night on the carrier.
*CAMERA — from `@road1` looking at `@mast`, dolly to `@road2` over 6s*
**EVELYN (RECORDING)** — We built this place to listen. I think I finally understand what that costs.
*FADE TO BLACK (0.6s)*
*AMBIENCE — stop static*
*AMBIENCE — loop hum*
*CAMERA — from `3` looking at `c` (cut)*
*FADE IN (0.8s)*
*CAMERA — from `3` looking at `c`, dolly to `2` over 5s*
**OKAFOR** — Carrier's holding at one-oh-seven point nine. Doctor… it's answering.
**EVELYN** — It can't answer. We haven't sent anything.
**OKAFOR** — Then who is it talking to?
*CAMERA — from `1` looking at `m` over 3.5s*
*SFX — glitch*
*MONITOR — types out: CARRIER LOCK  107.9 MHz / INBOUND TRANSMISSION / ORIGIN: UNRESOLVED / TIMESTAMP: 17 OCT 2026*
**EVELYN** — Twenty twenty-six. That's not a fault, Tunde. That's a date.
*LIGHTS — power dies; red emergency lamps pulse*
*AMBIENCE — loop alarm*
*MUSIC — drone_b*
*CAMERA — from `4` looking at `k`, dolly to `5` over 4s*
*[move k#1 5 3.2]*
*[move k#2 4 2.6]*
*SFX — step (positional, at `k`)*
*SFX — step (positional, at `4`)*
**PA** — Attention. Containment fault, sublevel four. All personnel remain at your stations.
*[move n 2 4]*
**MARCUS (RADIO)** — Hale to all posts. Seal the lower levels. Nobody opens the Door. Nobody.
*CAMERA — from `2` looking at `e` over 4s*
**EVELYN** — Mayday, mayday. This is HELIX-9 to any station. Can anyone hear me?
**EVELYN** — We opened it. We opened it, and something heard us.
**MIRA** — Doctor Voss — the lift's still running. Come with us. Please.
**EVELYN** — Take him, Mira. Take him up to the surface and do not look back.
**MIRA** — I'm not leaving you down here—
**EVELYN** — Go!
*CAMERA — from `5` looking at `g` (cut)*
*AMBIENCE — stop cine*
*MUSIC — silence*
*(beat — 1.2s)*
*[show_ent x]*
*SFX — clicks*
*CAMERA — from `5` looking at `g` over 3.2s*
*[hide_ent x]*
*SFX — glitch*
*AMBIENCE — loop static*
**DANIEL? (STATIC)** — …whatever happens… do not open the door.
**EVELYN** — Who is this? Identify yourself. Who is on this channel?
*SFX — power_down*
*FADE TO BLACK (0.15s)*
*AMBIENCE — stop static*
*(beat — 3.5s)*
*SFX — whisper*
**VOICE** — Can anyone hear me?
*(beat — 2s)*
*TITLE — DEAD FREQUENCY (glitch reveal, bass impact); tagline: HELIX-9 HAS BEEN SILENT FOR TWENTY-EIGHT YEARS*
*→ MAIN MENU*


---

## CHAPTER 01 — THE ARRIVAL

### Opening sequence

*CAMERA — from `@far` looking at `@gate` (cut)*
*AMBIENCE — loop rain*
*CAMERA — from `@far` looking at `@gate`, dolly to `@road1` over 7s*
**DISPATCH (KESSLER)** — Northline to Arlen. You at the gate yet?
**DANIEL** — At the gate. Snow gave up about a mile back. Now it's just rain.
**DISPATCH (KESSLER)** — Beacon's still pinging. Same message every ninety seconds, three weeks running.
**DANIEL** — Read it to me.
*CAMERA — from `@road2` looking at `@door`, dolly to `@truck` over 6s*
**DISPATCH (KESSLER)** — 'Request communications technician. Arlen, Daniel.' Over and over. Your name, Danny. From a box nobody's touched since nineteen ninety-eight.
**DANIEL** — Somebody typed my name into a database once, and the database got lonely. That's all it is.
**DISPATCH (KESSLER)** — That's what I keep telling myself. Four hours, Danny. Check in on the hour.
**DANIEL** — On the hour.
*CAMERA — from `@low` looking at `@door`, dolly to `@road2` over 5s*
*SFX — thunder*
**DANIEL** — ...The blast door's open. Nobody said the blast door would be open.
*FADE TO BLACK (1.2s)*
*AMBIENCE — stop cine*
*CAMERA — return to Daniel's eyes*
*SFX — door*
*(beat — 1s)*
*FADE IN (1.5s)*
**DANIEL** — Twenty-eight years of dust, and the emergency lamps still think someone's coming home.
**DANIEL** — Right. Power, uplink, records, out. Four hours, and I'm back above the snow line.
*HINT — WASD move · Shift sprint · Ctrl crouch · Q/E lean · T flashlight · F interact · Tab journal*
*OBJECTIVE — Restore auxiliary power. The generator is past the checkpoint.*

### Trigger `w`

*— cinematic begins (player control locked, subtitles, skip enabled) —*
*RADIO — the receiver switches itself on, 101.3 MHz*
*SFX — glitch*
*(beat — 1s)*
**DANIEL? (101.3 MHz)** — Daniel…
**DANIEL** — Who is this? This channel is — who's transmitting?
**DANIEL? (101.3 MHz)** — Daniel. Whatever happens. Do not open the door.
**DANIEL** — That's my voice.
*(beat — 1.2s)*
**DANIEL** — That is my voice.
*RADIO — off*
*— control returns to the player —*
*JOURNAL — "101.3 MHz — the warning"*
*OBJECTIVE — Find a way into the communications annex.*

### Interaction — “Press PLAY”

*— cinematic begins (player control locked, subtitles, skip enabled) —*
*MUSIC — silence*
*SFX — click*
*AMBIENCE — loop static*
*(beat — 1.5s)*
**VOICE (TAPE)** — Daniel… if you are hearing this, it means the signal has already found you.
*(beat — 0.8s)*
*RADIO — the receiver switches itself on, 101.3 MHz*
*(beat — 0.6s)*
**DANIEL? (RADIO)** — You shouldn't have come here.
*RADIO — off*
*AMBIENCE — stop static*
*LIGHTS — power dies; red emergency lamps pulse*
*(beat — 1.6s)*
*SFX — step (positional, at `C`)*
*(beat — 0.7s)*
*SFX — step (positional, at `C`)*
*(beat — 0.6s)*
*SFX — step (positional, at `y`)*
*(beat — 0.5s)*
*Daniel turns to look at `C`*
*(beat — 1.4s)*
**DANIEL** — …Hello?
*(beat — 3s)*
*SFX — glitch*
*SFX — static*
*CAMERA SHAKE*
*CAMERA — from `3` looking at `m` over 3s*
*MONITOR — types out: SIGNAL IDENTIFIED / SUBJECT: DANIEL ARLEN / STATUS: ALREADY INSIDE*
*FADE TO BLACK (0.05s)*
*ACHIEVEMENT — Already Inside — reach the communications annex*
*TITLE — DEAD FREQUENCY (glitch reveal, bass impact)*
*→ NEXT CHAPTER*


---

## CHAPTER 02 — THE SILENT WING

### Trigger `1`

*— cinematic begins (player control locked, subtitles, skip enabled) —*
*MUSIC — silence*
*THE LISTENER — spawn at `z` (watch)*
*SFX — voice (positional, at `z`)*
*Daniel turns to look at `z`*
*(beat — 1s)*
**DANIEL** — (whispering) There's somebody in the supervisor's office.
*CAMERA — from `1` looking at `z` over 4s*
*SFX — clicks (positional, at `z`)*
*(beat — 1.2s)*
**DANIEL** — Hello? I'm with Northline Recovery. Are you hurt?
*(beat — 1.5s)*
*THE LISTENER — face*
*SFX — glitch*
*CAMERA — from `1` looking at `z`, dolly to `g` over 3s*
*(beat — 1.5s)*
**LISTENER (DANIEL'S VOICE)** — Hello? I'm with Northline Recovery. Are you hurt?
*(beat — 0.8s)*
*LIGHTS — power dies; red emergency lamps pulse*
*SFX — screech (positional, at `z`)*
*(beat — 1.4s)*
*THE LISTENER — despawn*
*(beat — 0.6s)*
*LIGHTS — power on*
*CAMERA — return to Daniel's eyes*
**DANIEL** — It said what I said. In my voice. It said it back to me.
**DANIEL** — Okay. Okay. Don't breathe, Arlen. Don't you breathe.
*ACHIEVEMENT — It Has No Face — survive the first sighting*
*(story flag `c2_loose`)*
*THE LISTENER — spawn at `Z` (patrol)*
*MUSIC — drone_b*
*HINT — 94.6 MHz — PROXIMITY. Faster beeps: closer. A sharper tone: you are facing it.*
*HINT — Lockers hide you. If it watches you get in, the locker is not a hiding place.*
*OBJECTIVE — Get into the supervisor's office. The records room might know the door code.*
*— control returns to the player —*

### Door

*— cinematic begins (player control locked, subtitles, skip enabled) —*
**PA** — Medical wing. Please have your pass ready.
**DANIEL** — Pass is ready.
**PA** — Thank you. Welcome back, Daniel.
**DANIEL** — ...I didn't tell it my name. I never told it my name.
*FADE TO BLACK (1.5s)*
*→ NEXT CHAPTER*


---

## CHAPTER 03 — WHAT REMAINS

### Tape — “Dr. Voss — hearing assessment”

*— cinematic begins (player control locked, subtitles, skip enabled) —*
*CAMERA — from `t` looking at `T`, dolly to `j` over 5s*
**EVELYN (TAPE)** — Assessment six. Doctor Lind present. Subject is my son, so you can strike 'subject' from the record, Sara.
**LIND (TAPE)** — Evelyn, I'm going to say this once, on tape, so it exists. Take him off the mountain.
**EVELYN (TAPE)** — He sleeps down here. Do you understand what that means to me? Nowhere else does he sleep.
**LIND (TAPE)** — He sleeps because it sings to him. He turns toward it like a flower. That isn't sleep. That's listening.
**EVELYN (TAPE)** — ...Then he's the first person on this site who isn't afraid of it.
**LIND (TAPE)** — That's what frightens me.
*SFX — click*
*CAMERA — return to Daniel's eyes*
*— control returns to the player —*
**DANIEL** — Voss. Doctor Evelyn Voss. The director.
**DANIEL** — She brought her kid down here. Into this.
*(beat — 1s)*
*RADIO — the receiver switches itself on, 107.9 MHz*
*SFX — glitch*
**DANIEL** — The set's drifting on its own— hundred and seven point nine.
*(beat — 1.5s)*
**DANIEL** — There's writing on the wall. There's— that wasn't there a second ago.
*HINT — 107.9 MHz — UNSEEN. Shows what hides. It is the loudest band: it carries further than any other.*
*(beat — 2s)*
*RADIO — off*
*OBJECTIVE — Find a way down. The service lift is at the east end of the corridor.*

### Interaction — “Fit fuse and call the service lift”

*— cinematic begins (player control locked, subtitles, skip enabled) —*
*SFX — power_up*
**DANIEL** — Fuse is seated. Come on, come on...
*SFX — tram (positional, at `Y`)*
*(beat — 2s)*
*SFX — door (positional, at `Y`)*
**DANIEL** — Residential. Sublevel three. Somewhere the lights might still be on.
*THE LISTENER — despawn*
*FADE TO BLACK (1s)*
*AMBIENCE — loop tram*
*(beat — 2s)*
*RADIO — the receiver switches itself on, 96.1 MHz*
*SFX — whisper*
**MIRA? (96.1 MHz)** — (humming, very faint — a lullaby, four slow notes and a fall)
**DANIEL** — I know that tune.
**DANIEL** — ...Why do I know that tune?
*RADIO — off*
*AMBIENCE — stop cine*
*→ NEXT CHAPTER*


---

## CHAPTER 04 — BELOW THE SURFACE

### Interaction — “Climb down the maintenance shaft”

*— cinematic begins (player control locked, subtitles, skip enabled) —*
*SFX — metal*
**DANIEL** — Power station. Forty metres of ladder.
**DANIEL** — Don't look down, Arlen. There's nothing down there you want to see first.
*FADE TO BLACK (1.5s)*
*→ NEXT CHAPTER*

### Door

*— cinematic begins (player control locked, subtitles, skip enabled) —*
*SFX — stop knock*
*(story flag `c4_opened`)*
*(beat — 0.6s)*
**MIRA? (TAPE)** — Daniel? Daniel, it's Mira. I'm in the laundry. Open the door.
*Daniel turns to look at `X`*
**DANIEL** — A tape deck. A cassette deck on the floor, playing her voice into the door.
**DANIEL** — ...Who pressed play?
*SFX — screech*
*CAMERA SHAKE*
*THE LISTENER — spawn at `2` (hunt)*
*— control returns to the player —*
*OBJECTIVE — It's here. Hide, or run.*


---

## CHAPTER 05 — THE VOICES

### Trigger `w`

*— cinematic begins (player control locked, subtitles, skip enabled) —*
*THE LISTENER — spawn at `g` (watch)*
*Daniel turns to look at `g`*
*CAMERA — from `w` looking at `g` over 2.5s*
**DANIEL** — Oh no.
*THE LISTENER — face*
*SFX — screech (positional, at `g`)*
*CAMERA SHAKE*
*(beat — 1.2s)*
**DANIEL** — No, no, no — it saw me — it SAW me—
*CAMERA — return to Daniel's eyes*
*THE LISTENER — hunt*
*— control returns to the player —*
*OBJECTIVE — RUN. The tunnel door — east end of the turbine hall.*

### Door

*— cinematic begins (player control locked, subtitles, skip enabled) —*
*SFX — door*
**DANIEL** — Through — through — shut it, SHUT IT—
*SFX — impact*
*CAMERA SHAKE*
*(beat — 1s)*
**DANIEL** — ...It stopped. It stopped at the door.
**DANIEL** — It doesn't need doors. Why did it stop at the door?
*FADE TO BLACK (1.5s)*
*→ NEXT CHAPTER*

### Puzzle solved — brk

*— cinematic begins (player control locked, subtitles, skip enabled) —*
*SFX — power_up*
*LIGHTS — power on*
*AMBIENCE — loop hum*
*[noise_mult 0.45]*
*CAMERA SHAKE*
**PA** — Main power restored. Good morning, HELIX-9.
*RADIO — the receiver switches itself on, 89.1 MHz*
*AMBIENCE — loop static*
**OKAFOR (ECHO)** — —carrier's holding at one-oh-seven-nine—
**PELL (ECHO)** — —not on the open channel, not any more—
**LIND (ECHO)** — —take him off the mountain, Evelyn—
**HALE (ECHO)** — —nobody opens the Door. Nobody—
**MIRA (ECHO)** — —Danny, look. Look at all the lights—
**DUARTE (ECHO)** — —somebody is on channel two and it is my voice—
**VOICES** — —can anyone hear me — can anyone hear me — can anyone—
*RADIO — off*
*AMBIENCE — stop static*
**DANIEL** — Every voice that ever went through this place. It's all still in the wires.
**DANIEL** — Turbines are loud now. Good. Loud is good. Nothing hears me over that.
*HINT — Running machinery masks your footsteps.*
*CHECKPOINT — game saved*
*— control returns to the player —*
*OBJECTIVE — Main power is up. Get back through the control room — the tunnel door is at the east end of the turbine hall.*


---

## CHAPTER 06 — NO WAY BACK

### Interaction — “Climb toward the Communications Centre”

*— cinematic begins (player control locked, subtitles, skip enabled) —*
*SFX — splash*
*SFX — metal*
**DANIEL** — Out of the water. Up. Comms is up.
**DANIEL** — Okafor never said it on the radio. So it can't say it back.
*FADE TO BLACK (1.5s)*
*→ NEXT CHAPTER*


---

## CHAPTER 07 — THE SIGNAL ROOM

### Interaction — “Bring the uplink online”

*— cinematic begins (player control locked, subtitles, skip enabled) —*
*SFX — power_up*
*SFX — beep_hi*
*(beat — 1s)*
*CAMERA — from `x` looking at `U` over 4s*
**PA** — Uplink established.
**DANIEL** — Northline, this is Arlen on the HELIX-9 uplink. Kessler, do you copy? Anyone at Northline?
*(beat — 2s)*
*SFX — static*
**KESSLER (UPLINK)** — —Danny? Danny, is that you? Christ. Where have you been?
**DANIEL** — Inside. Four hours, like we said. I missed a check-in, I know—
**KESSLER (UPLINK)** — Danny, you've been gone nine days.
*(beat — 1.5s)*
**DANIEL** — ...No.
**KESSLER (UPLINK)** — Your truck's at the gate under a foot of snow. We sent a team in on day three. The blast door is welded shut, Danny. Rusted shut. Nobody's been through that door since the nineties.
**DANIEL** — I walked through it. It was standing open. I walked through it.
**KESSLER (UPLINK)** — ...Then how are you talking to me?
*SFX — glitch*
**KESSLER? (UPLINK)** — Four hours, Danny. Check in on the hour.
**DANIEL** — Kessler?
**KESSLER? (UPLINK)** — Four hours, Danny. Four hours, Danny.
*SFX — power_down*
*(beat — 1s)*
**PA** — Uplink established. Thank you, Daniel.
**DANIEL** — It's on the line. It went up the line. It's in his radio.
*RADIO — the receiver switches itself on, 103.7 MHz*
*SFX — glitch*
**HALE (103.7 MHz)** — Good work, Arlen. The uplink's live — but it's a whisper. Nobody hears a whisper through a mountain.
**HALE (103.7 MHz)** — You need power behind the signal. The only transmitter big enough is the one in the Final Experiment chamber. Go through the labs. The transport line runs down to it.
*RADIO — the receiver switches itself on, 96.1 MHz*
*SFX — glitch*
**MIRA (96.1 MHz)** — Danny— Daniel. Don't. Whatever Marcus wants switched on down there, don't.
**DANIEL** — You called me Danny.
**MIRA (96.1 MHz)** — Did I? I'm sorry. I'm tired, Daniel. I'm so tired. Please. Not the chamber.
*RADIO — off*
*CAMERA — return to Daniel's eyes*
**DANIEL** — No way back up. And she's down there. So: down.
*(story flag `c7_uplink`)*
*CHECKPOINT — game saved*
*OBJECTIVE — The research labs are through the door at the east end of the corridor.*
*— control returns to the player —*

### Door

*— cinematic begins (player control locked, subtitles, skip enabled) —*
**DANIEL** — Labs. Whatever they were really doing down here, it's through this door.
*FADE TO BLACK (1.5s)*
*→ NEXT CHAPTER*


---

## CHAPTER 08 — THE ECHO PROJECT

### Interaction — “Play the briefing reel”

*— cinematic begins (player control locked, subtitles, skip enabled) —*
*CAMERA — from `v` looking at `m` over 3s*
*MONITOR — types out: DIRECTORATE OF SIGNAL RESEARCH / PROJECT ECHO — BRIEFING 04/96 / CLASSIFICATION: HELIX*
**EVELYN (BRIEFING, 1996)** — Gentlemen. Every radio signal ever transmitted is still travelling. You know that. It thins, it scatters, but it doesn't stop.
**EVELYN (BRIEFING, 1996)** — What you don't know is that some of it comes back. Not reflected — returned, through a layer of the deep crust we're calling the echo shelf. Delayed by years. Sometimes decades.
**EVELYN (BRIEFING, 1996)** — And some of it arrives before it was sent.
**EVELYN (BRIEFING, 1996)** — HELIX-9 sits on the thinnest point of that shelf on this continent. With the array, we hear the past. With the Aperture, we believe we can hear the future.
**DIRECTORATE (BRIEFING, 1996)** — And transmit?
**EVELYN (BRIEFING, 1996)** — In principle, both ways. The Aperture isn't a receiver, Colonel. It's a door.
**DIRECTORATE (BRIEFING, 1996)** — Then what's on the other side of it, Doctor?
**EVELYN (BRIEFING, 1996)** — Everything anyone has ever said. Waiting to be heard.
*MONITOR — types out: PHASE III — THE APERTURE / "OPEN THE LINE BOTH WAYS"*
*CAMERA — return to Daniel's eyes*
**DANIEL** — They didn't build a listening post. They built a door.
**DANIEL** — 'Whatever happens, do not open the door.'
*(story flag `c8_brief`)*
*— control returns to the player —*

### Door

*— cinematic begins (player control locked, subtitles, skip enabled) —*
**DANIEL** — Rails, going down into the dark. Of course they are.
*FADE TO BLACK (1.5s)*
*→ NEXT CHAPTER*


---

## CHAPTER 09 — DEAD LINE

### Trigger `R`

*— cinematic begins (player control locked, subtitles, skip enabled) —*
*MUSIC — silence*
*RADIO — the receiver switches itself on, 96.1 MHz*
*SFX — glitch*
**MIRA (96.1 MHz)** — Daniel? You're on the platform. I can hear the rails singing.
**DANIEL** — Tram's live. I'm coming down to you. Containment. Ten minutes.
**MIRA (96.1 MHz)** — Don't. Please. Not if Marcus sent you.
**DANIEL** — Nobody sent me. I'm coming because you're there.
*(beat — 1.5s)*
**MIRA (96.1 MHz)** — Can I tell you something stupid? There's a song. I hum it when I'm frightened. I've hummed it eleven thousand times down here.
**DANIEL** — I heard you. In the lift. I knew the tune.
**MIRA (96.1 MHz)** — You couldn't. Evelyn wrote the words. Nobody alive knows them but me.
**MIRA (96.1 MHz)** — (singing, barely) Little light, little light... hold the line through the night...
**DANIEL** — (singing, without meaning to) ...if the dark calls your name, it is not me.
*(beat — 2.5s)*
**MIRA (96.1 MHz)** — Where did you learn that?
**DANIEL** — I don't know. I've always known it. I sang it under the covers when I was small. My mum — the woman who raised me — said I came with it.
**MIRA (96.1 MHz)** — Came with it.
**MIRA (96.1 MHz)** — Daniel. When's your birthday?
**DANIEL** — Fourteenth of August.
*(beat — 2s)*
**MIRA (96.1 MHz)** — ...Danny?
*RADIO — the receiver switches itself on, 107.9 MHz*
*(beat — 0.6s)*
*Daniel turns to look at `m`*
**DANIEL** — ...Mira?
**MIRA (96.1 MHz)** — I carried you up that lift. Two forty-four. You had your hand in my hair the whole way up and you never cried once.
**MIRA (96.1 MHz)** — I gave you to Ines at the gate. I pinned your name to your blanket, and I told her: don't let them ever bring him back here.
**MIRA (96.1 MHz)** — And then I went back down for your mother.
**DANIEL** — My mother.
**MIRA (96.1 MHz)** — Evelyn. Evelyn Voss. You're her son, Danny. You're Evelyn's boy.
*(beat — 2s)*
**DANIEL** — The file. The birthday. Subject D. I kept telling myself — I kept—
**MIRA (96.1 MHz)** — Look at you. You got so old. You got so tall.
**DANIEL** — You haven't aged a day.
**MIRA (96.1 MHz)** — (a laugh that breaks) It's only been one night, Danny. It's only ever been one night.
*RADIO — off*
*JOURNAL — "Mira"*
*(story flag `c9_reveal`)*
*(story flag `lullaby_aired`)*
*RADIO — the receiver switches itself on, 103.7 MHz*
*SFX — glitch*
**HALE (103.7 MHz)** — Arlen. Get on the tram. Now. It heard every word of that, and it's coming for you.
*RADIO — off*
*THE LISTENER — spawn at `Z` (hunt)*
*SFX — screech (positional, at `Z`)*
*— control returns to the player —*
*OBJECTIVE — Get on the tram!*

### Interaction — “Start the tram”

*— cinematic begins (player control locked, subtitles, skip enabled) —*
*THE LISTENER — despawn*
*SFX — power_up*
*AMBIENCE — loop tram*
*CAMERA SHAKE*
**DANIEL** — Go, go, go—
*FADE TO BLACK (1s)*
*(beat — 1s)*
*RADIO — the receiver switches itself on, 96.1 MHz*
**MIRA (96.1 MHz)** — Danny? Are you on it?
**DANIEL** — I'm on it. It's behind us. I think it's behind us.
**MIRA (96.1 MHz)** — Talk to me. Keep talking. It's harder for it when you're not alone.
**DANIEL** — What do I talk about?
**MIRA (96.1 MHz)** — Anything. What you did. Who you turned into. I've wondered for eleven thousand nights.
**DANIEL** — I fix radios. I used to run rescue comms in the mountains. Then one night I listened to the wrong voice, and four people froze on Harrow Pass. So now I fix radios.
**MIRA (96.1 MHz)** — Whose voice?
**DANIEL** — Mine.
*(beat — 1.5s)*
**MIRA (96.1 MHz)** — ...Danny. That's what it does.
*CAMERA SHAKE*
*SFX — metal*
**DANIEL** — We're slowing. Containment. We're here.
*RADIO — off*
*AMBIENCE — stop cine*
*→ NEXT CHAPTER*


---

## CHAPTER 10 — WHAT LISTENS

### Interaction — “Bulkhead intercom”

*— cinematic begins (player control locked, subtitles, skip enabled) —*
*SFX — stop knock*
**MIRA? (BEHIND THE BULKHEAD)** — Danny, open it. Please. I can hear it on the stairs.
*RADIO — the receiver switches itself on, 96.1 MHz*
*SFX — glitch*
**MIRA (96.1 MHz)** — Danny, that isn't me. I'm not at the bulkhead. I'm in the chamber, with your mother. Whatever is at that door — keep it shut.
*RADIO — the receiver switches itself on, 103.7 MHz*
*SFX — glitch*
**HALE (103.7 MHz)** — Arlen, that's her at the door. That's Mira. The thing on the radio is wearing her. Open the bulkhead and get her out.
*RADIO — off*
**DANIEL** — Two Miras. Hale says open it. Mira says keep it shut.
**DANIEL** — Mira. Sing it. Sing me the song.
**MIRA? (BEHIND THE BULKHEAD)** — (singing) Little light, little light, hold the line through the night...
*RADIO — the receiver switches itself on, 96.1 MHz*
**MIRA (96.1 MHz)** — (singing) Little light, little light, hold the line through the night...
**DANIEL** — Both. They both know it.
**MIRA (96.1 MHz)** — I sang it on the air. On the platform. I'm sorry, Danny. I sang it on the air, and now it has it.
*RADIO — off*
*HINT — Look before you choose. 107.9 shows what hides.*
*(story flag `c10_dilemma`)*
*— control returns to the player —*
*OBJECTIVE — Decide. The bulkhead release is beside the intercom.*

### Interaction — “Bulkhead release”

*— cinematic begins (player control locked, subtitles, skip enabled) —*
*[PLAYER CHOICE — "The bulkhead release is under your hand."]*
- **Open the bulkhead.**
  *(story flag `c10_opened`)*
  *SFX — alarm*
  *[unlock K True]*
  *(beat — 1.2s)*
  **MIRA? (BEHIND THE BULKHEAD)** — Thank you, Danny.
  *THE LISTENER — hunt*
  *SFX — screech*
  *CAMERA SHAKE*
  *RADIO — the receiver switches itself on, 96.1 MHz*
  **MIRA (96.1 MHz)** — It's through. Danny, it's through — run. Just keep moving. It's all right. Just keep moving.
  *RADIO — off*
- **Keep it sealed.**
  *(story flag `trust_mira`)*
  *(story flag `c10_sealed`)*
  **DANIEL** — No. I heard you, Mira. The real one. It stays shut.
  *(beat — 1.2s)*
  **MIRA? (BEHIND THE BULKHEAD)** — Danny, please—
*(beat — 1s)*
**LISTENER (DANIEL'S VOICE)** — Hold them. Don't send them up yet.
**DANIEL** — ...What did you say?
**LISTENER (DANIEL'S VOICE)** — Hold them. Don't send them up yet. Hold them. Don't send them up yet.
**DANIEL** — Harrow Pass. That's Harrow Pass. The dead channel. My voice. That was — that was YOU.
**DANIEL** — You sat on my channel and you wore my voice and four people froze on that mountain waiting for me.
*RADIO — the receiver switches itself on, 103.7 MHz*
*SFX — glitch*
**HALE? (103.7 MHz)** — Hold them. Don't send them up yet.
**DANIEL** — ...Hale. That came out of your channel, Hale.
*RADIO — off*
*JOURNAL — "Harrow Pass"*
*(story flag `c10_choice`)*
*[unless `c10_opened`:]*
  *THE LISTENER — spawn at `Z` (stalk)*
*CHECKPOINT — game saved*
*OBJECTIVE — The archive lift is past the security post, south of the hall.*
*— control returns to the player —*

### Door

*— cinematic begins (player control locked, subtitles, skip enabled) —*
**DANIEL** — Archive lift. Down to where they kept everything they couldn't throw away.
*FADE TO BLACK (1.5s)*
*→ NEXT CHAPTER*


---

## CHAPTER 11 — EVERY VOICE EVER LOST

### Door

*— cinematic begins (player control locked, subtitles, skip enabled) —*
**PA** — Current time: zero two — forty-three.
**DANIEL** — Last stop. Whatever's at the bottom, it's been waiting since before I was born.
*[unless `shutdown_key`:]*
  **DANIEL** — Her vault. I never opened her vault. Too late now.
*FADE TO BLACK (1.5s)*
*→ NEXT CHAPTER*


---

## CHAPTER 12 — 02:43

### Interaction — “Operator's log terminal”

*— cinematic begins (player control locked, subtitles, skip enabled) —*
*MONITOR — types out: RUN 19 — OPERATOR LOG / 02:40  APERTURE 40% / 02:42  APERTURE 80% — CARRIER ANSWERING / 02:43  APERTURE OPENING — NOT US / 02:43  D. STILL ON LEVEL*
**DANIEL** — 'D. still on level.' She knew. She knew I was still down here when it opened.
*— control returns to the player —*

### Trigger `f`

*— cinematic begins (player control locked, subtitles, skip enabled) —*
*MUSIC — silence*
*THE LISTENER — spawn at `x` (watch)*
*Daniel turns to look at `x`*
*CAMERA — from `f` looking at `x` over 3s*
*SFX — clicks (positional, at `x`)*
**EVELYN? (THE LISTENER)** — Danny. Sweetheart. You came home.
**HALE? (THE LISTENER)** — Good work, Arlen. Now open it.
**KESSLER? (THE LISTENER)** — Four hours, Danny.
**MIRA? (THE LISTENER)** — Little light, little light, hold the line through the night—
**LISTENER (DANIEL'S VOICE)** — Hold them. Don't send them up yet.
**LISTENER (DANIEL'S VOICE)** — Daniel. Whatever happens. Do not open the door.
**DANIEL** — That too? The warning? Was that you as well?
**LISTENER (DANIEL'S VOICE)** — Daniel. Whatever happens. Do not open the door.
**DANIEL** — You don't know. You don't know anything. You only know what you've heard.
**DANIEL** — So hear this.
*RADIO — off*
*AMBIENCE — stop amb*
*(beat — 2.5s)*
*THE LISTENER — blind*
*THE LISTENER — dormant*
*CAMERA — return to Daniel's eyes*
*HINT — It can only hear now. Radio off. Crouch. Not a sound.*
*OBJECTIVE — Get past it to the inner seal at the north wall. Silently.*
*— control returns to the player —*

### Interaction — “Release the inner seal”

*— cinematic begins (player control locked, subtitles, skip enabled) —*
*SFX — door*
*CAMERA SHAKE*
**DANIEL** — (whispering) I'm through. I'm through.
*FADE TO BLACK (1.5s)*
*→ NEXT CHAPTER*


---

## CHAPTER 13 — THE LAST TRANSMISSION

### Opening sequence

*THE LISTENER — spawn at `x` (watch)*
*CAMERA — from `S` looking at `A`, dolly to `U` over 6s*
**PA** — Current time: zero two — forty-three.
**DANIEL** — The Door.
*SFX — clicks (positional, at `x`)*
*RADIO — the receiver switches itself on, 96.1 MHz*
*SFX — glitch*
**MIRA (96.1 MHz)** — Danny. You're here. I can see you. I can see you on the glass, like a reflection that walks.
**DANIEL** — Where are you?
**MIRA (96.1 MHz)** — Right beside you. Twenty-eight years to the left.
*RADIO — the receiver switches itself on, 107.9 MHz*
*(beat — 1s)*
*CAMERA — return to Daniel's eyes*
*Daniel turns to look at `m`*
**DANIEL** — ...I see you. Mira. I can see you.
*Daniel turns to look at `e`*
**EVELYN (02:51, 1998)** — Mira, the seal's going — I need both hands on this — Mira, who are you talking to?
**MIRA (96.1 MHz)** — Nobody. Nobody, Evelyn. Keep your hands on the seal.
*RADIO — off*
*THE LISTENER — face*
*OBJECTIVE — The Aperture console.*

### Interaction — “The Aperture console”

*— cinematic begins (player control locked, subtitles, skip enabled) —*
*Daniel turns to look at `A`*
**LISTENER (EVELYN'S VOICE)** — Open it, Danny. Open it, and we all come home. Me. Mira. Forty-one people. Open the door.
**LISTENER (DANIEL'S VOICE)** — Daniel. Whatever happens. Do not open the door.
*RADIO — the receiver switches itself on, 96.1 MHz*
**MIRA (96.1 MHz)** — Whatever you choose, I'm here. You hear me? You're not alone.
*RADIO — off*
*[PLAYER CHOICE — "The Aperture console. One master switch. Three positions."]*
- **OPEN the Door.**
  *(story flag `final_open`)*
  **DANIEL** — Everyone comes home.
- **SHUT IT DOWN. Turn the key. Silence.**
  *(story flag `final_silence`)*
  *[if `shutdown_key`:]*
    **DANIEL** — I'm sorry. I'm so sorry.
  *[otherwise:]*
    **DANIEL** — The key— her key. I never took her key.
- **ANSWER IT. Send the last transmission.**
  *(story flag `final_send`)*
  **DANIEL** — Signal...
*FADE TO BLACK (1s)*
*→ ENDING (decided by story flags)*


---

## ENDING A — SILENCE

### Opening sequence

*THE LISTENER — spawn at `x` (watch)*
*THE LISTENER — face*
*CAMERA — from `U` looking at `A` (cut)*
*FADE IN (1.5s)*
*SFX — metal*
**DANIEL** — Mira. Evelyn. I'm turning it.
**MIRA (96.1 MHz)** — I know. It's all right. It's allowed. She said so.
**MIRA (96.1 MHz)** — Danny — thank you for coming back for me. Nobody ever came back for—
*SFX — power_down*
*CAMERA SHAKE*
*LIGHTS — power dies; red emergency lamps pulse*
*THE LISTENER — despawn*
*AMBIENCE — stop amb*
*FADE TO BLACK (0.1s)*
*(beat — 4s)*
*EXTERIOR — night*
*CAMERA — from `@behind` looking at `@gate` (cut)*
*FADE IN (3s)*
*CAMERA — from `@behind` looking at `@gate`, dolly to `@truck` over 14s*
**DANIEL (LATER)** — They found the blast door rusted shut from the outside, the way Kessler said. They found me sitting in the truck. Day eleven.
**DANIEL (LATER)** — I told them the site was empty. It is now.
**DANIEL (LATER)** — I don't listen to the radio any more. Some nights the house is so quiet I can hear my own heart, and I tell myself that's what silence sounds like.
**DANIEL (LATER)** — I tell myself it's enough.
*(beat — 2s)*
*FADE TO BLACK (2.5s)*
*CARD — ENDING A — SILENCE*
*TITLE — DEAD FREQUENCY (glitch reveal, bass impact)*
*→ END CREDITS*


---

## ENDING B — THE OPEN DOOR

### Opening sequence

*THE LISTENER — spawn at `x` (watch)*
*THE LISTENER — face*
*CAMERA — from `U` looking at `A` (cut)*
*FADE IN (1s)*
**DANIEL** — Everyone comes home.
*SFX — power_up*
*CAMERA SHAKE*
*107.9 reveal forced on*
*CAMERA — from `S` looking at `A`, dolly to `U` over 6s*
**VOICES** — Thank you. Thank you. Thank you.
**EVELYN** — My little light. Look how tall you got.
**MIRA** — Danny — Danny, wait. Something's wrong. They're not— they don't have faces, Danny—
**LISTENER (EVERY VOICE)** — Thank you, Daniel.
*FADE TO BLACK (1.5s)*
*107.9 reveal forced off*
*THE LISTENER — despawn*
*EXTERIOR — dawn*
*CAMERA — from `@road2` looking at `@far` (cut)*
*FADE IN (2.5s)*
*CAMERA — from `@road2` looking at `@far`, dolly to `@road1` over 12s*
**DANIEL (LATER)** — We walked out at dawn. Forty-one of them behind me in the snow, talking, laughing, saying my name.
**DANIEL (LATER)** — By the time I reached the truck there was only me.
*SFX — click*
**KESSLER (RADIO)** — Danny? Danny, something's happening — every set in the valley just switched itself on—
**KESSLER? (RADIO)** — Four hours, Danny. Four hours, Danny.
**LISTENER (DANIEL'S VOICE, EVERY RADIO)** — Thank you, Daniel. Thank you, Daniel. Thank you, Daniel.
*FADE TO BLACK (2.5s)*
*CARD — ENDING B — THE OPEN DOOR*
*TITLE — DEAD FREQUENCY (glitch reveal, bass impact)*
*→ END CREDITS*


---

## ENDING C — THE LOOP

### Opening sequence

*THE LISTENER — spawn at `x` (watch)*
*THE LISTENER — face*
*CAMERA — from `U` looking at `A` (cut)*
*FADE IN (1s)*
*[if `final_silence`:]*
  **DANIEL** — The key — I don't have the key. Mira, I don't have her key—
*[if `final_send`:]*
  **DANIEL** — Signal— Mira? Mira, answer. Why isn't anybody answering? It's just me. It's just my voice—
*SFX — glitch*
*CAMERA SHAKE*
*LIGHTS — power dies; red emergency lamps pulse*
**LISTENER (DANIEL'S VOICE)** — Again.
*FADE TO BLACK (0.2s)*
*THE LISTENER — despawn*
*(beat — 2s)*
*CUT — Daniel is at `n`*
*CAMERA — return to Daniel's eyes*
*FADE IN (1.5s)*
**PA** — Current time: zero two — forty-three.
**DANIEL** — ...The annex. I'm back in the annex.
**DANIEL** — The recorder. The monitor. Two forty-three. It's always two forty-three.
**DANIEL** — There's a microphone. Somebody has to warn him. Somebody has to tell him before he comes in.
*CAMERA — from `c` looking at `r` over 4s*
*RADIO — the receiver switches itself on, 101.3 MHz*
**DANIEL** — (into the microphone, broken) Daniel...
**DANIEL** — Whatever happens. Do not open the door.
*RADIO — off*
*FADE TO BLACK (2s)*
*EXTERIOR — storm*
*CAMERA — from `@far` looking at `@gate` (cut)*
*FADE IN (2s)*
*CAMERA — from `@far` looking at `@gate`, dolly to `@road1` over 7s*
**DISPATCH (KESSLER)** — Northline to Arlen. You at the gate yet?
**DANIEL** — At the gate. Snow gave up about a mile back. Now it's just rain.
*FADE TO BLACK (2.5s)*
*CARD — ENDING C — THE LOOP*
*TITLE — DEAD FREQUENCY (glitch reveal, bass impact)*
*→ END CREDITS*


---

## ENDING D — THE LAST TRANSMISSION

### Opening sequence

*THE LISTENER — spawn at `x` (watch)*
*THE LISTENER — face*
*CAMERA — from `U` looking at `A` (cut)*
*FADE IN (1s)*
**DANIEL** — Mira. I need you on the line. I can't do this alone. That's the whole point.
**MIRA (96.1 MHz)** — I'm here. I've been here the whole time.
**DANIEL** — Lind. Okafor. Hale. Evelyn. Every tape I found, every real voice. I'm patching them into the uplink. All of them at once.
*SFX — power_up*
*AMBIENCE — loop static*
*[if `tape_okafor`:]*
  **OKAFOR (TAPE)** — I love you. That isn't a thing it can take.
**HALE (TAPE)** — I kept my word as long as I could.
**LIND (TAPE)** — Take him off the mountain.
**EVELYN (TAPE)** — Little light. Signal and answer.
**DANIEL** — Signal.
**MIRA (96.1 MHz)** — Answer.
**LISTENER (EVERY VOICE)** — Daniel— Daniel— Dan—
*SFX — screech*
*CAMERA SHAKE*
*THE LISTENER — despawn*
*AMBIENCE — stop static*
*(beat — 1s)*
*107.9 reveal forced on*
**EVELYN (02:51, 1998)** — ...Who's on this channel? Mira — who is that?
**DANIEL** — Mum. It's Danny.
*(beat — 2s)*
**EVELYN (02:51, 1998)** — Danny? Oh — oh, look at you. Little light. You got so tall.
**DANIEL** — You can close it now. From your side. I'll close it from mine. Together. Not alone.
**EVELYN (02:51, 1998)** — Together. Yes. Yes, my love.
**MIRA (96.1 MHz)** — I'm staying with her, Danny. I carried you once. Let me carry her now.
**DANIEL** — Mira—
**MIRA (96.1 MHz)** — Signal and answer. Go home.
*SFX — metal*
*SFX — power_down*
*CAMERA SHAKE*
*FADE TO BLACK (2s)*
*107.9 reveal forced off*
*(beat — 1.5s)*
*EXTERIOR — dawn*
*CAMERA — from `@behind` looking at `@gate` (cut)*
*FADE IN (2.5s)*
*CAMERA — from `@behind` looking at `@gate`, dolly to `@truck` over 12s*
**DANIEL (LATER)** — The blast door was standing open when I came out. The snow had stopped. It was morning.
**DANIEL (LATER)** — Forty-one names went on a stone in Halden the next spring. Mira's is the last one. I asked them to leave room under it.
**DANIEL (LATER)** — I still drive with the radio on. Mostly it's static.
**MIRA (RADIO, VERY FAINT)** — (humming)
**MIRA (RADIO, VERY FAINT)** — Signal, Danny.
**DANIEL** — Answer.
*FADE TO BLACK (3s)*
*CARD — ENDING D — THE LAST TRANSMISSION*
*TITLE — DEAD FREQUENCY (glitch reveal, bass impact)*
*→ END CREDITS*

