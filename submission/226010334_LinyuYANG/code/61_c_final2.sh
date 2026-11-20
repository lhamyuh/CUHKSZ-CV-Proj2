#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
rm -rf $ROOT/runs/fusion/frames3
python code/render_views.py --ply $ROOT/runs/fusion/fused_final2.ply --cameras $ROOT/runs/fusion/path2.json \
  --out $ROOT/runs/fusion/frames3 --bg 0 2>&1 | tail -1
python code/make_mp4.py --frames $ROOT/runs/fusion/frames3 --out $ROOT/preview/fusion3.mp4 --fps 24 2>&1 | tail -1
for i in 000 080 120 160 200 239; do cp $ROOT/runs/fusion/frames3/frame_$i.png $ROOT/preview/g$i.png; done
echo C_FINAL2_DONE