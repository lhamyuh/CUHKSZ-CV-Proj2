"""RANSAC the Garden tabletop plane from the sparse cloud using one val view.

Points are selected by an image-space ellipse around the table, then the dominant
plane is fitted; its normal is the scene "up" (oriented towards the camera), the
inlier centroid the table centre, and the inlier spread the table radius.
"""
import json
import struct
from pathlib import Path

import numpy as np

REL = Path(r"D:\Essay\CUHKSZ\AY2627Term1\Image Processing\Asgn2\Assignment2_release")
OUT = Path(r"D:\Essay\CUHKSZ\AY2627Term1\Image Processing\Asgn2\preview")


def read_points3d(path):
    pts = []
    with open(path, "rb") as f:
        n = struct.unpack("<Q", f.read(8))[0]
        for _ in range(n):
            f.read(8)
            xyz = struct.unpack("<3d", f.read(24))
            f.read(3)
            f.read(8)
            tl = struct.unpack("<Q", f.read(8))[0]
            f.read(8 * tl)
            pts.append(xyz)
    return np.asarray(pts)


def fit_plane(P):
    c = P.mean(0)
    _, _, vt = np.linalg.svd(P - c)
    n = vt[2]
    return c, n / np.linalg.norm(n)


def main():
    pts = read_points3d(REL / "train" / "sparse" / "0" / "points3D.bin")
    cams = json.loads((REL / "val" / "cameras.json").read_text())
    view = next(v for v in cams["views"] if v["name"] == "DSC07956.JPG")
    M = np.asarray(view["world_to_camera"])
    R, t = M[:3, :3], M[:3, 3]
    fx, fy, cx, cy = cams["fx"], cams["fy"], cams["cx"], cams["cy"]
    cam = pts @ R.T + t
    z = cam[:, 2]
    ok = z > 0.1
    u = fx * cam[:, 0] / np.where(ok, z, 1) + cx
    v = fy * cam[:, 1] / np.where(ok, z, 1) + cy
    ell = ((u - 650) / 330.0) ** 2 + ((v - 405) / 95.0) ** 2
    sel = ok & (ell < 1.0)
    P = pts[sel]
    print("selected points:", len(P))

    rng = np.random.default_rng(0)
    best = None
    for _ in range(3000):
        idx = rng.choice(len(P), 3, replace=False)
        a, b, c = P[idx]
        n = np.cross(b - a, c - a)
        nn = np.linalg.norm(n)
        if nn < 1e-9:
            continue
        n /= nn
        d = np.abs((P - a) @ n)
        inl = d < 0.02
        if best is None or inl.sum() > best[0]:
            best = (int(inl.sum()), n, a, inl)
    ninl, n, a, inl = best
    c, n2 = fit_plane(P[inl])
    if np.dot(n2, n) < 0:
        n2 = -n2
    C = -R.T @ t
    if np.dot(n2, C - c) < 0:
        n2 = -n2
    r = np.linalg.norm(P[inl] - c, axis=1)
    print(f"inliers {ninl}/{len(P)}  centre {np.round(c,4)}  normal {np.round(n2,4)}  "
          f"radius(median) {np.median(r):.4f}  radius(p90) {np.percentile(r,90):.4f}")
    print(f"camera height above plane {np.dot(C - c, n2):.4f}  camera dist {np.linalg.norm(C-c):.4f}")

    # cross-check: average camera up over 6 val views (photos are roughly level)
    ups = []
    for vw in cams["views"][:6]:
        Rv = np.asarray(vw["world_to_camera"])[:3, :3]
        ups.append(Rv.T @ np.array([0.0, -1.0, 0.0]))
    up_cam = np.mean(ups, axis=0)
    up_cam /= np.linalg.norm(up_cam)
    print("camera-up average", np.round(up_cam, 4), "angle to plane normal (deg):",
          round(float(np.degrees(np.arccos(abs(np.dot(up_cam, n2))))), 2))

    out = {"centre": c.tolist(), "normal": n2.tolist(), "radius": float(np.median(r)),
           "radius_p90": float(np.percentile(r, 90)), "camera_up": up_cam.tolist(),
           "camera_centre": C.tolist()}
    (OUT / "table_geometry.json").write_text(json.dumps(out, indent=2))


if __name__ == "__main__":
    main()
