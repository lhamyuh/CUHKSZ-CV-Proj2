#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
INIT=$ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_refined.ply
python code/smooth_object.py --ply $INIT --out $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_smooth3.ply \
  --k 12 --color_alpha 0.5 --opacity_beta 0.5 --scale_clamp 1.8 --scale_alpha 0.4 2>&1 | tail -2
python code/render_views.py --ply $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_smooth3.ply \
  --cameras $ROOT/runs/obj_w/orbit_probe.json --out $ROOT/runs/fusion/orb_sm3 --bg 1 2>&1 | tail -1
python - <<'PY'
import glob
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
rows=[]
for tag,name in (('init','initial (raw)'),('sm3','initial + light smoothing'),('cur','current (dilated + smoothing)')):
    fs=sorted(glob.glob(f'{R}/runs/fusion/orb_{tag}/*.png'))[:4]
    ims=[Image.open(f).convert('RGB').resize((260,int(260*720/406)), Image.LANCZOS) for f in fs]
    row=Image.new('RGB',(4*260,ims[0].height+22),'white')
    for i,im in enumerate(ims): row.paste(im,(i*260,22))
    ImageDraw.Draw(row).text((6,5),name,fill='black'); rows.append(row)
sheet=Image.new('RGB',(1040,sum(r.height for r in rows)),'white'); y=0
for r in rows: sheet.paste(r,(0,y)); y+=r.height
sheet.save(f'{G}/B_versions3.jpg', quality=88); print('ok')
PY
echo LIGHT_SMOOTH_DONE