#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/make_gallery.py --root $ROOT 2>&1 | tail -4
# make the freshness visible on the page
python - <<'PY'
import re, datetime
R='/root/autodl-tmp/CIE6004_ASGN2'
p=f'{R}/gallery/index.html'
h=open(p).read()
stamp=datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
h=h.replace('<h1>Assignment 2 — visual verification</h1>',
            f'<h1>Assignment 2 — visual verification</h1><p style="color:#666">last rebuilt: {stamp} (build 3: Phong relighting, 2x scale, establish-hide-reveal)</p>')
open(p,'w').write(h)
print('index stamped', stamp)
PY
pkill -f "http.server 6006" 2>/dev/null || true
cd $ROOT/gallery
nohup python -m http.server 6006 --bind 0.0.0.0 > $ROOT/logs/gallery.log 2>&1 &
sleep 2
curl -s -o /dev/null -w "index:%{http_code} " http://127.0.0.1:6006/index.html
curl -s -o /dev/null -w "cstrip:%{http_code} " http://127.0.0.1:6006/C/C_strip.jpg
curl -s -o /dev/null -w "video:%{http_code}\n" http://127.0.0.1:6006/media/fusion_orbit.mp4
curl -s http://127.0.0.1:6006/index.html | grep -o "last rebuilt: [^<]*"
ls -l $ROOT/gallery/C/C_strip.jpg $ROOT/gallery/media/fusion_orbit.mp4 | awk '{print $5, $9}'
echo GALLERY_REFRESH_DONE