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
OBJ=$ROOT/runs/obj_d2/point_cloud/iteration_30000/point_cloud_smooth.ply
python code/phong_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --object $OBJ --placement $ROOT/preview/placement_h.json --view_pos="$VIEW" \
  --ka 0.62 --kd 0.55 --ks 0.08 --shininess 24 --clearance_pct 6 --weighted_contact 1 \
  --base_align 1 --base_mode percentile --scale_boost 1.30 --opacity_add 0.9 --deglare 0.68 \
  --shadow_strength 0.80 --shadow_len 0.30 --shadow_wid 0.19 --shadow_offset 0.55 \
  --ao_strength 0.60 --ao_radius 0.20 \
  --out_scene $ROOT/runs/fusion/final.ply --out_placement $ROOT/preview/placement_final3.json 2>&1 | tail -6
rm -rf $ROOT/runs/fusion/final_frames
python code/render_views.py --ply $ROOT/runs/fusion/final.ply --cameras $ROOT/runs/fusion/path_h.json \
  --out $ROOT/runs/fusion/final_frames --bg 0 2>&1 | tail -1
python code/make_mp4.py --frames $ROOT/runs/fusion/final_frames --out $ROOT/preview/fusion_final.mp4 --fps 24 2>&1 | tail -1
echo "=== orbit gif ==="
rm -rf $ROOT/runs/obj_d2/orbit_frames
python code/render_views.py --ply $OBJ --cameras $ROOT/runs/obj_w/orbit.json --out $ROOT/runs/obj_d2/orbit_frames --bg 1 2>&1 | tail -1
python code/frames_to_gif.py --frames $ROOT/runs/obj_d2/orbit_frames --out $ROOT/preview/obj_orbit.gif --size 480 --fps 20 2>&1 | tail -1
python - <<'PY'
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
fr=[]
for i in ('000','120','150','180','239'):
    im=Image.open(f'{R}/runs/fusion/final_frames/frame_{i}.png').convert('RGB').resize((420,236), Image.LANCZOS)
    c=Image.new('RGB',(420,260),'white'); c.paste(im,(0,24)); ImageDraw.Draw(c).text((6,6),f'{int(i)/24:.1f}s',fill='black'); fr.append(c)
row=Image.new('RGB',(1260,260),'white')
for i,c in enumerate(fr[:3]): row.paste(c,(i*420,0))
row.save(f'{G}/final_strip.jpg', quality=88)
row2=Image.new('RGB',(840,260),'white'); row2.paste(fr[3],(0,0)); row2.paste(fr[4],(420,0)); row2.save(f'{G}/final_strip2.jpg', quality=90)
im=Image.open(f'{R}/runs/fusion/final_frames/frame_000.png').convert('RGB')
im.crop((250,260,850,680)).resize((760,532), Image.LANCZOS).save(f'{G}/final_zoom.jpg', quality=86)
row3=Image.new('RGB',(1920,384),'white')
lab={'000':'0.0 s  establish','150':'6.2 s  occluded','239':'10.0 s  revealed'}
for j,(k,t) in enumerate(lab.items()):
    x=Image.open(f'{R}/runs/fusion/final_frames/frame_{k}.png').convert('RGB').resize((640,360), Image.LANCZOS)
    c=Image.new('RGB',(640,384),'white'); c.paste(x,(0,24)); ImageDraw.Draw(c).text((6,6),t,fill='black'); row3.paste(c,(j*640,0))
row3.save(f'{G}/final_strip3.jpg', quality=88)
print('ok')
PY
df -h /root/autodl-tmp | tail -1
echo FINAL_ALL_DONE