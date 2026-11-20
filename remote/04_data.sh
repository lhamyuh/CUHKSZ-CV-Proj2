#!/usr/bin/env bash
set -euo pipefail
cd /root/autodl-tmp/CIE6004_ASGN2
source env/bin/activate
rm -rf release/Assignment2_release
unzip -q release.zip -d release
shopt -s dotglob
mv release/Assignment2_release/* release/
rmdir release/Assignment2_release
find release -name '._*' -delete
find release -name '.DS_Store' -delete
echo "--- release top ---"
ls release
echo "--- counts ---"
echo -n "train images: "; ls release/train/images | wc -l
echo -n "val refs: "; ls release/val/reference | wc -l
echo -n "val baseline: "; ls release/val/baseline | wc -l
echo "--- sparse ---"
ls -l release/train/sparse/0
echo "--- any junk left ---"
find release -name '._*' | head -5
echo "--- disk ---"
df -h /root/autodl-tmp | tail -1
echo DATA_OK
