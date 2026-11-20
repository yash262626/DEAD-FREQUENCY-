#!/usr/bin/env python3
"""Generate the data-driven design documents from the game's own story data.

Usage:  tools/test.sh export DF_OUT=/tmp/df_story.json   (dumps game/data/*.gd as JSON)
        python3 tools/gen_docs.py /tmp/df_story.json docs/

Everything written here is derived from game/data, so these documents cannot drift
from what actually ships: if the data changes, regenerate.
"""
import json, sys, os, re

src, out = sys.argv[1], sys.argv[2]
D = json.load(open(src))
CH = D["chapters"]

SUMMARY = {
 0: "October 17, 1998, 02:43. A storm over the mountain. Inside HELIX-9, Dr. Evelyn Voss's team watches the 107.9 carrier answer a message nobody sent, stamped with a date twenty-eight years in the future. Security chief Marcus Hale orders the lower levels sealed. Evelyn sends Mira Solace up the lift with a child. A voice on the channel — Daniel's — warns: do not open the door. The power dies. *Can anyone hear me?* Title.",
 1: "2026. Daniel Arlen arrives at the gate in the rain; dispatch reads him the beacon's message: his own name. He restores auxiliary power, finds the HX-7 receiver, hears 1998 on 89.1, glimpses something tall at the end of a corridor and hears his own voice on 101.3: *do not open the door*. In the comms annex a tape addressed to him plays; the monitor identifies him: ALREADY INSIDE. Second title reveal (~25 min).",
 2: "The administration wing, where the night shift stopped mid-sentence. First full sighting: the Listener stands in the supervisor's office and repeats Daniel's words back in Daniel's voice. It hunts the wing from then on. A 1998 echo gives the supervisor's code; a dispatcher's voice that only repeats teaches the core rule: it can only say what has already been said over the air.",
 3: "The medical wing. A patient file with Daniel's birthday. Evelyn's first recording — about her son, who hears the carrier without a receiver. 107.9 reveals writing on the walls. The Listener begins to stalk in Evelyn's voice. A crate on a treadle plate opens the morgue for the lift fuse.",
 4: "Residential quarters. Mira's note says 96.1. Something knocks on the laundry door in Mira's voice — the real Mira, on the radio, says it isn't her. She is in 1998, always at 02:43. Evelyn's apartment (the birthday code) holds the lullaby Evelyn never sang over the air. Mira gives the caretaker's code; the master key opens the shaft down.",
 5: "The power station. A man who calls himself Marcus Hale answers on 103.7 and directs Daniel toward the uplink. A 1998 engineer's echo gives the breaker order. Main power returns and with it every voice in the wires. The Listener sees Daniel from the turbine hall gantry: first chase.",
 6: "The stairwell collapses: no way back. Flood tunnels where water doubles every footstep. Mira says Hale sealed twenty-three people behind the containment bulkhead, including her; Hale says the thing wears Mira. Valve settings painted in luminous paint are only readable on 107.9.",
 7: "The Communications Centre. A numbers station on 99.7 and a 1998 echo give the storeroom code and the feed-horn headings. The uplink connects: Northline says Daniel has been gone nine days and the blast door is rusted shut. The Listener rides the line into Kessler's radio. 'Hale' wants the Final Experiment chamber; Mira begs him not to go.",
 8: "The research labs. The 1996 Project ECHO briefing: the Aperture was never a receiver. It's a door. 101.3 forecasts the Listener's next move — and is always right. Lab notes on 'Subject D', fourteen months old: it doesn't want us. It wants him.",
 9: "The transport line. Mira sings the first line of the lullaby; Daniel finishes it without knowing how. She asks his birthday. She carried him up the lift in 1998. He is Evelyn's son. The song has now gone out over the air. 'Hale' orders him onto the tram; the chase begins.",
 10: "Containment. The Listener is invisible here except on 107.9. At the bulkhead, two Miras — one through the steel, one on 96.1 — both know the song now. 'Hale' urges Daniel to open it. Whatever Daniel chooses, the Listener speaks the words he heard on Harrow Pass three years ago: *Hold them. Don't send them up yet.* It has been talking to him all his life.",
 11: "The Archive. Ines Duarte's sealed statement explains how a baby called Daniel left the mountain. Hale's real last tape: if you hear me on the radio after tonight, it isn't me — do the opposite. The 'Hale' on 103.7 answers in Daniel's voice. In the Director's vault: Evelyn's goodbye to her son, and the shutdown key.",
 12: "The Aperture ring. Three emitters replay the last eight minutes of 1998. At the chamber the Listener speaks with every voice it owns — and with Daniel's warning. Daniel switches off the radio: it can only hear now. He walks past it in silence.",
 13: "The Door. Mira beside him, twenty-eight years to the left. Evelyn at the seal in 1998. The Listener in his mother's voice. One switch, three positions: open, silence, answer.",
}

def is_line(e):
    return isinstance(e, list) and len(e) > 1 and isinstance(e[1], str) and (str(e[0]) == "" or str(e[0]) != str(e[0]).lower())

def lines_of(evs, depth=0, out=None, stage=False):
    if out is None: out = []
    pad = "  " * depth
    for e in evs or []:
        if not isinstance(e, list) or not e: continue
        c = str(e[0])
        if is_line(e):
            out.append(f"{pad}**{c or 'SYSTEM'}** — {e[1]}")
        elif c in ("if", "ifnot"):
            cond = ("if" if c == "if" else "unless") + f" `{e[1]}`"
            sub = lines_of(e[2], depth + 1, [], stage)
            if sub: out.append(f"{pad}*[{cond}:]*"); out += sub
            if c == "if" and len(e) > 3:
                sub = lines_of(e[3], depth + 1, [], stage)
                if sub: out.append(f"{pad}*[otherwise:]*"); out += sub
        elif c == "choice":
            out.append(f"{pad}*[PLAYER CHOICE — \"{e[1]}\"]*")
            for opt in e[2]:
                out.append(f"{pad}- **{opt[0]}**")
                out += lines_of(opt[1], depth + 1, [], stage)
        elif stage:
            out.append(f"{pad}{stage_dir(e)}")
    return out

def stage_dir(e):
    c = e[0]; a = e[1:]
    m = {
        "cam": lambda: f"CAMERA — from `{a[0]}` looking at `{a[1]}`" + (f", dolly to `{a[3]}`" if len(a) > 3 and a[3] else "") + (f" over {a[2]}s" if a[2] else " (cut)"),
        "camoff": lambda: "CAMERA — return to Daniel's eyes",
        "cine": lambda: "— cinematic begins (player control locked, subtitles, skip enabled) —" if a[0] else "— control returns to the player —",
        "sfx": lambda: f"SFX — {a[0]}" + (f" (positional, at `{a[3]}`)" if len(a) > 3 and a[3] else ""),
        "music": lambda: f"MUSIC — {a[0] or 'silence'}",
        "loop": lambda: f"AMBIENCE — loop {a[1]}", "unloop": lambda: f"AMBIENCE — stop {a[0]}",
        "loop3d": lambda: f"SFX — loop {a[1]} at `{a[2]}`", "unloop3d": lambda: f"SFX — stop {a[0]}",
        "fade": lambda: ("FADE TO BLACK" if a[0] else "FADE IN") + (f" ({a[1]}s)" if len(a) > 1 else ""),
        "wait": lambda: f"(beat — {a[0]}s)", "pulse": lambda: "LIGHTS — power dies; red emergency lamps pulse",
        "lights": lambda: "LIGHTS — power on" if a[0] else "LIGHTS — power off",
        "radio_on": lambda: (f"RADIO — the receiver switches itself on, {a[1]} MHz" if a[0] and len(a) > 1 else ("RADIO — on" if a[0] else "RADIO — off")),
        "monitor": lambda: "MONITOR — types out: " + " / ".join(a[0]),
        "title": lambda: "TITLE — DEAD FREQUENCY (glitch reveal, bass impact)" + (f"; tagline: {a[0]}" if a and a[0] else ""),
        "card": lambda: "CHAPTER CARD", "text": lambda: f"CARD — {a[0]}",
        "listener": lambda: f"THE LISTENER — {a[0]}" + (f" at `{a[1]}`" if len(a) > 1 else "") + (f" ({a[2]})" if len(a) > 2 else ""),
        "shake": lambda: "CAMERA SHAKE", "look": lambda: f"Daniel turns to look at `{a[0]}`",
        "obj": lambda: f"OBJECTIVE — {a[0]}", "toast": lambda: f"HINT — {a[0]}", "journal": lambda: f"JOURNAL — \"{a[0]}\"",
        "flag": lambda: f"(story flag `{a[0]}`)", "ach": lambda: f"ACHIEVEMENT — {D['ach'].get(a[0], a[0])}",
        "checkpoint": lambda: "CHECKPOINT — game saved", "next": lambda: "→ NEXT CHAPTER", "ending": lambda: "→ ENDING (decided by story flags)",
        "credits": lambda: "→ END CREDITS", "menu": lambda: "→ MAIN MENU", "tp": lambda: f"CUT — Daniel is at `{a[0]}`",
        "ext": lambda: f"EXTERIOR — {a[0]}", "reveal": lambda: "107.9 reveal forced " + ("on" if a[0] else "off"),
    }
    try: return "*" + m.get(c, lambda: f"[{c} {' '.join(map(str, a))}]")() + "*"
    except Exception: return f"*[{c}]*"

def label(ch, l):
    t = l["t"]
    if t == "note": return f"Document — “{l['title']}”"
    if t == "tape": return f"Tape — “{l['title']}”"
    if t == "radio": return f"Radio {l['f']} MHz — “{l.get('title', 'transmission')}”"
    if t == "trig": return f"Trigger `{ch}`"
    if t == "use": return f"Interaction — “{l.get('prompt', 'Use')}”"
    if t == "door": return "Door"
    if t == "item": return f"Pickup — {D['items'].get(l['id'], l['id'])}"
    if t == "ghost": return "107.9 writing"
    if t == "plate": return "Pressure plate"
    return t

def order(chd):
    seen = []; keys = []
    for s in chd.get("walk", []):
        k = s[1] if isinstance(s, list) and s[0] == "radio" else (s if isinstance(s, str) else None)
        if k and k in chd["leg"] and k not in keys: keys.append(k)
    for k in chd["leg"]:
        if k not in keys: keys.append(k)
    return keys

def has_content(l):
    return l.get("ev") or l.get("lines") or l.get("t") == "note"

def title_of(chd):
    if "ending" in chd:
        return {"A": "ENDING A — SILENCE", "B": "ENDING B — THE OPEN DOOR", "C": "ENDING C — THE LOOP", "D": "ENDING D — THE LAST TRANSMISSION"}[chd["ending"]]
    return f"CHAPTER {chd['n']:02d} — {chd['title']}" if chd["n"] else "PROLOGUE — OCTOBER 17, 1998"

# -------------------------------------------------------------- 06 dialogue & audio script
w = []
w.append("# DEAD FREQUENCY — Dialogue & Audio Script\n")
w.append("*Generated from `game/data/*.gd` by `tools/gen_docs.py`. This is the exact text the game displays (subtitles) and the casting/recording script for voice-over. Do not edit by hand — edit the data and regenerate.*\n")
w.append("Speaker tags: `NAME (1998)` = 89.1 echo of the past · `NAME (96.1 MHz)` etc. = live transmission · `NAME?` = the Listener imitating that person · `(TAPE)` = recording · `PA` = facility public address.\n")
w.append("**Voice-over status:** no voice actors are recorded yet. In the current build every line is subtitled and accompanied by a procedural radio-voice texture (see 11_ASSET_PRODUCTION_LIST.md).\n")
for chd in CH:
    w.append(f"\n---\n\n## {title_of(chd)}\n")
    if chd.get("pre_ev") or chd.get("start_ev"):
        w.append("### Opening\n")
        w += lines_of(chd.get("pre_ev", []) + chd.get("start_ev", [])) or ["*(no dialogue)*"]
        w.append("")
    for k in order(chd):
        l = chd["leg"][k]
        if not has_content(l): continue
        body = []
        if l["t"] == "note":
            body.append("> " + l["text"].replace("\n", "\n> "))
        body += lines_of(l.get("lines", []))
        body += lines_of(l.get("ev", []))
        if not body: continue
        w.append(f"### {label(k, l)}\n")
        w += body; w.append("")
    for g, evs in chd.get("groups", {}).items():
        body = lines_of(evs)
        if body:
            w.append(f"### Puzzle solved — `{g}`\n"); w += body; w.append("")
open(os.path.join(out, "06_DIALOGUE_AND_AUDIO_SCRIPT.md"), "w").write("\n".join(w) + "\n")

# -------------------------------------------------------------- 07 cinematic script
w = ["# DEAD FREQUENCY — Cinematic Script\n",
     "*Generated from the game's event data by `tools/gen_docs.py`. Every cinematic below is implemented in-engine (Godot 3.5) with the event runner in `game/scripts/level.gd`: camera dollies between map markers, positional sound, lighting cues, subtitles and hold-to-skip. Marker letters refer to the chapter maps in 08_LEVEL_DESIGN.md.*\n",
     "Shared presentation rules: 55° cinematic FOV; filmic tonemapping, glow, SSAO (High+), volumetric-style depth fog per area palette; letterbox-free (subtitles bottom-centre); every cinematic is skippable by holding SPACE / (A) for 0.8 s and never longer than ~3 minutes.\n"]
def is_cine(evs):
    return any(isinstance(e, list) and e and e[0] in ("cine", "cam", "title", "monitor") for e in evs or [])
for chd in CH:
    blocks = []
    st = chd.get("pre_ev", []) + chd.get("start_ev", [])
    if is_cine(st) or chd["n"] == 0 or "ending" in chd:
        blocks.append(("Opening sequence", st))
    for k in order(chd):
        l = chd["leg"][k]
        evs = (l.get("lines", []) or []) + (l.get("ev", []) or [])
        if is_cine(evs): blocks.append((label(k, l), evs))
    for g, evs in chd.get("groups", {}).items():
        if is_cine(evs): blocks.append((f"Puzzle solved — {g}", evs))
    if not blocks: continue
    w.append(f"\n---\n\n## {title_of(chd)}\n")
    for name, evs in blocks:
        w.append(f"### {name}\n")
        w += lines_of(evs, stage=True); w.append("")
open(os.path.join(out, "07_CINEMATIC_SCRIPT.md"), "w").write("\n".join(w) + "\n")

# -------------------------------------------------------------- 04 campaign + 05 missions + 08 level design
def objectives(chd):
    out = []
    def walk(evs):
        for e in evs or []:
            if not isinstance(e, list) or not e: continue
            if e[0] == "obj" and e[1] not in out: out.append(e[1])
            elif e[0] in ("if", "ifnot"):
                walk(e[2]); walk(e[3] if len(e) > 3 else [])
            elif e[0] == "choice":
                for o in e[2]: walk(o[1])
    walk(chd.get("start_ev", []))
    for k in order(chd):
        l = chd["leg"][k]; walk(l.get("lines")); walk(l.get("ev"))
    for g in chd.get("groups", {}).values(): walk(g)
    return out

def puzzles(chd):
    p = []
    seqs = {}; cyc = {}
    for k, l in chd["leg"].items():
        if l["t"] == "door" and "code" in l: p.append(f"Keypad `{l.get('label', 'door')}` — code **{l['code']}**")
        if l["t"] == "door" and "lock" in l: p.append(f"Door locked by item — needs **{D['items'].get(l['lock'], l['lock'])}**")
        if l["t"] == "door" and "needflag" in l: p.append(f"Door gated by story state `{l['needflag']}` — “{l.get('msg', '')}”")
        if l["t"] == "use" and "seq" in l: seqs.setdefault(l["seq"], []).append((l["step"], l.get("prompt", k)))
        if l["t"] == "use" and "cycle" in l: cyc.setdefault(l["group"], []).append((l.get("prompt", k), l["target"], l["cycle"]))
        if l["t"] == "use" and "need" in l: p.append(f"“{l.get('prompt')}” — needs **{D['items'].get(l['need'], l['need'])}**")
        if l["t"] == "radio" and l["f"] not in (89.1, 94.6, 101.3, 107.9): p.append(f"Hidden carrier **{l['f']} MHz** — “{l.get('title', '')}”")
        if l["t"] == "plate": p.append("Physics: push the crate onto the treadle plate")
        if l["t"] == "ghost" and "text" in l: p.append(f"107.9-only writing: “{l['text'].replace(chr(10), ' / ')}”")
    for g, steps in seqs.items():
        p.append(f"Ordered switches `{g}` — correct order: " + " → ".join(s[1] for s in sorted(steps)) + " (a mistake resets the board and makes noise)")
    for g, items in cyc.items():
        p.append(f"Rotation puzzle `{g}` — " + "; ".join(f"{i[0]}: position {i[1]} of {i[2]}" for i in items))
    return p

def collectibles(chd):
    c = []
    for k, l in chd["leg"].items():
        if l["t"] == "tape": c.append(f"Tape — {l['title']}" + (" **(Evelyn — counts toward ending D)**" if str(l.get('flag', '')).startswith('tape_ev') else ""))
        if l["t"] == "note": c.append(f"Document — {l['title']}")
        if l["t"] == "radio": c.append(f"Transmission {l['f']} MHz — {l.get('title', '')}")
        if l["t"] == "item": c.append(f"Item — {D['items'].get(l['id'], l['id'])}")
    return c

w = ["# DEAD FREQUENCY — Chapter-by-Chapter Campaign\n",
     "*Story summaries are authored; objectives, puzzles, collectibles and checkpoints are generated from the shipped chapter data by `tools/gen_docs.py`.*\n",
     "| # | Chapter | Location | Main threat | Signature mechanic |", "|---|---|---|---|---|"]
LOC = {0: ("Prologue", "1998 facility (cinematic)", "—", "Opening cinematic + first title reveal"), 1: ("THE ARRIVAL", "Mountain entrance, security checkpoint", "Glimpse only", "Receiver tutorial (89.1, 101.3), second title reveal"),
 2: ("THE SILENT WING", "Administration", "Patrol", "94.6 proximity, lockers, mimicry rule"), 3: ("WHAT REMAINS", "Medical wing", "Stalker (freezes when watched)", "107.9 reveal, crate & plate"),
 4: ("BELOW THE SURFACE", "Residential quarters", "Patrol / hunt if the door is opened", "96.1 Mira, knocking-door choice"), 5: ("THE VOICES", "Power station", "Patrol → first chase", "Breaker order from a 1998 echo, noise masking"),
 6: ("NO WAY BACK", "Flood tunnels", "Patrol in water (louder steps)", "Valves readable only on 107.9"), 7: ("THE SIGNAL ROOM", "Communications centre", "Patrol", "Numbers station 99.7, feed-horn alignment, uplink"),
 8: ("THE ECHO PROJECT", "Research labs", "Scripted forecasts", "101.3 forecasts that come true"), 9: ("DEAD LINE", "Transport line", "Patrol → chase to the tram", "Switch order, the Mira revelation"),
 10: ("WHAT LISTENS", "Containment", "Invisible stalker (107.9 only)", "Bulkhead choice (trust)"), 11: ("EVERY VOICE EVER LOST", "Archive", "Ambush (uses learned habits)", "Vault codes, Hale's last tape, shutdown key"),
 12: ("02:43", "Aperture ring", "Patrol → blind listener", "Three emitters, silent approach"), 13: ("THE LAST TRANSMISSION", "The Door", "—", "Final choice → four endings")}
for n, v in LOC.items(): w.append(f"| {n:02d} | {v[0]} | {v[1]} | {v[2]} | {v[3]} |")
for chd in CH:
    if "ending" in chd: continue
    n = chd["n"]
    w.append(f"\n---\n\n## {title_of(chd)}\n\n*{chd.get('sub', '')}*\n\n{SUMMARY.get(n, '')}\n")
    ob = objectives(chd)
    if ob: w.append("**Objectives (in order shown to the player)**\n"); w += [f"1. {o}" for o in ob]; w.append("")
    pz = puzzles(chd)
    if pz: w.append("**Puzzles & gates**\n"); w += [f"- {p}" for p in pz]; w.append("")
    co = collectibles(chd)
    if co: w.append("**Discoveries**\n"); w += [f"- {c}" for c in co]; w.append("")
    ai = chd.get("ai", [])
    w.append("**The Listener** — " + ("; ".join(f"{s.get('mode', 'patrol')} from `{s['at']}`" + (f" once `{s['if']}`" if 'if' in s else "") + (f" until `{s['ifnot']}`" if 'ifnot' in s else "") for s in ai) if ai else "scripted appearances only") + (". **Cloaked**: visible only on 107.9 or at arm's length." if chd.get("cloaked") else ""))
    saves = sum(row.count("V") for row in chd["map"])
    w.append(f"\n**Saves** — automatic at chapter start and at story checkpoints; {saves} emergency-log terminal(s) for manual saves.\n")
open(os.path.join(out, "04_CAMPAIGN.md"), "w").write("\n".join(w) + "\n")

# 05: solutions/QA walkthrough
w = ["# DEAD FREQUENCY — Mission Design & QA Walkthrough\n",
     "*Generated. Contains full spoilers. The critical path below is exactly the step list the automated playthrough test (`tools/test.sh play`) executes against the real game; if it passes, every chapter can be completed.*\n"]
for chd in CH:
    if "ending" in chd or chd["n"] == 0: continue
    w.append(f"\n## {title_of(chd)}\n")
    steps = []
    for s in chd.get("walk", []):
        if isinstance(s, list):
            if s[0] == "radio": l = chd["leg"][s[1]]; steps.append(f"Tune **{l['f']} MHz** near the source and face it — {l.get('title', '')}")
            elif s[0] == "choice": steps.append(f"*(choice for the next decision: option {int(s[1]) + 1})*")
            elif s[0] == "crate": steps.append("Push the crate onto the pressure plate")
        else:
            l = chd["leg"].get(s) or {"t": "builtin"}
            steps.append(label(s, l) + (f" (code {l['code']})" if l.get("code") else ""))
    w += [f"{i + 1}. {s}" for i, s in enumerate(steps)]
    w.append("\n**Mission objectives**: " + " → ".join(objectives(chd)))
w.append("\n## Ending requirements\n")
w.append("| Ending | Final choice | Also requires |\n|---|---|---|")
w.append("| B — The Open Door | Open | — |")
w.append("| D — The Last Transmission | Answer | kept the bulkhead sealed (`trust_mira`), heard Hale's last tape (`hale_truth`), at least 5 of 7 Evelyn tapes, carrying the shutdown key |")
w.append("| A — Silence | Shut down | carrying the shutdown key |")
w.append("| C — The Loop | anything else | (shut down without the key, or answer without the full truth) |")
open(os.path.join(out, "05_MISSION_DESIGN.md"), "w").write("\n".join(w) + "\n")

# 08: level design
BUILT = {"S": "player start", "L": "ceiling light", "F": "flickering light", "R": "red emergency light", "P": "Listener patrol point", "H": "hiding locker", "V": "emergency-log terminal (save)", "D": "door", "#": "wall", ".": "floor"}
w = ["# DEAD FREQUENCY — Level Design\n",
     "Every level is authored as an ASCII grid (one character = 2 × 2 m cell) plus a legend, in `game/data/chNN.gd`. At load the engine builds walls/floors/ceilings with triplanar PBR materials, places props and lights, bakes an A* navigation grid for the Listener (locked doors and blocking props disabled), and auto-dresses corridors with pipe runs and debris. The layout test (`tools/test.sh layout`) proves no prop ever blocks a passage; the walkthrough test proves every step is reachable.\n",
     "Built-in symbols: " + ", ".join(f"`{k}` {v}" for k, v in BUILT.items()) + ".\n"]
for chd in CH:
    if "ending" in chd: continue
    w.append(f"\n---\n\n## {title_of(chd)}\n")
    w.append(f"Palette: **{chd.get('pal')}** · ceiling height {chd.get('h', 'palette default')} · grid {len(chd['map'][0])}×{len(chd['map'])} cells ({len(chd['map'][0]) * 2}×{len(chd['map']) * 2} m)" + (" · starts unpowered (emergency lighting only)" if chd.get("dark") else "") + "\n")
    w.append("```"); w += chd["map"]; w.append("```")
    leg = []
    for k, l in chd["leg"].items():
        desc = label(k, l)
        if l["t"] == "prop": desc = f"prop: {l['p']}" + (" (blocks navigation)" if l.get("block") else "")
        if l["t"] == "light": desc = "light" + (" (always on)" if l.get("always") else "") + (" red" if l.get("red") else "")
        if l["t"] == "mark": desc = "marker (camera / spawn point)"
        if l["t"] == "pcrate": desc = "physics crate"
        if l["t"] == "hide": desc = "hiding locker"
        leg.append(f"`{k}` {desc}")
    w.append("Legend: " + " · ".join(leg) + "\n")
open(os.path.join(out, "08_LEVEL_DESIGN.md"), "w").write("\n".join(w) + "\n")
print("generated 04 05 06 07 08")
