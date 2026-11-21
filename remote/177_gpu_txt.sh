#!/usr/bin/env bash
set -uo pipefail
R=/root/autodl-tmp/CIE6004_ASGN2
OUT=$R/deliver/gpu.txt
{
echo "# Hardware record for 226010334 Linyu YANG"
echo "# captured on the AutoDL instance that produced every number in report.pdf"
echo
echo "## nvidia-smi (full output)"
nvidia-smi
echo
echo "## nvidia-smi --query-gpu (name, memory, driver, compute capability)"
nvidia-smi --query-gpu=name,memory.total,driver_version,compute_cap --format=csv
echo
echo "## cgroup allocation (what actually applies inside the container)"
echo "cpu.max:    $(cat /sys/fs/cgroup/cpu.max 2>/dev/null)"
echo "memory.max: $(cat /sys/fs/cgroup/memory.max 2>/dev/null)"
echo "nproc:      $(nproc)"
echo
echo "## host CPU (lscpu, first lines)"
lscpu | head -16
echo
echo "## OS"
cat /etc/os-release | head -3
uname -r
echo
echo "## CUDA toolkit"
/usr/local/cuda/bin/nvcc --version | tail -1
echo
echo "## PyTorch"
$R/env/bin/python -c 'import torch; print(torch.__version__, torch.version.cuda)'
echo
echo "## disk"
df -h /root/autodl-tmp | tail -1
} > $OUT
wc -l $OUT
echo GPU_TXT_DONE