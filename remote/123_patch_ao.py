import io
f = r"D:\Essay\CUHKSZ\AY2627Term1\Image Processing\Asgn2\remote\code\phong_fusion.py"
s = io.open(f, encoding="utf-8").read()
if "--ao_strength" not in s:
    s = s.replace('    p.add_argument("--base_mode", default="percentile", choices=["percentile", "plane"])',
                  '    p.add_argument("--base_mode", default="percentile", choices=["percentile", "plane"])\n'
                  '    p.add_argument("--ao_strength", type=float, default=0.0, help="extra contact AO under the object")\n'
                  '    p.add_argument("--ao_radius", type=float, default=0.16)')
    anchor = '''    atten = 1.0 - args.shadow_strength * np.exp(-0.5 * q) * on_plane'''
    new = '''    atten = 1.0 - args.shadow_strength * np.exp(-0.5 * q) * on_plane
    if args.ao_strength > 0:
        dc0 = sxyz - base_center
        dh0 = dc0 @ up
        dr0 = np.linalg.norm(dc0 - dh0[:, None] * up, axis=1)
        ao = np.exp(-(dr0 ** 2) / (2 * args.ao_radius ** 2)) * (np.abs(sh) < 0.08)
        atten = atten * (1.0 - args.ao_strength * ao)
        print("contact AO: %d Gaussians, min %.2f" % ((ao > 0.01).sum(), atten.min()))'''
    if anchor in s:
        s = s.replace(anchor, new, 1)
        print("AO inserted")
    else:
        print("AO ANCHOR MISSING")
io.open(f, "w", encoding="utf-8", newline="\n").write(s)
import ast; ast.parse(io.open(f, encoding="utf-8").read()); print("syntax ok")