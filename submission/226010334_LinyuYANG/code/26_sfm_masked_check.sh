#!/usr/bin/env bash
ROOT=/root/autodl-tmp/CIE6004_ASGN2
D=$ROOT/runs/obj_sfm_m
echo "--- feat ---"; tail -c 200 $D/feat.log 2>/dev/null
echo "--- match ---"; tail -c 200 $D/match.log 2>/dev/null
echo "--- mapper ---"; tail -c 300 $D/mapper.log 2>/dev/null
echo "--- procs ---"; ps -eo pid,etime,pcpu,args | grep colmap | grep -v grep | cut -c1-100
ls -d $D/sparse/* 2>/dev/null