#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/make_mp4.py --frames $ROOT/runs/garden_base/frames_orbit --out $ROOT/preview/scene_orbit.mp4 --fps 24 2>&1 | tail -1
python code/make_gallery.py --root $ROOT 2>&1 | tail -2
cd $ROOT/gallery && (curl -s -o /dev/null -w "index=%{http_code} gif=%{http_code} scene=%{http_code}\n" http://127.0.0.1:6006/index.html http://127.0.0.1:6006/B/B_orbit.gif http://127.0.0.1:6006/media/scene_orbit.mp4 || true)
echo SCENE_MP4_DONE