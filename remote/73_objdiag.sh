#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python - <<'PY'
import numpy as np
from plyfile import PlyData
R='/root/autodl-tmp/CIE6004_ASGN2'
n_obj=69690
v=PlyData.read(f'{R}/runs/fusion/fused_v9.ply')['vertex']
n=len(v['x']); print('total',n)
x=np.stack([v['x'],v['y'],v['z']],1).astype(np.float64)
o=x[n-n_obj:]
print('object bbox min',np.round(o.min(0),3),'max',np.round(o.max(0),3))
op=1/(1+np.exp(-np.array(v['opacity'][n-n_obj:])))
print('object opacity mean %.3f p50 %.3f max %.3f' % (op.mean(), np.median(op), op.max()))
C0=0.28209479177387814
rgb=0.5+C0*np.stack([np.array(v['f_dc_0'][n-n_obj:]),np.array(v['f_dc_1'][n-n_obj:]),np.array(v['f_dc_2'][n-n_obj:])],1)
print('object rgb mean',np.round(rgb.mean(0),3),'nan?',np.isnan(rgb).any())
print('scene bbox min',np.round(x[:n-n_obj].min(0),3),'max',np.round(x[:n-n_obj].max(0),3))
PY
echo OBJDIAG_DONE