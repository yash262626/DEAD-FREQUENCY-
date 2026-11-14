#!/usr/bin/env python3
"""Fetches CC0 assets from Poly Haven (https://polyhaven.com, CC0 1.0) into the Godot project.

    python3 tools/fetch_polyhaven.py model <id> [res=1k]     → game/assets/models/<id>/   (glTF + textures)
    python3 tools/fetch_polyhaven.py tex   <id> [res=2k]     → game/assets/surfaces/<id>/ (diff, nor_gl, arm, disp as jpg/png)

Every fetched id is appended to game/assets/POLYHAVEN_ASSETS.txt, which THIRD_PARTY_NOTICES.md lists.
Only JSON metadata and asset files are downloaded; nothing downloaded is executed.
"""
import json, os, sys, urllib.request

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "assets")
API = "https://api.polyhaven.com"

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "dead-frequency-asset-fetch/1.0"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return r.read()

def save(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)

def record(kind, aid, res):
    p = os.path.join(ROOT, "POLYHAVEN_ASSETS.txt")
    line = f"{kind}\t{aid}\t{res}\thttps://polyhaven.com/a/{aid}\n"
    have = open(p).read() if os.path.exists(p) else ""
    if f"\t{aid}\t" not in have:
        with open(p, "a") as f:
            f.write(line)

def model(aid, res="1k"):
    files = json.loads(get(f"{API}/files/{aid}"))
    g = files["gltf"][res]["gltf"]
    out = os.path.join(ROOT, "models", aid)
    save(os.path.join(out, f"{aid}.gltf"), get(g["url"]))
    total = g.get("size", 0)
    for rel, v in g.get("include", {}).items():
        save(os.path.join(out, rel), get(v["url"]))
        total += v.get("size", 0)
    record("model", aid, res)
    print(f"model {aid} {res}: {total / 1e6:.1f} MB")

def tex(aid, res="2k"):
    files = json.loads(get(f"{API}/files/{aid}"))
    out = os.path.join(ROOT, "surfaces", aid)
    want = {"Diffuse": "diff", "nor_gl": "nor_gl", "arm": "arm", "Displacement": "disp", "AO": "ao", "Rough": "rough", "Metal": "metal"}
    total = 0
    for key, short in want.items():
        if key not in files or res not in files[key]:
            continue
        fmts = files[key][res]
        f = fmts.get("jpg") or fmts.get("png")
        if not f:
            continue
        ext = "jpg" if "jpg" in fmts else "png"
        save(os.path.join(out, f"{short}.{ext}"), get(f["url"]))
        total += f.get("size", 0)
    record("texture", aid, res)
    print(f"texture {aid} {res}: {total / 1e6:.1f} MB")

if __name__ == "__main__":
    kind, aid = sys.argv[1], sys.argv[2]
    res = sys.argv[3] if len(sys.argv) > 3 else ("1k" if kind == "model" else "2k")
    (model if kind == "model" else tex)(aid, res)
