#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
cp $ROOT/preview/obj_orbit_final.gif $ROOT/preview/obj_orbit.gif
python code/make_gallery.py --root $ROOT 2>&1 | tail -2
cp $ROOT/preview/B_versions3.jpg $ROOT/gallery/B/B_versions.jpg 2>/dev/null || true
python - <<'PY'
import datetime, re
R='/root/autodl-tmp/CIE6004_ASGN2'; p=f'{R}/gallery/index.html'; h=open(p).read()
stamp=datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
h=re.sub(r'last rebuilt: [0-9:\- ]+ \(build \d+[^)]*\)', f'last rebuilt: {stamp} (build 10: initial model + light smoothing delivered; brighter object, tighter shadow)', h, count=1)
if 'B_versions' not in h:
    h=h.replace('<img src="B/B_orbit.gif">', '<p>Model comparison: initial (top) / initial+smoothing (middle) / dilated (bottom).</p><img src="B/B_versions.jpg"><img src="B/B_orbit.gif">')
open(p,'w').write(h); print('stamped')
PY
pkill -f "http.server 6006" 2>/dev/null || true
cd $ROOT/gallery && setsid nohup python -m http.server 6006 --bind 0.0.0.0 > $ROOT/logs/gallery.log 2>&1 < /dev/null &
sleep 2
for u in index.html B/B_versions.jpg B/B_orbit.gif C/C_strip.jpg media/fusion_orbit.mp4; do echo "$u $(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:6006/$u)"; done
echo GALLERY10_DONE