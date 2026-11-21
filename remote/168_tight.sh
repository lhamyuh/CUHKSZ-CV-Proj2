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
for tag in a b; do
  if [ "$tag" = "a" ]; then SH=0.55; SL=0.20; SW=0.12; SO=0.30; AO=0.30; DG=0.85; GN=1.05; else SH=0.40; SL=0.18; SW=0.11; SO=0.25; AO=0.22; DG=0.95; GN=1.00; fi
  python code/phong_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
    --object $OBJ --placement $ROOT/preview/placement_h.json --view_pos="$VIEW" \
    --ka 0.75 --kd 0.45 --ks 0.05 --shininess 24 --weighted_contact 1 --base_align 1 --base_mode percentile \
    --scale_boost 1.30 --opacity_add 0.9 --deglare $DG --gain $GN \
    --shadow_strength $SH --shadow_len $SL --shadow_wid $SW --shadow_offset $SO \
    --ao_strength $AO --ao_radius 0.14 \
    --out_scene $ROOT/runs/fusion/tg_$tag.ply --out_placement $ROOT/preview/placement_tg_$tag.json 2>&1 | grep -E "shading|shadow:"
  python code/render_views.py --ply $ROOT/runs/fusion/tg_$tag.ply --cameras $ROOT/runs/fusion/one.json --out $ROOT/runs/fusion/ptg_$tag --bg 0 2>&1 | tail -1
  rm -f $ROOT/runs/fusion/tg_$tag.ply
done
python - <<'PY'
from PIL import Image, ImageDraw
import numpy as np
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
tiles=[]
for t,lab in (('basic','basic merge'),('a','shadow .55 / ao .30'),('b','shadow .40 / ao .22')):
    p = f'{R}/runs/fusion/pair_basic/frame_000.png' if t=='basic' else f'{R}/runs/fusion/ptg_{t}/frame_000.png'
    im=Image.open(p).convert('RGB'); crop=im.crop((200,240,900,700)); a=np.asarray(crop).astype(float)
    c=Image.new('RGB',(560,392),'white'); c.paste(crop.resize((560,368), Image.LANCZOS),(0,24))
    ImageDraw.Draw(c).text((6,6), f'{lab} (crop mean {a.mean():.0f})', fill='black'); tiles.append(c)
row=Image.new('RGB',(1680,392),'white')
for i,c in enumerate(tiles): row.paste(c,(i*560,0))
row.save(f'{G}/tight_cmp.jpg', quality=90); print('ok')
PY
echo TIGHT_DONE