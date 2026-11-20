"""Build the object training set from a COLMAP model, split.json and rembg masks.

Outputs
  data_object/train/images/<stem>.png         RGBA, background RGB=0, alpha=mask
  data_object/train/sparse/0/{cameras,images,points3D}.bin   train frames only, points filtered
  data_object/val_cameras.json, test_cameras.json            release-style camera JSON

The alpha channel turns 3DGS's built-in `image *= alpha_mask` into foreground-weighted
photometric supervision; points whose observations fall outside the masks are dropped.
"""
import argparse
import json
import os
import shutil

import numpy as np
from PIL import Image

from colmap_io import (qvec2rotmat, read_cameras, read_images, read_points3d,
                       write_cameras, write_images, write_points3d)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--sfm", required=True, help="dir with cameras.bin images.bin points3D.bin")
    p.add_argument("--frames", required=True)
    p.add_argument("--masks", required=True)
    p.add_argument("--split", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--min_obs", type=int, default=2)
    p.add_argument("--bg", type=int, default=255, help="background value outside the mask (0 or 255)")
    p.add_argument("--dilate", type=int, default=0, help="dilate masks by N pixels before use")
    p.add_argument("--upscale", type=int, default=1, help="resize images (and intrinsics) by this factor")
    args = p.parse_args()

    split = json.load(open(args.split))
    train_names = [n + ".jpg" for n in split["train"]]
    cams = read_cameras(os.path.join(args.sfm, "cameras.bin"))
    imgs = read_images(os.path.join(args.sfm, "images.bin"))
    pts = read_points3d(os.path.join(args.sfm, "points3D.bin"))
    print(f"model: {len(cams)} cameras, {len(imgs)} images, {len(pts)} points")

    by_name = {im["name"]: (iid, im) for iid, im in imgs.items()}
    missing = [n for n in train_names if n not in by_name]
    print(f"train frames registered: {len(train_names)-len(missing)}/{len(train_names)}")
    if missing:
        print("missing (not registered):", missing[:10], "...")

    # --- masks and RGBA images ---
    train_dir = os.path.join(args.out, "train")
    img_out = os.path.join(train_dir, "images")
    os.makedirs(img_out, exist_ok=True)
    kept_names = []
    for jpg in train_names:
        stem = os.path.splitext(jpg)[0]
        mpath = os.path.join(args.masks, stem + ".png")
        if not os.path.exists(mpath) or jpg not in by_name:
            continue
        rgb = np.asarray(Image.open(os.path.join(args.frames, jpg)).convert("RGB"))
        m = np.asarray(Image.open(mpath).convert("L"))
        if m.shape != rgb.shape[:2]:
            m = np.asarray(Image.fromarray(m).resize((rgb.shape[1], rgb.shape[0]), Image.NEAREST))
        if args.dilate > 0:
            import cv2
            k = np.ones((args.dilate * 2 + 1,) * 2, np.uint8)
            m = cv2.dilate((m > 127).astype(np.uint8) * 255, k, iterations=1)
        if args.upscale > 1:
            from PIL import Image as _I
            W2 = rgb.shape[1] * args.upscale
            H2 = rgb.shape[0] * args.upscale
            rgb = np.asarray(_I.fromarray(rgb).resize((W2, H2), _I.LANCZOS))
            m = np.asarray(_I.fromarray(m).resize((W2, H2), _I.NEAREST))
        bg = np.full_like(rgb, args.bg, dtype=np.uint8)
        comp = np.where((m > 127)[..., None], rgb, bg)
        Image.fromarray(comp, "RGB").save(os.path.join(img_out, stem + ".png"))
        kept_names.append(stem)
    print("masked images written:", len(kept_names))

    # --- filtered point cloud ---
    name_to_mask = {}
    for n in kept_names:
        stem = os.path.splitext(n)[0]
        name_to_mask[stem] = np.asarray(
            Image.open(os.path.join(args.masks, stem + ".png")).convert("L")) > 127
    kept_pts = {}
    n_obs = 0
    for pid, pt in pts.items():
        inside = 0
        for (iid, p2d) in pt["track"]:
            im = imgs.get(iid)
            if im is None or p2d >= len(im["points2D"]):
                continue
            stem = os.path.splitext(im["name"])[0]
            m = name_to_mask.get(stem)
            if m is None:
                continue
            x, y = im["points2D"][p2d][0], im["points2D"][p2d][1]
            xi, yi = int(round(x)), int(round(y))
            if 0 <= yi < m.shape[0] and 0 <= xi < m.shape[1] and m[yi, xi]:
                inside += 1
                n_obs += 1
        if inside >= args.min_obs:
            kept_pts[pid] = pt
    print(f"points kept {len(kept_pts)}/{len(pts)} ({100*len(kept_pts)/max(1,len(pts)):.1f}%)")

    # --- train-only COLMAP model ---
    sp = os.path.join(train_dir, "sparse", "0")
    os.makedirs(sp, exist_ok=True)
    new_imgs = {}
    for stem in kept_names:
        iid, im = by_name[stem + ".jpg"]
        im2 = dict(im)
        im2["name"] = stem + ".png"
        new_imgs[iid] = im2
    if args.upscale > 1:
        for cid, c in cams.items():
            c["width"] *= args.upscale
            c["height"] *= args.upscale
            c["params"] = [p * args.upscale for p in c["params"]]
    write_cameras(os.path.join(sp, "cameras.bin"), cams)
    write_images(os.path.join(sp, "images.bin"), new_imgs)
    write_points3d(os.path.join(sp, "points3D.bin"), kept_pts)
    print("train model:", len(new_imgs), "images,", len(kept_pts), "points")

    # --- val / test cameras in release JSON format ---
    for split_name in ("val", "test"):
        views = []
        for stem in split[split_name]:
            jpg = stem + ".jpg"
            if jpg not in by_name:
                continue
            iid, im = by_name[jpg]
            c = cams[im["camera_id"]]
            fx, fy, cx, cy = c["params"][:4]
            R = qvec2rotmat(im["q"])
            M = np.eye(4)
            M[:3, :3] = R
            M[:3, 3] = im["t"]
            views.append({"name": stem + ".png", "world_to_camera": M.tolist(),
                          "source": stem + ".jpg"})
        out = {"width": c["width"], "height": c["height"], "fx": fx, "fy": fy,
               "cx": cx, "cy": cy, "views": views}
        path = os.path.join(args.out, f"{split_name}_cameras.json")
        json.dump(out, open(path, "w"), indent=1)
        print(split_name, "cameras:", len(views), "->", path)


if __name__ == "__main__":
    main()
