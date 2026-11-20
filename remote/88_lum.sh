#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python - <<'PY'
import json, numpy as np
from PIL import Image
R='/root/autodl-tmp/CIE6004_ASGN2'
cams=json.load(open(f'{R}/release/val/cameras.json'))['views']
rat=[]; gains=[]
for v in cams:
    stem=v['name'].split('.')[0]
    a=np.asarray(Image.open(f'{R}/runs/garden_base/renders_val/{stem}.png').convert('RGB'),np.float32)/255
    b=np.asarray(Image.open(f'{R}/release/val/reference/{v["name"]}').convert('RGB'),np.float32)/255
    la,lb=a.mean(),b.mean(); rat.append(la/lb); gains.append(np.log(lb/la))
    print('%-14s ours %.3f ref %.3f ratio %.3f' % (stem, la, lb, la/lb))
print('mean ratio %.4f  std %.4f  -> suggested gain %.3f' % (np.mean(rat), np.std(rat), float(np.exp(np.mean(gains)))))
PY
echo LUM_DONE