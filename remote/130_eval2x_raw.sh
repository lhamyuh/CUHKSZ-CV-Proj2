#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/render_views.py --ply $ROOT/runs/obj_x2/point_cloud/iteration_30000/point_cloud_refined.ply \
  --cameras $ROOT/runs/obj_w/ablation_cams.json --out $ROOT/runs/obj_x2/views_ablation_raw --bg 1 2>&1 | tail -1
python code/eval_object.py --renders $ROOT/runs/obj_x2/views_ablation_raw --frames $ROOT/data_object/frames \
  --masks $ROOT/data_object/masks --cams $ROOT/runs/obj_w/ablation_cams.json --out $ROOT/runs/obj_x2/eval_raw.json 2>&1 | tail -3
echo EVAL2X_RAW_DONE