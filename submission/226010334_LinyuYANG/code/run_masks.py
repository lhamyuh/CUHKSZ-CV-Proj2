"""Foreground masks for object frames with rembg (u2net), written as 0/255 PNG."""
import argparse
import os
import sys

import numpy as np
from PIL import Image
from rembg import new_session, remove


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--frames", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--limit", type=int, default=0)
    p.add_argument("--dilate", type=int, default=0)
    p.add_argument("--model", default="u2netp")
    args = p.parse_args()
    os.makedirs(args.out, exist_ok=True)
    sess = new_session(args.model)
    names = sorted(n for n in os.listdir(args.frames) if n.lower().endswith(".jpg"))
    if args.limit:
        names = names[:args.limit]
    for i, n in enumerate(names):
        out = os.path.join(args.out, os.path.splitext(n)[0] + ".png")
        if os.path.exists(out):
            continue
        img = Image.open(os.path.join(args.frames, n)).convert("RGB")
        m = remove(img, session=sess, only_mask=True)
        arr = np.asarray(m)
        arr = (arr > 127).astype(np.uint8) * 255
        if args.dilate > 0:
            import cv2
            k = np.ones((args.dilate * 2 + 1,) * 2, np.uint8)
            arr = cv2.dilate(arr, k, iterations=1)
        Image.fromarray(arr).save(out)
        if i % 50 == 0:
            print(f"{i+1}/{len(names)} {n}", flush=True)
    print("masks done:", len(names))


if __name__ == "__main__":
    main()
