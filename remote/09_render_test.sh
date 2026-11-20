#!/usr/bin/env bash
set -euo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/render_views.py --ply runs/garden_smoke/point_cloud/iteration_2000/point_cloud.ply \
  --cameras release/val/cameras.json --out runs/garden_smoke/renders_val --limit 3 2>&1 | tail -5
ls -l runs/garden_smoke/renders_val
echo RENDER_OK