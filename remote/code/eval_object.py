"""Compare object renders against source frames inside the foreground masks.

  python code/eval_object.py --renders runs/obj_w/views_ablation --frames data_object/frames \
      --masks data_object/masks --cams runs/obj_w/ablation_cams.json --out runs/obj_w/eval.json
"""
import argparse
import json
import os

import numpy as np
from PIL import Image


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--renders", required=True)
    p.add_argument("--frames", required=True)
    p.add_argument("--masks", required=True)
    p.add_argument("--cams", required=True)
    p.add_argument("--out", required=True)
    args = p.parse_args()

    cams = json.load(open(args.cams))
    rows = []
    for v in cams["views"]:
        stem = os.path.splitext(v["name"])[0]
        src = os.path.splitext(v.get("source", stem + ".jpg"))[0]
        gt = np.asarray(Image.open(os.path.join(args.frames, src + ".jpg")).convert("RGB"), np.float32) / 255
        mask = np.asarray(Image.open(os.path.join(args.masks, stem + ".png")).convert("L")) > 127
        pred = np.asarray(Image.open(os.path.join(args.renders, stem + ".png")).convert("RGB"), np.float32) / 255
        m = mask[..., None]
        mse = float(np.mean(((pred - gt) ** 2)[np.broadcast_to(m, pred.shape)]))
        psnr = -10 * np.log10(max(mse, 1e-10))
        # silhouette IoU: rendered non-white pixels vs mask
        sil = np.abs(pred - 1.0).max(2) > 12 / 255.0
        inter = np.logical_and(sil, mask).sum()
        union = np.logical_or(sil, mask).sum()
        iou = float(inter) / max(int(union), 1)
        rows.append(dict(name=stem, psnr_masked=psnr, iou=iou,
                         mask_area=int(mask.sum()), sil_area=int(sil.sum())))
        print(f"{stem}: psnr(masked) {psnr:.2f}  IoU {iou:.3f}")
    means = {k: float(np.mean([r[k] for r in rows])) for k in ("psnr_masked", "iou")}
    json.dump(dict(means=means, views=rows), open(args.out, "w"), indent=2)
    print("means", means)


if __name__ == "__main__":
    main()
