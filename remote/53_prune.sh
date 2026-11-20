#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python code/prune_object.py --run $ROOT/runs/obj_w --masks $ROOT/data_object/masks \
  --out $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_pruned.ply --min_ratio 0.5 2>&1 | tail -3
python - <<'PY'
import numpy as np
from plyfile import PlyData
v = PlyData.read('/root/autodl-tmp/CIE6004_ASGN2/runs/obj_w/point_cloud/iteration_30000/point_cloud_pruned.ply')['vertex']
xyz = np.stack([v['x'],v['y'],v['z']],1).astype(np.float64)
lo,hi=np.percentile(xyz,1,0),np.percentile(xyz,99,0)
print('bbox',np.round(lo,3),np.round(hi,3),'extent',np.round(hi-lo,3),'diag',round(float(np.linalg.norm(hi-lo)),3))
c=xyz.mean(0); P=xyz-c; w,V=np.linalg.eigh(P.T@P/len(P)); o=np.argsort(w)[::-1]
print('centre',np.round(c,3))
for k in o:
    pr=P@V[:,k]; print(' axis',np.round(V[:,k],3),'std',round(float(np.sqrt(w[k])),3),'range',round(float(pr.max()-pr.min()),3))
PY
echo PRUNE_DONE