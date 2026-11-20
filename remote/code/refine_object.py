"""Clean up the object point cloud: remove floaters, raise the opacity distribution.

Diagnosis on the white-background training: p05 opacity 0.007, median 0.080, and 64% of
Gaussians below 0.15. Those low-opacity splats are exactly the white haze and the
"semi-transparent body" seen in the orbit. We
  * drop Gaussians with opacity < --min_opacity,
  * drop oversized floaters (max scale > --max_scale),
  * remap the remaining opacity in logit space: logit' = a*logit + b.
"""
import argparse

import numpy as np
from plyfile import PlyData, PlyElement


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--ply", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--min_opacity", type=float, default=0.03)
    p.add_argument("--max_scale", type=float, default=0.12)
    p.add_argument("--gain", type=float, default=1.0, help="multiplier on logit")
    p.add_argument("--bias", type=float, default=0.0, help="additive in logit space")
    p.add_argument("--min_neighbors", type=int, default=0,
                   help=">0 keeps only Gaussians with at least this many neighbours within --radius")
    p.add_argument("--radius", type=float, default=0.05)
    args = p.parse_args()

    v = PlyData.read(args.ply)["vertex"]
    names = [pr.name for pr in v.properties]
    d = {n: np.array(v[n]) for n in names}

    op_raw = d["opacity"].astype(np.float64)
    op = 1.0 / (1.0 + np.exp(-op_raw))
    sh = np.exp(np.stack([d["scale_0"], d["scale_1"], d["scale_2"]], 1).astype(np.float64))

    keep = (op >= args.min_opacity) & (sh.max(1) <= args.max_scale)
    if args.min_neighbors > 0:
        from scipy.spatial import cKDTree
        xyz = np.stack([d["x"], d["y"], d["z"]], 1).astype(np.float64)
        tree = cKDTree(xyz)
        cnt = np.array([len(tree.query_ball_point(p, args.radius)) - 1 for p in xyz])
        keep &= cnt >= args.min_neighbors
        print(f"density filter: median neighbours {np.median(cnt):.0f}, dropped {(cnt < args.min_neighbors).sum()}")
    print(f"keep {keep.sum()}/{len(keep)} ({100*keep.mean():.1f}%)")

    for n in names:
        d[n] = d[n][keep]
    logit = d["opacity"].astype(np.float64)
    logit = args.gain * logit + args.bias
    d["opacity"] = logit.astype(np.float32)

    newop = 1.0 / (1.0 + np.exp(-d["opacity"]))
    print("opacity after: p05 %.3f median %.3f p95 %.3f" %
          (np.percentile(newop, 5), np.median(newop), np.percentile(newop, 95)))

    arr = np.array(list(zip(*[d[n] for n in names])), dtype=[(n, "f4") for n in names])
    PlyData([PlyElement.describe(arr, "vertex")]).write(args.out)
    print("wrote", args.out, len(arr))


if __name__ == "__main__":
    main()
