#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/fuse_scene.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --object $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_pruned3.ply \
  --placement $ROOT/runs/fusion/placement_v7.json --out $ROOT/runs/fusion/fused_v7.ply 2>&1 | tail -1
rm -rf $ROOT/runs/fusion/frames4
python code/render_views.py --ply $ROOT/runs/fusion/fused_v7.ply --cameras $ROOT/runs/fusion/path3.json \
  --out $ROOT/runs/fusion/frames4 --bg 0 2>&1 | tail -1
python code/make_mp4.py --frames $ROOT/runs/fusion/frames4 --out $ROOT/preview/fusion4.mp4 --fps 24 2>&1 | tail -1
for i in 000 060 100 140 180 220 239; do cp $ROOT/runs/fusion/frames4/frame_$i.png $ROOT/preview/h$i.png; done
echo C_FINAL3_DONE