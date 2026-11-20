#!/usr/bin/env bash
ROOT=/root/autodl-tmp/CIE6004_ASGN2
echo "=== procs ==="
ps -eo pid,etime,pcpu,pmem,args | grep -E "run_masks|colmap|train.py" | grep -v grep | cut -c1-140
echo "=== train ==="
tail -c 110 $ROOT/logs/garden_base.log
echo
echo "=== masks ==="
ls $ROOT/data_object/masks 2>/dev/null | wc -l
tail -c 120 $ROOT/logs/masks.log 2>/dev/null
echo
echo "=== sfm ==="
tail -2 $ROOT/runs/obj_sfm/match.log 2>/dev/null
tail -3 $ROOT/runs/obj_sfm/mapper.log 2>/dev/null
ls -d $ROOT/runs/obj_sfm/sparse/* 2>/dev/null
echo "=== gpu ==="
nvidia-smi --query-gpu=memory.used,utilization.gpu --format=csv,noheader