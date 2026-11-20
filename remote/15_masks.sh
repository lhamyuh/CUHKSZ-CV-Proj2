#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
source /etc/network_turbo 2>/dev/null || true
rm -f /root/.u2net/u2net.onnx
python code/run_masks.py --frames $ROOT/data_object/frames --out $ROOT/data_object/masks --model u2netp > $ROOT/logs/masks.log 2>&1
echo "masks rc=$?"
tail -2 $ROOT/logs/masks.log
ls $ROOT/data_object/masks | wc -l
echo MASKS_DONE