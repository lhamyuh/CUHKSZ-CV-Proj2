#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/refine_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --object $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_refined2.ply \
  --placement $ROOT/runs/fusion/placement_v7.json --clearance_pct 10 \
  --shadow_sigma 0.12 --shadow_strength 0.70 --object_gain 1.35 --base_disc 4000 \
  --out_scene $ROOT/runs/fusion/fused_v14.ply --out_placement $ROOT/preview/placement_v14.json 2>&1 | tail -3
python code/render_views.py --ply $ROOT/runs/fusion/fused_v14.ply --cameras $ROOT/runs/fusion/closeup.json --out $ROOT/runs/fusion/closeup_v14 --bg 0 2>&1 | tail -1
python code/render_views.py --ply $ROOT/runs/fusion/fused_v14.ply --cameras $ROOT/runs/fusion/bonus_cam.json --out $ROOT/runs/fusion/probe_v14 --bg 0 2>&1 | tail -1
python code/crop_proj.py --render $ROOT/runs/fusion/closeup_v14/closeup.png --cameras $ROOT/runs/fusion/closeup.json --placement $ROOT/preview/placement_v14.json --out $ROOT/preview/zoom_v14.jpg --zoom 0.14 2>&1 | tail -1
python code/crop_proj.py --render $ROOT/runs/fusion/probe_v14/frame_120.png --cameras $ROOT/runs/fusion/bonus_cam.json --placement $ROOT/preview/placement_v14.json --out $ROOT/preview/zoom_probe_v14.jpg --zoom 0.12 2>&1 | tail -1
echo V14_DONE