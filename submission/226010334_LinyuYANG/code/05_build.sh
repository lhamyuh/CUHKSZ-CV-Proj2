#!/usr/bin/env bash
set -euo pipefail
cd /root/autodl-tmp/CIE6004_ASGN2
source env/bin/activate
source /etc/network_turbo 2>/dev/null || true
export CUDA_HOME=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$PATH
export TORCH_CUDA_ARCH_LIST="9.0"
pip install -q plyfile opencv-python-headless scipy "lpips==0.1.4" imageio imageio-ffmpeg pandas scikit-learn \
  -i https://pypi.tuna.tsinghua.edu.cn/simple
echo "--- deps ---"
python - <<'PY'
import importlib.util as u
for m in ["plyfile","cv2","lpips","scipy","imageio","pandas","sklearn","torchvision"]:
    print(m, bool(u.find_spec(m)))
PY
cd gs/repo
echo "--- build rasterizer ---"
pip install -q ./submodules/diff-gaussian-rasterization 2>&1 | tail -20
echo "--- build simple-knn ---"
pip install -q ./submodules/simple-knn 2>&1 | tail -20
python - <<'PY'
import torch
from diff_gaussian_rasterization import GaussianRasterizationSettings, GaussianRasterizer
import simple_knn._C as sk
print("rasterizer+simpleknn import OK", torch.cuda.get_device_name(0))
PY
echo BUILD_OK
