#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python - <<'PY'
import json, numpy as np
from plyfile import PlyData
R='/root/autodl-tmp/CIE6004_ASGN2'
v=PlyData.read(f'{R}/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply')['vertex']
x=np.stack([v['x'],v['y'],v['z']],1).astype(np.float64)
g=json.load(open(f'{R}/preview/table_geometry.json')); c=np.array(g['centre']); up=np.array(g['normal']); up/=np.linalg.norm(up)
C0=0.28209479177387814
rgb=0.5+C0*np.stack([np.array(v['f_dc_0']),np.array(v['f_dc_1']),np.array(v['f_dc_2'])],1)
h=(x-c)@up; r=np.linalg.norm((x-c)-h[:,None]*up,axis=1)
sel=(np.abs(h)<0.04)&(r<1.05)
print(' r-bin      n     R     G     B   lum    R-B')
for lo in np.arange(0.0,1.0,0.1):
    m=sel&(r>=lo)&(r<lo+0.1)
    if m.sum()>200:
        rr=rgb[m].mean(0)
        print('%.1f-%.1f %6d %.3f %.3f %.3f %.3f %+.3f' % (lo,lo+0.1,m.sum(),rr[0],rr[1],rr[2],rr.mean(),rr[0]-rr[2]))
PY
echo DISC2_DONE