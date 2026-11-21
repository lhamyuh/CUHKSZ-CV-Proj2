#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
source $ROOT/env/bin/activate
OUT=$ROOT/deliver/repro_226010334_LinyuYANG
rm -rf $OUT; mkdir -p $OUT/{code,data,metrics,env,logs}
cp $ROOT/code/*.py $OUT/code/ 2>/dev/null || true
cp $ROOT/remote/*.sh $OUT/code/ 2>/dev/null || true
cp -r $ROOT/tools_local/* $OUT/code/ 2>/dev/null || true
cp $ROOT/data_object/split.json $OUT/data/object_split.json
ls $ROOT/data_object/frames | sort > $OUT/data/frames.txt
md5sum $ROOT/data_object/masks/*.png | sed 's| .*/| |' > $OUT/data/masks.md5
cp $ROOT/runs/garden_base/metrics_val.json $OUT/metrics/ 2>/dev/null || true
cp $ROOT/runs/obj_w/eval*.json $OUT/metrics/ 2>/dev/null || true
cp $ROOT/runs/garden_base/loss.csv $OUT/logs/ 2>/dev/null || true
cp $ROOT/preview/placement_wfinal.json $OUT/metrics/fusion_placement.json 2>/dev/null || true
pip freeze > $OUT/env/pip_freeze.txt
nvidia-smi > $OUT/env/nvidia_smi.txt 2>&1 || true
nvcc --version > $OUT/env/nvcc.txt 2>&1 || true
colmap -h 2>&1 | head -3 > $OUT/env/colmap.txt || true
git -C $ROOT/gs/repo rev-parse HEAD > $OUT/env/gs_commit.txt 2>/dev/null || true
python --version > $OUT/env/python.txt 2>&1
cat > $OUT/REPRODUCE.md <<'MD'
# Reproducing 226010334 Linyu YANG from scratch

Everything below runs on one Linux GPU box. The course data (`train/`, `val/`, `test/`,
`trajectory/`, `object/camera/`) is **not** redistributed; take it from the course release.

## 1. Environment

```bash
python -m venv --system-site-packages env && source env/bin/activate
pip install plyfile opencv-python-headless scipy lpips==0.1.4 imageio imageio-ffmpeg rembg onnxruntime
# exact versions: env/pip_freeze.txt
git clone https://github.com/graphdeco-inria/gaussian-splatting gs/repo
cd gs/repo && git checkout 54c035f7834b564019656c3e3fcc3646292f727d
pip install ./submodules/diff-gaussian-rasterization ./submodules/simple-knn   # TORCH_CUDA_ARCH_LIST=9.0
```

## 2. Garden (Task A)

```bash
cd gs/repo
python train.py -s $ROOT/release/train -m $ROOT/runs/garden_base \
  --iterations 30000 --save_iterations 7000 15000 30000
python code/render_views.py --ply $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --cameras $ROOT/release/val/cameras.json --out $ROOT/runs/garden_base/renders_val
# test renders, trajectory video and metrics: see code/16_eval_garden.sh and 09_render_test.sh
```

## 3. Object (Task B)

```bash
python code/prep_object.py ...          # 8 fps frame extraction + u2netp masks
bash code/24_sfm_masked.sh              # mask-limited COLMAP, 498/498 registered
python code/build_object_dataset.py ... # train split, white background, masks dilated by 2 px
bash code/31_train_obj.sh               # 30k iterations
python code/prune_object.py ... && python code/refine_object.py ... && python code/smooth_object.py ...
python code/render_views.py ...         # orbit frames -> frames_to_gif.py
```

`data/object_split.json` is the exact split; `data/frames.txt` and `data/masks.md5` pin the inputs.

## 4. Fusion (Task C)

```bash
python code/fuse_scene.py ...           # table plane fit, placement (see metrics/fusion_placement.json)
python code/phong_fusion.py --scene ... --object ... --placement ... \
  --ka 0.62 --kd 0.55 --ks 0.06 --deglare 0.38 --scale_boost 1.30 --opacity_add 0.9 \
  --shadow_strength 0.85 --shadow_len 0.28 --shadow_wid 0.17 --shadow_offset 0.45 \
  --ao_strength 0.60 --ao_radius 0.20 --base_align 1 --base_mode percentile
python code/render_views.py --ply fused.ply --cameras path_h.json --out frames
python code/make_mp4.py --frames frames --out fusion/orbit.mp4 --fps 24
```

## 5. Check

```bash
python release/tools/validate_submission.py 226010334_LinyuYANG release/test/cameras.json
sha256sum -c SHA256SUMS   # inside records_226010334_LinyuYANG.tar.gz
```
MD
python - <<PY
import hashlib, os
root = "$OUT"
lines = []
for dp, dn, fn in os.walk(root):
    for f in sorted(fn):
        p = os.path.join(dp, f)
        if f == "SHA256SUMS":
            continue
        lines.append("%s  %s" % (hashlib.sha256(open(p, "rb").read()).hexdigest(), os.path.relpath(p, root)))
open(os.path.join(root, "SHA256SUMS"), "w").write("\n".join(lines) + "\n")
print("hashed", len(lines))
PY
cd $ROOT/deliver && tar -czf repro_226010334_LinyuYANG.tar.gz repro_226010334_LinyuYANG
ls -lh repro_226010334_LinyuYANG.tar.gz
echo REPRO_DONE