#!/usr/bin/env bash
pkill -9 -f exhaustive_matcher && echo "matcher killed"
pkill -9 -f "colmap mapper" 2>/dev/null
sleep 1
ps -eo pid,args | grep colmap | grep -v grep | cut -c1-100
echo KILLED