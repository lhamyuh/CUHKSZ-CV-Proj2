import io
f = r"D:\Essay\CUHKSZ\AY2627Term1\Image Processing\Asgn2\remote\code\phong_fusion.py"
s = io.open(f, encoding="utf-8").read()
if "clearance_plane" not in s:
    s = s.replace('        ang = float(np.degrees(np.arccos(np.clip(n_base @ up, -1, 1))))',
                  '        clearance_plane = None\n        ang = float(np.degrees(np.arccos(np.clip(n_base @ up, -1, 1))))')
    s = s.replace('            print("rotated object by %.2f deg onto the table" % ang)',
                  '            cQ2 = (cQ - cen) @ Rfix.T + cen\n            clearance_plane = float((cQ2 - table_c) @ up)\n            print("rotated object by %.2f deg onto the table" % ang)')
    old = '''    h = (world - table_c) @ up
    if args.weighted_contact:'''
    new = '''    h = (world - table_c) @ up
    if args.base_mode == "plane" and clearance_plane is not None:
        clearance = clearance_plane
        print("contact from the fitted base plane: %.1f mm" % (clearance * 1000))
    elif args.weighted_contact:'''
    if old in s:
        s = s.replace(old, new, 1)
        print("plane clearance inserted")
    else:
        print("H ANCHOR MISSING")
io.open(f, "w", encoding="utf-8", newline="\n").write(s)
import ast; ast.parse(io.open(f, encoding="utf-8").read()); print("syntax ok")