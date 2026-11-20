"""Merge the object gaussians into the Garden scene with a similarity transform.

placement.json: {"object_to_scene": 4x4 (column vectors), "scale": s}
  p_scene = s * R @ p_obj + t,  and gaussian log-scales += log(s), rotations q_R * q_obj.
"""
import argparse
import json
import math

import numpy as np
from plyfile import PlyData, PlyElement


def load(path):
    v = PlyData.read(path)["vertex"]
    names = [p.name for p in v.properties]
    return {n: np.array(v[n]) for n in names}, names


def rotmat2qvec(R):
    Rxx, Ryx, Rzx, Rxy, Ryy, Rzy, Rxz, Ryz, Rzz = R.flat
    K = np.array([
        [Rxx - Ryy - Rzz, 0, 0, 0],
        [Ryx + Rxy, Ryy - Rxx - Rzz, 0, 0],
        [Rzx + Rxz, Rzy + Ryz, Rzz - Rxx - Ryy, 0],
        [Ryz - Rzy, Rzx - Rxz, Rxy - Ryx, Rxx + Ryy + Rzz]]) / 3.0
    vals, vecs = np.linalg.eigh(K)
    q = vecs[[3, 0, 1, 2], np.argmax(vals)]
    if q[0] < 0:
        q = -q
    return q  # w, x, y, z


def qmul(a, b):
    w1, x1, y1, z1 = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    w2, x2, y2, z2 = b[..., 0], b[..., 1], b[..., 2], b[..., 3]
    return np.stack([
        w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2,
        w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2,
        w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2,
        w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2], axis=-1)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--scene", required=True)
    p.add_argument("--object", required=True)
    p.add_argument("--placement", required=True)
    p.add_argument("--out", required=True)
    args = p.parse_args()

    pl = json.load(open(args.placement))
    M = np.asarray(pl["object_to_scene"], dtype=np.float64)
    s = float(pl.get("scale", 1.0))
    R = M[:3, :3] / s
    t = M[:3, 3]

    sc, s_names = load(args.scene)
    ob, o_names = load(args.object)
    need = ["x", "y", "z", "opacity", "scale_0", "scale_1", "scale_2",
            "rot_0", "rot_1", "rot_2", "rot_3"]
    fdc = [n for n in s_names if n.startswith("f_dc_")]
    frest = [n for n in s_names if n.startswith("f_rest_")]
    core = need + fdc + frest
    for n in core:
        assert n in s_names, f"scene missing {n}"
        assert n in o_names, f"object missing {n}"
    # keep any extra scene fields (e.g. normals); fill object side with zeros
    extras = [n for n in s_names if n not in core]
    for n in extras:
        ob[n] = np.zeros(len(ob["x"]), dtype=np.float32)
    s_names = core + extras

    xyz = np.stack([ob["x"], ob["y"], ob["z"]], 1)
    ob["x"], ob["y"], ob["z"] = (s * (xyz @ R.T) + t).T

    for i in range(3):
        ob[f"scale_{i}"] = ob[f"scale_{i}"] + math.log(s)

    qR = rotmat2qvec(R)
    qo = np.stack([ob["rot_0"], ob["rot_1"], ob["rot_2"], ob["rot_3"]], 1)
    qn = qmul(np.broadcast_to(qR, qo.shape), qo)
    qn /= np.linalg.norm(qn, axis=1, keepdims=True)
    ob["rot_0"], ob["rot_1"], ob["rot_2"], ob["rot_3"] = qn.T

    dtype = [(n, "f4") for n in s_names]
    merged = np.empty(len(sc["x"]) + len(ob["x"]), dtype=dtype)
    for n in s_names:
        merged[n] = np.concatenate([sc[n].astype(np.float32), ob[n].astype(np.float32)])
    el = PlyElement.describe(merged, "vertex")
    PlyData([el]).write(args.out)
    print(f"merged {len(sc['x'])} + {len(ob['x'])} = {len(merged)} gaussians -> {args.out}")


if __name__ == "__main__":
    main()
