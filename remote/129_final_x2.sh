#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
OBJ=$ROOT/runs/obj_x2/point_cloud/iteration_30000/point_cloud_smooth.ply
echo "=== masked PSNR at val resolution ==="
python code/render_views.py --ply $OBJ --cameras $ROOT/runs/obj_w/ablation_cams.json --out $ROOT/runs/obj_x2/views_ablation --bg 1 2>&1 | tail -1
python code/eval_object.py --renders $ROOT/runs/obj_x2/views_ablation --frames $ROOT/data_object/frames \
  --masks $ROOT/data_object/masks --cams $ROOT/runs/obj_w/ablation_cams.json --out $ROOT/runs/obj_x2/eval.json 2>&1 | tail -3
echo "=== orbit gif ==="
rm -rf $ROOT/runs/obj_x2/orbit_frames
python code/render_views.py --ply $OBJ --cameras $ROOT/runs/obj_w/orbit.json --out $ROOT/runs/obj_x2/orbit_frames --bg 1 2>&1 | tail -1
python code/frames_to_gif.py --frames $ROOT/runs/obj_x2/orbit_frames --out $ROOT/preview/obj_orbit_x2.gif --size 480 --fps 20 2>&1 | tail -1
echo "=== fusion ==="
VIEW=$(python - <<'PY' | tail -1
import json, numpy as np
d=json.load(open('/root/autodl-tmp/CIE6004_ASGN2/runs/fusion/path_h.json'))
M=np.array(d['views'][0]['world_to_camera']); C=-M[:3,:3].T@M[:3,3]
print(','.join('%.4f'%x for x in C))
PY
)
python code/phong_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --object $OBJ --placement $ROOT/preview/placement_h.json --view_pos="$VIEW" \
  --ka 0.62 --kd 0.55 --ks 0.08 --shininess 24 --clearance_pct 6 --weighted_contact 1 \
  --base_align 1 --base_mode plane --scale_boost 1.20 --opacity_add 0.8 --deglare 0.68 \
  --shadow_strength 0.78 --shadow_len 0.30 --shadow_wid 0.18 --shadow_offset 0.90 \
  --ao_strength 0.55 --ao_radius 0.16 \
  --out_scene $ROOT/runs/fusion/x2.ply --out_placement $ROOT/preview/placement_x2.json 2>&1 | tail -5
rm -rf $ROOT/runs/fusion/x2_frames
python code/render_views.py --ply $ROOT/runs/fusion/x2.ply --cameras $ROOT/runs/fusion/path_h.json \
  --out $ROOT/runs/fusion/x2_frames --bg 0 2>&1 | tail -1
python code/make_mp4.py --frames $ROOT/runs/fusion/x2_frames --out $ROOT/preview/fusion_x2.mp4 --fps 24 2>&1 | tail -1
python - <<'PY'
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
fr=[]
for i in ('000','120','150','180','239'):
    im=Image.open(f'{R}/runs/fusion/x2_frames/frame_{i}.png').convert('RGB').resize((420,236), Image.LANCZOS)
    c=Image.new('RGB',(420,260),'white'); c.paste(im,(0,24)); ImageDraw.Draw(c).text((6,6),f'{int(i)/24:.1f}s',fill='black'); fr.append(c)
row=Image.new('RGB',(1260,260),'white')
for i,c in enumerate(fr[:3]): row.paste(c,(i*420,0))
row.save(f'{G}/x2_strip.jpg', quality=88)
row2=Image.new('RGB',(840,260),'white'); row2.paste(fr[3],(0,0)); row2.paste(fr[4],(420,0)); row2.save(f'{G}/x2_strip2.jpg', quality=90)
Image.open(f'{R}/runs/fusion/x2_frames/frame_000.png').convert('RGB').crop((250,260,850,680)).resize((760,532), Image.LANCZOS).save(f'{G}/x2_zoom.jpg', quality=86)
print('ok')
PY
echo FINAL_X2_DONE