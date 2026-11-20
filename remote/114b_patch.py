import io
f = r"D:\Essay\CUHKSZ\AY2627Term1\Image Processing\Asgn2\remote\code\phong_fusion.py"
s = io.open(f, encoding="utf-8").read()
if "--deglare" not in s:
    s = s.replace('    p.add_argument("--base_align", type=int, default=1)',
                  '    p.add_argument("--base_align", type=int, default=1)\n'
                  '    p.add_argument("--deglare", type=float, default=0.0, help="cap object RGB at this value (kills white glare)")')
anchor = '    orgb = 0.5 + C0 * np.stack([od["f_dc_0"], od["f_dc_1"], od["f_dc_2"]], 1)'
if anchor in s and 'deglare' not in s.split('anchor')[0]:
    pass
old_write = '''    for k, c in enumerate(("f_dc_0", "f_dc_1", "f_dc_2")):
        od[c] = ((orgb[:, k] - 0.5) * shade * tint[k]) / C0'''
new_write = '''    if args.deglare > 0:
        orgb = np.minimum(orgb, args.deglare)
    for k, c in enumerate(("f_dc_0", "f_dc_1", "f_dc_2")):
        od[c] = ((orgb[:, k] - 0.5) * shade * tint[k]) / C0'''
if old_write in s:
    s = s.replace(old_write, new_write, 1)
    print("deglare inserted")
else:
    print("WRITE ANCHOR MISSING")
io.open(f, "w", encoding="utf-8", newline="\n").write(s)
import ast; ast.parse(io.open(f, encoding="utf-8").read()); print("syntax ok")