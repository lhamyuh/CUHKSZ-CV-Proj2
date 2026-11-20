import io
f = r"D:\Essay\CUHKSZ\AY2627Term1\Image Processing\Asgn2\remote\code\prune_object.py"
s = io.open(f, encoding="utf-8").read()
old = '''        ui = np.clip(u, 0, W - 1).astype(int)
        wi = np.clip(w, 0, H - 1).astype(int)
        inside = ok & (u >= 0) & (u < W) & (w >= 0) & (w < H) & m[wi, ui]'''
new = '''        mh, mw = m.shape[0], m.shape[1]
        su = mw / float(W)
        sv = mh / float(H)
        ui = np.clip(u * su, 0, mw - 1).astype(int)
        wi = np.clip(w * sv, 0, mh - 1).astype(int)
        inside = ok & (u >= 0) & (u < W) & (w >= 0) & (w < H) & m[wi, ui]'''
if old in s:
    s = s.replace(old, new, 1)
    print("prune mask scale patched")
else:
    print("PRUNE ANCHOR MISSING")
io.open(f, "w", encoding="utf-8", newline="\n").write(s)
import ast; ast.parse(io.open(f, encoding="utf-8").read()); print("syntax ok")