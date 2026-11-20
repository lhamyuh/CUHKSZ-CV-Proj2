#!/usr/bin/env bash
set -u
echo "=== host ==="
hostname; whoami; pwd
echo "=== os ==="
. /etc/os-release; echo "$PRETTY_NAME"
echo "=== gpu ==="
nvidia-smi --query-gpu=name,memory.total,driver_version,compute_cap --format=csv,noheader
echo "=== cuda toolkit ==="
ls -d /usr/local/cuda* 2>/dev/null
/usr/local/cuda/bin/nvcc -V 2>/dev/null | tail -3
echo "=== python ==="
/root/miniconda3/bin/python -V 2>&1
/root/miniconda3/bin/conda env list 2>&1
echo "=== torch in base ==="
/root/miniconda3/bin/python - <<'PY' 2>&1
try:
    import torch
    print("torch", torch.__version__, "cuda", torch.version.cuda, "avail", torch.cuda.is_available())
except Exception as e:
    print("no torch:", e)
PY
echo "=== build tools ==="
gcc --version 2>&1 | head -1
g++ --version 2>&1 | head -1
cmake --version 2>&1 | head -1
git --version 2>&1
echo "=== resources ==="
free -g | head -2
nproc
df -h /root /root/autodl-tmp
echo "=== autodl-tmp ==="
ls -la /root/autodl-tmp
echo "=== net ==="
curl -s -m 8 -o /dev/null -w "github:%{http_code}\n" https://github.com || echo "curl failed"
