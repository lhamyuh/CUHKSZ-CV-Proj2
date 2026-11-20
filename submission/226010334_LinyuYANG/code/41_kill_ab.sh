#!/usr/bin/env bash
pkill -9 -f "runs/garden_a1" && echo killed_a1
pkill -9 -f "runs/garden_a4" && echo killed_a4
sleep 2
ps -eo pid,args | grep train.py | grep -v grep | cut -c1-110
echo KILL_AB_DONE