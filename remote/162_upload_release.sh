#!/usr/bin/env bash
set -uo pipefail
TOK="${GITHUB_TOKEN:?set GITHUB_TOKEN first}"
F=/root/autodl-tmp/CIE6004_ASGN2/deliver/records_226010334_LinyuYANG.tar.gz
URL=https://uploads.github.com/repos/lhamyuh/CUHKSZ-CV-Proj2/releases/453041725/assets?name=records_226010334_LinyuYANG.tar.gz
nohup curl -sS --retry 3 --max-time 3600 -X POST \
  -H "Authorization: token $TOK" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @"$F" "$URL" > /root/autodl-tmp/CIE6004_ASGN2/logs/upload_records.json 2>&1 &
echo "started upload pid $!"
sleep 20
tail -c 300 /root/autodl-tmp/CIE6004_ASGN2/logs/upload_records.json 2>/dev/null | head -c 300; echo
echo UPLOAD_STARTED