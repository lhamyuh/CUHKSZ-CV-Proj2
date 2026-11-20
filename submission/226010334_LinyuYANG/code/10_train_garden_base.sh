#!/usr/bin/env bash
set -euo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT/gs/repo
source $ROOT/env/bin/activate
mkdir -p $ROOT/logs $ROOT/runs
python train.py -s $ROOT/release/train -m $ROOT/runs/garden_base \
  --iterations 30000 --save_iterations 7000 15000 30000 --test_iterations 30000 \
  --checkpoint_iterations 30000 > $ROOT/logs/garden_base.log 2>&1
echo TRAIN_EXIT=$?
tail -3 $ROOT/logs/garden_base.log
ls -l $ROOT/runs/garden_base/point_cloud/
