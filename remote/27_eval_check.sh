#!/usr/bin/env bash
ROOT=/root/autodl-tmp/CIE6004_ASGN2
echo "--- renders ---"
ls $ROOT/runs/garden_base/renders_val 2>/dev/null | wc -l
ls $ROOT/runs/garden_base/renders_test 2>/dev/null | wc -l
ls $ROOT/runs/garden_base/frames_orbit 2>/dev/null | wc -l
ls -l $ROOT/runs/garden_base/orbit.mp4 2>/dev/null
echo "--- metrics ---"
cat $ROOT/runs/garden_base/metrics_val.json 2>/dev/null | head -20
echo "--- masked sfm ---"
tail -2 $ROOT/runs/obj_sfm_m/mapper.log 2>/dev/null
for m in $ROOT/runs/obj_sfm_m/sparse/*/; do echo -n "$m "; colmap model_analyzer --path $m 2>/dev/null | grep -E "Registered images|Points" | tr "\n" " "; echo; done