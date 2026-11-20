#!/usr/bin/env bash
ROOT=/root/autodl-tmp/CIE6004_ASGN2
echo "=== obj_w ==="; tail -c 150 $ROOT/logs/obj_w.log
echo; echo "=== a1 ==="; tail -c 120 $ROOT/logs/garden_a1.log
echo; echo "=== a4 ==="; tail -c 120 $ROOT/logs/garden_a4.log
echo; echo "=== gpu ==="; nvidia-smi --query-gpu=memory.used,utilization.gpu --format=csv,noheader