#!/usr/bin/env bash
set -euo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT/gs/repo
source $ROOT/env/bin/activate
mkdir -p $ROOT/logs
( while true; do nvidia-smi --query-gpu=memory.used,utilization.gpu --format=csv,noheader >> $ROOT/logs/smoke_gpu.csv; sleep 2; done ) &
MON=$!
t0=$(date +%s)
python train.py -s $ROOT/release/train -m $ROOT/runs/garden_smoke \
  --iterations 2000 --save_iterations 2000 --test_iterations 2000 \
  > $ROOT/logs/smoke.log 2>&1 || { tail -40 $ROOT/logs/smoke.log; kill $MON; exit 1; }
t1=$(date +%s)
kill $MON 2>/dev/null || true
echo "ELAPSED_SEC=$((t1-t0))"
echo "--- peak gpu ---"
sort -t, -k1 -n $ROOT/logs/smoke_gpu.csv | tail -3
echo "--- log tail ---"
tail -15 $ROOT/logs/smoke.log
echo "--- ply ---"
ls -l $ROOT/runs/garden_smoke/point_cloud/iteration_2000/ 2>/dev/null
echo SMOKE_OK
