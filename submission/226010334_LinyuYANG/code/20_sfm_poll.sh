#!/usr/bin/env bash
ROOT=/root/autodl-tmp/CIE6004_ASGN2
ps -eo pid,etime,pcpu,args | grep colmap | grep -v grep | cut -c1-120
echo "=== match tail ==="
tail -c 300 $ROOT/runs/obj_sfm/match.log 2>/dev/null
echo
echo "=== mapper tail ==="
tail -c 500 $ROOT/runs/obj_sfm/mapper.log 2>/dev/null
echo
ls -la $ROOT/runs/obj_sfm/sparse/ 2>/dev/null
echo POLL_DONE