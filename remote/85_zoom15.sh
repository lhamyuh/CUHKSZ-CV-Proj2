#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/crop_proj.py --render $ROOT/runs/fusion/probe_v15/probe.png --cameras $ROOT/runs/fusion/probe_cam15.json \
  --placement $ROOT/preview/placement_v15b.json --out $ROOT/preview/zoom_v15.jpg --zoom 0.16 2>&1 | tail -1
echo ZOOM15_DONE