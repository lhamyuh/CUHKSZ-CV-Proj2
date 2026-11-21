"""Build a server-side review gallery (images + videos) for manual verification.

Everything is composed on the server; the browser only downloads the thumbnails.
Run:  python code/make_gallery.py --root /root/autodl-tmp/CIE6004_ASGN2
"""
import argparse
import json
import os
import shutil

from PIL import Image, ImageDraw

W = 420


def load(path):
    return Image.open(path).convert("RGB")


def fit(im, w=W):
    h = int(im.height * w / im.width)
    return im.resize((w, h), Image.LANCZOS)


def labelled(im, text, h=22):
    c = Image.new("RGB", (im.width, im.height + h), "white")
    c.paste(im, (0, h))
    ImageDraw.Draw(c).text((5, 5), text, fill="black")
    return c


def stack_rows(rows, path):
    h = sum(r.height for r in rows)
    w = max(r.width for r in rows)
    c = Image.new("RGB", (w, h), "white")
    y = 0
    for r in rows:
        c.paste(r, (0, y))
        y += r.height
    c.save(path, quality=86)
    print("wrote", path, c.size)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--root", required=True)
    args = p.parse_args()
    R = args.root
    G = os.path.join(R, "gallery")
    for sub in ("A", "B", "C", "media"):
        os.makedirs(os.path.join(G, sub), exist_ok=True)

    # ---------- A: validation comparison ----------
    cams = json.load(open(os.path.join(R, "release/val/cameras.json")))["views"]
    rows = []
    for v in cams:
        stem = os.path.splitext(v["name"])[0]
        ref = labelled(fit(load(os.path.join(R, "release/val/reference", v["name"]))), "reference")
        ours = labelled(fit(load(os.path.join(R, "runs/garden_base/renders_val", stem + ".png"))), "ours")
        base = labelled(fit(load(os.path.join(R, "release/val/baseline", stem + ".png"))), "released baseline")
        row = Image.new("RGB", (ref.width * 3, ref.height), "white")
        row.paste(ref, (0, 0))
        row.paste(ours, (ref.width, 0))
        row.paste(base, (2 * ref.width, 0))
        d = ImageDraw.Draw(row)
        d.text((6, row.height - 3), stem, fill="black")
        rows.append(row)
    stack_rows(rows[:6], os.path.join(G, "A", "A_val_1.jpg"))
    stack_rows(rows[6:], os.path.join(G, "A", "A_val_2.jpg"))

    hard = os.path.join(R, "runs/garden_base/renders_val/DSC07988.png")
    ref88 = os.path.join(R, "release/val/reference/DSC07988.JPG")
    base88 = os.path.join(R, "release/val/baseline/DSC07988.png")
    row = Image.new("RGB", (3 * W, int(W * 840 / 1297) + 22), "white")
    x = 0
    for path, t in ((ref88, "reference"), (hard, "ours"), (base88, "baseline")):
        im = labelled(fit(load(path)), t)
        row.paste(im, (x, 0))
        x += im.width
    row.save(os.path.join(G, "A", "A_hardest.jpg"), quality=88)

    # ---------- B: object ----------
    st = []
    for it in (5000, 10000, 15000, 30000):
        im = load(os.path.join(R, f"runs/obj_w/stages/{it}/1976_0048.png"))
        st.append(labelled(fit(im, 300), f"{it//1000}k iters"))
    row = Image.new("RGB", (sum(i.width for i in st), st[0].height), "white")
    x = 0
    for i in st:
        row.paste(i, (x, 0))
        x += i.width
    row.save(os.path.join(G, "B", "B_stages.jpg"), quality=88)

    rows = []
    for stem in ("1976_0043", "1976_0048", "1976_0060"):
        a = labelled(fit(load(os.path.join(R, "runs/obj_w/views_ablation", stem + ".png")), 320), f"baseline {stem}")
        b = labelled(fit(load(os.path.join(R, "runs/obj_d2/views_ablation", stem + ".png")), 320), f"+2px mask {stem}")
        r = Image.new("RGB", (a.width + b.width, a.height), "white")
        r.paste(a, (0, 0))
        r.paste(b, (a.width, 0))
        rows.append(r)
    stack_rows(rows, os.path.join(G, "B", "B_ablation.jpg"))

    src = load(os.path.join(R, "data_object/frames/1976_0048.jpg"))
    m = Image.open(os.path.join(R, "data_object/masks/1976_0048.png")).convert("L").resize(src.size)
    mask = Image.merge("RGB", [m, m, m])
    ren = load(os.path.join(R, "runs/obj_w/views_ablation/1976_0048.png"))
    trip = [labelled(fit(src), "source frame"), labelled(fit(mask), "foreground mask"),
            labelled(fit(ren), "reconstruction")]
    row = Image.new("RGB", (sum(i.width for i in trip), trip[0].height), "white")
    x = 0
    for i in trip:
        row.paste(i, (x, 0))
        x += i.width
    row.save(os.path.join(G, "B", "B_mask_triplet.jpg"), quality=88)
    shutil.copy(os.path.join(R, "preview/obj_orbit.gif"), os.path.join(G, "B", "B_orbit.gif"))

    # ---------- C: fusion ----------
    frames = []
    for i in ("000", "120", "150", "180", "239"):
        im = load(os.path.join(R, f"runs/fusion/cfinal_frames/frame_{i}.png"))
        frames.append(labelled(fit(im, 420), f"{int(i)/24:.1f} s"))
    row = Image.new("RGB", (sum(i.width for i in frames), frames[0].height), "white")
    x = 0
    for i in frames:
        row.paste(i, (x, 0))
        x += i.width
    row.save(os.path.join(G, "C", "C_strip.jpg"), quality=88)

    # ---------- media ----------
    shutil.copy(os.path.join(R, "preview/scene_orbit.mp4"), os.path.join(G, "media/scene_orbit.mp4"))
    shutil.copy(os.path.join(R, "preview/fusion_cfinal.mp4"), os.path.join(G, "media/fusion_orbit.mp4"))

    # ---------- index ----------
    metrics = json.load(open(os.path.join(R, "runs/garden_base/metrics_val.json")))
    base = json.load(open(os.path.join(R, "release/val/baseline.json")))
    obj = json.load(open(os.path.join(R, "runs/obj_w/eval.json")))
    objd = json.load(open(os.path.join(R, "runs/obj_d2/eval.json")))
    html = f"""<!doctype html><meta charset="utf-8"><title>Assignment 2 review</title>
<style>body{{font-family:system-ui;margin:24px;max-width:1500px}} img{{max-width:100%;border:1px solid #ddd;margin:6px 0}}
table{{border-collapse:collapse}} td,th{{border:1px solid #ccc;padding:4px 8px;font-size:14px}}
h2{{margin-top:36px}}</style>
<h1>Assignment 2 — visual verification</h1>
<h2>Quantitative summary</h2>
<table><tr><th></th><th>PSNR</th><th>SSIM</th><th>LPIPS</th></tr>
<tr><td>Garden baseline</td><td>{base['means']['psnr']:.3f}</td><td>{base['means']['ssim']:.4f}</td><td>{base['means']['lpips']:.4f}</td></tr>
<tr><td>Garden ours</td><td>{metrics['means']['psnr']:.3f}</td><td>{metrics['means']['ssim']:.4f}</td><td>{metrics['means']['lpips']:.4f}</td></tr>
<tr><td>Object baseline (masked PSNR / IoU)</td><td colspan="3">{obj['means']['psnr_masked']:.2f} / {obj['means']['iou']:.3f}</td></tr>
<tr><td>Object +2px mask</td><td colspan="3">{objd['means']['psnr_masked']:.2f} / {objd['means']['iou']:.3f}</td></tr></table>

<h2>A · Garden</h2>
<p>Per view: reference | ours | released baseline. Check seams, foliage, sky, floaters.</p>
<img src="A/A_val_1.jpg"><img src="A/A_val_2.jpg"><img src="A/A_hardest.jpg">
<p><a href="media/scene_orbit.mp4">scene_orbit.mp4</a> (240 frames, 24 fps, 10 s)</p>
<video src="media/scene_orbit.mp4" controls width="900"></video>

<h2>B · Object (camera)</h2>
<img src="B/B_orbit.gif"><img src="B/B_stages.jpg"><img src="B/B_ablation.jpg"><img src="B/B_mask_triplet.jpg">

<h2>C · Fusion</h2>
<img src="C/C_strip.jpg">
<p><a href="media/fusion_orbit.mp4">fusion_orbit.mp4</a> (240 frames, 24 fps, 10 s)</p>
<video src="media/fusion_orbit.mp4" controls width="900"></video>
"""
    open(os.path.join(G, "index.html"), "w").write(html)
    print("gallery ready:", G)


if __name__ == "__main__":
    main()
