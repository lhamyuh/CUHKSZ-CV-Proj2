"""Export training loss scalars from a TensorBoard run to CSV."""
import argparse
import csv
import os

from tensorboard.backend.event_processing.event_accumulator import EventAccumulator


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--run", required=True)
    p.add_argument("--out", required=True)
    args = p.parse_args()
    ea = EventAccumulator(args.run, size_guidance={"scalars": 0})
    ea.Reload()
    tags = ea.Tags()["scalars"]
    print("tags:", tags)
    want = ["train_loss_patches/total_loss", "train_loss_patches/l1_loss", "iter_time"]
    data = {}
    for t in want:
        if t in tags:
            data[t] = {e.step: e.value for e in ea.Scalars(t)}
    steps = sorted(set().union(*[set(d) for d in data.values()])) if data else []
    with open(args.out, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["iteration", "total_loss", "l1_loss", "iter_time"])
        for s in steps:
            w.writerow([s,
                        data.get("train_loss_patches/total_loss", {}).get(s, ""),
                        data.get("train_loss_patches/l1_loss", {}).get(s, ""),
                        data.get("iter_time", {}).get(s, "")])
    print("wrote", args.out, len(steps), "rows")


if __name__ == "__main__":
    main()
