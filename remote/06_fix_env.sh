#!/usr/bin/env bash
set -euo pipefail
cd /root/autodl-tmp/CIE6004_ASGN2
source env/bin/activate
pip install -q "numpy==1.26.4" -i https://pypi.tuna.tsinghua.edu.cn/simple
python - <<'PY'
import numpy, torch, scipy, pandas, cv2, lpips
print("numpy", numpy.__version__)
print("torch", torch.__version__, torch.version.cuda, torch.cuda.is_available())
print("scipy", scipy.__version__, "pandas", pandas.__version__, "cv2", cv2.__version__)
from diff_gaussian_rasterization import GaussianRasterizer
import simple_knn._C
print("extensions OK")
PY
echo FIX_OK
