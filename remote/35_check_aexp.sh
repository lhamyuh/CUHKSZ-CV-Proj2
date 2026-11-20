#!/usr/bin/env bash
ROOT=/root/autodl-tmp/CIE6004_ASGN2
for f in garden_a1 garden_a4; do echo "--- $f"; ls -l $ROOT/logs/$f.log 2>/dev/null; tail -3 $ROOT/logs/$f.log 2>/dev/null; done
echo "--- procs"; ps -eo pid,etime,args | grep train.py | grep -v grep | cut -c1-100
echo "--- gpu"; nvidia-smi --query-gpu=memory.used,utilization.gpu --format=csv,noheader