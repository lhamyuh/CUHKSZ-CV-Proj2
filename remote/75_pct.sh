#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python - <<'PY'
import json, numpy as np
from plyfile import PlyData
R='/root/autodl-tmp/CIE6004_ASGN2'
pl=json.load(open(f'{R}/runs/fusion/placement_v7.json')); M=np.array(pl['object_to_scene']); s=pl['scale']
up=np.array(pl['scene_up']); c=np.array(pl['table_centre']); G=M[:3,:3]/s; t=M[:3,3]
v=PlyData.read(f'{R}/runs/obj_w/point_cloud/iteration_30000/point_cloud_refined2.ply')['vertex']
xyz=np.stack([v['x'],v['y'],v['z']],1).astype(np.float64)
w=s*(xyz@G.T)+t; h=(w-c)@up
for q in (1,3,5,10,15,20,30,50):
    print('p%-3d %6.1f mm' % (q, np.percentile(h,q)*1000))
# local table surface under the object
sg=PlyData.read(f'{R}/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply')['vertex']
sx=np.stack([sg['x'],sg['y'],sg['z']],1).astype(np.float64)
sh=(sx-c)@up; oc=w.mean(0); rad=np.linalg.norm((sx-oc)-((sx-oc)@up)[:,None]*up,axis=1)
loc=(rad<0.18)&(np.abs(sh)<0.15)
print('local surface under object: n=%d p50 %.1f p90 %.1f mm' % (loc.sum(), np.percentile(sh[loc],50)*1000, np.percentile(sh[loc],90)*1000))
# metal disc vs wood: radial bands
sr=np.linalg.norm((sx-c)-sh[:,None]*up,axis=1)
for lo,hi in ((0.0,0.30),(0.30,0.55),(0.55,0.90)):
    band=(sr>lo)&(sr<hi)&(np.abs(sh)<0.10)
    print('band %.2f-%.2f: n=%d p50 height %.1f mm' % (lo,hi,band.sum(), np.percentile(sh[band],50)*1000))
PY
echo PCT_DONE