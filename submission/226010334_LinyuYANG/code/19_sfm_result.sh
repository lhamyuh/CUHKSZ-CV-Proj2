#!/usr/bin/env bash
ROOT=/root/autodl-tmp/CIE6004_ASGN2
tail -4 $ROOT/runs/obj_sfm/mapper.log 2>/dev/null
echo "=== models ==="
for m in $ROOT/runs/obj_sfm/sparse/*/; do
  echo "--- $m"
  colmap model_analyzer --path $m 2>/dev/null | grep -E "Cameras|Images|Points" 
done
echo DONE