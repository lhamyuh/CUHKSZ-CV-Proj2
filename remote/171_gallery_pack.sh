#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
cp $ROOT/preview/obj_orbit_final.gif $ROOT/preview/obj_orbit.gif 2>/dev/null || true
python code/make_gallery.py --root $ROOT 2>&1 | tail -2
cp $ROOT/preview/B_versions3.jpg $ROOT/gallery/B/B_versions.jpg 2>/dev/null || true
python - <<'PY'
import datetime, re
R='/root/autodl-tmp/CIE6004_ASGN2'; p=f'{R}/gallery/index.html'; h=open(p).read()
stamp=datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
h=re.sub(r'last rebuilt: [0-9:\- ]+ \(build \d+[^)]*\)', f'last rebuilt: {stamp} (build 11: final stills, brighter object, tighter contact shadow)', h, count=1)
open(p,'w').write(h); print('stamped')
PY
cd $ROOT/gallery
rm -f $ROOT/deliver/gallery_226010334_LinyuYANG.tar.gz
tar -czf $ROOT/deliver/gallery_226010334_LinyuYANG.tar.gz .
ls -lh $ROOT/deliver/gallery_226010334_LinyuYANG.tar.gz
echo GALLERY_PACK_DONE