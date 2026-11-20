#!/usr/bin/env bash
ROOT=/root/autodl-tmp/CIE6004_ASGN2
echo "=== fusion v2 ==="; ls $ROOT/runs/fusion/ | tr "\n" " "; echo
echo "=== eval json ==="; cat $ROOT/runs/obj_w/eval.json 2>/dev/null | head -6; echo; cat $ROOT/runs/obj_d2/eval.json 2>/dev/null | head -6
echo "=== procs ==="; ps -eo pid,args | grep -E "fuse_scene|render_views|eval_object" | grep -v grep | cut -c1-90