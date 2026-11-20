#!/usr/bin/env bash
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python - <<'PY'
import numpy as np
from plyfile import PlyData
v = PlyData.read('/root/autodl-tmp/CIE6004_ASGN2/runs/obj_w/point_cloud/iteration_30000/point_cloud.ply')['vertex']
xyz = np.stack([v['x'], v['y'], v['z']], 1).astype(np.float64)
lo, hi = np.percentile(xyz, 1, 0), np.percentile(xyz, 99, 0)
print('robust bbox min', np.round(lo, 4), 'max', np.round(hi, 4))
print('extent', np.round(hi - lo, 4), 'diag', round(float(np.linalg.norm(hi-lo)), 4))
c = xyz.mean(0)
P = xyz - c
cov = P.T @ P / len(P)
w, V = np.linalg.eigh(cov)
order = np.argsort(w)[::-1]
print('pca centre', np.round(c, 4))
for k in order:
    ax = V[:, k]
    proj = P @ ax
    print(f'  axis {np.round(ax,4)} std {np.sqrt(w[k]):.4f} range [{proj.min():.3f},{proj.max():.3f}]')
PY
echo STATS_DONE