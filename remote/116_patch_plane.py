import io
f = r"D:\Essay\CUHKSZ\AY2627Term1\Image Processing\Asgn2\remote\code\phong_fusion.py"
s = io.open(f, encoding="utf-8").read()
if "--base_mode" not in s:
    s = s.replace('    p.add_argument("--deglare", type=float, default=0.0, help="cap object RGB at this value (kills white glare)")',
                  '    p.add_argument("--deglare", type=float, default=0.0, help="cap object RGB at this value (kills white glare)")\n'
                  '    p.add_argument("--base_mode", default="percentile", choices=["percentile", "plane"])')
old = '''    if args.base_align:
        hh0 = (world - table_c) @ up
        low = hh0 < np.percentile(hh0, 25)
        Q = world[low]
        cQ = Q.mean(0)
        _, _, vt = np.linalg.svd(Q - cQ)
        n_base = vt[2]'''
new = '''    if args.base_align:
        if args.base_mode == "plane":
            rng = np.random.default_rng(0)
            best = (0, None)
            for _ in range(600):
                idx = rng.choice(len(world), 3, replace=False)
                a, b, c = world[idx]
                n = np.cross(b - a, c - a)
                nn = np.linalg.norm(n)
                if nn < 1e-9:
                    continue
                n = n / nn
                cnt = int((np.abs((world - a) @ n) < 0.012).sum())
                if cnt > best[0]:
                    best = (cnt, n)
            n_base = best[1]
            print("largest planar face: %d inliers" % best[0])
        else:
            hh0 = (world - table_c) @ up
            low = hh0 < np.percentile(hh0, 25)
            Q = world[low]
            cQ = Q.mean(0)
            _, _, vt = np.linalg.svd(Q - cQ)
            n_base = vt[2]'''
if old in s:
    s = s.replace(old, new, 1)
    print("plane mode inserted")
else:
    print("ALIGN ANCHOR MISSING")
io.open(f, "w", encoding="utf-8", newline="\n").write(s)
import ast; ast.parse(io.open(f, encoding="utf-8").read()); print("syntax ok")