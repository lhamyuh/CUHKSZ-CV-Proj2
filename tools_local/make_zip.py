import os, sys, zipfile
base = r"D:\Essay\CUHKSZ\AY2627Term1\Image Processing\Asgn2\submission"
name = "226010334_LinyuYANG"
root = os.path.join(base, name)
out = os.path.join(base, name + ".zip")
if os.path.exists(out):
    os.remove(out)
n = 0
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for dp, dn, fn in os.walk(root):
        for f in sorted(fn):
            p = os.path.join(dp, f)
            arc = os.path.relpath(p, base).replace("\\", "/")
            z.write(p, arc)
            n += 1
print("wrote", out, n, "files", round(os.path.getsize(out) / 1e6, 1), "MB")
with zipfile.ZipFile(out) as z:
    names = z.namelist()
print("sample:", names[:4])
print("renders:", sum(1 for x in names if x.startswith(name + "/renders/") and x.endswith(".png")))
print("all forward slashes:", all("\\" not in x for x in names))