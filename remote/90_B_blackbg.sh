#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
echo "=== build black-background dataset (dilated masks) ==="
rm -rf $ROOT/data_object/bg0
python code/build_object_dataset.py --sfm $ROOT/runs/obj_sfm_m/sparse/0 \
  --frames $ROOT/data_object/frames --masks $ROOT/data_object/masks \
  --split $ROOT/data_object/split.json --out $ROOT/data_object/bg0 \
  --min_obs 1 --bg 0 --dilate 2 2>&1 | tail -5
mv $ROOT/data_object/bg0/train $ROOT/data_object/bg0_ds 2>/dev/null || true
mkdir -p $ROOT/data_object/bg0_ds2 && mv $ROOT/data_object/bg0_ds $ROOT/data_object/bg0_ds2/train
echo "=== train (black bg, no white_background flag) ==="
cd $ROOT/gs/repo
python train.py -s $ROOT/data_object/bg0_ds2/train -m $ROOT/runs/obj_k --iterations 30000 \
  --save_iterations 30000 --port 6020 > $ROOT/logs/obj_k.log 2>&1
echo "train rc=$?"; tail -3 $ROOT/logs/obj_k.log
echo B_BLACKBG_DONE