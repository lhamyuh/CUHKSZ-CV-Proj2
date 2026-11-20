#!/usr/bin/env bash
ps -eo pid,etime,args | grep run_masks | grep -v grep
kill -9 8893 2>/dev/null && echo "killed 8893 (stuck u2net download)"
sleep 2
ps -eo pid,pcpu,args | grep run_masks | grep -v grep
echo OK