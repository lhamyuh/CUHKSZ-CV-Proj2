import io
f = r"D:\Essay\CUHKSZ\AY2627Term1\Image Processing\Asgn2\remote\code\phong_fusion.py"
s = io.open(f, encoding="utf-8").read()
if "--sink" not in s:
    s = s.replace('    p.add_argument("--ao_radius", type=float, default=0.16)',
                  '    p.add_argument("--ao_radius", type=float, default=0.16)\n'
                  '    p.add_argument("--sink", type=float, default=0.0, help="push the object this far into the table (metres)")')
    s = s.replace('    t2 = t - clearance * up',
                  '    t2 = t - (clearance + args.sink) * up')
    s = s.replace('    world -= clearance * up',
                  '    world -= (clearance + args.sink) * up')
io.open(f, "w", encoding="utf-8", newline="\n").write(s)
import ast; ast.parse(io.open(f, encoding="utf-8").read()); print("sink ok")