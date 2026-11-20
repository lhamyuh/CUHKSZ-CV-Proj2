#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
PLY=$ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply
echo "=== render val ==="
python code/render_views.py --ply $PLY --cameras $ROOT/release/val/cameras.json --out $ROOT/runs/garden_base/renders_val 2>&1 | tail -2
echo "=== render test ==="
python code/render_views.py --ply $PLY --cameras $ROOT/release/test/cameras.json --out $ROOT/runs/garden_base/renders_test 2>&1 | tail -2
echo "=== render trajectory ==="
python code/render_views.py --ply $PLY --cameras $ROOT/release/trajectory/garden.json --out $ROOT/runs/garden_base/frames_orbit 2>&1 | tail -2
echo "=== encode orbit mp4 ==="
python code/make_mp4.py --frames $ROOT/runs/garden_base/frames_orbit --out $ROOT/runs/garden_base/orbit.mp4 --fps 24 2>&1 | tail -2
echo "=== evaluate val ==="
python $ROOT/release/tools/evaluate.py $ROOT/release/val $ROOT/runs/garden_base/renders_val $ROOT/runs/garden_base/metrics_val.json 2>&1 | tail -5
echo EVAL_DONE