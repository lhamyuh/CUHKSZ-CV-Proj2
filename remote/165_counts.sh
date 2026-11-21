#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
source $ROOT/env/bin/activate
python - <<PY
from plyfile import PlyData
import os
R = "$ROOT"
for p in ["runs/obj_w/point_cloud/iteration_30000/point_cloud.ply",
          "runs/obj_w/point_cloud/iteration_30000/point_cloud_pruned.ply",
          "runs/obj_w/point_cloud/iteration_30000/point_cloud_refined.ply",
          "runs/obj_w/point_cloud/iteration_30000/point_cloud_smooth3.ply",
          "runs/obj_d2/point_cloud/iteration_30000/point_cloud.ply",
          "runs/obj_d2/point_cloud/iteration_30000/point_cloud_refined.ply"]:
    f = os.path.join(R, p)
    if os.path.exists(f):
        print(len(PlyData.read(f)["vertex"]), p)
PY
echo COUNTS_DONE