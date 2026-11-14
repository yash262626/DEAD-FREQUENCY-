#!/bin/bash
# Usage: tools/test.sh <mode> [ENV=VAL ...]   e.g. tools/test.sh validate
cd "$(dirname "$0")/../game" || exit 1
mode=$1; shift
env DF_TEST="$mode" "$@" timeout ${DF_TIMEOUT:-600} xvfb-run -a -s "-screen 0 1280x720x24" godot3 --resolution ${DF_RES:-256x144} tests/Test.tscn 2>&1 \
  | grep -vE "ALSA|alsa|audio_server|dummy driver|^ *$|XDG_RUNTIME|libpng warning|pulseaudio|rtkit|status < 0|init_device" | tee /tmp/df_test.log
rc=${PIPESTATUS[0]}
if grep -qE "SCRIPT ERROR|^ERROR" /tmp/df_test.log; then echo "== ENGINE ERRORS PRESENT"; rc=1; fi
exit $rc
