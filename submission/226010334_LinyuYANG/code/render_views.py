"""Render release JSON cameras with a trained 3DGS model.

Usage:
  python code/render_views.py --ply runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
      --cameras release/val/cameras.json --out renders_val [--bg 0]

Cameras JSON: {width,height,fx,fy,cx,cy,views:[{name,world_to_camera(4x4)}]}, OpenCV convention.
"""
import argparse
import json
import os
import sys

import numpy as np
import torch
from PIL import Image

GS_REPO = os.environ.get("GS_REPO", "/root/autodl-tmp/CIE6004_ASGN2/gs/repo")
sys.path.insert(0, GS_REPO)

from arguments import PipelineParams  # noqa: E402
from gaussian_renderer import render  # noqa: E402
from scene.cameras import Camera  # noqa: E402
from scene.gaussian_model import GaussianModel  # noqa: E402
from utils.graphics_utils import focal2fov  # noqa: E402


def build_pipe():
    import argparse as ap
    pipe = PipelineParams(ap.ArgumentParser())
    pipe.convert_SHs_python = False
    pipe.compute_cov3D_python = False
    pipe.debug = False
    pipe.antialiasing = False
    return pipe


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--ply", required=True)
    p.add_argument("--cameras", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--sh_degree", type=int, default=3)
    p.add_argument("--bg", type=float, default=0.0)
    p.add_argument("--limit", type=int, default=0)
    args = p.parse_args()

    os.makedirs(args.out, exist_ok=True)
    cams = json.loads(open(args.cameras).read())
    W, H = int(cams["width"]), int(cams["height"])
    fx, fy = float(cams["fx"]), float(cams["fy"])
    FoVx, FoVy = focal2fov(fx, W), focal2fov(fy, H)

    model = GaussianModel(args.sh_degree)
    model.load_ply(args.ply)
    model.active_sh_degree = args.sh_degree
    pipe = build_pipe()
    bg = torch.tensor([args.bg, args.bg, args.bg], dtype=torch.float32, device="cuda")

    views = cams["views"]
    if args.limit:
        views = views[:args.limit]
    dummy = Image.new("RGB", (W, H), (0, 0, 0))
    for i, v in enumerate(views):
        M = np.asarray(v["world_to_camera"], dtype=np.float64)
        # 3DGS Camera expects R = camera-to-world rotation (COLMAP loader transposes
        # qvec2rotmat) and T = COLMAP tvec, i.e. the world-to-camera translation.
        cam = Camera(
            resolution=(W, H), colmap_id=i, R=M[:3, :3].T, T=M[:3, 3],
            FoVx=FoVx, FoVy=FoVy, depth_params=None, image=dummy,
            invdepthmap=None, image_name=v["name"], uid=i, data_device="cuda",
        )
        with torch.no_grad():
            img = render(cam, model, pipe, bg)["render"]
        arr = (img.clamp(0, 1).permute(1, 2, 0).cpu().numpy() * 255.0 + 0.5).astype(np.uint8)
        name = os.path.splitext(os.path.basename(v["name"]))[0]
        out = os.path.join(args.out, name + ".png")
        Image.fromarray(arr).save(out)
        if i % 20 == 0:
            print(f"{i+1}/{len(views)} {name} {arr.shape}", flush=True)
    print("done", len(views), "->", args.out)


if __name__ == "__main__":
    main()
