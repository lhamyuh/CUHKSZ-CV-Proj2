import io
f = r"D:\Essay\CUHKSZ\AY2627Term1\Image Processing\Asgn2\remote\code\phong_fusion.py"
s = io.open(f, encoding="utf-8").read()
old = '''            n_base = best[1]
            print("largest planar face: %d inliers" % best[0])'''
new = '''            n_base = best[1]
            c0 = world.mean(0)
            inl = np.abs((world - c0) @ n_base) < 0.012
            cQ = world[inl].mean(0) if inl.sum() > 10 else c0
            print("largest planar face: %d inliers" % best[0])'''
if old in s:
    s = s.replace(old, new, 1)
    print("cQ fix inserted")
else:
    print("CQ ANCHOR MISSING")
io.open(f, "w", encoding="utf-8", newline="\n").write(s)
import ast; ast.parse(io.open(f, encoding="utf-8").read()); print("syntax ok")