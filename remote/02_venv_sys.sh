#!/usr/bin/env bash
set -euo pipefail
cd /root/autodl-tmp/CIE6004_ASGN2
rm -rf env
/root/miniconda3/bin/python -m venv --system-site-packages env
source env/bin/activate
python -V
python - <<'PY'
import torch, numpy, sys
print("torch", torch.__version__, "cuda", torch.version.cuda, "avail", torch.cuda.is_available())
print("numpy", numpy.__version__)
print("cc", torch.cuda.get_device_capability(0))
PY
echo VENV_SYS_OK
