#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
SCENE=$ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply
OBJ=$ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_pruned.ply
python code/fuse_scene.py --scene $SCENE --object $OBJ --placement $ROOT/runs/fusion/placement_v3.json --out $ROOT/runs/fusion/f3.ply 2>&1 | tail -1
python code/render_views.py --ply $ROOT/runs/fusion/f3.ply --cameras $ROOT/runs/fusion/closeup.json --out $ROOT/runs/fusion/closeup3 --bg 0 2>&1 | tail -1
python code/render_views.py --ply $ROOT/runs/fusion/f3.ply --cameras $ROOT/runs/fusion/cam0.json --out $ROOT/runs/fusion/try3 --bg 0 2>&1 | tail -1
cp $ROOT/runs/fusion/f3.ply $ROOT/runs/fusion/fused_final.ply
echo V3_DONE