"""Minimal COLMAP binary model reader/writer (cameras.bin, images.bin, points3D.bin)."""
import struct

import numpy as np


def read_cameras(path):
    cams = {}
    with open(path, "rb") as f:
        n = struct.unpack("<Q", f.read(8))[0]
        for _ in range(n):
            cid, model, w, h = struct.unpack("<iiQQ", f.read(24))
            k = {0: 3, 1: 4, 2: 4, 3: 5, 4: 8, 5: 9}[model]
            params = list(struct.unpack("<" + "d" * k, f.read(8 * k)))
            cams[cid] = dict(model=model, width=w, height=h, params=params)
    return cams


def write_cameras(path, cams):
    with open(path, "wb") as f:
        f.write(struct.pack("<Q", len(cams)))
        for cid, c in cams.items():
            f.write(struct.pack("<iiQQ", cid, c["model"], c["width"], c["height"]))
            f.write(struct.pack("<" + "d" * len(c["params"]), *c["params"]))


def read_images(path):
    imgs = {}
    with open(path, "rb") as f:
        n = struct.unpack("<Q", f.read(8))[0]
        for _ in range(n):
            iid = struct.unpack("<i", f.read(4))[0]
            q = struct.unpack("<4d", f.read(32))
            t = struct.unpack("<3d", f.read(24))
            cid = struct.unpack("<i", f.read(4))[0]
            name = b""
            while True:
                ch = f.read(1)
                if ch == b"\x00":
                    break
                name += ch
            npts = struct.unpack("<Q", f.read(8))[0]
            pts = [struct.unpack("<ddq", f.read(24)) for _ in range(npts)]
            imgs[iid] = dict(q=q, t=t, camera_id=cid, name=name.decode(), points2D=pts)
    return imgs


def write_images(path, imgs):
    with open(path, "wb") as f:
        f.write(struct.pack("<Q", len(imgs)))
        for iid, im in imgs.items():
            f.write(struct.pack("<i", iid))
            f.write(struct.pack("<4d", *im["q"]))
            f.write(struct.pack("<3d", *im["t"]))
            f.write(struct.pack("<i", im["camera_id"]))
            f.write(im["name"].encode() + b"\x00")
            f.write(struct.pack("<Q", len(im["points2D"])))
            for p in im["points2D"]:
                f.write(struct.pack("<ddq", *p))


def read_points3d(path):
    pts = {}
    with open(path, "rb") as f:
        n = struct.unpack("<Q", f.read(8))[0]
        for _ in range(n):
            pid = struct.unpack("<Q", f.read(8))[0]
            xyz = struct.unpack("<3d", f.read(24))
            rgb = struct.unpack("<3B", f.read(3))
            err = struct.unpack("<d", f.read(8))[0]
            nt = struct.unpack("<Q", f.read(8))[0]
            track = [struct.unpack("<ii", f.read(8)) for _ in range(nt)]
            pts[pid] = dict(xyz=xyz, rgb=rgb, err=err, track=track)
    return pts


def write_points3d(path, pts):
    with open(path, "wb") as f:
        f.write(struct.pack("<Q", len(pts)))
        for pid, p in pts.items():
            f.write(struct.pack("<Q", pid))
            f.write(struct.pack("<3d", *p["xyz"]))
            f.write(struct.pack("<3B", *p["rgb"]))
            f.write(struct.pack("<d", p["err"]))
            f.write(struct.pack("<Q", len(p["track"])))
            for a, b in p["track"]:
                f.write(struct.pack("<ii", a, b))


def qvec2rotmat(q):
    w, x, y, z = q
    return np.array([
        [1 - 2 * y * y - 2 * z * z, 2 * x * y - 2 * z * w, 2 * x * z + 2 * y * w],
        [2 * x * y + 2 * z * w, 1 - 2 * x * x - 2 * z * z, 2 * y * z - 2 * x * w],
        [2 * x * z - 2 * y * w, 2 * y * z + 2 * x * w, 1 - 2 * x * x - 2 * y * y],
    ])


def rotmat2qvec(R):
    Rxx, Ryx, Rzx, Rxy, Ryy, Rzy, Rxz, Ryz, Rzz = R.flat
    K = np.array([
        [Rxx - Ryy - Rzz, 0, 0, 0],
        [Ryx + Rxy, Ryy - Rxx - Rzz, 0, 0],
        [Rzx + Rxz, Rzy + Ryz, Rzz - Rxx - Ryy, 0],
        [Ryz - Rzy, Rzx - Rxz, Rxy - Ryx, Rxx + Ryy + Rzz]]) / 3.0
    vals, vecs = np.linalg.eigh(K)
    qvec = vecs[[3, 0, 1, 2], np.argmax(vals)]
    if qvec[0] < 0:
        qvec = -qvec
    return qvec
