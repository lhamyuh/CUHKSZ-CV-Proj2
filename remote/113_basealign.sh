#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
VIEW=$(python - <<'PY' | tail -1
import json, numpy as np
d=json.load(open('/root/autodl-tmp/CIE6004_ASGN2/runs/fusion/path_d.json'))
M=np.array(d['views'][0]['world_to_camera']); C=-M[:3,:3].T@M[:3,3]
print(','.join('%.4f'%x for x in C))
PY
)
python - <<'PY'
import json
d=json.load(open('/root/autodl-tmp/CIE6004_ASGN2/runs/fusion/path_d.json'))
one={k:d[k] for k in ('width','height','fx','fy','cx','cy')}; one['views']=[d['views'][0]]
json.dump(one, open('/root/autodl-tmp/CIE6004_ASGN2/runs/fusion/one.json','w'))
PY
python code/phong_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --object $ROOT/runs/obj_d2/point_cloud/iteration_30000/point_cloud_refined.ply \
  --placement $ROOT/runs/fusion/placement_d.json --view_pos="$VIEW" \
  --ka 0.62 --kd 0.55 --ks 0.08 --shininess 24 --clearance_pct 8 --weighted_contact 1 --base_align 1 \
  --scale_boost 1.18 --opacity_add 0.6 --shadow_strength 0.5 \
  --shadow_len 0.26 --shadow_wid 0.14 --shadow_offset 0.55 \
  --out_scene $ROOT/runs/fusion/ba.ply --out_placement $ROOT/preview/placement_ba.json 2>&1 | tail -6
python code/render_views.py --ply $ROOT/runs/fusion/ba.ply --cameras $ROOT/runs/fusion/one.json --out $ROOT/runs/fusion/probe_ba --bg 0 2>&1 | tail -1
python - <<'PY'
from PIL import Image
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
im=Image.open(f'{R}/runs/fusion/probe_ba/frame_000.png').convert('RGB')
im.crop((250,260,850,680)).resize((760,532), Image.LANCZOS).save(f'{G}/ba_zoom.jpg', quality=86)
print('ok')
PY
echo BASEALIGN_DONE