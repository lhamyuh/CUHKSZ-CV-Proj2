"""Prune object gaussians that lie outside the foreground masks in most training views.

White-background training tends to leave a white "halo" around the object; those
gaussians project outside the masks and are invisible in the source footage, so we
drop them. This is a visibility-consistency prune, not a colour heuristic.

  python code/prune_object.py --run runs/obj_w --masks data_object/masks --out pruned.ply
"""
import argparse
import json
import os

import numpy as np
from PIL import Image
from plyfile import PlyData, PlyElement


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--run", required=True)
    p.add_argument("--masks", required=True)
    p.add_argument("--ply", default="")
    p.add_argument("--out", required=True)
    p.add_argument("--min_ratio", type=float, default=0.5)
    p.add_argument("--subsample", type=int, default=40)
    p.add_argument("--scale_shrink", type=float, default=0.6,
                   help="multiply log-scale by this factor after pruning (shrink halo sizes)")
    p.add_argument("--max_dist", type=float, default=0.0,
                   help="if >0, drop gaussians farther than this from the centroid")
    p.add_argument("--white_thresh", type=float, default=1.1,
                   help="if <1, drop gaussians whose min RGB channel exceeds this and lie beyond half max_dist")
    args = p.parse_args()

    ply_path = args.ply or os.path.join(args.run, "point_cloud/iteration_30000/point_cloud.ply")
    ply = PlyData.read(ply_path)
    v = ply["vertex"]
    names = [pr.name for pr in v.properties]
    data = {n: np.array(v[n]) for n in names}
    xyz = np.stack([data["x"], data["y"], data["z"]], 1).astype(np.float64)
    print("gaussians:", len(xyz))

    cams = json.load(open(os.path.join(args.run, "cameras.json")))
    cams = cams[: args.subsample] if args.subsample else cams
    keep = np.zeros(len(xyz), dtype=bool)
    ratios = np.zeros(len(xyz), dtype=np.float32)
    for c in cams:
        stem = os.path.splitext(c["img_name"])[0]
        mpath = os.path.join(args.masks, stem + ".png")
        if not os.path.exists(mpath):
            continue
        m = np.asarray(Image.open(mpath).convert("L")) > 127
        R = np.array(c["rotation"], dtype=np.float64)      # camera-to-world
        C = np.array(c["position"], dtype=np.float64)
        fx, fy = float(c["fx"]), float(c["fy"])
        W, H = c["width"], c["height"]
        cam = (xyz - C) @ R                                   # == R^T (x - C)
        z = cam[:, 2]
        ok = z > 1e-6
        u = np.full(len(xyz), -1.0)
        w = np.full(len(xyz), -1.0)
        u[ok] = fx * cam[ok, 0] / z[ok] + W / 2
        w[ok] = fy * cam[ok, 1] / z[ok] + H / 2
        mh, mw = m.shape[0], m.shape[1]
        su = mw / float(W)
        sv = mh / float(H)
        ui = np.clip(u * su, 0, mw - 1).astype(int)
        wi = np.clip(w * sv, 0, mh - 1).astype(int)
        inside = ok & (u >= 0) & (u < W) & (w >= 0) & (w < H) & m[wi, ui]
        ratios += inside.astype(np.float32)
    ratios /= max(len(cams), 1)
    keep = ratios >= args.min_ratio
    if args.max_dist > 0:
        c0 = xyz.mean(0)
        dist = np.linalg.norm(xyz - c0, axis=1)
        keep &= dist < args.max_dist
        if args.white_thresh < 1.0:
            C0 = 0.28209479177387814
            rgb = 0.5 + C0 * np.stack([data["f_dc_0"], data["f_dc_1"], data["f_dc_2"]], 1)
            whitish = rgb.min(1) > args.white_thresh
            keep &= ~(whitish & (dist > 0.5 * args.max_dist))
    print(f"keep {keep.sum()}/{len(keep)} ({100*keep.mean():.1f}%) at min_ratio {args.min_ratio}")

    out = {}
    for n in names:
        arr = data[n][keep]
        if n.startswith("scale_"):
            arr = arr + np.log(args.scale_shrink)
        out[n] = arr.astype(np.float32)
    el = PlyElement.describe(np.array(list(zip(*[out[n] for n in names])), dtype=[(n, "f4") for n in names]), "vertex")
    PlyData([el]).write(args.out)
    print("wrote", args.out, len(out["x"]))


if __name__ == "__main__":
    main()
