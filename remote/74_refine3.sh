#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/refine_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --object $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_refined2.ply \
  --placement $ROOT/runs/fusion/placement_v7.json --clearance_pct 3 \
  --out_scene $ROOT/runs/fusion/fused_v10.ply --out_placement $ROOT/preview/placement_v10.json 2>&1 | tail -6
python code/render_views.py --ply $ROOT/runs/fusion/fused_v10.ply --cameras $ROOT/runs/fusion/bonus_cam.json --out $ROOT/runs/fusion/probe_v10 --bg 0 2>&1 | tail -1
python code/render_views.py --ply $ROOT/runs/fusion/fused_v10.ply --cameras $ROOT/runs/fusion/closeup.json --out $ROOT/runs/fusion/closeup_v10 --bg 0 2>&1 | tail -1
python - <<'PY'
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
old=Image.open(f'{G}/bonus_after2.png').convert('RGB')
new=Image.open(f'{R}/runs/fusion/probe_v10/frame_120.png').convert('RGB')
close=Image.open(f'{R}/runs/fusion/closeup_v10/closeup.png').convert('RGB')
def fit(im,w): return im.resize((w,int(im.height*w/im.width)), Image.LANCZOS)
box=(420,250,900,600)
row=Image.new('RGB',(960,372),'white')
row.paste(fit(old.crop(box),480),(0,22)); row.paste(fit(new.crop(box),480),(480,22))
d=ImageDraw.Draw(row); d.text((6,5),'before',fill='black'); d.text((486,5),'after v10',fill='black')
row.save(f'{G}/probe_fusion_v10.jpg', quality=88)
close.resize((900,506), Image.LANCZOS).save(f'{G}/closeup_v10.jpg', quality=85)
print('ok')
PY
echo REFINE3_DONE