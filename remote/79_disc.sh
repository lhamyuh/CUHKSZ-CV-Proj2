#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/refine_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --object $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_refined2.ply \
  --placement $ROOT/runs/fusion/placement_v7.json --clearance_pct 10 \
  --shadow_sigma 0.12 --shadow_strength 0.70 --object_gain 1.35 --base_disc 4000 \
  --out_scene $ROOT/runs/fusion/fused_v13.ply --out_placement $ROOT/preview/placement_v13.json 2>&1 | tail -4
python code/render_views.py --ply $ROOT/runs/fusion/fused_v13.ply --cameras $ROOT/runs/fusion/closeup.json --out $ROOT/runs/fusion/closeup_v13 --bg 0 2>&1 | tail -1
python code/render_views.py --ply $ROOT/runs/fusion/fused_v13.ply --cameras $ROOT/runs/fusion/bonus_cam.json --out $ROOT/runs/fusion/probe_v13 --bg 0 2>&1 | tail -1
python - <<'PY'
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
close=Image.open(f'{R}/runs/fusion/closeup_v13/closeup.png').convert('RGB')
close.crop((520,240,900,480)).resize((760,480), Image.LANCZOS).save(f'{G}/closeup_v13.jpg', quality=86)
old=Image.open(f'{G}/bonus_after2.png').convert('RGB'); new=Image.open(f'{R}/runs/fusion/probe_v13/frame_120.png').convert('RGB')
box=(420,250,900,600)
def fit(im,w): return im.resize((w,int(im.height*w/im.width)), Image.LANCZOS)
row=Image.new('RGB',(960,372),'white'); row.paste(fit(old.crop(box),480),(0,22)); row.paste(fit(new.crop(box),480),(480,22))
d=ImageDraw.Draw(row); d.text((6,5),'before',fill='black'); d.text((486,5),'after v13 (contact disc)',fill='black')
row.save(f'{G}/probe_fusion_v13.jpg', quality=88)
print('ok')
PY
echo DISC_DONE