#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT/gs/repo
source $ROOT/env/bin/activate
python train.py -s $ROOT/data_object/train -m $ROOT/runs/obj_base \
  --iterations 30000 --save_iterations 5000 10000 15000 30000 --test_iterations 30000 \
  > $ROOT/logs/obj_base.log 2>&1
echo "train rc=$?"
tail -4 $ROOT/logs/obj_base.log
ls $ROOT/runs/obj_base/point_cloud/ 2>/dev/null
echo OBJ_TRAIN_DONE