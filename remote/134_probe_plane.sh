#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
VIEW=$(python - <<'PY' | tail -1
import json, numpy as np
d=json.load(open('/root/autodl-tmp/CIE6004_ASGN2/runs/fusion/path_h.json'))
M=np.array(d['views'][0]['world_to_camera']); C=-M[:3,:3].T@M[:3,3]
print(','.join('%.4f'%x for x in C))
PY
)
OBJ=${1:-$ROOT/runs/obj_x2/point_cloud/iteration_30000/point_cloud_smooth.ply}
python code/phong_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --object $OBJ --placement $ROOT/preview/placement_h.json --view_pos="$VIEW" \
  --ka 0.62 --kd 0.55 --ks 0.08 --shininess 24 --clearance_pct 6 --weighted_contact 0 \
  --base_align 1 --base_mode plane --scale_boost 1.20 --opacity_add 0.8 --deglare 0.68 \
  --shadow_strength 0.78 --shadow_len 0.30 --shadow_wid 0.18 --shadow_offset 0.90 \
  --ao_strength 0.55 --ao_radius 0.16 \
  --out_scene $ROOT/runs/fusion/pp.ply --out_placement $ROOT/preview/placement_pp.json 2>&1 | tail -7
python code/render_views.py --ply $ROOT/runs/fusion/pp.ply --cameras $ROOT/runs/fusion/one.json --out $ROOT/runs/fusion/probe_pp --bg 0 2>&1 | tail -1
python - <<'PY'
from PIL import Image
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
Image.open(f'{R}/runs/fusion/probe_pp/frame_000.png').convert('RGB').crop((250,260,850,680)).resize((760,532), Image.LANCZOS).save(f'{G}/pp_zoom.jpg', quality=86)
print('ok')
PY
echo PROBE_PLANE_DONE