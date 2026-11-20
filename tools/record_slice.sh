#!/bin/bash
# Records a gameplay video of the vertical slice: real movement, radio, encounter script and Listener AI, driven by
# the t_slicerec test controller (game/tests/test.gd). Each frame is exactly 1/30 s of game time (--fixed-fps 30),
# so the video plays at true speed however slowly the machine renders. The video is silent: the cloud machine has
# no audio device, and with a fixed frame time the audio clock would not match the picture.
#   tools/record_slice.sh [out.mp4] [WxH] [preset 0-4]
out=${1:-docs/media/slice_gameplay.mp4}; res=${2:-1280x720}; preset=${3:-2}
frames=$(mktemp -d)
cd "$(dirname "$0")/.." || exit 1
DF_TIMEOUT=${DF_TIMEOUT:-14400} tools/test.sh slicerec DF_RES="$res" DF_SCREEN="$res" DF_PRESET="$preset" DF_OUT="$frames" \
  DF_GODOT_ARGS="--fixed-fps 30" || { echo "recording failed"; exit 1; }
mkdir -p "$(dirname "$out")"
ffmpeg -y -loglevel error -framerate 30 -i "$frames/f%05d.png" -c:v libx264 -preset slow -crf 22 -pix_fmt yuv420p -movflags +faststart "$out"
echo "wrote $out ($(ls "$frames" | wc -l) frames)"; rm -rf "$frames"
