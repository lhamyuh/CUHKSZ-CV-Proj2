#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
OBJ=$ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_smooth3.ply
echo "=== masked PSNR of the delivered model ==="
python code/render_views.py --ply $OBJ --cameras $ROOT/runs/obj_w/ablation_cams.json --out $ROOT/runs/obj_w/views_sm3 --bg 1 2>&1 | tail -1
python code/eval_object.py --renders $ROOT/runs/obj_w/views_sm3 --frames $ROOT/data_object/frames \
  --masks $ROOT/data_object/masks --cams $ROOT/runs/obj_w/ablation_cams.json --out $ROOT/runs/obj_w/eval_sm3.json 2>&1 | tail -2
echo "=== orbit gif ==="
rm -rf $ROOT/runs/obj_w/orbit_frames_sm3
python code/render_views.py --ply $OBJ --cameras $ROOT/runs/obj_w/orbit.json --out $ROOT/runs/obj_w/orbit_frames_sm3 --bg 1 2>&1 | tail -1
python code/frames_to_gif.py --frames $ROOT/runs/obj_w/orbit_frames_sm3 --out $ROOT/preview/obj_orbit_final.gif --size 480 --fps 20 2>&1 | tail -1
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
  --base_align 1 --base_mode percentile --scale_boost 1.25 --opacity_add 1.0 --deglare 0.45 --gain 1.45 \
  --shadow_strength 0.90 --shadow_len 0.22 --shadow_wid 0.14 --shadow_offset 0.35 \
  --ao_strength 0.35 --ao_radius 0.14 \
  --out_scene $ROOT/runs/fusion/wfinal.ply --out_placement $ROOT/preview/placement_wfinal.json 2>&1 | tail -4
rm -rf $ROOT/runs/fusion/wfinal_frames
python code/render_views.py --ply $ROOT/runs/fusion/wfinal.ply --cameras $ROOT/runs/fusion/path_h.json \
  --out $ROOT/runs/fusion/wfinal_frames --bg 0 2>&1 | tail -1
python code/make_mp4.py --frames $ROOT/runs/fusion/wfinal_frames --out $ROOT/preview/fusion_wfinal.mp4 --fps 24 2>&1 | tail -1
rm -f $ROOT/runs/fusion/wfinal.ply
python - <<'PY'
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
lab={'000':'0.0 s  establish','150':'6.2 s  occluded','239':'10.0 s  revealed'}
row=Image.new('RGB',(1920,384),'white')
for j,(k,t) in enumerate(lab.items()):
    x=Image.open(f'{R}/runs/fusion/wfinal_frames/frame_{k}.png').convert('RGB').resize((640,360), Image.LANCZOS)
    c=Image.new('RGB',(640,384),'white'); c.paste(x,(0,24)); ImageDraw.Draw(c).text((6,6),t,fill='black'); row.paste(c,(j*640,0))
row.save(f'{G}/wfinal_strip.jpg', quality=88)
Image.open(f'{R}/runs/fusion/wfinal_frames/frame_000.png').convert('RGB').crop((250,260,850,680)).resize((760,532), Image.LANCZOS).save(f'{G}/wfinal_zoom.jpg', quality=86)
print('ok')
PY
echo FINAL_W_DONE