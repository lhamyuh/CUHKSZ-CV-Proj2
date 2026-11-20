#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/refine_object.py --ply $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_pruned3.ply \
  --out $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_refined2.ply \
  --min_opacity 0.05 --max_scale 0.12 --gain 1.9 --bias 1.3 2>&1 | tail -3
python code/refine_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --object $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_refined2.ply \
  --placement $ROOT/runs/fusion/placement_v7.json --clearance_pct 5 \
  --out_scene $ROOT/runs/fusion/fused_v9.ply --out_placement $ROOT/preview/placement_v9.json 2>&1 | tail -6
python code/render_views.py --ply $ROOT/runs/fusion/fused_v9.ply --cameras $ROOT/runs/fusion/bonus_cam.json --out $ROOT/runs/fusion/probe_v9 --bg 0 2>&1 | tail -1
python code/render_views.py --ply $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_refined2.ply \
  --cameras $ROOT/runs/obj_w/orbit_probe.json --out $ROOT/runs/obj_w/orbit_probe2 --bg 1 2>&1 | tail -1
python - <<'PY'
import glob, os
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
old=Image.open(f'{G}/bonus_after2.png').convert('RGB'); new=Image.open(f'{R}/runs/fusion/probe_v9/frame_120.png').convert('RGB')
box=(420,250,900,600)
def fit(im,w): return im.resize((w,int(im.height*w/im.width)), Image.LANCZOS)
a=fit(old.crop(box),480); b=fit(new.crop(box),480)
row=Image.new('RGB',(a.width+b.width, a.height+22),'white'); row.paste(a,(0,22)); row.paste(b,(a.width,22))
d=ImageDraw.Draw(row); d.text((6,5),'before',fill='black'); d.text((a.width+6,5),'after v9',fill='black')
row.save(f'{G}/probe_fusion_v9.jpg', quality=88)
fs=sorted(glob.glob(f'{R}/runs/obj_w/orbit_probe2/*.png')); ims=[fit(Image.open(f).convert('RGB'),300) for f in fs]
h=ims[0].height; sheet=Image.new('RGB',(4*300,2*h),'white')
for i,im in enumerate(ims): sheet.paste(im,((i%4)*300,(i//4)*h))
sheet.save(f'{G}/probe_orbit_v9.jpg', quality=88)
print('ok')
PY
echo REFINE2_DONE