#!/usr/bin/env bash
set -uo pipefail
R=/root/autodl-tmp/CIE6004_ASGN2
for f in garden_base obj_w; do
  echo "=== $f ==="
  head -c 400 $R/logs/$f.log | tr '\r' '\n' | grep -oE "\[[0-9]{2}/[0-9]{2} [0-9:]{8}\]" | head -1
  tr '\r' '\n' < $R/logs/$f.log | grep -oE "\[[0-9]{2}/[0-9]{2} [0-9:]{8}\]" | tail -1
  tr '\r' '\n' < $R/logs/$f.log | grep -c "ITER"
done
ls /usr/local/cuda*/bin/nvcc 2>/dev/null; /usr/local/cuda/bin/nvcc --version 2>/dev/null | tail -1
echo TIMES_DONE