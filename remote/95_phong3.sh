#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
VIEW=$(python - <<'PY' | tail -1
import json, numpy as np
d=json.load(open('/root/autodl-tmp/CIE6004_ASGN2/runs/fusion/path_c.json'))
M=np.array(d['views'][0]['world_to_camera']); C=-M[:3,:3].T@M[:3,3]
print(','.join('%.4f'%x for x in C))
PY
)
python code/phong_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --object $ROOT/runs/obj_k/point_cloud/iteration_30000/point_cloud_refined.ply \
  --placement $ROOT/runs/fusion/placement_c.json --view_pos="$VIEW" \
  --ka 0.55 --kd 0.45 --ks 0.12 --shininess 24 --gain 1.0 \
  --shadow_strength 0.45 --shadow_len 0.25 --shadow_wid 0.13 --shadow_offset 0.55 \
  --out_scene $ROOT/runs/fusion/fused_phong.ply --out_placement $ROOT/preview/placement_phong.json 2>&1 | tail -5
python code/render_views.py --ply $ROOT/runs/fusion/fused_phong.ply --cameras $ROOT/runs/fusion/path_c.json \
  --out $ROOT/runs/fusion/phong_frames --bg 0 2>&1 | tail -1
python - <<'PY'
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
fr=[]
for i in ('000','060','120','180','239'):
    im=Image.open(f'{R}/runs/fusion/phong_frames/frame_{i}.png').convert('RGB').resize((420,236), Image.LANCZOS)
    c=Image.new('RGB',(420,260),'white'); c.paste(im,(0,24)); ImageDraw.Draw(c).text((6,6),f'{int(i)/24:.1f}s',fill='black'); fr.append(c)
row=Image.new('RGB',(1260,260),'white')
for i,c in enumerate(fr[:3]): row.paste(c,(i*420,0))
row.save(f'{G}/phong_strip.jpg', quality=88)
row2=Image.new('RGB',(840,260),'white'); row2.paste(fr[3],(0,0)); row2.paste(fr[4],(420,0)); row2.save(f'{G}/phong_strip2.jpg', quality=90)
print('ok')
PY
echo PHONG3_DONE