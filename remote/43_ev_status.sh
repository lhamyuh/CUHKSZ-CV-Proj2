#!/usr/bin/env bash
ROOT=/root/autodl-tmp/CIE6004_ASGN2
ps -eo pid,etime,pcpu,args | grep -E "render_views|make_orbit|frames_to_gif|python" | grep -v grep | cut -c1-130
echo ---
ls $ROOT/runs/obj_w/ | head
ls $ROOT/runs/obj_w/orbit_frames 2>/dev/null | wc -l
ls -l $ROOT/runs/obj_w/orbit.json 2>/dev/null