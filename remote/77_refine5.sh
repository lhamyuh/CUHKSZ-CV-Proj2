#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/refine_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --object $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_refined2.ply \
  --placement $ROOT/runs/fusion/placement_v7.json --clearance_pct 20 \
  --shadow_sigma 0.12 --shadow_strength 0.70 --object_gain 1.35 \
  --out_scene $ROOT/runs/fusion/fused_v12.ply --out_placement $ROOT/preview/placement_v12.json 2>&1 | tail -3
python code/render_views.py --ply $ROOT/runs/fusion/fused_v12.ply --cameras $ROOT/runs/fusion/closeup.json --out $ROOT/runs/fusion/closeup_v12 --bg 0 2>&1 | tail -1
python - <<'PY'
from PIL import Image
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
close=Image.open(f'{R}/runs/fusion/closeup_v12/closeup.png').convert('RGB')
crop=close.crop((520,220,900,470)).resize((760,500), Image.LANCZOS)
crop.save(f'{G}/closeup_v12.jpg', quality=85)
print('ok')
PY
echo REFINE5_DONE