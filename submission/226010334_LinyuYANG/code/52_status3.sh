#!/usr/bin/env bash
ROOT=/root/autodl-tmp/CIE6004_ASGN2
echo "=== d2 ==="; tail -c 100 $ROOT/logs/obj_d2.log; ls $ROOT/runs/obj_d2/point_cloud 2>/dev/null
echo "=== fusion ==="; ls $ROOT/runs/fusion/ 2>/dev/null
ps -eo pid,args | grep -E "fuse_scene|render_views" | grep -v grep | cut -c1-100