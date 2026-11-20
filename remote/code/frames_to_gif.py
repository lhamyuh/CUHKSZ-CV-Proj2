"""JPEG frames -> looping GIF (downscaled), for evidence/orbit.gif."""
import argparse
import glob
import os

from PIL import Image


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--frames", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--size", type=int, default=480)
    p.add_argument("--fps", type=float, default=20)
    p.add_argument("--pattern", default="*.png")
    args = p.parse_args()
    files = sorted(glob.glob(os.path.join(args.frames, args.pattern)))
    ims = []
    for f in files:
        im = Image.open(f).convert("RGB").resize((args.size, args.size), Image.LANCZOS)
        ims.append(im.convert("P", palette=Image.ADAPTIVE, colors=128))
    ims[0].save(args.out, save_all=True, append_images=ims[1:],
                duration=int(1000 / args.fps), loop=0, optimize=True)
    print("gif:", args.out, len(ims), "frames", os.path.getsize(args.out) // 1024, "KB")


if __name__ == "__main__":
    main()
