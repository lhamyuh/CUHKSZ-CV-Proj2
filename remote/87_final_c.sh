#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/refine_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --object $ROOT/runs/obj_d2/point_cloud/iteration_30000/point_cloud_refined.ply \
  --placement $ROOT/runs/fusion/placement_v15.json --clearance_pct 10 \
  --shadow_sigma 0.12 --shadow_strength 0.70 --object_gain 1.35 --base_disc 4000 \
  --out_scene $ROOT/runs/fusion/fused_final3.ply --out_placement $ROOT/preview/placement_final.json 2>&1 | tail -3
rm -rf $ROOT/runs/fusion/final_frames
python code/render_views.py --ply $ROOT/runs/fusion/fused_final3.ply --cameras $ROOT/runs/fusion/path5.json \
  --out $ROOT/runs/fusion/final_frames --bg 0 2>&1 | tail -1
python code/make_mp4.py --frames $ROOT/runs/fusion/final_frames --out $ROOT/preview/fusion_final.mp4 --fps 24 2>&1 | tail -1
for i in 000 060 120 180 239; do cp $ROOT/runs/fusion/final_frames/frame_$i.png $ROOT/preview/f_$i.png; done
echo FINAL_C_DONE