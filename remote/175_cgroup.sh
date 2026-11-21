#!/usr/bin/env bash
set -uo pipefail
echo "cpu.max: $(cat /sys/fs/cgroup/cpu.max 2>/dev/null || echo n/a)"
echo "memory.max: $(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo n/a)"
echo "cpu quota(us): $(cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us 2>/dev/null || echo n/a)"
echo "memory(GiB) cgroup v1: $(cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null || echo n/a)"
nproc
echo CGROUP_DONE