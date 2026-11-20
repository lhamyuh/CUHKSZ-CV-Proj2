import io
f = r"D:\Essay\CUHKSZ\AY2627Term1\Image Processing\Asgn2\remote\code\phong_fusion.py"
s = io.open(f, encoding="utf-8").read()
old = '''        foot = np.linalg.norm((world - table_c) - ((world - table_c) @ up)[:, None] * up, axis=1)
        low = ((world - table_c) @ up) < np.percentile((world - table_c) @ up, 20)
        R_f = float(np.percentile(foot[low], 90)) * args.disc_scale if low.sum() > 10 else 0.08
        base_c = np.median(world[low], axis=0)
        base_c = base_c - ((base_c - table_c) @ up) * up + 0.001 * up'''
new = '''        hh = (world - table_c) @ up
        low = hh < np.percentile(hh, 20)
        base_c = np.median(world[low], axis=0) if low.sum() > 10 else world.mean(0)
        off = (world - base_c)
        off = off - (off @ up)[:, None] * up
        foot = np.linalg.norm(off, axis=1)
        R_f = float(np.percentile(foot[low], 90)) * args.disc_scale if low.sum() > 10 else 0.08
        base_c = base_c - ((base_c - table_c) @ up) * up + 0.001 * up'''
if old in s:
    s = s.replace(old, new, 1)
    print("disc radius fixed")
else:
    print("DISC RADIUS ANCHOR MISSING")
io.open(f, "w", encoding="utf-8", newline="\n").write(s)
import ast; ast.parse(io.open(f, encoding="utf-8").read()); print("syntax ok")