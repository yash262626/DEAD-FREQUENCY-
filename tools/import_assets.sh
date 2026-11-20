#!/bin/bash
# Imports every asset (CC0 textures and models, slice art, the icon) into game/.import so the game and the tests
# can load them. Needed after a fresh clone or after adding assets: .import/ is a cache and is not committed.
# Godot 3 has no "import only" switch and `--editor --quit` exits before the import scan, so this runs the
# editor on a virtual display until every source file has its cache entry, then stops it.
cd "$(dirname "$0")/../game" || exit 1
missing() {   # importable sources with no cache entry yet, or changed since they were imported
  find . -type f -not -path "./.import/*" \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.gltf" -o -iname "*.glb" \
    -o -iname "*.ogg" -o -iname "*.wav" -o -iname "*.exr" -o -iname "*.hdr" -o -iname "*.obj" \) | while read -r f; do
    rel="${f#./}"; h=$(printf '%s' "res://$rel" | md5sum | cut -c1-32)
    m=".import/$(basename "$rel")-$h.md5"
    if [ ! -f "$m" ]; then echo "$rel"; continue; fi
    grep -q "source_md5=\"$(md5sum < "$f" | cut -c1-32)\"" "$m" || echo "$rel"    # changed since the last import
  done
}
n=$(missing | wc -l)
if [ "$n" -eq 0 ]; then echo "assets already imported"; exit 0; fi
echo "importing $n files"
xvfb-run -a godot3 --editor --path . > /tmp/df_import.log 2>&1 &
pid=$!
for i in $(seq 1 "${DF_IMPORT_WAIT:-300}"); do
  sleep 2
  [ "$(missing | wc -l)" -eq 0 ] && break
done
sleep 4   # let the last file finish writing
pkill -f "godot3 --editor --path \." 2>/dev/null; kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
left=$(missing | wc -l); echo "not imported: $left"
[ "$left" -eq 0 ]
