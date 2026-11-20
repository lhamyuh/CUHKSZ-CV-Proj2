#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python - <<'PY'
import numpy as np
from plyfile import PlyData
R='/root/autodl-tmp/CIE6004_ASGN2'
v=PlyData.read(f'{R}/runs/obj_d2/point_cloud/iteration_30000/point_cloud_refined.ply')['vertex']
xyz=np.stack([v['x'],v['y'],v['z']],1).astype(np.float64)
lo,hi=np.percentile(xyz,1,0),np.percentile(xyz,99,0)
print('bbox',np.round(lo,3),np.round(hi,3),'extent',np.round(hi-lo,3))
c=xyz.mean(0); P=xyz-c; w,V=np.linalg.eigh(P.T@P/len(P)); o=np.argsort(w)[::-1]
print('centre',np.round(c,4))
for k in o:
    pr=P@V[:,k]; print(' axis',np.round(V[:,k],4),'range %.3f' % (pr.max()-pr.min()))
PY
echo STATS2_DONE