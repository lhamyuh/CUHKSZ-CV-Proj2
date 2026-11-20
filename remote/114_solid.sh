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
for cfg in "s1 1.35 1.0" "s2 1.50 1.4"; do
set -- $cfg
python code/phong_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --object $ROOT/runs/obj_d2/point_cloud/iteration_30000/point_cloud_refined.ply \
  --placement $ROOT/runs/fusion/placement_d.json --view_pos="$VIEW" \
  --ka 0.62 --kd 0.55 --ks 0.08 --shininess 24 --clearance_pct 8 --weighted_contact 1 --base_align 1 \
  --scale_boost $2 --opacity_add $3 --shadow_strength 0.5 --shadow_len 0.26 --shadow_wid 0.14 \
  --out_scene $ROOT/runs/fusion/$1.ply --out_placement $ROOT/preview/$1.json 2>&1 | grep -E "grounded|rotated|shadow:"
python code/render_views.py --ply $ROOT/runs/fusion/$1.ply --cameras $ROOT/runs/fusion/one.json --out $ROOT/runs/fusion/probe_$1 --bg 0 2>&1 | tail -1
done
python - <<'PY'
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
ims=[]
for n,t in (('s1','boost 1.35 / +1.0'),('s2','boost 1.50 / +1.4')):
    im=Image.open(f'{R}/runs/fusion/probe_{n}/frame_000.png').convert('RGB').crop((250,260,850,680)).resize((600,420), Image.LANCZOS)
    c=Image.new('RGB',(600,444),'white'); c.paste(im,(0,24)); ImageDraw.Draw(c).text((6,6),t,fill='black'); ims.append(c)
row=Image.new('RGB',(1200,444),'white')
for i,c in enumerate(ims): row.paste(c,(i*600,0))
row.save(f'{G}/solid_variants.jpg', quality=88); print('ok')
PY
echo SOLID_DONE