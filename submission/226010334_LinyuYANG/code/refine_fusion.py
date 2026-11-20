"""Ground the object on the table, match illumination, add a contact shadow.

Fixes measured on the first fusion:
  * clearance below the object (47.7 mm) -> shift down until the base percentile touches
  * ring-shaped contact shadow instead of a barely visible tint
  * object illumination: vertical AO gradient + warm tint toward the table, gain from the
    table's p60 luminance

This performs the *full* similarity transform (positions, log-scales, quaternions) and
rewrites placement.json so the reported matrix matches the rendered geometry.
"""
import argparse
import json
import math

import numpy as np
from plyfile import PlyData, PlyElement

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


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--scene", required=True)
    p.add_argument("--object", required=True)
    p.add_argument("--placement", required=True)
    p.add_argument("--out_scene", required=True)
    p.add_argument("--out_placement", required=True)
    p.add_argument("--clearance_pct", type=float, default=3.0)
    p.add_argument("--shadow_sigma", type=float, default=0.10)
    p.add_argument("--shadow_strength", type=float, default=0.55)
    p.add_argument("--object_gain", type=float, default=1.0,
                   help="multiplier on the estimated illumination gain")
    p.add_argument("--base_disc", type=int, default=3000,
                   help="number of contact Gaussians added under the object (0 disables)")
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
    print("height mm: min %.1f p1 %.1f p3 %.1f p5 %.1f -> contact %.1f"
          % (h.min() * 1e3, np.percentile(h, 1) * 1e3, np.percentile(h, 3) * 1e3,
             np.percentile(h, 5) * 1e3, clearance * 1e3))
    t2 = t - clearance * up
    world = world - clearance * up

    # ---- transform the object gaussians ----
    od["x"], od["y"], od["z"] = world.T
    for i in range(3):
        od[f"scale_{i}"] = od[f"scale_{i}"] + math.log(s)
    qR = rotmat2qvec(G)
    qo = np.stack([od["rot_0"], od["rot_1"], od["rot_2"], od["rot_3"]], 1)
    qn = qmul(np.broadcast_to(qR, qo.shape), qo)
    qn /= np.linalg.norm(qn, axis=1, keepdims=True)
    od["rot_0"], od["rot_1"], od["rot_2"], od["rot_3"] = qn.T

    # ---- scene reference ----
    sv = PlyData.read(args.scene)["vertex"]
    snames = [pr.name for pr in sv.properties]
    sd = {n: np.array(sv[n]) for n in snames}
    sxyz = np.stack([sd["x"], sd["y"], sd["z"]], 1).astype(np.float64)
    srgb = 0.5 + C0 * np.stack([sd["f_dc_0"], sd["f_dc_1"], sd["f_dc_2"]], 1)
    slum = srgb.mean(1)
    sh = (sxyz - table_c) @ up
    sr = np.linalg.norm((sxyz - table_c) - sh[:, None] * up, axis=1)
    near = (np.abs(sh) < 0.05) & (sr < 0.60) & (sr > 0.12)
    ref_lum = float(np.percentile(slum[near], 60))
    ref_rgb = srgb[near].mean(0)
    print("table near object: n=%d p60 lum %.3f RGB %s" % (near.sum(), ref_lum, np.round(ref_rgb, 3)))

    # ---- object illumination ----
    orgb = 0.5 + C0 * np.stack([od["f_dc_0"], od["f_dc_1"], od["f_dc_2"]], 1)
    cur = float(np.percentile(orgb.mean(1), 75))
    gain = float(np.clip(0.92 * ref_lum / max(cur, 1e-3), 0.8, 2.2)) * args.object_gain
    hrel = (world - table_c) @ up
    hrel = (hrel - hrel.min()) / (np.ptp(hrel) + 1e-9)
    ao = 0.80 + 0.32 * hrel
    tint = ref_rgb / max(ref_rgb.mean(), 1e-6)
    tint = 1.0 + 0.30 * (tint - 1.0)
    fac = gain * ao
    print("object p75 lum %.3f -> %.3f (gain %.2f), tint %s" % (cur, cur * gain, gain, np.round(tint, 3)))
    for k, c in enumerate(("f_dc_0", "f_dc_1", "f_dc_2")):
        od[c] = ((orgb[:, k] - 0.5) / C0) * fac * tint[k]

    # ---- contact shadow on the table ----
    o_c = world.mean(0)
    dxy = np.linalg.norm((sxyz - o_c) - ((sxyz - o_c) @ up)[:, None] * up, axis=1)
    on_plane = np.abs(sh) < 0.05
    w = np.exp(-(dxy ** 2) / (2 * args.shadow_sigma ** 2)) * on_plane
    shade = 1.0 - args.shadow_strength * w
    print("contact shadow: %d Gaussians, min %.3f" % ((shade < 0.999).sum(), shade.min()))
    for c in ("f_dc_0", "f_dc_1", "f_dc_2"):
        arr = 0.5 + C0 * sd[c]
        sd[c] = ((np.where(shade < 0.999, arr * shade, arr)) - 0.5) / C0

    # ---- contact disc: fills the unseen underside and anchors the object ----
    extra = {n: np.zeros(0, dtype=np.float32) for n in snames}
    if args.base_disc > 0:
        for _k in snames:
            extra[_k] = np.zeros(int(args.base_disc), dtype=np.float32)
        foot = np.linalg.norm((world - o_c) - ((world - o_c) @ up)[:, None] * up, axis=1)
        base_h = (world - table_c) @ up
        low = base_h < np.percentile(base_h, 15)
        R_foot = float(np.percentile(foot[low], 85)) if low.sum() > 10 else 0.09
        tmp = np.array([1.0, 0.0, 0.0])
        if abs(tmp @ up) > 0.9:
            tmp = np.array([0.0, 1.0, 0.0])
        e1 = np.cross(up, tmp); e1 /= np.linalg.norm(e1)
        e2 = np.cross(up, e1)
        n = int(args.base_disc)
        r = R_foot * np.sqrt(np.random.default_rng(0).random(n))
        th = np.random.default_rng(1).uniform(0, 2 * np.pi, n)
        base_center = np.median(world[low], axis=0) if low.sum() > 10 else o_c
        pos = (base_center - ((base_center - table_c) @ up) * up) + 0.002 * up
        pos = pos + r[:, None] * (np.cos(th)[:, None] * e1 + np.sin(th)[:, None] * e2)
        qR_disc = rotmat2qvec(np.stack([e1, np.cross(up, e1), up], axis=1))
        extra["x"], extra["y"], extra["z"] = pos.T
        for i in range(3):
            extra[f"scale_{i}"] = np.full(n, np.log(0.011 if i < 2 else 0.0015), dtype=np.float32)
        for i in range(3):
            extra[f"rot_{i}"] = np.zeros(n, dtype=np.float32)
        extra["rot_0"] = np.zeros(n); extra["rot_1"] = np.full(n, 0.0)
        # identity rotation aligned with world z is enough: scale is nearly isotropic
        extra["rot_0"] = np.full(n, 1.0, dtype=np.float32)
        extra["opacity"] = np.full(n, 0.9, dtype=np.float32)   # sigmoid ~0.71
        dark = (ref_rgb * 0.55 + 0.02)
        for k, c in enumerate(("f_dc_0", "f_dc_1", "f_dc_2")):
            extra[c] = np.full(n, (dark[k] - 0.5) / C0, dtype=np.float32)
        print("base disc: %d Gaussians, R_foot %.3f" % (n, R_foot))

    # ---- write ----
    dtype = [(n, "f4") for n in snames]
    merged = np.empty(len(sd["x"]) + len(od["x"]) + len(extra["x"]), dtype=dtype)
    for n in snames:
        merged[n] = np.concatenate([sd[n].astype(np.float32), od[n].astype(np.float32), extra[n]])
    PlyData([PlyElement.describe(merged, "vertex")]).write(args.out_scene)

    M2 = M.copy()
    M2[:3, 3] = t2
    pl["object_to_scene"] = M2.tolist()
    pl["grounding_shift_m"] = float(clearance)
    pl["contact_percentile"] = args.clearance_pct
    json.dump(pl, open(args.out_placement, "w"), indent=2)
    print("wrote", args.out_scene, len(merged))


if __name__ == "__main__":
    main()
