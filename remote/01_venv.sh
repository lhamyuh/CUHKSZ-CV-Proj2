#!/usr/bin/env bash
set -euo pipefail
cd /root/autodl-tmp/CIE6004_ASGN2
/root/miniconda3/bin/python -V
/root/miniconda3/bin/python -m venv env
source env/bin/activate
python -V
python -m pip install -q --upgrade pip setuptools wheel
pip -V
echo VENV_OK
