#!/usr/bin/env bash
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cat $ROOT/runs/garden_base/metrics_val.json 2>/dev/null | head -30
echo "--- obj train ---"
tail -c 150 $ROOT/logs/obj_base.log
echo
ls $ROOT/runs/obj_base/point_cloud 2>/dev/null