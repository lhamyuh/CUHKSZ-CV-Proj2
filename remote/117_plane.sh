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
python code/phong_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --object $ROOT/runs/obj_d2/point_cloud/iteration_30000/point_cloud_refined.ply \
  --placement $ROOT/runs/fusion/placement_d.json --view_pos="$VIEW" \
  --ka 0.62 --kd 0.55 --ks 0.08 --shininess 24 --clearance_pct 6 --weighted_contact 1 \
  --base_align 1 --base_mode plane --scale_boost 1.35 --opacity_add 1.0 --deglare 0.68 \
  --shadow_strength 0.5 --shadow_len 0.24 --shadow_wid 0.13 --shadow_offset 0.30 \
  --out_scene $ROOT/runs/fusion/h.ply --out_placement $ROOT/preview/placement_h.json 2>&1 | tail -6
python code/render_views.py --ply $ROOT/runs/fusion/h.ply --cameras $ROOT/runs/fusion/one.json --out $ROOT/runs/fusion/probe_h --bg 0 2>&1 | tail -1
python - <<'PY'
from PIL import Image
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
Image.open(f'{R}/runs/fusion/probe_h/frame_000.png').convert('RGB').crop((250,260,850,680)).resize((760,532), Image.LANCZOS).save(f'{G}/h_zoom.jpg', quality=86)
print('ok')
PY
echo PLANE_DONE