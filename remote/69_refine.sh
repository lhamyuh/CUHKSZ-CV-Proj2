#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
echo "=== refine object ==="
python code/refine_object.py --ply $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_pruned3.ply \
  --out $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_refined.ply \
  --min_opacity 0.03 --max_scale 0.12 --gain 1.5 --bias 0.6 2>&1 | tail -4
echo "=== refine fusion ==="
python code/refine_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --object $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_refined.ply \
  --placement $ROOT/runs/fusion/placement_v7.json \
  --out_scene $ROOT/runs/fusion/fused_v8.ply --out_placement $ROOT/preview/placement_v8.json 2>&1 | tail -8
echo "=== render orbit probe (8 frames) ==="
python - <<'PY'
import json
o=json.load(open('/root/autodl-tmp/CIE6004_ASGN2/runs/obj_w/orbit.json'))
one={k:o[k] for k in ('width','height','fx','fy','cx','cy')}
one['views']=[o['views'][i] for i in range(0,120,15)]
json.dump(one, open('/root/autodl-tmp/CIE6004_ASGN2/runs/obj_w/orbit_probe.json','w'))
PY
python code/render_views.py --ply $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_refined.ply \
  --cameras $ROOT/runs/obj_w/orbit_probe.json --out $ROOT/runs/obj_w/orbit_probe --bg 1 2>&1 | tail -1
echo "=== render fusion probe ==="
python code/render_views.py --ply $ROOT/runs/fusion/fused_v8.ply --cameras $ROOT/runs/fusion/bonus_cam.json \
  --out $ROOT/runs/fusion/probe_v8 --bg 0 2>&1 | tail -1
python code/render_views.py --ply $ROOT/runs/fusion/fused_v8.ply --cameras $ROOT/runs/fusion/closeup.json \
  --out $ROOT/runs/fusion/closeup_v8 --bg 0 2>&1 | tail -1
echo REFINE_DONE