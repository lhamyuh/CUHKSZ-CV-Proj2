#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/make_gallery.py --root $ROOT 2>&1 | tail -2
python - <<'PY'
import datetime
R='/root/autodl-tmp/CIE6004_ASGN2'; p=f'{R}/gallery/index.html'; h=open(p).read()
stamp=datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
h=h.replace('<h1>Assignment 2 — visual verification</h1>',
 f'<h1>Assignment 2 — visual verification</h1><p style="color:#666">last rebuilt: {stamp} (build 5: object on wood, base-aligned, deglared, closer path)</p>')
open(p,'w').write(h); print('stamped', stamp)
PY
pkill -f "http.server 6006" 2>/dev/null || true
cd $ROOT/gallery && nohup python -m http.server 6006 --bind 0.0.0.0 > $ROOT/logs/gallery.log 2>&1 &
sleep 2
curl -s -o /dev/null -w "index:%{http_code} strip:%{http_code} video:%{http_code}\n" http://127.0.0.1:6006/index.html http://127.0.0.1:6006/C/C_strip.jpg http://127.0.0.1:6006/media/fusion_orbit.mp4
echo GALLERY_H_DONE