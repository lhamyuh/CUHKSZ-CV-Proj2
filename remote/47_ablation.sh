#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
# variant: 2 px mask dilation (single change), same split / points / budget
rm -rf $ROOT/data_object/train_d2
python code/build_object_dataset.py --sfm $ROOT/runs/obj_sfm_m/sparse/0 \
  --frames $ROOT/data_object/frames --masks $ROOT/data_object/masks \
  --split $ROOT/data_object/split.json --out $ROOT/data_object/d2 --min_obs 1 --bg 255 --dilate 2 2>&1 | tail -4
# move into a self-contained dataset dir
rm -rf $ROOT/data_object/d2ds; mkdir -p $ROOT/data_object/d2ds
mv $ROOT/data_object/d2/train $ROOT/data_object/d2ds/train
cd $ROOT/gs/repo
python train.py -s $ROOT/data_object/d2ds/train -m $ROOT/runs/obj_d2 --iterations 30000 --white_background \
  --save_iterations 30000 --port 6013 > $ROOT/logs/obj_d2.log 2>&1
echo "train rc=$?"
tail -3 $ROOT/logs/obj_d2.log
echo ABLATION_TRAIN_DONE