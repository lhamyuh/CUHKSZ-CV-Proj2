#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT/gs/repo
source $ROOT/env/bin/activate
python train.py -s $ROOT/data_object/bg0_ds2/train -m $ROOT/runs/obj_m --iterations 40000 \
  --densify_grad_threshold 0.0001 --densify_until_iter 20000 --save_iterations 40000 --port 6021 \
  > $ROOT/logs/obj_m.log 2>&1
echo "rc=$?"; tail -3 $ROOT/logs/obj_m.log
echo B_DENSE_DONE