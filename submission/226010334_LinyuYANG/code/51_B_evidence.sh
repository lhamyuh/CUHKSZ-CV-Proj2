#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
M=$ROOT/runs/obj_w
echo "=== render d2 at ablation cams ==="
python code/render_views.py --ply $ROOT/runs/obj_d2/point_cloud/iteration_30000/point_cloud.ply \
  --cameras $M/ablation_cams.json --out $ROOT/runs/obj_d2/views_ablation --bg 1 2>&1 | tail -1
echo "=== eval baseline ==="
python code/eval_object.py --renders $M/views_ablation --frames $ROOT/data_object/frames \
  --masks $ROOT/data_object/masks --cams $M/ablation_cams.json --out $M/eval.json 2>&1 | tail -3
echo "=== eval d2 ==="
python code/eval_object.py --renders $ROOT/runs/obj_d2/views_ablation --frames $ROOT/data_object/frames \
  --masks $ROOT/data_object/masks --cams $M/ablation_cams.json --out $ROOT/runs/obj_d2/eval.json 2>&1 | tail -3
echo "=== loss csv ==="
python code/export_loss.py --run $M --out $ROOT/preview/loss.csv 2>&1 | tail -2
echo B_EVIDENCE_DONE