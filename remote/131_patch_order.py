import io
f = r"D:\Essay\CUHKSZ\AY2627Term1\Image Processing\Asgn2\remote\code\build_object_dataset.py"
s = io.open(f, encoding="utf-8").read()
old = '''        bg = np.full_like(rgb, args.bg, dtype=np.uint8)
        comp = np.where((m > 127)[..., None], rgb, bg)
        if args.upscale > 1:
            from PIL import Image as _I
            comp = np.asarray(_I.fromarray(comp).resize(
                (comp.shape[1] * args.upscale, comp.shape[0] * args.upscale), _I.LANCZOS))
        Image.fromarray(comp, "RGB").save(os.path.join(img_out, stem + ".png"))'''
new = '''        if args.upscale > 1:
            from PIL import Image as _I
            W2 = rgb.shape[1] * args.upscale
            H2 = rgb.shape[0] * args.upscale
            rgb = np.asarray(_I.fromarray(rgb).resize((W2, H2), _I.LANCZOS))
            m = np.asarray(_I.fromarray(m).resize((W2, H2), _I.NEAREST))
        bg = np.full_like(rgb, args.bg, dtype=np.uint8)
        comp = np.where((m > 127)[..., None], rgb, bg)
        Image.fromarray(comp, "RGB").save(os.path.join(img_out, stem + ".png"))'''
if old in s:
    s = s.replace(old, new, 1)
    print("composite order fixed")
else:
    print("ORDER ANCHOR MISSING")
io.open(f, "w", encoding="utf-8", newline="\n").write(s)
import ast; ast.parse(io.open(f, encoding="utf-8").read()); print("syntax ok")