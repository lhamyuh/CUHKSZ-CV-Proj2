#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
rm -rf $ROOT/data_object/train
python code/build_object_dataset.py --sfm $ROOT/runs/obj_sfm_m/sparse/0 \
  --frames $ROOT/data_object/frames --masks $ROOT/data_object/masks \
  --split $ROOT/data_object/split.json --out $ROOT/data_object --min_obs 1 --bg 255 2>&1 | tail -6
python - <<'PY'
from PIL import Image; import numpy as np
im = Image.open('/root/autodl-tmp/CIE6004_ASGN2/data_object/train/images/1975_0000.png')
a = np.asarray(im); print('mode', im.mode, a.shape, 'corner', a[0,0])
PY
cd $ROOT/gs/repo
python train.py -s $ROOT/data_object/train -m $ROOT/runs/obj_w --iterations 30000 --white_background \
  --save_iterations 5000 10000 15000 30000 --port 6012 > $ROOT/logs/obj_w.log 2>&1
echo "train rc=$?"
tail -4 $ROOT/logs/obj_w.log
echo OBJ_W_DONE