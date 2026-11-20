#!/usr/bin/env bash
set -uo pipefail
export DEBIAN_FRONTEND=noninteractive
echo "=== apt colmap ==="
apt-get update -qq 2>&1 | tail -2
apt-get install -y -qq colmap 2>&1 | tail -5
which colmap && colmap -h 2>&1 | head -3
echo "=== rembg ==="
cd /root/autodl-tmp/CIE6004_ASGN2
source env/bin/activate
pip install -q "rembg" "onnxruntime" -i https://pypi.tuna.tsinghua.edu.cn/simple 2>&1 | tail -3
python - <<'PY'
try:
    import rembg
    print("rembg", rembg.__version__)
except Exception as e:
    print("rembg import failed:", e)
PY
echo INSTALL_DONE
