#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/render_views.py --ply $ROOT/runs/garden_45k/point_cloud/iteration_45000/point_cloud.ply \
  --cameras $ROOT/release/val/cameras.json --out $ROOT/runs/garden_45k/renders_val 2>&1 | tail -1
python $ROOT/release/tools/evaluate.py $ROOT/release/val $ROOT/runs/garden_45k/renders_val $ROOT/runs/garden_45k/metrics_val.json 2>&1 | tail -1
python - <<'PY'
import json
R='/root/autodl-tmp/CIE6004_ASGN2'
a=json.load(open(f'{R}/runs/garden_base/metrics_val.json'))['means']
b=json.load(open(f'{R}/runs/garden_45k/metrics_val.json'))['means']
print('30k  PSNR %.3f SSIM %.4f LPIPS %.4f' % (a['psnr'],a['ssim'],a['lpips']))
print('45k  PSNR %.3f SSIM %.4f LPIPS %.4f' % (b['psnr'],b['ssim'],b['lpips']))
print('delta PSNR %+.3f  SSIM %+.4f  LPIPS %+.4f' % (b['psnr']-a['psnr'], b['ssim']-a['ssim'], b['lpips']-a['lpips']))
PY
echo EVAL45K_DONE