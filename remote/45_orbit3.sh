#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
M=$ROOT/runs/obj_w
PLY=$M/point_cloud/iteration_30000/point_cloud.ply
python code/make_orbit_cameras.py --ply $PLY --out $M/orbit.json --n 120 --size 512 \
  --fovy_deg 40 --elev_deg 20 --radius_scale 3.0 2>&1 | tail -1
python code/render_views.py --ply $PLY --cameras $M/orbit.json --out $M/orbit_frames --bg 1 2>&1 | tail -1
echo ORBIT3_DONE