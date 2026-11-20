#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
for v in v11 v12; do
  python code/render_views.py --ply $ROOT/runs/fusion/fused_$v.ply --cameras $ROOT/runs/fusion/sidecam.json --out $ROOT/runs/fusion/side_$v --bg 0 2>&1 | tail -1
done
python - <<'PY'
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
ims=[]
for v in ('v11','v12'):
    im=Image.open(f'{R}/runs/fusion/side_{v}/side.png').convert('RGB').crop((420,250,900,560)).resize((640,413), Image.LANCZOS)
    c=Image.new('RGB',(640,437),'white'); c.paste(im,(0,24)); ImageDraw.Draw(c).text((6,6),v,fill='black'); ims.append(c)
row=Image.new('RGB',(1280,437),'white'); row.paste(ims[0],(0,0)); row.paste(ims[1],(640,0))
row.save(f'{G}/contact_compare.jpg', quality=88)
print('ok')
PY
echo SIDE_DONE