#!/usr/bin/env bash
set -uo pipefail
R=/root/autodl-tmp/CIE6004_ASGN2
ls -la $R/logs/*.log 2>/dev/null | awk '{print $5, $9}'
for f in $R/logs/garden_45k.log $R/logs/obj_d2.log $R/logs/obj_w.log $R/logs/garden_base.log; do
  [ -f "$f" ] || continue
  s=$(tr '\r' '\n' < "$f" | grep -oE "\[[0-9]{2}/[0-9]{2} [0-9:]{8}\]" | head -1)
  e=$(tr '\r' '\n' < "$f" | grep -oE "\[[0-9]{2}/[0-9]{2} [0-9:]{8}\]" | tail -1)
  echo "$(basename $f): $s -> $e"
done
echo LOGS_DONE