#!/usr/bin/env bash
set -uo pipefail
TOK="__TOKEN__"
F=/root/autodl-tmp/CIE6004_ASGN2/deliver/gallery_226010334_LinyuYANG.tar.gz
URL="https://uploads.github.com/repos/lhamyuh/CUHKSZ-CV-Proj2/releases/453041725/assets?name=gallery_226010334_LinyuYANG.tar.gz"
curl -sS --retry 3 -X POST -H "Authorization: token $TOK" -H "Content-Type: application/octet-stream" --data-binary @"$F" "$URL" | head -c 300
echo
sha256sum $F
echo GALLERY_UPLOADED