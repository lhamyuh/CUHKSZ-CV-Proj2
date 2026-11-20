#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/make_mp4.py --frames $ROOT/runs/garden_base/frames_orbit --out $ROOT/preview/scene_orbit.mp4 --fps 24 2>&1 | tail -1
cp $ROOT/data_object/split.json $ROOT/preview/object_split.json
python - <<'PY'
import json
p='/root/autodl-tmp/CIE6004_ASGN2/preview/object_split.json'
d=json.load(open(p))
print('split sizes', len(d['train']), len(d['val']), len(d['test']))
PY
ls -l $ROOT/preview/scene_orbit.mp4 $ROOT/preview/object_split.json
echo PACK_DONE