#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
rm -rf $ROOT/data_object/x2b
python code/build_object_dataset.py --sfm $ROOT/runs/obj_sfm_m/sparse/0 \
  --frames $ROOT/data_object/frames --masks $ROOT/data_object/masks \
  --split $ROOT/data_object/split.json --out $ROOT/data_object/x2b \
  --min_obs 1 --bg 255 --dilate 2 --upscale 2 2>&1 | tail -3
cd $ROOT/gs/repo
python train.py -s $ROOT/data_object/x2b/train -m $ROOT/runs/obj_x2b --iterations 30000 --white_background \
  --save_iterations 30000 --port 6041 > $ROOT/logs/obj_x2b.log 2>&1
echo "rc=$?"; tail -3 $ROOT/logs/obj_x2b.log
echo X2B_DONE