#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python - <<'PY'
import json
p='/root/autodl-tmp/CIE6004_ASGN2/runs/fusion/path4.json'
d=json.load(open(p)); one={k:d[k] for k in ('width','height','fx','fy','cx','cy')}; one['views']=[d['views'][120]]
json.dump(one, open('/root/autodl-tmp/CIE6004_ASGN2/runs/fusion/bonus_cam.json','w'))
print('camera', d['views'][120]['name'])
PY
python code/bonus_shadow.py --ply $ROOT/runs/fusion/fused_v7.ply --n_object 114828 \
  --placement $ROOT/runs/fusion/placement_v7.json --out $ROOT/runs/fusion/fused_bonus.ply 2>&1 | tail -3
python code/render_views.py --ply $ROOT/runs/fusion/fused_bonus.ply --cameras $ROOT/runs/fusion/bonus_cam.json --out $ROOT/runs/fusion/bonus --bg 0 2>&1 | tail -1
cp $ROOT/runs/fusion/bonus/frame_120.png $ROOT/preview/bonus_after.png
echo BONUS_DONE