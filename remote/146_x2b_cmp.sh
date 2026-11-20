#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python - <<'PY'
import glob
from PIL import Image
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
def fit(im,w): return im.resize((w,int(im.height*w/im.width)), Image.LANCZOS)
rows=[]
for tag,path in (('1x smoothed (delivered)','runs/obj_d2/orbit_probe2'),('2x smoothed (new)','runs/obj_x2b/orbit_probe')):
    fs=sorted(glob.glob(f'{R}/{path}/*.png'))
    ims=[fit(Image.open(f).convert('RGB'),260) for f in fs[:4]]
    if not ims: continue
    row=Image.new('RGB',(4*260,ims[0].height),'white')
    for i,im in enumerate(ims): row.paste(im,(i*260,0))
    rows.append(row)
if rows:
    sheet=Image.new('RGB',(1040,sum(r.height for r in rows)),'white'); y=0
    for r in rows: sheet.paste(r,(0,y)); y+=r.height
    sheet.save(f'{G}/orbit_1x_2x.jpg', quality=88); print('ok', len(rows))
else:
    print('no images')
PY
echo CMP_DONE