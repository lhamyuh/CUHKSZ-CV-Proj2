#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
INIT=$ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_refined.ply
for v in a b; do
  if [ "$v" = "a" ]; then CR=1.15; OC=0.45; else CR=1.05; OC=0.35; fi
  python code/prune_halo.py --ply $INIT --out $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_halo_$v.ply \
    --core_ratio $CR --opacity_cut $OC 2>&1 | tail -2
  python code/render_views.py --ply $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_halo_$v.ply \
    --cameras $ROOT/runs/obj_w/orbit_probe.json --out $ROOT/runs/fusion/orb_h$v --bg 1 2>&1 | tail -1
done
python - <<'PY'
import glob
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
rows=[]
for tag,name in (('init','initial (raw)'),('ha','halo-prune 1.15 / 0.45'),('hb','halo-prune 1.05 / 0.35'),('cur','current (dilated+smooth)')):
    fs=sorted(glob.glob(f'{R}/runs/fusion/orb_{tag}/*.png'))[:4]
    ims=[Image.open(f).convert('RGB').resize((260,int(260*720/406)), Image.LANCZOS) for f in fs]
    row=Image.new('RGB',(4*260,ims[0].height+22),'white')
    for i,im in enumerate(ims): row.paste(im,(i*260,22))
    ImageDraw.Draw(row).text((6,5),name,fill='black'); rows.append(row)
sheet=Image.new('RGB',(1040,sum(r.height for r in rows)),'white'); y=0
for r in rows: sheet.paste(r,(0,y)); y+=r.height
sheet.save(f'{G}/B_halo.jpg', quality=88); print('ok')
PY
echo HALO_DONE