#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
rm -rf $ROOT/runs/fusion/h_frames
python code/render_views.py --ply $ROOT/runs/fusion/h.ply --cameras $ROOT/runs/fusion/path_h.json \
  --out $ROOT/runs/fusion/h_frames --bg 0 2>&1 | tail -1
python code/make_mp4.py --frames $ROOT/runs/fusion/h_frames --out $ROOT/preview/fusion_h.mp4 --fps 24 2>&1 | tail -1
python - <<'PY'
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
fr=[]
for i in ('000','120','150','180','239'):
    im=Image.open(f'{R}/runs/fusion/h_frames/frame_{i}.png').convert('RGB').resize((420,236), Image.LANCZOS)
    c=Image.new('RGB',(420,260),'white'); c.paste(im,(0,24)); ImageDraw.Draw(c).text((6,6),f'{int(i)/24:.1f}s',fill='black'); fr.append(c)
row=Image.new('RGB',(1260,260),'white')
for i,c in enumerate(fr[:3]): row.paste(c,(i*420,0))
row.save(f'{G}/h_strip.jpg', quality=88)
row2=Image.new('RGB',(840,260),'white'); row2.paste(fr[3],(0,0)); row2.paste(fr[4],(420,0)); row2.save(f'{G}/h_strip2.jpg', quality=90)
print('ok')
PY
echo FINAL_H_DONE