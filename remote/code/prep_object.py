"""Extract frames from the supplied object clips and build the disjoint split.

Split (8 fps, so 1 s == 8 frames):
  train : 1975_0000-0197 + 1976_0000-0031 + 1976_0081-0135   (285)
  val   : 1976_0040-0072                                      ( 33)  gaps 0032-0039 / 0073-0080
  test  : 1977_0000-0163                                      (164)
"""
import argparse
import json
import os

import cv2
from PIL import Image

CLIPS = {"1975": 198, "1976": 136, "1977": 164}


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--release", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--object", default="camera")
    args = p.parse_args()

    frames_dir = os.path.join(args.out, "frames")
    os.makedirs(frames_dir, exist_ok=True)
    for clip, n_expected in CLIPS.items():
        path = os.path.join(args.release, "object", args.object, clip + ".mp4")
        cap = cv2.VideoCapture(path)
        n = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        idx = 0
        while True:
            ok, fr = cap.read()
            if not ok:
                break
            Image.fromarray(cv2.cvtColor(fr, cv2.COLOR_BGR2RGB)).save(
                os.path.join(frames_dir, f"{clip}_{idx:04d}.jpg"), quality=95)
            idx += 1
        cap.release()
        print(f"{clip}: wrote {idx} frames (expected {n_expected}, container says {n})")

    def ids(clip, a, b):
        return [f"{clip}_{i:04d}" for i in range(a, b + 1)]

    split = {
        "object": args.object,
        "fps": 8,
        "val_gap_frames": 8,
        "clips": CLIPS,
        "train": ids("1975", 0, 197) + ids("1976", 0, 31) + ids("1976", 81, 135),
        "val": ids("1976", 40, 72),
        "test": ids("1977", 0, 163),
    }
    assert not (set(split["train"]) & set(split["val"]))
    assert not (set(split["train"]) & set(split["test"]))
    assert not (set(split["val"]) & set(split["test"]))
    with open(os.path.join(args.out, "split.json"), "w") as f:
        json.dump(split, f, indent=2)
    print("train", len(split["train"]), "val", len(split["val"]), "test", len(split["test"]))

    train_dir = os.path.join(args.out, "images_train")
    os.makedirs(train_dir, exist_ok=True)
    for name in split["train"]:
        src = os.path.join(frames_dir, name + ".jpg")
        dst = os.path.join(train_dir, name + ".jpg")
        if not os.path.exists(dst):
            os.symlink(src, dst)
    print("images_train:", len(os.listdir(train_dir)))

    val_dir = os.path.join(args.out, "images_val")
    os.makedirs(val_dir, exist_ok=True)
    for name in split["val"]:
        src = os.path.join(frames_dir, name + ".jpg")
        dst = os.path.join(val_dir, name + ".jpg")
        if not os.path.exists(dst):
            os.symlink(src, dst)
    print("images_val:", len(os.listdir(val_dir)))


if __name__ == "__main__":
    main()
