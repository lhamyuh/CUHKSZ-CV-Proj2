#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT/gs/repo
source $ROOT/env/bin/activate
python train.py -s $ROOT/release/train -m $ROOT/runs/garden_45k --iterations 45000 \
  --save_iterations 45000 --port 6030 > $ROOT/logs/garden_45k.log 2>&1
echo "rc=$?"; tail -3 $ROOT/logs/garden_45k.log
echo A45K_DONE