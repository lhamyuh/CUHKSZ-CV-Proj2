"""Remove needle-like bright splats that read as white strands around the object.

Heuristics (all in object space):
  * anisotropy = max(scale) / min(scale); needles are 8-50x elongated,
  * bright   : min(RGB) above --bright,
  * isolated : fewer than --min_neigh neighbours within --radius.
A splat is dropped when it is (needle and bright) or (bright and isolated).
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
    p.add_argument("--aniso", type=float, default=8.0)
    p.add_argument("--bright", type=float, default=0.55)
    p.add_argument("--min_neigh", type=int, default=4)
    p.add_argument("--radius", type=float, default=0.03)
    args = p.parse_args()

    v = PlyData.read(args.ply)["vertex"]
    names = [pr.name for pr in v.properties]
    d = {n: np.array(v[n]) for n in names}
    xyz = np.stack([d["x"], d["y"], d["z"]], 1).astype(np.float64)
    sc = np.exp(np.stack([d[f"scale_{i}"] for i in range(3)], 1).astype(np.float64))
    rgb = 0.5 + C0 * np.stack([d["f_dc_0"], d["f_dc_1"], d["f_dc_2"]], 1)
    bright = rgb.min(1) > args.bright
    aniso = sc.max(1) / np.maximum(sc.min(1), 1e-9)
    needle = aniso > args.aniso
    tree = cKDTree(xyz)
    nb = tree.query_ball_point(xyz, args.radius)
    n_cnt = np.array([len(x) - 1 for x in nb])
    isolated = n_cnt < args.min_neigh
    drop = ((needle & bright) | (bright & isolated))
    keep = ~drop
    print("points %d | bright %d needle %d isolated %d -> drop %d (%.1f%%), keep %d"
          % (len(xyz), bright.sum(), needle.sum(), isolated.sum(), drop.sum(),
             100 * drop.mean(), keep.sum()))

    out = {}
    for n in names:
        out[n] = d[n][keep].astype(np.float32)
    arr = np.array(list(zip(*[out[n] for n in names])), dtype=[(n, "f4") for n in names])
    PlyData([PlyElement.describe(arr, "vertex")]).write(args.out)
    print("wrote", args.out, len(arr))


if __name__ == "__main__":
    main()
