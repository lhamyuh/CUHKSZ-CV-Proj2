# CIE 6004 Assignment 2 — Reproducibility README

Student: **Linyu YANG (226010334)**. Submission archive: `226010334_LinyuYANG.zip`.
Model weights, `cfg_args`, COLMAP model and checksums are kept as the release asset
`records_226010334_LinyuYANG.tar.gz`:
<https://github.com/lhamyuh/CUHKSZ-CV-Proj2/releases/tag/v2.0-final>

All numbers in `report.pdf` come from the runs described here. Everything was executed on a
single AutoDL instance (NVIDIA H800 PCIe 80 GB, 20 vCPU, 100 GB RAM, Ubuntu 22.04), with the
project root `/root/autodl-tmp/CIE6004_ASGN2`.

## Environment

| item | value |
|---|---|
| Python | 3.10.8 (venv created from the image's Miniconda) |
| PyTorch | 2.1.2+cu118 |
| CUDA toolkit | 11.8 (system `/usr/local/cuda`) |
| 3DGS code | `graphdeco-inria/gaussian-splatting` @ `54c035f7834b564019656c3e3fcc3646292f727d` |
| CUDA extensions | `diff-gaussian-rasterization`, `simple-knn` compiled with `TORCH_CUDA_ARCH_LIST=9.0` |
| Extra packages | numpy 1.26.4, plyfile 1.0.3, opencv-python-headless 4.10.0.84, scipy, lpips 0.1.4, imageio-ffmpeg, rembg 2.0.69 (u2netp), tensorboard |
| COLMAP | 3.7 (Ubuntu package, CPU SIFT) |

Setup commands:

```bash
cd /root/autodl-tmp/CIE6004_ASGN2
/root/miniconda3/bin/python -m venv --system-site-packages env
source env/bin/activate
pip install plyfile opencv-python-headless scipy lpips==0.1.4 imageio imageio-ffmpeg rembg onnxruntime
cd gs/repo && pip install ./submodules/diff-gaussian-rasterization ./submodules/simple-knn
```

## Garden (Task A)

```bash
cd gs/repo
python train.py -s $ROOT/release/train -m $ROOT/runs/garden_base \
  --iterations 30000 --save_iterations 7000 15000 30000 --test_iterations 30000
python code/render_views.py --ply runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --cameras release/val/cameras.json --out runs/garden_base/renders_val
python code/render_views.py --ply ... --cameras release/test/cameras.json --out runs/garden_base/renders_test
python code/render_views.py --ply ... --cameras release/trajectory/garden.json --out runs/garden_base/frames_orbit
python code/make_mp4.py --frames runs/garden_base/frames_orbit --out scene/orbit.mp4 --fps 24
python release/tools/evaluate.py release/val runs/garden_base/renders_val runs/garden_base/metrics_val.json
```

Seed: 3DGS default (no `--seed` flag); COLMAP initialisation is deterministic. Wall clock: 21 min,
4,173,282 Gaussians, validation 27.27 dB / 0.8668 / 0.0764.

## Object (Task B)

```bash
python code/prep_object.py --release release --out data_object --object camera
python code/run_masks.py --frames data_object/frames --out data_object/masks --model u2netp
# COLMAP with mask-limited features (mask_path), CPU SIFT, exhaustive matching, mapper
bash remote/24_sfm_masked.sh          # registers 498/498 frames, 10,939 points
python code/build_object_dataset.py --sfm runs/obj_sfm_m/sparse/0 --frames data_object/frames \
  --masks data_object/masks --split data_object/split.json --out data_object --min_obs 1 --bg 255
cd gs/repo && python train.py -s $ROOT/data_object/train -m $ROOT/runs/obj_w \
  --iterations 30000 --white_background --save_iterations 5000 10000 15000 30000
```

Controlled experiment: identical command with `--dilate 2` in `build_object_dataset.py` and the
same 30k budget (`runs/obj_d2`). Metrics: `python code/eval_object.py ...`.

## Fusion (Task C)

* Table plane: RANSAC over the sparse cloud inside an image-space ellipse (`tools_local/fit_table.py`);
  centre, normal and radius written to `fusion/placement.json` metadata.
* Object scale: PCA extents of the pruned object model, body width 5.28 units = 136 mm.
* `placement.json` stores `object_to_scene` (4x4, column vectors). Applying it:
  `p_scene = s R p_obj + t`, log-scales `+= log s`, rotations `q_R * q_obj`
  (`code/fuse_scene.py`).
* Render: `python code/render_views.py --ply fused.ply --cameras path.json --out frames --bg 0`
  then `python code/make_mp4.py --frames frames --out fusion/orbit.mp4 --fps 24`.

## Files

| path | content |
|---|---|
| `code/` | all scripts: camera loader, object prep, masks, dataset builder, pruning, fusion, rendering, metrics, video |
| `renders/` | 12 test views at 1297x840 |
| `scene/orbit.mp4` | 240 poses, 24 fps, 10.0 s, 1280x720 |
| `evidence/` | orbit GIF, loss CSV/PNG, stages, ablation |
| `fusion/` | placement JSON and 10 s fusion video |
| `object_split.json` | disjoint train/val/test frame identifiers |
