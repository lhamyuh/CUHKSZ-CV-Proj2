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
up=np.array(pl['scene_up']); c=np.array(pl['table_centre'])
v=PlyData.read(f'{R}/runs/obj_w/point_cloud/iteration_30000/point_cloud_pruned3.ply')['vertex']
xyz=np.stack([v['x'],v['y'],v['z']],1).astype(np.float64)
w=(s*(xyz@ (M[:3,:3]/s).T)+M[:3,3])
h=(w-c)@up
print('object height above table plane: min %.4f  max %.4f  (units; 1 unit ~ 1 m)' % (h.min(), h.max()))
print('=> clearance below object (should be ~0): %.1f mm' % ((h.min())*1000))
op=1/(1+np.exp(-np.array(v['opacity'])))
sh=np.exp(np.stack([v['scale_0'],v['scale_1'],v['scale_2']],1))
print('opacity: min %.3f p05 %.3f median %.3f p95 %.3f' % (op.min(), np.percentile(op,5), np.median(op), np.percentile(op,95)))
print('gaussians with opacity<0.15: %d (%.1f%%)' % ((op<0.15).sum(), 100*(op<0.15).mean()))
print('gaussians with max scale > 0.10 units: %d' % ((sh.max(1)>0.10).sum()))
C0=0.28209479177387814
rgb=0.5+C0*np.stack([np.array(v['f_dc_0']),np.array(v['f_dc_1']),np.array(v['f_dc_2'])],1)
print('object mean RGB', np.round(rgb.mean(0),3), 'lum %.3f' % rgb.mean())
# table brightness near the object
sg=PlyData.read(f'{R}/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply')['vertex']
sx=np.stack([sg['x'],sg['y'],sg['z']],1).astype(np.float64)
srgb=0.5+C0*np.stack([np.array(sg['f_dc_0']),np.array(sg['f_dc_1']),np.array(sg['f_dc_2'])],1)
hh=(sx-c)@up; rr=np.linalg.norm((sx-c)-hh[:,None]*up,axis=1)
near=(np.abs(hh)<0.05)&(rr<0.45)&(rr>0.15)
print('table around object: n=%d mean RGB %s lum %.3f' % (near.sum(), np.round(srgb[near].mean(0),3), srgb[near].mean()))
PY
echo DIAG_DONE