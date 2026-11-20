"""Remove the halo *around* the object without touching the body.

The initial model has a coherent body plus sparse bright splats around it; colour/scale
smoothing fixed the halo but broke the body. This filter only removes the halo:

  1. estimate the body core from the high-opacity splats (median centre, p90 radius),
  2. drop splats that are far from the core AND faint.

Nothing inside the core is modified, so the body keeps its opacity/colour.
"""
import argparse

import numpy as np
from plyfile import PlyData, PlyElement


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--ply", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--core_ratio", type=float, default=1.15)
    p.add_argument("--opacity_cut", type=float, default=0.45)
    p.add_argument("--core_opacity", type=float, default=0.60)
    args = p.parse_args()

    v = PlyData.read(args.ply)["vertex"]
    names = [pr.name for pr in v.properties]
    d = {n: np.array(v[n]) for n in names}
    xyz = np.stack([d["x"], d["y"], d["z"]], 1).astype(np.float64)
    op = 1.0 / (1.0 + np.exp(-d["opacity"].astype(np.float64)))

    core = op >= args.core_opacity
    if core.sum() < 50:
        core = op >= np.percentile(op, 90)
    c = np.median(xyz[core], axis=0)
    rad = np.linalg.norm(xyz[core] - c, axis=1)
    R = float(np.percentile(rad, 90))
    dist = np.linalg.norm(xyz - c, axis=1)

    drop = (dist > args.core_ratio * R) & (op < args.opacity_cut)
    keep = ~drop
    print("core splats %d, R_core %.4f | drop %d (%.1f%%) keep %d"
          % (core.sum(), R, drop.sum(), 100 * drop.mean(), keep.sum()))

    out = {n: d[n][keep].astype(np.float32) for n in names}
    arr = np.array(list(zip(*[out[n] for n in names])), dtype=[(n, "f4") for n in names])
    PlyData([PlyElement.describe(arr, "vertex")]).write(args.out)
    print("wrote", args.out, len(arr))


if __name__ == "__main__":
    main()
