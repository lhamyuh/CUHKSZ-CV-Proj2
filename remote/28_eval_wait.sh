#!/usr/bin/env bash
ROOT=/root/autodl-tmp/CIE6004_ASGN2
ps -eo pid,etime,pcpu,args | grep evaluate | grep -v grep | cut -c1-120
tail -5 $ROOT/runs/garden_base/metrics_val.json 2>/dev/null
ls -l $ROOT/runs/garden_base/metrics_val.json 2>/dev/null
echo ---
tail -3 $ROOT/runs/obj_sfm_m/mapper.log