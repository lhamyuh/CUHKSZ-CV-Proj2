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
COMMON="--ka 0.75 --kd 0.45 --ks 0.05 --shininess 24 --weighted_contact 1 --base_align 1 --base_mode percentile --scale_boost 1.30 --opacity_add 0.9 --shadow_strength 0.40 --shadow_len 0.18 --shadow_wid 0.11 --shadow_offset 0.25 --ao_strength 0.22 --ao_radius 0.14"
python code/phong_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --object $OBJ --placement $ROOT/preview/placement_h.json --view_pos="$VIEW" $COMMON \
  --deglare 0.95 --gain 1.00 --out_scene $ROOT/runs/fusion/cfinal.ply --out_placement $ROOT/preview/placement_cfinal.json 2>&1 | tail -3
rm -rf $ROOT/runs/fusion/cfinal_frames
python code/render_views.py --ply $ROOT/runs/fusion/cfinal.ply --cameras $ROOT/runs/fusion/path_h.json --out $ROOT/runs/fusion/cfinal_frames --bg 0 2>&1 | tail -1
python code/make_mp4.py --frames $ROOT/runs/fusion/cfinal_frames --out $ROOT/preview/fusion_cfinal.mp4 --fps 24 2>&1 | tail -1
python - <<'PY'
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
lab={'000':'0.0 s  establish','150':'6.2 s  occluded','239':'10.0 s  revealed'}
row=Image.new('RGB',(1920,384),'white')
for j,(k,t) in enumerate(lab.items()):
    x=Image.open(f'{R}/runs/fusion/cfinal_frames/frame_{k}.png').convert('RGB').resize((640,360), Image.LANCZOS)
    c=Image.new('RGB',(640,384),'white'); c.paste(x,(0,24)); ImageDraw.Draw(c).text((6,6),t,fill='black'); row.paste(c,(j*640,0))
row.save(f'{G}/cfinal_strip3.jpg', quality=88)
# matched bonus pair: basic merge vs final
for t,src in (('basic', f'{R}/runs/fusion/pair_basic/frame_000.png'), ('final', f'{R}/runs/fusion/cfinal_frames/frame_000.png')):
    pass
a=Image.open(f'{R}/runs/fusion/pair_basic/frame_000.png').convert('RGB').crop((200,240,900,700)).resize((560,368), Image.LANCZOS)
b=Image.open(f'{R}/runs/fusion/cfinal_frames/frame_000.png').convert('RGB').crop((200,240,900,700)).resize((560,368), Image.LANCZOS)
pair=Image.new('RGB',(1120,392),'white')
for i,(im,t) in enumerate(((a,'basic merge'),(b,'+ base alignment, grounding, shadow, relighting'))):
    c=Image.new('RGB',(560,392),'white'); c.paste(im,(0,24)); ImageDraw.Draw(c).text((6,6),t,fill='black'); pair.paste(c,(i*560,0))
pair.save(f'{G}/bonus_pair_final.jpg', quality=90)
print('ok')
PY
rm -f $ROOT/runs/fusion/cfinal.ply
echo FINAL_C_DONE