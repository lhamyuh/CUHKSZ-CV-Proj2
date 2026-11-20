#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python - <<'PY'
import os, glob, numpy as np
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
def fit(im,w):
    return im.resize((w,int(im.height*w/im.width)), Image.LANCZOS)
# orbit probe grid
fs=sorted(glob.glob(f'{R}/runs/obj_w/orbit_probe/*.png'))
ims=[fit(Image.open(f).convert('RGB'),300) for f in fs]
h=ims[0].height; cols=4; rows=(len(ims)+cols-1)//cols
sheet=Image.new('RGB',(cols*300, rows*h),'white')
for i,im in enumerate(ims): sheet.paste(im,((i%cols)*300,(i//cols)*h))
sheet.save(f'{G}/probe_orbit_v8.jpg', quality=88)
# before/after crop, same bonus camera
old=Image.open(f'{G}/bonus_after2.png').convert('RGB'); new=Image.open(f'{R}/runs/fusion/probe_v8/frame_120.png').convert('RGB')
box=(420,250,900,600)
a=fit(old.crop(box),480); b=fit(new.crop(box),480)
row=Image.new('RGB',(a.width+b.width, a.height+22),'white'); row.paste(a,(0,22)); row.paste(b,(a.width,22))
d=ImageDraw.Draw(row); d.text((6,5),'before (v7, floating)',fill='black'); d.text((a.width+6,5),'after (grounded + shadow)',fill='black')
row.save(f'{G}/probe_fusion_v8.jpg', quality=88)
print('composed', os.path.getsize(f'{G}/probe_orbit_v8.jpg')//1024,'KB,', os.path.getsize(f'{G}/probe_fusion_v8.jpg')//1024,'KB')
PY
echo COMPARE_DONE