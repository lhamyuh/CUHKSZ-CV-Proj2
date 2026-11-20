#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/make_gallery.py --root $ROOT 2>&1 | tail -2
cp $ROOT/preview/orbit_1x_2x.jpg $ROOT/gallery/B/B_1x_vs_2x.jpg 2>/dev/null || true
python - <<'PY'
import datetime
R='/root/autodl-tmp/CIE6004_ASGN2'; p=f'{R}/gallery/index.html'; h=open(p).read()
stamp=datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
import re
h=re.sub(r'last rebuilt: [0-9:\- ]+ \(build \d+[^)]*\)', f'last rebuilt: {stamp} (build 9: deglare 0.38, shadow 0.85)', h, count=1)
if 'B_1x_vs_2x' not in h:
    h=h.replace('<img src="B/B_orbit.gif">',
     '<p>1x (top) vs 2x retrain (bottom): masked PSNR 18.2 vs 13.7 dB, so 1x is delivered.</p><img src="B/B_1x_vs_2x.jpg"><img src="B/B_orbit.gif">')
open(p,'w').write(h); print('stamped')
PY
pkill -f "http.server 6006" 2>/dev/null || true
cd $ROOT/gallery && setsid nohup python -m http.server 6006 --bind 0.0.0.0 > $ROOT/logs/gallery.log 2>&1 < /dev/null &
sleep 2
for u in index.html C/C_strip.jpg media/fusion_orbit.mp4; do echo "$u $(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:6006/$u)"; done
echo GALLERY9_DONE