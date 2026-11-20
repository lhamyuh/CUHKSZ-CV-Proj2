#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/crop_proj.py --render $ROOT/runs/fusion/closeup_v13/closeup.png --cameras $ROOT/runs/fusion/closeup.json \
  --placement $ROOT/preview/placement_v13.json --out $ROOT/preview/zoom_v13.jpg --zoom 0.14 2>&1 | tail -2
python code/crop_proj.py --render $ROOT/runs/fusion/probe_v13/frame_120.png --cameras $ROOT/runs/fusion/bonus_cam.json \
  --placement $ROOT/preview/placement_v13.json --out $ROOT/preview/zoom_probe_v13.jpg --zoom 0.12 2>&1 | tail -2
echo CROP_DONE