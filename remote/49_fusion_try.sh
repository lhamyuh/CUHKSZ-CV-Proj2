#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
mkdir -p $ROOT/runs/fusion
ls -l $ROOT/runs/placement_yaw*.json
python - <<'PY'
import json
tj = json.load(open('/root/autodl-tmp/CIE6004_ASGN2/release/trajectory/garden.json'))
one = {k: tj[k] for k in ('width','height','fx','fy','cx','cy')}
one['views'] = [tj['views'][0]]
json.dump(one, open('/root/autodl-tmp/CIE6004_ASGN2/runs/fusion/cam0.json','w'))
print('cam0 written', tj['views'][0]['name'])
PY
SCENE=$ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply
OBJ=$ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud.ply
ls -lh $SCENE $OBJ
for y in 0 90 180 270; do
  python code/fuse_scene.py --scene $SCENE --object $OBJ --placement $ROOT/runs/placement_yaw$y.json --out $ROOT/runs/fusion/fused_$y.ply 2>&1 | tail -1
  python code/render_views.py --ply $ROOT/runs/fusion/fused_$y.ply --cameras $ROOT/runs/fusion/cam0.json --out $ROOT/runs/fusion/try_$y --bg 0 2>&1 | tail -1
  rm -f $ROOT/runs/fusion/fused_$y.ply
done
echo FUSION_TRYS_DONE