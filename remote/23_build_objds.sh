#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
cp code/colmap_io.py code/build_object_dataset.py $ROOT/code/ 2>/dev/null
python code/build_object_dataset.py --sfm $ROOT/runs/obj_sfm/sparse/0 \
  --frames $ROOT/data_object/frames --masks $ROOT/data_object/masks \
  --split $ROOT/data_object/split.json --out $ROOT/data_object --min_obs 2 2>&1 | tail -25
echo BUILD_DS_DONE