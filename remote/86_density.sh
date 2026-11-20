#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/refine_object.py --ply $ROOT/runs/obj_d2/point_cloud/iteration_30000/point_cloud_pruned.ply \
  --out $ROOT/runs/obj_d2/point_cloud/iteration_30000/point_cloud_ref2.ply \
  --min_opacity 0.05 --max_scale 0.12 --gain 1.9 --bias 1.3 --min_neighbors 4 --radius 0.05 2>&1 | tail -4
python code/render_views.py --ply $ROOT/runs/obj_d2/point_cloud/iteration_30000/point_cloud_ref2.ply \
  --cameras $ROOT/runs/obj_w/orbit_probe.json --out $ROOT/runs/obj_d2/orbit_probe2 --bg 1 2>&1 | tail -1
python - <<'PY'
import glob
from PIL import Image
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
def fit(im,w): return im.resize((w,int(im.height*w/im.width)), Image.LANCZOS)
fs=sorted(glob.glob(f'{R}/runs/obj_d2/orbit_probe2/*.png'))
ims=[fit(Image.open(f).convert('RGB'),260) for f in fs[:4]]
row=Image.new('RGB',(4*260,ims[0].height),'white')
for i,im in enumerate(ims): row.paste(im,(i*260,0))
row.save(f'{G}/orbit_density.jpg', quality=88)
print('ok')
PY
echo DENSITY_DONE