#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
echo "=== prune d2 model ==="
python code/prune_object.py --run $ROOT/runs/obj_d2 --masks $ROOT/data_object/masks \
  --out $ROOT/runs/obj_d2/point_cloud/iteration_30000/point_cloud_pruned.ply --min_ratio 0.75 2>&1 | tail -2
python code/refine_object.py --ply $ROOT/runs/obj_d2/point_cloud/iteration_30000/point_cloud_pruned.ply \
  --out $ROOT/runs/obj_d2/point_cloud/iteration_30000/point_cloud_refined.ply \
  --min_opacity 0.05 --max_scale 0.12 --gain 1.9 --bias 1.3 2>&1 | tail -2
echo "=== orbit probe ==="
python code/render_views.py --ply $ROOT/runs/obj_d2/point_cloud/iteration_30000/point_cloud_refined.ply \
  --cameras $ROOT/runs/obj_w/orbit_probe.json --out $ROOT/runs/obj_d2/orbit_probe --bg 1 2>&1 | tail -1
python - <<'PY'
import glob
from PIL import Image
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
def fit(im,w): return im.resize((w,int(im.height*w/im.width)), Image.LANCZOS)
rows=[]
for tag,path in (('obj_w','runs/obj_w/orbit_probe'),('obj_d2','runs/obj_d2/orbit_probe')):
    fs=sorted(glob.glob(f'{R}/{path}/*.png')); ims=[fit(Image.open(f).convert('RGB'),260) for f in fs[:4]]
    row=Image.new('RGB',(4*260,ims[0].height),'white')
    for i,im in enumerate(ims): row.paste(im,(i*260,0))
    rows.append(row)
sheet=Image.new('RGB',(4*260,sum(r.height for r in rows)),'white')
y=0
for r in rows: sheet.paste(r,(0,y)); y+=r.height
sheet.save(f'{G}/orbit_compare_obj.jpg', quality=88)
print('ok')
PY
echo BETTER_OBJ_DONE