#!/usr/bin/env bash
ROOT=/root/autodl-tmp/CIE6004_ASGN2
ls -l /root/.cache/torch/hub/checkpoints/ 2>/dev/null
du -sh /root/.cache/torch 2>/dev/null
ps -eo pid,etime,pcpu,rss,args | grep evaluate | grep -v grep | cut -c1-100
cat $ROOT/runs/garden_base/metrics_val.json 2>/dev/null | head -3