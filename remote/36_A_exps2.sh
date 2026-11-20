#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT/gs/repo
source $ROOT/env/bin/activate
setsid nohup python train.py -s $ROOT/release/train -m $ROOT/runs/garden_a1 --iterations 30000 \
  --densify_grad_threshold 0.0001 --save_iterations 30000 --port 6010 \
  > $ROOT/logs/garden_a1.log 2>&1 < /dev/null &
setsid nohup python train.py -s $ROOT/release/train -m $ROOT/runs/garden_a4 --iterations 45000 \
  --save_iterations 45000 --port 6011 \
  > $ROOT/logs/garden_a4.log 2>&1 < /dev/null &
sleep 20
ps -eo pid,args | grep train.py | grep -v grep | cut -c1-110
echo A2_LAUNCHED