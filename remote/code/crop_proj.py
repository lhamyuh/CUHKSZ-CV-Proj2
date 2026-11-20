"""Crop a render around the projected object centre (for contact/quality checks)."""
import argparse
import json

import numpy as np
from PIL import Image


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--render", required=True)
    p.add_argument("--cameras", required=True)
    p.add_argument("--view", default="")
    p.add_argument("--placement", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--width", type=int, default=760)
    p.add_argument("--zoom", type=float, default=0.22, help="crop half-size as a fraction of image width")
    args = p.parse_args()

    cams = json.load(open(args.cameras))
    view = cams["views"][0]
    if args.view:
        view = next(v for v in cams["views"] if v["name"] == args.view)
    M = np.asarray(view["world_to_camera"], dtype=np.float64)
    fx, fy, cx, cy = cams["fx"], cams["fy"], cams["cx"], cams["cy"]
    pl = json.load(open(args.placement))
    P = np.asarray(pl["position"], dtype=np.float64)
    # position was stored before grounding; add the grounding shift if present
    if "grounding_shift_m" in pl:
        P = P - float(pl["grounding_shift_m"]) * np.asarray(pl["scene_up"], dtype=np.float64)
    cam = M[:3, :3] @ P + M[:3, 3]
    u = fx * cam[0] / cam[2] + cx
    v = fy * cam[1] / cam[2] + cy
    im = Image.open(args.render).convert("RGB")
    half = int(args.zoom * im.width)
    box = (int(u - half), int(v - half), int(u + half), int(v + half))
    crop = im.crop(box)
    h = int(crop.height * args.width / crop.width)
    crop.resize((args.width, h), Image.LANCZOS).save(args.out, quality=88)
    print(f"object at ({u:.0f},{v:.0f}) crop {box} -> {args.out}")


if __name__ == "__main__":
    main()
