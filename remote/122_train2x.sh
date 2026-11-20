#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
rm -rf $ROOT/data_object/x2
python code/build_object_dataset.py --sfm $ROOT/runs/obj_sfm_m/sparse/0 \
  --frames $ROOT/data_object/frames --masks $ROOT/data_object/masks \
  --split $ROOT/data_object/split.json --out $ROOT/data_object/x2 \
  --min_obs 1 --bg 255 --dilate 2 --upscale 2 2>&1 | tail -4
python - <<'PY'
from PIL import Image
im=Image.open('/root/autodl-tmp/CIE6004_ASGN2/data_object/x2/train/images/1975_0000.png')
print('train image', im.size, im.mode)
PY
cd $ROOT/gs/repo
python train.py -s $ROOT/data_object/x2/train -m $ROOT/runs/obj_x2 --iterations 30000 --white_background \
  --save_iterations 30000 --port 6040 > $ROOT/logs/obj_x2.log 2>&1
echo "rc=$?"; tail -3 $ROOT/logs/obj_x2.log
echo X2_DONE