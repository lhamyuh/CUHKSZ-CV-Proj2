"""Check that release val cameras + COLMAP sparse points use a consistent convention.

Projects the sparse 3D points (COLMAP world frame) into each val reference photo and
writes an overlay. If the dots land on scene structure, world_to_camera + intrinsics
(including the 1/4 stored-resolution scale) are correct.
"""
import json
import struct
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

REL = Path(r"D:\Essay\CUHKSZ\AY2627Term1\Image Processing\Asgn2\Assignment2_release")
OUT = Path(r"D:\Essay\CUHKSZ\AY2627Term1\Image Processing\Asgn2\preview")
OUT.mkdir(exist_ok=True)


def read_points3d_bin(path):
    pts = []
    with open(path, "rb") as f:
        n = struct.unpack("<Q", f.read(8))[0]
        for _ in range(n):
            f.read(8)  # id
            xyz = struct.unpack("<3d", f.read(24))
            f.read(3)  # rgb
            f.read(8)  # error
            track_len = struct.unpack("<Q", f.read(8))[0]
            f.read(8 * track_len)
            pts.append(xyz)
    return np.asarray(pts, dtype=np.float64)


def main():
    pts = read_points3d_bin(REL / "train" / "sparse" / "0" / "points3D.bin")
    print("sparse points:", pts.shape)
    cams = json.loads((REL / "val" / "cameras.json").read_text())
    fx, fy, cx, cy = cams["fx"], cams["fy"], cams["cx"], cams["cy"]
    W, H = cams["width"], cams["height"]
    print(f"intrinsics fx={fx:.2f} fy={fy:.2f} cx={cx} cy={cy} {W}x{H}")

    for view in cams["views"][:3]:
        M = np.asarray(view["world_to_camera"], dtype=np.float64)
        R, t = M[:3, :3], M[:3, 3]
        cam = pts @ R.T + t
        z = cam[:, 2]
        valid = z > 1e-6
        u = fx * cam[valid, 0] / z[valid] + cx
        v = fy * cam[valid, 1] / z[valid] + cy
        inside = (u >= 0) & (u < W) & (v >= 0) & (v < H)
        u, v, zv = u[inside], v[inside], z[valid][inside]
        print(f"{view['name']}: {inside.sum()} points inside image, "
              f"depth {zv.min():.2f}..{zv.max():.2f}")

        img = Image.open(REL / "val" / "reference" / view["name"]).convert("RGB")
        draw = ImageDraw.Draw(img)
        order = np.argsort(-zv)  # far first
        for i in order:
            d = 1.0 - (zv[i] - zv.min()) / (np.ptp(zv) + 1e-9)
            color = (int(255 * d), int(255 * (1 - d)), 80)
            draw.ellipse([u[i] - 1.2, v[i] - 1.2, u[i] + 1.2, v[i] + 1.2], fill=color)
        out = OUT / f"pose_check_{Path(view['name']).stem}.jpg"
        img.save(out, quality=90)
        print("wrote", out)


if __name__ == "__main__":
    main()
