#!/usr/bin/env bash
ROOT=/root/autodl-tmp/CIE6004_ASGN2
tail -c 200 $ROOT/logs/garden_base.log
echo
ls -l $ROOT/runs/garden_base/point_cloud/ 2>/dev/null
echo CHK