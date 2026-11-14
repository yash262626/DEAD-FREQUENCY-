#!/bin/bash
# Builds the clean Windows release package:
#   build/release/DeadFrequency-<version>-Windows-x64/  and  build/DeadFrequency-<version>-Windows-x64.zip
# Usage: tools/package_release.sh [--export]
#   --export   re-export build/windows/DeadFrequency.exe from the current source first
#              (needs the Godot 3.5.2 export templates; imports assets if needed)
set -e
root="$(cd "$(dirname "$0")/.." && pwd)"; cd "$root"
ver=$(sed -n 's/^config\/version="\(.*\)"/\1/p' game/project.godot)
name="DeadFrequency-$ver-Windows-x64"
exe=build/windows/DeadFrequency.exe
if [ "$1" = "--export" ]; then
  tools/import_assets.sh
  mkdir -p build/windows
  (cd game && timeout 900 xvfb-run -a godot3 --no-window --export "Windows Desktop" "../$exe" 2>&1 | tail -2)
fi
[ -f "$exe" ] || { echo "missing $exe (run with --export)"; exit 1; }
out=build/release/$name
rm -rf "$out" "build/$name.zip"; mkdir -p "$out/licenses"
cp "$exe" "$out/DeadFrequency.exe"
sed "s/{VERSION}/$ver/" release/README.txt > "$out/README.txt"
cp docs/PRIVACY.md "$out/PRIVACY.txt"
cp docs/THIRD_PARTY_NOTICES.md "$out/THIRD_PARTY_NOTICES.txt"
cp licenses/*.txt "$out/licenses/"
# credits: generated from the in-game credits list so the two can never differ
python3 - "$out/CREDITS.txt" <<'PY'
import re, sys
src = open("game/data/story.gd").read()
block = src[src.index("const CREDITS"):]; block = block[:block.index("\n]\n")]
lines = []
for kind, val in re.findall(r'\["(\w+)", "([^"]*)"\]', block):
    if kind == "gap": lines.append("") if int(val) >= 40 and (not lines or lines[-1] != "") else None
    else: lines.append(val)
open(sys.argv[1], "w").write("\n".join(lines).strip() + "\n")
PY
# Windows line endings for the text files (Notepad on older Windows 10 needs them)
for f in "$out"/*.txt "$out"/licenses/*.txt; do sed -i 's/\r$//; s/$/\r/' "$f"; done
(cd "$out" && find . -type f ! -name SHA256SUMS.txt | sort | xargs sha256sum > SHA256SUMS.txt)
(cd build/release && zip -qr9 "../$name.zip" "$name")
echo "package: build/$name.zip ($(du -h "build/$name.zip" | cut -f1))"
ls -la "$out" "$out/licenses"
