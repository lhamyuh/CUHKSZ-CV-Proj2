#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
rm -rf $ROOT/runs/fusion/frames5
python code/render_views.py --ply $ROOT/runs/fusion/fused_v7.ply --cameras $ROOT/runs/fusion/path4.json \
  --out $ROOT/runs/fusion/frames5 --bg 0 2>&1 | tail -1
python code/make_mp4.py --frames $ROOT/runs/fusion/frames5 --out $ROOT/preview/fusion5.mp4 --fps 24 2>&1 | tail -1
for i in 000 040 080 120 160 200 239; do cp $ROOT/runs/fusion/frames5/frame_$i.png $ROOT/preview/k$i.png; done
echo C_FINAL4_DONE