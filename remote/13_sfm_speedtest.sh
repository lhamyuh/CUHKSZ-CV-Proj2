#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
D=$ROOT/runs/sfm_test
rm -rf $D; mkdir -p $D/images
for f in $(ls $ROOT/data_object/frames/*.jpg | sed -n 1,10p); do cp "$f" $D/images/; done
ls $D/images | wc -l
t0=$(date +%s)
colmap feature_extractor --database_path $D/db.db --image_path $D/images \
  --ImageReader.single_camera 1 --ImageReader.camera_model PINHOLE \
  --SiftExtraction.use_gpu 0 --SiftExtraction.num_threads 20 \
  --SiftExtraction.max_image_size 720 > $D/feat.log 2>&1
echo "feat rc=$? $(( $(date +%s)-t0 ))s"
tail -5 $D/feat.log
t2=$(date +%s)
colmap exhaustive_matcher --database_path $D/db.db \
  --SiftMatching.use_gpu 0 --SiftMatching.num_threads 20 > $D/match.log 2>&1
echo "match rc=$? $(( $(date +%s)-t2 ))s"
tail -5 $D/match.log
echo COLMAP_SPEED_OK