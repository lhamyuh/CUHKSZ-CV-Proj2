#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python - <<'PY'
from PIL import Image
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
im=Image.open(f'{R}/runs/fusion/final2_frames/frame_000.png').convert('RGB')
im.crop((150,300,650,650)).resize((760,532), Image.LANCZOS).save(f'{G}/final2_zoom.jpg', quality=86)
print('ok')
PY
echo ZOOM_DONE