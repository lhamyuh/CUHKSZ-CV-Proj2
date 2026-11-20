#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
CUR=$ROOT/runs/obj_d2/point_cloud/iteration_30000/point_cloud_smooth.ply
FIL=$ROOT/runs/obj_d2/point_cloud/iteration_30000/point_cloud_final.ply
python code/filter_strands.py --ply $CUR --out $FIL --aniso 7 --bright 0.5 --min_neigh 4 --radius 0.03 2>&1 | tail -3
echo "=== orbit probes: initial / current / filtered ==="
INIT=$ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_refined.ply
for tag in init cur fil; do
  case $tag in
    init) P=$INIT;; cur) P=$CUR;; fil) P=$FIL;;
  esac
  python code/render_views.py --ply $P --cameras $ROOT/runs/obj_w/orbit_probe.json --out $ROOT/runs/fusion/orb_$tag --bg 1 2>&1 | tail -1
done
python - <<'PY'
import glob
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
rows=[]
for tag,name in (('init','initial (white bg, 30k)'),('cur','current (dilated + smoothed)'),('fil','filtered strands')):
    fs=sorted(glob.glob(f'{R}/runs/fusion/orb_{tag}/*.png'))[:4]
    ims=[Image.open(f).convert('RGB').resize((260,int(260*720/406)), Image.LANCZOS) for f in fs]
    row=Image.new('RGB',(4*260,ims[0].height+22),'white')
    for i,im in enumerate(ims): row.paste(im,(i*260,22))
    ImageDraw.Draw(row).text((6,5),name,fill='black')
    rows.append(row)
sheet=Image.new('RGB',(1040,sum(r.height for r in rows)),'white'); y=0
for r in rows: sheet.paste(r,(0,y)); y+=r.height
sheet.save(f'{G}/B_versions.jpg', quality=88); print('ok')
PY
echo STRANDS_DONE