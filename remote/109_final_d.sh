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
  --ka 0.62 --kd 0.55 --ks 0.08 --shininess 24 --gain 1.0 \
  --scale_boost 1.18 --opacity_add 0.6 \
  --shadow_strength 0.45 --shadow_len 0.26 --shadow_wid 0.14 --shadow_offset 0.55 \
  --out_scene $ROOT/runs/fusion/fused_d.ply --out_placement $ROOT/preview/placement_d_final.json 2>&1 | tail -5
rm -rf $ROOT/runs/fusion/d_frames
python code/render_views.py --ply $ROOT/runs/fusion/fused_d.ply --cameras $ROOT/runs/fusion/path_d.json \
  --out $ROOT/runs/fusion/d_frames --bg 0 2>&1 | tail -1
python code/make_mp4.py --frames $ROOT/runs/fusion/d_frames --out $ROOT/preview/fusion_d.mp4 --fps 24 2>&1 | tail -1
python - <<'PY'
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
fr=[]
for i in ('000','096','150','200','239'):
    im=Image.open(f'{R}/runs/fusion/d_frames/frame_{i}.png').convert('RGB').resize((420,236), Image.LANCZOS)
    c=Image.new('RGB',(420,260),'white'); c.paste(im,(0,24)); ImageDraw.Draw(c).text((6,6),f'{int(i)/24:.1f}s',fill='black'); fr.append(c)
row=Image.new('RGB',(1260,260),'white')
for i,c in enumerate(fr[:3]): row.paste(c,(i*420,0))
row.save(f'{G}/d_strip.jpg', quality=88)
row2=Image.new('RGB',(840,260),'white'); row2.paste(fr[3],(0,0)); row2.paste(fr[4],(420,0)); row2.save(f'{G}/d_strip2.jpg', quality=90)
im=Image.open(f'{R}/runs/fusion/d_frames/frame_000.png').convert('RGB')
im.crop((250,260,850,680)).resize((900,630), Image.LANCZOS).save(f'{G}/d_zoom.jpg', quality=86)
print('ok')
PY
echo FINAL_D_DONE