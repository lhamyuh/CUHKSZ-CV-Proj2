"""Create an orbit camera JSON around the reconstructed object.

Two modes:
  --ply + --cameras : centre/radius/up are estimated from the *training camera centres*
                      (a turntable-like capture), which is far more reliable than the
                      point-cloud bounding box when floaters are present.
  --ply only        : fall back to a robust point-cloud bounding box.
"""
import argparse
import json
import math
import os

import numpy as np
from plyfile import PlyData


def load_xyz(ply_path):
    ply = PlyData.read(ply_path)
    v = ply["vertex"]
    return np.stack([v["x"], v["y"], v["z"]], axis=1).astype(np.float64)


def robust_bounds(xyz, q=1.0):
    return np.percentile(xyz, q, axis=0), np.percentile(xyz, 100 - q, axis=0)


def estimate_from_cameras(cam_json, bbox_center):
    cams = json.load(open(cam_json))
    C = np.array([c["position"] for c in cams], dtype=np.float64)
    center = np.median(C, axis=0)
    radius = float(np.median(np.linalg.norm(C - center, axis=1)))
    _, _, vt = np.linalg.svd(C - center)
    n = vt[2]
    n /= np.linalg.norm(n)
    if np.dot(n, center - bbox_center) < 0:
        n = -n
    return center, radius, n


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--ply", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--cameras", default="", help="3DGS cameras.json of the training run")
    p.add_argument("--size", type=int, default=512)
    p.add_argument("--fovy_deg", type=float, default=42.0)
    p.add_argument("--n", type=int, default=120)
    p.add_argument("--elev_deg", type=float, default=15.0)
    p.add_argument("--radius_scale", type=float, default=1.0)
    args = p.parse_args()

    xyz = load_xyz(args.ply)
    lo, hi = robust_bounds(xyz, 1.0)
    bbox_center = 0.5 * (lo + hi)

    if args.cameras:
        center, radius, up = estimate_from_cameras(args.cameras, bbox_center)
        target = bbox_center
    else:
        center = bbox_center
        radius = 0.5 * float(np.linalg.norm(hi - lo)) * 2.5
        up = np.array([0.0, 0.0, 1.0])
        target = bbox_center
    radius *= args.radius_scale

    # basis in the orbit plane
    tmp = np.array([1.0, 0.0, 0.0])
    if abs(np.dot(tmp, up)) > 0.9:
        tmp = np.array([0.0, 1.0, 0.0])
    e1 = np.cross(up, tmp)
    e1 /= np.linalg.norm(e1)
    e2 = np.cross(up, e1)

    fovy = math.radians(args.fovy_deg)
    f = 0.5 * args.size / math.tan(0.5 * fovy)
    elev = math.radians(args.elev_deg)

    views = []
    for i in range(args.n):
        a = 2 * math.pi * i / args.n
        pos = center + radius * (math.cos(a) * e1 + math.sin(a) * e2) + radius * math.tan(elev) * up
        forward = target - pos
        forward /= np.linalg.norm(forward)
        right = np.cross(forward, up)
        if np.linalg.norm(right) < 1e-6:
            right = e1
        right /= np.linalg.norm(right)
        down = np.cross(forward, right)
        R = np.stack([right, down, forward])
        t = -R @ pos
        M = np.eye(4)
        M[:3, :3] = R
        M[:3, 3] = t
        views.append({"name": f"orbit_{i:04d}", "world_to_camera": M.tolist()})

    out = {"width": args.size, "height": args.size, "fx": f, "fy": f,
           "cx": args.size / 2, "cy": args.size / 2,
           "center": center.tolist(), "target": target.tolist(),
           "radius": radius, "up": up.tolist(), "views": views}
    json.dump(out, open(args.out, "w"), indent=1)
    print(f"orbit: centre {np.round(center,3)} radius {radius:.3f} up {np.round(up,3)} n={args.n}")


if __name__ == "__main__":
    main()
