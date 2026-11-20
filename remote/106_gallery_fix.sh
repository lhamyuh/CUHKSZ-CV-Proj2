#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/make_gallery.py --root $ROOT 2>&1 | tail -2
python - <<'PY'
import datetime
R='/root/autodl-tmp/CIE6004_ASGN2'
p=f'{R}/gallery/index.html'; h=open(p).read()
stamp=datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
h=h.replace('<h1>Assignment 2 — visual verification</h1>',
            f'<h1>Assignment 2 — visual verification</h1><p style="color:#666">last rebuilt: {stamp} (build 4: C strip now includes the 6.2 s occlusion frame)</p>')
open(p,'w').write(h); print('stamped', stamp)
PY
curl -s -o /dev/null -w "index:%{http_code} strip:%{http_code}\n" http://127.0.0.1:6006/index.html
curl -s http://127.0.0.1:6006/C/C_strip.jpg -o /tmp/c.jpg; ls -l /tmp/c.jpg | awk '{print "C_strip bytes", $5}'
echo DONE