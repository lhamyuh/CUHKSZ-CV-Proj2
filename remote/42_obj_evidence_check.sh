#!/usr/bin/env bash
ROOT=/root/autodl-tmp/CIE6004_ASGN2
M=$ROOT/runs/obj_w
ls $M/orbit_frames 2>/dev/null | wc -l
ls -l $ROOT/preview/obj_orbit.gif 2>/dev/null
for d in 5000 10000 15000 30000; do echo -n "stages/$d: "; ls $M/stages/$d 2>/dev/null | wc -l; done
ls $M/views_ablation 2>/dev/null | wc -l
cat $M/orbit.json 2>/dev/null | python -c "import json,sys; d=json.load(sys.stdin); print('center',d['center'],'radius',round(d['radius'],4))"