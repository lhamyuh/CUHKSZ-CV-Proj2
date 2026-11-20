#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
D=$ROOT/runs/obj_sfm
rm -rf $D; mkdir -p $D/sparse
cd $D
echo "=== feature extraction ==="
colmap feature_extractor --database_path db.db --image_path $ROOT/data_object/frames \
  --ImageReader.single_camera 1 --ImageReader.camera_model PINHOLE \
  --SiftExtraction.use_gpu 0 --SiftExtraction.num_threads 20 \
  --SiftExtraction.max_image_size 720 > feat.log 2>&1
echo "feat rc=$?"; tail -3 feat.log
echo "=== exhaustive matching ==="
colmap exhaustive_matcher --database_path db.db \
  --SiftMatching.use_gpu 0 --SiftMatching.num_threads 20 > match.log 2>&1
echo "match rc=$?"; tail -3 match.log
echo "=== mapper ==="
colmap mapper --database_path db.db --image_path $ROOT/data_object/frames \
  --output_path sparse --Mapper.num_threads 20 > mapper.log 2>&1
echo "mapper rc=$?"; tail -5 mapper.log
echo "=== models ==="
ls -d sparse/* 2>/dev/null
for m in sparse/*/; do echo -n "$m: "; colmap model_analyzer --path $m 2>/dev/null | grep -E "Registered images|Points" | tr "\n" " "; echo; done
echo SFM_DONE