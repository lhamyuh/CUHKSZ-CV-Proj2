import io
f = r"D:\Essay\CUHKSZ\AY2627Term1\Image Processing\Asgn2\remote\code\phong_fusion.py"
s = io.open(f, encoding="utf-8").read()
if "--base_align" not in s:
    s = s.replace(
        '    p.add_argument("--weighted_contact", type=int, default=1,',
        '    p.add_argument("--base_align", type=int, default=1)\n'
        '    p.add_argument("--weighted_contact", type=int, default=1,')
anchor = "    h = (world - table_c) @ up\n    if args.weighted_contact:"
block = '''    if args.base_align:
        hh0 = (world - table_c) @ up
        low = hh0 < np.percentile(hh0, 25)
        Q = world[low]
        cQ = Q.mean(0)
        _, _, vt = np.linalg.svd(Q - cQ)
        n_base = vt[2]
        if n_base @ up < 0:
            n_base = -n_base
        ang = float(np.degrees(np.arccos(np.clip(n_base @ up, -1, 1))))
        print("base normal %s, %.2f deg from table normal" % (np.round(n_base, 3), ang))
        if ang > 1.0:
            axis = np.cross(n_base, up)
            axis /= np.linalg.norm(axis) + 1e-9
            K = np.array([[0, -axis[2], axis[1]], [axis[2], 0, -axis[0]], [-axis[1], axis[0], 0]])
            Rfix = np.eye(3) + np.sin(np.radians(ang)) * K + (1 - np.cos(np.radians(ang))) * (K @ K)
            cen = world.mean(0)
            world = (world - cen) @ Rfix.T + cen
            G = Rfix @ G
            od["x"], od["y"], od["z"] = world.T
            qF = rotmat2qvec(Rfix)
            qo2 = np.stack([od["rot_0"], od["rot_1"], od["rot_2"], od["rot_3"]], 1)
            q2 = qmul(np.broadcast_to(qF, qo2.shape), qo2)
            q2 /= np.linalg.norm(q2, axis=1, keepdims=True)
            od["rot_0"], od["rot_1"], od["rot_2"], od["rot_3"] = q2.T
            print("rotated object by %.2f deg onto the table" % ang)
''' + anchor
if anchor in s:
    s = s.replace(anchor, block, 1)
    print("patched base align")
else:
    print("ANCHOR MISSING")
io.open(f, "w", encoding="utf-8", newline="\n").write(s)
import ast
ast.parse(io.open(f, encoding="utf-8").read())
print("syntax ok")