#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
SCENE=$ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply
OBJ=$ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_pruned.ply
python code/prune_object.py --run $ROOT/runs/obj_w --masks $ROOT/data_object/masks \
  --out $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_pruned2.ply --min_ratio 0.75 2>&1 | tail -2
python code/fuse_scene.py --scene $SCENE --object $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_pruned2.ply \
  --placement $ROOT/runs/fusion/placement_v5.json --out $ROOT/runs/fusion/fused_final.ply 2>&1 | tail -1
python code/render_views.py --ply $ROOT/runs/fusion/fused_final.ply --cameras $ROOT/runs/fusion/path.json \
  --out $ROOT/runs/fusion/frames --bg 0 2>&1 | tail -2
python code/make_mp4.py --frames $ROOT/runs/fusion/frames --out $ROOT/preview/fusion.mp4 --fps 24 2>&1 | tail -1
echo C_VIDEO_DONE