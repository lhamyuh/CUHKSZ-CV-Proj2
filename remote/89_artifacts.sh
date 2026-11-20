#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
OBJ=$ROOT/runs/obj_d2/point_cloud/iteration_30000/point_cloud_refined.ply
echo "=== orbit gif (improved model) ==="
rm -rf $ROOT/runs/obj_d2/orbit_frames
python code/render_views.py --ply $OBJ --cameras $ROOT/runs/obj_w/orbit.json --out $ROOT/runs/obj_d2/orbit_frames --bg 1 2>&1 | tail -1
python code/frames_to_gif.py --frames $ROOT/runs/obj_d2/orbit_frames --out $ROOT/preview/obj_orbit.gif --size 480 --fps 20 2>&1 | tail -1
echo "=== bonus pair (same camera/placement) ==="
python code/refine_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --object $OBJ --placement $ROOT/runs/fusion/placement_v15.json --clearance_pct 10 \
  --shadow_sigma 0.12 --shadow_strength 0.0 --object_gain 1.0 --base_disc 0 \
  --out_scene $ROOT/runs/fusion/fused_basic.ply --out_placement $ROOT/preview/placement_basic.json 2>&1 | tail -1
python code/render_views.py --ply $ROOT/runs/fusion/fused_basic.ply --cameras $ROOT/runs/fusion/probe_cam15.json --out $ROOT/runs/fusion/bonus_basic --bg 0 2>&1 | tail -1
python code/render_views.py --ply $ROOT/runs/fusion/fused_final3.ply --cameras $ROOT/runs/fusion/probe_cam15.json --out $ROOT/runs/fusion/bonus_final --bg 0 2>&1 | tail -1
python - <<'PY'
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
b=Image.open(f'{R}/runs/fusion/bonus_basic/probe.png').convert('RGB')
a=Image.open(f'{R}/runs/fusion/bonus_final/probe.png').convert('RGB')
box=(500,250,780,470)
def lab(im,t,W=560):
    im=im.resize((W,int(im.height*W/im.width)), Image.LANCZOS)
    c=Image.new('RGB',(im.width,im.height+24),'white'); c.paste(im,(0,24)); ImageDraw.Draw(c).text((6,6),t,fill='black'); return c
row=Image.new('RGB',(1120,lab(b,'x').height),'white')
row.paste(lab(b,'basic (no shadow / no light match)',560),(0,0))
row.paste(lab(a,'improved (contact shadow + disc + match)',560),(560,0))
row.save(f'{G}/bonus_pair.jpg', quality=88)
# fusion strip
fr=[]
for i in ('000','120','239'):
    im=Image.open(f'{R}/runs/fusion/final_frames/frame_{i}.png').convert('RGB')
    fr.append(lab(im,f'{int(i)/24:.1f} s',420))
strip=Image.new('RGB',(1260,fr[0].height),'white')
for i,im in enumerate(fr): strip.paste(im,(i*420,0))
strip.save(f'{G}/fusion_strip_final.jpg', quality=88)
print('ok')
PY
python code/make_gallery.py --root $ROOT 2>&1 | tail -3
echo ARTIFACTS_DONE