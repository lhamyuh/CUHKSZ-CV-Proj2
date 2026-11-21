#!/usr/bin/env bash
set -uo pipefail
TOK="${GITHUB_TOKEN:?}"
F=/root/autodl-tmp/CIE6004_ASGN2/deliver/repro_226010334_LinyuYANG.tar.gz
URL="https://uploads.github.com/repos/lhamyuh/CUHKSZ-CV-Proj2/releases/453041725/assets?name=repro_226010334_LinyuYANG.tar.gz"
curl -sS --retry 3 -X POST -H "Authorization: token $TOK" -H "Content-Type: application/octet-stream" --data-binary @"$F" "$URL" | head -c 400
echo
sha256sum $F
echo REPRO_UPLOADED