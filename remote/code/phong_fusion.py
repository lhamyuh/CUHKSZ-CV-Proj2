"""Phong-style relighting + directional soft shadow for the inserted object.

Pipeline
  1. ground the object on the fitted table plane (height percentile),
  2. estimate local normals with k-NN PCA,
  3. estimate the scene illuminant from the table Gaussians (ambient level, diffuse range,
     horizontal light direction),
  4. shade the object with ambient + diffuse + specular terms,
  5. project an elliptical shadow on the table along the light direction, multiplicative so the
     wood texture stays visible.

  python code/phong_fusion.py --scene ... --object ... --placement ... \
      --out_scene ... --out_placement ... --view_pos x,y,z
"""
import argparse
import json
import math

import numpy as np
from plyfile import PlyData, PlyElement
from scipy.spatial import cKDTree

C0 = 0.28209479177387814


def rotmat2qvec(R):
    Rxx, Ryx, Rzx, Rxy, Ryy, Rzy, Rxz, Ryz, Rzz = R.flat
    K = np.array([
        [Rxx - Ryy - Rzz, 0, 0, 0],
        [Ryx + Rxy, Ryy - Rxx - Rzz, 0, 0],
        [Rzx + Rxz, Rzy + Ryz, Rzz - Rxx - Ryy, 0],
        [Ryz - Rzy, Rzx - Rxz, Rxy - Ryx, Rxx + Ryy + Rzz]]) / 3.0
    vals, vecs = np.linalg.eigh(K)
    q = vecs[[3, 0, 1, 2], np.argmax(vals)]
    return -q if q[0] < 0 else q


def qmul(a, b):
    w1, x1, y1, z1 = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    w2, x2, y2, z2 = b[..., 0], b[..., 1], b[..., 2], b[..., 3]
    return np.stack([
        w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2,
        w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2,
        w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2,
        w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2], axis=-1)


def estimate_normals(P, k=24):
    tree = cKDTree(P)
    _, idx = tree.query(P, k=k)
    N = np.zeros_like(P)
    for i in range(len(P)):
        nb = P[idx[i]] - P[idx[i]].mean(0)
        w, v = np.linalg.eigh(nb.T @ nb)
        N[i] = v[:, 0]
    c = P.mean(0)
    flip = np.einsum("ij,ij->i", N, P - c) < 0
    N[flip] *= -1
    return N


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--scene", required=True)
    p.add_argument("--object", required=True)
    p.add_argument("--placement", required=True)
    p.add_argument("--out_scene", required=True)
    p.add_argument("--out_placement", required=True)
    p.add_argument("--view_pos", default="", help="camera position used for the specular term")
    p.add_argument("--clearance_pct", type=float, default=10.0)
    p.add_argument("--ka", type=float, default=0.55)
    p.add_argument("--kd", type=float, default=0.55)
    p.add_argument("--ks", type=float, default=0.18)
    p.add_argument("--shininess", type=float, default=28.0)
    p.add_argument("--gain", type=float, default=1.0)
    p.add_argument("--shadow_strength", type=float, default=0.45)
    p.add_argument("--shadow_len", type=float, default=0.22)
    p.add_argument("--shadow_wid", type=float, default=0.12)
    p.add_argument("--shadow_offset", type=float, default=0.55)
    args = p.parse_args()

    pl = json.load(open(args.placement))
    M = np.asarray(pl["object_to_scene"], dtype=np.float64)
    s = float(pl["scale"])
    up = np.asarray(pl["scene_up"], dtype=np.float64)
    up /= np.linalg.norm(up)
    table_c = np.asarray(pl["table_centre"], dtype=np.float64)
    G = M[:3, :3] / s
    t = M[:3, 3]

    ov = PlyData.read(args.object)["vertex"]
    onames = [pr.name for pr in ov.properties]
    od = {n: np.array(ov[n]) for n in onames}
    oxyz = np.stack([od["x"], od["y"], od["z"]], 1).astype(np.float64)
    world = s * (oxyz @ G.T) + t
    h = (world - table_c) @ up
    clearance = float(np.percentile(h, args.clearance_pct))
    t2 = t - clearance * up
    world -= clearance * up
    od["x"], od["y"], od["z"] = world.T
    for i in range(3):
        od[f"scale_{i}"] = od[f"scale_{i}"] + math.log(s)
    qR = rotmat2qvec(G)
    qo = np.stack([od["rot_0"], od["rot_1"], od["rot_2"], od["rot_3"]], 1)
    qn = qmul(np.broadcast_to(qR, qo.shape), qo)
    qn /= np.linalg.norm(qn, axis=1, keepdims=True)
    od["rot_0"], od["rot_1"], od["rot_2"], od["rot_3"] = qn.T
    print(f"grounded by {clearance*1000:.1f} mm")

    sv = PlyData.read(args.scene)["vertex"]
    snames = [pr.name for pr in sv.properties]
    sd = {n: np.array(sv[n]) for n in snames}
    sxyz = np.stack([sd["x"], sd["y"], sd["z"]], 1).astype(np.float64)
    srgb = 0.5 + C0 * np.stack([sd["f_dc_0"], sd["f_dc_1"], sd["f_dc_2"]], 1)

    # ---- illuminant from the table ----
    sh = (sxyz - table_c) @ up
    sr = np.linalg.norm((sxyz - table_c) - sh[:, None] * up, axis=1)
    near = (np.abs(sh) < 0.05) & (sr < 0.75) & (sr > 0.15)
    P = sxyz[near]
    L = srgb[near].mean(1)
    c2 = P[:, :2] - P[:, :2].mean(0)
    A = np.stack([np.ones(len(P)), c2[:, 0], c2[:, 1]], 1)
    coef, *_ = np.linalg.lstsq(A, L, rcond=None)
    gx, gy = coef[1], coef[2]
    gh = np.array([gx, gy])
    gh = gh / (np.linalg.norm(gh) + 1e-9)
    # world horizontal basis comes from the plane normal
    tmp = np.array([1.0, 0.0, 0.0])
    if abs(tmp @ up) > 0.9:
        tmp = np.array([0.0, 1.0, 0.0])
    e1 = np.cross(up, tmp); e1 /= np.linalg.norm(e1)
    e2 = np.cross(up, e1)
    Ldir = gh[0] * e1 + gh[1] * e2
    elev = math.radians(42.0)
    Lvec = math.cos(elev) * Ldir + math.sin(elev) * up
    Lvec /= np.linalg.norm(Lvec)
    amb = float(np.percentile(L, 20))
    diff = float(np.percentile(L, 80) - np.percentile(L, 20))
    amb_rgb = np.percentile(srgb[near], 10, axis=0)
    diff_rgb = np.percentile(srgb[near], 90, axis=0) - amb_rgb
    print("light dir %s  ambient %.3f diffuse %.3f" % (np.round(Lvec, 3), amb, diff))

    # ---- normals + Phong ----
    N = estimate_normals(world)
    V = np.asarray([float(x) for x in args.view_pos.split(",")]) if args.view_pos else world.mean(0)
    Vdir = V - world
    Vdir /= np.linalg.norm(Vdir, axis=1, keepdims=True) + 1e-9
    ndl = np.clip(np.einsum("ij,j->i", N, Lvec), 0, 1)
    Hv = Lvec[None] + Vdir
    Hv /= np.linalg.norm(Hv, axis=1, keepdims=True) + 1e-9
    ndh = np.clip(np.einsum("ij,ij->i", N, Hv), 0, 1)
    shade = args.ka + args.kd * ndl + args.ks * ndh ** args.shininess
    shade = shade / max(float(shade.mean()), 1e-6) * args.gain
    print("shading: min %.2f median %.2f max %.2f" % (shade.min(), np.median(shade), shade.max()))

    orgb = 0.5 + C0 * np.stack([od["f_dc_0"], od["f_dc_1"], od["f_dc_2"]], 1)
    # tint toward the diffuse colour of the table
    tint = diff_rgb / max(diff_rgb.mean(), 1e-6)
    tint = 1.0 + 0.25 * (tint - 1.0)
    for k, c in enumerate(("f_dc_0", "f_dc_1", "f_dc_2")):
        od[c] = ((orgb[:, k] - 0.5) * shade * tint[k]) / C0

    # ---- directional shadow ----
    base_center = np.median(world, axis=0)
    base_center -= ((base_center - table_c) @ up) * up
    Lh = Ldir / (np.linalg.norm(Ldir) + 1e-9)
    Lh = np.cross(up, np.cross(Lh, up))
    Lh /= np.linalg.norm(Lh) + 1e-9
    hh = (world - table_c) @ up
    obj_h = float(np.percentile(hh, 95) - np.percentile(hh, 5))
    centre = base_center - Lh * (args.shadow_offset * max(obj_h, 0.05))
    d = sxyz - centre
    dh = d @ Lh
    dw = d - dh[:, None] * Lh
    dw = dw - (dw @ up)[:, None] * up
    dwn = np.linalg.norm(dw, axis=1)
    q = (dh / args.shadow_len) ** 2 + (dwn / args.shadow_wid) ** 2
    on_plane = np.abs(sh) < 0.06
    atten = 1.0 - args.shadow_strength * np.exp(-0.5 * q) * on_plane
    print("shadow: %d Gaussians, min %.2f" % ((atten < 0.999).sum(), atten.min()))
    for c in ("f_dc_0", "f_dc_1", "f_dc_2"):
        sd[c] = ((0.5 + C0 * sd[c]) * atten - 0.5) / C0

    # ---- write ----
    dtype = [(n, "f4") for n in snames]
    merged = np.empty(len(sd["x"]) + len(od["x"]), dtype=dtype)
    for n in snames:
        merged[n] = np.concatenate([sd[n].astype(np.float32), od[n].astype(np.float32)])
    PlyData([PlyElement.describe(merged, "vertex")]).write(args.out_scene)
    M2 = M.copy(); M2[:3, 3] = t2
    pl["object_to_scene"] = M2.tolist()
    pl["grounding_shift_m"] = float(clearance)
    pl["light_dir"] = Lvec.tolist()
    json.dump(pl, open(args.out_placement, "w"), indent=2)
    print("wrote", args.out_scene, len(merged))


if __name__ == "__main__":
    main()
