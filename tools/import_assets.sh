#!/bin/bash
# Imports every asset (the CC0 textures, the icon) into game/.import so the game and the tests can load them.
# Needed once after a fresh clone: .import/ is a cache and is not committed.
# Godot 3 has no "import only" switch and `--editor --quit` exits before the import scan, so this runs the
# editor on a virtual display until every source has its cache entry, then stops it. ~1 min on a 4-core CPU.
cd "$(dirname "$0")/../game" || exit 1
need=$(find . -name "*.import" -type f -not -path "./.import/*" | wc -l)
have() { ls .import 2>/dev/null | grep -c "\.md5$"; }
if [ "$(have)" -ge "$need" ]; then echo "assets already imported ($need)"; exit 0; fi
xvfb-run -a godot3 --editor --path . > /tmp/df_import.log 2>&1 &
pid=$!
for i in $(seq 1 "${DF_IMPORT_WAIT:-300}"); do
  [ "$(have)" -ge "$need" ] && break
  sleep 2
done
sleep 4   # let the last file finish writing
pkill -f "godot3 --editor --path \." 2>/dev/null; kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
n=$(have); echo "imported $n / $need"
[ "$n" -ge "$need" ]
