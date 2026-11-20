#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/make_gallery.py --root $ROOT 2>&1 | tail -12
pkill -f "http.server 6006" 2>/dev/null || true
cd $ROOT/gallery
nohup python -m http.server 6006 --bind 0.0.0.0 > $ROOT/logs/gallery.log 2>&1 &
sleep 2
curl -s -o /dev/null -w "index:%{http_code}\n" http://127.0.0.1:6006/index.html
curl -s -o /dev/null -w "sheet:%{http_code}\n" http://127.0.0.1:6006/A/A_val_1.jpg
du -sh $ROOT/gallery
echo GALLERY_DONE