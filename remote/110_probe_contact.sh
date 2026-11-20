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
run () {
  name=$1; pct=$2; sh=$3
  python code/phong_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
    --object $ROOT/runs/obj_d2/point_cloud/iteration_30000/point_cloud_refined.ply \
    --placement $ROOT/runs/fusion/placement_d.json --view_pos="$VIEW" \
    --ka 0.62 --kd 0.55 --ks 0.08 --shininess 24 --clearance_pct $pct \
    --scale_boost 1.18 --opacity_add 0.6 --shadow_strength $sh \
    --shadow_len 0.26 --shadow_wid 0.14 --shadow_offset 0.55 \
    --out_scene $ROOT/runs/fusion/p_$name.ply --out_placement $ROOT/preview/p_$name.json 2>&1 | tail -2
  python - <<PY
import json
d=json.load(open('/root/autodl-tmp/CIE6004_ASGN2/runs/fusion/path_d.json'))
one={k:d[k] for k in ('width','height','fx','fy','cx','cy')}; one['views']=[d['views'][0]]
json.dump(one, open('/root/autodl-tmp/CIE6004_ASGN2/runs/fusion/one.json','w'))
PY
  python code/render_views.py --ply $ROOT/runs/fusion/p_$name.ply --cameras $ROOT/runs/fusion/one.json --out $ROOT/runs/fusion/probe_$name --bg 0 2>&1 | tail -1
}
run a 10 0.0
run b 25 0.45
run c 25 0.75
python - <<'PY'
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
ims=[]
for n,t in (('a','p10, no shadow'),('b','p25, shadow 0.45'),('c','p25, shadow 0.75')):
    im=Image.open(f'{R}/runs/fusion/probe_{n}/frame_000.png').convert('RGB').crop((250,260,850,680)).resize((520,364), Image.LANCZOS)
    c=Image.new('RGB',(520,388),'white'); c.paste(im,(0,24)); ImageDraw.Draw(c).text((6,6),t,fill='black'); ims.append(c)
row=Image.new('RGB',(1560,388),'white')
for i,c in enumerate(ims): row.paste(c,(i*520,0))
row.save(f'{G}/contact_variants.jpg', quality=88); print('ok')
PY
echo PROBE_DONE