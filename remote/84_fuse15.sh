#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/refine_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --object $ROOT/runs/obj_d2/point_cloud/iteration_30000/point_cloud_refined.ply \
  --placement $ROOT/runs/fusion/placement_v15.json --clearance_pct 10 \
  --shadow_sigma 0.12 --shadow_strength 0.70 --object_gain 1.35 --base_disc 4000 \
  --out_scene $ROOT/runs/fusion/fused_v15.ply --out_placement $ROOT/preview/placement_v15b.json 2>&1 | tail -4
python code/render_views.py --ply $ROOT/runs/fusion/fused_v15.ply --cameras $ROOT/runs/fusion/probe_cam15.json --out $ROOT/runs/fusion/probe_v15 --bg 0 2>&1 | tail -1
echo FUSE15_DONE