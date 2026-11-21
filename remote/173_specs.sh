#!/usr/bin/env bash
set -uo pipefail
echo "=== GPU ==="
nvidia-smi --query-gpu=name,memory.total,driver_version,compute_cap --format=csv,noheader
echo "=== CPU ==="
lscpu | grep -E "Model name|^CPU\(s\)|Thread|Core\(s\) per socket|Socket" | head -5
echo "=== RAM ==="
free -g | head -2
echo "=== OS ==="
cat /etc/os-release | head -2
uname -r
echo "=== CUDA ==="
nvcc --version | tail -1
echo "=== DISK ==="
df -h /root/autodl-tmp | tail -1
echo "=== TORCH ==="
/root/autodl-tmp/CIE6004_ASGN2/env/bin/python -c 'import torch; print(torch.__version__, torch.version.cuda)'
echo "=== TIMES (from logs) ==="
grep -h "Training complete" /root/autodl-tmp/CIE6004_ASGN2/logs/garden_base.log /root/autodl-tmp/CIE6004_ASGN2/logs/obj_w.log 2>/dev/null | tail -4
grep -hE "\[ITER 30000\]" /root/autodl-tmp/CIE6004_ASGN2/logs/garden_base.log /root/autodl-tmp/CIE6004_ASGN2/logs/obj_w.log 2>/dev/null | tail -4
echo SPECS_DONE