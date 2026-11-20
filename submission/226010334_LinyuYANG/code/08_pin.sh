#!/usr/bin/env bash
set -euo pipefail
cd /root/autodl-tmp/CIE6004_ASGN2
source env/bin/activate
pip install -q "plyfile==1.0.3" "opencv-python-headless==4.10.0.84" "numpy==1.26.4" -i https://pypi.tuna.tsinghua.edu.cn/simple 2>&1 | tail -5
python - <<'PY'
import numpy, cv2, plyfile
print("numpy", numpy.__version__, "cv2", cv2.__version__, "plyfile", plyfile.__version__)
PY
echo PIN_OK
