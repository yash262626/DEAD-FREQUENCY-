#!/usr/bin/env python3
"""Turns playtesters' play-time logs into measured chapter times.

Each tester sends the file  %APPDATA%\\Godot\\app_userdata\\DEAD FREQUENCY\\playtest.json
(written by the game itself: seconds of unpaused play, deaths and completion per chapter, per run).

    python3 tools/playtest_report.py playtests/*.json  > playtests/REPORT.md

Only chapters a run actually completed are timed. Chapter-select runs are counted per chapter; full-campaign
totals use only runs started with NEW GAME / NEW GAME+ that reached an ending. This is the evidence required
before the campaign length may be quoted (docs/17_TIME_BUDGET.md).
"""
import json, statistics, sys

def load(paths):
    runs = []
    for p in paths:
        try:
            d = json.load(open(p, encoding="utf-8"))
        except (OSError, ValueError) as e:
            print(f"skipping {p}: {e}", file=sys.stderr); continue
        for rid, r in d.items():
            if isinstance(r, dict) and isinstance(r.get("ch"), dict):
                runs.append((p, rid, r))
    return runs

def fmt(m): return f"{m:.0f}"

def main(paths):
    runs = load(paths)
    if not runs:
        print("No play-time logs found."); return 1
    print(f"# Playtest timing report\n\n{len(runs)} runs from {len(set(p for p, _, _ in runs))} log files.\n")
    print("| Ch | Completions | Median min | Min–max min | Deaths per completion |\n|---|---|---|---|---|")
    for ch in range(1, 14):
        t = [float(r["ch"][str(ch)]["t"]) / 60 for _, _, r in runs if str(ch) in r["ch"] and r["ch"][str(ch)].get("done")]
        dz = [int(r["ch"][str(ch)].get("deaths", 0)) for _, _, r in runs if str(ch) in r["ch"] and r["ch"][str(ch)].get("done")]
        if t:
            print(f"| {ch:02d} | {len(t)} | {fmt(statistics.median(t))} | {fmt(min(t))}–{fmt(max(t))} | {statistics.mean(dz):.1f} |")
        else:
            print(f"| {ch:02d} | 0 | – | – | – |")
    full = [sum(float(c["t"]) for c in r["ch"].values()) / 3600 for _, _, r in runs
            if r.get("mode") in ("new", "ngplus") and r.get("ending")]
    print()
    if full:
        print(f"Complete campaigns (start to an ending): {len(full)} — median {statistics.median(full):.1f} h, "
              f"range {min(full):.1f}–{max(full):.1f} h (unpaused play, excluding the ending and credits).")
    else:
        print("No complete campaign yet: the total length is not measured.")
    ends = {}
    for _, _, r in runs:
        if r.get("ending"): ends[r["ending"]] = ends.get(r["ending"], 0) + 1
    if ends: print("\nEndings reached: " + ", ".join(f"{k} ×{v}" for k, v in sorted(ends.items())))
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
