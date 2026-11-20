import io
f = r"D:\Essay\CUHKSZ\AY2627Term1\Image Processing\Asgn2\remote\code\phong_fusion.py"
s = io.open(f, encoding="utf-8").read()
if "--disc_dark" not in s:
    s = s.replace('    p.add_argument("--sink", type=float, default=0.0, help="push the object this far into the table (metres)")',
                  '    p.add_argument("--sink", type=float, default=0.0, help="push the object this far into the table (metres)")\n'
                  '    p.add_argument("--disc_dark", type=float, default=0.0, help=">0 adds a footprint disc at this brightness factor")\n'
                  '    p.add_argument("--disc_scale", type=float, default=1.05)')
    anchor = '''    # ---- write ----
    dtype = [(n, "f4") for n in snames]'''
    new = '''    # ---- footprint disc (hides the unobserved underside, reads as contact) ----
    extra = {n: np.zeros(0, dtype=np.float32) for n in snames}
    if args.disc_dark > 0:
        n_d = 4000
        for _k in snames:
            extra[_k] = np.zeros(n_d, dtype=np.float32)
        foot = np.linalg.norm((world - table_c) - ((world - table_c) @ up)[:, None] * up, axis=1)
        low = ((world - table_c) @ up) < np.percentile((world - table_c) @ up, 20)
        R_f = float(np.percentile(foot[low], 90)) * args.disc_scale if low.sum() > 10 else 0.08
        base_c = np.median(world[low], axis=0)
        base_c = base_c - ((base_c - table_c) @ up) * up + 0.001 * up
        rng = np.random.default_rng(0)
        rr = R_f * np.sqrt(rng.random(n_d))
        th = rng.uniform(0, 2 * np.pi, n_d)
        tmp = np.array([1.0, 0.0, 0.0])
        if abs(tmp @ up) > 0.9:
            tmp = np.array([0.0, 1.0, 0.0])
        e1 = np.cross(up, tmp); e1 /= np.linalg.norm(e1)
        e2 = np.cross(up, e1)
        pos = base_c + rr[:, None] * (np.cos(th)[:, None] * e1 + np.sin(th)[:, None] * e2)
        extra["x"], extra["y"], extra["z"] = pos.T
        for i in range(3):
            extra[f"scale_{i}"] = np.full(n_d, np.log(0.010 if i < 2 else 0.0012), dtype=np.float32)
        extra["rot_0"] = np.ones(n_d, dtype=np.float32)
        extra["opacity"] = np.full(n_d, 1.1, dtype=np.float32)
        dark = ref_rgb * args.disc_dark
        for k, c in enumerate(("f_dc_0", "f_dc_1", "f_dc_2")):
            extra[c] = np.full(n_d, (dark[k] - 0.5) / C0, dtype=np.float32)
        print("footprint disc: %d gaussians, R %.3f, brightness %.2f" % (n_d, R_f, args.disc_dark))

    # ---- write ----
    dtype = [(n, "f4") for n in snames]'''
    if anchor in s:
        s = s.replace(anchor, new, 1)
        s = s.replace('    merged = np.empty(len(sd["x"]) + len(od["x"]), dtype=dtype)\n    for n in snames:\n        merged[n] = np.concatenate([sd[n].astype(np.float32), od[n].astype(np.float32)])',
                      '    merged = np.empty(len(sd["x"]) + len(od["x"]) + len(extra["x"]), dtype=dtype)\n    for n in snames:\n        merged[n] = np.concatenate([sd[n].astype(np.float32), od[n].astype(np.float32), extra[n]])')
        print("disc inserted")
    else:
        print("DISC ANCHOR MISSING")
io.open(f, "w", encoding="utf-8", newline="\n").write(s)
import ast; ast.parse(io.open(f, encoding="utf-8").read()); print("syntax ok")