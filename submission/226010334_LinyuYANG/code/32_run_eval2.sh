#!/usr/bin/env bash
ROOT=/root/autodl-tmp/CIE6004_ASGN2
grep -n "3 :3" $ROOT/code/render_views.py | head -3
bash $ROOT/../16_eval_garden.sh 2>/dev/null || true