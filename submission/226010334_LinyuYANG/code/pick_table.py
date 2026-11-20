"""Pick 3D points from the COLMAP sparse cloud nearest to given pixels of a val view.

Used to measure the Garden table (rim, centre, plane normal) in scene units.
"""
import json
import struct
from pathlib import Path

import numpy as np

REL = Path(r"D:\Essay\CUHKSZ\AY2627Term1\Image Processing\Asgn2\Assignment2_release")


def read_points3d(path):
    pts = []
    with open(path, "rb") as f:
        n = struct.unpack("<Q", f.read(8))[0]
        for _ in range(n):
            f.read(8)
            xyz = struct.unpack("<3d", f.read(24))
            f.read(3)
            f.read(8)
            track_len = struct.unpack("<Q", f.read(8))[0]
            f.read(8 * track_len)
            pts.append(xyz)
    return np.asarray(pts)


def main(view_name="DSC07956.JPG", clicks=((452, 408), (988, 402), (648, 458))):
    pts = read_points3d(REL / "train" / "sparse" / "0" / "points3D.bin")
    cams = json.loads((REL / "val" / "cameras.json").read_text())
    view = next(v for v in cams["views"] if v["name"] == view_name)
    M = np.asarray(view["world_to_camera"])
    R, t = M[:3, :3], M[:3, 3]
    fx, fy, cx, cy = cams["fx"], cams["fy"], cams["cx"], cams["cy"]
    cam = pts @ R.T + t
    z = cam[:, 2]
    ok = z > 0.1
    u = np.full(len(pts), -1e9)
    v = np.full(len(pts), -1e9)
    u[ok] = fx * cam[ok, 0] / z[ok] + cx
    v[ok] = fy * cam[ok, 1] / z[ok] + cy

    picked = []
    for (px, py) in clicks:
        d = np.hypot(u - px, v - py)
        i = int(np.argmin(d))
        picked.append(pts[i])
        print(f"click ({px},{py}) -> point #{i} 3D={np.round(pts[i], 4)} pixel_dist={d[i]:.2f} depth={z[i]:.3f}")
    P = np.stack(picked)

    # circumcentre of the triangle (table rim points)
    a, b, c = P
    ab, ac = b - a, c - a
    n = np.cross(ab, ac)
    n /= np.linalg.norm(n)
    # circumcentre (analytic)
    u = np.cross(ab, ac)
    centre = a + (np.dot(ab, ab) * np.cross(ac, u) + np.dot(ac, ac) * np.cross(u, ab)) / (2.0 * np.dot(u, u))
    radius = np.linalg.norm(a - centre)
    print("plane normal", np.round(n, 4), "centre", np.round(centre, 4), "radius", round(float(radius), 4))
    print("side lengths", [round(float(np.linalg.norm(x - y)), 4) for x, y in ((a, b), (b, c), (c, a))])

    # camera centre and height above plane
    C = -R.T @ t
    print("camera centre", np.round(C, 4), "height above table plane", round(float((C - centre) @ n), 4))
    # table diameter vs camera distance
    print("camera distance to centre", round(float(np.linalg.norm(C - centre)), 4))

    out = {"centre": centre.tolist(), "normal": n.tolist(), "radius": float(radius),
           "camera_centre": C.tolist()}
    (REL.parent / "preview" / "table_geometry.json").write_text(json.dumps(out, indent=2))


if __name__ == "__main__":
    main()
