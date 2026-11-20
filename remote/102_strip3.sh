#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python - <<'PY'
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
labels={'000':'0.0 s','150':'6.2 s','239':'10.0 s'}
ims=[]
for i,t in labels.items():
    im=Image.open(f'{R}/runs/fusion/final2_frames/frame_{i}.png').convert('RGB').resize((640,360), Image.LANCZOS)
    c=Image.new('RGB',(640,384),'white'); c.paste(im,(0,24)); ImageDraw.Draw(c).text((6,6),t,fill='black'); ims.append(c)
row=Image.new('RGB',(1920,384),'white')
for i,c in enumerate(ims): row.paste(c,(i*640,0))
row.save(f'{G}/final_strip3.jpg', quality=88); print('ok')
PY
echo STRIP3_DONE