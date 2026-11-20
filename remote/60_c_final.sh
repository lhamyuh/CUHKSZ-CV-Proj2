#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
SCENE=$ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply
OBJ=$ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_pruned2.ply
python code/prune_object.py --run $ROOT/runs/obj_w --masks $ROOT/data_object/masks \
  --ply $OBJ --out $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_pruned3.ply \
  --min_ratio 0.0 --max_dist 1.9 --white_thresh 0.92 --scale_shrink 1.0 2>&1 | tail -2
python code/fuse_scene.py --scene $SCENE --object $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_pruned3.ply \
  --placement $ROOT/runs/fusion/placement_v6.json --out $ROOT/runs/fusion/fused_final2.ply 2>&1 | tail -1
rm -rf $ROOT/runs/fusion/frames2
python code/render_views.py --ply $ROOT/runs/fusion/fused_final2.ply --cameras $ROOT/runs/fusion/path.json \
  --out $ROOT/runs/fusion/frames2 --bg 0 2>&1 | tail -1
python code/make_mp4.py --frames $ROOT/runs/fusion/frames2 --out $ROOT/preview/fusion2.mp4 --fps 24 2>&1 | tail -1
cp $ROOT/runs/fusion/frames2/frame_000.png $ROOT/preview/c0.png
cp $ROOT/runs/fusion/frames2/frame_150.png $ROOT/preview/c150.png
cp $ROOT/runs/fusion/frames2/frame_205.png $ROOT/preview/c205.png
cp $ROOT/runs/fusion/frames2/frame_239.png $ROOT/preview/c239.png
echo C_FINAL_DONE