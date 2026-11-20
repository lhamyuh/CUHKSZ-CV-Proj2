"""Smooth the object's surface appearance: median-blend colour, opacity and scale.

White-background 3DGS training leaves needle-like splats and colour speckle. We cannot add
detail that is not in the data, but we can trade the sharp noise for a smoother surface:

  * k-NN (k=--k) in object space,
  * colour:   dc'   = (1-a) dc   + a * median(neighbour dc)
  * opacity:  op'   = (1-b) op   + b * median(neighbour op)      (logit space)
  * scale:    clamp to [1/c, c] * median(neighbour scale), then blend

  python code/smooth_object.py --ply in.ply --out out.ply --k 12
"""
import argparse

import numpy as np
from plyfile import PlyData, PlyElement
from scipy.spatial import cKDTree

C0 = 0.28209479177387814


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--ply", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--k", type=int, default=12)
    p.add_argument("--color_alpha", type=float, default=0.5)
    p.add_argument("--opacity_beta", type=float, default=0.5)
    p.add_argument("--scale_clamp", type=float, default=1.8)
    p.add_argument("--scale_alpha", type=float, default=0.4)
    args = p.parse_args()

    v = PlyData.read(args.ply)["vertex"]
    names = [pr.name for pr in v.properties]
    d = {n: np.array(v[n]) for n in names}
    xyz = np.stack([d["x"], d["y"], d["z"]], 1).astype(np.float64)
    tree = cKDTree(xyz)
    _, idx = tree.query(xyz, k=args.k + 1)
    nb = idx[:, 1:]
    print("points", len(xyz), "k", nb.shape[1])

    # colour
    rgb = 0.5 + C0 * np.stack([d["f_dc_0"], d["f_dc_1"], d["f_dc_2"]], 1)
    med = np.median(rgb[nb], axis=1)
    rgb2 = (1 - args.color_alpha) * rgb + args.color_alpha * med

    # opacity in logit space
    op = d["opacity"].astype(np.float64)
    op_med = np.median(op[nb], axis=1)
    op2 = (1 - args.opacity_beta) * op + args.opacity_beta * op_med

    # scale: clamp extremes toward the neighbourhood median
    sc = np.stack([d[f"scale_{i}"] for i in range(3)], 1).astype(np.float64)
    sc_med = np.median(sc[nb], axis=1)
    lo = sc_med - np.log(args.scale_clamp)
    hi = sc_med + np.log(args.scale_clamp)
    sc_clamped = np.clip(sc, lo, hi)
    sc2 = (1 - args.scale_alpha) * sc_clamped + args.scale_alpha * sc_med

    print("colour delta %.4f  opacity delta %.3f  scale delta %.3f"
          % (np.abs(rgb2 - rgb).mean(), np.abs(op2 - op).mean(), np.abs(sc2 - sc).mean()))

    for k, c in enumerate(("f_dc_0", "f_dc_1", "f_dc_2")):
        d[c] = ((rgb2[:, k] - 0.5) / C0).astype(np.float32)
    d["opacity"] = op2.astype(np.float32)
    for i in range(3):
        d[f"scale_{i}"] = sc2[:, i].astype(np.float32)

    arr = np.array(list(zip(*[d[n] for n in names])), dtype=[(n, "f4") for n in names])
    PlyData([PlyElement.describe(arr, "vertex")]).write(args.out)
    print("wrote", args.out, len(arr))


if __name__ == "__main__":
    main()
