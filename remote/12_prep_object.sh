#!/usr/bin/env bash
set -euo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/prep_object.py --release $ROOT/release --out $ROOT/data_object --object camera 2>&1 | tail -12
ls $ROOT/data_object
echo PREP_OK