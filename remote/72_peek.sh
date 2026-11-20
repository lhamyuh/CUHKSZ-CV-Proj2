#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python - <<'PY'
from PIL import Image
R='/root/autodl-tmp/CIE6004_ASGN2'
im=Image.open(f'{R}/runs/fusion/probe_v9/frame_120.png').convert('RGB')
im.resize((900,506), Image.LANCZOS).save(f'{R}/preview/peek_v9.jpg', quality=82)
print('saved')
PY
echo PEEK_DONE