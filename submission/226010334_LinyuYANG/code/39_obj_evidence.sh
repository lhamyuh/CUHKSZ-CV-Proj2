#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
M=$ROOT/runs/obj_w
PLY=$M/point_cloud/iteration_30000/point_cloud.ply

echo "=== orbit cameras ==="
python code/make_orbit_cameras.py --ply $PLY --out $M/orbit.json --n 120 --size 512 \
  --fovy_deg 42 --elev_deg 18 --radius_scale 2.2 2>&1 | tail -2

echo "=== render orbit ==="
python code/render_views.py --ply $PLY --cameras $M/orbit.json --out $M/orbit_frames --bg 1 2>&1 | tail -2

echo "=== gif ==="
python code/frames_to_gif.py --frames $M/orbit_frames --out $ROOT/preview/obj_orbit.gif --size 480 --fps 20 2>&1 | tail -2

echo "=== stages at fixed val camera ==="
python - <<'PY'
import json
src = json.load(open('/root/autodl-tmp/CIE6004_ASGN2/data_object/val_cameras.json'))
v = src['views'][8]
one = {k: src[k] for k in ('width','height','fx','fy','cx','cy')}
one['views'] = [v]
json.dump(one, open('/root/autodl-tmp/CIE6004_ASGN2/runs/obj_w/stage_cam.json','w'))
print('stage camera', v['name'])
PY
for it in 5000 10000 15000 30000; do
  python code/render_views.py --ply $M/point_cloud/iteration_$it/point_cloud.ply \
    --cameras $M/stage_cam.json --out $M/stages/$it --bg 1 2>&1 | tail -1
done

echo "=== 3 fixed views for ablation ==="
python - <<'PY'
import json
src = json.load(open('/root/autodl-tmp/CIE6004_ASGN2/data_object/val_cameras.json'))
views = [src['views'][i] for i in (3, 8, 20)]
one = {k: src[k] for k in ('width','height','fx','fy','cx','cy')}
one['views'] = views
json.dump(one, open('/root/autodl-tmp/CIE6004_ASGN2/runs/obj_w/ablation_cams.json','w'))
print('ablation cams', [v['name'] for v in views])
PY
python code/render_views.py --ply $PLY --cameras $M/ablation_cams.json --out $M/views_ablation --bg 1 2>&1 | tail -1

echo OBJ_EVIDENCE_DONE
