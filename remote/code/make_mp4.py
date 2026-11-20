"""Encode a directory of frames (sorted) into an H.264 MP4 via imageio-ffmpeg.

  python code/make_mp4.py --frames dir --out out.mp4 --fps 24 [--size 1280x720] [--crf 21]
"""
import argparse
import glob
import os

import numpy as np
from PIL import Image


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--frames", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--fps", type=float, default=24)
    p.add_argument("--pattern", default="*.png")
    p.add_argument("--size", default="")
    p.add_argument("--crf", type=int, default=21)
    args = p.parse_args()

    files = sorted(glob.glob(os.path.join(args.frames, args.pattern)))
    assert files, f"no frames in {args.frames}"
    first = np.asarray(Image.open(files[0]).convert("RGB"))
    h, w = first.shape[:2]
    if args.size:
        w, h = [int(x) for x in args.size.lower().split("x")]

    import imageio_ffmpeg
    writer = imageio_ffmpeg.write_frames(
        args.out, size=(w, h), fps=args.fps, codec="libx264",
        output_params=["-crf", str(args.crf), "-pix_fmt", "yuv420p", "-movflags", "+faststart"],
    )
    writer.send(None)
    for f in files:
        img = np.asarray(Image.open(f).convert("RGB"))
        if img.shape[1] != w or img.shape[0] != h:
            img = np.asarray(Image.fromarray(img).resize((w, h), Image.LANCZOS))
        writer.send(img.tobytes())
    writer.close()
    print(f"wrote {args.out}: {len(files)} frames, {w}x{h} @ {args.fps} fps, "
          f"duration {len(files)/args.fps:.2f}s, {os.path.getsize(args.out)//1024} KB")


if __name__ == "__main__":
    main()
