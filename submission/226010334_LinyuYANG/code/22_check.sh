#!/usr/bin/env bash
ROOT=/root/autodl-tmp/CIE6004_ASGN2
echo "=== procs ==="
ps -eo pid,etime,pcpu,args | grep -E "colmap|train.py" | grep -v grep | cut -c1-110
echo "=== match end ==="
tail -3 $ROOT/runs/obj_sfm/match.log
echo "=== mapper ==="
tail -5 $ROOT/runs/obj_sfm/mapper.log
ls $ROOT/runs/obj_sfm/sparse/ 2>/dev/null
echo "=== train ==="
tail -c 100 $ROOT/logs/garden_base.log
echo
nvidia-smi --query-gpu=memory.used,utilization.gpu --format=csv,noheader