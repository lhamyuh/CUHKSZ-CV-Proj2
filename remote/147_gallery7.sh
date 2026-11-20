#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/make_gallery.py --root $ROOT 2>&1 | tail -2
cp $ROOT/preview/orbit_1x_2x.jpg $ROOT/gallery/B/B_1x_vs_2x.jpg
python - <<'PY'
import datetime
R='/root/autodl-tmp/CIE6004_ASGN2'; p=f'{R}/gallery/index.html'; h=open(p).read()
stamp=datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
h=h.replace('<h1>Assignment 2 — visual verification</h1>',
 f'<h1>Assignment 2 — visual verification</h1><p style="color:#666">last rebuilt: {stamp} (build 7: 2x retrain evaluated, no gain; 1x kept)</p>')
h=h.replace('<img src="B/B_orbit.gif">',
 '<p>1x (top row) vs 2x upscaled retrain (bottom row). Masked PSNR 18.2 vs 13.7 dB, so the 1x model is delivered.</p><img src="B/B_1x_vs_2x.jpg"><img src="B/B_orbit.gif">')
open(p,'w').write(h); print('stamped', stamp)
PY
pkill -f "http.server 6006" 2>/dev/null || true
cd $ROOT/gallery && nohup python -m http.server 6006 --bind 0.0.0.0 > $ROOT/logs/gallery.log 2>&1 &
sleep 2
for u in index.html B/B_1x_vs_2x.jpg B/B_orbit.gif media/fusion_orbit.mp4 media/scene_orbit.mp4; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:6006/$u")
  echo "$u -> $code"
done
echo GALLERY7_DONE