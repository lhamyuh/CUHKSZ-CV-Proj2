"""Bonus: contact shadow + brightness match for the inserted object.

The merged PLY stores scene Gaussians first and the object last. We
  1) darken table Gaussians near the object base with a radial falloff (contact shadow),
  2) scale the object's SH DC by a small factor so it sits closer to the table's brightness.
No geometry is added, so depth ordering and the rest of the scene are untouched.
"""
import argparse
import json
import math

import numpy as np
from plyfile import PlyData, PlyElement

SH_C0 = 0.28209479177387814


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--ply", required=True)
    p.add_argument("--n_object", type=int, required=True)
    p.add_argument("--placement", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--shadow_radius", type=float, default=0.30)
    p.add_argument("--shadow_sigma", type=float, default=0.12)
    p.add_argument("--shadow_strength", type=float, default=0.55)
    p.add_argument("--object_gain", type=float, default=0.92)
    args = p.parse_args()

    ply = PlyData.read(args.ply)
    v = ply["vertex"]
    names = [pr.name for pr in v.properties]
    data = {n: np.array(v[n]) for n in names}
    n_all = len(data["x"])
    n_obj = args.n_object
    n_scene = n_all - n_obj
    print("scene", n_scene, "object", n_obj)

    pl = json.load(open(args.placement))
    up = np.array(pl["scene_up"])
    p_center = np.array(pl["position"])
    # object half-height along up in scene units: use the transformed model extent
    half_h = 0.5 * 2.989 * pl["scale"]
    base = p_center - half_h * up

    xyz = np.stack([data["x"], data["y"], data["z"]], 1).astype(np.float64)
    h = (xyz[:n_scene] - base) @ up
    radial = xyz[:n_scene] - base - h[:, None] * up
    r = np.linalg.norm(radial, axis=1)
    near_plane = np.abs(h) < 0.03
    w = np.exp(-(r ** 2) / (2 * args.shadow_sigma ** 2)) * near_plane
    shade = 1.0 - args.shadow_strength * w
    print(f"shadow affects {(shade < 0.999).sum()} table Gaussians, min {shade.min():.3f}")

    for c in ("f_dc_0", "f_dc_1", "f_dc_2"):
        data[c][:n_scene] = data[c][:n_scene] * shade.astype(np.float32)
    for c in ("f_dc_0", "f_dc_1", "f_dc_2"):
        data[c][n_scene:] = data[c][n_scene:] * args.object_gain

    arr = np.array(list(zip(*[data[n] for n in names])), dtype=[(n, "f4") for n in names])
    PlyData([PlyElement.describe(arr, "vertex")]).write(args.out)
    print("wrote", args.out)


if __name__ == "__main__":
    main()
