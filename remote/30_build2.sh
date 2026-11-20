#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
rm -rf $ROOT/data_object/train
python code/build_object_dataset.py --sfm $ROOT/runs/obj_sfm_m/sparse/0 \
  --frames $ROOT/data_object/frames --masks $ROOT/data_object/masks \
  --split $ROOT/data_object/split.json --out $ROOT/data_object --min_obs 1 2>&1 | tail -15
echo "--- dataset ---"
ls $ROOT/data_object/train/images | wc -l
ls -l $ROOT/data_object/train/sparse/0/
echo BUILD2_DONE