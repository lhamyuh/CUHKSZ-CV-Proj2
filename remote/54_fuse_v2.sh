#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
SCENE=$ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply
OBJ=$ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_pruned.ply
for y in 0 180; do
python code/fuse_scene.py --scene $SCENE --object $OBJ --placement $ROOT/runs/placement_v2_yaw$y.json --out $ROOT/runs/fusion/fused_v2_$y.ply 2>&1 | tail -1
python code/render_views.py --ply $ROOT/runs/fusion/fused_v2_$y.ply --cameras $ROOT/runs/fusion/cam0.json --out $ROOT/runs/fusion/tryv2_$y --bg 0 2>&1 | tail -1
rm -f $ROOT/runs/fusion/fused_v2_$y.ply
done
echo FUSE_V2_DONE