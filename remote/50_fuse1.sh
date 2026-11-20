#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
SCENE=$ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply
OBJ=$ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud.ply
for y in 0 180; do
python code/fuse_scene.py --scene $SCENE --object $OBJ --placement $ROOT/runs/placement_yaw$y.json --out $ROOT/runs/fusion/fused_$y.ply 2>&1 | tail -1
python code/render_views.py --ply $ROOT/runs/fusion/fused_$y.ply --cameras $ROOT/runs/fusion/cam0.json --out $ROOT/runs/fusion/try_$y --bg 0 2>&1 | tail -1
done
rm -f $ROOT/runs/fusion/fused_*.ply
echo FUSE2_DONE