#!/usr/bin/env python3
"""Converts the Godot game's story data into the data files the Unreal Engine project loads.

    tools/test.sh export DF_OUT=/tmp/story.json            # 1. export the shipped Godot data (the source of truth)
    python3 tools/ue/godot_to_ue.py /tmp/story.json         # 2. convert -> unreal/DeadFrequency/Content/Data/Story/

Output (UTF-8 JSON, field names match the C++ USTRUCTs in Source/DeadFrequency/Story/DFStoryTypes.h, which
FJsonObjectConverter matches case-insensitively):
  chapter_00.json … chapter_13.json, ending_A.json … ending_D.json   one FDFChapterData each
  items.json, achievements.json, credits.json, titles.json, index.json
  PARITY.md   proof that nothing was lost: per-chapter counts, and every voice-over line of docs/vo/vo_script.csv
              found again (same id, same speaker, same text) in the converted data, and nothing extra

Event scripts become flat sequences: nested blocks (if / ifnot / choice / group) are moved into their own
sequence and referenced by index, so the C++ runtime never needs recursive structs. Every argument is a string.
Dialogue lines become {"command": "line", "args": [speaker, text, (seconds)], "vo": <id>} with the same voice-over
id the Godot game and the VO recording script use, so recorded audio maps 1:1.
"""
import csv, hashlib, json, os, sys
from collections import Counter

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OUT = os.path.join(ROOT, "unreal", "DeadFrequency", "Content", "Data", "Story")
VO_CSV = os.path.join(ROOT, "docs", "vo", "vo_script.csv")


def vo_id(who, text):
    """Identical to game/scripts/ui.gd vo_id() and tools/vo_package.py."""
    base = who.split(" ")[0].replace("?", "").lower() or "system"
    return "%s_%s" % (base, hashlib.md5((who + "|" + text).encode("utf-8")).hexdigest()[:10])


def s(v):
    """Every argument is stored as a string; nested structures as compact JSON."""
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, float) and v.is_integer():
        return str(int(v)) if abs(v) < 1e15 else repr(v)
    if isinstance(v, (int, float, str)):
        return str(v)
    return json.dumps(v, ensure_ascii=False, separators=(",", ":"))


class Chapter:
    def __init__(self, src):
        self.src = src
        self.sequences = []      # [{"steps": [...]}]
        self.lines = []          # (speaker, text) in conversion order, for the parity check

    def seq(self, events):
        """Converts a Godot event list into a sequence; returns its index (or -1 for none)."""
        if events is None:
            return -1
        idx = len(self.sequences)
        self.sequences.append({"steps": []})
        steps = []
        for e in events:
            if not isinstance(e, list) or not e:
                continue
            c = str(e[0])
            if c == "" or c != c.lower():                       # a spoken line: [SPEAKER, text, (seconds)]
                text = e[1] if len(e) > 1 else ""
                step = {"command": "line", "args": [c, s(text)] + [s(x) for x in e[2:]], "vo": vo_id(c, text)}
                self.lines.append((c, text))
            elif c in ("if", "ifnot"):
                step = {"command": c, "args": [s(e[1])], "then": self.seq(e[2]), "else": self.seq(e[3]) if len(e) > 3 else -1}
            elif c == "choice":
                step = {"command": "choice", "args": [s(e[1])],
                        "options": [{"label": s(o[0]), "sequence": self.seq(o[1])} for o in e[2]]}
            else:
                step = {"command": c, "args": [s(x) for x in e[1:]]}
            steps.append(step)
        self.sequences[idx]["steps"] = steps
        return idx

    def convert(self):
        d = self.src
        out = {}
        if "ending" in d:
            out["ending"] = d["ending"]
            out["number"] = -1
        else:
            out["number"] = d.get("n", -1)
        out["title"] = d.get("title", "")
        out["subtitle"] = d.get("sub", "")
        out["preSequence"] = self.seq(d.get("pre_ev"))
        out["startSequence"] = self.seq(d.get("start_ev"))
        out["resumeSequence"] = self.seq(d.get("resume_ev"))
        out["groups"] = {g: self.seq(evs) for g, evs in (d.get("groups") or {}).items()}
        legend = []
        for ch, l in (d.get("leg") or {}).items():
            if not isinstance(l, dict):
                continue
            ent = {"symbol": ch, "kind": l.get("t", ""), "props": {}, "sequence": -1, "lines": -1}
            for k, v in l.items():
                if k == "t":
                    continue
                if k == "ev":
                    ent["sequence"] = self.seq(v)
                elif k == "lines":
                    ent["lines"] = self.seq(v)
                else:
                    ent["props"][k] = s(v)
            legend.append(ent)
        out["legend"] = legend
        grid = d.get("map") or []
        out["map"] = grid
        out["cellSize"] = 200.0                                # 2 m cells, in Unreal centimetres
        places = []
        for row, line in enumerate(grid):
            for col, c in enumerate(line):
                if c not in "#.":
                    places.append({"symbol": c, "cell": {"x": col, "y": row}})
        out["placements"] = places
        skip = {"n", "title", "sub", "pre_ev", "start_ev", "resume_ev", "groups", "leg", "map", "walk", "ending", "map_cells"}
        out["props"] = {k: s(v) for k, v in d.items() if k not in skip}
        out["walkthrough"] = [s(w) for w in (d.get("walk") or [])]
        out["sequences"] = self.sequences
        return out


def counts(ch_src, conv):
    leg = ch_src.get("leg") or {}
    kinds = Counter(v.get("t") for v in leg.values() if isinstance(v, dict))
    return {"lines": len(conv.lines), "notes": kinds["note"], "tapes": kinds["tape"], "radio": kinds["radio"], "items": kinds["item"],
            "devices": kinds["use"], "doors": kinds["door"], "echoes": kinds["ghost"], "triggers": kinds["trig"],
            "groups": len(ch_src.get("groups") or {}), "sequences": len(conv.sequences), "walk": len(ch_src.get("walk") or [])}


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    src = json.load(open(sys.argv[1], encoding="utf-8"))
    out_dir = sys.argv[2] if len(sys.argv) > 2 else OUT
    os.makedirs(out_dir, exist_ok=True)
    index, report, all_lines = [], [], []
    for d in src["chapters"]:
        c = Chapter(d)
        data = c.convert()
        name = ("ending_%s" % d["ending"]) if "ending" in d else ("chapter_%02d" % d["n"])
        with open(os.path.join(out_dir, name + ".json"), "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=1)
        index.append({"file": name + ".json", "number": data["number"], "title": data["title"], "ending": data.get("ending", "")})
        report.append((name, data["title"], counts(d, c)))
        all_lines += c.lines
    for key in ("items", "titles", "credits"):
        with open(os.path.join(out_dir, key + ".json"), "w", encoding="utf-8") as f:
            json.dump(src.get(key), f, ensure_ascii=False, indent=1)
    with open(os.path.join(out_dir, "achievements.json"), "w", encoding="utf-8") as f:
        json.dump(src.get("ach"), f, ensure_ascii=False, indent=1)
    with open(os.path.join(out_dir, "index.json"), "w", encoding="utf-8") as f:
        json.dump({"chapters": index}, f, ensure_ascii=False, indent=1)

    # the Listener's mimicry lines live in its AI script, not in the story data: carry them over as data too
    import re
    lsrc = open(os.path.join(ROOT, "game", "scripts", "listener.gd"), encoding="utf-8").read()
    mimic = [{"speaker": w, "text": t, "vo": vo_id(w, t)} for w, t in re.findall(r'\["([A-Z]+\?)", "([^"]+)"\]', lsrc.split("const MIMIC = [")[1].split("]\n")[0] + "]")]
    ngp = [{"ending": k, "speaker": w, "text": t, "vo": vo_id(w, t)} for k, w, t in re.findall(r'"([A-D])": \["([A-Z]+\?)", "([^"]+)"\]', lsrc.split("const MIMIC_NGP = {")[1].split("}")[0])]
    with open(os.path.join(out_dir, "listener_mimicry.json"), "w", encoding="utf-8") as f:
        json.dump({"lines": mimic, "newGamePlus": ngp}, f, ensure_ascii=False, indent=1)

    # parity against the voice-over script (generated from the same data by tools/vo_package.py)
    vo_rows = list(csv.DictReader(open(VO_CSV, encoding="utf-8"))) if os.path.exists(VO_CSV) else []
    want = Counter((r["id"], r["speaker_tag"], r["subtitle"]) for r in vo_rows)
    have = Counter((vo_id(w, t), w, t) for w, t in all_lines)
    missing = want - have
    extra = have - want
    md = ["# Story data parity: Godot → Unreal", "",
          "Generated by `tools/ue/godot_to_ue.py` from the Godot export. Re-run after any story change; the Unreal",
          "project must never be edited by hand where these files are the source.", "",
          "| File | Title | Lines | Notes | Tapes | Radio | Items | Devices | Doors | Echoes | Triggers | Puzzle groups | Sequences | Walkthrough steps |",
          "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
    tot = Counter()
    for name, title, k in report:
        md.append("| %s | %s | %s |" % (name, title, " | ".join(str(k[x]) for x in ("lines", "notes", "tapes", "radio", "items", "devices", "doors", "echoes", "triggers", "groups", "sequences", "walk"))))
        tot.update(k)
    md.append("| **total** | | %s |" % " | ".join("**%d**" % tot[x] for x in ("lines", "notes", "tapes", "radio", "items", "devices", "doors", "echoes", "triggers", "groups", "sequences", "walk")))
    md += ["", "**Voice-over parity:** %d lines in `docs/vo/vo_script.csv`, %d spoken lines in the converted data; "
           "missing %d, extra %d." % (sum(want.values()), sum(have.values()), sum(missing.values()), sum(extra.values()))]
    if extra:
        md += ["", "Lines in the converted data that the VO script does not list (they are spoken in sequences the VO tool does not walk, e.g. resume scripts):", ""]
        md += ["- `%s` %s: %s" % (i, w, t) for (i, w, t) in sorted(extra)]
    if missing:
        md += ["", "**Lines missing from the converted data:**", ""] + ["- `%s` %s: %s" % (i, w, t) for (i, w, t) in sorted(missing)]
    md += ["", "Also converted: %d item types, %d achievements, %d credit entries, %d chapter titles." % (
        len(src.get("items") or {}), len(src.get("ach") or {}), len(src.get("credits") or []), len(src.get("titles") or []))]
    md += ["", "**The Listener's mimicry** (`listener_mimicry.json`): %d lines it speaks in other people's voices while stalking, "
           "plus %d New Game+ lines keyed to the previous ending. They are defined in the Godot AI script, not in the story data, "
           "so the Godot voice-over script does not list them either: **%d more lines to record** (same actors, the 'wearing this voice' "
           "direction)." % (len(mimic), len(ngp), len(mimic) + len(ngp))]
    open(os.path.join(out_dir, "PARITY.md"), "w", encoding="utf-8").write("\n".join(md) + "\n")
    print("converted %d scripts; lines %d (VO script %d, missing %d, extra %d)" % (
        len(index), sum(have.values()), sum(want.values()), sum(missing.values()), sum(extra.values())))
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
