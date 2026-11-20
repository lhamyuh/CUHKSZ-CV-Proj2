import io
f = r"D:\Essay\CUHKSZ\AY2627Term1\Image Processing\Asgn2\remote\code\build_object_dataset.py"
s = io.open(f, encoding="utf-8").read()
if "--upscale" not in s:
    s = s.replace('    p.add_argument("--dilate", type=int, default=0, help="dilate masks by N pixels before use")',
                  '    p.add_argument("--dilate", type=int, default=0, help="dilate masks by N pixels before use")\n'
                  '    p.add_argument("--upscale", type=int, default=1, help="resize images (and intrinsics) by this factor")')
    old = '''        bg = np.full_like(rgb, args.bg, dtype=np.uint8)
        comp = np.where((m > 127)[..., None], rgb, bg)
        Image.fromarray(comp, "RGB").save(os.path.join(img_out, stem + ".png"))'''
    new = '''        bg = np.full_like(rgb, args.bg, dtype=np.uint8)
        comp = np.where((m > 127)[..., None], rgb, bg)
        if args.upscale > 1:
            from PIL import Image as _I
            comp = np.asarray(_I.fromarray(comp).resize(
                (comp.shape[1] * args.upscale, comp.shape[0] * args.upscale), _I.LANCZOS))
        Image.fromarray(comp, "RGB").save(os.path.join(img_out, stem + ".png"))'''
    if old in s:
        s = s.replace(old, new, 1)
        print("upscale insert ok")
    else:
        print("IMAGE ANCHOR MISSING")
    old2 = '''    write_cameras(os.path.join(sp, "cameras.bin"), cams)'''
    new2 = '''    if args.upscale > 1:
        for cid, c in cams.items():
            c["width"] *= args.upscale
            c["height"] *= args.upscale
            c["params"] = [p * args.upscale for p in c["params"]]
    write_cameras(os.path.join(sp, "cameras.bin"), cams)'''
    if old2 in s:
        s = s.replace(old2, new2, 1)
        print("camera scale ok")
    else:
        print("CAM ANCHOR MISSING")
io.open(f, "w", encoding="utf-8", newline="\n").write(s)
import ast; ast.parse(io.open(f, encoding="utf-8").read()); print("syntax ok")