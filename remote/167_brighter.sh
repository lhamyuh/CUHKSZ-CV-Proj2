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
run () {
  tag=$1; dg=$2; gn=$3; ao=$4
  python code/phong_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
    --object $OBJ --placement $ROOT/preview/placement_h.json --view_pos="$VIEW" \
    --ka 0.70 --kd 0.55 --ks 0.05 --shininess 24 --weighted_contact 1 --base_align 1 --base_mode percentile \
    --scale_boost 1.30 --opacity_add 0.9 --deglare $dg --gain $gn \
    --shadow_strength 0.85 --shadow_len 0.28 --shadow_wid 0.17 --shadow_offset 0.45 \
    --ao_strength $ao --ao_radius 0.20 \
    --out_scene $ROOT/runs/fusion/br_$tag.ply --out_placement $ROOT/preview/placement_br_$tag.json 2>&1 | grep -E "shading|wrote"
  python code/render_views.py --ply $ROOT/runs/fusion/br_$tag.ply --cameras $ROOT/runs/fusion/one.json --out $ROOT/runs/fusion/pbr_$tag --bg 0 2>&1 | tail -1
  rm -f $ROOT/runs/fusion/br_$tag.ply
}
run a 0.80 1.15 0.35
run b 0.95 1.00 0.35
python - <<'PY'
from PIL import Image, ImageDraw
import numpy as np
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
tiles=[]
for t,lab in (('basic','basic merge'),('a','deglare .80 gain 1.15'),('b','deglare .95 gain 1.00')):
    p = f'{R}/runs/fusion/pair_basic/frame_000.png' if t=='basic' else f'{R}/runs/fusion/pbr_{t}/frame_000.png'
    im=Image.open(p).convert('RGB')
    crop=im.crop((200,240,900,700))
    a=np.asarray(crop).astype(float)
    lum=a.mean()
    c=Image.new('RGB',(560,392),'white'); c.paste(crop.resize((560,368), Image.LANCZOS),(0,24))
    ImageDraw.Draw(c).text((6,6), f'{lab}  (mean {lum:.0f})', fill='black')
    tiles.append(c)
row=Image.new('RGB',(1680,392),'white')
for i,c in enumerate(tiles): row.paste(c,(i*560,0))
row.save(f'{G}/brighter_cmp.jpg', quality=90); print('ok')
PY
echo BRIGHTER_DONE