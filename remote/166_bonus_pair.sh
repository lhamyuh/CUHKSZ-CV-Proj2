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
OBJ=$ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_smooth3.ply
python code/phong_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --object $OBJ --placement $ROOT/preview/placement_h.json --view_pos="$VIEW" \
  --ka 1.0 --kd 0.0 --ks 0.0 --weighted_contact 1 --base_align 1 --base_mode percentile \
  --shadow_strength 0 --ao_strength 0 --scale_boost 1.0 --opacity_add 0 --deglare 0 \
  --out_scene $ROOT/runs/fusion/basic.ply --out_placement $ROOT/preview/placement_basic.json 2>&1 | tail -2
python code/phong_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --object $OBJ --placement $ROOT/preview/placement_h.json --view_pos="$VIEW" \
  --ka 0.62 --kd 0.55 --ks 0.06 --shininess 24 --weighted_contact 1 --base_align 1 --base_mode percentile \
  --scale_boost 1.30 --opacity_add 0.9 --deglare 0.38 --gain 1.45 \
  --shadow_strength 0.85 --shadow_len 0.28 --shadow_wid 0.17 --shadow_offset 0.45 \
  --ao_strength 0.60 --ao_radius 0.20 \
  --out_scene $ROOT/runs/fusion/improved.ply --out_placement $ROOT/preview/placement_improved.json 2>&1 | tail -2
for t in basic improved; do
  python code/render_views.py --ply $ROOT/runs/fusion/$t.ply --cameras $ROOT/runs/fusion/one.json --out $ROOT/runs/fusion/pair_$t --bg 0 2>&1 | tail -1
  rm -f $ROOT/runs/fusion/$t.ply
done
python - <<'PY'
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
ims=[]
for t,lab in (('basic','basic merge'),('improved','+ alignment, grounding, shadow, relight')):
    im=Image.open(f'{R}/runs/fusion/pair_{t}/frame_000.png').convert('RGB').crop((200,240,900,700)).resize((560,368), Image.LANCZOS)
    c=Image.new('RGB',(560,392),'white'); c.paste(im,(0,24)); ImageDraw.Draw(c).text((6,6),lab,fill='black'); ims.append(c)
row=Image.new('RGB',(1120,392),'white')
for i,c in enumerate(ims): row.paste(c,(i*560,0))
row.save(f'{G}/bonus_pair_final.jpg', quality=90); print('ok')
PY
echo BONUS_PAIR_DONE