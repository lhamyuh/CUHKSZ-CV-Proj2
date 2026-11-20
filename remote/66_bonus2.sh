#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/bonus_shadow.py --ply $ROOT/runs/fusion/fused_v7.ply --n_object 114828 \
  --placement $ROOT/runs/fusion/placement_v7.json --out $ROOT/runs/fusion/fused_bonus2.ply \
  --shadow_radius 0.40 --shadow_sigma 0.16 --shadow_strength 0.80 --object_gain 0.90 2>&1 | tail -2
python code/render_views.py --ply $ROOT/runs/fusion/fused_bonus2.ply --cameras $ROOT/runs/fusion/bonus_cam.json --out $ROOT/runs/fusion/bonus2 --bg 0 2>&1 | tail -1
cp $ROOT/runs/fusion/bonus2/frame_120.png $ROOT/preview/bonus_after2.png
echo BONUS2_DONE